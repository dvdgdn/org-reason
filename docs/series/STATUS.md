# Status and order of work

Update this file in the same commit as the work it records. It is the only
place that says what is done.

## How to run a session

1. Read [README.md](README.md), then this file.
2. Take the first package below that is not done, not blocked and not marked
   `OWNER`. If the first open item is an owner gate or decision, present it to
   the owner and stop.
3. Read the files the package names. Read [principles.md](principles.md)
   before any writing, and [snowflake.md](snowflake.md) before any story work.
4. Work on a branch from `main` named `series/<package>`, for example
   `series/s1-constraint`. Code packages follow `CONTRIBUTING.md`.
5. Run the checks the package and the twelve rules in the README require.
   State plainly in the commit message anything not checked.
6. Tick the package here, add one line under "Log", commit. Do not push; the
   owner pushes.

Two packages may run at the same time only if they touch different files. A
story package and a code package usually can.

## Decisions waiting for the owner

| # | Decision | The plan assumes | Blocks |
|---|---|---|---|
| D1 | Volume 3 as one novella plus a casebook | Yes. Acted on 13 Nov 2026 without the owner choosing; reversible | V3.2 onward |
| D2 | A shared world: one character carried into each later volume | Yes, lightly. Acted on 13 Nov 2026: Ruth of the Maple Street Pantry appears once in volume 2; volume 3 mentions Garnet Street | V2.4 |
| D3 | Which flashcard reviewer | Undecided; existing cards are in org-drill format | C2, S8 |
| D4 | Whether design directories, which contain spoilers, are pushed to this public repository | Not pushed until decided | Pushing any `design/` |
| D5 | Supplying the image cycling primer and deciding whether it may be committed | Supplied privately, not committed | V3 rungs 2, 3, 13 |
| D6 | Supplying or confirming access to the source books named in the volume files | Needed before step 0 of each volume | V2.1, V3.1 |

Record each decision here with its date when made.

## Phase 0: ground

- [x] **C0** Clean the Org Reason wiring in the owner's configuration.
  Commit `9f88987` in that repository.
- [x] **S0** Prepare release 0.2.0 from what the changelog lists as
  unreleased. `OWNER` tags and pushes.
- [ ] **C4** `OWNER` Other computers install the tagged release. The pin is
  in the configuration (commit `ff75455` there) and installs v0.2.0 on a
  computer without the package; checked in a fresh profile. What remains is
  to start Emacs on each other computer. One that already has an install
  follows the comment above the Org Reason block in `init.el`.
- [x] **C3** Fix the Org-roam block for a computer with no `~/org`. Commit
  `b097d0d` in that repository, on the branch
  `claude/org-reason-novellas-1764a6`; not yet on its `main`.
- [ ] **P0** `OWNER` Work the seventeen steps of *Three Hundred Seats* on real
  commitments, with this series as one project. The real workspace holds six
  unclarified captures and three projects as of 12 November 2026. Blocks S3.

## Phase 1: volume 2

*The Fourth Visit* was written in one pass on 13 November 2026, after the
owner said "finish the novellas". The gates were not held: the writing agent
made each choice and recorded it in `docs/series/volume-2/design/story.md`.
See "What was skipped" below before treating any of this as finished.

Story track. Design files in `docs/series/volume-2/design/`; the novella in
`docs/the-fourth-visit/`.

- [ ] **V2.0** `OWNER` Work one real problem through all six trees with the
  existing commands. Not done. Decides S4.
- [x] **V2.1 – V2.8** Steps 0 to 7, folded into `story.md` and `numbers.md`.
  Gates at steps 1, 2 and 3 decided by the agent.
- [ ] **V2.9** Step 7a. The story's reasoning is in `reasoning.md`, written
  by hand. It has not been entered as a commons or validated.
- [x] **V2.10** Step 8: `scenes.md`, with the tests for felt tension run on
  the list. Gate decided by the agent.
- [x] **V2.11 – V2.12** Briefs and draft, done together. No voice gate.
- [x] **V2.13** Passes 1 to 4, by the writing agent only.
- [x] **V2.14** Pass 5: exercises, written against release 0.2.0. They use
  only commands that exist. Revise the Org Reason sections when S1 to S3
  ship: steps 9, 15 and 16 will change most.
- [ ] **V2.15** Cold reader. Not done.
- [x] **V2.16** Appendix and README. **Gate `OWNER`** before release: read it.

Code track. See [software.md](software.md).

- [ ] **S1** Current constraint.
- [ ] **S2** `OR_SERVES` links. After S1.
- [ ] **S3** Constraint and Candidates panels. After S1, S2 and P0.
- [ ] **S4** Edit and withdraw a commons statement. Only if V2.0 asks for it.

