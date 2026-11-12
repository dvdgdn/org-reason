# Building a novella with the Snowflake method

Randy Ingermanson's Snowflake method grows a story from one sentence by
expanding it in ten steps, checking at each size that the story still works.
It suits this series because a mistake is found while it is one sentence long,
not after seventeen chapters.

Volume 1 used a short form of it. Its appendix shows four of the stages: the
seed (step 1), the five-sentence story (step 2), the characters under pressure
(steps 3 and 5) and the scene map (step 8).

This file adapts the ten steps for a teaching novella. Two things are added.
A teaching spine is fixed before step 1, and the story's reasoning is built as
real files before drafting.

## Rules for the whole process

- Do the steps in order. Each step's output is a file in
  `docs/series/<volume>/design/`, committed before the next step starts.
- When a later step shows that an earlier one is wrong, go back, change the
  earlier file, and bring every later file into line. Ingermanson's method
  expects this; it is the point of working small first.
- Steps marked `OWNER` are gates. Present the output and wait.
- At steps 1 and 2 produce three different candidates, not one. The owner
  chooses or combines.
- Nothing in a design file names software.

## Step 0. The teaching spine (before any story)

Take these from the volume's file and copy them into the design directory as
working documents. The story is built to carry them.

- `00-lesson-ladder.md`: the ordered rungs, one per chapter. Each rung has the
  lesson in one sentence, the step the reader will do, and what the reader
  holds afterwards.
- `00-tension-ledger.md`: the central tensions. For each: the shared aim, the
  two needs, the two opposing actions, and two empty columns for the
  characters who will hold each side.
- `00-numbers.md`: empty for now. Every number, date, name and place in the
  story will be recorded here once and looked up from here.

Done when: each rung depends only on rungs above it, and each tension is
written as two needs that are both fair.

## Step 1. One sentence `OWNER`

Write the story in one sentence of about fifteen words. No character names.
It joins the outer problem to what the main character stands to lose.

Volume 1's sentence: *After losing a sold-out benefit's venue, a producer has
ten days to make good on three hundred tickets.*

Checks:

- It contains a person, a loss and a limit of time or resource.
- It does not mention the method.
- Someone who reads only this sentence wants to know what happens.
- The situation naturally forces the volume's central tension. If the
  sentence could be resolved by working harder, it is the wrong sentence.

Output: `01-sentence.md` with three candidates and a note on which tension
each one presses hardest.

## Step 2. One paragraph `OWNER`

Expand the chosen sentence to five sentences:

1. The setup: who, where, what they want.
2. The first disaster, which ends the first quarter.
3. The second disaster, at the midpoint.
4. The third disaster, which ends the third quarter.
5. The ending.

Each disaster must be caused by a central tension left unresolved, not by bad
luck. Under the paragraph, write one line per disaster naming the tension that
caused it. The second disaster should come from the character's own first fix
(principles, rule 3). The third should come from the cost of the real answer
(rule 6).

Checks:

- Each disaster is worse than the one before and can be stated as a number.
- The ending is earned by a change in how the character sees, not by rescue.
- All central tensions in the ledger appear in at least one sentence.

Output: `02-paragraph.md`.

## Step 3. Characters, one page each `OWNER`

For each major character write:

- Name.
- Their storyline in one sentence.
- Motivation: what they want in the abstract.
- Goal: what they concretely want in this story.
- Conflict: what stops them.
- Epiphany: what they learn or how they change.
- Their storyline in one paragraph.

Then fill in the tension ledger: every side of every central tension is
assigned to a character. Add two columns to each character page.

- **The need they carry.** Which side of which tension.
- **Why they are right.** Three sentences in their own voice.

Checks:

- No character exists only to be wrong.
- The mentor has a stake and a limit: something they want, and a reason they
  cannot simply solve it. They are absent for at least one whole part.
- Six to eight named characters. More cannot be held in a novella.
- No two characters carry the same need.

Output: `03-characters.md` and the completed `00-tension-ledger.md`.

## Step 4. One page

Expand each of the five sentences from step 2 into a paragraph. Every
paragraph except the last ends in its disaster.

Beside each paragraph list the rungs of the lesson ladder that fall inside it.
All rungs must be placed, in ladder order. If the ladder and the plot disagree
about order, change the plot. If that is impossible, bring the problem to the
owner; do not reorder the ladder on your own.

Output: `04-page.md`.

## Step 5. Character synopses

Write the story again from each character's point of view: one page for each
major character, half a page for the others. This is where a flat opponent is
found. If a character's version of the story is not one in which they act
sensibly, repair the character.

