# A small, orthogonal vocabulary

Capture needs no tags or classification. Automatic metadata records the capture
time, device, method, default language, optional location, source, and private
classification. The privacy value is descriptive metadata, not encryption or an
access-control system.

## Representation

| Dimension | Representation | Examples |
|---|---|---|
| Identity | Org `ID`, or native commons ID | Stable across an ordinary refile |
| Primary personal object type | `OR_TYPE` | question, observation, hypothesis, reference, action, project, experiment, result, practice, feeling, failure |
| Subject | Org tags or links to richer topic notes | `:german:`, `:writing:`, a project or topic ID link |
| Action state | Org TODO keyword | TODO, NEXT, WAIT, SOMEDAY, DONE, CANCELLED |
| Physical/tools context | Org context tag | `:@computer:`, `:@calls:`, `:@home:` |
| Action activity | `OR_ACTION_KIND` | read, listen, meet, write, call, investigate, practise |
| Estimate | Org `EFFORT` | `0:20` |
| Actual time | Org clock records | LOGBOOK CLOCK intervals; no parallel actual-time field |
| Available effort | `OR_ENERGY` | low, medium, high; optional self-description |
| Language of this content | `OR_LANGUAGE` | en, de, zh |
| Language of original source, when different | `OR_SOURCE_LANGUAGE` | de |
| Language being learned | `OR_TARGET_LANGUAGE` | de now, zh later if relevant |
| Origin device | `OR_DEVICE` | laptop, work-computer, phone |
| Original recording device, if different and known | `OR_SOURCE_DEVICE` | phone; importing on a Mac does not identify the original recorder |
| Delivery / capture method | `OR_METHOD` | manual, org-capture, browser, audio, handwriting, drop |
| Physical place, if useful | `OR_LOCATION` | An explicitly entered location; never inferred from IP |
| Source or explanatory connection | `OR_SOURCE`, `OR_REASON`, `OR_COMMONS` | source URI/path; `rc:writing/n-…`; commons slug |
| Feeling | `OR_FEELING` or a standalone feeling note | fear, aversion, confusion, relief, or your own words |
| Failure interpretation | `OR_FAILURE_CLASS` | simple, complex, intelligent, unclassified |
| Evidence quality / interpretation | original hash; derivative review property | pending, human-authored, human-reviewed |

Use `C-c r M` to set or remove an optional field; `C-c r /` finds by a field or
tag through normal Emacs completion. For substring patterns in body text, use
Consult, ripgrep, or standard Org search. Tags remain ordinary Org
tags; no comprehensive topic ontology is imposed.

## Two important distinctions

A feeling can be the subject of a note **or** an attribute of a result. Neither
requires classifying an entire person. Recording aversion does not establish
whether unclear work, fatigue, a tool problem, competing responsibilities, or
another condition explains a delay.

A failed prediction, an unsuccessful intervention, an implementation miss, and an
intelligent experiment are different dimensions. The optional `simple` value
corresponds to what Amy Edmondson calls a **basic** failure in an established
process. `Complex` concerns interacting contributors. `Intelligent` is reserved
for a considered, bounded attempt in genuinely new territory that produces useful
information, not every avoidable mistake with a positive reframe. Her primary
account is linked in `sources.md`. Leave the interpretation unclassified if unclear.

## Avoid taxonomy debt

Start with topics you already use and contexts that change which actions are
available. Add a property only when it changes retrieval or a decision. Remove
one that does not. Language, device, medium, state, feeling, and topic should not
all become a pile of indistinguishable tags.

Formal commons nodes retain upstream `kind`, `status`, and attribution fields.
They do not acquire an Emacs-specific copy of `OR_TYPE`. Acceptance is separate
from author, observed evidence, and permission to act.
