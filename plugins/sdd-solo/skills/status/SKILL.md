---
name: status
description: Where things stand — STATE.md, the UCs by status and gate, the trace ratio and AC coverage counted from git; plus the lookup of every decision in the project in time order. Use it when the user asks "where are we", "which UCs are left", "what share of commits carry an ID", "what has this project decided", "what rules do we have", "what is forbidden".
allowed-tools: Bash Read
---

Reply in whatever language the user writes in; keep file names, IDs and slugs in English.

Run it and interpret briefly (do not repeat it verbatim):
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/status.sh"
```
If there is a `=== Version ===` section, say so straight away: each mismatched line already carries the right command for **that particular link** — ③ `/sdd-solo:init --update`, ② `/plugin update`, ① `/plugin marketplace update`. Do not tell the user to run all three.

A `=== Dependencies ===` section at the end of the output means a **required** dependency is missing (only `git` and an initialised repo are required) — say briefly what is missing. When everything is there the script says nothing; do not bring it up.

Say: which UC and step we are on; which UCs are past the gate but not implemented (being coded); which draft UCs are left; the last two numbers and whether they are getting worse since the user last asked (if you know). Do not propose writing code.

---

When the user asks **what the project has decided** — "what rules do we have", "what is forbidden", "why did we choose that back then", "are there constraints left" — that is NOT `status.sh`. Run:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/decisions.sh"
```
It gathers CON · RULE · ADR · Forbidden · CHG · notes from six places onto one timeline. It always exits 0; it is not a gate. And the other direction — *"what decided this UC?"*, *"why is this feature like that?"* — is:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/context.sh" UC-### --why
```
which prints only the RULE · CON · ADR that the UC cites, plus architecture's `## Forbidden`. The two commands are two directions of the same question: `decisions.sh` goes from time down to decisions, `--why` goes from one UC upwards. Print the whole table for the user to read — this is a table for **human eyes** to compare against, do not summarise it into a few sentences.

The three trailing blocks, when present, must be said out loud rather than skipped:
- **Review overdue** — a constraint whose review date has come and nobody has looked. A constraint stops being
  true when *the world* changes, and when the world changes nothing in the repo moves; this is the only net.
- **No date** — cannot be placed on the timeline. Say plainly that this is the one thing in the document set that
  cannot be reconstructed: two decisions with no dates leave nobody able to tell which came first once they clash.
- **`br.md` is still the skeleton** — only the sample slice `specs/core/br-000/` exists, so the lines printed are a
  teaching example, not this project's decisions. Tell the user to run `/sdd-solo:intake` first; its step 0 is
  `specs/vision.md`, and while layer 0 is unwritten every BR is red in `br-check`.
