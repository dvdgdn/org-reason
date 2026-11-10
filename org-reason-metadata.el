;;; org-reason-metadata.el --- Optional, orthogonal classification -*- lexical-binding: t; -*-
;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Code:
(require 'org-reason-core)
(defconst org-reason-metadata-fields
  '(("OR_LANGUAGE" "en" "de" "zh")
    ("OR_SOURCE_LANGUAGE" "en" "de" "zh")
    ("OR_TARGET_LANGUAGE" "en" "de" "zh")
    ("OR_LOCATION") ("OR_FEELING")
    ("OR_SOURCE_DEVICE" "phone" "laptop" "work-computer")
    ("OR_FAILURE_CLASS" "simple" "complex" "intelligent" "unclassified")
    ("OR_ACTION_KIND" "read" "listen" "meet" "write" "call" "investigate" "practise")
    ("OR_ENERGY" "low" "medium" "high") ("OR_COMMONS") ("EFFORT")))

(defun org-reason-metadata (property value)
  "Set optional PROPERTY to VALUE on this entry; an empty value removes it.
Topic tags and context tags still use ordinary `org-set-tags-command'."
  (interactive
   (let* ((property (completing-read "Optional field: " org-reason-metadata-fields nil t))
          (value (completing-read (concat property ": ") (cdr (assoc property org-reason-metadata-fields)) nil nil
                                  (org-entry-get nil property))))
     (list property value)))
  (org-reason--require-entry)
  (when (and (equal property "EFFORT") (not (string-empty-p value))
             (not (string-match-p "\\`[0-9]+:[0-5][0-9]\\'" value)))
    (user-error "Use an effort estimate in H:MM"))
  (if (string-empty-p value) (org-entry-delete nil property)
    (org-entry-put nil property (org-reason--clean value)))
  (save-buffer))

(defun org-reason-find (property value)
  "Find identified records by PROPERTY and VALUE, using normal completion.
Use TAG for topics or contexts; an empty VALUE matches any value."
  (interactive
   (let* ((property (completing-read "Find by: " (append '("OR_TYPE" "TAG") (mapcar #'car org-reason-metadata-fields)) nil t))
          (entries (org-reason--entries "" (lambda () (org-entry-get nil "ID"))))
          (values (delete-dups (delq nil (mapcar (lambda (e) (org-reason--property e property)) entries)))))
     (list property (completing-read (concat property " (blank = any): ") values nil nil))))
  (let* ((entries (org-reason--entries
                   "" (lambda ()
                        (and (org-entry-get nil "ID")
                             (if (equal property "TAG") (or (string-empty-p value) (member value (org-get-tags)))
                               (let ((actual (org-entry-get nil property)))
                                 (and actual (or (string-empty-p value) (equal actual value)))))))))
         (choices (mapcar (lambda (e) (cons (format "%s · %s [%s]" (or (org-reason--property e "OR_TYPE") "inbox")
                                                   (plist-get e :title) (plist-get e :id)) (plist-get e :id))) entries)))
    (unless choices (user-error "No matching records"))
    (org-reason-open-id (cdr (assoc (completing-read "Record: " choices nil t) choices)))))

(provide 'org-reason-metadata)
;;; org-reason-metadata.el ends here
