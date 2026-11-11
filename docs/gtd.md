# GTD translated into Org

This implementation follows the David Allen Company's five-stage workflow and
keeps processing separate from collecting. It is an independent implementation,
not an official or certified GTD product. Primary references are in `sources.md`.

## Clarification decisions

| Meaning of the item | Org representation | Important distinction |
|---|---|---|
| Not yet clarified | Identified inbox entry, no required TODO state | Capture is not a commitment |
| No action and no useful retention | `archive/discarded.org` | Recoverable discard, not automatic deletion |
| Useful information | Identified reference note | Reference is not a future action |
| Possible future commitment | `SOMEDAY` | Incubation is separate from current commitments |
| Bring it back at a real future date | Dated tickler | Review then; do not pretend it is already a next action |
| Can complete now in a couple of minutes | Do it; record `DONE` only afterward | The quick-action rule is applied during processing |
| Delegated, with an outcome to track | `WAIT`, named person, delegation date | Capturing WAIT does not send a message |
| Physical step available to you | `NEXT`, context, optional effort/energy | No dependency still needs resolving |
| Day- or time-specific work | Calendar entry | Use genuine date requirements; no arbitrary urgency |
| Outcome requiring multiple actions | `TODO` project, `OR_TYPE: project`, first `NEXT` child | Project outcome and next action are different |
| Discussion point for a person/meeting | Agenda entry with person/meeting | Keep it available for that conversation |

Your external calendar remains authoritative for its appointments. Org Reason
calendar entries appear through normal Org scheduling. Enter a date alone or
a date with an optional time such as `2026-11-14 15:00` during clarification.
Tickler entries take a date. Actual deadlines can use Org's standard `DEADLINE`, with its normal
warning behavior. Dates are not assigned to ordinary actions by default.

## Projects and support

Projects are outcome reminders. Actions belonging to a project live beneath that
project's heading in its file; the agenda is the consolidated view. A project's
research, sketches, and future dependent steps are support, not duplicate action
reminders. `TODO` can hold a planned step; promote it to `NEXT` when actually available.

The dashboard flags an active project without a live `NEXT`, `WAIT`, or dated
calendar child. A pending response can legitimately keep a project moving. A
completed or incubated parent is excluded when choosing available actions.
The audit is structural: it cannot tell whether “work on article” is physically
specific enough. Your review supplies that judgment.

Completing the last `NEXT` does not silently promote a guessed future action.
Review the desired outcome, mark the project complete or choose its next step.
Use Org's normal archiving deliberately; the package does not purge completed work.

## Reflect and engage

The weekly review file covers collection points, clarification, a mental sweep,
action lists, the past and upcoming calendar, waiting, project outcomes, relevant
checklists, incubated possibilities, and new ideas. Its wording is original; use
the official checklist when you want David Allen's exact presentation.

`C-c r e` filters available actions by context, time, and energy. You then choose
by priority. `OR_ACTION_KIND` such as read/listen/meet is optional descriptive data,
not a substitute for a physical next action or a context.

`gtd/horizons.org` is an editable place for purpose/principles, vision, longer-term
goals, areas of responsibility, and links to projects. Reason Commons can examine
what a goal depends on; an ongoing area of responsibility is not automatically
a finite project. Review higher horizons when the decision warrants it.

## What the reasoning backlog means

“Test this causal link” or “examine this assumption” belongs to the commons backlog.
It becomes a GTD reminder only when you choose a concrete action and make that
commitment. Reasoning acceptance, empirical evidence, and permission to implement
a change remain separate decisions.


## Archive completed actions

Run `C-c r A` or `M-x org-reason-archive-actions` to move completed and
cancelled single actions to `archive/actions.org`. The command keeps their
IDs, links, and subtrees. Use `C-c r /` to find archived actions.
