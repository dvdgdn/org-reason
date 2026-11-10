;;; org-reason.el --- GTD capture, frozen predictions and Reason Commons in Org -*- lexical-binding: t; -*-

;; Copyright (C) 2026 David Joseph and Org Reason contributors
;; SPDX-License-Identifier: GPL-3.0-or-later

;; Author: David Joseph
;; URL: https://github.com/dvdgdn/org-reason
;; Version: 0.1.1
;; Package-Requires: ((emacs "29.1") (org "9.6"))
;; Keywords: outlines, convenience

;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation, either version 3 of the License, or (at your option)
;; any later version.  It is distributed WITHOUT ANY WARRANTY; see LICENSE.

;;; Commentary:

;; Capture anything into one inbox, clarify it into next actions and projects
;; (GTD), freeze a prediction before you know the outcome and compare it with
;; what happened, and work through recurring problems with Reason Commons
;; thinking-process trees.  Plain Org files; local-first; additive.
;;
;; Turn on `org-reason-mode' for the C-c r prefix; C-c r h opens the guided
;; tutorial.  Emacs and Org suffice for capture, GTD and learning; Python 3
;; with PyYAML enables the Reason Commons commands.  See README.md and
;; docs/install.md.

;;; Code:
(require 'org-reason-core)
(require 'org-reason-capture)
(require 'org-reason-gtd)
(require 'org-reason-learning)
(require 'org-reason-review)
(require 'org-reason-metadata)

(autoload 'org-reason-import-file "org-reason-media" nil t)
(autoload 'org-reason-import-drop "org-reason-media" nil t)
(autoload 'org-reason-derive "org-reason-media" nil t)
(autoload 'org-reason-import-interpretation "org-reason-media" nil t)
(autoload 'org-reason-mark-interpretation-reviewed "org-reason-media" nil t)
(autoload 'org-reason-commons-new "org-reason-reasoning" nil t)
(autoload 'org-reason-node-add "org-reason-reasoning" nil t)
(autoload 'org-reason-link-add "org-reason-reasoning" nil t)
(autoload 'org-reason-item-accept "org-reason-reasoning" nil t)
(autoload 'org-reason-item-annotate "org-reason-reasoning" nil t)
(autoload 'org-reason-reasoning-view "org-reason-reasoning" nil t)
(autoload 'org-reason-reasoning-diagram "org-reason-reasoning" nil t)
(autoload 'org-reason-node-action "org-reason-reasoning" nil t)
;; Register rc links before the optional reasoning module is first invoked.
(autoload 'org-reason-rc-follow "org-reason-reasoning" nil nil)
(org-link-set-parameters "rc" :follow #'org-reason-rc-follow)

(defconst org-reason--link-views '("inbox" "agenda" "engage" "dashboard" "review")
  "Views an org-reason: link may open.  Nothing else runs from a link.")

(defun org-reason-link-follow (view _argument)
  "Open the Org Reason VIEW named by an org-reason: link, e.g. org-reason:inbox.
The dashboard uses these instead of elisp: links, which ask before every click."
  (unless (member view org-reason--link-views)
    (user-error "Not an Org Reason view: %s" view))
  (call-interactively (intern (concat "org-reason-" view))))

(org-link-set-parameters "org-reason" :follow #'org-reason-link-follow
                         :complete (lambda (&optional _)
                                     (concat "org-reason:" (completing-read "View: " org-reason--link-views nil t))))

(defvar mac-command-modifier)           ; macOS builds only
(defvar mac-option-modifier)

(defun org-reason--gui-emacs ()
  "The Emacs to run the tutorial in: this one if it is graphical.
From a terminal, look for the platform's GUI Emacs; nil if there is none."
  (if (display-graphic-p)
      (expand-file-name invocation-name invocation-directory)
    (seq-find #'file-executable-p
              (pcase system-type
                ('darwin '("/Applications/Emacs.app/Contents/MacOS/Emacs"))
                ('windows-nt (list (expand-file-name "runemacs.exe" invocation-directory)))))))

(defun org-reason-tutorial ()
  "Open the guided Org Reason tutorial, as `help-with-tutorial' does for Emacs.
