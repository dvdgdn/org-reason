;;; org-reason-media.el --- Originals, imports, and optional derivation -*- lexical-binding: t; -*-
;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Code:
(require 'org-reason-core)
(require 'org-reason-capture)
(require 'org-reason-learning)

(defcustom org-reason-ocr-command nil
  "Explicit OCR argv list, e.g. (\"tesseract\" \"%f\" \"stdout\" \"-l\" \"eng+deu\").
The program must emit only its UTF-8 interpretation to stdout.  %f is replaced
by the original filename.  No shell is used.  Nothing runs automatically."
  :type '(repeat string) :group 'org-reason)
(defcustom org-reason-transcription-command nil
  "Explicit local transcription argv; same contract as `org-reason-ocr-command'.
Nil means no backend is configured.  Microphone recording is done by your
existing recorder; import its audio file without waiting for a transcript."
  :type '(repeat string) :group 'org-reason)

(defun org-reason-import-file (source &optional method)
  "Copy SOURCE into a capture's media directory and preserve its digest.
Return the new capture ID.  Never move or delete the source file."
  (interactive (list (read-file-name "Import original: " nil nil t)
                     (completing-read "Method: " '("audio" "handwriting" "file") nil t)))
  (unless (and (file-regular-p source) (file-readable-p source)) (user-error "Choose a readable regular file"))
  (org-reason-initialize)
  (let* ((id (org-id-new))
         (extension (or (file-name-extension source) "bin"))
         (extension (if (string-match-p "\\`[[:alnum:]]+\\'" extension) extension "bin"))
         (relative (concat "media/" id "/original." extension))
         (destination (org-reason-path relative))
         digest)
    (org-reason--ensure-directory (file-name-directory destination))
    (copy-file source destination nil t)
    (set-file-modes destination #o600)
    ;; Hash the preserved bytes, even if an external writer changed the source.
    (setq digest (org-reason--sha256-file destination))
    (org-reason--append
     (org-reason--capture-file) (file-name-nondirectory source)
     (format "Original: [[reason-file:%s][%s]]\n\nInterpretation may be added later.\n"
             relative
             (org-reason--clean (file-name-nondirectory source)))
     (append (list (cons "ID" id) (cons "OR_ORIGINAL" relative)
                   (cons "OR_ORIGINAL_NAME" (file-name-nondirectory source))
                   (cons "OR_SHA256" digest))
             (org-reason--capture-properties (or method "file") (expand-file-name source))))))

(defun org-reason-import-drop ()
  "Import files directly inside inbox/drop, skipping known hashes.
UTF-8 text (.txt, .text, .md, .org) becomes a plain capture.
Source files remain in place.  Subdirectories and symlinks are not traversed."
  (interactive)
  (org-reason-initialize)
  (let ((known (make-hash-table :test #'equal)) (imported 0) (skipped 0))
    (dolist (entry (org-reason--entries "" (lambda () (or (org-entry-get nil "OR_SHA256")
                                                         (org-entry-get nil "OR_DROP_SHA256")))))
      (puthash (or (org-reason--property entry "OR_DROP_SHA256")
                   (org-reason--property entry "OR_SHA256")) t known))
    (dolist (file (directory-files (org-reason-path "inbox/drop") t directory-files-no-dot-files-regexp))
      (when (and (file-regular-p file) (not (file-symlink-p file)))
        (let* ((plain (member (downcase (or (file-name-extension file) "")) '("txt" "text" "md" "org")))
               (bytes (when plain
                        (with-temp-buffer
                          (set-buffer-multibyte nil)
                          (insert-file-contents-literally file)
                          (buffer-string))))
               (digest (if plain (secure-hash 'sha256 bytes) (org-reason--sha256-file file)))
               (content (when plain (decode-coding-string bytes 'utf-8))))
          (if (or (gethash digest known) (and plain (string-blank-p content)))
              (cl-incf skipped)
            (if plain
                (org-reason--capture-plain-text content (file-name-nondirectory file) "drop" file
                                                (list (cons "OR_DROP_SHA256" digest)))
              (org-reason-import-file file "drop"))
            (puthash digest t known)
            (cl-incf imported)))))
    (message "Imported %d; skipped %d empty or already captured files" imported skipped)
    (list :imported imported :skipped skipped)))

(defun org-reason-add-derivative (id text kind &optional human-authored)
  "Preserve TEXT as a new KIND interpretation of capture ID.
Machine interpretations stay review-pending; originals are never replaced."
  (unless (member kind '("ocr" "transcript")) (user-error "Choose ocr or transcript"))
  (let* ((marker (org-reason--find-id id))
         (relative (concat "media/" (org-reason--id-filename id) "/" kind "-" (org-id-new) ".txt"))
         (file (org-reason-path relative)))
    (unless marker (user-error "Capture not found: %s" id))
    (when (string-empty-p (string-trim text)) (user-error "Interpretation is empty"))
    (org-reason--ensure-directory (file-name-directory file))
    (with-temp-buffer
      (insert text)
      (let ((coding-system-for-write 'utf-8-unix)) ; the same bytes on every OS
        (write-region (point-min) (point-max) file nil 'silent nil 'excl)))
    (set-file-modes file #o600)
    (with-current-buffer (marker-buffer marker)
      (save-excursion
        (goto-char marker)
        (org-entry-put nil "OR_LATEST_DERIVATIVE" relative)
        (org-entry-put nil "OR_DERIVATIVE_REVIEW" (if human-authored "human-authored" "pending"))
        (org-end-of-subtree t t)
        (insert (format "\nInterpretation (%s; %s; %s): [[reason-file:%s][text]]\n"
                        kind (if human-authored "human-authored" "machine; review pending")
                        (org-reason--now) relative))
        (org-reason--save-buffer)))
    file))

(defun org-reason-import-interpretation (file kind)
  "Attach an existing transcript or OCR FILE to the current capture."
  (interactive (list (read-file-name "Interpretation text: " nil nil t)
                     (completing-read "Kind: " '("transcript" "ocr") nil t)))
  (org-reason--require-entry)
  (let ((id (org-entry-get nil "ID"))
        (human (y-or-n-p "Was this interpretation authored by a person? ")))
    (org-reason-add-derivative id (with-temp-buffer (insert-file-contents file) (buffer-string)) kind human)))

(defun org-reason-derive (kind)
  "Explicitly run the configured KIND adapter on this entry's original.
The asynchronous program receives argv directly, never through a shell."
  (interactive (list (completing-read "Interpret original with: " '("ocr" "transcript") nil t)))
  (org-reason--require-entry)
  (let* ((id (org-entry-get nil "ID"))
         (relative (org-entry-get nil "OR_ORIGINAL"))
         (file (and relative (org-reason-path relative)))
         (command (if (equal kind "ocr") org-reason-ocr-command org-reason-transcription-command)))
    (unless (and file (file-readable-p file)) (user-error "This entry has no readable original"))
    (unless (and command (seq-every-p #'stringp command)) (user-error "Configure the local %s command first" kind))
    (unless (seq-some (lambda (arg) (string-match-p "%f" arg)) command)
      (user-error "The argv template must contain %%f"))
    (unless (executable-find (car command)) (user-error "Program not found: %s" (car command)))
    (let ((output (generate-new-buffer " *org-reason-interpretation*"))
          (errors (generate-new-buffer "*Org Reason: interpretation errors*")))
      (make-process
       :name (concat "org-reason-" kind "-" id) :buffer output :stderr errors
       :command (mapcar (lambda (arg) (replace-regexp-in-string "%f" file arg t t)) command)
       :coding 'utf-8-unix :noquery t
       :sentinel
       (lambda (process _event)
         (when (memq (process-status process) '(exit signal))
           (unwind-protect
               (if (and (eq (process-status process) 'exit) (zerop (process-exit-status process)))
                   (condition-case error-data
                       (progn
                         (org-reason-add-derivative id (with-current-buffer output (buffer-string)) kind)
                         (message "%s saved; check it against the original" kind)
                         (when (buffer-live-p errors) (kill-buffer errors)))
                     (error (message "Interpretation could not be attached: %s; output retained in %s"
                                     (error-message-string error-data) (buffer-name output))
                            (setq output nil)))
                 (with-current-buffer errors
                   (goto-char (point-max))
                   (insert (format "\nProcess status: %s / %s\n" (process-status process) (process-exit-status process))
                           (with-current-buffer output (buffer-string))))
                 (message "Interpretation failed; see %s" (buffer-name errors)))
             (when (buffer-live-p output) (kill-buffer output)))))))))

(defun org-reason-mark-interpretation-reviewed ()
  "Record the user's explicit check of the latest interpretation."
  (interactive)
  (org-reason--require-entry)
  (unless (org-entry-get nil "OR_LATEST_DERIVATIVE") (user-error "No interpretation attached"))
  (org-entry-put nil "OR_DERIVATIVE_REVIEW" "human-reviewed")
  (org-entry-put nil "OR_DERIVATIVE_REVIEWED_AT" (org-reason--now))
  (org-reason--save-buffer))

(provide 'org-reason-media)
;;; org-reason-media.el ends here
