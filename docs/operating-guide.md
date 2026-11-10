# Use the system to learn, not only to keep records

## First week: make it trustworthy

Begin with capture, clarification, and one weekly review. Use your existing
calendar as the source for real appointments; no calendar service sync is added.
Keep existing Org-roam notes where they are. Do not bulk reclassify your history.

Capture a thought in one field, or select text in Emacs and press `C-c r c`.
If typing is inconvenient, make a voice memo or photograph a paper note. Import
that original when convenient. Classification and interpretation can wait.

When processing the inbox, take one entry and decide what it means. If the next
action is a quick thing you can complete in the present context, do it, then mark
`done-now`. If it requires several actions, name the desired outcome as a project
and specify its first available physical action. Put subsequent dependent steps
in project support as `TODO`, not on the `NEXT` list.

`C-c r e` offers available next actions. Blank time or energy means no filter;
unknown estimates remain visible. It does not choose what matters for you. Use
your calendar, situation, available time and energy, and judgment about priority.

For actual time, use ordinary Org commands at the action:

| Action | Command |
|---|---|
| Set an estimate | `C-c r M` → `EFFORT`, e.g. `0:20` |
| Start / stop a task clock | `C-c C-x C-i` / `C-c C-x C-o` |
| Change state | `C-c C-t` |
| Add a topic or context tag | `C-c C-q` |
| Summarize clocked time | Org clock table, or `R` in the Org Reason agenda |

Estimated time and clocked time answer different questions. Review misses when
they would improve a future estimate; do not turn every activity into measurement.

## When a difficulty keeps recurring

Start with the smallest useful record: “Expected __; observed __; next/revisit __.”
`C-c r !` creates that capture. A feeling can be recorded in your own words. It
does not automatically explain the cause of an outcome, and you can leave it private.
Immediate repair, rest, or asking for help can be the right next step.

For a consequential recurring difficulty, identify the goal, boundary, time horizon,
and conditions that must be protected. Distinguish observations from explanations.
Keep the leading constraint hypothesis and a plausible alternative visible. Ask
what observation would distinguish them before drawing a large tree.

Use a Goal Tree for necessary conditions, a Current Reality Tree for causal
hypotheses about existing effects, a Cloud for an apparent conflict, a Future
Reality Tree for a proposed change and possible harm, a Prerequisite Tree for
obstacles, and a Transition Tree for concrete actions and expected effects.
Use the trees that serve the decision; there is no requirement to complete six.

## Freeze one prediction, then compare

1. `C-c r p`: write an experiment title, prediction, and review date.
2. Edit the relevant sections: baseline, dose, measurement, alternative explanation,
   protected conditions, stopping rule, and action. Unknowns can remain explicit.
3. `C-c r f`: preserve the exact formulation before the outcome is known. Supply a
   probability only for a precise binary event you actually want to score.
4. Create the physical work as a GTD next action if you have committed to doing it.
   A draft experiment is not itself an executable action.
5. `C-c r o`: inspect the original forecast, record observations, distinguish an
   implementation miss from a contradicted prediction or inconclusive evidence,
   and state the next decision. Fill in fidelity and changed conditions in the result.

The review date is a cue shown on the dashboard, not a fake deadline or a scheduled
background notification. A past-dated forecast is not automatically labelled
prospective: you explicitly report whether the outcome was still unknown.

The binary event score and the causal assessment are separate. You might correctly
predict an outcome while remaining uncertain about its cause. Numeric predictions
can be compared in prose without shoehorning them into binary scoring.

An experiment gets one programmatic outcome record. Later corrections can be
appended visibly to that result; do not overwrite its history. Automatic scoring
continues to use the recorded binary outcome property. To formally revise an
experiment, create a follow-up with a new prediction and link the earlier one.

## A proposed first experiment for you

This is a proposal, not a claim about your behavior and not an accepted commitment.

**Question:** Does a very small capture-and-review loop help you return to a useful
next action more reliably in one real area of work?

**Boundary:** Choose one current project or one German component skill. Do not
instrument your whole life. Record the existing situation as an unknown baseline
until you observe it; do not invent historical rates.

**Change:** For one week, capture a mismatch when it matters and review those few
captures once. Choose one next action from the evidence.

**Prediction:** Write your own observable expectation before starting. For example,
you might expect the next review to produce one concrete adjustment that you then
try in the following week. Do not inherit a confidence number from this example.

**Alternative:** The dominant issue may be available time, unclear commitments,
missing feedback, task difficulty, or a tool limitation rather than the capture loop.

**Guardrail:** If logging interrupts the work or becomes repetitive rumination,
use the one-line capture only, or stop. These timeboxes are design choices to test.

**Decision at review:** Keep, simplify, adjust, or stop the loop. The outcome is a
better decision and a real attempt, not the number of notes collected.

## Improve a specific skill

`C-c r s` records a component skill, small challenge, and feedback source, followed
by an attempt, the observed feedback, and an adjustment for the next repetition.
For German, that could be a short paragraph targeting one grammar pattern and
reliable correction of that pattern. Add a later sample of ordinary writing to
check transfer. Practice performance alone does not establish broad improvement.

The same goes for brain-training tools such as N-back: a score is evidence about
that task. If you want to claim a benefit elsewhere, specify and assess the
real-world outcome separately. Org Reason makes no assumption that more training
on one task implies more general ability.

## Review the system itself

During a weekly review, make commitments current first. The optional learning
section comes afterward. Look for whether captures were retrievable, projects had
available next steps, feedback changed a decision, and maintenance was tolerable.
Choose one system change at a time as a practical starting rule, not a proven optimum.
Release old experiments, obsolete commitments, and fields that no longer help.