Its exercises run real Org Reason commands, so it opens in a separate
Emacs that loads neither your init nor your records: `org-reason-demo'
works on fictional data in ~/.emacs.d/org-reason-demo/.  There it opens
a copy of docs/user-guide.org that keeps your ticked lessons, beside the
dashboard; delete that directory to start over."
  (interactive)
  (let* ((library (locate-library "org-reason-demo"))
         (emacs (org-reason--gui-emacs))
         (keys (when (and (boundp 'mac-command-modifier) (boundp 'mac-option-modifier))
                 ;; -Q would drop your Command/Option layout; keep it.
                 (list "--eval" (format "(setq mac-command-modifier '%S mac-option-modifier '%S)"
                                        mac-command-modifier mac-option-modifier)))))
    (unless library (user-error "Cannot find org-reason-demo.el on the load-path"))
    (unless (and emacs (file-executable-p emacs))
      (user-error "No GUI Emacs found; in a terminal, run: emacs -Q -L %s -l org-reason-demo"
                  (abbreviate-file-name (file-name-directory library))))
    ;; BUFFER 0: start it and return at once, detached from this Emacs.
    (apply #'call-process emacs nil 0 nil
           (append (list "-Q" "-L" (file-name-directory library))
                   keys (list "-l" "org-reason-demo")))
    (message "Opening the Org Reason tutorial in a separate Emacs, on fictional data")))

(defvar org-reason-reasoning-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "c") #'org-reason-commons-new)
    (define-key map (kbd "v") #'org-reason-reasoning-view)
    (define-key map (kbd "n") #'org-reason-node-add)
    (define-key map (kbd "l") #'org-reason-link-add)
    (define-key map (kbd "a") #'org-reason-item-accept)
    (define-key map (kbd "?") #'org-reason-item-annotate)
    (define-key map (kbd "g") #'org-reason-reasoning-diagram)
    (define-key map (kbd "x") #'org-reason-node-action)
    map))
(defvar org-reason-command-map
  (let ((map (make-sparse-keymap)))
    (dolist (binding '(("c" . org-reason-capture) ("i" . org-reason-inbox) ("x" . org-reason-clarify)
                        ("d" . org-reason-dashboard) ("a" . org-reason-agenda) ("e" . org-reason-engage)
                        ("w" . org-reason-review) ("p" . org-reason-experiment) ("f" . org-reason-freeze-prediction)
                        ("o" . org-reason-record-result) ("s" . org-reason-practice) ("!" . org-reason-feedback)
                        ("m" . org-reason-import-file) ("I" . org-reason-import-drop) ("D" . org-reason-derive)
                        ("v" . org-reason-show-forecast) ("M" . org-reason-metadata) ("/" . org-reason-find)
                        ("h" . org-reason-tutorial)))
      (define-key map (kbd (car binding)) (cdr binding)))
    (define-key map (kbd "t") org-reason-reasoning-map)
    map))
(defvar org-reason-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c r") org-reason-command-map)
    map))

(defcustom org-reason-roam-knowledge-only t
  "Whether Org-roam indexes only the knowledge/ notes of the workspace.
When `org-reason-directory' is inside `org-roam-directory', every capture,
action and experiment, each with an ID, would otherwise become an Org-roam
node.  `org-reason-mode' then adds one entry to `org-roam-file-exclude-regexp'
for the inbox, gtd, learning, archive, media and commons directories, and
removes it again when turned off.  Run `org-roam-db-sync' after changing it."
  :type 'boolean :group 'org-reason)

(defvar org-roam-directory)
(defvar org-roam-file-exclude-regexp)
(defvar org-reason--roam-exclusion nil
  "The entry `org-reason-mode' added to `org-roam-file-exclude-regexp'.")

(defun org-reason--roam-exclusion-regexp ()
  "Regexp for the workspace's non-knowledge directories, as Org-roam sees them.
Org-roam matches it against paths relative to `org-roam-directory'.  Nil
when the workspace is not inside that directory."
  (let ((root (file-truename (file-name-as-directory org-roam-directory)))
        (workspace (file-truename (file-name-as-directory org-reason-directory))))
    (when (file-in-directory-p workspace root)
      (concat "\\`" (regexp-quote (if (file-equal-p workspace root) ""
                                    (file-relative-name workspace root)))
              "\\(?:inbox\\|gtd\\|learning\\|archive\\|media\\|commons\\)/"))))

(defun org-reason--roam-setup ()
  "Keep the workspace's tasks and captures out of the Org-roam index."
  (when (and org-reason-mode org-reason-roam-knowledge-only
             (boundp 'org-roam-directory) (boundp 'org-roam-file-exclude-regexp))
    (let ((regexp (org-reason--roam-exclusion-regexp)))
      (when regexp
        (when (stringp org-roam-file-exclude-regexp)
          (setq org-roam-file-exclude-regexp (list org-roam-file-exclude-regexp)))
        (add-to-list 'org-roam-file-exclude-regexp regexp)
        (setq org-reason--roam-exclusion regexp)))))

(defun org-reason--roam-teardown ()
  "Undo `org-reason--roam-setup'."
  (when (and org-reason--roam-exclusion (boundp 'org-roam-file-exclude-regexp)
             (listp org-roam-file-exclude-regexp))
    (setq org-roam-file-exclude-regexp
          (remove org-reason--roam-exclusion org-roam-file-exclude-regexp)))
  (setq org-reason--roam-exclusion nil))

;;;###autoload
(define-minor-mode org-reason-mode
  "Enable additive capture and the C-c r command prefix globally.
Disabling removes package-installed capture entries, keybindings and the
Org-roam index exclusion (see `org-reason-roam-knowledge-only'), but
keeps your data.  Existing browser templates are left in place."
  :global t :group 'org-reason
  (if org-reason-mode
      (progn (org-reason-capture-enable)
             ;; Also for saves by you or Org capture, not only the package's.
             (add-hook 'before-save-hook #'org-reason--prefer-utf-8)
             (with-eval-after-load 'org-roam (org-reason--roam-setup)))
    (org-reason-capture-disable)
    (remove-hook 'before-save-hook #'org-reason--prefer-utf-8)
    (org-reason--roam-teardown)))

(provide 'org-reason)
;;; org-reason.el ends here
