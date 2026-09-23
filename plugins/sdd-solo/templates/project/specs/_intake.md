# Intake — the questions that pull an idea out into a BR

Use this when only the sample `core/br-000/` exists and you do not know where to start.
With Claude Code, type `/sdd-solo:intake` — it asks one question at a time and writes the slice's `br.md`.
Without it, answer the seven questions below on paper and fill `specs/<core|craft>/br-###/br.md` per the
right-hand column.

**Question 0 — before the seven:** does `specs/vision.md` exist yet? If not, the owner writes it first, in
plain words: where we are going · 3–5 things that must not shrink · which craft opens first, and what
"done" means. Every BR has to claim its `**Slice:**` from that table, so without layer 0 the seven
questions below have nothing to stand on.

**Three rules while answering:**

1. **"I don't know" is a valid answer.** Write `___` and mark it as an Open Question.
   A number guessed here will be defended by all 24 checks at the DoR gate for the rest of the project's life.
   That includes a number **you guessed yourself** — "a few times every week" is an estimate, not a count;
   say it is an estimate, do not let it become a fact in `## Background`.
2. **Tell the story, do not list features.** If the answer starts with "build a…", that is a solution, not a
   problem. Ask yourself back: *what would that let me know or do that I cannot now?*
3. **One question at a time.** Reading all seven and thinking about them together produces seven vague answers.

---

## The three required questions

Do not write `br.md` until these three are done.

| # | Question | Where it goes in br.md |
|---|---|---|
| 1 | What hurts right now? Tell it plainly, no polish needed. | `## Background` · `## Goal` |
| 2 | Who is hurting? (me · the customer · whoever operates it · another system) | `## Goal` · WHO on the Impact Map |
| 3 | How do they cope today, and what does it cost? (time · number of mistakes · money) | `## Background` |

Answers — write them straight in here:

> **1.**
>
> **2.**
>
> **3.**

Question 3 is where the baseline number comes from. Never counted it? Write `___` **and write down how you
will count** — "count the threads in the inbox every Monday" is a valid way to measure; no analytics needed.

## The four digging questions

Only ask these once the first three have answers. Ending in `___` is allowed.

| # | Question | Where it goes in br.md |
|---|---|---|
| 4 | If nothing is done for another six months, what happens? | `## Background` or `CON-###` |
| 5 | Is there a way to get that **without building software**? (buy one? change the process? hire someone?) | `## Background` — record why building still wins |
| 6 | What are you **deliberately not doing** in the first version? | `## Out of Scope` + a `-.->` branch on the Impact Map |
| 7 | How will you know it is done? Which number, taken from where? | `## Success Metrics` |

**Question 5 is the most valuable one and the most often skipped.** It is the only thing that stops you
building software that need not exist. The more exciting the idea, the more it has to be asked.

Not thought about it yet? Do not leave it blank — **that is an answer too**. Put one line in `## Background`:
`**Why still build:** no reason yet — no non-software option has been weighed`. Far more honest than a
sentence that sounds as if the weighing had been done, and `br-check` keeps reminding you until that line exists.

Stuck? List **at least three** non-software routes and knock each one down: change the process · do it by
hand in batches · buy an existing tool · hire someone · a shelf and a label. Naming exactly one means you
are walking yourself into it.

Answers:

> **4.**
>
> **5.**
>
> **6.**
>
> **7.**

**No answer to question 6 = the BR is not finished being thought about.** A team has a PO to hold scope back;
working alone, that Out of Scope line is the only thing that does.

---

## When that is done

```bash
.sdd/scripts/br-check.sh BR-001
```

Warnings about `___` are **normal in Phase 1** — that is debt on the books, not a mistake.
The ✗ lines are what must be fixed.

Then `/sdd-solo:adversarial BR-001` — three roles read the BR you just wrote back at you. The sceptic asks
exactly one frightening question: *is this really a BR, or a solution already chosen and written backwards
into a reason?*

---

## If you are holding a brief written by another agent

```
/sdd-solo:intake path/to/brief.md
```

Do not copy it straight into `specs/`. A brief written by an LLM almost always carries plausible numbers
nobody decided — *"lock for 15 minutes after 5 failures"*, *"hold stock for 30 minutes"*, *"support 100
concurrent users"*. None of them has a source. Once copied in, all the DoR gate checks will defend them very
diligently from then on.

Four rules for the conversion:

1. A number with no source → `___` + an Open Question. A brief **proposing** a number ≠ somebody **approving** it.
2. Every "build X" must push back up to a measurable goal. It does not → an orphan feature; into Out of Scope
   or an Open Question, never left silent.
3. A claim without evidence ("customers complain a lot") → an Open Question, not `## Background`.
4. Anything **dropped** goes into the BR's `## Dropped from brief` section, one line each with a reason **and a
   destination**: `→ slice ___` (which slice in `vision.md` picks it up) or `→ reopen when ___` — not just said
   out loud once. Six months later the file is the only thing left. `br-check` goes red when a line has no
   destination (7.0).
