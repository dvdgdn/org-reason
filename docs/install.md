# Install and set up

Org Reason needs Emacs 29.1+ with its bundled Org (9.6+). Capture, GTD, review,
media import and learning need nothing else. The Reason Commons commands also need
Python 3 with PyYAML; browser capture needs your OS to hand `org-protocol://`
links to Emacs.

## 1. The package

With Emacs 30, in your init:

```elisp
(use-package org-reason
  :vc (:url "https://github.com/dvdgdn/org-reason" :rev "v0.1.1")
  :custom
  (org-reason-directory "~/org/reason/")
  (org-reason-device (system-name))
  :config
  (org-reason-mode 1))
```

On Emacs 29, evaluate
`(package-vc-install "https://github.com/dvdgdn/org-reason" "v0.1.1")` with
`M-:`, then use the same block without the `:vc` line. These snippets pin
the latest tagged release. Update the tag when you choose a newer release.

To work on Org Reason itself, clone the repository and run
`M-x package-vc-install-from-checkout` on the clone. Use the same block
without the `:vc` line. After editing, use `M-x package-vc-rebuild` to
recompile it. The new commands below are available from a development checkout.

The data directory is created the first time the mode is turned on; loading the
library alone writes nothing. Your records stay there and never belong in this
repository.

| Setting | Default | What it is |
|---|---|---|
| `org-reason-directory` | `~/org/reason/` | Where your records live |
| `org-reason-device` | `(system-name)` | Stable device name recorded on each capture |
| `org-reason-inbox-per-device` | `nil` | Give each device its own inbox file |
| `org-reason-key-prefix` | `C-c r` | Customize the prefix. Set to `nil` to use `M-x org-reason-menu` |
| `org-reason-language` | `en` | Default language of new material |
| `org-reason-capture-key` | `r` | The `org-capture` template key, added only if free |
| `org-reason-roam-knowledge-only` | `t` | If the workspace is inside `org-roam-directory`, index only its `knowledge/` notes |
| `org-reason-python-command` | `nil` (find one) | Python for the Reason Commons commands |

## 2. Python, for the Reason Commons commands

`C-c r t …` runs `org_reason_commons.py`, beside the Elisp. With
`org-reason-python-command` left at `nil`, Org Reason uses `python3` or `python`;
on Windows it tries the `py` launcher first, since `python3` there is often only
a Microsoft Store placeholder. It needs PyYAML, plus `tzdata` on Windows, where
Python has no time-zone database. Both are in `requirements.txt`.

With Python 3 installed, run `M-x org-reason-setup-python` (also
`C-c r t P` with the default prefix). Choose the virtual environment
directory. The command creates or reuses the environment, runs pip with
the bundled requirements, and saves `org-reason-python-command` in your
Emacs customization file after installation succeeds. Pip downloads the
requirements using its normal package index settings.

For manual setup, create a venv with `python3 -m venv PATH` (or
`py -m venv PATH` on Windows), then run its Python with
`-m pip install -r requirements.txt` from the package directory.
Point `org-reason-python-command` to that interpreter.

If the Python you already have includes PyYAML, no setup is needed.

`C-c r t c` creates a commons, asking for a project/system name and the human
participant name you want recorded. Set `org-reason-participant` only to your actual,
explicitly chosen participant ID. Imported commons prompt when that ID is not
present; the system does not guess you are their driver. If another tool (an AI
assistant using the Reason Commons skill, say) works on the same
`commons/<name>/reason-commons.yaml`, edit in turn, and don't leave Emacs holding
unsaved YAML changes while it writes.

## 3. Browser capture

The bookmarklet in [capture/bookmarklet.html](../capture/bookmarklet.html) sends the
page title, URL and selected text to `org-protocol://reason-capture`. Emacs files it
straight into the inbox. Two things must be in place:

1. **Emacs runs a server**, so `emacsclient` can reach it: add `(server-start)` to
   your init (or `(unless (server-running-p) (server-start))` after `(require 'server)`).
2. **The OS passes `org-protocol://` links to `emacsclient`:**
   - **macOS:** run `capture/macos/install.sh`. It builds a small URL-handler app,
     `~/Applications/Org Protocol.app`, which starts Emacs if needed. Org Reason
     captures show a notification and leave you in the browser.
   - **Windows:** in PowerShell, run
     `powershell -ExecutionPolicy Bypass -File capture\windows\install-org-protocol.ps1`.
     It finds `emacsclientw.exe` and registers the link type for your user only
     (no administrator rights). Pass `-EmacsBin "C:\path\to\emacs\bin"` if it can't.
   - **Linux:** copy `capture/linux/org-protocol.desktop` to
     `~/.local/share/applications/`, then run
     `xdg-mime default org-protocol.desktop x-scheme-handler/org-protocol`.

