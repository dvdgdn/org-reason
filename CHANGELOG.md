# Changelog

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
- Works on macOS, Linux and Windows: Python is found automatically (`py` first on
  Windows), process I/O and new files are UTF-8 with LF, workspace files are
  saved as UTF-8 without asking, paths use one canonical directory name (Windows
  8.3 short names), and capture handlers are included for all three.
