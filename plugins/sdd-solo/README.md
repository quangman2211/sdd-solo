# sdd-solo — Spec-Driven Development for one developer + an AI

A Claude Code plugin packaging the SDD-Solo process: it keeps the four requirement layers of Spec-Driven Development (BR → Use Case → Entity → Acceptance Criteria), adds a standard diagram at every layer (flow and state in Mermaid, DMN, UML, an Impact Map, a Story Map), makes Claude Design an official step, and replaces every mechanism that needs a second person with one a single person can run: a three-role adversarial pass, a Definition of Ready gate before any code, a two-level design layer, `STATE.md` instead of a standup, git hooks instead of a reviewer.

Background: the ebook *Spec Driven Development* (Nguyễn Thế Huy) · AI Unified Process · GitHub Spec Kit · OpenSpec — read them to learn the **shape of the artifacts**; since 4.0.0 the plugin depends on none of their commands.

## Install

```
/plugin marketplace add quangman2211/sdd-solo
/plugin install sdd-solo@sdd-solo
```

Then, in the project repo: `/sdd-solo:init`. The mandatory dependencies are `git`, `bash` and `node` (>= 18) — no other plugin is needed.

Then **`/sdd-solo:intake`** — it asks seven questions (what hurts · who hurts · what it costs · what happens if nothing is done · is there a way not to build software · what is deliberately left out · what measures it) and writes `specs/br.md` for you. Already holding a brief written by another AI: `/sdd-solo:intake brief.md`.

