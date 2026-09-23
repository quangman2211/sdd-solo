# specs/ — the business source of truth

## Where to start

Only the sample `core/br-000/` is here → **`/sdd-solo:intake`**. Its step 0 is `vision.md` — the owner
says the direction in plain words and intake transcribes it; then seven questions write the first BR into
the right craft.
Already holding a brief from another agent? `/sdd-solo:intake path/to/brief.md`.
Prefer to write it yourself: read the sample `BR-000` in `core/br-000/br.md`; `_intake.md` is those seven
questions on paper.

A BR comes before a UC: `/sdd-solo:start UC-###`. The other way round is building on unwritten ground —
`/sdd-solo:status` will say so in red.

## Three levels of place (7.0)
```
specs/
  vision.md · glossary.md · rules.md · architecture.md · decisions.md · adr/   ← ROOT: across the whole project
  changes/ · traceability.md
  core/                                                                       ← CORE: shared, a sibling of a craft
    entities/<Name>.md           one file per entity
    br-###/                      one slice of the core
      br.md · evidence.md · use-cases/UC-###-slug/{UC-###.md, UC-###.flow.md, screens/, design.md, tasks.md}
  <craft>/                                                                    ← CRAFT: one craft open at a time
    glossary.md · rules.md · adr/ · entities/<Name>.md    craft-only
    br-###/ …                                             one BR per slice
```
Boundary rule: the root and `core/` **cite no craft's IDs**; a craft cites the root and `core` freely.
`src/core` does not import `src/<craft>`. `layer-check.sh` checks it; the githook
`pre-commit.d/20-layer-boundary` blocks it. "Context" is no longer a folder unit (T3, 2026-09-18); old
context names survive only in the glossary if they are still useful.

## Boundaries
- **direction** = where we are going, what must not shrink, which craft opens when. → `vision.md` (layer 0, written by the owner, exempt from the "no numbers" rule)
- **spec** = how the system must behave. The customer can feel it. Changes when the business changes. → `core/` · `<craft>/`
- **architecture and decisions** = how it is built, and why. → root `architecture.md` · `adr/` · `decisions.md`
- **change** = a proposed change to behaviour already shipped. → `changes/` (Phase 5)
- **state** = how far along we are. → `STATE.md` (repo root, not inside specs/)
- **process trace** = questions between agents, review minutes, maps. → `notes/{hoi-dap,soat,ban-do}/` (outside specs/)
- **evidence trail** = scratch paper already used: `UC-###.trace.md` (adversarial · re-read · history once the UC closes)
  and the slice's `evidence.md` (the body of `## Background`). Open them when something is disputed; they are not
  everyday reading, and `context.sh` and `decisions.sh` do not read them.

One question, one place that answers it. Everywhere else cites the ID and copies nothing.

The skeletons for UC/craft/slice/entity/change live in the plugin (`templates/skel/`); a skill copies one
when it is needed — they never land in the project. Phase 0 (Design System) and Phase 4 (feedback) have
**no command yet**; open an issue if you need one.

## The ID system
| Family | Answers | File |
|---|---|---|
| — | Where we are going, what must not shrink | `specs/vision.md` |
| BR-### | Why this slice is being built | `specs/<core\|craft>/br-###/br.md` — one sequence for the whole project |
| UC-### | Who does what | `specs/<core\|craft>/br-###/use-cases/UC-###-slug/UC-###.md` |
| UC-###/AC-# | How we know it is right | inside the UC file |
| RULE-### | A constraint crossing several UCs | `specs/rules.md` (project-wide) · `specs/<craft>/rules.md` (craft-only) — one sequence |
| CON-### | A technical / legal / timing constraint | in the BR's Constraints section |
| ENT | A concept, its relations and states | `specs/core/entities/<Name>.md` · `specs/<craft>/entities/<Name>.md` |
| SCR-###-# | A screen / screen state of UC-### | `.../UC-###-slug/screens/` |
| ADR-### | Why it is built this way | `specs/adr/ADR-###-slug.md` · `specs/<craft>/adr/` — one sequence |
| CHG-### | A change against the baseline | `specs/changes/CHG-###-slug/` |

## What this project has already decided

```bash
.sdd/scripts/decisions.sh
```

One screen, **every decision in the project in time order** — gathered from the CONs of every BR, the root
and craft RULEs, the root and craft ADRs, the `## Forbidden` section of `architecture.md`, and
`decisions.md`. Generated at read time, not a file to commit: a copy drifts from its sources, and drifting
is exactly the "green when it should be red" trap this whole check set exists to prevent.

Time order is deliberate. Two decisions written months apart both read fine on their own; sitting next to
each other on one timeline, the later one being stricter than the earlier one becomes obvious. No mechanical
check catches that, and a human eye catches it instantly.

`--md` exports a markdown table when you need to paste it somewhere.

The other direction — *what decided this feature?*:

```bash
.sdd/scripts/context.sh UC-### --why
```

prints only the RULE · CON · ADR that the UC cites, plus `## Forbidden`. Without `--why` it prints the UC's
**whole effective context** — that is what an agent reads before designing or writing code, in place of 15
files spread over six folders.

## How to read this repo (for a new person and for a new AI session)
1. `STATE.md` — which step we are standing on.
2. `specs/vision.md` — where we are going, which craft is open.
3. `.sdd/scripts/decisions.sh` — what the project has decided, in time order.
4. `.sdd/scripts/context.sh UC-###` — the whole effective context of the current UC, in one command.
5. `specs/architecture.md` — stack, boundaries, prohibitions (already inside 4; read on its own when editing it).

## UC status
`draft` → `reviewed` (past the DoR gate) → `implemented` (past DoD) → `deprecated`
