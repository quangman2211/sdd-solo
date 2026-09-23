# intake · brief conversion mode (`$1` is a file path)

<!-- Read this file when /sdd-solo:intake was given a path to a brief. It is the WHOLE of mode B: how to split the
     brief into a BR, declaring brief_path in .sdd/config, and anchoring the brief version in br.md. Step 0 and
     part C (finishing, both modes) stay in SKILL.md and still apply — this file replaces neither. -->

## B. Brief conversion mode

Read the file, then split it into four parts: why (the BR) · who does what (candidate UCs) · constraints (CON) ·
unclear (Open Questions).

**Step 0 applies to this mode too.** A brief is another agent's words; layer 0 is the owner's. The brief asks for
something that contradicts an item in `## Do not narrow` → **the owner wins, the brief loses**, and that line goes
down into `## Dropped from brief` with a destination.

**Before filling in Goal / In Scope: ask the user three questions in words, one per turn — required, even when the
brief already answers them (#46, #47).** Real runxops case: BR-003 was converted straight from a brief; both sceptic
roles (BR-003, BR-002) concluded *"a solution written backwards into a reason"*; two things surfaced **afterwards** —
*"the cause of work falling through = not being told"* and *"run it for myself before selling it"* — and they changed
the plan more than every technical finding put together. A brief is another agent's words; these three questions are
the words of the person paying.

1. *"What hurts, and why does it fall through?"* (the cause, not the symptom)
2. *"Build it to run for you first, or go ask customers first?"*
3. *"Once v1 is done, what do you open every day to do your work? What can you change yourself without a developer?"*

Record the answers **verbatim**, with a trail, into the file — not into something said:
- 1 → `## Background`, the line `**What pain, why it lands:** "<verbatim>" (asked in words, <date>)`; and `## Goal` is
  written from this answer, not from the brief.
- 2 → `## Background`, the line `**Run it for ourselves first or sell it:** "<verbatim>" (asked in words, <date>)`.
- 3 → `## In Scope`, as the first line `**Opened every day:** "<verbatim>"` — this **must be** in In Scope before
  anything is cut; if it contradicts the brief, the brief loses and that goes into `## Dropped from brief`.
`br-check` warns when a BR has `**Source:** brief` but Background has no `**What pain, why it lands:**` line.

**The required rules — no exceptions:**

1. **Never invent a number.** Every threshold, deadline, quota or permission the brief does not give a **source** for
   → write `___` and add a specific Open Question. Even when the brief **does** state a number: with no source it is a
   *proposal*, not a decision. Write `___ (the brief proposes 15, nobody has approved it)`.
2. **Push every feature back up a layer.** Every "build X" item must answer *which goal X serves, measured how*.
   Pushing back reaches no goal → mark it an **orphan feature** and put it into Out of Scope or an Open Question. Never
   keep it silently.
3. **A claim without evidence does not go into Background.** A brief often says "customers complain a lot about…"
   with no number. That becomes an Open Question *"where does this number come from?"*, not a fact in Background.
4. **Record what was dropped — in the FILE, not on the screen.** Every sentence or item in the brief not carried into
   the spec becomes a line `- <item> — <reason> → <destination>` in the BR's `## Dropped from brief` section, and only
   then is read back to the user. **The destination is required since 7.0** — `→ slice ___` (which slice in
   `vision.md` picks it up) · `→ reopen when ___` (the condition) · `→ moved to: <architecture.md · ADR-### · CHG-### ·
   Open Question>` for anything in the design layer. `br-check` is **red** when a line has no destination; it no longer
   only warns. Version 3.2.0 only said "print the list", so the entire product of this rule lived in speech: close the
   terminal and it is gone, and six months later nobody knows what the brief contained or why it vanished. The three
   rules above all leave a `___` or an Open Question in the file; this one must leave a trail too. See #21.

   **Dropping and deferring are two different things.** A reason of the form *"belongs to the design layer"*,
   *"belongs in an ADR"*, *"belongs to Phase 5"*, *"later"* is a **deferral**, and a deferral must record a
   DESTINATION: `→ moved to: architecture.md · ADR-### · CHG-### · Open Question`. With no destination nothing carries
   it: each UC's `design.md` is produced by `/sdd-solo:design`, and that reads the brief **only when** `brief_path` has
   been declared. The most common destination of a deferred architecture item is `specs/architecture.md` (root,
   project-wide), section `## Settled from brief`. Real case (`runxops`, #34): the line *"the whole three-layer
   architecture — belongs to the design layer"* sat still for two days while `plan.md` was written with an architecture
   **opposed to the brief**, and nobody saw it because both sides were internally consistent. A forwarding address
   nobody delivers to looks exactly like a completed handover. `br-check` is red when a deferred line has no
   `→ moved to:` (7.0).

5. **Do not write the UCs.** Only produce the IDs + names of candidate UCs.
6. **Record the source in the BR's Metadata:** the line `- **Source:** brief <path>`. That is what tells `br-check.sh`
   this BR must have a `## Dropped from brief` section.
7. **Anchor the brief — two jobs, both required.** After intake the brief becomes a **write-only** file: all three of
   the plugin's checking layers (`gate-check`, `verify`, the three adversarial roles) look only inside `specs/`. So it
   has to be brought into view by hand:

```bash
# a) declare it in .sdd/config — this puts the brief into the REQUIRED READING ORDER of every later session.
#    A repo initialised before 3.21.0 has NO brief_path= line, and `sed` on a line that does not
#    exist silently does nothing — so ask first, then pick the branch.
if grep -q '^brief_path=' .sdd/config; then
  sed -i.bak "s|^brief_path=.*|brief_path=$1|" .sdd/config && rm -f .sdd/config.bak
else
  printf 'brief_path=%s\n' "$1" >> .sdd/config
fi
grep '^brief_path=' .sdd/config        # print it, to see that it really went in
# b) anchor the brief's version in br.md — if the brief changes after intake, br-check goes red
printf '**Brief source:** %s · sha256 %s · loaded %s\n' \
  "$1" "$(shasum -a 256 "$1" | cut -c1-12)" "$(date +%F)"
```
   Paste the `**Brief source:**` line into the BR's Metadata, right under `- **Source:**`. Without (a), later sessions
   do not know the brief exists; without (b), the brief can be edited at any time with nobody knowing, and two
   documents contradict each other in silence.

**The number boundary — which numbers are forbidden and which are not.** Rule 1 forbids numbers in a **business
decision**: thresholds, deadlines, quotas, permissions. It does **not** forbid numbers in a **way of measuring**:
"time 20 consecutive table bookings" is a concrete measurement and far better than "time a few bookings". A vague
measurement makes the metric uncheckable, which loses exactly what `BR-000` is teaching. Being concrete about the
measurement is right; being concrete about a decision nobody approved is invention.

Why these rules are strict: a brief written by an LLM almost always carries plausible numbers nobody decided —
*"lock for 15 minutes after 5 failures"*, *"hold stock for 30 minutes"*. Copied straight into `specs/`, all 24 DoR gate
checks will defend those silent numbers very diligently from then on. That is exactly what `sdd-process` calls a silent
decision, except the model filled it in before the repo existed.

---
