---
name: gate
description: Step ⑨ — the Definition of Ready gate for one UC, checked mechanically (AC vs E#, Screens, RULEs exist, the mermaid flow matched against E# both ways, the adversarial pass, and the re-read by an unprimed head — `/sdd-solo:verify` is required and its commit must be the newest spec commit; 6.0.0 removed the overnight door). Red means no design and no code; green sets status reviewed, writes the marker .sdd/gate/UC-###.ok and commits.
disable-model-invocation: true
argument-hint: "UC-###"
allowed-tools: Bash Read
---

Reply in whatever language the user writes in; keep file names, IDs and slugs in English.

The DoR gate for `$1`.

**Never delegated to an agent:** `gate` is the owner's job (orchestrate §2 rule 7). Running under another agent's brief → only run `gate-check` and report; do not run `pass.sh gate`.

1. Run it and print the output verbatim:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/gate-check.sh" $1
```
(if `${CLAUDE_PLUGIN_ROOT}` is not substituted: `find ~/.claude/plugins -type f -name gate-check.sh -path '*sdd-solo*' | head -1`).
2. Exit ≠ 0 → **THE GATE IS CLOSED**. For each ✗ line, tell the user what to fix and in which file. Do not edit the spec for them (unless they ask). Do not run `/sdd-solo:design`, do not write code. Stop here.
3. Exit 0 → run:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/pass.sh" gate $1
```
The script sets `Status: reviewed`, writes `.sdd/gate/$1.ok`, and commits `docs($1): spec reviewed — DoR gate passed`.
4. STATE.md: `Working on: $1 · step ⑨ done — ready for /sdd-solo:design`. `Next: /sdd-solo:design $1, read design.md before the first line of code`.
5. Remind the user of three things to look for while reading `design.md`: is the RULE checked before the record is created; does the RULE's logic sit in the domain or in an adapter; do the state transitions follow the state diagram.

There is no skip flag. Getting past the gate means making the spec sufficient.