Run the fair-opponent test here for the first time.

Output: `05-synopses.md`.

## Step 6. Four pages

Expand each paragraph of step 4 to a page. Decisions about cause and
consequence are made here. For every lesson, mark the bruise: the earlier
moment where lacking it cost something countable.

Start filling `00-numbers.md`. From here on no number is typed into a design
file without being recorded there.

Output: `06-synopsis.md`.

## Step 7. Character charts

For each character record what a writer needs to stay consistent: age, work,
history that bears on the story, how they speak, what they notice first in a
room, what they would never say, and how they are different at the end.

Output: `07-charts.md`.

## Step 7a. The story commons (added for this series)

Build the reasoning that the characters will do, as real files, before any
scene depends on it.

- For a volume that teaches reasoning: create a commons under
  `docs/series/<volume>/commons/` and enter every tree the story shows, in the
  state the characters have reached at each part. Include the wrong versions
  the characters draw first. Validate with the pinned validator.
- For a volume that teaches practice: create the fictional skill records,
  session logs and frozen predictions, with the dates and scores the story
  quotes.

Have someone who knows the method challenge the files. An error found here
costs minutes; found in chapter 12 it costs the chapter.

Done when: the files validate, every claim a character makes in the synopsis
is in them, and every number matches `00-numbers.md`.

## Step 8. The scene list `OWNER`

One row per scene, in a table. This is the most important file in the process.

| Column | Content |
|---|---|
| # and part | Scene number; which of the four parts |
| Point of view | Whose eyes |
| Goal | What that character wants in this scene |
| Conflict | What opposes it |
| Outcome | The setback, or the decision reached |
| Tension | Which ledger tension is pressed, and from which side |
| Bruise for | The lesson whose lack costs something here, if any |
| Lesson earned | The ladder rung reached here, if any |
| Reader's step | The step that will follow this chapter |
| Clock and price | The deadline in force and the cost of missing it |
| Holds after | What the character has in hand that they did not before |

Chapters and steps are one to one, as in volume 1. A chapter may hold two or
three scenes.

Run every test in [principles.md](principles.md#tests-for-felt-tension)
against this table. Fix failures in the table, not later in the prose.

Output: `08-scenes.md`.

## Step 9. Scene briefs

For each scene write a short brief in one of two shapes.

- A **scene**: goal, conflict, setback.
- A **sequel**: reaction, dilemma, decision.

A setback should usually be followed by a sequel. The dilemma is where a
tension is felt: the character sees two bad options, each serving one fair
need, and the reader weighs them too. Give the dilemma room. The lesson, when
it comes, is the decision.

Each brief also lists the lines of dialogue that must occur, any exact
numbers, and what the reader must not yet know.

Output: `09-briefs.md`.

## Step 10. Draft `OWNER` after two chapters

Draft the chapters in order from the briefs. Stop after the second chapter for
the owner to approve the voice.

Drafting rules:

- Start each scene late and leave it early.
- Show the cost in objects and numbers: a printed programme, a chair in an
  aisle, a figure on an invoice.
- When a character reasons, they do it out loud or on paper, wrongly at first,
  and someone objects.
- Use the method's own words only after the character has done the thing.
- Do not write the lesson recap or the exercises yet.

## After the draft: five passes, in this order

1. **Logic pass.** Compare every piece of reasoning in the prose with the
   story commons. The prose changes, not the commons, unless the commons was
   wrong, in which case fix it and revalidate.
2. **Numbers pass.** Check every number, date and name against
   `00-numbers.md`.
3. **Tension pass.** Run the tests for felt tension on the prose.
4. **Lesson pass.** Write "What the character has just learned" for each
   chapter. If it cannot be written in four lines without giving away a later
   chapter, the chapter is carrying the wrong rung.
5. **Exercise pass.** Write the general step, then the Org Reason section,
   then the Reason Commons section where the volume has one, then "Carry
   forward". This pass waits until the commands exist in a tagged release.

Then the cold-reader test: one person new to the method reads the whole volume
and does every step with their own material. Their difficulties are recorded
in `design/cold-reader.md` and fixed before release.

## The appendix

Written last, from the design files: the sentence, the paragraph, the
characters under pressure, the scene map, the method summed up, the story's
finished reasoning, and sources. It replaces the design directory for readers.

## Source

Randy Ingermanson, "The Snowflake Method for Designing a Novel", and *How to
Write a Novel Using the Snowflake Method* (2014). The scene and sequel shapes
come from Dwight Swain, *Techniques of the Selling Writer* (1965). Read the
sources before relying on this summary for anything it does not cover.
