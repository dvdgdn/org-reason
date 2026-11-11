;;; org-reason-core.el --- Identity and local storage -*- lexical-binding: t; -*-
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; No network requests, external packages, or filesystem writes at load time.
;;; Code:
(require 'cl-lib)
(require 'org)
(require 'org-element)
(require 'org-id)
(require 'org-src)
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

(defconst org-reason--package-root
  (file-name-directory (or load-file-name buffer-file-name))
  "Directory containing Org Reason's code and bundled files.")

(defun org-reason--system-python ()
  (seq-some #'executable-find
            (if (eq system-type 'windows-nt) '("py" "python" "python3")
              '("python3" "python"))))

(defun org-reason-python ()
  "Return the Python program to run, or signal a `user-error'."
  (or (if org-reason-python-command
          (executable-find org-reason-python-command)
        (org-reason--system-python))
      (user-error "No Python 3 found; set `org-reason-python-command'")))

(defconst org-reason--todo-line
  "#+todo: TODO(t) NEXT(n) WAIT(w@) SOMEDAY(s) | DONE(d!) CANCELLED(c@)\n")

(defvar org-reason--root nil
  "Cache: (`org-reason-directory' . its canonical name).")

(defun org-reason--root ()
  "The workspace directory under one canonical name.
On Windows a directory can have two names, a short 8.3 one and the long
one, and Org's ID index records the long one; building every path from
the truename keeps one file from being visited under both."
  (unless (equal (car org-reason--root) org-reason-directory)
    (setq org-reason--root
          (cons org-reason-directory
                (file-name-as-directory (file-truename (expand-file-name org-reason-directory))))))
  (cdr org-reason--root))

(defun org-reason-path (relative)
  "Resolve RELATIVE inside `org-reason-directory'."
  (expand-file-name relative (org-reason--root)))

(defun org-reason--prefer-utf-8 ()
  "Save this workspace buffer as UTF-8 if its encoding is still undecided.
A file holding only ASCII is read as `undecided'; adding a non-ASCII
character then makes saving ask for a coding system wherever the default
is not UTF-8, as on Windows.  The line endings are kept."
  (when (and buffer-file-name
             (eq (coding-system-base buffer-file-coding-system) 'undecided)
             (file-in-directory-p buffer-file-name (org-reason--root)))
    (setq buffer-file-coding-system
          (coding-system-change-text-conversion buffer-file-coding-system 'utf-8))))

(defun org-reason--save-buffer ()
  "Save the current workspace buffer, as UTF-8 when undecided."
  (org-reason--prefer-utf-8)
  (save-buffer))

(defun org-reason--now () (format-time-string "%Y-%m-%dT%H:%M:%S%z"))
(defun org-reason--today () (format-time-string "%Y-%m-%d"))
(defun org-reason--id-filename (id)
  "Keep ID safe as a single filename component."
  (if (string-match-p "\\`[[:alnum:]_-]+\\'" id) id (secure-hash 'sha256 id)))
(defun org-reason--clean (text)
  "Return TEXT as a single-line property value."
  (org-reason--inert-file-locals
   (string-trim (replace-regexp-in-string "[\n\r]+" " " (or text "")))))

(defun org-reason--inert-file-locals (text)
  "Quote Emacs's file-local variable markers anywhere in TEXT."
  (let ((case-fold-search t))
    (replace-regexp-in-string
     "-\\*-" "-\\*-"
     (replace-regexp-in-string "Local Variables:" (lambda (match)
                                                     (concat (substring match 0 -1) "\\:"))
                                text t t)
     t t)))

(defun org-reason--literal-text (text)
  "Make TEXT inert as an Org example, keeping line breaks and indentation."
  (let ((text (replace-regexp-in-string "\r\n?" "\n" text)))
    (concat "#+begin_example\n"
            (org-escape-code-in-string (org-reason--inert-file-locals text))
            (unless (string-suffix-p "\n" text) "\n")
            "#+end_example\n")))

(defun org-reason--sha256-file (file)
  "Hash the literal bytes of FILE."
  (with-temp-buffer
    (set-buffer-multibyte nil)
    (insert-file-contents-literally file)
    (secure-hash 'sha256 (current-buffer))))

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
      (condition-case nil
          (with-temp-buffer
            (insert "#+title: " (org-reason--clean title) "\n" org-reason--todo-line "#+startup: overview\n\n")
            (let ((coding-system-for-write 'utf-8-unix))
              (write-region (point-min) (point-max) path nil 'silent nil 'excl))
            (set-file-modes path #o600))
        (file-already-exists nil)))
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
  (let* ((enable-local-variables nil)
         (enable-local-eval nil)
         (buffer (or (get-file-buffer file) (find-buffer-visiting file)
                     (find-file-noselect file))))
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
      (org-reason--save-buffer))
    (org-id-add-location id file)
    id))

(defun org-reason--files (&optional subdir)
  "Return Org files beneath SUBDIR of this workspace."
  (let ((root (org-reason-path (or subdir ""))))
    (when (file-directory-p root)
      (let ((drop (directory-file-name (org-reason-path "inbox/drop"))))
        (unless (equal (directory-file-name root) drop)
          (seq-filter #'file-regular-p
                      (directory-files-recursively
                       root "\\.org\\'" nil
                       (lambda (dir) (not (equal (directory-file-name dir) drop))))))))))

(defun org-reason--scan-file (file function)
  "Call FUNCTION at the start of FILE, without visiting it.
Read live edits when present.  For an unmodified stale buffer, read the
current disk contents without reverting the user's buffer."
  (let ((buffer (or (get-file-buffer file) (find-buffer-visiting file))))
    (if (and buffer (or (buffer-modified-p buffer)
                        (verify-visited-file-modtime buffer)))
        (with-current-buffer buffer
          (org-with-wide-buffer
           (goto-char (point-min))
           (funcall function)))
      (with-temp-buffer
        (setq default-directory (file-name-directory file))
        (when (condition-case nil (insert-file-contents file) (file-missing nil))
          (let ((org-inhibit-startup t) (org-element-cache-persistent nil))
            (delay-mode-hooks (org-mode)))
          (goto-char (point-min))
          (funcall function))))))

(defun org-reason--find-id (id)
  "Resolve ID, including after a refile; return a marker or nil."
  (or (ignore-errors (org-id-find id 'marker))
      (catch 'found
        (dolist (file (org-reason--files))
          (when (org-reason--scan-file file (lambda () (org-find-entry-with-id id)))
            (with-current-buffer (org-reason--buffer file)
              (org-with-wide-buffer
               (goto-char (point-min))
               (when-let ((position (org-find-entry-with-id id)))
                 (org-id-add-location id file)
                 (throw 'found (copy-marker position))))))))))

(defun org-reason-open-id (id)
  "Open the workspace object ID."
  (let ((marker (org-reason--find-id id)))
    (unless marker (user-error "Cannot find ID %s" id))
    (switch-to-buffer (marker-buffer marker))
    (goto-char marker)
    (org-fold-show-context 'link-search)))

(defun org-reason--entries (subdir predicate &optional extra)
  "Return plists for headings under SUBDIR satisfying PREDICATE.
PREDICATE and optional EXTRA run at the heading.  EXTRA receives the file
name and returns additional plist fields.  Results contain only values."
  (let (entries)
    (dolist (file (org-reason--files subdir))
      (org-reason--scan-file
       file
       (lambda ()
         (org-map-entries
          (lambda ()
            (when (funcall predicate)
              (push (append (list :id (org-entry-get nil "ID")
                                  :title (org-get-heading t t t t)
                                  :state (org-get-todo-state)
                                  :file file
                                  :tags (org-get-tags)
                                  :properties (org-entry-properties nil 'standard))
                            (when extra (funcall extra file)))
                    entries)))))))
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
  (set-buffer-modified-p nil)
  (read-only-mode 1))

(defun org-reason--insert-child (title body properties &optional state tags)
  "Insert an identified child at point without saving; return its ID."
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
            ;; Canonical directory names: on Windows one directory can have
            ;; a short and a long name, and mixing them breaks the result.
            (let* ((absolute (expand-file-name (org-link-unescape path)
                                               (file-truename (file-name-directory source))))
                   (relative (file-relative-name absolute
                                                 (file-truename (file-name-directory destination))))
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
