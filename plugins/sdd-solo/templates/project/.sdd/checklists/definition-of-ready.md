# Definition of Ready — the gate before opening Claude Code

A UC is ready when **all** of these hold:

- [ ] Actor, Trigger, Preconditions, Main Flow, the sharpest Exceptions, Postconditions — all present.
- [ ] Every cited RULE-### exists in `specs/rules.md` or `specs/<craft>/rules.md`; no rule hides inside an AC.
- [ ] ≥ 1 AC for the main flow; ≥ 1 AC per Exception. In Given/When/Then form.
- [ ] The flow is drawn (`UC-###.flow.md`, mermaid); every E# has a branch reaching a named end node; every Postcondition has an end node. `/sdd-solo:gate` checks the first two mechanically.
- [ ] Every entity the UC touches has a file in `specs/core/entities/` or `specs/<craft>/entities/`; state changes follow only arrows that exist on the state diagram.
- [ ] Every E# has ≥ 1 SCR screen state; every SCR points back to a step or an E#.
- [ ] `**Implementation assumption:** <runs where · who calls it · stack>` is written. None of the four
      layers BR/UC/Entity/AC has a slot for this sentence. Saying it here gives `/sdd-solo:design`
      (step ⑩) something to check against `specs/architecture.md`; leaving it out means a mismatch
      only shows up after the code is written. `gate` warns, it does not block.
- [ ] The adversarial pass ran in a fresh session; every question has an output (spec / Open Question / Out of Scope).
- [ ] The spec was re-read by an unprimed head — `/sdd-solo:verify UC-###` (subagent). Since 6.0.0 this is the **only** door; there is no "leave it for another day". `/sdd-solo:gate` checks it mechanically: ≥ 1 `F#` line carrying `[anchor: ...]` and an output, and the commit `docs(UC-###): re-read — …` is the newest spec commit.
- [ ] The `docs(UC-###): re-read — …` commit (verify) is the last spec commit; editing the spec afterwards means re-reading again.

One line missing → do not open Claude Code. A small UC runs through the checklist fast; that is not a reason to skip it.
