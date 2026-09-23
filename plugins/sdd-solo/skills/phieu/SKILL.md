---
name: phieu
description: Question tickets with a number lock (7.2) — allocates the next number mechanically (an atomic lock shared by every worktree, the placeholder row committed immediately), closes a ticket by counting F#/K# in the file and requiring a KETQUA from each role, and audits the index. Use it when an agent needs a new ticket, when the coordinator closes one, or when the index looks out of step.
disable-model-invocation: true
argument-hint: "new \"<task>\" <from-role> [slug] | close <n> | muc-luc | list [--mo] | hoi <role> \"<question>\""
allowed-tools: Bash Read
---

Reply in whatever language the user writes in; keep file names, IDs and slugs in English.

Run `phieu.sh` with `$ARGUMENTS`:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/phieu.sh" $ARGUMENTS
```
(if the variable is not substituted: `find ~/.claude/plugins -type f -name phieu.sh -path '*sdd-solo*' | head -1`; in a project that has run `init --update`: `.sdd/scripts/phieu.sh`).

- `new "<task>" <from-role>` — **take the number first, write the body after.** The script locks with `mkdir` in `git-common-dir` (shared by every worktree), takes the number as the max of the index ∪ the file names ∪ `git log --all "ticket #n"` (which catches tickets in an unmerged worktree), creates `notes/hoi-dap/phieu/NNN-<slug>.md` from the skeleton, adds the index row, and **commits the placeholder row immediately** with `--only`. It prints `#n <path>`. The agent then fills in Question · Already looked up · If chosen wrong · The agent leans towards, and commits separately as `chore(sdd): ticket #n — <task>`, naming the files explicitly. A 6.x log at `specs/internal/hoi-dap.md` is also accepted.
- `close <n>` — counts `F#`/`K#` **in the file** against the ticket's own declared total (a mismatch is red and lists what is missing — P-33); every role with work in `For:` must have a `KETQUA ket=xong` (`role.sh --ketqua`) — missing one is red. All present → the index row goes to `applied` and it commits.
- `muc-luc` — repeated numbers · gaps · files with no row · rows with no file. Run it read-only over the existing log before trusting it.
- `list [--mo]` — print the index; `--mo` shows only tickets not yet `applied`/`closed`.
- `hoi <role> "<question>"` (7.3) — opens an `ASK-<V>n` entry in `notes/hoi-dap/hoi-<V>.md` from the four-box addressed skeleton (source · blocking · doing while waiting · spec work when answered) plus the `Answer (A/R)` · `target:` box. Check with `hoi-check.sh <V>`.

Do not write the ticket body for the agent; do not grade L0–L3 (that is R's job); do not use `AskUserQuestion` while running under a brief — the ticket *is* the question.
