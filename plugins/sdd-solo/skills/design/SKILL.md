---
name: design
description: Step ⑩ — the technical design for a UC that has passed the DoR gate. Produces design.md + tasks.md in the UC folder, checked back against specs/vision.md, specs/architecture.md and the source brief. Use it after /sdd-solo:gate and BEFORE the first line of code.
disable-model-invocation: true
argument-hint: "UC-###"
allowed-tools: Bash Read Write Edit Grep Glob AskUserQuestion
---

Reply in whatever language the user writes in; keep file names, IDs and slugs in English.

The design for `$1`.

**Ticket mode (7.3) — when running under another agent's brief** (the brief opens with `Vai:`/`Lượt`, or
`bash .sdd/scripts/role.sh --xem` reports a role other than the coordinator, or you are not sure there is a human at
the other end): **do not open `AskUserQuestion`** — nobody clicks it and the turn hangs until it times out (#53).
Every question you would have asked becomes a ticket: `bash .sdd/scripts/phieu.sh new "<task>" <role>` with
Question · Already looked up · If chosen wrong · The agent leans towards; leave whatever depends on it as `___` plus
an interim decision; then **STOP**, ending with `role.sh --ketqua <key> ket=chan hoi=#<n>`. When the owner types this
command themselves in their own session, ask as normal.

**Why this step belongs to sdd-solo instead of being outsourced:** the five requirement layers (Direction · BR · UC ·
Entity · AC) answer *where we are going · why this slice · who does what · which concepts · how we know it is right*.
**No layer answers *built with what · runs where · called by whom*.** Before 4.0.0 that question fell to an outside
tool, and that tool read exactly two things: a thin file containing only IDs, and a `constitution.md` that in a real
repo was still all placeholders. **The brief was not among those inputs and never had been** — so the design
contradicted the brief for two days without anyone seeing it, because every document was internally consistent (#34).

---

## 1. The entry gate

```bash
ls "$(git rev-parse --show-toplevel)/.sdd/gate/$1.ok"
```

Missing → **stop**. Tell the user to run `/sdd-solo:gate $1` first. Designing for a UC that has not passed the gate is
designing for a spec that is still moving. **Generate no files** on this turn.

## 2. Reading — ONE command, then the brief

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/context.sh" $1
```
(if the variable is not substituted: `find ~/.claude/plugins -type f -name context.sh -path '*sdd-solo*' | head -1`)

It prints exactly enough: the UC (with the three evidence-trail sections stripped) · the flow · **only the**
`RULE`/`CON`/`ADR` the UC cites · the parent BR's sections without Background · the four `architecture.md` sections ·
the entities and glossary the UC names. Up to 4.2.0 this spot was an instruction to read **13 file names**,
unverifiable, and it failed at #34 — a design contradicting the brief for two days with nobody seeing it. Measured at
runxops: UC-009 210 KB / 15 files → one command of ≤ 30 KB; UC-014 cites 5 RULEs + 9 ADRs → 222 KB after the evidence
trail is cut (#43) — the per-source size lines at the end of the output point at whichever source is bloating, read
that first.

Then read **the source brief** — the last output line carries `brief_path` and its sha. It is the only source outside
`specs/` that no other check is allowed to look at; `context.sh` deliberately does not print it.

And read **`specs/vision.md`** — two sections, not the whole file: this UC's slice row in the `## Crafts and slices`
table (which craft, which slice, open or waiting) and `## Do not narrow`. The design is where a "do not narrow" item
dies most quietly: nobody removes it from the spec, the design simply takes a route that cannot carry it, and six
months later reopening it costs as much as rewriting. A UC in a slice that is still **waiting** (not open) → say so to
the user before designing.

The output carries `! architecture.md … still has placeholders` or `! specs/architecture.md is missing` →
**stop and do that first**, with the user. A `design.md` checked against an empty constitution is an empty check, and
an empty test looks exactly like a passing one. A line `! RULE-### — the UC cites it but rules.md does not have it` is
also a stop: that is designing on a rule that does not exist.

## 3. Write `design.md`

Copy `${CLAUDE_PLUGIN_ROOT}/templates/skel/use-case/UC-000.design.md` to `<UC folder>/design.md`, replace `UC-000` with
`$1`, then fill it in with the user. Six sections, and the two in the middle are the reason this whole step exists:

- `## Summary` · `## Technical context` (language · dependencies · storage · test · runtime platform)
- **`## Checked against architecture.md`** — a six-row table. Every **departure** from the constitution belongs here
  with a reason and a real `ADR-###`. No departures still has to be written down as no departures.
- **`## Checked against brief`** — what the brief asks for that this design does **not** do, and why. No brief → write
  *"the project has no source brief"*. **Record the `vision.md` check in the same section:** one line per item in
  `## Do not narrow` — how this design carries it, or that it does not yet and how it gets reopened. An item that
  cannot be carried → **stop and ask the owner**; do not write a line that sounds as if it had been weighed.
- `## Code structure` (real paths) — **and the signature of every port / use-case function** (name · parameters ·
  return type · errors thrown), not just file names (#39). Role T writes the harness and the fakes **from this
  section** before D has any code; a design that only names files forces T to guess signatures → `HỎI-T1` at runxops
  on the very first round. It pays off solo too: a signature written first is what the red test attaches to.
- `## Risks and complexity`

**Hitting a technical decision that neither the UC nor `architecture.md` states** (choosing a library, a storage kind,
a protocol) → **STOP and ask the user** with `AskUserQuestion`, the same rule as for a business decision. Do not pick a
default and write it into the file as if it had been discussed.

A decision that **changes the constitution** rather than applying it → write it into `specs/architecture.md` (root,
project-wide), do not hide it in one UC's `design.md`. A project-level decision inside one UC's folder is a place the
second UC will never find. Its ADR goes with it: `specs/adr/` if it binds the whole project, `specs/<craft>/adr/` if
only that craft — one `ADR-###` sequence for the whole project.

**A UC in `core` may cite no craft's IDs** — no `RULE-###`/`ADR-###`/`UC-###`/`BR-###` living under `specs/<craft>/`,
no entity name in `specs/<craft>/entities/`. In `## Code structure`, `src/core` **does not import** `src/<craft>/`.
`design-check` calls `layer-check --file` and **warns** where this is violated; a warning here means read it again,
not ignore it — the core citing a craft is where the second craft finds it can no longer reuse the core.

## 4. Write `tasks.md`

Copy `${CLAUDE_PLUGIN_ROOT}/templates/skel/use-case/UC-000.tasks.md` to `<UC folder>/tasks.md`. **One row, one task and
one test file per AC**, `tests/use-cases/<core|craft>/$1/AC-#.test.*` — `<core|craft>` is the craft of the slice holding
the UC. Do not copy the AC text across — a copy is a second copy to drift. Tasks tied to no AC (scaffolding,
configuration) go in their own section at the end.

## 5. Check it mechanically and print the output verbatim

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/design-check.sh" $1
```
(if `${CLAUDE_PLUGIN_ROOT}` is not substituted: `find ~/.claude/plugins -type f -name design-check.sh -path '*sdd-solo*' | head -1`)

Red → fix and run again. Do not write code while a single ✗ line remains.

## 6. Its own commit

```bash
git add <UC folder>/design.md <UC folder>/tasks.md && git commit --only -m "docs($1): design — design.md + tasks.md" -- <UC folder>/design.md <UC folder>/tasks.md
```

## 7. Tell the user

Next is step ⑪ **writing the code against `tasks.md`**, red test first. Point out the three usual mistakes when reading
`design.md`: is the RULE checked **before** the record is created · does the RULE's logic sit in the domain or has it
slipped into an adapter · do the state transitions follow the state diagram in the entity file
(`specs/<core|craft>/entities/<Name>.md`).

---

## Limits — tell the user, do not hide them

1. **`design-check` measures PRESENCE, not CORRECTNESS.** It knows the `## Checked against architecture.md` section has
   content; it does **not** know whether that content is really the result of a check. The only thing that catches that
   is the user reading it. Do not say "checked" when you mean "the script is green".
2. **Write no code in this step.** Not even a small function to "see if it runs".
3. **Do not edit the spec yourself.** The design exposes something wrong in the UC → say so and let the user decide;
   editing a UC that has passed the gate is a job for re-running `/sdd-solo:gate`, or for Phase 5 if the UC is already
   `implemented`.
