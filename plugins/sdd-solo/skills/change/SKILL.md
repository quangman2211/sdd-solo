---
name: change
description: Phase 5 — the gate for a CHG-### that changes behaviour already shipped (proposal, design, delta ADDED/MODIFIED/REMOVED matching the baseline, the UCs it touches must be implemented). Red means no code changes; green sets status applying, writes the marker .sdd/gate/CHG-###.ok and commits.
disable-model-invocation: true
argument-hint: "CHG-###"
allowed-tools: Bash Read
---

Reply in whatever language the user writes in; keep file names, IDs and slugs in English.

The Phase 5 gate for `$1`.

Phase 5 is only for a change that makes **an old AC no longer true** on an already `implemented` UC. Adding a new AC without breaking an old one is still Phase 3: edit the UC directly, `## History` v+1 in `UC-###.trace.md`, done. If the user opens a change for something that belongs to Phase 3, say so immediately and do not continue.

1. No change folder yet → create one first: copy `${CLAUDE_PLUGIN_ROOT}/templates/skel/change/` (if the variable is not substituted: `find ~/.claude/plugins -type d -name skel -path '*sdd-solo*' | head -1`) to `specs/changes/$1-<slug>/`, fill it in with the user, commit `docs($1): ...`. Do not invent Why/Scope/delta for them.
2. Run it and print the output verbatim:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/change-check.sh" $1
```
(if `${CLAUDE_PLUGIN_ROOT}` is not substituted: `find ~/.claude/plugins -type f -name change-check.sh -path '*sdd-solo*' | head -1`).
3. Exit ≠ 0 → **THE GATE IS CLOSED**. For each ✗ line say what to fix and where. The four common ✗ lines and what they really mean:
   - *"not re-read by an unprimed head"* / *"the change moved after the re-read"* → run `/sdd-solo:verify $1` (6.0.0, #38: required, there is no overnight door any more). That is the first thing to do, not editing the spec.
   - *"the UC is still draft, not implemented"* → this is Phase 3; close the change.
   - *"no delta MODIFIED/REMOVED anything"* → also Phase 3.
   - *"REMOVED AC-# but the baseline does not have it"* → the delta is talking about a different baseline from the real one; re-read the UC before touching the delta.
   Do not edit the spec for the user (unless they ask). Do not write code. Stop here.
4. Exit 0 → run:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/pass.sh" change $1
```
The script sets `Status: applying`, writes `.sdd/gate/$1.ok`, and commits `docs($1): change reviewed — Phase 5 gate passed`. Without that marker the githook blocks every code commit tagged `($1)`.
5. STATE.md: `Working on: $1 · past the Phase 5 gate — applying`. `Next: test for the new AC (red first) → change the domain → the old ACs that were kept are still green`.
6. Remind the user: an AC marked `REMOVED` is **not deleted** from the baseline at archive time — it is marked `deprecated` with a date. And the last task in `tasks.md` is the archive: merge the delta into `specs/`, the UC's `## History` v+1 in `UC-###.trace.md`, commit `chore($1): archive`.

There is no skip flag.
