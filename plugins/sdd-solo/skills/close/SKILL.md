---
name: close
description: Step ⑭ — Definition of Done for one UC — every AC has a correctly named test, docs comes before feat in the git log, literal numbers are reviewed (hidden rules), History has a line; green sets status implemented, writes traceability and commits.
disable-model-invocation: true
argument-hint: "UC-###"
allowed-tools: Bash Read Edit
---

Reply in whatever language the user writes in; keep file names, IDs and slugs in English.

Close `$1`.

**Never delegated to an agent:** `close` is the owner's job (orchestrate §2 rule 7). Running under another agent's brief → stop and write `KETQUA ket=chan hoi=-` saying plainly "close is the owner's job".

1. Go through the five self-review questions with the user first (from `.sdd/checklists/self-review.md`), especially question 5 *"who decided, the AI or me?"* — if there is a technical decision worth remembering, append one line to `specs/decisions.md` (root) in the format that file uses.
2. Run it and print the output:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/close-check.sh" $1
```
3. Exit ≠ 0 → list what is still missing (a missing test, the commit order, the gate not passed). Stop.
4. A "literal numbers to review" warning → walk each line with the user: every number must cite a RULE/CON or the user explains it; a number that is a business rule the spec does not have → stop, add the RULE, commit `docs(...)`, and only then close.
5. Exit 0 → run:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/pass.sh" close $1
```
6. If the spec changed while coding and `## History` does not say so → add the v+1 line to **`UC-###.trace.md`**
   before passing. Since 8.0.0 the trail lives there from the first line, so `pass.sh close` has nothing to move: it
   appends the `implemented` version line to that file, and compresses the `[x]` Open Questions out of the UC body.
   (On a repo written before 8.0.0 it still moves the three sections out of the body, exactly as 5.0.0 did — run
   `migrate.sh --trace` once and that path is never needed again.) Tell the user: `trace.md` is **scratch paper
   already used** — open it when something is disputed, it is not everyday reading; `context.sh` and `decisions.sh`
   do not read it. Measured on the runxops copy: 2.33 MB of UC bodies → 1.01 MB, with nothing lost.
7. Suggest the next UC from the `## Related Use Cases` table in the slice's `br.md` (the first one still `draft`) and mention `/sdd-solo:state`.

   The slice has no `draft` UC left → say so, and read the `## Crafts and slices` table in `specs/vision.md`: which
   slice of the craft comes next, or whether this craft is close to "done" per `## What "done" means per craft`.
   **Never declare a craft done and never open the next one** — the "done" condition belongs to the owner, at layer 0.
   Only read the condition back to the user and ask.
