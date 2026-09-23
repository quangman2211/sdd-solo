---
name: deprecate
description: Retire a UC properly (rewritten, or no longer being built) — Status deprecated, History v+1 with the reason and the replacement UC, the gate marker .sdd/gate/UC-###.ok removed, one line in specs/decisions.md, the Related Use Cases table in the slice's br.md, one commit. Use it when the user says "drop this UC", "rewrite it as another UC", "deprecated".
disable-model-invocation: true
argument-hint: "UC-### [--by UC-###] [reason]"
allowed-tools: Bash Read Edit AskUserQuestion
---

Reply in whatever language the user writes in; keep file names, IDs and slugs in English.

Retire `$1`.

**Ticket mode (7.3) — when running under another agent's brief** (the brief opens with `Vai:`/`Lượt`, or
`bash .sdd/scripts/role.sh --xem` reports a role other than the coordinator, or you are not sure there is a human at
the other end): **do not open `AskUserQuestion`** — nobody clicks it and the turn hangs until it times out (#53).
Every question you would have asked becomes a ticket: `bash .sdd/scripts/phieu.sh new "<task>" <role>` with
Question · Already looked up · If chosen wrong · The agent leans towards; leave whatever depends on it as `___` plus
an interim decision; then **STOP**, ending with `role.sh --ketqua <key> ket=chan hoi=#<n>`. When the owner types this
command themselves in their own session, ask as normal.

**Why this command exists (#45):** at runxops the owner chose to rewrite UC-009 and UC-012 — setting
`Status: deprecated` by hand, while `.sdd/gate/UC-009.ok` and `UC-012.ok` were still there (so the githook still
allowed `feat(UC-009)` commits), `status.sh` said nothing, History and `decisions.md` were written by hand and
forgotten, and STATE carried the debt for days. Four separate jobs means one of them is always missed.

1. Find the UC: `find specs -path "*/br-*/use-cases/$1-*/$1.md"`. Not there → stop and say so.
   Status is already `deprecated` and the marker is gone → say "already retired" and stop.
2. **The reason and the replacement UC** — the two things History must record. Take them from `$ARGUMENTS`
   (`--by UC-###` and the remaining text). No reason → ask **in words**, one question: *"why is it being dropped —
   rewritten, merged into another UC, or not being built?"*. No replacement → ask with `AskUserQuestion`: one option
   per `draft` UC in the `## Related Use Cases` table of every `specs/*/br-*/br.md`, plus *"a new UC not opened yet —
   write the intended ID"* and *"no replacement UC"*. Do not choose for them.
3. If the UC is already `implemented` and there is code tagged `($1)`: say plainly that **the code is not touched** —
   retiring a UC only retires the *effective spec*; removing code is a CHG (Phase 5) or the replacement UC's job. Do
   not delete the UC file, do not delete the folder.
4. Run:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/pass.sh" deprecate $1 --by <UC-### | ->  "<reason>"
```
(if the variable is not substituted: `find ~/.claude/plugins -type f -name pass.sh -path '*sdd-solo*' | head -1`.)
   The script does exactly five things in one commit `docs($1): deprecated — <reason>`:
   - `**Status:** deprecated` + today's `Last updated` in the UC file;
   - `## History` v+1: `deprecated — <reason> · replaced by <UC-###>`;
   - removes `.sdd/gate/$1.ok` (from then on the githook blocks `feat($1)`: a retired UC gets no more code commits in its name);
   - the Status column in the `## Related Use Cases` table of that slice's `br.md` → `deprecated`;
   - one line in `specs/decisions.md` (root): `- <date> — Retire $1 (<reason>). Rejected: keep $1. Detail: <replacement UC>`.
   Print the output verbatim.
5. If the slice's `## Related Use Cases` table still points at `$1` on another row (or another slice points at it) →
   tell the user and suggest editing it by hand (to the replacement UC); do not edit the BR yourself. When the
   replacement UC belongs to **another slice**, say clearly which `specs/<core|craft>/br-###/use-cases/` it will be
   created in — `/sdd-solo:start` asks for the slice, it does not infer it from the old UC.
6. STATE.md: `Working on: <replacement UC> · step ① — inherited from $1`; `Next: /sdd-solo:start <replacement UC>`
   (if it is not open yet). Mention `/sdd-solo:state`.

Since 6.4.0 `/sdd-solo:status` warns *"gate marker on a deprecated UC"* and *"deprecated UC still in STATE"* — so
even when somebody retires a UC by hand instead of using this command, something still says so.

Do not write code. Do not delete files. Do not touch the replacement UC.
