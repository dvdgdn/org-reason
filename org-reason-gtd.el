;;; org-reason-gtd.el --- GTD clarification and action views -*- lexical-binding: t; -*-
;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Code:
(require 'org-reason-capture)
(require 'org-agenda)
(require 'org-clock)

(defvar org-time-was-given) ; dynamically bound for org-read-date

(defcustom org-reason-contexts '("@computer" "@calls" "@home" "@work" "@errands" "@anywhere")
  "Contexts available when clarifying an action."
  :type '(repeat string) :group 'org-reason)

(defun org-reason--move (destination transform &optional alternatives)
  "Move this subtree to DESTINATION after applying TRANSFORM to a copy.
A saved destination carries the source path and digest.  A retry can
finish removing the same source without re-creating the destination."
  (org-reason--require-entry)
  (let* ((source (current-buffer))
         (source-file buffer-file-name)
         (relative-source (file-relative-name source-file (org-reason--root)))
         (id (org-entry-get nil "ID"))
         (start (point))
         (end (save-excursion (org-end-of-subtree t t) (point)))
         (text (buffer-substring-no-properties start end))
         (digest (secure-hash 'sha256 text)))
    (when (file-equal-p source-file destination)
      (user-error "Source and destination must differ"))
    (unless (verify-visited-file-modtime source)
      (user-error "Inbox or actions file changed on disk; reconcile it first"))
    (dolist (file alternatives)
      (when (and (not (equal file destination)) (file-exists-p file)
                 (org-reason--scan-file file (lambda () (org-find-entry-with-id id))))
        (user-error "ID %s already exists in %s; inspect it or retry the original disposition"
                    id (file-relative-name file (org-reason--root)))))
    (with-current-buffer (org-reason--buffer destination)
      (org-with-wide-buffer
       (goto-char (point-min))
       (let ((existing (org-find-entry-with-id id)))
         (if existing
             (progn
               (goto-char existing)
               (unless (and (equal (org-entry-get nil "OR_MOVE_SOURCE") relative-source)
                            (equal (org-entry-get nil "OR_MOVE_SHA256") digest))
                 (user-error "ID %s already exists in the destination; reconcile both entries" id))
               (org-reason--save-buffer))
           (let ((prepared
                  (with-temp-buffer
                    (insert org-reason--todo-line text)
                    (delay-mode-hooks (org-mode))
                    (goto-char (point-min))
                    (outline-next-heading)
                    (org-entry-put nil "OR_MOVE_SOURCE" relative-source)
                    (org-entry-put nil "OR_MOVE_SHA256" digest)
                    (funcall transform)
                    (save-excursion (org-reason--rebase-file-links source-file destination))
                    (buffer-substring-no-properties (line-beginning-position) (point-max)))))
             (atomic-change-group
               (goto-char (point-max))
               (unless (bolp) (insert "\n"))
               (insert prepared "\n")
               (org-reason--save-buffer)))))))
    (with-current-buffer source
      (unless (and (verify-visited-file-modtime source)
                   (<= end (point-max))
                   (equal text (buffer-substring-no-properties start end)))
        (user-error "Source changed during the move; reconcile both entries"))
      (atomic-change-group
        (delete-region start end)
        (org-reason--save-buffer)))
    (org-id-add-location id destination)
    id))

(defun org-reason--clarification-destinations (id)
  "Return the possible destination paths for an inbox capture ID."
  (mapcar #'org-reason-path
          (append '("gtd/actions.org" "gtd/waiting.org" "gtd/someday.org"
                    "gtd/calendar.org" "gtd/tickler.org" "gtd/agendas.org" "archive/discarded.org")
                  (let ((name (concat (org-reason--id-filename id) ".org")))
                    (list (concat "gtd/projects/" name) (concat "knowledge/notes/" name))))))

(defun org-reason--calendar-date-valid-p (date)
  (and (stringp date)
       (string-match-p "\\`[0-9-]\\{10\\}\\(?: \\(?:[01][0-9]\\|2[0-3]\\):[0-5][0-9]\\)?\\'" date)
       (org-reason--date-valid-p (substring date 0 10))))

(defun org-reason--effort-valid-p (effort)
  (or (string-empty-p effort)
      (and (string-match-p "\\`[0-9]+:[0-5][0-9]\\'" effort)
           (> (org-duration-to-minutes effort) 0))))

(defun org-reason-clarify-entry (disposition &optional options)
  "Clarify the entry at point using DISPOSITION and OPTIONS.
OPTIONS is a plist with :context, :effort, :person, :date, :next or :title.
A calendar :date accepts YYYY-MM-DD or YYYY-MM-DD HH:MM; tickler is date-only.
This function is also a stable API for capture adapters and tests."
  (org-reason--require-entry)
  (unless (org-reason--inbox-file-p buffer-file-name)
    (user-error "Clarify from the inbox; use ordinary Org editing elsewhere"))
  (let* ((effort (or (plist-get options :effort) ""))
         (context (plist-get options :context))
         (date (plist-get options :date))
         (person (plist-get options :person))
         (props nil) destination state)
    (unless (org-reason--effort-valid-p effort) (user-error "Use effort H:MM, or leave it blank"))
    (pcase disposition
      ("calendar"
       (unless (org-reason--calendar-date-valid-p date)
         (user-error "Use a real calendar date, optionally followed by HH:MM")))
      ("tickler"
       (unless (and (stringp date) (org-reason--date-valid-p date))
         (user-error "Use a real date for the tickler"))))
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
    (let* ((file (org-reason-path destination))
           (tags (and context (list context)))
           child-id
           (id
            (org-reason--move
             file
             (lambda ()
               (dolist (pair props)
                 (org-entry-put nil (car pair) (org-reason--clean (cdr pair))))
               (org-entry-put nil "OR_CLARIFIED" (org-reason--now))
               (let ((org-inhibit-logging t))
                 (org-todo (or state 'none))
                 (when date (org-schedule nil date)))
               (when-let ((title (plist-get options :title)))
                 (org-edit-headline (org-reason--clean title)))
               (when tags (org-set-tags (delete-dups (append (org-get-tags nil t) tags))))
               (when (equal disposition "project")
                 (setq child-id
                       (org-reason--insert-child
                        (plist-get options :next) ""
                        (append '(("OR_TYPE" . "action"))
                                (unless (string-empty-p effort) (list (cons "EFFORT" effort))))
                        "NEXT" tags))))
             (org-reason--clarification-destinations (org-entry-get nil "ID")))))
      (when child-id (org-id-add-location child-id file))
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
    (pcase choice
      ("calendar"
       (let (org-time-was-given)
         (setq options (plist-put options :date
                                  (org-read-date t nil nil "Commitment date and optional time: ")))))
      ("tickler"
       (setq options (plist-put options :date (org-read-date nil nil nil "Bring-forward date: ")))))
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

(defun org-reason--stalled-project-p ()
  "Whether the current project is active without a usable commitment."
  (and (equal (org-entry-get nil "OR_TYPE") "project")
       (not (org-entry-is-done-p))
       (not (equal (org-get-todo-state) "SOMEDAY"))
       (let ((root (point)))
         (not (catch 'covered
                (org-map-entries
                 (lambda ()
                   (when (and (> (point) root) (org-reason--available-tree-p)
                              (not (org-entry-is-done-p))
                              (or (member (org-get-todo-state) '("NEXT" "WAIT"))
                                  (and (equal (org-entry-get nil "OR_TYPE") "calendar")
                                       (or (org-entry-get nil "SCHEDULED")
                                           (org-entry-get nil "DEADLINE")))))
                     (throw 'covered t)))
                 nil 'tree)
                nil)))))

(defun org-reason-projects-without-next-action ()
  "Return active projects lacking NEXT, WAIT, or a dated commitment."
  (org-reason--entries "gtd" #'org-reason--stalled-project-p))

(defun org-reason-archive-actions ()
  "Move completed single actions to archive/actions.org, preserving their IDs."
  (interactive)
  (org-reason-initialize)
  (let ((destination (org-reason--ensure-file "archive/actions.org" "Completed single actions"))
        (count 0))
    (with-current-buffer (org-reason--buffer (org-reason-path "gtd/actions.org"))
      (org-with-wide-buffer
       (dolist (marker (delq nil (org-map-entries
                                  (lambda ()
                                    (when (and (= (org-outline-level) 1)
                                               (org-entry-is-done-p)
                                               (org-entry-get nil "ID"))
                                      (point-marker))))))
         (goto-char marker)
         (org-reason--move destination
                           (lambda () (org-entry-put nil "OR_ARCHIVED" (org-reason--now))))
         (cl-incf count))))
    (message "Archived %d completed actions" count)
    count))

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
