# The Org Reason series: development plan

This directory is the plan for turning Org Reason into a series of teaching
novellas, a shared record model, and one hub in Emacs. It is written so that a
person or an agent who has seen none of the earlier discussion can start work
and is unlikely to build the wrong thing.

Read this file first. Then read [STATUS.md](STATUS.md), which says what is done
and what to do next.

## The idea in one paragraph

Each method is taught by a novella. A reader follows a character through a
real problem, and after every chapter does one step with their own material.
By the last chapter the reader has a working practice of their own. Org Reason
is the place where those practices meet: one set of records, and one view that
helps the reader answer a single question.

> Given what I am trying to achieve, what is the most valuable thing I can do
> next, and how will I know whether it worked?

## The series

| Volume | The reader's question | Method | State |
|---|---|---|---|
| 1. *Three Hundred Seats* | What have I promised? | Getting Things Done | Written: `docs/three-hundred-seats/` |
| 2. *The Fourth Visit* | What is worth doing? | Theory of Constraints thinking processes | Written, not reviewed: `docs/the-fourth-visit/`. Spec: [volume-2.md](volume-2.md) |
| 3. *Two Minutes at Full Speed* | How do I become able to do it? | Deliberate practice | Written, not reviewed: `docs/two-minutes-at-full-speed/`. Spec: [volume-3.md](volume-3.md) |
| Casebook | Does this technique work for me? | One technique per short story | Planned: [casebook.md](casebook.md) |

## The unit of work is a volume

A volume is finished only when it has delivered all four of these. Never
deliver one of them for several volumes at once.

1. **A story** in which the method is needed before it is named.
2. **Exercises**, one after each chapter, that work on paper.
3. **One software capability** in Org Reason that the exercises use.
4. **One panel** of the hub that shows what that capability recorded.

## Reading order

| File | Read it when |
|---|---|
| [STATUS.md](STATUS.md) | Every session, first. It names the next work package |
| [principles.md](principles.md) | Before writing or reviewing anything. These rules do not change per volume |
| [snowflake.md](snowflake.md) | Before any story work. The method for building each novella |
| [volume-2.md](volume-2.md) | Working on the thinking-processes novella |
| [volume-3.md](volume-3.md) | Working on the deliberate-practice novella |
| [casebook.md](casebook.md) | Working on a single technique |
| [software.md](software.md) | Writing code in this package or in the owner's Emacs config |

## Twelve rules that keep this from going wrong

Each rule has a check. A work package is not done while any check that applies
to it fails.

1. **One work package per session.** Take the first unblocked package in
   STATUS.md, finish it, update STATUS.md, commit. Check: the commit touches
   one package's files and STATUS.md.
2. **Stop at every owner gate.** Gates are marked `OWNER` in STATUS.md. Present
   what the gate asks for and wait. Check: no file after a gate exists before
   the gate is recorded as passed.
3. **Each novella teaches its method alone.** A reader with no software and no
   other volume can do every general step. Check: the independence test in
   [principles.md](principles.md#independence).
4. **Each novella is better with the others.** Every Org Reason section says
   what a reader who already keeps a trusted system gains. Check: the synergy
   table in the volume's file is covered row by row.
5. **Software never appears in a chapter.** Characters use paper, walls,
   whiteboards and conversation. Check: search the chapter text for "Org
   Reason", "Emacs", "Reason Commons" and key names.
6. **A lesson is paid for before it is named.** Its absence costs a character
   something countable in an earlier scene. Check: the bruise column of the
   scene list has no empty cell.
7. **Every central tension has two legitimate sides.** Each side is held by a
   character the reader likes. Check: the tension ledger names both holders.
8. **The story's reasoning is real.** Every tree, cloud and number in the story
   exists as a validated file before the chapter that shows it is drafted.
   Check: the story commons validates with the pinned validator.
9. **Exercises are written last.** They name commands, so the commands must be
   released first. Check: every key and command in an exercise page exists in
   the tagged release the page names.
10. **The hub never decides.** It shows candidates and the links the reader
    made. Check: no code computes the current constraint or a single best
    action.
11. **Claims about what a technique does are sourced.** Check: each claim has a
    row in the evidence ledger with a primary source someone has read.
12. **The package's own rules still apply.** `CONTRIBUTING.md`: a job, a
    scenario and a test for new behaviour; nothing on a timer; nothing sent
    anywhere; originals and frozen forecasts are never overwritten.

## What only the owner can do

- Approve each gate.
- Work the exercises on real commitments and real problems. The plan depends on
  this: the hub is designed from real records, not invented ones.
- Push branches, tag releases and publish. This repository is public.
- Supply or approve source material that is under someone else's copyright.

## Words used in this plan

| Word | Meaning here |
|---|---|
| Volume | One novella with its exercises, capability and hub panel |
| General step | The exercise as it works with paper. Called "Your trusted system" in volume 1 |
| Tension | Two legitimate needs that seem to demand opposite actions |
| Tension ledger | The table of a volume's central tensions and who holds each side |
| Lesson ladder | The ordered list of what the reader learns, one rung per chapter |
| Bruise | The scene in which the lack of a lesson costs a character something |
| Story commons | The fictional reasoning of a novella, kept as validated files |
| Hub | The Org Reason dashboard, grown by one panel per volume |
| Adapter | A small file that connects one outside tool to the hub |
| Gate | A point where work stops until the owner approves |
