;;; org-reason-learning.el --- Predictions, outcomes, and practice -*- lexical-binding: t; -*-
;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Code:
(require 'org-reason-core)
(require 'org-reason-capture)
(require 'json)

(defun org-reason--json-read (file)
  (let ((json-object-type 'alist) (json-array-type 'list) (json-key-type 'string)
        (json-false :false) (json-null nil))
    (json-read-file file)))

(defun org-reason--forecast-path (id)
  (org-reason-path (concat "learning/forecasts/" (org-reason--id-filename id) ".json")))

(defun org-reason-create-experiment (title prediction review-on)
  "Create a draft experiment TITLE with PREDICTION and REVIEW-ON.
Return its ID.  A draft is not a prospective forecast until explicitly frozen."
  (org-reason-initialize)
  (unless (org-reason--date-valid-p review-on) (user-error "Use a valid review date"))
  (org-reason--append
   (org-reason-path "learning/experiments.org") title
   (concat "** Prediction\n" prediction
           "\n\n** Goal and system boundary\nUnknown.\n\n** Baseline and observation period\nUnknown.\n"
           "\n** Intervention and dose\nUnknown.\n\n** Measurement and success criterion\nUnknown.\n"
           "\n** Strongest alternative explanation\nUnknown.\n\n** Protected conditions and stop rule\nUnknown.\n"
           "\n** Next physical action\nUnknown. Create a GTD action when committed.\n"
           "\n** Reconsider if\nUnknown.\n")
   (list '("OR_TYPE" . "experiment") (cons "OR_CREATED" (org-reason--now))
         (cons "OR_REVIEW_ON" review-on) '("OR_STATUS" . "draft"))))

(defun org-reason-experiment (title prediction review-on)
  "Draft one bounded experiment; edit its fields before freezing."
  (interactive (list (read-string "Experiment: ") (read-string "What do you expect? ")
                     (org-read-date nil nil nil "Review the outcome on: ")))
  (org-reason-open-id (org-reason-create-experiment title prediction review-on))
  (org-fold-show-subtree)
  (message "Fill the relevant fields, then C-c r f to freeze the prediction"))

(defun org-reason--section-text (name)
  "Read the immediate subsection NAME of the current entry."
  (save-excursion
    (let ((end (save-excursion (org-end-of-subtree t t) (point)))
          (prefix (make-string (1+ (org-outline-level)) ?*)))
      (forward-line)
      (when (re-search-forward (concat "^" (regexp-quote prefix) " " (regexp-quote name) "[ \t]*$") end t)
        (forward-line)
        (let ((start (point)))
          (if (re-search-forward org-heading-regexp end t)
              (string-trim (buffer-substring-no-properties start (line-beginning-position)))
            (string-trim (buffer-substring-no-properties start end))))))))

(defun org-reason-freeze-prediction (&optional probability event prospective)
  "Freeze the current draft before its outcome is known.
PROBABILITY is optional, from 0 to 1, for the precise binary EVENT.
PROSPECTIVE is t only when the user reports that the outcome is still unknown.
Forecast files are never overwritten by package commands; ordinary files
are not tamper-proof or independently timestamped."
  (interactive
   (let* ((p (read-string "Probability 0..1 (blank = no binary score): "))
          (number (unless (string-empty-p p)
                    (unless (string-match-p "\\`\\(?:[01]\\(?:\\.[0-9]+\\)?\\|\\.[0-9]+\\)\\'" p)
                      (user-error "Use a probability between 0 and 1"))
                    (string-to-number p))))
     (list number (when number (read-string "Precisely which yes/no event? "))
           (y-or-n-p "Is the outcome still unknown to you? "))))
  (org-reason--require-entry)
  (unless (equal (org-entry-get nil "OR_TYPE") "experiment")
    (user-error "Freeze from the experiment's top heading"))
  (when (and probability (or (not (numberp probability)) (< probability 0) (> probability 1)))
    (user-error "Probability must be between 0 and 1"))
  (when (and probability (string-empty-p (string-trim (or event ""))))
    (user-error "A scored prediction needs an explicit yes/no event"))
  (let* ((id (org-entry-get nil "ID"))
         (prediction (org-reason--section-text "Prediction"))
         (review (org-entry-get nil "OR_REVIEW_ON"))
         (file (org-reason--forecast-path id)))
    (unless (and prediction (not (string-empty-p prediction))) (user-error "Write a Prediction section first"))
    (unless (and review (org-reason--date-valid-p review)) (user-error "Set OR_REVIEW_ON to a valid date"))
    (when (file-exists-p file) (user-error "Prediction already frozen; create a new experiment for a revision"))
    (let ((snapshot
           (list (cons "schema_version" 1) (cons "id" id)
                 (cons "recorded_at" (org-reason--now))
                 (cons "title" (org-get-heading t t t t))
                 (cons "statement" prediction) (cons "review_on" review)
                 (cons "prospective" (if prospective t :json-false))
                 (cons "binary_event" event) (cons "probability" probability)
                 (cons "original_org" (buffer-substring-no-properties
                                       (point) (save-excursion (org-end-of-subtree t t) (point)))))))
      (with-temp-buffer
        (insert (json-encode snapshot) "\n")
        (let ((coding-system-for-write 'utf-8-unix)) ; the same bytes on every OS
          (write-region (point-min) (point-max) file nil 'silent nil 'excl)))
      (set-file-modes file #o600))
    (org-entry-put nil "OR_STATUS" "open")
    (org-entry-put nil "OR_FORECAST" (file-relative-name file org-reason-directory))
    (org-reason--save-buffer)
    (message "Original prediction preserved; review %s" review)
    file))

(defun org-reason--experiments (&optional open-only)
  (org-reason--entries "learning"
                   (lambda () (and (equal (org-entry-get nil "OR_TYPE") "experiment")
                                   (or (not open-only)
                                       (and (equal (org-entry-get nil "OR_STATUS") "open")
                                            (not (org-entry-get nil "OR_RESULT_ID"))))))))

(defun org-reason--choose-experiment (&optional include-reviewed)
  "Choose an experiment, optionally including reviewed frozen originals."
  (let* ((entries (if include-reviewed
                      (seq-filter (lambda (entry)
                                    (file-exists-p (org-reason--forecast-path (plist-get entry :id))))
                                  (org-reason--experiments))
                    (org-reason--experiments t)))
         (choices (mapcar (lambda (e) (cons (format "%s [%s]" (plist-get e :title) (plist-get e :id))
                                           (plist-get e :id))) entries)))
    (unless choices (user-error (if include-reviewed "No frozen predictions" "No open frozen experiments")))
    (cdr (assoc (completing-read "Review experiment: " choices nil t) choices))))

(defun org-reason-show-forecast (id)
  "Show the original forecast ID without relying on edited working text."
  (interactive (list (org-reason--choose-experiment t)))
  (let ((snapshot (org-reason--json-read (org-reason--forecast-path id))))
    (with-current-buffer (get-buffer-create "*Org Reason: original forecast*")
      (let ((inhibit-read-only t))
        (erase-buffer) (org-mode)
        (insert "#+title: Original forecast\n\n" (cdr (assoc "original_org" snapshot)))
        (org-reason--view-setup))
      (display-buffer (current-buffer)))))

(defun org-reason-add-result (id assessment observation &optional binary-outcome feeling next-decision)
  "Append an outcome for frozen experiment ID, preserving its original forecast.
ASSESSMENT is supported, contradicted, implementation-failed, or inconclusive.
BINARY-OUTCOME is yes, no, or unknown, independent of the causal assessment."
  (unless (member assessment '("supported" "contradicted" "implementation-failed" "inconclusive"))
    (user-error "Unknown assessment"))
  (unless (member binary-outcome '(nil "yes" "no" "unknown")) (user-error "Unknown binary outcome"))
  (when (string-empty-p (string-trim observation)) (user-error "Record what actually happened"))
  (unless (file-exists-p (org-reason--forecast-path id)) (user-error "Freeze a prediction before recording its outcome"))
  (let ((marker (org-reason--find-id id)))
    (unless marker (user-error "Experiment not found"))
    (with-current-buffer (marker-buffer marker)
      (save-excursion
        (goto-char marker)
        (when (org-entry-get nil "OR_RESULT_ID")
          (user-error "Already reviewed; append a correction manually or create a follow-up experiment"))
        (let ((result-id
               (org-reason--child
                (concat "Outcome — " (org-reason--today))
                (concat "Observation: " observation "\n\n"
                        "Implementation fidelity: Unknown — was the intervention carried out?\n\n"
                        "Comparability / changed conditions: Unknown.\n\n"
                        "What this changes in the model: Unknown.\n\n"
                        "Next decision: " (or next-decision "Unknown.") "\n")
                (list '("OR_TYPE" . "result") (cons "OR_FOR" id)
                      (cons "OR_RECORDED" (org-reason--now)) (cons "OR_ASSESSMENT" assessment)
                      (cons "OR_BINARY_OUTCOME" (or binary-outcome "unknown"))
                      (cons "OR_FEELING" feeling)))))
          (org-entry-put nil "OR_RESULT_ID" result-id)
          (org-entry-put nil "OR_STATUS" "reviewed")
          (org-reason--save-buffer)
          result-id)))))

(defun org-reason-record-result ()
  "Compare an original prediction with observations and the next decision."
  (interactive)
  (let* ((id (org-reason--choose-experiment))
         (_view (org-reason-show-forecast id))
         (assessment (completing-read "Assessment: " '("supported" "contradicted" "implementation-failed" "inconclusive") nil t))
         (observation (read-string "What did you observe? "))
         (snapshot (org-reason--json-read (org-reason--forecast-path id)))
         (outcome (when (numberp (cdr (assoc "probability" snapshot)))
                    (completing-read (format "Did this event occur: %s? " (cdr (assoc "binary_event" snapshot)))
                                     '("yes" "no" "unknown") nil t)))
         (feeling (read-string "Feeling (optional): "))
         (decision (read-string "Next decision (continue / adjust / stop / seek evidence): ")))
    (org-reason-open-id (org-reason-add-result id assessment observation outcome feeling decision))))

(defun org-reason-calibration-data ()
  "Return honest counts and Brier scores for eligible binary forecasts.
Only self-reported prospective, resolved yes/no events are scored.
Unresolved and inconclusive records remain in the denominator counts."
  (let ((frozen 0) (eligible 0) (scored 0) (sum 0.0))
    (dolist (entry (org-reason--experiments))
      (let ((file (org-reason--forecast-path (plist-get entry :id))))
        (when (file-exists-p file)
          (cl-incf frozen)
          (let* ((snapshot (org-reason--json-read file))
                 (probability (cdr (assoc "probability" snapshot)))
                 (result (org-reason--property entry "OR_RESULT_ID"))
                 (marker (and result (org-reason--find-id result))))
            (when (and (eq (cdr (assoc "prospective" snapshot)) t) (numberp probability))
              (cl-incf eligible)
              (when marker
                (with-current-buffer (marker-buffer marker)
                  (save-excursion
                    (goto-char marker)
                    (let ((answer (org-entry-get nil "OR_BINARY_OUTCOME")))
                      (when (member answer '("yes" "no"))
                        (cl-incf scored)
                        (cl-incf sum (expt (- probability (if (equal answer "yes") 1 0)) 2))))))))))))
    (list :frozen frozen :eligible eligible :scored scored
          :unresolved (- eligible scored) :brier (and (> scored 0) (/ sum scored)))))

(defun org-reason-practice (skill challenge feedback)
  "Create a focused practice rep for SKILL, CHALLENGE, and FEEDBACK source."
  (interactive (list (read-string "Specific component skill: ")
                     (read-string "Small challenge: ")
                     (read-string "How will you get reliable feedback? ")))
  (org-reason-initialize)
  (org-reason-open-id
   (org-reason--append
    (org-reason-path "learning/practice.org") skill
    (concat "Challenge: " challenge "\n\nFeedback source / criterion: " feedback
            "\n\nAttempt and observed feedback: \n\nAdjustment for the next repetition: \n"
            "\nTransfer check in real work: \n")
    (list '("OR_TYPE" . "practice") (cons "OR_CREATED" (org-reason--now))))))

(defun org-reason-feedback (expected observed)
  "Capture a small mismatch, with no obligation to do a full debrief."
  (interactive (list (read-string "Expected: ") (read-string "Observed: ")))
  (org-reason-capture-text (concat "Expected: " expected "\nObserved: " observed
                                "\nRevisit / next: undecided.\n")
                       "Expectation / observation" "manual"))

(provide 'org-reason-learning)
;;; org-reason-learning.el ends here
