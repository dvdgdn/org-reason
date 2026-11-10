;;; org-reason-gtd.el --- GTD clarification and action views -*- lexical-binding: t; -*-
;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Code:
(require 'org-reason-core)
(require 'org-agenda)
(require 'org-clock)

(defcustom org-reason-contexts '("@computer" "@calls" "@home" "@work" "@errands" "@anywhere")
  "Contexts available when clarifying an action."
  :type '(repeat string) :group 'org-reason)

(defun org-reason--move (destination properties &optional state tags)
  "Move the current subtree to DESTINATION, preserving its ID and body.
Save the destination before removing the source.  If writing fails, the
source remains recoverable.  Plain files cannot provide a two-file transaction."
  (org-reason--require-entry)
  (let* ((source (current-buffer))
         (source-file buffer-file-name)
         (id (org-entry-get nil "ID"))
         (start (copy-marker (point)))
         (end (copy-marker (save-excursion (org-end-of-subtree t t) (point)) t))
         (text (buffer-substring-no-properties start end)))
    (when (file-equal-p buffer-file-name destination)
      (user-error "Source and destination must differ"))
    ;; Transform a copy, so cancellation or a write failure leaves the inbox intact.
    (setq text
          (with-temp-buffer
            (insert org-reason--todo-line text)
            (org-mode)
            (goto-char (point-min))
            (outline-next-heading)
            (dolist (pair properties)
              (org-entry-put nil (car pair) (org-reason--clean (cdr pair))))
            (org-entry-put nil "OR_CLARIFIED" (org-reason--now))
            (let ((org-inhibit-logging t)) (org-todo (or state 'none)))
            (when tags (org-set-tags (delete-dups (append (org-get-tags nil t) tags))))
            (save-excursion (org-reason--rebase-file-links source-file destination))
            (buffer-substring-no-properties (line-beginning-position) (point-max))))
    (with-current-buffer (org-reason--buffer destination)
      (goto-char (point-max))
      (unless (bolp) (insert "\n"))
      (let ((position (point)))
        (condition-case error-data
            (progn (insert text "\n") (org-reason--save-buffer))
          (error (delete-region position (point-max))
                 (signal (car error-data) (cdr error-data))))))
    (with-current-buffer source
      (delete-region start end)
      (org-reason--save-buffer))
    (org-id-add-location id destination)
    id))

(defun org-reason--effort-valid-p (effort)
  (or (string-empty-p effort)
      (and (string-match-p "\\`[0-9]+:[0-5][0-9]\\'" effort)
           (> (org-duration-to-minutes effort) 0))))

(defun org-reason-clarify-entry (disposition &optional options)
  "Clarify the entry at point using DISPOSITION and OPTIONS.
OPTIONS is a plist with :context, :effort, :person, :date, :next or :title.
This function is also a stable API for capture adapters and tests."
  (org-reason--require-entry)
  (unless (file-equal-p buffer-file-name (org-reason-path "inbox/inbox.org"))
    (user-error "Clarify from the inbox; use ordinary Org editing elsewhere"))
  (let* ((effort (or (plist-get options :effort) ""))
         (context (plist-get options :context))
         (date (plist-get options :date))
         (person (plist-get options :person))
         (props nil) destination state)
    (unless (org-reason--effort-valid-p effort) (user-error "Use effort H:MM, or leave it blank"))
    (when (and (member disposition '("calendar" "tickler"))
               (not (and date (org-reason--date-valid-p date))))
      (user-error "A genuine calendar date is required"))
    (when (and (equal disposition "delegate")
               (or (not person) (string-empty-p (string-trim person))))
      (user-error "Record who you are waiting for"))
    (when (and (equal disposition "project")
               (string-empty-p (string-trim (or (plist-get options :next) ""))))
      (user-error "A new active project needs a concrete first next action"))
    (pcase disposition
      ("next-action" (setq destination "gtd/actions.org" state "NEXT" props '(("OR_TYPE" . "action"))))
      ("done-now" (setq destination "gtd/actions.org" state "DONE" props '(("OR_TYPE" . "action"))))
      ("delegate" (setq destination "gtd/waiting.org" state "WAIT"
                        props (list '("OR_TYPE" . "action") (cons "OR_WAITING_FOR" person)
                                    (cons "OR_DELEGATED_ON" (org-reason--today)))))
      ("someday" (setq destination "gtd/someday.org" state "SOMEDAY" props '(("OR_TYPE" . "incubation"))))
      ("calendar" (setq destination "gtd/calendar.org" state "TODO" props '(("OR_TYPE" . "calendar"))))
      ("tickler" (setq destination "gtd/tickler.org" state "TODO" props '(("OR_TYPE" . "tickler"))))
      ("agenda" (setq destination "gtd/agendas.org" state "TODO"
                      props (list '("OR_TYPE" . "agenda") (cons "OR_PERSON" person))))
      ("project"
       (setq destination (concat "gtd/projects/" (org-reason--id-filename (org-entry-get nil "ID")) ".org")
             state "TODO" props '(("OR_TYPE" . "project")))
       (org-reason--ensure-file destination (or (plist-get options :title) (org-get-heading t t t t))))
      ((or "reference" "question" "observation" "hypothesis" "feeling" "failure")
       (setq destination (concat "knowledge/notes/" (org-reason--id-filename (org-entry-get nil "ID")) ".org")
             props (list (cons "OR_TYPE" disposition)))
       (org-reason--ensure-file destination (org-get-heading t t t t)))
      ("discard" (setq destination "archive/discarded.org" props '(("OR_TYPE" . "discarded"))))
      (_ (user-error "Unknown disposition: %s" disposition)))
    (unless (string-empty-p effort) (push (cons "EFFORT" effort) props))
    (let ((id (org-reason--move (org-reason-path destination) props state (and context (list context)))))
      (with-current-buffer (marker-buffer (org-reason--find-id id))
        (goto-char (org-reason--find-id id))
        (when (plist-get options :title)
          (org-edit-headline (org-reason--clean (plist-get options :title))))
        (when date (org-schedule nil date))
        (when (equal disposition "project")
          (org-reason--child (plist-get options :next) ""
                         (append '(("OR_TYPE" . "action"))
                                 (unless (string-empty-p effort) (list (cons "EFFORT" effort))))
                         "NEXT" (and context (list context))))
        (org-reason--save-buffer))
      id)))

(defun org-reason-clarify ()
  "Guide the GTD decision for the current inbox entry."
  (interactive)
  (org-reason--require-entry)
  (let* ((choice (completing-read
                  "Is it actionable? Choose where it belongs: "
                  '("next-action" "project" "delegate" "done-now" "calendar" "tickler"
                    "someday" "agenda" "reference" "question" "observation"
                    "hypothesis" "feeling" "failure" "discard") nil t))
         options)
    (when (member choice '("next-action" "project" "done-now" "calendar"))
      (setq options (plist-put options :title
                               (read-string (if (equal choice "project") "Desired outcome: " "Physical, visible next action: ")
                                            (org-get-heading t t t t)))))
    (when (equal choice "project")
      (setq options (plist-put options :next (read-string "First available physical action: "))))
    (when (member choice '("next-action" "project"))
      (setq options (plist-put options :context (completing-read "Context: " org-reason-contexts nil nil nil nil "@computer")))
      (setq options (plist-put options :effort (read-string "Estimated effort H:MM (optional): "))))
    (when (member choice '("delegate" "agenda"))
      (setq options (plist-put options :person (read-string "Who / meeting: "))))
    (when (member choice '("calendar" "tickler"))
      (setq options (plist-put options :date (org-read-date nil nil nil "Genuine date / bring-forward date: "))))
    (when (and (equal choice "done-now")
               (not (y-or-n-p "Have you actually completed this action? ")))
      (user-error "Leave it in the inbox, or clarify it as a next action"))
    (let ((id (org-reason-clarify-entry choice options)))
      (message "Clarified; original ID preserved")
      id)))

(defun org-reason-next-action (title &optional context effort reason)
  "Create a real next action TITLE, optionally linked to REASON."
  (interactive (list (read-string "Physical next action: ")
                     (completing-read "Context: " org-reason-contexts nil nil)
                     (read-string "Effort H:MM (optional): ")))
  (org-reason-initialize)
  (unless (org-reason--effort-valid-p (or effort "")) (user-error "Use effort H:MM"))
  (org-reason--append (org-reason-path "gtd/actions.org") title ""
                  (list '("OR_TYPE" . "action") (cons "OR_REASON" reason)
                        (cons "EFFORT" effort) (cons "OR_CREATED" (org-reason--now)))
                  "NEXT" (and context (list context))))

(defun org-reason-agenda ()
  "Show Org Reason commitments; dates retain ordinary Org semantics."
  (interactive)
  (org-reason-initialize)
  ;; The files are a setting of the command, not a `let' around it, so that
  ;; g in the agenda rebuilds from them too; as directories, they also pick
  ;; up projects added since.
  (let ((org-agenda-custom-commands
         `(("r" "Org Reason"
            ((agenda "") (todo "NEXT") (todo "WAIT")
             (tags "OR_TYPE=\"project\"/TODO") (todo "SOMEDAY"))
            ((org-agenda-files
              ',(list (org-reason-path "gtd/") (org-reason-path "gtd/projects/"))))))))
    (org-agenda nil "r")))

(defun org-reason--available-tree-p ()
  "Exclude actions beneath completed or incubated parents."
  (save-excursion
    (let ((available t))
      (while (org-up-heading-safe)
        (when (or (org-entry-is-done-p) (equal (org-get-todo-state) "SOMEDAY"))
          (setq available nil)))
      available)))

(defun org-reason-projects-without-next-action ()
  "Return active projects lacking NEXT, WAIT, or a dated commitment."
  (seq-filter
   (lambda (entry)
     (with-current-buffer (marker-buffer (plist-get entry :marker))
       (save-excursion
         (goto-char (plist-get entry :marker))
         (let ((root (point)) (covered nil))
           (org-map-entries
            (lambda ()
              (when (and (> (point) root) (org-reason--available-tree-p)
                         (not (org-entry-is-done-p))
                         (or (member (org-get-todo-state) '("NEXT" "WAIT"))
                             (and (equal (org-entry-get nil "OR_TYPE") "calendar")
                                  (or (org-entry-get nil "SCHEDULED")
                                      (org-entry-get nil "DEADLINE")))))
                (setq covered t))) nil 'tree)
           (not covered)))))
   (org-reason--entries "gtd" (lambda ()
                            (and (equal (org-entry-get nil "OR_TYPE") "project")
                                 (not (org-entry-is-done-p))
                                 (not (equal (org-get-todo-state) "SOMEDAY")))))))

(defun org-reason-engage (context minutes energy)
  "Filter available NEXT actions by CONTEXT, MINUTES and ENERGY.
Unknown effort/energy remains visible.  The final priority decision is yours."
  (interactive (list (completing-read "Context (blank = any): " org-reason-contexts nil nil)
                     (read-string "Minutes available (blank = any): ")
                     (completing-read "Energy (blank = any): " '("low" "medium" "high") nil t)))
  (unless (or (string-empty-p minutes) (string-match-p "\\`[0-9]+\\'" minutes))
    (user-error "Minutes must be a nonnegative integer or blank"))
  (let ((entries
         (org-reason--entries
          "gtd" (lambda ()
                  (and (equal (org-get-todo-state) "NEXT") (org-reason--available-tree-p)
                       (or (string-empty-p context) (member context (org-get-tags))
                           (member "@anywhere" (org-get-tags)))
                       (or (string-empty-p minutes) (not (org-entry-get nil "EFFORT"))
                           (<= (org-duration-to-minutes (org-entry-get nil "EFFORT"))
                               (string-to-number minutes)))
                       (or (string-empty-p energy) (not (org-entry-get nil "OR_ENERGY"))
                           (<= (or (cl-position (org-entry-get nil "OR_ENERGY") '("low" "medium" "high") :test #'equal) 0)
                               (or (cl-position energy '("low" "medium" "high") :test #'equal) 2))))))))
    (with-current-buffer (get-buffer-create "*Org Reason: engage*")
      (let ((inhibit-read-only t))
        (erase-buffer) (org-mode)
        (insert "#+title: Available next actions\n\nChoose by context, time, energy, then priority.\n\n")
        (dolist (entry entries)
          (insert (format "- [[id:%s][%s]] — %s; energy %s\n"
                          (plist-get entry :id) (plist-get entry :title)
                          (or (org-reason--property entry "EFFORT") "estimate unknown")
                          (or (org-reason--property entry "OR_ENERGY") "unknown"))))
        (unless entries (insert "No matching NEXT actions.\n"))
        (org-reason--view-setup
         (lambda () (interactive) (org-reason-engage context minutes energy)))))
    (pop-to-buffer "*Org Reason: engage*")))

(provide 'org-reason-gtd)
;;; org-reason-gtd.el ends here
