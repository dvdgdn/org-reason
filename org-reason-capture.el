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

(defun org-reason-capture-text (text &optional title method source)
  "Save TEXT immediately; return the capture ID.
TITLE, METHOD and SOURCE are optional; classification is not required."
  (org-reason-initialize)
  (when (string-empty-p (string-trim text)) (user-error "Nothing to capture"))
  (org-reason--append (org-reason-path "inbox/inbox.org")
                  (or title (truncate-string-to-width (org-reason--clean text) 90 nil nil "…"))
                  text (org-reason--capture-properties method source)))

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
  "Open the single Org Reason inbox."
  (interactive)
  (org-reason-initialize)
  (find-file (org-reason-path "inbox/inbox.org")))

(defun org-reason--template ()
  "Build a deferred-classification Org capture template."
  (concat "* %?\n:PROPERTIES:\n:ID: " (org-id-new)
          "\n:OR_CAPTURED: " (org-reason--now)
          "\n:OR_DEVICE: " (org-reason--clean org-reason-device)
          "\n:OR_METHOD: org-capture\n:OR_LANGUAGE: " (org-reason--clean org-reason-language)
          "\n:OR_PRIVACY: private\n:END:\n%i\n%a\n"))

(defun org-reason--protocol (info)
  "Receive browser capture INFO through the reason-capture protocol."
  (org-reason-capture-text (or (plist-get info :body) (plist-get info :url) "")
                       (plist-get info :title) "browser" (plist-get info :url))
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
                (list 'file (org-reason-path "inbox/inbox.org")) '(function org-reason--template)))
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
