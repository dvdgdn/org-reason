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

The full test names begin `org-reason-test-` (ERT) or `test_` (Python). The suffixes
below identify the actual executable contracts. Some scenarios share a test
because they describe inseparable parts of one end-to-end workflow.

| Scenarios | Executable contract suffixes |
|---|---|
| CAP01 | `capture-needs-no-classification` |
| CAP02 | `existing-capture-templates-and-protocol-survive`, `owned-template-enable-disable` |
| CAP03 | `standard-org-capture-really-finalizes` |
| CAP04 | `drop-import-is-repeatable-and-does-not-delete` |
| GTD01 | `clarification-preserves-identity-and-body` |
| GTD02 | `project-has-single-next-action-and-audit` |
| GTD03 | `waiting-records-person-and-delegation-date`, `invalid-clarification-keeps-inbox` |
| GTD04 | `incubation-is-not-next-action` |
| GTD05 | `real-date-required-only-for-calendar-or-tickler` |
| GTD06 | `failed-refile-keeps-source-material` |
| GTD07 | `review-preserves-answers-on-repeat` |
| GTD09 | `engage-filters-context-time-and-completed-parent` |
| LRN01, LRN03 | `prediction-original-cannot-be-rewritten-by-freeze` |
| LRN02 | `retrospective-and-unresolved-not-silently-scored` |
| RC01 | `capture_is_proposed_with_attribution`, `all_six_tree_families_use_native_kinds` |
| RC02 | `and_link_is_one_relationship_with_multiple_sources` |
| RC03 | `endpoints_must_be_accepted_before_link` |
| RC04 | `challenging_node_demotes_incident_links_and_retains_history` |
| RC05 | `backlog_is_independent_of_acceptance` |
| RC06 | `stale_digest_refuses_without_lost_update`, `uncooperative_external_edit_is_detected_before_replace` |
| RC07 | `unfamiliar_schema_and_duplicate_yaml_keys_are_rejected` |
| RC08 | `unknown_optional_data_survives_reserialization` |
| RC09 | `assistant_contribution_is_not_human_acceptance` |
| RC10 | `rc-link-selects-the-reasoning-object`, `emacs-python-real-schema-round-trip` |
| RC11 | `rendering_failure_reports_saved_state` |
| MED01, MED02 | `media-original-and-link-survive-refile` |
| MED05 | `async-machine-output-is-separate-and-pending` |

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
