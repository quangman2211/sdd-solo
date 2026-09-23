---
name: numbers
description: Gather every blank the owner still owes a number for — all of them at once, grouped, each naming the UCs it blocks. The "never invent a figure" rule leaves `___` wherever a number is not known; met one at a time in the middle of a gate run, the cheapest way past each one is to make it up. This is the list that lets the owner decide them in one sitting instead. Read-only, never a gate.
disable-model-invocation: true
argument-hint: "[UC-###] [--rules-only]"
allowed-tools: Bash Read
---

Reply in whatever language the user writes in; keep file names, IDs and slugs in English.

Gather the numbers the spec is still waiting for.

## 1. Run it

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/numbers.sh" $ARGUMENTS \
  || bash "$(find ~/.claude/plugins -name numbers.sh -path '*sdd-solo*' | head -1)" $ARGUMENTS
```

With no argument it sweeps the whole of `specs/`. With `UC-###` it shows only what that UC is waiting for —
its own blanks plus the blanks of every rules file and ADR, since a rule with a blank parameter blocks every UC
that quotes it. `--rules-only` keeps just the table blanks, which are the ones a rule cannot be enforced without.

It is read-only. It never blocks anything and it never writes.

## 2. Read the output with the user

Three kinds, and they are not equally urgent:

- **`param`** — a blank standing alone in its own table cell. This is a parameter: a rule, an ADR or a design
  that literally cannot be enforced or built until it has a value. The `blocks:` line under it names the UCs
  waiting. Start here.
- **`question`** — an Open Question whose interim decision is still `___`. The UC can move (the gate lets an
  Open Question through — #23), but nobody downstream knows what to assume.
- **`prose`** — a blank inside a sentence. Often a measurement not taken yet rather than a decision not made.
  Many of these are honest and should stay.

## 3. What to do about them

Work down the `param` list with the user, in order of how many UCs each blocks. For each one, either:

- the user gives a value → write it where it stands, and add the reason to `specs/decisions.md`; or
- the value depends on a measurement nobody has taken → say so **in the cell**, naming the measurement and who
  takes it, and leave the `___`. A blank with a named measurement beside it is a plan; a bare blank is a gap; and
- nobody is blocked and nobody remembers why the row is there → propose deleting the row.

**Never fill a blank in yourself, and never let filling one be the way past a red gate.** A gate red on a
placeholder is the plugin doing its one most valuable job. If the user asks for a plausible number, say plainly
that inventing it is the failure the whole BR layer exists to prevent, and offer the measurement instead.

## 4. Say what is left

End with the count by kind and the single parameter blocking the most UCs, so the user leaves knowing what the
next decision is worth. If nothing is blank, say that — it is worth knowing and it is rare.
