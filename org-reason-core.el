;;; org-reason-core.el --- Identity and local storage -*- lexical-binding: t; -*-
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; No network requests, external packages, or filesystem writes at load time.
;;; Code:
(require 'cl-lib)
(require 'org)
(require 'org-element)
(require 'org-id)
(require 'subr-x)
(require 'seq)

(defgroup org-reason nil
  "Capture, commitments, reasoning, and feedback."
  :group 'org)
(defcustom org-reason-directory (expand-file-name "~/org/reason/")
  "Private data directory.  Existing Org notes are never moved automatically."
  :type 'directory)
(defcustom org-reason-device (system-name)
  "Device recorded on new captures; set separately on each computer."
  :type 'string)
(defcustom org-reason-language "en"
  "Default language of newly written material, not the language being studied."
  :type 'string)
(defcustom org-reason-location ""
  "Optional capture location; blank means unknown."
  :type 'string)
(defcustom org-reason-python-command nil
  "Python 3 with PyYAML for the Reason Commons commands, or nil to find one.
Nil tries python3 then python, or on Windows the py launcher first, since
python3 there is often only a Microsoft Store placeholder.  Set an
absolute path, such as a virtual environment's python, to choose."
  :type '(choice (const :tag "Find automatically" nil) string))

(defun org-reason-python ()
  "Return the Python program to run, or signal a `user-error'."
  (or (if org-reason-python-command
          (executable-find org-reason-python-command)
        (seq-some #'executable-find
                  (if (eq system-type 'windows-nt)
                      '("py" "python" "python3")
                    '("python3" "python"))))
      (user-error "No Python 3 found; set `org-reason-python-command'")))

(defconst org-reason--todo-line
  "#+todo: TODO(t) NEXT(n) WAIT(w@) SOMEDAY(s) | DONE(d!) CANCELLED(c@)\n")

(defun org-reason-path (relative)
  "Resolve RELATIVE inside `org-reason-directory'."
  (expand-file-name relative (file-name-as-directory org-reason-directory)))

(defun org-reason--now () (format-time-string "%Y-%m-%dT%H:%M:%S%z"))
(defun org-reason--today () (format-time-string "%Y-%m-%d"))
(defun org-reason--id-filename (id)
  "Keep ID safe as a single filename component."
  (if (string-match-p "\\`[[:alnum:]_-]+\\'" id) id (secure-hash 'sha256 id)))
(defun org-reason--clean (text)
  "Return TEXT as a single-line property value."
  (string-trim (replace-regexp-in-string "[\n\r]+" " " (or text ""))))

(defun org-reason--ensure-directory (path)
  "Create PATH privately, without changing existing permissions."
  (unless (file-directory-p path)
    (let ((parent (file-name-directory (directory-file-name path))))
      (unless (or (equal parent path) (file-directory-p parent))
        (org-reason--ensure-directory parent)))
    (make-directory path t)
    (set-file-modes path #o700)))

(defun org-reason--ensure-file (relative title)
  "Create RELATIVE with TITLE only if absent; return its full path."
  (let ((path (org-reason-path relative)))
    (org-reason--ensure-directory (file-name-directory path))
    (unless (file-exists-p path)
      (with-temp-buffer
        (insert "#+title: " title "\n" org-reason--todo-line "#+startup: overview\n\n")
        (let ((coding-system-for-write 'utf-8-unix)) ; the same bytes on every OS
          (write-region (point-min) (point-max) path nil 'silent nil 'excl)))
      (set-file-modes path #o600))
    path))

(defun org-reason-initialize ()
  "Create the workspace idempotently.  Never replace existing files."
  (interactive)
  (org-reason--ensure-directory (expand-file-name org-reason-directory))
  (dolist (dir '("inbox/drop" "gtd/projects" "gtd/reviews" "knowledge/notes"
                 "knowledge/daily" "media" "learning/forecasts" "commons"
                 "archive"))
    (org-reason--ensure-directory (org-reason-path dir)))
  (dolist (spec '(("inbox/inbox.org" "Inbox — clarify later")
                  ("gtd/actions.org" "Single next actions")
                  ("gtd/waiting.org" "Waiting for")
                  ("gtd/someday.org" "Someday / Maybe")
                  ("gtd/agendas.org" "People and meetings")
                  ("gtd/calendar.org" "Day- and time-specific commitments")
                  ("gtd/tickler.org" "Bring forward on a genuine revisit date")
                  ("gtd/horizons.org" "Purpose, vision, goals, and areas of responsibility")
                  ("gtd/checklists.org" "Checklists")
                  ("learning/experiments.org" "Predictions and experiments")
                  ("learning/practice.org" "Practice with feedback")
                  ("learning/reflections.org" "Questions, feelings, and failure feedback")
                  ("archive/discarded.org" "Discarded captures — recoverable")))
    (org-reason--ensure-file (car spec) (cadr spec))))

(defun org-reason--buffer (file)
  "Visit FILE and refuse to overwrite concurrent changes."
  (let ((buffer (find-file-noselect file)))
    (with-current-buffer buffer
      (unless (verify-visited-file-modtime buffer)
        (if (buffer-modified-p)
            (user-error "File changed outside Emacs; reconcile %s first" file)
          (revert-buffer t t t)))
      (unless (derived-mode-p 'org-mode) (org-mode)))
    buffer))

(defun org-reason--append (file title body properties &optional state tags)
  "Append one identified heading to FILE; return its ID.
TITLE is one line, BODY is Org text, PROPERTIES is an alist.
STATE and TAGS use Org's ordinary TODO and tag machinery."
  (let ((id (or (cdr (assoc "ID" properties)) (org-id-new))))
    (with-current-buffer (org-reason--buffer file)
      (save-excursion
        (goto-char (point-max))
        (unless (bolp) (insert "\n"))
        (let ((start (point)))
          (atomic-change-group
            (insert "* " (if state (concat state " ") "")
                    (org-reason--clean title) "\n")
            (save-excursion
              (goto-char start)
              (org-entry-put nil "ID" id)
              (dolist (pair properties)
                (when (and (cdr pair) (not (string-empty-p (cdr pair))))
                  (org-entry-put nil (car pair) (org-reason--clean (cdr pair)))))
              (when tags (org-set-tags tags)))
            (goto-char (point-max))
            (insert (or body "") "\n\n"))))
      (save-buffer))
    (org-id-add-location id file)
    id))

(defun org-reason--files (&optional subdir)
  "Return Org files beneath SUBDIR of this workspace."
  (let ((root (org-reason-path (or subdir ""))))
    (when (file-directory-p root)
      (directory-files-recursively root "\\.org\\'"))))

(defun org-reason--find-id (id)
  "Resolve ID, including after a refile; return a marker or nil."
  (or (ignore-errors (org-id-find id 'marker))
      (catch 'found
        (dolist (file (org-reason--files))
          (with-current-buffer (org-reason--buffer file)
            (org-with-wide-buffer
             (goto-char (point-min))
             (let ((position (org-find-entry-with-id id)))
               (when position
                 (org-id-add-location id file)
                 (throw 'found (copy-marker position))))))))))

(defun org-reason-open-id (id)
  "Open the workspace object ID."
  (let ((marker (org-reason--find-id id)))
    (unless marker (user-error "Cannot find ID %s" id))
    (switch-to-buffer (marker-buffer marker))
    (goto-char marker)
    (org-fold-show-context 'link-search)))

(defun org-reason--entries (subdir predicate)
  "Return plists for headings under SUBDIR satisfying PREDICATE.
PREDICATE runs at the heading; no filesystem mutation is performed."
  (let (entries)
    (dolist (file (org-reason--files subdir))
      (with-current-buffer (org-reason--buffer file)
        (org-with-wide-buffer
         (org-map-entries
          (lambda ()
            (when (funcall predicate)
              (push (list :id (org-entry-get nil "ID")
                          :title (org-get-heading t t t t)
                          :state (org-get-todo-state)
                          :file file :marker (copy-marker (point))
                          :properties (org-entry-properties nil 'standard))
                    entries))) nil 'file))))
    (nreverse entries)))

(defun org-reason--property (entry property)
  (cdr (assoc property (plist-get entry :properties))))

(defun org-reason--require-entry ()
  "Require a heading in this workspace before modifying it."
  (unless (and (derived-mode-p 'org-mode) buffer-file-name
               (file-in-directory-p buffer-file-name (org-reason-path "")))
    (user-error "Place point on an Org Reason entry"))
  (org-back-to-heading t)
  (unless (org-entry-get nil "ID")
    (user-error "This heading has no stable ID")))

(defun org-reason--view-setup (&optional refresh)
  "Make the current Org buffer a read-only derived view.
q quits; g calls REFRESH when given.  The keys go in a map of this buffer's
own: `local-set-key' would change `org-mode-map', and so every Org buffer."
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map org-mode-map)
    (define-key map (kbd "q") #'quit-window)
    (when refresh (define-key map (kbd "g") refresh))
    (use-local-map map))
  (goto-char (point-min))
  (read-only-mode 1))

(defun org-reason--child (title body properties &optional state tags)
  "Append an identified child at the current heading; return its ID."
  (org-reason--require-entry)
  (let ((id (or (cdr (assoc "ID" properties)) (org-id-new)))
        (level (1+ (org-outline-level))))
    (save-excursion
      (org-end-of-subtree t t)
      (unless (bolp) (insert "\n"))
      (let ((start (point)))
        (atomic-change-group
          (insert (make-string level ?*) " " (if state (concat state " ") "")
                  (org-reason--clean title) "\n")
          (save-excursion
            (goto-char start)
            (org-entry-put nil "ID" id)
            (dolist (pair properties)
              (when (and (cdr pair) (not (string-empty-p (cdr pair))))
                (org-entry-put nil (car pair) (org-reason--clean (cdr pair)))))
            (when tags (org-set-tags tags)))
          (org-end-of-subtree t t)
          (insert (or body "") "\n\n"))))
    (save-buffer)
    (org-id-add-location id buffer-file-name)
    id))

(defun org-reason--date-valid-p (date)
  "Whether DATE is an actual YYYY-MM-DD calendar date."
  (and (string-match "\\`\\([0-9]\\{4\\}\\)-\\([0-9]\\{2\\}\\)-\\([0-9]\\{2\\}\\)\\'" date)
       (let ((year (string-to-number (match-string 1 date)))
             (month (string-to-number (match-string 2 date)))
             (day (string-to-number (match-string 3 date))))
         (condition-case nil
             (equal date (format-time-string "%Y-%m-%d" (encode-time 0 0 12 day month year)))
           (error nil)))))

(defun org-reason-file-follow (path _argument)
  "Open a root-relative reason-file:PATH even after its entry was refiled."
  (let ((file (org-reason-path path)))
    (unless (file-in-directory-p file (org-reason-path ""))
      (user-error "Media links must remain inside the workspace"))
    (org-open-file file)))

(org-link-set-parameters "reason-file" :follow #'org-reason-file-follow)

(defun org-reason--rebase-file-links (source destination)
  "Preserve relative file-link targets when this Org text moves files.
Only parsed links are changed: code examples and absolute links stay literal."
  (let (changes)
    (org-element-map (org-element-parse-buffer) 'link
      (lambda (link)
        (let ((path (org-element-property :path link))
              (raw (org-element-property :raw-link link))
              (search (org-element-property :search-option link)))
          (when (and (equal (org-element-property :type link) "file")
                     (not (file-name-absolute-p path)))
            (let* ((absolute (expand-file-name (org-link-unescape path) (file-name-directory source)))
                   (relative (file-relative-name absolute (file-name-directory destination)))
                   (replacement (concat "file:" (org-link-escape relative)
                                        (if search (concat "::" search) ""))))
              (save-excursion
                (goto-char (org-element-property :begin link))
                (when (search-forward raw (org-element-property :end link) t)
                  (push (list (match-beginning 0) (match-end 0) replacement) changes))))))))
    (dolist (change (sort changes (lambda (a b) (> (car a) (car b)))))
      (goto-char (nth 0 change))
      (delete-region (nth 0 change) (nth 1 change))
      (insert (nth 2 change)))))

(provide 'org-reason-core)
;;; org-reason-core.el ends here