Then open the bookmarklet page in your browser and drag the button to the bookmarks
bar. Select harmless text on a page and click it: it should appear in the inbox
(`C-c r i`). The first time, the browser asks whether to open the handler; allow it
for that site. No server or network service is involved.

## 4. Several computers

Install the package on each computer the same way. Give each its own
`org-reason-device`. Org Reason does not sync; to use one set of records everywhere,
sync `org-reason-directory` with a tool you trust (a private Git repository,
Syncthing, a cloud folder):

- Set `org-reason-inbox-per-device` to `t` and give each computer a distinct,
  stable `org-reason-device`. Each device appends to its own file. The inbox
  command offers a choice of files, including the existing `inbox/inbox.org`.
- Coordinate clarification and edits to shared files. Wait for sync before
  switching devices. The dashboard lists duplicate IDs.
- From a phone, drop a UTF-8 `.txt`, `.text`, `.md`, or `.org` file in
  `inbox/drop/` and run `C-c r I` in Emacs to capture its text. Other files
  are imported as originals. The drop files stay in place.
- Sync `media/`, `learning/forecasts/`, and the Commons histories in
  `.org-reason/history/` and `.reason-commons/` with the Org records.
- Keep Emacs's `.org-id-locations`, the Org-roam database, and Commons
  `.org-reason/*.lock` files local to each computer.
- With Git, keep line endings as they are (`git config core.autocrlf false` in that
  repository, or a `.gitattributes` with `* -text`): the forecast snapshots and
  commons histories are compared byte for byte.

**Windows:** Emacs reads `~` as `%HOME%` when that is set, and otherwise as your
`AppData\Roaming` folder. Set a user environment variable `HOME` (for example to
`C:\Users\you`) so `~/org/reason/` means the same place it does elsewhere, and so
your init is found in `%HOME%\.emacs.d`. File permissions are not enforced there:
Org Reason's "private" (`0600`/`0700`) modes apply only on macOS and Linux, so
rely on your Windows account and disk encryption.

## 5. Audio, handwriting, OCR

For audio, export a recording from your usual recorder and import it with `C-c r m`
choosing `audio`. For handwriting, import a photograph or scan as `handwriting`.
Both work before any interpretation exists.

OCR and transcription are optional. A local program must accept the filename and
print UTF-8 text to standard output. For a separately installed Tesseract with the
relevant language data:

```elisp
(with-eval-after-load 'org-reason-media
  (setq org-reason-ocr-command '("tesseract" "%f" "stdout" "-l" "eng+deu")))
```

For speech, set `org-reason-transcription-command` to your local tool's argv the same
way, or attach an existing transcript with `M-x org-reason-import-interpretation`.
`C-c r D` runs an adapter explicitly; nothing starts at capture or on a timer. If you
choose a cloud tool, its data handling is that tool's, not a property of Org Reason.

## 6. Org-roam

If `org-reason-directory` is inside `org-roam-directory`, Org Reason adds one entry
to `org-roam-file-exclude-regexp` so only its `knowledge/` notes become Org-roam
nodes; every capture, action and experiment has an ID and would otherwise appear
in `org-roam-node-find`. See [customization](customization.md) to change that.
Run `M-x org-roam-db-sync` once after installing.

## 7. A first smoke test

1. Capture a disposable line with `C-c r c`.
2. Open the inbox; put point on it and use `C-c r x` → `next-action`.
3. Check it appears once in `C-c r a` and has no invented due date.
4. Import a disposable image, clarify it as reference, and open its original link.
5. Draft a disposable experiment, freeze it, and record a clearly labelled test result.
6. If using reasoning, create a test commons and add proposed nodes. Only your
   explicit endorsement command should change an item's acceptance.

## Disable, back up, recover

`M-x org-reason-mode` toggles the interface off. It removes the capture template,
protocol handler, Org-roam exclusion and keymap it installed; it keeps your data.
Remove the `use-package` block to stop loading it. Loaded Org link handlers remain
available in the current Emacs session.

Back up the complete data directory, including media, forecast snapshots,
`.org-reason/`, and `.reason-commons/`. An Org-roam database is not canonical data.
Restore from backups and reconcile duplicate IDs before relying on links.

A refile saves the complete destination before removing the source. If it stops
between those writes, repeat the original disposition on the inbox entry to
finish removing it. The dashboard lists both copies if reconciliation is needed.

The Reason Commons bridge holds an OS lock for the duration of a write. The
operating system releases it when the Python process exits, including after an
interruption. Leave the persistent lock file in place. Older versions use a
different lock mechanism, so finish any writes from those versions before
switching. Digest checks and before-images remain available for recovery.

If valid YAML was saved but rendering failed, the command reports that
separately. Fix the history or rendering issue and open the diagram again.
