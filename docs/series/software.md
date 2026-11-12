# Software: the shared records, the adapters and the hub

What the series needs from code, in this package and in the owner's Emacs
configuration. Read `CONTRIBUTING.md` and `docs/architecture.md` first; every
rule there applies.

## Three places code can live

| Place | Holds | Rule |
|---|---|---|
| **Package core** (this repository) | Records, commands, the hub | Depends on no outside practice tool |
| **Adapters** | One small file per outside tool | Optional. The core never requires one. An adapter must byte-compile when its tool is not installed |
| **The owner's configuration** | Which adapters to load, paths, keys | Wiring only. Anything that changes what a command does belongs in the package |

Adapters for public packages go in `adapters/` here. Adapters for tools that
exist only in the owner's configuration go beside the tool there.

## Design rules

1. **The reader makes the links; the hub reads them back.** The "why" beside
   a suggested action is the chain of links the reader created: action, what
   it serves, the constraint, the goal. Nothing is inferred.
2. **The current constraint is set by hand.** It is labelled a working
   hypothesis and has a review date. No code computes it.
3. **Candidates, not a verdict.** The hub lists a few candidate actions in a
   stated order with their reasons. The reader chooses. There is no score.
4. **Each tool keeps its own results.** Raw scores stay in the tool's file.
   Org Reason stores a reference and asks the adapter for a summary.
5. **Nothing runs on a timer.** Sources are asked only when a view is drawn.
6. **A failing source cannot break the hub.** Each call is wrapped; a failure
   shows as "unavailable" on that source's line.
7. **Text first.** Every panel works in a terminal. Graphics are an addition
   where the display supports them.
8. **New records are additive.** Existing files are never rewritten to a new
   shape. Old practice entries stay valid.

## The record model

Existing records, unchanged: captures, actions, projects, waiting, calendar,
horizons, knowledge notes, experiments with frozen forecasts and results,
practice entries, commons.

New records and properties:

| Record | File | Fields |
|---|---|---|
| Constraint | `gtd/focus.org`, one entry per constraint ever set | `OR_TYPE` constraint; `OR_STATUS` current or retired; `OR_REF` an `rc:` or `id:` reference to the statement; `OR_SET_ON`; `OR_REVIEW_ON`; `OR_RETIRED_ON`. Body: the statement in the reader's words, why they believe it, what would show it is wrong |
| Skill | `learning/skills.org`, one entry per skill | `OR_TYPE` skill; `OR_FEEDBACK` scored or self-report; `OR_TIER` established, disputed or untested; `OR_SOURCE` the adapter's name, if any; `OR_SERVES`; `OR_REVIEW_ON` the date of the real-world check. Body sections: Scene, Where it breaks, Exercise, Feedback source, Real-world check |
| Session | A child entry of its skill | `OR_TYPE` session; `OR_ON`; `OR_MINUTES`; `OR_MEASURE` and `OR_VALUE` when scored; `OR_RAW` a link into the tool's own results. Body: what was noticed, the change for next time |
| Link | Property on an action, project or skill | `OR_SERVES`: one or more `id:` or `rc:` references to a goal, a constraint, a skill or a commons statement |

At most one constraint has `OR_STATUS` current. Setting a new one retires the
old one with its date; nothing is deleted, so the file is a history of what
the reader believed was limiting them.

An existing practice entry made with `C-c r s` has no skill identity. Offer a
command that attaches one to a skill. Never convert in bulk.

## The source registry

An adapter registers one source. Sketch; the implementer settles names.

```elisp
(org-reason-register-source
 'dual-n-back
 :name "Dual N-Back"
 :due        #'f   ; () -> integer, or nil when it does not apply
 :candidates #'f   ; () -> list of (:title :minutes :energy :skill :open)
 :summary    #'f   ; (skill-id) -> one line for the Practice panel
 :open       #'f)  ; () -> start the tool
```

A tool reports a finished session by calling one stable function:

```elisp
(org-reason-record-session SKILL-ID
  :source 'dual-n-back :minutes 12 :measure "level" :value 3
  :raw "file:~/org/dual-n-back.org")
```

