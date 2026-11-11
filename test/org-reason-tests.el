;;; org-reason-tests.el --- Behavioral ERT contracts -*- lexical-binding: t; -*-
(require 'ert)
(require 'org-reason)
(require 'org-reason-media)
(require 'org-reason-reasoning)
(when (getenv "ORG_REASON_TEST_PYTHON") (setq org-reason-python-command (getenv "ORG_REASON_TEST_PYTHON")))
;; Mocking a primitive should not require a system C toolchain for a trampoline.
(defvar native-comp-enable-subr-trampolines) ; absent without native compilation
(setq native-comp-enable-subr-trampolines nil)
;; Org-roam itself is not loaded in these tests; these stand in for it.
(defvar org-roam-directory)
(defvar org-roam-file-exclude-regexp)

(defmacro org-reason-test-workspace (&rest body)
  (declare (indent 0) (debug t))
  `(let* ((temporary (make-temp-file "org-reason-test-" t))
          (org-reason-directory (expand-file-name "data" temporary))
          (org-id-locations-file (expand-file-name "ids" temporary))
          (org-id-locations nil) (org-id-files nil)
          (org-capture-templates nil) (org-protocol-protocol-alist nil)
          (org-reason--installed-template nil) (org-reason--installed-protocol nil)
          (org-reason-mode nil)
          (make-backup-files nil) (create-lockfiles nil))
     (unwind-protect (save-window-excursion ,@body)
       (org-reason-mode -1)
       (dolist (buffer (buffer-list))
         (when (and (buffer-file-name buffer)
                    (file-in-directory-p (buffer-file-name buffer) temporary))
           (with-current-buffer buffer (set-buffer-modified-p nil))
           (kill-buffer buffer)))
       (delete-directory temporary t))))

(defmacro org-reason-test-at (id &rest body)
  (declare (indent 1) (debug t))
  `(let ((marker (org-reason--find-id ,id)))
     (should marker)
     (with-current-buffer (marker-buffer marker)
       (goto-char marker)
       ,@body)))

(ert-deftest org-reason-test-loading-does-not-initialize ()
  (org-reason-test-workspace
    (load "org-reason" nil t)
    (should-not (file-exists-p org-reason-directory))))

(ert-deftest org-reason-test-initialize-is-idempotent ()
  (org-reason-test-workspace
    (org-reason-initialize)
    (let ((id (org-reason-capture-text "Keep this exact material.")))
      (org-reason-initialize)
      (org-reason-test-at id (should (search-forward "Keep this exact material." nil t))))))

;; @CAP01
(ert-deftest org-reason-test-capture-needs-no-classification ()
  (org-reason-test-workspace
    (let ((id (org-reason-capture-text "A loose thought")))
      (org-reason-test-at id
        (should-not (org-get-todo-state))
        (should-not (org-entry-get nil "OR_TYPE"))
        (should (org-entry-get nil "OR_CAPTURED"))
        (should (equal (org-entry-get nil "OR_PRIVACY") "private"))))))

;; @CAP02
(ert-deftest org-reason-test-existing-capture-templates-and-protocol-survive ()
  (org-reason-test-workspace
    (let ((custom '("r" "Existing" entry (file "elsewhere.org") "* %?"))
          (protocol '("Existing handler" :protocol "reason-capture" :function ignore)))
      (setq org-capture-templates (list custom)
            org-protocol-protocol-alist (list protocol))
      (org-reason-mode 1)
      (org-reason-mode 1)
      (should (equal org-capture-templates (list custom)))
      (org-reason-mode -1)
      (should (equal org-capture-templates (list custom)))
      (should (equal org-protocol-protocol-alist (list protocol))))))

;; @CAP02
(ert-deftest org-reason-test-owned-template-enable-disable ()
  (org-reason-test-workspace
    (org-reason-mode 1)
    (org-reason-mode 1)
    (should (= (length org-capture-templates) 1))
    (should (= (length org-protocol-protocol-alist) 1))
    (org-reason-mode -1)
    (should-not org-capture-templates)
    (should-not org-protocol-protocol-alist)
    (should (file-exists-p (org-reason-path "inbox/inbox.org")))))

;; @GTD01
(ert-deftest org-reason-test-clarification-preserves-identity-and-body ()
  (org-reason-test-workspace
    (let ((id (org-reason-capture-text "Original body")))
      (org-reason-test-at id (org-reason-clarify-entry "next-action" '(:context "@computer" :effort "0:20")))
      (org-reason-test-at id
        (should (equal (org-get-todo-state) "NEXT"))
        (should (member "@computer" (org-get-tags)))
        (should (equal (org-entry-get nil "EFFORT") "0:20"))
        (should (search-forward "Original body" nil t)))
      (should-not (org-reason--entries "inbox" (lambda () (org-entry-get nil "ID"))))
      (should (= 1 (length (org-reason--entries "" (lambda () (equal (org-entry-get nil "ID") id)))))))))

;; @GTD03
(ert-deftest org-reason-test-invalid-clarification-keeps-inbox ()
  (org-reason-test-workspace
    (let ((id (org-reason-capture-text "Wait for something")))
      (org-reason-test-at id
        (should-error (org-reason-clarify-entry "delegate"))
        (should-not (org-entry-get nil "OR_TYPE"))
        (should (string-suffix-p "inbox/inbox.org" buffer-file-name))))))

;; @GTD02
(ert-deftest org-reason-test-project-has-single-next-action-and-audit ()
  (org-reason-test-workspace
    (let ((id (org-reason-capture-text "Article is ready to publish")))
      (org-reason-test-at id (org-reason-clarify-entry "project" '(:next "Draft one causal claim" :context "@computer")))
      (should-not (org-reason-projects-without-next-action))
      (org-reason-test-at id
        (outline-next-heading)
        (let ((org-inhibit-logging t)) (org-todo "DONE"))
        (save-buffer))
      (should (= 1 (length (org-reason-projects-without-next-action)))))))

;; @GTD03
(ert-deftest org-reason-test-waiting-records-person-and-delegation-date ()
  (org-reason-test-workspace
    (let ((id (org-reason-capture-text "A response arrives")))
      (org-reason-test-at id (org-reason-clarify-entry "delegate" '(:person "Named collaborator")))
      (org-reason-test-at id
        (should (equal (org-get-todo-state) "WAIT"))
        (should (equal (org-entry-get nil "OR_WAITING_FOR") "Named collaborator"))
        (should (org-entry-get nil "OR_DELEGATED_ON"))))))

;; @GTD04
(ert-deftest org-reason-test-incubation-is-not-next-action ()
  (org-reason-test-workspace
    (let ((id (org-reason-capture-text "Maybe study Mandarin")))
      (org-reason-test-at id (org-reason-clarify-entry "someday"))
      (org-reason-test-at id (should (equal (org-get-todo-state) "SOMEDAY")))
      (should-not (org-reason--entries "gtd" (lambda () (equal (org-get-todo-state) "NEXT")))))))

;; @GTD05
(ert-deftest org-reason-test-real-date-required-only-for-calendar-or-tickler ()
  (org-reason-test-workspace
    (let ((id (org-reason-capture-text "Appointment")))
      (org-reason-test-at id
        (should-error (org-reason-clarify-entry "calendar" '(:date "2026-02-31")))
        (org-reason-clarify-entry "calendar" '(:date "2026-11-14")))
      (org-reason-test-at id (should (org-entry-get nil "SCHEDULED"))))))

;; @MED01 @MED02
(ert-deftest org-reason-test-media-original-and-link-survive-refile ()
  (org-reason-test-workspace
    (let ((source (expand-file-name "original audio.wav" temporary)))
      (with-temp-file source (insert "Synthetic audio bytes"))
      (let* ((id (org-reason-import-file source "audio")) (digest (org-reason--sha256-file source)) original)
        (org-reason-test-at id
          (setq original (org-reason-path (org-entry-get nil "OR_ORIGINAL")))
          (org-reason-clarify-entry "reference"))
        (should (file-exists-p source))
        (should (equal digest (org-reason--sha256-file original)))
        (org-reason-test-at id (should (search-forward "[[reason-file:media/" nil t)))
        (org-reason-add-derivative id "Machine interpretation" "transcript")
        (org-reason-test-at id (should (equal (org-entry-get nil "OR_DERIVATIVE_REVIEW") "pending")))
        (should (equal digest (org-reason--sha256-file original)))))))

;; @CAP04
(ert-deftest org-reason-test-drop-import-is-repeatable-and-does-not-delete ()
  (org-reason-test-workspace
    (org-reason-initialize)
    (let ((file (org-reason-path "inbox/drop/handwriting.jpg")))
      (with-temp-file file (insert "Synthetic image bytes"))
      (should (= (plist-get (org-reason-import-drop) :imported) 1))
      (should (= (plist-get (org-reason-import-drop) :skipped) 1))
      (should (file-exists-p file)))))

;; @LRN01 @LRN03
(ert-deftest org-reason-test-prediction-original-cannot-be-rewritten-by-freeze ()
  (org-reason-test-workspace
    (let* ((id (org-reason-create-experiment "Synthetic experiment" "I expect one completed draft." "2026-11-14"))
           snapshot)
      (org-reason-test-at id
        (org-reason-freeze-prediction 0.8 "One draft is completed by the review date" t)
        (setq snapshot (org-reason--json-read (org-reason--forecast-path id)))
        (should-error (org-reason-freeze-prediction 0.2 "Changed prediction" t)))
      (should (equal (cdr (assoc "statement" snapshot)) "I expect one completed draft."))
      (org-reason-add-result id "supported" "One draft was completed." "yes" "relief" "Continue for one more trial")
      (should (equal (cdr (assoc "probability" (org-reason--json-read (org-reason--forecast-path id)))) 0.8))
      (let ((stats (org-reason-calibration-data)))
        (should (= (plist-get stats :scored) 1))
        (should (< (abs (- (plist-get stats :brier) 0.04)) 0.000001)))
      (should-error (org-reason-add-result id "contradicted" "Rewrite it" "no")))))

;; @LRN02
(ert-deftest org-reason-test-retrospective-and-unresolved-not-silently-scored ()
  (org-reason-test-workspace
    (let ((past (org-reason-create-experiment "Retrospective" "Already known." "2026-11-14"))
          (open (org-reason-create-experiment "Open" "Still unknown." "2026-11-14")))
      (org-reason-test-at past (org-reason-freeze-prediction 0.9 "An event occurs" nil))
      (org-reason-add-result past "supported" "It already happened." "yes")
      (org-reason-test-at open (org-reason-freeze-prediction 0.7 "A future event occurs" t))
      (let ((stats (org-reason-calibration-data)))
        (should (= (plist-get stats :frozen) 2))
        (should (= (plist-get stats :eligible) 1))
        (should (= (plist-get stats :unresolved) 1))
        (should-not (plist-get stats :brier))))))

;; @GTD07
(ert-deftest org-reason-test-review-preserves-answers-on-repeat ()
  (org-reason-test-workspace
    (org-reason-review)
    (goto-char (point-max)) (insert "A decision already made.\n") (save-buffer)
    (org-reason-review)
    (should (save-excursion (goto-char (point-min)) (search-forward "A decision already made." nil t)))))

(ert-deftest org-reason-test-dashboard-and-agenda-build-in-empty-workspace ()
  (org-reason-test-workspace
    (org-reason-dashboard)
    (should (string-match-p "0 unclarified" (buffer-string)))
    (org-reason-agenda)
    (should (derived-mode-p 'org-agenda-mode))))

(ert-deftest org-reason-test-view-keys-stay-in-their-buffer ()
  (org-reason-test-workspace
    (org-reason-dashboard)
    (should (eq (key-binding (kbd "g")) #'org-reason-dashboard))
    (should (eq (key-binding (kbd "q")) #'quit-window))
    (with-temp-buffer
      (org-mode)
      (should (eq (key-binding (kbd "g")) #'org-self-insert-command)))))

(ert-deftest org-reason-test-agenda-redo-keeps-projects ()
  (org-reason-test-workspace
    (org-reason-agenda)
    (let ((id (org-reason-capture-text "A project added after the agenda opened")))
      (org-reason-test-at id
        (org-reason-clarify-entry "project" '(:next "Its first action" :context "@computer"))))
    (with-current-buffer org-agenda-buffer-name
      (org-agenda-redo)
      (should (string-match-p "Its first action" (buffer-string)))
      (should (string-match-p "A project added after the agenda opened" (buffer-string))))))

(ert-deftest org-reason-test-links-open-only-views ()
  (org-reason-test-workspace
    (org-reason-link-follow "inbox" nil)
    (should (string-suffix-p "inbox/inbox.org" buffer-file-name))
    (should-error (org-reason-link-follow "freeze-prediction" nil) :type 'user-error)))

(ert-deftest org-reason-test-tutorial-starts-a-separate-demo-emacs ()
  (let (call)
    (cl-letf (((symbol-function 'call-process) (lambda (&rest args) (setq call args) nil))
              ((symbol-function 'display-graphic-p) (lambda (&rest _) t))
              ((symbol-function 'file-executable-p) (lambda (_) t)))
      (org-reason-tutorial))
    (should (equal (nth 0 call) (expand-file-name invocation-name invocation-directory)))
    (should (equal (nth 2 call) 0))     ; detached: never waits for it
    (let ((args (nthcdr 4 call)))
      (should (equal (car args) "-Q"))
      (should (equal (cadr (member "-L" args))
                     (file-name-directory (locate-library "org-reason-demo"))))
      (should (equal (last args 2) '("-l" "org-reason-demo"))))
    (should (eq (lookup-key org-reason-command-map (kbd "h")) #'org-reason-tutorial))))

(defun org-reason-test-load-roam ()
  "Act as if Org-roam had just loaded: run its after-load hooks, then forget it."
  (unwind-protect (provide 'org-roam)
    (setq features (delq 'org-roam features)
          after-load-alist (assq-delete-all 'org-roam after-load-alist))))

(ert-deftest org-reason-test-roam-indexes-only-knowledge ()
  (org-reason-test-workspace
    (let ((org-roam-directory temporary)
          (org-roam-file-exclude-regexp (list "attachments/")))
      (org-reason-mode 1)
      (should (equal org-roam-file-exclude-regexp '("attachments/")))
      (org-reason-test-load-roam)       ; Org-roam may load after the mode
      (let ((regexp (car org-roam-file-exclude-regexp)))
        (should (string-match-p regexp "data/gtd/actions.org"))
        (should (string-match-p regexp "data/inbox/inbox.org"))
        (should-not (string-match-p regexp "data/knowledge/notes/x.org"))
        (should-not (string-match-p regexp "20230101-a-note.org")))
      (org-reason-mode -1)
      (should (equal org-roam-file-exclude-regexp '("attachments/"))))))

(ert-deftest org-reason-test-roam-left-alone-outside-its-root ()
  (org-reason-test-workspace
    (let ((org-roam-directory (expand-file-name "elsewhere" temporary))
          (org-roam-file-exclude-regexp nil))
      (org-reason-mode 1)
      (org-reason-test-load-roam)
      (should-not org-roam-file-exclude-regexp))))

(ert-deftest org-reason-test-ascii-only-files-are-saved-as-utf-8 ()
  ;; On Windows the default encoding is not UTF-8, so saving a non-ASCII
  ;; character into a file read as `undecided' would stop and ask.
  (org-reason-test-workspace
    (org-reason-initialize)
    (with-current-buffer (find-file-noselect (org-reason-path "learning/experiments.org"))
      (should (eq (coding-system-base buffer-file-coding-system) 'undecided))
      (org-reason--prefer-utf-8)
      (should (eq buffer-file-coding-system 'utf-8-unix)))))

(ert-deftest org-reason-test-paths-use-one-canonical-directory-name ()
  ;; Windows gives a directory a short 8.3 name and a long one; macOS's
  ;; temporary directory is behind a symlink.  Paths use the truename.
  (org-reason-test-workspace
    (should (equal (org-reason-path "inbox/inbox.org")
                   (expand-file-name "inbox/inbox.org" (file-truename org-reason-directory))))))

(ert-deftest org-reason-test-browser-protocol-captures-into-inbox ()
  (org-reason-test-workspace
    (org-reason-mode 1)
    (org-protocol-check-filename-for-protocol
     (concat "org-protocol://reason-capture?url=" (url-hexify-string "https://example.org/a b")
             "&title=" (url-hexify-string "A page title")
             "&body=" (url-hexify-string "Selected words, with spaces"))
     nil nil)
    (let ((entry (car (org-reason--entries "inbox" (lambda () (org-entry-get nil "ID"))))))
      (should (equal (plist-get entry :title) "A page title"))
      (should (equal (org-reason--property entry "OR_SOURCE") "https://example.org/a b"))
      (should (equal (org-reason--property entry "OR_METHOD") "browser"))
      (org-reason-test-at (plist-get entry :id)
        (should (search-forward "Selected words, with spaces" nil t))))))

;; @RC10
(ert-deftest org-reason-test-emacs-python-real-schema-round-trip ()
  (org-reason-test-workspace
    (org-reason-initialize)
    (let ((file (org-reason--commons-path "synthetic")))
      (org-reason--ensure-directory (file-name-directory file))
      (org-reason--rc-call file '(("op" . "new") ("project" . "Synthetic commons") ("participant" . "tester") ("name" . "Test participant")))
      (let* ((inspection (org-reason--rc-inspect file))
             (result (org-reason--rc-call file (list '("op" . "add-node") '("by" . "tester") '("tree" . "goal")
                                                '("kind" . "goal") '("text" . "Deutsch üben — 学习")
                                                (cons "expected_sha256" (gethash "sha256" inspection))))))
        (should (equal (gethash "status" result) "proposed"))
        (org-reason-reasoning-view file)
        (should (string-match-p "Deutsch üben" (buffer-string)))))))

(ert-deftest org-reason-test-ids-cannot-escape-filename-component ()
  (should-not (string-match-p "/" (org-reason--id-filename "../../private")))
  (should (equal (org-reason--id-filename "normal-123") "normal-123")))

;; @CAP03
(ert-deftest org-reason-test-standard-org-capture-really-finalizes ()
  (org-reason-test-workspace
    (org-reason-mode 1)
    (org-capture nil org-reason-capture-key)
    (insert "Captured through Org's existing interface")
    (org-capture-finalize)
    (let ((entries (org-reason--entries "inbox" (lambda () (org-entry-get nil "ID")))))
      (should (= (length entries) 1))
      (should (equal (plist-get (car entries) :title) "Captured through Org's existing interface")))))

;; @GTD06
(ert-deftest org-reason-test-failed-refile-keeps-source-material ()
  (org-reason-test-workspace
    (let ((id (org-reason-capture-text "Recover this after a failed write")))
      (org-reason-test-at id
        (cl-letf (((symbol-function 'org-reason--buffer) (lambda (_file) (error "Synthetic destination failure"))))
          (should-error (org-reason-clarify-entry "next-action"))))
      (org-reason-test-at id
        (should (string-suffix-p "inbox/inbox.org" buffer-file-name))
        (should (search-forward "Recover this after a failed write" nil t))))))

;; @RC10
(ert-deftest org-reason-test-rc-link-selects-the-reasoning-object ()
  (org-reason-test-workspace
    (org-reason-initialize)
    (let ((file (org-reason--commons-path "synthetic")))
      (org-reason--ensure-directory (file-name-directory file))
      (org-reason--rc-call file '(("op" . "new") ("project" . "Test") ("participant" . "tester") ("name" . "Tester")))
      (let* ((inspection (org-reason--rc-inspect file))
             (result (org-reason--rc-call file (list '("op" . "add-node") '("by" . "tester") '("kind" . "goal")
                                                '("text" . "Find this exact reasoning object")
                                                (cons "expected_sha256" (gethash "sha256" inspection))))))
        (org-reason-rc-follow (concat "synthetic/" (gethash "id" result)) nil)
        (should (equal (org-entry-get nil "CUSTOM_ID") (gethash "id" result)))))))

(ert-deftest org-reason-test-refile-rebases-relative-file-links ()
  (org-reason-test-workspace
    (let ((id (org-reason-capture-text "Authored Org links")))
      (org-reason-test-at id
        (org-end-of-subtree t t)
        (insert "[[file:../source.txt::42][original label]]\n[[file:/absolute/fixed.txt]]\n"
                "#+begin_src text\n[[file:literal-example.txt]]\n#+end_src\n")
        (org-reason-clarify-entry "reference"))
      (org-reason-test-at id
        (should (search-forward "[[file:../../source.txt::42][original label]]" nil t))
        (should (search-forward "[[file:/absolute/fixed.txt]]" nil t))
        (should (search-forward "[[file:literal-example.txt]]" nil t))))))

;; @GTD09
(ert-deftest org-reason-test-engage-filters-context-time-and-completed-parent ()
  (org-reason-test-workspace
    (org-reason-next-action "Short computer action" "@computer" "0:10")
    (org-reason-next-action "Long computer action" "@computer" "2:00")
    (org-reason-next-action "Call somebody" "@calls" "0:05")
    (let ((id (org-reason-capture-text "Already completed project")))
      (org-reason-test-at id (org-reason-clarify-entry "project" '(:next "Child of completed project" :context "@computer")))
      (org-reason-test-at id (let ((org-inhibit-logging t)) (org-todo "DONE")) (save-buffer)))
    (org-reason-engage "@computer" "15" "")
    (should (string-match-p "Short computer action" (buffer-string)))
    (should-not (string-match-p "Long computer action" (buffer-string)))
    (should-not (string-match-p "Call somebody" (buffer-string)))
    (should-not (string-match-p "Child of completed project" (buffer-string)))
    (should-error (org-reason-engage "" "nonsense" ""))))

(ert-deftest org-reason-test-existing-commons-is-discoverable ()
  (org-reason-test-workspace
    (org-reason-initialize)
    (let ((file (org-reason--commons-path "synthetic")))
      (org-reason--ensure-directory (file-name-directory file))
      (org-reason--rc-call file '(("op" . "new") ("project" . "Test") ("participant" . "tester") ("name" . "Tester")))
      (with-temp-buffer
        (cl-letf (((symbol-function 'completing-read) (lambda (&rest _args) "synthetic")))
          (should (equal (org-reason--choose-commons) file)))))))

;; @MED05
(ert-deftest org-reason-test-async-machine-output-is-separate-and-pending ()
  (org-reason-test-workspace
    (let ((source (expand-file-name "handwriting.jpg" temporary))
          (org-reason-ocr-command (list (org-reason-python) "-c" "import sys; print('Synthetic OCR result')" "%f")))
      (with-temp-file source (insert "Synthetic original"))
      (let* ((id (org-reason-import-file source "handwriting")) process original)
        (org-reason-test-at id
          (setq original (org-reason-path (org-entry-get nil "OR_ORIGINAL")))
          (setq process (org-reason-derive "ocr")))
        (let ((deadline (+ (float-time) 5)))
          (while (and (process-live-p process) (< (float-time) deadline))
            (accept-process-output process 0.05))
          (accept-process-output process 0.05))
        (should (eq (process-status process) 'exit))
        (org-reason-test-at id
          (should (equal (org-entry-get nil "OR_DERIVATIVE_REVIEW") "pending"))
          (should (file-exists-p (org-reason-path (org-entry-get nil "OR_LATEST_DERIVATIVE")))))
        (should (equal (org-reason--sha256-file source) (org-reason--sha256-file original)))))))

(ert-deftest org-reason-test-clarification-preserves-topics-and-clears-reference-task-state ()
  (org-reason-test-workspace
    (let ((action (org-reason-capture-text "Read one paragraph"))
          (reference (org-reason-capture-text "TODO This is actually reference material")))
      (org-reason-test-at action
        (org-set-tags '("german"))
        (org-reason-clarify-entry "next-action" '(:context "@computer")))
      (org-reason-test-at action
        (should (member "german" (org-get-tags)))
        (should (member "@computer" (org-get-tags))))
      (org-reason-test-at reference (org-reason-clarify-entry "reference"))
      (org-reason-test-at reference (should-not (org-get-todo-state))))))

(ert-deftest org-reason-test-duplicate-id-report-identifies-both-files ()
  (org-reason-test-workspace
    (let ((id (org-reason-capture-text "A recoverable source")))
      (org-reason--append (org-reason-path "gtd/actions.org") "Synthetic interrupted refile" ""
                      (list (cons "ID" id)) "NEXT")
      (let ((duplicates (plist-get (org-reason-health-data) :duplicates)))
        (should (= (length duplicates) 2))
        (should-not (equal (plist-get (car duplicates) :file)
                           (plist-get (cadr duplicates) :file)))))))

(ert-deftest org-reason-test-original-viewer-includes-reviewed-experiments ()
  (org-reason-test-workspace
    (let ((id (org-reason-create-experiment "Reviewed original" "Preserve this original expectation." "2026-11-14")))
      (org-reason-test-at id (org-reason-freeze-prediction nil nil nil))
      (org-reason-add-result id "inconclusive" "Synthetic interface check only.")
      (cl-letf (((symbol-function 'completing-read)
                 (lambda (_prompt collection &rest _args) (caar collection))))
        (should-error (org-reason--choose-experiment))
        (should (equal (org-reason--choose-experiment t) id))
        (call-interactively #'org-reason-show-forecast))
      (with-current-buffer "*Org Reason: original forecast*"
        (should (string-match-p "Preserve this original expectation" (buffer-string)))))))

;; @CAP06
(ert-deftest org-reason-test-browser-text-is-inert-through-clarification ()
  (org-reason-test-workspace
    (org-reason--protocol
     '(:title "Web -*- eval: (error \"unsafe\") -*- [[elisp:(error \"unsafe\")]]"
       :url "https://example.org"
       :body "Selected text\r\n* A bullet\r\n#+end_example\r\n#+TODO: BAD | WORSE\r\n#+begin_src emacs-lisp\r\n(error \"unsafe\")\r\n#+end_src\r\nLocal Variables:\r\neval: (error \"unsafe\")\r\nEnd:\r\nLast line"))
    (let* ((entries (org-reason--entries "inbox" (lambda () t)))
           (id (plist-get (car entries) :id)))
      (should (= (length entries) 1))
      (org-reason-test-at id
        (should (= 1 (length (org-element-map (org-element-parse-buffer) 'example-block #'identity))))
        (should-not (org-element-map (org-element-parse-buffer) '(src-block link) #'identity))
        (should-not (hack-local-variables--find-variables))
        (org-reason-clarify-entry "reference"))
      (org-reason-test-at id
        (should (search-forward ",* A bullet" nil t))
        (should (search-forward "Last line" nil t))
        (should-not (save-excursion (goto-char (point-min)) (search-forward "-*-" (line-end-position) t))))
      (should-not (org-reason--entries "inbox" (lambda () t))))))

;; @CAP03
(ert-deftest org-reason-test-org-capture-selection-is-literal ()
  (org-reason-test-workspace
    (org-reason-mode 1)
    (let ((org-capture-initial "* Selected bullet\n%(error \"Do not expand\")\n%^{Do not prompt}\n#+end_example"))
      (org-capture nil org-reason-capture-key)
      (insert "Selected text")
      (org-capture-finalize))
    (let* ((entries (org-reason--entries "inbox" (lambda () t)))
           (id (plist-get (car entries) :id)))
      (should (= (length entries) 1))
      (org-reason-test-at id
        (should (search-forward ",* Selected bullet" nil t))
        (should (search-forward "%^{Do not prompt}" nil t))))))

;; @CAP07
(ert-deftest org-reason-test-device-inboxes-and-text-drop ()
  (org-reason-test-workspace
    (let* ((legacy (org-reason-capture-text "Legacy inbox"))
           (org-reason-inbox-per-device t)
           (org-reason-device "Phone/Notebook")
           (phone (org-reason-capture-text "Phone inbox"))
           (drop (org-reason-path "inbox/drop/Phone.org"))
           (org-reason-device "Desktop"))
      (with-temp-file drop (insert "* Read the next paragraph\n"))
      (should (equal (org-reason-import-drop) '(:imported 1 :skipped 0)))
      (let* ((entries (org-reason--entries "inbox" (lambda () t)))
             (capture (seq-find (lambda (entry) (org-reason--property entry "OR_DROP_SHA256")) entries)))
        (should (= 3 (length entries)))
        (should-not (org-reason--property capture "OR_ORIGINAL"))
        (should (equal (org-reason-import-drop) '(:imported 0 :skipped 1)))
        (should (file-exists-p drop))
        (org-reason-test-at phone (org-reason-clarify-entry "next-action"))
        (org-reason-test-at legacy (org-reason-clarify-entry "reference"))
        (should (= 1 (plist-get (org-reason-health-data) :inbox)))))))

;; @GTD10
(ert-deftest org-reason-test-retry-finishes-a-complete-project-move ()
  (org-reason-test-workspace
    (let* ((id (org-reason-capture-text "Prepare the sample report"))
           (inbox (org-reason--capture-file))
           (project (org-reason-path (concat "gtd/projects/" id ".org")))
           (save (symbol-function 'org-reason--save-buffer)))
      (org-reason-test-at id
        (cl-letf (((symbol-function 'org-reason--save-buffer)
                   (lambda ()
                     (if (equal buffer-file-name inbox) (error "Synthetic source write failure")
                       (funcall save)))))
          (should-error (org-reason-clarify-entry "project" '(:next "Draft the first paragraph"))))
        (should (equal (org-entry-get nil "ID") id))
        (should-error (org-reason-clarify-entry "next-action") :type 'user-error)
        (should (equal id (org-reason-clarify-entry "project" '(:next "Different retry input")))))
      (let ((entries (org-reason--entries "gtd/projects" (lambda () (org-entry-get nil "ID")))))
        (should (= (length entries) 2))
        (should (equal (plist-get (cadr entries) :title) "Draft the first paragraph"))
        (should (equal (plist-get (cadr entries) :state) "NEXT")))
      (should (file-exists-p project))
      (should-not (org-reason--entries "inbox" (lambda () t))))))

;; @GTD05
(ert-deftest org-reason-test-calendar-keeps-a-time-and-tickler-rejects-it ()
  (org-reason-test-workspace
    (let ((id (org-reason-capture-text "Dentist")))
      (org-reason-test-at id
        (should-error (org-reason-clarify-entry "calendar" '(:date "2026-11-14 24:00")))
        (should-error (org-reason-clarify-entry "tickler" '(:date "2026-11-14 15:00")))
        (org-reason-clarify-entry "calendar" '(:date "2026-11-14 15:00")))
      (org-reason-test-at id
        (should (string-match-p "15:00" (org-entry-get nil "SCHEDULED")))))))

;; @GTD11
(ert-deftest org-reason-test-archive-completed-actions-preserves-ids ()
  (org-reason-test-workspace
    (let ((done (org-reason-capture-text "Completed action"))
          (next (org-reason-next-action "Open action")))
      (org-reason-test-at done (org-reason-clarify-entry "done-now"))
      (should (= 1 (org-reason-archive-actions)))
      (should (= 0 (org-reason-archive-actions)))
      (org-reason-test-at done
        (should (file-equal-p buffer-file-name (org-reason-path "archive/actions.org")))
        (should (equal (org-get-todo-state) "DONE"))
        (should (search-forward "Completed action" nil t)))
      (org-reason-test-at next
        (should (file-equal-p buffer-file-name (org-reason-path "gtd/actions.org")))))))

;; @LRN05
(ert-deftest org-reason-test-calibration-verifies-bytes-and-compares-to-baseline ()
  (org-reason-test-workspace
    (let ((high (org-reason-create-experiment "High" "Test high" "2000-01-01"))
          (low (org-reason-create-experiment "Low" "Test low" "2000-01-01")))
      (org-reason-test-at high (org-reason-freeze-prediction 1.0 "Event H" t))
      (org-reason-test-at low (org-reason-freeze-prediction 0.25 "Event L" t))
      (org-reason-add-result high "supported" "Yes observed." "yes")
      (org-reason-add-result low "supported" "No observed." "no")
      (let ((data (org-reason-calibration-data)))
        (should (= 2 (plist-get data :scored)))
        (should (= 0.25 (plist-get data :baseline)))
        (should (= 0.03125 (plist-get data :brier)))
        (should (equal (mapcar (lambda (bucket) (plist-get bucket :low))
                              (plist-get data :buckets)) '(20 80))))
      (org-reason-dashboard)
      (should (string-match-p "Constant-rate baseline 0.250" (buffer-string)))
      (write-region " " nil (org-reason--forecast-path high) t 'silent)
      (should-error (org-reason-show-forecast high) :type 'user-error)
      (let ((data (org-reason-calibration-data)))
        (should (= 1 (plist-get data :scored)))
        (should (= 1 (length (plist-get data :problems))))))))

;; @LRN06
(ert-deftest org-reason-test-dashboard-reviews-the-selected-forecast-and-links-an-action ()
  (org-reason-test-workspace
    (let ((id (org-reason-create-experiment "Review me" "The cue helps" "2000-01-01"))
          (answers '("Started after one minute." "" "Leave the page open." "Leave the page open.")))
      (org-reason-test-at id (org-reason-freeze-prediction 0.75 "Start within two minutes" t))
      (org-reason-dashboard)
      (should (search-forward (format "[[org-reason-result:%s][Record outcome]]" id) nil t))
      (cl-letf (((symbol-function 'completing-read)
                 (lambda (_prompt choices &rest _) (car choices)))
                ((symbol-function 'read-string) (lambda (&rest _) (pop answers)))
                ((symbol-function 'y-or-n-p) (lambda (&rest _) t)))
        (org-reason--review-forecast-link id nil))
      (let ((result (org-reason--property
                     (car (org-reason--experiments)) "OR_RESULT_ID")))
        (should (equal (org-entry-get nil "OR_REASON") (concat "id:" result)))
        (should (equal (org-get-todo-state) "NEXT"))
        (with-current-buffer "*Org Reason: original forecast*"
          (should (string-match-p "Forecast probability: 75%" (buffer-string)))
          (should (string-match-p "Start within two minutes" (buffer-string))))))))

;; @UX01
(ert-deftest org-reason-test-dashboard-scans-without-visiting-and-sees-live-edits ()
  (org-reason-test-workspace
    (let* ((id (org-reason-capture-text "Need a project"))
           project)
      (org-reason-test-at id
        (org-reason-clarify-entry "project" '(:next "Draft the first paragraph")))
      (setq project (org-reason-path (concat "gtd/projects/" id ".org")))
      (kill-buffer (get-file-buffer project))
      (org-reason-dashboard)
      (should-not (get-file-buffer project))
      (should-not (plist-get (org-reason-health-data) :projects))
      (with-current-buffer (org-reason--buffer project)
        (goto-char (point-min))
        (re-search-forward "^\\*\\* NEXT ")
        (let ((org-inhibit-logging t)) (org-todo "DONE"))
        (should (= 1 (length (plist-get (org-reason-health-data) :projects))))))))

;; @UX02
(ert-deftest org-reason-test-example-opens-read-only-with-a-folded-outcome ()
  (org-reason-test-workspace
    (org-reason-link-follow "example" nil)
    (let ((example (current-buffer)))
      (should (equal (buffer-name) "*Org Reason Example*"))
      (should buffer-read-only)
      (should (eq (local-key-binding (kbd "q")) #'quit-window))
      (search-forward "I started within")
      (should (org-fold-folded-p (point)))
      (goto-char (point-min))
      (re-search-forward "^\\* Outcome")
      (org-cycle)
      (search-forward "I started within")
      (should-not (org-fold-folded-p (point)))
      (org-reason-example)
      (should (eq example (current-buffer))))
    (should-not (file-exists-p org-reason-directory))))

;; @UX03
(ert-deftest org-reason-test-prefix-can-move-or-be-disabled ()
  (org-reason-test-workspace
    (unwind-protect
        (let ((org-reason-key-prefix "C-c z"))
          (org-reason-mode 1)
          (should (eq (key-binding (kbd "C-c z ?")) #'org-reason-menu))
          (should-not (lookup-key org-reason-mode-map (kbd "C-c r")))
          (let ((org-reason-key-prefix nil))
            (org-reason-mode 1)
            (should-not (lookup-key org-reason-mode-map (kbd "C-c z")))))
      (org-reason--bind-prefix org-reason-key-prefix))))

;; @RC14
(ert-deftest org-reason-test-python-setup-configures-only-a-working-environment ()
  (org-reason-test-workspace
    (let* ((directory (expand-file-name "venv" temporary))
           (python (expand-file-name (if (eq system-type 'windows-nt)
                                        "Scripts/python.exe" "bin/python") directory))
           (pip-status 1)
           saved calls)
      (cl-letf (((symbol-function 'org-reason--system-python) (lambda () "bootstrap-python"))
                ((symbol-function 'file-executable-p) (lambda (file) (equal file python)))
                ((symbol-function 'display-buffer) #'ignore)
                ((symbol-function 'customize-save-variable)
                 (lambda (symbol value) (setq saved (cons symbol value))))
                ((symbol-function 'call-process)
                 (lambda (program _in _out _display &rest arguments)
                   (push (cons program arguments) calls)
                   (if (equal program python) pip-status 0))))
        (should-error (org-reason-setup-python directory) :type 'user-error)
        (should-not saved)
        (setq pip-status 0)
        (org-reason-setup-python directory)
        (should (equal saved (cons 'org-reason-python-command python)))
        (should (equal (car calls) (list python "-m" "pip" "install" "-r"
                                        (expand-file-name "requirements.txt" org-reason--package-root))))
        (should (equal (cadr calls) (list "bootstrap-python" "-m" "venv" directory)))))))

;; @GTD12
(ert-deftest org-reason-test-capture-and-clarify-acts-on-the-new-entry ()
  (org-reason-test-workspace
    (let (id)
      (cl-letf (((symbol-function 'completing-read)
                 (lambda (prompt &rest _) (if (string-prefix-p "Context" prompt) "@computer" "next-action")))
                ((symbol-function 'read-string)
                 (lambda (prompt &optional initial &rest _)
                   (if (string-prefix-p "Estimated" prompt) "0:10" (or initial "Do it"))))
                ((symbol-function 'pop-to-buffer-same-window) #'set-buffer))
        (setq id (org-reason-capture-and-clarify "Call the dentist")))
      (should-not (org-reason--entries "inbox" (lambda () (org-entry-get nil "ID"))))
      (should (= 1 (length (org-reason--entries "" (lambda ()
                                                     (and (equal (org-get-todo-state) "NEXT")
                                                          (org-entry-get nil "ID"))))))))))

;; @GTD13
(ert-deftest org-reason-test-clarify-prompts-offer-help ()
  (org-reason-test-workspace
    ;; Every prompt of one clarification, not just the first, gets the help key.
    (let ((id (org-reason-capture-text "Plan a trip")) (bound nil))
      (cl-letf (((symbol-function 'completing-read)
                 (lambda (prompt &rest _)
                   (push (memq #'org-reason--clarify-bind-help minibuffer-setup-hook) bound)
                   (if (string-prefix-p "Context" prompt) "@computer" "project")))
                ((symbol-function 'read-string)
                 (lambda (prompt &optional initial &rest _)
                   (push (memq #'org-reason--clarify-bind-help minibuffer-setup-hook) bound)
                   (if (string-prefix-p "Estimated" prompt) "" (or initial "Go"))))
                ((symbol-function 'org-get-heading) (lambda (&rest _) "Trip")))
        (org-reason-test-at id (org-reason-clarify)))
      (should (>= (length bound) 4))
      (should (cl-every #'identity bound))
      (should-not (memq #'org-reason--clarify-bind-help minibuffer-setup-hook)))
    ;; The help text matches the prompt being answered.
    (dolist (case '(("First available physical action: " . "Start with a verb")
                    ("Context: " . "@computer")))
      (cl-letf (((symbol-function 'minibuffer-prompt) (lambda () (car case))))
        (org-reason-clarify-help)
        (with-current-buffer "*Org Reason help*"
          (should (string-match-p (regexp-quote (cdr case)) (buffer-string))))))
    (cl-letf (((symbol-function 'minibuffer-prompt) (lambda () "Unknown: ")))
      (org-reason-clarify-help)
      (with-current-buffer "*Org Reason help*"
        (should (string-match-p "No help" (buffer-string)))))))

;;; org-reason-tests.el ends here
