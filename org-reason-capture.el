;;; org-reason-capture.el --- Capture before classifying -*- lexical-binding: t; -*-
;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Code:
(require 'org-reason-core)
(require 'org-capture)
(require 'org-protocol)
(require 'url-util)

(defcustom org-reason-capture-key "r"
  "Optional org-capture template key; an existing template is never replaced."
  :type 'string :group 'org-reason)
(defcustom org-reason-inbox-per-device nil
  "Whether this computer writes to its own inbox file.
Set a distinct, stable `org-reason-device' on each computer sharing records."
  :type 'boolean :group 'org-reason)
(defvar org-reason--installed-template nil)
(defvar org-reason--installed-protocol nil)

(defun org-reason--capture-properties (&optional method source)
  (list (cons "OR_CAPTURED" (org-reason--now))
        (cons "OR_DEVICE" org-reason-device)
        (cons "OR_METHOD" (or method "manual"))
        (cons "OR_LANGUAGE" org-reason-language)
        (cons "OR_LOCATION" org-reason-location)
        (cons "OR_PRIVACY" "private")
        (cons "OR_SOURCE" source)))

(defun org-reason--capture-file ()
  "Return the writable inbox for this device, creating it if needed."
  (if org-reason-inbox-per-device
      (let ((device (string-trim org-reason-device)))
        (when (string-empty-p device) (user-error "Set org-reason-device first"))
        (let ((label (replace-regexp-in-string "[^a-z0-9_-]" "-" (downcase device))))
          (org-reason--ensure-file
           (concat "inbox/device-" (truncate-string-to-width label 24) "-"
                   (secure-hash 'sha256 device) ".org")
           (concat "Inbox — " device))))
    (org-reason-path "inbox/inbox.org")))

(defun org-reason--inbox-file-p (file)
  "Whether FILE is a legacy or per-device inbox."
  (and (equal (file-name-directory (file-truename file)) (org-reason-path "inbox/"))
       (let ((name (file-name-nondirectory file)))
         (or (equal name "inbox.org")
             (string-match-p "\\`device-[-a-z0-9_]+-[0-9a-f]\\{64\\}\\.org\\'" name)))))

(defun org-reason-capture-text (text &optional title method source)
  "Save plain TEXT immediately and return the capture ID.
TITLE, METHOD and SOURCE are optional; classification is not required."
  (org-reason--capture-plain-text text title method source nil))

(defun org-reason--capture-title (title text)
  "Make a single-line headline from TITLE or the first line of TEXT."
  (let ((line (or (and title (not (string-blank-p title)) title)
                  (truncate-string-to-width (car (split-string (string-trim text) "[\n\r]"))
                                            90 nil nil "…"))))
    ;; Keep bracket links and inline Babel constructs inert in copied titles.
    (replace-regexp-in-string
     (regexp-opt '("[[" "{{{" "src_" "call_"))
     (lambda (token) (concat (substring token 0 -1) "\u2060" (substring token -1)))
     (org-reason--clean line) t t)))

(defun org-reason--capture-plain-text (text title method source properties)
  (when (string-empty-p (string-trim text)) (user-error "Nothing to capture"))
  (org-reason-initialize)
  (org-reason--append
   (org-reason--capture-file)
   (org-reason--capture-title title text)
   (org-reason--literal-text text)
   (append properties (org-reason--capture-properties method source))))

(defun org-reason-capture (text)
  "Capture the region, or a quick thought, without classification."
  (interactive (list (if (use-region-p)
                         (buffer-substring-no-properties (region-beginning) (region-end))
                       (read-string "Capture: "))))
  (let ((id (org-reason-capture-text text nil "manual"
                                 (and buffer-file-name (abbreviate-file-name buffer-file-name)))))
    (message "Captured %s" id)
    id))

(defun org-reason-inbox ()
  "Open an inbox.  With multiple device inboxes, offer a choice."
  (interactive)
  (org-reason-initialize)
  (let* ((local (org-reason--capture-file))
         (files (seq-filter #'org-reason--inbox-file-p (org-reason--files "inbox")))
         (choices (mapcar (lambda (file)
                            (cons (if (equal file local)
                                      (concat "This device — " (file-name-nondirectory file))
                                    (file-name-nondirectory file))
                                  file))
                          (cons local (delete local files)))))
    (switch-to-buffer
     (org-reason--buffer
      (if (cdr choices)
          (cdr (assoc (completing-read "Inbox: " choices nil t nil nil (caar choices)) choices))
        local)))))

(defun org-reason--template ()
  "Build a deferred-classification Org capture template."
  (concat "* %?\n:PROPERTIES:\n:ID: " (org-id-new)
          "\n:OR_CAPTURED: " (org-reason--now)
          "\n:OR_DEVICE: " (org-reason--clean org-reason-device)
          "\n:OR_METHOD: org-capture\n:OR_LANGUAGE: " (org-reason--clean org-reason-language)
          "\n:OR_PRIVACY: private\n:END:\n"))

(defun org-reason--template-initial ()
  "Insert the selection after Org has expanded the capture template."
  (let ((initial (plist-get org-store-link-plist :initial))
        (annotation (org-reason--clean (org-capture-get :annotation))))
    (save-excursion
      (goto-char (point-max))
      (unless (bolp) (insert "\n"))
      (unless (string-empty-p annotation) (insert annotation "\n"))
      (when (and initial (not (string-empty-p initial)))
        (insert (org-reason--literal-text initial))))))

(defun org-reason--protocol (info)
  "Receive browser capture INFO through the reason-capture protocol."
  (let ((body (plist-get info :body)))
    (org-reason-capture-text
     (if (and body (not (string-blank-p body))) body (or (plist-get info :url) ""))
     (plist-get info :title) "browser" (plist-get info :url)))
  nil)

(defconst org-reason--protocol-entry
  '("Org Reason capture" :protocol "reason-capture"
    :function org-reason--protocol :kill-client t))

(defun org-reason-capture-enable ()
  "Add a namespaced browser protocol and one nonconflicting template."
  (org-reason-initialize)
  (unless (assoc org-reason-capture-key org-capture-templates)
    (setq org-reason--installed-template
          (list org-reason-capture-key "Org Reason inbox" 'entry
                (list 'file #'org-reason--capture-file) '(function org-reason--template)
                :hook #'org-reason--template-initial))
    (add-to-list 'org-capture-templates org-reason--installed-template t))
  (unless (seq-some (lambda (entry) (equal (plist-get (cdr entry) :protocol) "reason-capture"))
                    org-protocol-protocol-alist)
    (add-to-list 'org-protocol-protocol-alist org-reason--protocol-entry)
    (setq org-reason--installed-protocol t)))

(defun org-reason-capture-disable ()
  (when org-reason--installed-template
    (setq org-capture-templates (delete org-reason--installed-template org-capture-templates)
          org-reason--installed-template nil))
  (when org-reason--installed-protocol
    (setq org-protocol-protocol-alist
          (delete org-reason--protocol-entry org-protocol-protocol-alist))
    (setq org-reason--installed-protocol nil)))

(provide 'org-reason-capture)
;;; org-reason-capture.el ends here
