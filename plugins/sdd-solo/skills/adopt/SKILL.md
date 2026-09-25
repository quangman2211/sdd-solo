---
name: adopt
description: Take a repo that already has code into the SDD process, one behaviour at a time. Lists every file that predates sdd-solo, groups it into BR/UC candidates with the owner, and hands each candidate to the ordinary steps ①-⑨. Use it right after /sdd-solo:init on a repo with existing code, and again whenever you want to see how much is left. It NEVER writes a UC file, never creates a gate marker, and never marks anything implemented — there is no import that skips the steps. Read-only itself; the writing is done by start/gate/close as usual.
disable-model-invocation: true
argument-hint: "[--count]"
allowed-tools: Bash Read
---

Reply in whatever language the user writes in; keep file names, IDs and slugs in English.

Bring existing code into the process without pretending it was specified first.

## What this skill is not

There is no `--import`, no `--as-built`, and no flag anywhere that sets `**Status:** implemented`.
This skill writes nothing into `specs/` and nothing into `.sdd/gate/`. A behaviour that already has
code becomes a UC exactly the way a new behaviour does: steps ①-⑨ and the real DoR gate. The steps
that a shortcut would skip — the adversarial pass and the re-read — are the steps that find the
defects, and on code nobody has re-read in years they are worth more, not less.

If the user asks for a faster path, say that plainly once and carry on with this one.

## 1. Show where the repo stands

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/adopt.sh"
```
Fallback if `${CLAUDE_PLUGIN_ROOT}` did not expand:
`find ~/.claude/plugins -name adopt.sh -path '*sdd-solo*'`

Print its output verbatim. With `--count`, print only the two counter lines and stop.

If it says the repo declares no baseline, the repo had no code when sdd-solo arrived: there is nothing
to adopt, and the answer is `/sdd-solo:intake`. Stop there.

## 2. Check the BR layer exists first

A UC hangs off a BR. If `specs/` still holds only the template (`br_untouched`, which
`/sdd-solo:status` reports), say so and send the user to `/sdd-solo:intake` first. Existing code still
needs its WHY written down — and the owner is the only one who has it. Do not infer a BR from code:
code says what happens, never what it was for.

## 3. Group the files into candidates — propose, never write

Read the listing and the files it names. Propose candidates in a table:

| Candidate | Files it would claim | Why these are one behaviour |
|---|---|---|

Rules for the grouping:
- One candidate = one behaviour a user of the system can observe, not one module and not one file.
  A helper function is not a UC; it is the code of some UC and belongs in that UC's `## Existing code`.
- Name the candidate after the behaviour, not the file.
- Files you cannot place into any behaviour: list them separately and ask. Some of them are genuinely
  code belonging to no UC and never will be — those go in `tool_paths`, not into a UC.
- **Ask the owner to confirm the grouping before anything is created.** Write nothing in this step.

## 4. Hand one candidate to the ordinary process

For a confirmed candidate, and one at a time:

1. `/sdd-solo:start` — the real step ①, which creates the UC skeleton.
2. Fill the UC from the behaviour, not from the code. Read the code to check your claims, never to
   copy its structure into the spec: a spec that mirrors the implementation cannot disagree with it,
   and a spec that cannot disagree finds nothing.
3. Add the `## Existing code` section listing the files this UC already has:

   ```markdown
   ## Existing code
   - path/to/file.js
   - path/to/other.js
   ```

   This is what lets `close-check` read the code of a UC whose commits predate its spec, so the
   literal-number scan actually runs. The gate checks these paths existed at the adoption baseline —
   code written yesterday cannot be declared pre-existing.
4. Steps ②-⑨ as normal, ending at `/sdd-solo:gate`.

Then run this skill again: the first counter line drops as the files come under commits carrying an ID.

## 5. What to tell the user about the exemption

While a file is still on that list, the githook lets a commit touching it through with a warning
instead of demanding an ID. Be accurate about what that means:

- It covers **only** files that were already there. Anything new is governed from its first commit.
- A file leaves the exemption **for good** the first time a commit carrying a real ID touches it.
- Those files are still in the trace-ratio denominator — unlike `tool_paths`, this is "no UC **yet**".
- On a repo of any age most commits only modify existing files, so early on the exemption will be
  carrying a large share of them. That is the cost of not freezing the repo, and the counter is there
  so it stays visible rather than becoming the way things are done.
