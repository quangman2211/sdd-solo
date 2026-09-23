# intake · interview mode (`$1` empty)

<!-- Read this file when /sdd-solo:intake was given no argument. It is the WHOLE of mode A: the discipline of one
     question per turn, the seven questions, and what to do with the answers. Step 0 and part C (finishing, both
     modes) stay in SKILL.md and still apply — this file replaces neither.
     It lives beside SKILL.md because a run is either mode A or mode B, never both (8.1.0). -->

## A. Interview mode

**The discipline of this mode matters more than the question set:**

- **One question per turn.** Ask, wait for the answer, then ask the next. Never put all seven out at once — someone
  who is still vague will answer none of them.
- **Say back what you just heard in one sentence, then ask the next.** "So it is ___, is that right?" This is the
  cheapest place to catch a misunderstanding, and it shows the user they are being heard.
- **"I don't know" is a valid answer.** Write `___` and an Open Question line. Do not push.
- **You may suggest a COUNTING FRAME, never a THRESHOLD.** The two rules "do not suggest numbers" and "the way of
  measuring may not be empty" collide for someone who has never measured anything — they need an example, and every
  example carries a number. The boundary: *where to count · what to count · how often* may be offered; **the
  threshold inside that frame may not**, and stays `___` even after the user nods.
  A safe phrasing: *"for counting, something like: every Sunday go through each channel and count the messages that
  waited a long time for a reply — could you do that? And how long 'a long time' is, we leave open for now."*
- **A number the user merely nods at, that YOU proposed, is not yet theirs.** Someone who is still vague will nod to
  move on. Required: leave `___` at the threshold, **and** write an Open Question line saying explicitly *"this
  number came from the interviewer; the user has not decided"*. Without that line, six months later nobody can tell
  the user's numbers from the machine's.
- **Do not propose features.** If the user asks "what should we build", answer with a question about the problem.
  This step is for understanding, not designing.
- **If the user answers question 1 with a solution** ("I want to build a dashboard"), do not put it in the Goal. Ask
  back: *"what would that dashboard let you know that you do not know now?"* A BR written backwards from a solution
  is the most expensive mistake at this layer.

**The three required questions** — do not write the file until these are done:

1. What hurts right now? (tell it plainly, no polish needed)
2. Who is hurting? (you · the customer · whoever operates it · another system)
3. How do they cope today, and what does it cost? (time · number of mistakes · money — `___` if unknown)

**The four digging questions** — only once the first three have answers, and they may end in `___`:

4. If nothing is done for another six months, what happens?
5. Is there a way to get that **without building software**? (buy one? change the process? hire someone?)
6. What are you **deliberately not doing** in the first version?
7. How will you know it is done? Which number, taken from where?

Question 5 is the most skipped and the most valuable — it is the only thing that stops you building software that need
not exist. Do not rush past it because the user is excited.
Question 6 produces Out of Scope; question 7 produces Success Metrics.

**Question 5 alone may offer options** — a deliberate exception to "do not propose features". Someone who has not
thought about it cannot list non-software routes themselves, so offering nothing means dropping the question
altogether. Two constraints: only **non-software** options (change the process, do it by hand in batches, buy an
existing tool, hire someone, a shelf and a label), and offer **at least three**, so the user is not walked into one
and nodded through it.

**"I haven't thought about it" is a result for question 5, not a blank.** Write one line into `## Background`:
`**Why still build:** no reason yet — the user has weighed no non-software option`, plus an Open Question. Do not turn
that line into a sentence that sounds as if the weighing had been done. `br-check` warns while that line is missing,
and the sceptic role in `/sdd-solo:adversarial BR-###` will push straight on it.

**Writing it out:**

- Questions 1 + 3 → `## Background`. Only what the user actually said. A number the user gives is recorded with its
  source ("I counted them by hand in the inbox last week"). No source → down to Open Questions.
  **Since 5.0.0, Background in `br.md` is a TABLE OF CONTENTS, not an evidence store:** one `### heading` per point
  plus a line `→ evidence.md`, and the `**…:**` lines (such as `**Why still build:**`). The body — measurements, long
  quotes, tables — goes into `evidence.md` **next to the `br.md` of the same slice**, under a `### heading` of the same
  name. Measured at runxops: `## Background` alone was 31.8 KB across 15 evidence items, and every later reading of the
  BR had to wade through it just to learn the Goal and the Scope. Evidence is what makes a BR stand up *while it is
  being written*; after that it is a trail.
  In a new slice, just write into the two files, no tool needed. A repo **still on the 6.x layout** (a combined
  `specs/br.md`) whose `## Background` has bloated: `bash .sdd/scripts/migrate.sh --evidence BR-### --dry-run` and then
  for real — that flag only understands the 6.x tree; in the 7.0 tree `migrate.sh --layout v7` already split out an
  `evidence.md` per slice during the move.
- Questions 1 + 2 → `## Goal`, **one sentence**, in the shape "who can do what that they cannot do now".
- Question 7 → `## Success Metrics`. Numbers may freely be `___`; **the way of measuring may not be empty**. No
  analytics yet → write the hand-counting method — "count the threads in the inbox every Monday" is a valid measurement.
- Question 6 → `## Out of Scope`, and each line becomes a `-.->` branch on the Impact Map. **Every line says where it
  goes:** `→ slice ___` (which slice in `vision.md` picks it up) or `→ reopen when ___` (the condition). And before
  writing, check against `## Do not narrow` in `vision.md`: any line matching a keyword there → **ask the owner** —
  either that line comes out of Out of Scope, or the owner settles it as a deliberate narrowing and the line records
  `deliberately narrowed — owner decided YYYY-MM-DD`. Do not pick a branch yourself; `br-check` is red without that label.
- Question 5 → **always** write a `**Why still build:** ...` line into `## Background`, whatever the answer was. A
  non-software option exists and the user still chooses to build → record the reason. Not thought about → write
  *"no reason yet"* + an Open Question. That line is the only thing in a BR that can say this software was shown to
  need to exist.
- Question 4 → `## Background`, or a `CON-###` if it is a timing constraint.
- Candidate UCs → `## Related Use Cases`, **ID + name only**. Do not write UC detail here.

---
