# Native Reason Commons contract

Compatibility target: conversational YAML `schema_version: 1`, from
`reasoncommons/reasoncommons` commit
`06f77ff081b55e9a8bbbd85f451dd60b63bd6316` (checked 7 November 2026).
The exact upstream schema reference and licensed validators are vendored.

The website describes a skill-based project with YAML as its local source of
truth. This addon is an additional **local authoring interface**. It does not
invent a public write API, publish a commons, or synchronize a hosted account.

## Roles and logical discipline

| Native tree | Useful question | Preserve |
|---|---|---|
| `goal` | What must be true to reach the goal? | Necessary conditions are not individually sufficient causes |
| `current_reality` | Why are these effects occurring? | Testable causal hypotheses and enabling conditions |
| `conflict` | Which apparent requirements conflict? | Objective, legitimate needs, prerequisites, and assumptions |
| `future_reality` | What might the proposed change cause? | Injection, predicted effects, and harmful branches |
| `prerequisite` | What must become possible first? | Obstacles, intermediate objectives, and order |
| `transition` | What concrete action has which expected effect? | Conditions, actions, needs, and expected effects |

`observation` is also available in every tree. The role list comes from the
upstream schema. A structural validator cannot establish whether an arrow is
causally sound or whether the current system constraint has been found.

## Actual behavior

- New nodes and relationships are always `proposed`, with attributed contributions.
- Multiple IDs in one link's `from` list represent jointly operating conditions
  (AND). Alternative causal paths are separate links.
- Endorsement requires a configured human, the displayed item, and the inspected
  file digest. Assistant contributions retain `by: assistant`; assistants cannot
  endorse through the bridge.
- An accepted relationship requires accepted endpoints. A substantive challenge
  disputes its item and returns accepted incident relationships to proposed.
- Adding an assumption returns the item to proposed, because the formulation to
  endorse has changed. Prior endorsement fields remain historical, not current status.
- Backlog is independent of endorsement. An accepted item may still need a test.
- Acceptance means an endorsed formulation, not empirical verification, an
  authenticated identity, group consensus, or approval to implement anything.
- The Org view includes all statuses. Upstream full and latest-change diagrams
  show accepted reasoning, with history triggered by accepted semantic change.
- Cross-tree traces, native feedback requests, change acceptances, share consents,
  and other optional structures already in the file survive ordinary edits.

`C-c r t x` creates one GTD reminder for a selected Transition Tree action. A
repeat invocation opens that existing reminder, including when it is completed;
it does not generate another commitment. Explicitly create a new action for a
new round of work. Creating the reminder does not endorse its reasoning.

## Using an existing commons

Copy the existing complete commons directory, including history, into
`commons/<slug>/`, or use the same data directory deliberately in both tools.
Never maintain two working copies while expecting automatic merges. The package
looks for `reason-commons.yaml`. Use `rc:<slug>/<node-or-link-id>` from an Org note
or an action's `OR_REASON` to navigate it.

Work in turns with Claude Code or the upstream LTP workflow. The bridge refuses
to operate while the YAML has unsaved edits in Emacs, rejects a stale inspected
digest, and reports a remaining lock rather than overwriting another writer.
Unknown schema versions are refused. Existing unversioned drafts need a deliberate
upstream migration; the package does not guess their meaning.

YAML comments and formatting are not round-tripped. If those carry indispensable
information, keep them in a note or use a comment-preserving external editor and
validate before returning to Org Reason. Structural optional fields are preserved.

## Editing and resolving a challenge

Node text editing, deletion, complex tree restructuring, and challenge-resolution
conversations are done in the canonical YAML or the upstream LTP workflow in this
release. They are not fake menu commands. Preserve the objection and its authorship,
record its resolution visibly, and explicitly choose the resulting status. The
addon refuses one-click endorsement of an unresolved disputed item.

After manual YAML edits, invoke `C-c r t v` to validate and inspect all statuses,
then `C-c r t g` to refresh accepted-history views. Maintain IDs and demote dependent
links when endpoints lose acceptance. Do not manually rewrite accepted-history files.

Learning experiments currently use Org and their own frozen forecast snapshots.
They can link to a commons via `OR_COMMONS` and `OR_REASON`; they do not implement
the upstream multi-participant `feedback_requests` lifecycle. That native structure
is preserved and validated when present, not mirrored into a competing queue.
