;;; org-reason-learning.el --- Predictions, outcomes, and practice -*- lexical-binding: t; -*-
;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Code:
(require 'org-reason-core)
(require 'org-reason-capture)
(require 'json)

(declare-function org-reason-next-action "org-reason-gtd" (title &optional context effort reason))

(defun org-reason--json-read (file &optional expected-digest)
  "Read FILE, verifying its exact bytes first when EXPECTED-DIGEST is set."
  (with-temp-buffer
    (set-buffer-multibyte nil)
    (insert-file-contents-literally file)
    (when (and expected-digest (not (equal expected-digest (secure-hash 'sha256 (current-buffer)))))
      (user-error "Forecast snapshot SHA-256 mismatch"))
    (let ((json-object-type 'alist) (json-array-type 'list) (json-key-type 'string)
          (json-false :false) (json-null nil))
      (json-read-from-string (decode-coding-string (buffer-string) 'utf-8)))))

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
  (message "Fill the relevant fields, then run org-reason-freeze-prediction"))

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
         (file (org-reason--forecast-path id))
         digest)
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
        (set-buffer-multibyte nil)
        (insert (encode-coding-string (concat (json-encode snapshot) "\n") 'utf-8-unix))
        (setq digest (secure-hash 'sha256 (current-buffer)))
        (let ((coding-system-for-write 'no-conversion))
          (write-region (point-min) (point-max) file nil 'silent nil 'excl)))
      (set-file-modes file #o600))
    (atomic-change-group
      (org-entry-put nil "OR_STATUS" "open")
      (org-entry-put nil "OR_FORECAST" (file-relative-name file org-reason-directory))
      (org-entry-put nil "OR_FORECAST_SHA256" digest)
      (org-reason--save-buffer))
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

(defun org-reason--read-forecast (id expected-digest)
  "Return the saved forecast for ID after checking its identity and digest."
  (let* ((file (org-reason--forecast-path id))
         (snapshot (if (file-readable-p file)
                       (org-reason--json-read file expected-digest)
                     (user-error "Forecast snapshot is missing")))
         (probability (cdr (assoc "probability" snapshot)))
         (event (cdr (assoc "binary_event" snapshot))))
    (unless (and (equal (cdr (assoc "schema_version" snapshot)) 1)
                 (equal (cdr (assoc "id" snapshot)) id)
                 (stringp (cdr (assoc "original_org" snapshot)))
                 (or (null probability)
                     (and (numberp probability) (<= 0 probability 1)
                          (stringp event) (not (string-blank-p event)))))
      (user-error "Invalid forecast snapshot for %s" id))
    snapshot))

(defun org-reason--experiment-marker (id)
  (let ((marker (org-reason--find-id id)))
    (unless (and marker (org-with-point-at marker
                          (equal (org-entry-get nil "OR_TYPE") "experiment")))
      (user-error "Experiment not found: %s" id))
    marker))

(defun org-reason--display-forecast (snapshot digest)
  (with-current-buffer (get-buffer-create "*Org Reason: original forecast*")
    (let ((inhibit-read-only t)
          (event (cdr (assoc "binary_event" snapshot)))
          (probability (cdr (assoc "probability" snapshot))))
      (erase-buffer)
      (org-mode)
      (insert "#+title: Original forecast\n\n")
      (unless digest (insert "This snapshot was saved without a SHA-256 digest.\n\n"))
      (when (numberp probability)
        (insert (format "Forecast probability: %g%%\n\n" (* 100 probability))
                "Yes/no event\n"
                (org-reason--literal-text event) "\n"))
      (insert (cdr (assoc "original_org" snapshot)))
      (org-reason--view-setup))
    (display-buffer (current-buffer))))

(defun org-reason-show-forecast (id)
  "Show the original forecast ID without relying on edited working text."
  (interactive (list (org-reason--choose-experiment t)))
  (let ((digest (org-with-point-at (org-reason--experiment-marker id)
                  (org-entry-get nil "OR_FORECAST_SHA256"))))
    (org-reason--display-forecast (org-reason--read-forecast id digest) digest)))

(defun org-reason-add-result (id assessment observation &optional binary-outcome feeling next-decision)
  "Append an outcome for frozen experiment ID, preserving its original forecast.
ASSESSMENT is supported, contradicted, implementation-failed, or inconclusive.
BINARY-OUTCOME is yes, no, or unknown, independent of the causal assessment."
  (unless (member assessment '("supported" "contradicted" "implementation-failed" "inconclusive"))
    (user-error "Unknown assessment"))
  (unless (member binary-outcome '(nil "yes" "no" "unknown")) (user-error "Unknown binary outcome"))
  (when (string-blank-p observation) (user-error "Record what actually happened"))
  (org-with-point-at (org-reason--experiment-marker id)
    (org-reason--read-forecast id (org-entry-get nil "OR_FORECAST_SHA256"))
    (when (org-entry-get nil "OR_RESULT_ID")
      (user-error "Already reviewed; append a correction manually or create a follow-up experiment"))
    (let (result-id)
      (atomic-change-group
        (setq result-id
              (org-reason--insert-child
               (concat "Outcome — " (org-reason--today))
               (concat "Observation\n" (org-reason--literal-text observation)
                       "\nImplementation fidelity: Unknown — was the intervention carried out?\n\n"
                       "Comparability / changed conditions: Unknown.\n\n"
                       "What this changes in the model: Unknown.\n\n"
                       "Next decision\n" (org-reason--literal-text (or next-decision "Unknown.")))
               (list '("OR_TYPE" . "result") (cons "OR_FOR" id)
                     (cons "OR_RECORDED" (org-reason--now))
                     (cons "OR_ASSESSMENT" assessment)
                     (cons "OR_BINARY_OUTCOME" (or binary-outcome "unknown"))
                     (cons "OR_FEELING" feeling))))
        (org-entry-put nil "OR_RESULT_ID" result-id)
        (org-entry-put nil "OR_STATUS" "reviewed")
        (org-reason--save-buffer))
      (org-id-add-location result-id buffer-file-name)
      result-id)))

(defun org-reason-record-result (&optional id)
  "Review forecast ID, or choose an open experiment."
  (interactive)
  (let* ((id (or id (org-reason--choose-experiment)))
         (digest (org-with-point-at (org-reason--experiment-marker id)
                   (unless (and (equal (org-entry-get nil "OR_STATUS") "open")
                                (not (org-entry-get nil "OR_RESULT_ID")))
                     (user-error "Choose an open frozen experiment"))
                   (org-entry-get nil "OR_FORECAST_SHA256")))
         (snapshot (org-reason--read-forecast id digest))
         (_view (org-reason--display-forecast snapshot digest))
         (assessment (completing-read "Assessment: " '("supported" "contradicted" "implementation-failed" "inconclusive") nil t))
         (observation (read-string "What did you observe? "))
         (outcome (when (numberp (cdr (assoc "probability" snapshot)))
                    (completing-read (format "Did this event occur: %s? " (cdr (assoc "binary_event" snapshot)))
                                     '("yes" "no" "unknown") nil t)))
         (feeling (read-string "Feeling (optional): "))
         (decision (read-string "Next decision (continue / adjust / stop / seek evidence): "))
         (result (org-reason-add-result id assessment observation outcome feeling decision)))
    (org-reason-open-id result)
    (when (and (not (string-blank-p decision))
               (y-or-n-p "Create a NEXT action linked to this result? "))
      (let ((title (read-string "Physical next action: " decision)))
        (unless (string-blank-p title)
          (org-reason-open-id (org-reason-next-action title nil nil (concat "id:" result))))))
    result))

(defun org-reason--review-forecast-link (id _argument)
  (org-reason-record-result id))

(org-link-set-parameters "org-reason-result" :follow #'org-reason--review-forecast-link)

(cl-defun org-reason-calibration-data
    (&optional (entries (org-reason--entries "" (lambda () (org-entry-get nil "ID")))))
  "Return calibration counts, probability buckets, and Brier scores.
Use resolved prospective yes/no forecasts.  The constant-rate reference
predicts the observed yes rate for every scored event in this sample."
  (let ((by-id (make-hash-table :test #'equal))
        (buckets (make-vector 5 nil))
        (frozen 0) (eligible 0) (scored 0) (sum 0.0) (yes 0) (unverified 0)
        problems)
    (dolist (entry entries)
      (puthash (plist-get entry :id) entry by-id))
    (dolist (entry entries)
      (when (equal (org-reason--property entry "OR_TYPE") "experiment")
        (let* ((id (plist-get entry :id))
               (digest (org-reason--property entry "OR_FORECAST_SHA256")))
          (when (or digest (org-reason--property entry "OR_FORECAST")
                    (file-exists-p (org-reason--forecast-path id)))
            (cl-incf frozen)
            (condition-case err
                (let* ((snapshot (org-reason--read-forecast id digest))
                       (probability (cdr (assoc "probability" snapshot)))
                       (result (gethash (org-reason--property entry "OR_RESULT_ID") by-id))
                       (answer (org-reason--property result "OR_BINARY_OUTCOME")))
                  (unless digest (cl-incf unverified))
                  (when (and (eq (cdr (assoc "prospective" snapshot)) t)
                             (numberp probability) (<= 0 probability 1))
                    (cl-incf eligible)
                    (when (member answer '("yes" "no"))
                      (let* ((actual (if (equal answer "yes") 1 0))
                             (index (min 4 (floor (* 5 probability))))
                             (bucket (or (aref buckets index) (list 0 0.0 0))))
                        (cl-incf scored)
                        (cl-incf yes actual)
                        (cl-incf sum (expt (- probability actual) 2))
                        (cl-incf (nth 0 bucket))
                        (cl-incf (nth 1 bucket) probability)
                        (cl-incf (nth 2 bucket) actual)
                        (aset buckets index bucket)))))
              (error (push (cons entry (error-message-string err)) problems)))))))
    (let ((rate (and (> scored 0) (/ (float yes) scored))))
      (list :frozen frozen :eligible eligible :scored scored :unresolved (- eligible scored)
            :unverified unverified :problems (nreverse problems)
            :brier (and rate (/ sum scored)) :baseline (and rate (* rate (- 1 rate)))
            :buckets (cl-loop for bucket across buckets
                              for low from 0 by 20
                              when bucket
                              collect (cl-destructuring-bind (n forecast actual) bucket
                                        (list :low low :high (+ low 20) :count n
                                              :forecast (/ forecast n) :actual (/ (float actual) n))))))))

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
