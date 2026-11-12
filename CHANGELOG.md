# Changelog

## 0.2.0 — 2026-11-12

- Add `C-c r C` to capture and clarify in one step, and `M-?` at every
  clarification prompt to show help with examples.
- Capture external text as literal Org, support optional per-device inboxes,
  and import plain text from the drop directory.
- Scan records without visiting unopened files. Retry an interrupted
  clarification, schedule commitments with a time, and archive completed actions.
- Verify frozen forecast digests, show calibration bands and a constant-rate
  baseline, and review due forecasts directly from the dashboard.
- Add the worked example, command menu, and configurable prefix.
- Set up Reason Commons Python from Emacs, release write locks on process exit,
  and load node kinds from the vendored schema.

## 0.1.1 — 2026-11-10

Fixes from the first CI run on Windows; all tests now pass on Linux, macOS and
Windows.

- A workspace file holding only ASCII is read with an undecided encoding;
  adding a non-ASCII character then made saving ask for a coding system on
  Windows, whose default isn't UTF-8. Such files are now saved as UTF-8 (by
  the package, and, with the mode on, by you and Org capture), keeping their
  line endings.
- Windows gives a directory a short 8.3 name and a long one. Paths are now
  built from one canonical name, so a file is never visited twice and
  relative links are rebased correctly when an entry moves.
- CI: the workflow file parses (the vendor hash check is now
  `scripts/check_vendor.py`), and the Python 3.9 job runs on Ubuntu 22.04.
  `make test` and `make compile` load the sources, not stale `.elc` files
  that `package-vc` leaves in a clone.

## 0.1.0 — 2026-11-10

First public release.

- One inbox for text, Org capture (template `r`), browser selections
  (`org-protocol://reason-capture`) and imported originals (audio, scans, files),
  with no classification required.
- GTD clarification into next actions, projects, waiting, someday, calendar,
  tickler, agendas, notes and discard, keeping each entry's ID; agenda, a
  next-action chooser by context/time/energy, an exceptions dashboard, and a
  weekly review that keeps earlier answers.
- Experiments whose prediction is frozen before the outcome is known, outcomes
  linked to the frozen original, and Brier scores only for prospective,
  resolved yes/no events; practice records with feedback and a transfer check.
- An Emacs interface to Reason Commons YAML v1: propose nodes and joint (AND)
  relationships in the six tree families, endorse, challenge, record
  assumptions, render accepted-reasoning diagrams, and turn a transition action
  into a GTD reminder. Validated by the pinned upstream scripts in `vendor/`.
- `C-c r h` opens a guided tutorial in a separate Emacs on fictional data.
- If the workspace is inside `org-roam-directory`, only its `knowledge/` notes
  are indexed (`org-reason-roam-knowledge-only`).
- Built for macOS, Linux and Windows: Python is found automatically (`py` first
  on Windows), process I/O and new files are UTF-8 with LF, and capture handlers
  are included for all three.
