---
name: adversarial
description: A three-role adversarial pass that reads the spec and lists the questions it does not answer. UC-### (step ⑦) uses the roles end customer / operations / abuser and asks about behaviour; BR-### (Phase 1) uses the one who pays / the one who operates it forever / the sceptic and asks about the reason for existing. It replaces the business reviewer when you work alone.
disable-model-invocation: true
argument-hint: "UC-### | BR-### [--phieu | --hoi]"
allowed-tools: Bash Read Write Edit Grep Agent AskUserQuestion
---

Reply in whatever language the user writes in; keep file names, IDs and slugs in English.

An adversarial pass for `$1`.

`$1` starting with `UC-` → **part A**. Starting with `BR-` → **part B**. Anything else → stop and ask again.

**Two modes for putting the questions — choose BEFORE running the three roles** (7.0.1, #53):

| Mode | When | Where a shape question goes |
|---|---|---|
| **ask** | the user typed the command in their own session, no flag · or `--hoi` is given | `AskUserQuestion`, one question per turn (step 5) |
| **ticket** | `--phieu` is given · or the round runs under **another agent's brief** (orchestrate: role B/C, a brief starting with `Vai:` / `Lượt`) without `--hoi` | one ticket collecting K1…Kn in the question log (step 5′), **never** `AskUserQuestion` |

Not sure which mode you are in → **ticket**. A ticket costs one extra round; a question opened in a session with
nobody in it hangs the whole round until it times out — the real runxops case (#53): adversarial ran under A's brief,
opened `AskUserQuestion`, nobody clicked, `## Adversarial pass` was never written, and A had to hand the work out
again. `--hoi` is there so A can force asking while A is sitting with the owner. Both modes use the same three roles,
the same shape/value test and the same four constraints on proposals — they differ in exactly one thing: who answers
a shape question, and when.

The question log: `notes/hoi-dap/hoi-dap.md` (the 7.0 tree) · `specs/internal/hoi-dap.md` (6.x). Missing → copy the
skeleton `${CLAUDE_PLUGIN_ROOT}/templates/skel/hoi-dap.md` (if the variable is not substituted:
`find ~/.claude/plugins -type f -name hoi-dap.md -path '*sdd-solo*skel*' | head -1`).

**The 6.x layout** (no `migrate --layout v7` yet): the BRs are in `specs/br.md` (sections `# BR-###`), the RULEs in
`specs/rules.md`, the entities in `specs/contexts/<ctx>/entities.md`, and there is no `specs/vision.md` → drop the
"Do not narrow" part, and say that you dropped it. `context.sh`, `gate-check.sh` and `br-check.sh` look in both trees.

---

## The two layers — read exactly one, now

The rest of this pass is in a file beside this one, one per layer. Read it **before** doing anything else; it is not
background, it is the whole of the run.

| `$1` | Read | It contains |
|---|---|---|
| `UC-###` | `references/uc-layer.md` | step ⑦: end customer · operations/accounting · abuser, the shape/value test, the four constraints on a proposal, both question modes, the commit |
| `BR-###` | `references/br-layer.md` | Phase 1: the one who pays · the one who operates it forever · the sceptic, what they ask of the reason for existing, the commit |

Full path: `${CLAUDE_PLUGIN_ROOT}/skills/adversarial/references/<file>`. If the variable is not substituted:
`find ~/.claude/plugins -type f -name <file> -path '*sdd-solo*adversarial*' | head -1`.

**Read one, not both.** The two layers ask about different things — behaviour versus the reason for existing — and
running the UC roles on a BR (or the reverse) produces a pass that looks complete and asks about the wrong thing.
A split run has nothing to gain from the other file: nothing above this line depends on it.
