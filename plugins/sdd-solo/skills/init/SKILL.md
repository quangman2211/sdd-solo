---
name: init
description: Install the SDD-Solo process into the current repo (scaffold specs/ .sdd/ STATE.md, the CLAUDE.md block, git hooks), or update to a newer plugin version without overwriting files edited by hand. --update only refreshes .sdd/ and the templates; --plugin does the whole chain marketplace → installed plugin → .sdd/ in one command.
disable-model-invocation: true
argument-hint: "[--update] [--plugin]"
allowed-tools: Bash Read
---

Reply in whatever language the user writes in; keep file names, IDs and slugs in English.

Install or update sdd-solo in the current repo.

`$ARGUMENTS` contains `--plugin` → **mode B** (the whole chain). Otherwise → **mode A** (scaffold).

---

## A. `/sdd-solo:init` · `/sdd-solo:init --update`

1. Find the repo root: `git rev-parse --show-toplevel` (not a git repo → ask the user whether to
   `git init`; the hooks need git).
2. Run the scaffold — it only understands `--update`, do not pass it any other flag:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.sh" "${CLAUDE_PLUGIN_ROOT}" "$(git rev-parse --show-toplevel)" --update
```
   (drop `--update` on a first install). If `${CLAUDE_PLUGIN_ROOT}` is not substituted, find the plugin:
   `find ~/.claude/plugins -type f -name scaffold.sh -path '*sdd-solo*' | head -1`, then use the parent
   directory of `scripts/`.
3. Print the output verbatim (the ✓ / ! lines).
4. Check dependencies and print the output verbatim:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/deps-check.sh"
```
   Since 4.0.0 this list is nearly empty — the only requirements are `git` and a repo that has been
   `git init`ed. Spec Kit, AIUP and Camunda are all **optional** and the script says one line about them.
   A non-zero exit means something genuinely required is missing; read the ✗ line back to the user.
5. The output warns *"specs/ also holds Spec Kit's whole tree"* → tell the user to run
   `bash .sdd/scripts/migrate.sh --dry-run` first and then for real. **Do not run it yourself** — it moves files.
6. **The repo is still on the 6.x layout and already has content** (`specs/contexts/` · `specs/br.md` ·
   `specs/internal/` still there) → tell the user to move to the 7.0 tree. Three steps, in this order, and
   **do not run any of them yourself**:

   a. Write the map file `.sdd/migrate-v7.map` — three words per line, saying where each thing goes:
      `context <ctx> <craft>` · `uc UC-### BR-###` · `br BR-### <core|craft>` · `adr ADR-### <craft>` ·
      `rule RULE-### <craft>` · `entity <Name> <core|craft>` · `glossary <heading-first-word> <craft>`.
      Miss a context or a BR and the script prints every gap and **does not run** — deliberately: what belongs
      to the core and what belongs to a craft is the owner's decision, not something inferable from a path.
   b. `bash .sdd/scripts/migrate.sh --layout v7 --dry-run` — read the three tables it prints: moved · files
      whose paths were rewritten · **BY HAND**.
   c. Run it for real, then work the "BY HAND" table. The script **does not commit for you** and **does not
      touch the source brief** (its sha must stay the same).

   After migrating: `.sdd/config` has a new key `nghe_paths=<craft names separated by spaces>` (`core` is not
   listed) — check it matches the real `specs/<craft>/` folders. And `specs/vision.md` is generated from the
   skeleton and **still empty**: tell the user to run `/sdd-solo:intake` to write layer 0 into it, because
   `br-check` requires every BR to declare a `**Slice:**` matching that file's `## Crafts and slices` table.

   A 6.x repo that has **not** migrated still runs exactly as before — every script looks in both layouts.
   Do not push the user to convert.
7. `specs/core/br-000/br.md` is still the template (it contains the string `<Business requirement name>`), or
   `specs/vision.md` is still the skeleton → say the next step is **`/sdd-solo:intake`**; its step 0 is layer 0.
   Do not propose writing code, do not propose outside tools.
8. Any `.new` file in the output → list them and tell the user to merge them by hand; never overwrite.

---

## B. `/sdd-solo:init --plugin`

Use it when the SessionStart hook or `/sdd-solo:status` reports a version mismatch. Run:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/update.sh"
```
(if the variable is not substituted: `find ~/.claude/plugins -type f -name update.sh -path '*sdd-solo*' | head -1`).

Print the output verbatim. The script skips whichever link is already correct, so do not re-run the sub-commands.

Then:
- In the `=== After the update ===` section, if *"this session is still running"* is lower than *"installed"* →
  **tell the user to open a new session**. A new version does not apply to an already open session, exactly like
  Claude Code updating itself. Do not promise it has taken effect.
- Any `.new` file in part ③ → list them, tell the user to merge. Never overwrite.
- On a **major** upgrade the scaffold cannot move existing files: read that version's CHANGELOG. For 4.0.0, tell
  the user to run `bash .sdd/scripts/migrate.sh --dry-run`; for **7.0.0** it is the new `specs/` tree — follow
  step 6 of mode A (map → `--layout v7 --dry-run` → for real → the BY HAND table).
- The script edits no spec and commits nothing. Changes under `.sdd/` and in the templates are the user's to
  commit — mention `chore(sdd): update sdd-solo <ver>`.
