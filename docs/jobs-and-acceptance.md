# Jobs to be done and acceptance coverage

Jobs describe the progress sought; scenarios define observable software behavior.
Gherkin is the readable specification. ERT and Python unittest are the executable
contracts. No Gherkin runner is configured, and the `.feature` files are not
themselves an executable test suite. Manual checks are explicitly tagged.

| Job | When… | Help me… | So I can… | Specification |
|---|---|---|---|---|
| J1 | Something has my attention | Save a fragment without classifying it | Return to the present work | capture.feature |
| J2 | I process an accumulated item | Decide the outcome and physical next step | Trust my commitments | gtd.feature |
| J3 | I have a real opportunity to act | See what is available in this context | Choose useful work without false dates | gtd.feature, GTD09; personal priority judgment remains manual |
| J4 | I record voice or handwriting | Preserve the source before interpretation | Correct recognition errors later | media.feature |
| J5 | A difficulty recurs | Inspect observations, assumptions, and alternative explanations | Choose a discriminating intervention | reasoning.feature; operating guide |
| J6 | I expect a change to help | Preserve the forecast and compare the result | Revise the next decision honestly | learning.feature |
| J7 | I practise a skill | Obtain useful feedback and adjust a repetition | Test transfer into real work | learning.feature, LRN04 manual |
| J8 | I reason with other people or tools | Preserve authorship, dissent, and exact endorsement | Resume from a shared model | reasoning.feature |
| J9 | My system gets complicated | Inspect its upkeep and remove excess | Keep attention for the actual goal | weekly review's optional learning section |
| J10 | Someone wants to extend the project | See contracts, code boundaries, examples, and tests | Improve it without a private monolith | architecture.md, README.md |

## Automated traceability

Test definitions carry their scenario IDs in the comment above each test.
Run `python3 scripts/check_scenarios.py` to verify that each `@automated`
scenario names at least one executable ERT or Python contract. CI runs this
check alongside both test suites.

Additional tests cover exclusive creation, cooperative locking, Unicode CLI I/O,
proposal-versus-accepted history, idempotent initialization, filename containment,
topic preservation, cleared reference task states, rebased file links, both paths
of a duplicate ID, commons discovery, and the empty-workspace dashboard and agenda.
Tests use temporary synthetic data;
they never load the user's full init or require private records.

## What remains a local or human check

CAP05, GTD08, LRN04, MED03, and MED04 are manual by design. Automated tests can
confirm storage and state transitions. They cannot establish that an actual Mac
URL handler works, a microphone recorded audibly, a backend recognized handwriting
accurately, a weekly review was thoughtful, or a skill improved in real work.

Tests also do not prove causal validity, human identity, consent, or the effectiveness
of this synthesized learning system. Treat those as real-world judgments and
review outcomes, not green CI badges.
