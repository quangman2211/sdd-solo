---
name: state
description: Update STATE.md at the end of a session — which UC and step, the latest decision, the open question, what is next, why you stopped. The solo replacement for a standup. Use it when the user says "update STATE", "done for today", "shutting down".
argument-hint: "[short note]"
allowed-tools: Bash Read Edit
---

Reply in whatever language the user writes in; keep file names, IDs and slugs in English.

Rewrite `STATE.md` (repo root) as exactly these 5 lines. Sources: the old STATE, `git log -5 --format='%s'`, `.sdd/gate/`, the UC open in this session, and `$ARGUMENTS`.

```
Working on:       UC-### · <core|craft> · BR-### · step N — <one phrase>
Latest decision:  <one sentence> (→ ADR-### | specs/decisions.md)
Open question:    <one sentence> (interim decision: ___)  | none
Next:             <the first concrete command or task of the next session>
Stopped because:  <the real reason, "out of battery" included>
```

Rules: never longer than the 5 main lines (keep the Retro section if there is one). "Next" must be something that can be started within 5 minutes. Do not commit STATE on its own — it rides along with the next commit, or `chore(sdd): state` if the user asks.

When "Next" is a new UC, take the suggestion from the `## Related Use Cases` table in the current slice's `br.md` (`specs/<core|craft>/br-###/br.md`), the first UC still `draft`. When the slice has no `draft` UC left, read the `## Crafts and slices` table in `specs/vision.md` to see which slice comes next — but **only write it into STATE, never edit `vision.md`**: layer 0 belongs to the owner.
