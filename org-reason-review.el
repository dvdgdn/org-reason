;;; org-reason-review.el --- Reviews and useful exceptions -*- lexical-binding: t; -*-
;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Code:
(require 'org-reason-gtd)
(require 'org-reason-learning)

(defun org-reason-review ()
  "Open this week's review, preserving previous answers on repeat visits."
  (interactive)
  (org-reason-initialize)
  (let* ((relative (format-time-string "gtd/reviews/%G-W%V.org"))
         (file (org-reason--ensure-file relative "Weekly review")))
    (with-current-buffer (org-reason--buffer file)
      (when (save-excursion (goto-char (point-min)) (not (re-search-forward "^\\* " nil t)))
        (goto-char (point-max))
        (insert "* Get clear\n"
                "- [ ] Gather loose paper, handwritten notes, recordings, email, and other collection points.\n"
                "- [ ] Clarify each inbox item, including captures outside Emacs.\n"
                "- [ ] Write down remaining open loops from memory.\n\n"
                "* Get current\n"
                "- [ ] Bring action lists up to date.\n"
                "- [ ] Look back through the calendar for overlooked follow-up.\n"
                "- [ ] Look ahead through the calendar and prepare.\n"
                "- [ ] Check delegated commitments and follow up where needed.\n"
                "- [ ] Review each project outcome and its current action, wait, or calendar commitment.\n"
                "- [ ] Use relevant checklists to notice missing commitments.\n\n"
                "* Get creative\n"
                "- [ ] Reconsider incubated possibilities; activate, retain, or release them.\n"
                "- [ ] Capture new possibilities suggested by the review.\n\n"
                "* Optional learning review\n"
                "- [ ] Compare due predictions with evidence, including implementation and changed conditions.\n"
                "- [ ] Examine one recurring difficulty and a plausible alternative explanation.\n"
                "- [ ] Keep, adjust, or stop one process change. Has the constraint moved?\n"
                "- [ ] Check one practice skill for transfer to real work.\n"
                "- [ ] Remove any metadata or ritual that costs more than it helps.\n\n"
                "* One decision for next week\n\n"
                "* What to defer or stop\n\n")
        (org-reason--save-buffer)))
    (find-file file)))

(defun org-reason-health-data ()
  "Return actionable exceptions, without assigning a productivity score."
  (let ((seen (make-hash-table :test #'equal)) duplicates missing-media)
    (dolist (entry (org-reason--entries "" (lambda () (org-entry-get nil "ID"))))
      (let ((id (plist-get entry :id)) (original (org-reason--property entry "OR_ORIGINAL")))
        (let ((previous (gethash id seen)))
          (if previous
              (progn
                (unless (memq previous duplicates) (push previous duplicates))
                (push entry duplicates))
            (puthash id entry seen)))
        (when (and original (not (file-exists-p (org-reason-path original)))) (push entry missing-media))))
    (list :duplicates duplicates :missing-media missing-media
          :projects (org-reason-projects-without-next-action)
          :waiting (org-reason--entries "gtd" (lambda () (and (equal (org-get-todo-state) "WAIT")
                                                          (not (org-entry-get nil "OR_WAITING_FOR")))))
          :due (seq-filter (lambda (e) (let ((date (org-reason--property e "OR_REVIEW_ON")))
                                        (and date (not (string-lessp (org-reason--today) date)))))
                           (org-reason--experiments t)))))

(defun org-reason-dashboard ()
  "Show open loops and review cues; this is a view, never another task store."
  (interactive)
  (org-reason-initialize)
  (let* ((health (org-reason-health-data))
         (inbox (org-reason--entries "inbox" (lambda () (= (org-outline-level) 1))))
         (calibration (org-reason-calibration-data)))
    (with-current-buffer (get-buffer-create "*Org Reason*")
      (let ((inhibit-read-only t))
        (erase-buffer) (org-mode)
        (insert "#+title: Org Reason\n\n"
                "[[org-reason:inbox][Inbox]] · [[org-reason:agenda][Commitments]] · "
                "[[org-reason:engage][Next actions]] · [[org-reason:review][Weekly review]]\n\n")
        (insert (format "* Inbox: %d unclarified captures\n" (length inbox)))
        (dolist (section '((:projects . "Projects missing an available action, wait, or dated commitment")
                            (:due . "Predictions due for review")
                            (:waiting . "Waiting entries missing a person")
                            (:duplicates . "Duplicate IDs — reconcile before relying on links")
                            (:missing-media . "Missing original files")))
          (insert "\n* " (cdr section) "\n")
          (let ((entries (plist-get health (car section))))
            (if entries
                (dolist (entry entries)
                  (if (eq (car section) :duplicates)
                      (insert (format "- [[file:%s][%s]] — %s\n" (plist-get entry :file)
                                      (plist-get entry :title)
                                      (file-relative-name (plist-get entry :file) org-reason-directory)))
                    (insert (format "- [[id:%s][%s]]\n" (plist-get entry :id) (plist-get entry :title)))))
              (insert "None found.\n"))))
        (insert (format "\n* Prediction feedback\nFrozen: %d. Prospective binary events: %d. Scored: %d. Unresolved / unknown: %d.\n"
                        (plist-get calibration :frozen) (plist-get calibration :eligible)
                        (plist-get calibration :scored) (plist-get calibration :unresolved)))
        (when (plist-get calibration :brier)
          (insert (format "Mean Brier score: %.3f (0 is best; small, selected samples need care).\n"
                          (plist-get calibration :brier))))
        (insert "This measures these forecasts, not intelligence, competence, or causal proof.\n"
                "\n* Today\nCheck the real calendar, then choose a next action by context, time, energy and priority.\n"
                "\nNo background reminders or monitoring are running. Refresh with g; q quits.\n")
        (org-reason--view-setup #'org-reason-dashboard)))
    (pop-to-buffer "*Org Reason*")))

(provide 'org-reason-review)
;;; org-reason-review.el ends here