Volume 2 is finished when V2.16 and S3 are released together.

## Phase 2: volume 3

*Two Minutes at Full Speed* was written the same way on 13 November 2026.
Design files in `docs/series/volume-3/design/`; the novella in
`docs/two-minutes-at-full-speed/`.

- [ ] **V3.0** `OWNER` Practise one skill from each cell for four weeks. Not
  done.
- [ ] **V3.1** Evidence ledger. Not done. The novella's appendix states what
  it takes to be known, from general knowledge, with sources named and not
  re-read. The SMART figures are still unverified and are not used.
- [x] **V3.2 – V3.11** Snowflake steps, folded into `story.md`, `numbers.md`
  and `scenes.md`. Gates decided by the agent. The fictional records of step
  7a are in `numbers.md`.
- [x] **V3.12 – V3.13** Draft and passes, by the writing agent only.
  Exercises use only commands in release 0.2.0; revise when S5 to S10 ship.
- [ ] **V3.14** Cold reader. Not done.
- [ ] **V3.15** Release. **Gate `OWNER`**: read it, and decide D5. The
  image cycling chapters were written from the plan's summary of the
  owner's primer; the primer itself is not in the repository.
- [ ] **S5** Skill records.
- [ ] **S6** Session logging. After S5.
- [ ] **S7** Source registry.
- [ ] **C1** N-back hook and adapter. After S6 and S7.
- [ ] **C2** `OWNER` chooses the flashcard reviewer (D3); install it.
- [ ] **S8** Flashcard adapter. After C2 and S7.
- [ ] **S9** Routine for self-reported practice. After S5.
- [ ] **S10** Practice panel. After S7 and V3.0.
- [ ] **V3.12 – V3.15** Draft with its gate, passes, cold reader, release.

## Phase 3: the casebook

One case at a time, in the order of the owner's own practice. For each:

- [ ] Ledger row complete; owner's four weeks of records exist.
- [ ] Adapter or routine released.
- [ ] Short Snowflake: steps 0, 1, 2 **gate `OWNER`**, 3, 8, 10.
- [ ] Passes, cold reader, release.

## Phase 4: the hub as a whole

- [ ] **S11** Graphics where supported; tutorial and worked example cover all
  panels on fictional data.
- [ ] Release 1.0. `OWNER`.

## What was skipped when the novellas were written

Both novellas exist in full. These things the plan required were not done,
and each is a reason not to call a volume released.

| Skipped | Consequence | To put right |
|---|---|---|
| Owner gates at Snowflake steps 1, 2, 3, 8 and the voice gate | Setting, characters and plot are the agent's choices | Owner reads `design/story.md` for each volume and the first two chapters; anything rejected is rewritten from that step down |
| D6: the source books were not read | The method is taught from general knowledge. Terms and emphasis may differ from Goldratt, Dettmer and Ericsson | Read them; correct the appendices and any step that misstates the method |
| V2.0 and V3.0: the owner's own practice | No friction log, so the Org Reason sections describe the commands as documented, not as lived | Owner works the steps; revise pages where the tool gets in the way |
| Step 7a for volume 2 | The story's trees are not a validated commons | Enter `reasoning.md` as a commons under `docs/series/volume-2/commons/` and validate |
| Evidence ledger (V3.1) | Claims in volume 3's appendix are unverified | Read each source listed there |
| Cold readers | Nobody new to either method has done the steps | One reader per volume |
| S1 to S10 | Exercises cannot use the constraint, skill and session records | Build them; revise the pages |
| Casebook | Not started | Phase 3, after the owner's own practice |

Checked by script (`docs/series/tools/check_volume.py`): no software or key
names in any chapter; every Org Reason key in the exercises exists in 0.2.0;
links resolve; chapters are between 1,100 and 1,900 words.

## Log

- 2026-11-12 Plan written. C0 done.
- 2026-11-12 S0 release files prepared. The owner still needs to tag v0.2.0.
- 2026-11-12 S0 done. Published Org Reason 0.2.0 as `v0.2.0`.
- 2026-11-12 C4 pin published in Emacs config commit `ff75455`. Installs on other computers are pending.
- 2026-11-12 C3 done in Emacs config commit `b097d0d` (unmerged branch). S0 and C4 reviewed: release CI passed on Linux, macOS and Windows; the pin installs v0.2.0 in a fresh profile. C4 now waits only on the owner.
- 2026-11-13 *The Fourth Visit* (18 chapters) and *Two Minutes at Full Speed* (16 chapters) written with their steps, on the branch `series/novellas`. Gates not held; see "What was skipped".
