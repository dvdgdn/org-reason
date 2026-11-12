# Principles for every volume

These rules hold for every novella, exercise and feature in the series. A
volume's own file adds to them and never overrides them.

## 1. Three properties of a volume

### Independence

A reader can pick up any one novella, with no software and without the other
volumes, and finish with the method working on paper.

The independence test, run on every page before it is accepted:

- The chapter does not rely on events, characters or terms from another
  volume. A character from another volume may appear, but the scene must work
  for a reader who has never met them.
- The general step uses no word that only another volume defines. If a step
  needs the idea of a "next action", it explains it in one sentence.
- The general step names no software.
- The lesson recap gives away nothing from later chapters.
- A reader could do the step with a pen and the pages they made in earlier
  steps of this volume alone.

### Synergy

A reader who already has the practice from another volume gets more from this
one, and is told exactly where.

- Every "The same step in Org Reason" section contains one clearly marked
  paragraph that begins **If you keep a trusted system**. It says what to do
  with this step's result in the reader's lists: which result becomes a
  project, a next action, a waiting-for entry, or a frozen prediction.
- Each volume's file has a synergy table. Every row must be covered by at
  least one page.
- The paragraph is skippable. A reader without the other practice loses
  nothing they need.

### Complementarity

Each volume answers a question the others cannot.

| Volume | It gives the reader | It cannot tell the reader |
|---|---|---|
| 1 | Commitments they can trust | Which of them matters most |
| 2 | A reasoned view of what limits progress | How to become able to act on it |
| 3 | A way to build an ability and check it | What the ability is for |

The last page of each volume ends by naming the question it leaves open. It
does not advertise the next volume by title.

## 2. The page format

Volume 1 has five parts on every page. Later volumes keep them in this order
and may add the sixth.

| # | Part | What it holds |
|---|---|---|
| 1 | The chapter | The story |
| 2 | What the character has just learned | The lesson in a few lines, no spoilers |
| 3 | The general step | The exercise in tool-free terms, with a time estimate |
| 4 | The same step in Org Reason | The same exercise with real commands, checkboxes to confirm, and the **If you keep a trusted system** paragraph |
| 5 | The same step in Reason Commons | Volume 2 on every page; other volumes only where the step involves shared reasoning |
| 6 | Carry forward | What to keep for the next step |

The three exercise sections are layers. Each adds only what its tool adds and
repeats nothing from the layer before.

| Layer | It adds |
|---|---|
| General step | The thinking itself. Complete without anything below |
| Org Reason | Records that persist, stable identity, links from reasoning to commitments, predictions fixed before the outcome |
| Reason Commons | Other people: who proposed a claim, who has endorsed it, who objects and why, and a shared record that an assistant or a colleague can continue from |

The Reason Commons section follows the same pattern as the Org Reason section:
it restates the general step's purpose in one line, gives the concrete actions,
and ends with a way to confirm the result. It must be accurate for the Reason
Commons version the page names.

File conventions, matching volume 1:

- One directory per volume under `docs/`, named for the novella.
- One Org file per chapter, `NN-slug.org`, plus `README.org` and `appendix.org`.
- Chapters run from about 1,100 to 2,100 words.
- Each step states its time: most five minutes, a few fifteen.
- The appendix is read last. It shows how the story was built and sums up the
  method.

## 3. The story comes first

The novellas are stories in which people meet real problems, make mistakes and
find methods. They are not demonstrations of software.

- No software appears in any chapter.
- The method's vocabulary appears only after the character has done the thing
  it names. The character does it clumsily first; the name comes later, if at
  all.
- The mentor asks questions and leaves. The mentor does not explain a method
  in a speech. See the lecture test below.
- Every scene moves both the plot and the lesson. A scene that does only one
  is cut or merged.
- Numbers are exact and consistent. Volume 1 works because three hundred
  tickets, eighty missing seats and a Friday deadline can be checked by the
  reader. Keep a single table of every number, date and name for each volume.

## 4. Making the tensions real and felt

A tension is two legitimate needs that seem to demand opposite actions. The
reader feels a tension only when they can see that both needs are fair and
that the character must still choose. These rules produce that.

1. **Both sides have a face.** Each side of a central tension is held by a
   named character the reader likes. No side is held by a fool or a villain.
2. **Cost before concept.** Before a lesson appears, its absence costs someone
   something that can be counted: money, hours, a place on a list, a person's
   trust. This is the bruise.
3. **The wrong answer is the reader's answer.** The character's first response
   is what a capable reader would do. It works for a short while. Then it
   makes things worse, for a reason the reader could have seen.
4. **The method fails once in the wrong hands.** Each main tool is misused at
   least once: a diagram drawn to prove a point already believed, a conflict
   "solved" by splitting the difference. The failure costs something.
5. **A clock and a price in every part.** Each of the four parts of a novella
   has its own deadline and its own stated cost of missing it.
6. **The solution hurts someone.** The character's answer creates a new
   problem for a character the reader cares about. Dealing with that is part
   of the story, not an afterthought.
7. **The reader's own tension.** Every general step asks the reader to do the
   uncomfortable version with their own material, and says so plainly.
8. **No tension is resolved by a tool, a coincidence or the mentor.** The
   character resolves it by seeing something and then acting on it at a cost.

### Tests for felt tension

Run all of these on the scene list before drafting, and again on the draft.

| Test | Pass when |
|---|---|
| Bruise test | Every lesson has an earlier scene where its lack cost something countable |
| Fair-opponent test | A reader asked "who is right?" at the midpoint cannot answer quickly |
| Wrong-answer test | The first fix is one the cold reader says they would have tried |
| Lecture test | No character explains a concept for more than four sentences in a row, and no concept is named before it has been used |
| Swap test | Removing any scene breaks both the plot and the lesson ladder |
| Price test | For each part, the reader can state the deadline and what missing it costs |
| Cost-of-the-answer test | The reader can name who was hurt by the solution and what was done about it |
| Cold-reader test | A reader new to the method reports at least three places where they wanted to argue with the character, and can do every step |

## 5. Honesty

- The series teaches methods. It does not claim they are proven to improve a
  life. The package README already says there is no claim that training
  performance demonstrates general cognitive improvement. Volume 3 makes that
  sentence its subject.
- Every claim about what a technique does carries an evidence tier and a
  primary source that someone working on the series has read. Figures quoted
  from memory or from an assistant's summary are marked unverified until read.
- Trademarks and sources are acknowledged the way volume 1 does for GTD.
- A speculative practice stays in the series as speculative. It is described
  fairly, labelled, and tested by a prediction fixed in advance. The software
  never asserts that it works.

## 6. Where things live

| Thing | Place |
|---|---|
| This plan | `docs/series/` |
| A volume's working design files | `docs/series/<volume>/design/` until the volume ships |
| A volume's story commons | `docs/series/<volume>/commons/` |
| The finished novella | `docs/<novella-slug>/` |
| Package code, jobs, scenarios, tests | As `CONTRIBUTING.md` lays out |
| Adapters for public packages | `adapters/` in this repository, optional, never required by the core |
| Adapters for the owner's own tools | Beside the tool in the owner's Emacs config |
| The owner's records | Wherever `org-reason-directory` points. Never in this repository |

Design files contain spoilers and this repository is public. Do not push a
design directory without the owner's decision.