Both become stable extension points and are added to the table in
`docs/customization.md`.

## The hub

The hub is `org-reason-dashboard` (`C-c r d`) grown by panels. It stays one
view; it does not become a second task store.

```
Org Reason — Today

CURRENT CONSTRAINT            working hypothesis · set 3 Nov · review 1 Dec
  German listening comprehension
  Why: <the reader's sentence>            [open] [review]

CANDIDATES                                      you choose
  1. 15 min listening practice              serves the constraint · @home
  2. Call the hall about Saturday           dated today
  3. …

PRACTICE
  German vocabulary     24 due            last check: —     next check 14 Dec
  Dual N-Back           level 3           sealed guess due 20 Nov

COMMITMENTS                                     (today's dashboard)
  Inbox 6 · projects without a next action 1 · predictions due 2 · …
```

Order of candidates, stated in the view itself:

1. available actions that serve the current constraint;
2. actions and checks dated today or overdue;
3. other available actions that fit the context, time and energy given.

Within a group the order is the reader's own priority, then age. Unknown
effort and energy never hide an action, as in `org-reason-engage` today.

## Work packages

Each package needs, per `CONTRIBUTING.md`: a job in
`docs/jobs-and-acceptance.md`, scenarios in `features/`, tests, a changelog
line, and documentation of any new key. `make test` and `make compile` pass.

### In this package

| # | Package | Done when |
|---|---|---|
| S0 | Release what is unreleased as 0.2.0 | Tag exists; README install snippet names it. `OWNER` pushes |
| S1 | Set, show and retire the current constraint | One current at most; history kept; a passed review date appears under exceptions |
| S2 | `OR_SERVES` links and a command to add one, with completion over goals, the constraint, skills and commons statements. `C-c r t x` sets it | `org-reason-engage` shows what each action serves; a function returns the chain for any entry |
| S3 | Constraint and Candidates panels | Order is as stated above and is printed in the view; works with no constraint set |
| S4 | Edit and withdraw a commons statement from Emacs | Only if the friction log of V2.0 asks for it. History and authorship preserved |
| S5 | Skill records and a command to create one from the five body sections | A skill can be found, linked and reviewed; old practice entries can be attached |
| S6 | `org-reason-record-session` | Appends one session; refuses an unknown skill; never rewrites earlier sessions |
| S7 | Source registry | A failing source shows as unavailable; nothing is called until a view is drawn |
| S8 | Flashcard adapter in `adapters/` | Reports the number due and opens a review. Package chosen in C2 |
| S9 | A routine for self-reported practice: fixed steps, fixed report fields, and a required sealed guess | A session cannot be logged for an untested skill that has no frozen prediction; the tier is shown wherever the skill is |
| S10 | Practice panel | One line per skill from `:summary`, with the next real-world check |
| S11 | The hub as a whole: graphics where supported, tutorial and example updated | Terminal and graphical displays both pass; `C-c r h` covers the new panels on fictional data |

### In the owner's Emacs configuration

That repository's `CLAUDE.md` has its rules. It is shared between computers
and must start on all of them.

| # | Package | Done when |
|---|---|---|
| C0 | Remove duplicated Org Reason code; load edited sources without a rebuild | Done, commit `9f88987` there |
| C1 | Give the n-back trainer a hook run with each finished set, and an adapter file beside it that registers a source and logs a session | The trainer still works with Org Reason absent |
| C2 | Choose and install a flashcard reviewer | The existing German cards, which are in org-drill's two-sided format, can be reviewed. `OWNER` chooses the package |
| C3 | Stop the Org-roam block failing on a computer with no `~/org` | Batch load in an empty home shows no error |
| C4 | Install a tagged Org Reason release on other computers | After S0. This computer keeps using the clone |

## What is deliberately not built

- An algorithm that picks the single best action.
- Background checks, reminders or notifications.
- Any call to an AI service from the package.
- A replacement for a tool that already exists: spaced repetition, chess
  training and the n-back trainer are reached through adapters.
- A streak, a productivity score, or any claim that practice scores show
  general improvement.
