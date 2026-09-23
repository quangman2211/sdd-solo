# orchestrate · traps already hit with herdr 0.9.0

<!-- Read this file ONLY when the project actually runs herdr. It is not a dependency of sdd-solo and no step of
     the standard chain needs it; it lives beside SKILL.md so a run that has never heard of herdr does not carry
     it (8.1.0). Other runners have other traps — this is a record of ours, not a specification. -->

## Appendix — traps already hit with herdr 0.9.0 (not a dependency; other tools have other traps)

- `agent wait --timeout` counts **milliseconds**: `900` = 0.9 s and looks like the agent finished; use `900000` for
  15 minutes. `wait` returns early between subagent phases → wait with a loop `for i in 1..6: wait; read agent_status;
  break when != working`.
- A brief over ~1,500 characters pasted into the input box becomes `[Pasted text #N]` and is **not sent**: `prompt`
  returns `agent_prompted` while the state stays `idle`. After every prompt check `agent_status = working`; `idle` +
  `[Pasted text` on screen → `send-keys <name> enter`.
- A brief through zsh: `<wt>`, `$(…)` and backticks are read as shell syntax → `parse error`, and the prompt never
  arrives. Write it into a scratchpad file and `prompt "$(cat file)"`; name things in words ("worktree-path").
- A background shell loses PATH → `export PATH=/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin:$PATH` at the start of
  every background command.
- A freshly started Claude can be stuck on a dialog while its state still reads `idle` rather than `blocked` → after
  `agent start`, read the screen before prompting. A dialog with a privacy option (scanning shell history) → A does
  not click it, A asks the owner.
- The input box shows a ghost suggestion (`\x1b[2m` when read with `--format ansi`) after a skill finishes — harmless;
  `agent read` as text cannot tell it apart from typed characters.
- `agent read` may fail to retrieve a long answer → for long output, make the agent write a file.
- `agent send-keys` only accepts **named keys** (`enter`, `escape`, `ctrl-u`…) and cannot type characters —
  `send-keys soi "/clear" enter` returns `invalid_key` and does nothing. Every slash command goes through
  `agent prompt <name> "/clear"`. A fresh session for C: `prompt soi "/clear"`, wait ~8 s, then prompt the brief. An
  agent reporting "3% until auto-compact" → `/clear` before the next round; D/T keep their session because they hold
  code context.
- Restarting an agent to load a new plugin version (a new version does not apply to an open session):
  `agent prompt <name> "/exit"` → the pane returns to a shell and the agent name disappears →
  `agent start <name> --kind claude --pane <pane> --timeout 90000` → read the screen → resend the role brief. Runxops
  did this for 6 panes after 6.6.1, and all 6 answered "ready".
- A Claude Code pane draws files changed by `git merge` exactly like files the agent edited (§2 rule 2).
