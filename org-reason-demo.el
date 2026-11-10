;;; org-reason-demo.el --- A separate, explicitly fictional test drive -*- lexical-binding: t; -*-
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; C-c r h (`org-reason-tutorial') starts this in its own Emacs, without
;; your init and away from ~/org.  By hand:
;;   emacs -Q -L <this directory> -l org-reason-demo  The data goes in ~/.emacs.d/org-reason-demo/, which is
;; gitignored, with a copy of the guide that keeps your progress; delete
;; that directory to start over.

;;; Code:
(setq org-reason-directory (locate-user-emacs-file "org-reason-demo/")
      org-reason-device "fictional-demo-device"
      org-id-locations-file (locate-user-emacs-file "org-reason-demo/id-locations")
      frame-title-format "Org Reason tutorial — fictional data")
(require 'org-reason)
(org-reason-mode 1)
(unless (file-exists-p (org-reason-path "DEMO-SEEDED"))
  (org-reason-capture-text "[DEMO] I notice I hesitate when the next writing step is unclear.")
  (org-reason-capture-text "[DEMO] Maybe try a small German writing exercise.")
  (let* ((id (org-reason-capture-text "[DEMO] A fictional paragraph is revised."))
         (marker (org-reason--find-id id)))
    (with-current-buffer (marker-buffer marker)
      (goto-char marker)
      (org-reason-clarify-entry "project" '(:next "[DEMO] Mark one unclear sentence" :context "@computer" :effort "0:10"))))
  (with-temp-file (org-reason-path "DEMO-SEEDED") (insert "Synthetic examples only.\n")))

;; Like C-h t, work in a copy of the guide, so ticked lessons are kept and
;; the guide in the repository stays as shipped.
(let ((guide (org-reason-path "tutorial.org")))
  (unless (file-exists-p guide)
    (copy-file (expand-file-name "docs/user-guide.org"
                                 (file-name-directory (or load-file-name buffer-file-name)))
               guide))
  (find-file guide)
  (org-reason-dashboard)
  ;; Start reading the guide; the dashboard stays in view beside it.
  (select-window (get-buffer-window (get-file-buffer guide))))

(provide 'org-reason-demo)
;;; org-reason-demo.el ends here
