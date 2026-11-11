;;; org-reason-reasoning.el --- A native Reason Commons interface -*- lexical-binding: t; -*-
;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Code:
(require 'org-reason-core)
(require 'org-reason-gtd)
(require 'json)
(require 'browse-url)

(defcustom org-reason-participant nil
  "Your explicit participant ID, or nil to choose from each commons."
  :type '(choice (const nil) string) :group 'org-reason)
(defvar-local org-reason--commons-view-file nil)

(defun org-reason--commons-path (slug)
  (unless (string-match-p "\\`[[:alnum:]_-]+\\'" slug) (user-error "Use a simple commons name, without slashes"))
  (org-reason-path (concat "commons/" slug "/reason-commons.yaml")))

(defun org-reason--commons-slug (file)
  (file-name-nondirectory (directory-file-name (file-name-directory file))))

(defun org-reason--choose-commons ()
  (if org-reason--commons-view-file org-reason--commons-view-file
    (let* ((root (org-reason-path "commons"))
           (files (when (file-directory-p root) (directory-files-recursively root "\\`reason-commons\\.yaml\\'")))
           (choices (mapcar (lambda (file) (cons (org-reason--commons-slug file) file)) files)))
      (unless choices (user-error "Create a commons with M-x org-reason-commons-new"))
      (cdr (assoc (completing-read "Commons: " choices nil t) choices)))))

(defun org-reason--rc-call (file request)
  "Run a structured local REQUEST on FILE.  No shell or network is involved."
  (let ((visiting (find-buffer-visiting file)))
    (when (and visiting (buffer-modified-p visiting)) (user-error "Save your YAML edits before using the reasoning commands"))
    (with-temp-buffer
      (insert (json-encode request))
      (let* ((process-environment (cons "PYTHONIOENCODING=utf-8" process-environment))
             ;; The script reads and writes UTF-8; Windows' default process
             ;; coding would garble anything beyond ASCII.
             (coding-system-for-read 'utf-8-unix)
             (coding-system-for-write 'utf-8-unix)
             (status (call-process-region (point-min) (point-max) (org-reason-python) t t nil
                                          (expand-file-name "org_reason_commons.py" org-reason--package-root)
                                          "--file" file)))
        (unless (eq status 0) (user-error "%s" (string-trim (buffer-string))))
        (let* ((json-object-type 'hash-table) (json-array-type 'list) (json-key-type 'string)
               (result (json-read-from-string (buffer-string))))
          (when (and visiting (gethash "saved" result))
            (with-current-buffer visiting (revert-buffer t t t)))
          (when (gethash "view_error" result)
            (display-warning 'org-reason
                             (concat "YAML saved; repair views: " (gethash "view_error" result))))
          (when (gethash "history_warning" result)
            (display-warning 'org-reason
                             (concat "YAML saved with its before-image, but the event log failed: "
                                     (gethash "history_warning" result))))
          result)))))

(defun org-reason-setup-python (directory)
  "Install the bundled Reason Commons requirements in a venv in DIRECTORY.
Set and save `org-reason-python-command' after installation succeeds."
  (interactive (list (read-directory-name
                      "Reason Commons virtual environment: "
                      (expand-file-name "org-reason-venv" user-emacs-directory))))
  (let* ((base (or (org-reason--system-python) (user-error "Install Python 3 first")))
         (directory (expand-file-name directory))
         (python (expand-file-name (if (eq system-type 'windows-nt) "Scripts/python.exe" "bin/python")
                                   directory))
         (requirements (expand-file-name "requirements.txt" org-reason--package-root))
         (log (get-buffer-create "*Org Reason: Python setup*")))
    (unless (file-readable-p requirements) (user-error "Cannot read %s" requirements))
    (with-current-buffer log (erase-buffer))
    (unless (and (or (file-exists-p (expand-file-name "pyvenv.cfg" directory))
                     (eq 0 (call-process base nil (list log t) nil "-m" "venv" directory)))
                 (file-executable-p python)
                 (eq 0 (call-process python nil (list log t) nil "-m" "pip" "install" "-r" requirements)))
      (display-buffer log)
      (user-error "Python setup failed; see the setup buffer"))
    (customize-save-variable 'org-reason-python-command python)
    (message "Reason Commons Python set to %s" python)))

(defun org-reason--rc-inspect (file) (org-reason--rc-call file '(("op" . "inspect"))))
(defun org-reason--rc-actor (state &optional allow-assistant)
  (let* ((people (gethash "participants" state))
         (keys (hash-table-keys people)))
    (if (and org-reason-participant (gethash org-reason-participant people)) org-reason-participant
      (completing-read "Record your contribution as: "
                       (if allow-assistant (append keys '("assistant")) keys) nil t))))

(defun org-reason--rc-items (state &optional nodes-only)
  (let (items)
    (maphash (lambda (tree data)
               (dolist (item (append (gethash "nodes" data) (unless nodes-only (gethash "links" data))))
                 (push (list :tree tree :item item) items))) (gethash "trees" state))
    (nreverse items)))

(defun org-reason--rc-choose-item (state &optional nodes-only)
  (let ((choices (mapcar
                  (lambda (entry)
                    (let ((item (plist-get entry :item)))
                      (cons (format "%s · %s · %s [%s]"
                                    (plist-get entry :tree) (gethash "status" item "proposed")
                                    (or (gethash "text" item) (gethash "relation" item)) (gethash "id" item))
                            (gethash "id" item))))
                  (org-reason--rc-items state nodes-only))))
    (unless choices (user-error "No reasoning items yet"))
    (cdr (assoc (completing-read "Item: " choices nil t) choices))))

(defun org-reason--rc-annotations (item slug)
  "Insert attribution, reservations and cross-tree traces for ITEM."
  (when (gethash "accepted_by" item)
    (insert "Endorsed by: " (string-join (gethash "accepted_by" item) ", ") "\n"))
  (insert "Origin: " (mapconcat (lambda (c) (concat (gethash "by" c) " (" (gethash "mode" c) ")"))
                                (gethash "contributions" item) ", ") "\n")
  (dolist (field '("assumptions" "challenges"))
    (dolist (note (gethash field item))
      (insert "- " field ": " (gethash "text" note) " — " (gethash "by" note) "\n")))
  (dolist (field '("addresses" "derived_from" "implements"))
    (when (gethash field item)
      (insert "- " field ": " (mapconcat (lambda (id) (format "[[rc:%s/%s][%s]]" slug id id))
                                          (gethash field item) ", ") "\n"))))

(defun org-reason-commons-new (slug project participant name)
  "Create a real v1 commons, with the participant explicitly named."
  (interactive (list (read-string "Short commons directory name: ") (read-string "Goal / system: ")
                     (read-string "Your participant ID: " nil nil "self")
                     (read-string "Your display name: ")))
  (org-reason-initialize)
  (let ((file (org-reason--commons-path slug)))
    (org-reason--ensure-directory (file-name-directory file))
    (org-reason--rc-call file (list '("op" . "new") (cons "project" project)
                               (cons "participant" participant) (cons "name" name)))
    (org-reason-reasoning-view file)))

(defun org-reason-node-add ()
  "Capture one proposed node in any of the six native tree families."
  (interactive)
  (let* ((file (org-reason--choose-commons)) (inspection (org-reason--rc-inspect file))
         (state (gethash "state" inspection))
         (kinds (gethash "tree_kinds" inspection))
         (tree (completing-read "Tree question: " kinds nil t nil nil (gethash "active_tree" state)))
         (kind (completing-read "Role in this tree: " (gethash tree kinds) nil t))
         (text (if (use-region-p) (buffer-substring-no-properties (region-beginning) (region-end))
                 (read-string "Statement: "))))
    (org-reason--rc-call file (list '("op" . "add-node") (cons "tree" tree) (cons "kind" kind) (cons "text" text)
                               (cons "by" (org-reason--rc-actor state))
                               (cons "expected_sha256" (gethash "sha256" inspection))))
    (org-reason-reasoning-view file)))

(defun org-reason-link-add ()
  "Propose a relationship; multiple sources explicitly mean AND."
  (interactive)
  (let* ((file (org-reason--choose-commons)) (inspection (org-reason--rc-inspect file))
         (state (gethash "state" inspection))
         (tree (completing-read "Tree: " (hash-table-keys (gethash "trees" state)) nil t))
         (nodes (gethash "nodes" (gethash tree (gethash "trees" state))))
         (choices (mapcar (lambda (n) (cons (format "%s [%s]" (gethash "text" n) (gethash "id" n)) (gethash "id" n))) nodes))
         (chosen (completing-read-multiple "Source conditions (comma-separated; together = AND): " choices nil t))
         (sources (mapcar (lambda (choice) (cdr (assoc choice choices))) chosen))
         (target (cdr (assoc (completing-read "Target: " choices nil t) choices)))
         (relations (delete-dups (append (gethash "relation_suggestions" inspection)
                                          (mapcar (lambda (link) (gethash "relation" link))
                                                  (gethash "links" (gethash tree (gethash "trees" state)))))))
         (relation (completing-read "Source → target relation: " relations)))
    (org-reason--rc-call file (list '("op" . "add-link") (cons "tree" tree)
                               (cons "from" (vconcat sources)) (cons "to" target) (cons "relation" relation)
                               (cons "by" (org-reason--rc-actor state))
                               (cons "expected_sha256" (gethash "sha256" inspection))))
    (org-reason-reasoning-view file)))

(defun org-reason-item-accept ()
  "Explicitly endorse the exact displayed item; acceptance is not empirical proof."
  (interactive)
  (let* ((file (org-reason--choose-commons)) (inspection (org-reason--rc-inspect file))
         (state (gethash "state" inspection)) (id (org-reason--rc-choose-item state))
         (entry (seq-find (lambda (e) (equal (gethash "id" (plist-get e :item)) id)) (org-reason--rc-items state)))
         (item (plist-get entry :item)))
    (with-help-window "*Org Reason: endorsement*"
      (princ "Endorse this identified formulation as your current reasoning.\nThis does not mark it empirically verified or approve an implementation.\n\n")
      (princ (json-encode item)))
    (unless (yes-or-no-p "Endorse this displayed item? ") (user-error "No endorsement recorded"))
    (org-reason--rc-call file (list '("op" . "accept") (cons "id" id) (cons "by" (org-reason--rc-actor state))
                               (cons "expected_sha256" (gethash "sha256" inspection))))
    (org-reason-reasoning-view file)))

(defun org-reason-item-annotate (operation)
  "Add a challenge, assumption, or reasoning backlog entry."
  (interactive (list (completing-read "Add: " '("challenge" "assumption" "backlog") nil t)))
  (let* ((file (org-reason--choose-commons)) (inspection (org-reason--rc-inspect file))
         (state (gethash "state" inspection)) (id (org-reason--rc-choose-item state))
         (text (read-string (concat operation ": "))))
    (org-reason--rc-call file (list (cons "op" operation) (cons "id" id)
                               (cons (if (equal operation "backlog") "work" "text") text)
                               (cons "by" (org-reason--rc-actor state))
                               (cons "expected_sha256" (gethash "sha256" inspection))))
    (org-reason-reasoning-view file)))

(defun org-reason-reasoning-view (file)
  "Show FILE as a derived Org view with all statuses and AND links."
  (interactive (list (org-reason--choose-commons)))
  (let* ((inspection (org-reason--rc-inspect file)) (state (gethash "state" inspection))
         (slug (org-reason--commons-slug file)))
    (with-current-buffer (get-buffer-create (format "*Commons: %s*" slug))
      (let ((inhibit-read-only t))
        (erase-buffer) (org-mode)
        (setq-local org-reason--commons-view-file file)
        (insert "#+title: " (gethash "project" state) "\n\n"
                "Derived view. YAML is canonical. Proposed and disputed claims remain visible.\n"
                "Keys under C-c r: t n node; t l link; t a endorse; t ? challenge / assumption.\n")
        (maphash
         (lambda (tree data)
           (insert "\n* " (replace-regexp-in-string "_" " " tree) "\n")
           (dolist (node (gethash "nodes" data))
             (insert (format "** [%s] %s\n:PROPERTIES:\n:CUSTOM_ID: %s\n:END:\n%s\n"
                             (gethash "status" node "proposed") (gethash "kind" node)
                             (gethash "id" node) (gethash "text" node)))
             (org-reason--rc-annotations node slug))
           (insert "** Relationships\n")
           (dolist (link (gethash "links" data))
             (insert (format "*** [%s] %s\n:PROPERTIES:\n:CUSTOM_ID: %s\n:END:\n(%s) → %s\n"
                             (gethash "status" link "proposed") (gethash "relation" link) (gethash "id" link)
                             (mapconcat (lambda (id) (format "[[rc:%s/%s][%s]]" slug id id)) (gethash "from" link) " AND ")
                             (format "[[rc:%s/%s][%s]]" slug (gethash "to" link) (gethash "to" link))))
             (org-reason--rc-annotations link slug))
           (insert "** Unfinished reasoning (separate from commitments)\n")
           (dolist (task (gethash "backlog" data))
             (insert "- " (gethash "ref" task) ": " (gethash "work" task) "\n")))
         (gethash "trees" state))
        (org-reason--view-setup
         (lambda () (interactive) (org-reason-reasoning-view org-reason--commons-view-file)))))
    (pop-to-buffer (format "*Commons: %s*" slug))))

(defun org-reason-reasoning-diagram ()
  "Generate and open the upstream offline accepted-reasoning SVG views."
  (interactive)
  (let* ((file (org-reason--choose-commons)) (inspection (org-reason--rc-inspect file))
         (tree (gethash "active_tree" (gethash "state" inspection)))
         (result (org-reason--rc-call file '(("op" . "views"))))
         (diagram (expand-file-name (concat "diagrams/current/" tree ".html") (gethash "output" result))))
    (if (file-exists-p diagram) (browse-url-of-file diagram)
      (message "No accepted items in this tree yet; the Org view shows proposals"))))

(defun org-reason-rc-follow (path _argument)
  "Follow rc:COMMONS/ITEM using the same canonical YAML."
  (unless (string-match "\\`\\([^/]+\\)/\\(.+\\)\\'" path) (user-error "Use rc:commons/item-id"))
  (let ((file (org-reason--commons-path (match-string 1 path))) (id (match-string 2 path)))
    (org-reason-reasoning-view file)
    (goto-char (point-min))
    (unless (re-search-forward (concat "^:CUSTOM_ID: " (regexp-quote id) "$") nil t) (user-error "Item not found"))
    (org-back-to-heading t) (org-fold-show-context 'link-search)))

(defun org-reason-node-action ()
  "Make one GTD reminder for a Transition Tree action, preserving its rc link."
  (interactive)
  (let* ((file (org-reason--choose-commons)) (state (gethash "state" (org-reason--rc-inspect file)))
         (id (org-reason--rc-choose-item state t))
         (entry (seq-find (lambda (e) (equal (gethash "id" (plist-get e :item)) id)) (org-reason--rc-items state t)))
         (node (plist-get entry :item))
         (ref (concat (org-reason--commons-slug file) "/" id))
         (existing (car (org-reason--entries "gtd" (lambda () (equal (org-entry-get nil "OR_RC_REF") ref))))))
    (unless (and (equal (plist-get entry :tree) "transition") (equal (gethash "kind" node) "action"))
      (user-error "Choose a Transition Tree action"))
    (if existing (org-reason-open-id (plist-get existing :id))
      (let* ((context (completing-read "Context: " org-reason-contexts nil nil))
             (task (org-reason-next-action (gethash "text" node) context nil (concat "rc:" ref))))
        (org-reason-open-id task)
        (org-entry-put nil "OR_RC_REF" ref)
        (org-reason--save-buffer)))))

(org-link-set-parameters "rc" :follow #'org-reason-rc-follow)
(provide 'org-reason-reasoning)
;;; org-reason-reasoning.el ends here
