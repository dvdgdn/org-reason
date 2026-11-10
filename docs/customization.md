# Extend a small core

The settings (`org-reason-directory`, `org-reason-device`, `org-reason-language`;
see [install](install.md)) configure paths and provenance without editing library
code. Different directories give separate datasets, for example a work and a
personal one; to share one dataset between computers, see install.md. Nothing here establishes cross-device sync, encryption,
backup, or organizational permission to transfer data. Use one deliberate writer at
a time if you configure file sync separately.

## Org-roam

If your Org-roam root already contains `org-reason-directory`, keep it that way:
don't switch the root to a subdirectory just for Org Reason, which would hide
existing notes from the index. New knowledge headings have ordinary Org IDs and
appear as heading nodes when Org-roam synchronizes.

Every inbox capture, action, and experiment also has an ID, and would flood
`org-roam-node-find` if indexed. So with `org-reason-roam-knowledge-only` on (the
default), `org-reason-mode` adds one entry to `org-roam-file-exclude-regexp` that
leaves the workspace's `inbox`, `gtd`, `learning`, `archive`, `media` and `commons`
directories out of the index; only `knowledge/` is indexed. To index everything,
set the option to nil before turning the mode on and run `M-x org-roam-db-sync`.
To index experiments and practice records too, keep the option off and add your
own entry without `learning`. No canonical notes are moved either way.

## Media adapters

`org-reason-ocr-command` and `org-reason-transcription-command` are argv lists, not shell
strings. `%f` is replaced by the preserved original's full filename. The process
runs asynchronously only when explicitly invoked and must print UTF-8 text on
stdout. Use stderr for diagnostics. The adapter saves a new interpretation and
marks it pending, retaining all previous interpretation files and the original.

Use `M-x org-reason-import-interpretation` when the tool writes a text file instead of
stdout. Mark the latest interpretation reviewed with
`M-x org-reason-mark-interpretation-reviewed` only after checking it. This is an explicit
user assertion, not automated verification. Derived text never auto-creates accepted nodes.

Phone and paper are legitimate collection tools. Put exported files directly in
`inbox/drop/` and run `C-c r I`. Repeat runs skip already captured content hashes
without deleting source files. The command scans only direct regular files;
subdirectories and symlinks are not followed. A watched-folder daemon is not shipped.

## Stable extension points

| API | Contract |
|---|---|
| `org-reason-capture-text TEXT &optional TITLE METHOD SOURCE` | Save without classification; return ID |
| `org-reason-import-file PATH &optional METHOD` | Preserve original bytes; return capture ID |
| `org-reason-add-derivative ID TEXT KIND &optional HUMAN` | Preserve a separate interpretation; machine output pending |
| `org-reason-clarify-entry DISPOSITION OPTIONS` | Apply one explicit inbox decision while retaining ID |
| `org-reason-next-action TITLE CONTEXT EFFORT REASON` | Create an available reminder without a fake deadline |
| `org-reason-create-experiment TITLE PREDICTION REVIEW-DATE` | Create an editable draft; not yet a prospective forecast |
| `org-reason-add-result ID ASSESSMENT OBSERVATION OUTCOME FEELING DECISION` | Link an outcome to a frozen original |
| `org_reason_commons.py --file PATH` + JSON stdin | Validated native reasoning edits with digest-based concurrency checks |

Internal double-hyphen functions are not stable APIs. Keep new adapters optional;
do not add media dependencies to quick text capture. Add a job, scenario, and
meaningful executable contract for new behavior.

## Existing AI tools

Use the existing Claude Code integration over the local data when you deliberately
want help interpreting it. Org Reason itself sends no prompts or records to
an AI provider. A suggestion remains a proposal; the human owns commitments and
endorsement. The [agent handoff prompt](agent-handoff.md) helps keep that boundary
clear in another conversation.
