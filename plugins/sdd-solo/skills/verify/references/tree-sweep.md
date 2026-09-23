# verify · the tree sweep (`/sdd-solo:verify` with no ID)

<!-- Read this file when /sdd-solo:verify was given no ID: the sweep over the whole spec tree rather than a re-read
     of one UC or one change. Part A in SKILL.md is the per-ID round and does not apply here (8.1.0). -->

## B. `/sdd-solo:verify` — the tree sweep

Use it when the documents just changed a lot and you need to know what still disagrees. Not tied to any gate.

1. **Pick the scope first, do not skim the whole tree.** A small tree (< ~3,000 lines) can be read whole. Larger:
   take `git diff --name-only <the previous verify>..HEAD -- specs/` plus **every file whose IDs those cite**
   (`RULE-###` → `specs/rules.md` or `specs/<craft>/rules.md`, `CON-###`/`BR-###` → that slice's `br.md`, `UC-###` →
   that UC's file, an entity name → that entity's file). Skimming the whole tree is the surest way to miss error
   kinds #3 and #4, the two most common ones.
2. Run a **subagent** with `.sdd/prompts/verify-pass.md` over that scope. For a large tree, split by layer — one
   agent for vision↔BR, one for BR↔RULE, one for UC↔AC↔flow, one for entity↔glossary — but **each agent must still
   see both sides** of the pair it is checking, otherwise it only reads half the argument.
   One extra check exists only in the 7.0 tree: **does the root `specs/*.md`, `specs/adr/` or `specs/core/` cite any
   craft's IDs** — `bash .sdd/scripts/layer-check.sh` counts it mechanically, cheaper than reading.
3. Check each `F#` as in part A step 4 — asking nobody.
4. Write the result into `notes/soat/verify-<YYYY-MM-DD>.md` (a process trace, outside `specs/`): the scope read,
   each `F#` with both sides verbatim, and its output. **Record the rejected lines too, with the reason** — that is
   what makes the next run cheaper, and the only thing left after the terminal is closed.
5. `git add notes/soat/verify-<date>.md && git commit --only -m "docs: verify pass <date> — <n> findings" --
   notes/soat/verify-<date>.md` (6.x: `specs/internal/`), then print the `Undecided` list as in part A step 8.
   Editing the spec per the answers is a separate round.

---
