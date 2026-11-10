# Install and set up

Org Reason needs Emacs 29.1+ with its bundled Org (9.6+). Capture, GTD, review,
media import and learning need nothing else. The Reason Commons commands also need
Python 3 with PyYAML; browser capture needs your OS to hand `org-protocol://`
links to Emacs.

## 1. The package

With Emacs 30, in your init:

```elisp
(use-package org-reason
  :vc (:url "https://github.com/dvdgdn/org-reason" :rev :newest)
  :custom
  (org-reason-directory "~/org/reason/")
  (org-reason-device (system-name))
  :config
  (org-reason-mode 1))
```

On Emacs 29, run `M-x package-vc-install RET https://github.com/dvdgdn/org-reason`
once, then use the same block without the `:vc` line. Either way,
`M-x package-vc-upgrade RET org-reason` updates it.

To work on Org Reason itself, clone the repository and run
`M-x package-vc-install-from-checkout` on the clone: the same block then loads
your working copy. After editing, `M-x package-vc-rebuild` recompiles it.

The data directory is created the first time the mode is turned on; loading the
library alone writes nothing. Your records stay there and never belong in this
repository.

| Setting | Default | What it is |
|---|---|---|
| `org-reason-directory` | `~/org/reason/` | Where your records live |
| `org-reason-device` | `(system-name)` | Recorded on each capture; name each computer |
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

The simplest setup is a virtual environment of its own. In the package directory
(`M-x find-library RET org-reason`, then `M-x dired-jump` shows it):

macOS and Linux:

```sh
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
```

Windows (PowerShell):

```powershell
py -m venv .venv
.venv\Scripts\python -m pip install -r requirements.txt
```

Then point Emacs at it:

```elisp
(setq org-reason-python-command
      (expand-file-name (if (eq system-type 'windows-nt) ".venv/Scripts/python.exe" ".venv/bin/python")
                        (file-name-directory (locate-library "org-reason"))))
```

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

- Edit on one computer at a time and let the sync finish before switching.
  Clarifying moves an entry between files; two computers doing that to the same
  files between syncs produce conflicts or duplicates. `C-c r d` lists duplicate IDs.
- Sync the records, including `media/`, `learning/forecasts/` and each commons'
  `.org-reason/` and `.reason-commons/` histories.
- Don't sync per-computer state: Emacs's `.org-id-locations`, an Org-roam database,
  or a leftover `*.org-reason-lock` file.
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

A refile saves the destination before removing the source. A crash between those
two writes can leave a recoverable duplicate; `C-c r d` surfaces duplicate IDs.
Reasoning edits use a lock, digest comparison, before-images, atomic replacement,
and accepted-history snapshots. A noncooperating external editor still requires
coordination; this is not a multiwriter database.

After a killed Python process, a `.org-reason-lock` can remain beside the YAML.
Confirm no writer is running and inspect the working file and history before
removing that stale lock. If valid YAML was saved but rendering failed, the command
reports that separately: fix the history/render issue and invoke the diagram
command again.
