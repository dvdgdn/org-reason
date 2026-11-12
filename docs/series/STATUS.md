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
| D1 | Volume 3 as one novella plus a casebook | Yes | V3.2 onward |
| D2 | A shared world: one character carried into each later volume | Yes, lightly | V2.4 |
| D3 | Which flashcard reviewer | Undecided; existing cards are in org-drill format | C2, S8 |
| D4 | Whether design directories, which contain spoilers, are pushed to this public repository | Not pushed until decided | Pushing any `design/` |
| D5 | Supplying the image cycling primer and deciding whether it may be committed | Supplied privately, not committed | V3 rungs 2, 3, 13 |
| D6 | Supplying or confirming access to the source books named in the volume files | Needed before step 0 of each volume | V2.1, V3.1 |

Record each decision here with its date when made.

## Phase 0: ground

- [x] **C0** Clean the Org Reason wiring in the owner's configuration.
  Commit `9f88987` in that repository.
- [ ] **S0** Prepare release 0.2.0 from what the changelog lists as
  unreleased. `OWNER` tags and pushes.
- [ ] **C4** Other computers install the tagged release. After S0.
- [ ] **C3** Fix the Org-roam block for a computer with no `~/org`.
- [ ] **P0** `OWNER` Work the seventeen steps of *Three Hundred Seats* on real
  commitments, with this series as one project. The real workspace holds six
  unclarified captures and three projects as of 12 November 2026. Blocks S3.

## Phase 1: volume 2

Story track. Files in `docs/series/volume-2/design/`.

- [ ] **V2.0** `OWNER`, an agent may assist. Work one real problem through all
  six trees with the existing commands. Output `friction.md`: every point
  where the tool or the method got in the way. Decides S4.
- [ ] **V2.1** Step 0: lesson ladder, tension ledger, empty numbers file.
  Needs D6.
- [ ] **V2.2** Step 1: three candidate sentences. **Gate `OWNER`.**
- [ ] **V2.3** Step 2: three candidate paragraphs for the chosen sentence.
  **Gate `OWNER`.**
- [ ] **V2.4** Step 3: characters; tension ledger completed. Needs D2.
  **Gate `OWNER`.**
- [ ] **V2.5** Step 4: one page, with every rung placed.
- [ ] **V2.6** Step 5: character synopses; fair-opponent test.
- [ ] **V2.7** Step 6: four pages; bruises marked; numbers file started.
- [ ] **V2.8** Step 7: character charts.
- [ ] **V2.9** Step 7a: the story commons, validated, with the wrong first
  versions included.
- [ ] **V2.10** Step 8: scene list; all tests for felt tension run on it.
  **Gate `OWNER`.**
- [ ] **V2.11** Step 9: scene briefs.
- [ ] **V2.12** Step 10: draft two chapters. **Gate `OWNER`** on voice. Then
  the rest.
- [ ] **V2.13** Passes 1 to 4: logic, numbers, tension, lesson.
- [ ] **V2.14** Pass 5: exercises. Needs S1 to S3 released, and S4 if built.
- [ ] **V2.15** Cold reader. Record findings in `cold-reader.md` and fix them.
- [ ] **V2.16** Appendix, README, sources. **Gate `OWNER`** before release.

Code track. See [software.md](software.md).

- [ ] **S1** Current constraint.
- [ ] **S2** `OR_SERVES` links. After S1.
- [ ] **S3** Constraint and Candidates panels. After S1, S2 and P0.
- [ ] **S4** Edit and withdraw a commons statement. Only if V2.0 asks for it.

Volume 2 is finished when V2.16 and S3 are released together.

## Phase 2: volume 3

- [ ] **V3.0** `OWNER` Practise one skill from each cell of the table in
  [volume-3.md](volume-3.md) for four weeks with the existing commands.
  Output `friction.md`.
- [ ] **V3.1** Evidence ledger, every source read. Needs D6.
- [ ] **V3.2 – V3.11** Snowflake steps 0 to 9, as V2.1 to V2.11, with the same
  gates. Step 7a builds fictional skill records, sessions and frozen guesses.
  Needs D1 and D5.
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

## Log

- 2026-11-12 Plan written. C0 done.
