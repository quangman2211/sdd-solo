---
name: start
description: Step ① of the UC loop — create the use case folder from the skeleton inside its slice (br-###), assign the ID, check the ID is free and the BR exists, update STATE.md. Use it when the user starts a new use case.
disable-model-invocation: true
argument-hint: "UC-### [BR-###] [<english-slug>]"
allowed-tools: Bash Read Write Edit Glob Grep AskUserQuestion
---

Reply in whatever language the user writes in; keep file names, IDs and slugs in English.

Create the skeleton for use case `$1`.

**Ticket mode (7.3) — when running under another agent's brief** (the brief opens with `Vai:`/`Lượt`, or
`bash .sdd/scripts/role.sh --xem` reports a role other than the coordinator, or you are not sure there is a human at
the other end): **do not open `AskUserQuestion`** — nobody clicks it and the turn hangs until it times out (#53).
Every question you would have asked becomes a ticket: `bash .sdd/scripts/phieu.sh new "<task>" <role>` with
Question · Already looked up · If chosen wrong · The agent leans towards; leave whatever depends on it as `___` plus
an interim decision; then **STOP**, ending with `role.sh --ketqua <key> ket=chan hoi=#<n>`. When the owner types this
command themselves in their own session, ask as normal.

The skeleton lives in the plugin: `${CLAUDE_PLUGIN_ROOT}/templates/skel/` (if the variable is not substituted: `find ~/.claude/plugins -type d -name skel -path '*sdd-solo*' | head -1`). Since 5.0.0 the skeleton is no longer copied into the project's `.sdd/templates/` — only skills read it, and a skill only runs when the plugin is there, so the copy in the project was 13 files nobody ever touched (measured at runxops: byte-identical after weeks).

1. Find the repo root (`git rev-parse --show-toplevel`). No `specs/` → tell them to run `/sdd-solo:init` first.
2. ID: `$1` must be `UC-###`. Check it is free: `find specs -path "*/br-*/use-cases/$1-*"`. Taken → stop and say so.
3. **The slice (`$2`) — every UC belongs to exactly one `BR-###` slice.** No `$2`, or unclear, → list the existing slices (`ls -d specs/*/br-*/`) and ask the user to choose **with `AskUserQuestion`**: one option per slice, showing the craft and the slice name taken from the `**Slice:**` line of its `br.md`.

   **The craft follows from the BR's folder**, never asked separately: `specs/core/br-007/` is a core slice, `specs/ebay/br-012/` is a slice of the `ebay` craft.

   The BR the user picks **has no folder** → **stop and tell the user to run `/sdd-solo:intake` first**. Do not create `br-###/` yourself: a BR is the layer above, writing it is intake's job together with the owner, and a skeleton `br.md` produced by this skill would sit there as if somebody had written it.
4. Slug (`$3`): English, kebab-case, verb + noun from the glossary (e.g. `activate-device`). None given → propose one from the UC's name in the `## Related Use Cases` table of that slice's `br.md` if the UC already has a stub, then ask for confirmation.
5. Create:
   - `specs/<core|craft>/br-###/use-cases/$1-<slug>/` from `${CLAUDE_PLUGIN_ROOT}/templates/skel/use-case/` (copy `UC-000.md` → `$1.md`, `UC-000.flow.md` → `$1.flow.md`, `UC-000.sequence.md` → `$1.sequence.md`, `UC-000.trace.md` → `$1.trace.md`, `screens/README.md`). Replace every `UC-000` with `$1`, `Last updated` with today, `Status: draft`.
   - The UC's Metadata: `- **Craft:** <core | craft> · **Slice:** BR-###` — the craft is exactly the folder holding the slice. Check the BR is real: the slice's `br.md` must exist and contain the heading `# BR-###`.
   - Add or update the UC's row in the `## Related Use Cases` table of that slice's `br.md`, columns `| UC | Name | Actor | BR | Status |`.
6. STATE.md: set `Working on:` to `$1 · step ① — skeleton created, no content yet`; `Next:` to `fill in $1's content with the user (step ②) then write the RULEs and ACs`.
7. Tell the user: the file paths, and that the next step is **filling in the content together with the user** per the `sdd-process` skill — **writing into the file just created**, not creating a new one.
8. **Ask the user whether any business question is still unanswered, then classify it for them** — this is where a user usually stalls, not knowing whether to research further or start writing Main Flow:
   - A question that changes the **shape** of the UC (who the actor is · where the data comes from · who is allowed) → **settle it first**, because a Main Flow written on a wrong assumption gets thrown away, not reworded. **Put this group through `AskUserQuestion`** — at most 4 questions per turn, each with 2–4 directions and their consequences, the recommended one first with "(Recommended)", and always an option "undecided — stop here, go ask or measure, come back". Do not write them as bullets at the end of a message (the UC-012 case, #36: the user had to number their own answers).
   - A question that changes a **value** inside a step (a threshold · a deadline · an enum · a key) → **it can wait.** **Do not ask.** Write it straight into `## Open Questions` as `- [ ] <question> (interim decision: ___)` and carry on. `___` there is valid, and `gate-check.sh --pre` does not count it as unfilled.
   The one-sentence test: *if the answer were the opposite, would Main Flow have to be rewritten?*
9. **An entity the UC names that has no file** → copy `${CLAUDE_PLUGIN_ROOT}/templates/skel/entity.md` to `<Name>.md`, one file per entity. Ask the user **with `AskUserQuestion`** where each entity belongs:
   - `specs/core/entities/<Name>.md` — every craft uses this concept;
   - `specs/<craft>/entities/<Name>.md` — only this craft uses it.

   Do not choose for them: an entity wrongly placed in `core` makes every other craft inherit a concept that is not theirs, and one wrongly placed in a craft cannot be cited by the core at all (the boundary rule). File name = entity name in the code = name in the glossary. Filling in the content is step ③ with the user; this skill only builds the skeleton.
10. If any entity file is still the untouched skeleton, or `specs/glossary.md` (root) and `specs/<craft>/glossary.md` are still templates, say so immediately: they are the input to the three roles at step ⑦ and a hard condition at gate ⑨. Writing them at step ③ is far cheaper than after step ⑦ — changing the model later means rewording the ACs.
11. **A UC under `specs/core/` may cite no craft's IDs** — a `RULE-###`/`ADR-###`/`UC-###`/`BR-###` living under `specs/<craft>/`, or an entity name in `specs/<craft>/entities/`. Core knows nothing of a craft. Say this to the user as soon as the chosen slice is `core`; `gate-check` and `design-check` call `layer-check` and will warn.
12. Do not write code. Do not commit (the first docs commit is made by `/sdd-solo:adversarial`).