Optional, and **none of these is part of the 14 steps** (since 4.0.0):
- **Claude Design** — needed for Phase 0 and step ⑤ (the Design System, the SCR screens). It is the optional piece most worth installing.
- **GitHub Spec Kit** — a good design reference, updated often; install it and read it. Only one rule: it writes into `.speckit/`, not into `specs/`. See [Why Spec Kit left the chain](#why-spec-kit-left-the-chain).
- **AIUP** · **Camunda Modeler** — not needed. AIUP writes into a `docs/` tree and collides with the ID system; the flow diagrams are drawn in Mermaid, so no app is required.

## Use

In the project repo:

| When | Command |
|---|---|
| First time / after updating the plugin | `/sdd-solo:init` · `/sdd-solo:init --update` |
| Opening a session | the hook reads `STATE.md` and says which step you are at |
| **Starting a project — nothing written yet** | `/sdd-solo:intake` (a 7-question interview) or `/sdd-solo:intake brief.md` (converting another agent's brief) |
| The BR is written | `/sdd-solo:adversarial BR-###` — the three roles: whoever pays / whoever runs it forever / the sceptic |
| Starting a use case | `/sdd-solo:start UC-### [ctx] [slug]`, then write the UC content with the AI |
| After writing the RULEs, the ACs, drawing the flow and the screens | `/sdd-solo:adversarial UC-###` → `/sdd-solo:verify UC-###` |
| The re-read is done | `/sdd-solo:gate UC-###` → green means `/sdd-solo:design UC-###` → write the code from `tasks.md` |
| The code is done | `/sdd-solo:close UC-###` |
| End of the session | `/sdd-solo:state` |
| Where things stand · am I running an old version | `/sdd-solo:status` |
| There is a new version | `/sdd-solo:init --plugin` — runs all three slots, then open a new session |

Four questions to remember: **Written? Drawn? Reviewed? Through the gate?**

## What lives where

Since 2.0.0 the project repo holds only **two process directories** (+ `notes/` for the process trail since 7.0):

```
.sdd/     the machinery — config, gate/, scripts/, hooks/, checklists/, prompts/
specs/    all the content — three levels of place (7.0):
  vision.md · glossary.md · rules.md · architecture.md · decisions.md · adr/ · changes/   ← the root: project-wide
  core/{entities/<Name>.md, br-###/{br.md, evidence.md, use-cases/UC-###-slug/}}        ← the core, a peer of a craft
  <craft>/{glossary.md, rules.md, adr/, entities/, br-###/…}                             ← one directory per craft
notes/    hoi-dap/ · soat/ · ban-do/ — the process trail between agents, outside specs/
STATE.md  CLAUDE.md  <code>/  <tests>/use-cases/<core|craft>/UC-###/
```

Layer 0, `specs/vision.md` (7.0): the owner writes it in plain words — the positioning · **what must not be narrowed** ·
the crafts and slices table · what "done" means per craft. Every BR is **one slice** of one craft
(`specs/<craft>/br-###/`) and claims it with `**Slice:**`; `br-check` goes red when Out of Scope narrows something
vision.md forbids narrowing. The core does not know a craft, a craft knows the core — `layer-check.sh` checks it and
the `pre-commit.d/20-layer-boundary` githook blocks it once enabled. A 6.x repo (`specs/contexts/`, one merged
`specs/br.md`) moves with `migrate.sh --layout v7` and a `.sdd/migrate-v7.map` file; the scripts still read both layouts.

- **`.sdd/`** holds the machinery, including **a copy of the checking scripts** — so `bash .sdd/scripts/gate-check.sh UC-###` runs in CI and on the machine of whoever clones the repo, with no plugin installed. If that copy drifts from the plugin version, the hook and `status` warn.
- **`specs/`** holds everything that describes the system. The spec↔doc boundary does not disappear, it drops one level: what the customer can feel → `core/` · `<craft>/`, what only the builder cares about → `architecture.md` · `adr/` · `decisions.md` at the root. Work in progress → `changes/`. The process trail (questions, reviews) → `notes/`, outside specs/.
- The artifacts of a UC live **entirely inside the UC directory**: `UC-###.md` · `UC-###.flow.md` · `screens/` · and since 4.0.0 `design.md` + `tasks.md` (step ⑩).
- The technical design has **two levels**: `specs/architecture.md` for the whole project (the stack · where it runs · who calls it · the boundaries · what is forbidden), and each UC's `design.md` checked back against it.
- The plugin never overwrites a file you edited — `init --update` puts the new version next to it as `.new`.

## Why Spec Kit left the chain

Up to 3.x, step ⑩ of the 14-step round was `/speckit-plan`. Since **4.0.0** it is `/sdd-solo:design`. The change came
from three measurements, not from a preference:

**① Two systems fighting over one directory.** `speckit-specify/SKILL.md:84,88,91,93` tells the agent **in prose**:
the specs live under `specs/`, the next number comes from *"scanning existing directories in `specs/`"*, then
`mkdir -p specs/<NNN>-<slug>`. At `runxops`: `specs/001-assign-product-key/` sat next to `specs/contexts/`.
Two ID systems (`001-` and `UC-###`), one directory, neither side aware of the other — and their numbering scan
was counting our own `br.md`, `contexts/` and `changes/`.

**② The step that decides the architecture ran on two empty inputs.** `speckit-plan` reads exactly two things:
`FEATURE_SPEC` and `.specify/memory/constitution.md`. `FEATURE_SPEC` is the thin file sdd-solo generates, holding
**only IDs**. And in a real repo `constitution.md` was still the `[PROJECT_NAME]` placeholder. **The brief is not
among those two inputs and never was** — so the design contradicted the brief for two days with nobody seeing it,
because each document was internally consistent.

**③ "Spec Kit" is not one thing.** Four repos on one machine: 10 · 24 · 25 · 35 `speckit-*` commands.
Putting someone else's command name into a **hard rule** means the rule breaks on their release schedule.

So: the hard rules of sdd-solo now talk about **repo state** (is there a `.sdd/gate/UC-###.ok`, is there a
`design.md`) and name no command at all. Spec Kit is still worth installing and reading — it only has to write into
`.speckit/`. A repo mixing the two trees is separated by `bash .sdd/scripts/migrate.sh --dry-run`, keeping the git history.

## Where your repo keeps its code

`.sdd/config` — generated once at `init` by probing the repo, and `init --update` **never overwrites it**:

```
code_paths=src app lib
test_paths=tests
uc_test_dir=tests/use-cases
```

The githooks and every checking script read this file. Before 1.5.0 those two paths were hard-coded as `src`/`tests`, so a repo with its code in `app/` had the hook **wave through every code commit with no ID without a word** — a hard block turned into no block at all. Now a commit holding source files while no directory in `code_paths` exists is **blocked**, pointing at `.sdd/config`; `/sdd-solo:status` checks it again too.

## Upgrading 1.x → 2.0.0

**The order is mandatory: migrate FIRST, `init --update` AFTER.** The other way round, `init` builds the destination tree out of empty templates, the migration finds the destination already there and skips it, and the real content stays stuck in the old place. Since 2.0.1 both commands refuse to run in the wrong order.

```bash
/plugin marketplace update sdd-solo && /plugin update sdd-solo   # get 2.0.x
bash <plugin>/scripts/migrate.sh --dry-run                       # preview
bash <plugin>/scripts/migrate.sh                                 # git mv, keeping the history
/sdd-solo:init --update                                          # only then this step
git add -A && git commit -m "chore(sdd): migrate to the 2.0.0 layout"
```

The script stops at the very start if the working tree is dirty or if the old and the new tree both exist — in both cases it has touched no file.

## Which version am I running

Four places hold a version, and each mismatch has a different fix:

```
GitHub ─①─▶ the downloaded marketplace ─②─▶ the installed version ─③─▶ the project .sdd/
                                                └───④─▶ the open Claude Code session
```

| Slot | Command |
|---|---|
| ③ `.sdd/` older than the installed version | `/sdd-solo:init --update` |
| ② the installed version older than the downloaded one | `/plugin update sdd-solo` |
| ① GitHub has a newer version | `/plugin marketplace update sdd-solo` |
| ④ the open session still runs an old version | **no command can fix it** — open a new session |

Slot ④ is the dangerous one: you have just run `/plugin update`, `.sdd/` is new, everything on disk is right, and the open session still runs the code it loaded when it opened — typing `/sdd-solo:gate` gets the old logic. Only the SessionStart hook can know which version a session loaded, so it records it for `version-check` to read.

`/sdd-solo:status` checks all three (asking GitHub for at most 3 seconds, remembering for 24 hours) and only speaks when something is out of step. `/sdd-solo:init --plugin` runs exactly the slots that are out of step, in one command — but **a new version only takes effect in the next session**, exactly like Claude Code updating itself. The session-open hook warns too, but **it only compares locally and makes no network call** — so slot ① only shows up when you run `status`.

## How hard the blocks are — honestly

- **Hard blocks**: the `commit-msg` githook refuses a code commit with no ID or for a UC that has not passed the gate; `pre-commit` refuses to mix spec and code. There is no skip flag.
- **Soft blocks**: no external tool's command is named anywhere any more (since 4.0.0). The `CLAUDE.md` block and the SessionStart hook teach the session to refuse to **write code** while there is no `.sdd/gate/UC-###.ok` marker or no `design.md`; an AI obeys, a human can override.

## Documentation

- `plugins/sdd-solo/docs/playbook-example-khoskill.html` — the full playbook with one worked example throughout (the licence flow of a sample project). Written in Vietnamese.
- `plugins/sdd-solo/skills/sdd-process/SKILL.md` — the background knowledge, and also what the AI reads while working in a repo.

## Layout

```
sdd-solo/
├── .claude-plugin/marketplace.json
└── plugins/sdd-solo/
    ├── .claude-plugin/plugin.json
    ├── skills/  sdd-process · init · intake · start · adversarial · verify · gate · design · change · close · deprecate · orchestrate · role · phieu · queue · state · status
    ├── hooks/hooks.json            SessionStart → scripts/session-start.sh
    ├── scripts/                    scaffold · br-check · gate-check · design-check · change-check · close-check · pass · status · metrics · migrate · role · phieu · queue · js/
    ├── templates/
    │   ├── project/                specs/ notes/ .sdd/ STATE.md
    │   ├── CLAUDE.md.tmpl          the rules block, spliced into the repo CLAUDE.md
    │   └── githooks/               commit-msg · pre-commit
    └── docs/
```

## Language

The plugin itself is English: the skills, the printed messages, the comments and the templates. The documentation
keywords are bilingual (`scripts/kw.tsv`) — a gate reads a spec written in either English or Vietnamese and returns
the same verdict, and a new project writes English because `scaffold` sets `doc_lang=en` in a new `.sdd/config`.
A project already writing in Vietnamese changes nothing: `doc_lang` defaults to `vi` and the git history stays readable.
The skills reply in whatever language you type in.

MIT.
