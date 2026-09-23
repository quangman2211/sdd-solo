# Questions and answers between agents

An append-only log. When an agent (B · spec, C · review, D · code, T · test, Q · QA) hits something
the spec does not say, it **writes a ticket and stops** — no `AskUserQuestion`, no messaging another
agent. R · the arbiter grades it and answers right under the ticket; A · the coordinator forwards the
`For:` part to each role, or asks the owner when it is L3. This is not spec: when a decision becomes
a rule, B puts it into `specs/` and A records it in `specs/decisions.md`. The log lives in
`notes/hoi-dap/` — outside `specs/`, because it is a trace of the process, not a specification.

Default authority: R decides up to **L2**; an L2 is an **interim** decision, and the `Approve:` box
stays empty waiting for the owner. If more than ___ of R's decisions are overturned in one week,
drop R's authority to L1.

## Four levels

| Level | Kind of question | What R does |
|---|---|---|
| **L0 · Look it up** | The answer is already in spec / ADR / decisions / glossary / design | Answer, **always with `file:line`**. No source → it is not L0 |
| **L1 · Local technical** | Inside the settled `architecture.md` / `design.md`; if wrong it takes < 30 minutes to fix and nobody outside the repo sees it | Decide, record the reason |
| **L2 · Interpretation** | The spec reads two ways, but **the customer sees no difference either way** | Decide **provisionally**, work continues; `Approve:` left empty for the owner |
| **L3 · Owner** | Numbers · thresholds · enums · permissions · prices · the shape of a UC · a new library or runtime location · changing the behaviour of an implemented UC · skipping a process step · gate/close · push/deploy/delete/send outside · keys, real data | **Does not decide.** Drafts a 2–4 option question, one consequence sentence per option, the recommended option first, always including "Undecided — record an Open Question" |

**Grading rules**
1. No source means it is not L0.
2. Torn between two levels → take the **higher** one.
3. The one-sentence test: *if this is decided wrong, does the customer see a difference, or does Main Flow have to be rewritten?* Yes → L3.
4. A Claude Code permission dialog is not a question for this log — always hand it to the owner.
5. R edits no file but this log, and does not commit — A commits.
6. C tends to escalate things `design.md` has already settled: R **reads the design first** before grading; C's "the owner must decide" reaches the owner **only after R confirms L3**.

## Ticket skeleton

```
### #<n> · from: <spec|review|code|test|qa> · task: <BR-###|UC-###|…> · <YYYY-MM-DD>
Question: <one sentence>
Already looked up: <file:line, …>
If chosen wrong: <consequence>
The agent leans towards: <option + why>

**Answer (R):** <level L0–L3> · <the answer, or the question drafted for the owner>
Source / reason: <file:line or reason>
For: <spec · D · T — one line per role saying what to do; the order to apply, if it matters>
Approve: <empty · the owner writes "accepted" or "overturned: …" — required for L2 and L3>
```

One ticket may collect several findings (K1…Kn of one review pass): R grades each K in a table
`| K | Level | Interim decision | For |`, and the end of the ticket states **the order to apply**
(spec first · D · T) — the three roles apply in parallel because they only need the ticket's text.

## Tickets

One file per ticket, `phieu/NNN-<slug>.md`, plus one row in the table below. **Allocate the number
mechanically, never by reading the table and guessing:**
`bash .sdd/scripts/phieu.sh new "<task>" <from-role>` — an atomic lock shared by every worktree, it
creates the file from the skeleton, adds the row and commits the placeholder row immediately; write
the body afterwards (7.2, P-21: four collisions in one day when numbers were allocated by hand).
Closing a ticket: `phieu.sh close <n>` counts F#/K# **in the file** and requires a KETQUA from every
role listed in `For:` (P-33). Audit: `phieu.sh muc-luc`.

| # | Work | From | Date | State | File |
|---|---|---|---|---|---|
