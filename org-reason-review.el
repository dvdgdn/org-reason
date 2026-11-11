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

(defun org-reason--health-entries ()
  (org-reason--entries
   "" (lambda () (org-entry-get nil "ID"))
   (lambda (file)
     (cond
      ((org-reason--inbox-file-p file) (list :inbox (= (org-outline-level) 1)))
      ((file-in-directory-p file (org-reason-path "gtd/"))
       (list :gtd t :stalled (org-reason--stalled-project-p)))))))

(cl-defun org-reason-health-data (&optional (entries (org-reason--health-entries)))
  "Return actionable exceptions, without assigning a productivity score."
  (let ((seen (make-hash-table :test #'equal)) (today (org-reason--today))
        (inbox 0) duplicates missing-media projects waiting due)
    (dolist (entry entries)
      (let* ((id (plist-get entry :id))
             (original (org-reason--property entry "OR_ORIGINAL"))
             (previous (gethash id seen))
             (date (org-reason--property entry "OR_REVIEW_ON")))
        (if previous
            (progn
              (unless (memq previous duplicates) (push previous duplicates))
              (push entry duplicates))
          (puthash id entry seen))
        (when (plist-get entry :inbox) (cl-incf inbox))
        (when (plist-get entry :stalled) (push entry projects))
        (when (and original (not (file-exists-p (org-reason-path original))))
          (push entry missing-media))
        (when (and (plist-get entry :gtd) (equal (plist-get entry :state) "WAIT")
                   (not (org-reason--property entry "OR_WAITING_FOR")))
          (push entry waiting))
        (when (and (equal (org-reason--property entry "OR_TYPE") "experiment")
                   (equal (org-reason--property entry "OR_STATUS") "open")
                   (not (org-reason--property entry "OR_RESULT_ID"))
                   date (not (string-lessp today date)))
          (push entry due))))
    (list :inbox inbox :duplicates (nreverse duplicates) :missing-media (nreverse missing-media)
          :projects (nreverse projects) :waiting (nreverse waiting) :due (nreverse due))))

(defun org-reason--insert-calibration (calibration)
  (insert (format "\n* Prediction feedback\nFrozen: %d · Prospective binary events: %d · Scored: %d · Unresolved: %d\n"
                  (plist-get calibration :frozen) (plist-get calibration :eligible)
                  (plist-get calibration :scored) (plist-get calibration :unresolved)))
  (when-let ((buckets (plist-get calibration :buckets)))
    (insert "\n| Probability band | Forecasts | Mean forecast | Observed yes |\n"
            "|------------------+-----------+---------------+--------------|\n")
    (dolist (bucket buckets)
      (let ((high (plist-get bucket :high)))
        (insert (format "| %d–%s%d%% | %d | %.0f%% | %.0f%% |\n"
                        (plist-get bucket :low) (if (= high 100) "" "<") high
                        (plist-get bucket :count) (* 100 (plist-get bucket :forecast))
                        (* 100 (plist-get bucket :actual))))))
    (save-excursion (forward-line -1) (org-table-align))
    (insert (format "\nBrier score %.3f · Constant-rate baseline %.3f (using this sample’s yes rate). Lower is better.\n"
                    (plist-get calibration :brier) (plist-get calibration :baseline))))
  (when (> (plist-get calibration :unverified) 0)
    (insert (format "\nOlder snapshots without a digest: %d.\n" (plist-get calibration :unverified))))
  (when-let ((problems (plist-get calibration :problems)))
    (insert "\nSnapshot problems excluded from scoring\n")
    (dolist (problem problems)
      (insert (format "- [[id:%s][%s]] · %s\n" (plist-get (car problem) :id)
                      (plist-get (car problem) :title) (org-reason--clean (cdr problem)))))))

(defun org-reason-dashboard ()
  "Show open loops and review cues; this is a view, never another task store."
  (interactive)
  (org-reason-initialize)
  (let* ((entries (org-reason--health-entries))
         (health (org-reason-health-data entries))
         (calibration (org-reason-calibration-data entries)))
    (with-current-buffer (get-buffer-create "*Org Reason*")
      (let ((inhibit-read-only t))
        (erase-buffer) (org-mode)
        (insert "#+title: Org Reason\n\n"
                "[[org-reason:inbox][Inbox]] · [[org-reason:agenda][Commitments]] · "
                "[[org-reason:engage][Next actions]] · [[org-reason:review][Weekly review]]\n"
                "[[org-reason:example][See an example]]\n\n")
        (insert (format "* Inbox: %d unclarified captures\n" (plist-get health :inbox)))
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
                    (insert (format "- [[id:%s][%s]]" (plist-get entry :id) (plist-get entry :title)))
                    (when (eq (car section) :due)
                      (insert (format " · [[org-reason-result:%s][Record outcome]]" (plist-get entry :id))))
                    (insert "\n")))
              (insert "None found.\n"))))
        (org-reason--insert-calibration calibration)
        (insert "\n* Today\nCheck the real calendar, then choose a next action by context, time, energy and priority.\n"
                "\nRefresh with g. Quit with q.\n")
        (org-reason--view-setup #'org-reason-dashboard)))
    (pop-to-buffer "*Org Reason*")))

(provide 'org-reason-review)
;;; org-reason-review.el ends here
