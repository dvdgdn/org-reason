# Architecture and actual directories

There are two different roots: the shareable code project and private user data.
The code does not live inside `~/org`; private data does not live in this repository.

## Private workspace, by default `~/org/reason/`

| Relative path | Responsibility |
|---|---|
| `inbox/inbox.org` | Default inbox for unclarified captures |
| `inbox/device-*.org` | Optional inbox files for individual devices |
| `inbox/drop/` | Manually delivered plain text, audio, scans, or other files |
| `gtd/actions.org` | Current single next actions |
| `gtd/projects/<id>.org` | One project outcome, its actions, and project support |
| `gtd/waiting.org` | Standalone delegated outcomes |
| `gtd/someday.org` | Incubation |
| `gtd/agendas.org` | Discussion points for people and meetings |
| `gtd/calendar.org` | Day- and time-specific commitments |
| `gtd/tickler.org` | Dated bring-forward reminders |
| `gtd/horizons.org` | Purpose, vision, goals, and responsibility areas |
| `gtd/checklists.org` | Reusable review and work checklists |
| `gtd/reviews/<ISO-year>-W<week>.org` | Dated weekly review and decisions |
| `knowledge/notes/<id>.org` | Identified reference, observation, question, hypothesis, feeling, or failure |
| `knowledge/daily/` | Reserved for an optional user-configured daily-note workflow |
| `learning/experiments.org` | Working experiment records and linked outcome children |
| `archive/actions.org` | Completed or cancelled single actions |
| `learning/forecasts/<id>.json` | Original formulation, timestamp, self-reported prospectivity, optional binary event and probability |
| `learning/practice.org` | Challenge, feedback, adjusted repetition, and transfer check |
| `learning/reflections.org` | Available for manually organized reflections; clarification normally creates individual knowledge notes |
| `commons/<slug>/reason-commons.yaml` | Canonical native Reason Commons v1 working model |
| `commons/<slug>/.org-reason/history/` | Before-images of package writes and attributed operation events |
| `commons/<slug>/.reason-commons/history/` | Upstream accepted-reasoning snapshots |
| `commons/<slug>/.reason-commons/diagrams/` | Derived offline accepted and latest-change SVG/HTML |
| `media/<capture-id>/original.<ext>` | Preserved original with digest on the Org record |
| `media/<capture-id>/<kind>-<uuid>.txt` | Separate, versioned transcript/OCR interpretations |
| `archive/discarded.org` | Recoverable discard |

Empty directories reserve simple extension points, not implemented automatic
features. For example, the package does not add an alternative daily-note command
to one an Org-roam setup may already supply.

## Code, in this repository

| Path | Boundary |
|---|---|
| `org-reason.el` | Mode, keymaps, `org-reason:` view links, tutorial launcher, Org-roam exclusion |
| `org-reason-core.el` | Paths, IDs, Org storage primitives, read-only views, Python lookup |
| `org-reason-capture.el` | Raw text, Org capture, namespaced browser protocol |
| `org-reason-gtd.el` | Clarification decisions, project audit, agenda, engagement |
| `org-reason-learning.el` | Frozen predictions, results, calibration, practice |
| `org-reason-metadata.el` | Optional fields and property/tag retrieval |
| `org-reason-review.el` | Weekly review and exception dashboard |
| `org-reason-reasoning.el` | Optional Emacs interface to actual commons YAML |
| `org-reason-media.el` | Original imports and explicitly configured interpretation processes |
| `org-reason-demo.el` | Isolated fictional workspace for the tutorial, run in a separate `emacs -Q` |
| `org_reason_commons.py` | Structured local editor; validation, locking, history |
| `vendor/reasoncommons/` | Unmodified upstream validator, feedback validator, schema reference, MIT notice |
| `capture/` | Bookmarklet and the macOS, Windows and Linux `org-protocol://` handlers |
| `features/` | Behavioral Gherkin specifications |
| `docs/` | Usage, decisions, interfaces, sources, and customization |
| `test/` | Executable ERT and Python contracts |

## Identity and relationships

An Org object has one stable `ID`, even when it moves out of the inbox. Normal
clarification moves the subtree; it does not leave a second live task behind.
Original metadata, body, and attachment identity travel with it. `id:` links
refer to that object. New semantic objects may link to a source without being
the same object: a prediction derived from a captured conversation is a new claim.

A Reason Commons node has its own native ID within one commons. It may play a
role in a typed tree and trace to nodes in other trees. `rc:slug/item-id` locates
the canonical node or link. The derived Org view uses `CUSTOM_ID`, not duplicate
Org `ID` records. A GTD action created from a Transition Tree action has its own
reminder ID and `OR_RC_REF`; repeating that command opens the existing reminder.

Backlinks are navigation. Only a typed reasoning relationship asserts necessity,
causality, order, or another specified meaning. `OR_REASON` is an explanatory
reference, not evidence that a hypothesis is true. `reason-file:` links resolve from
the private workspace root, so generated media links survive refiling.

## Recovery and concurrency

New files are created exclusively and privately. Originals, interpretation
versions, and frozen forecast files are not overwritten by package commands.
The source is saved into the destination before an inbox subtree is removed.
Two-file refiling is not transactional: a crash can leave duplicate IDs, which
the dashboard flags. Ordinary relative `file:` links typed inside a capture are
rebased during refiling; generated media uses root-relative `reason-file:` links.

Python edits validate before and after transformation, reject duplicate YAML
mapping keys, refuse unfamiliar schema versions, compare the inspected digest,
and use a cooperative lock and atomic replacement. Existing optional data is
preserved structurally; YAML comments and original formatting are reserialized.
Before-images cover proposed changes too. Upstream accepted snapshots are generated
only when the accepted semantic projection changes.

Coordinate with noncooperating writers. A digest comparison has a small remaining
race between the final check and replacement; it is not a distributed transaction.
Files and histories are ordinary owner-controlled files, not cryptographic proof.
Backups remain necessary. External transcription output is marked pending and
does not create accepted reasoning.
