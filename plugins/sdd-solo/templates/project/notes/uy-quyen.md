# Delegation — when the coordinator decides on the owner's behalf

<!-- Skeleton (7.3). The owner writes Scope; the coordinator may only decide inside it. This is the repo's
     POLICY — the plugin ships no real stop points; the five rows below are a sample taken from runxops,
     rename them freely. Two checks run in .sdd/scripts/status.sh: every `STOP-<name>` in notes/hang-doi.md
     must appear in the Stop points table; and every Ledger row pointing at `#n` or at decisions must have a
     matching line in specs/decisions.md — otherwise the decision is invisible to every later session. -->

## Scope
<Owner writes this, in their own words: what the coordinator may decide, and until when. For example:
"four BRs are settled, run until every UC is implemented". While this section is empty the coordinator
decides NO L3 question at all.>

## Source order — stop at the first source that answers
1. `specs/decisions.md` — settled means not asked again.
2. `specs/vision.md` — layer 0; the coordinator **does not edit it and does not overturn it**. Vision is wrong → one line in `## Reverse ledger` plus a Ledger row below, then continue with `___`.
3. <the project's own clarifying documents, in priority order — or delete this line>
4. The source brief (`brief_path` in `.sdd/config`).
5. No source answers → take the option that is **reversible, cheapest, and narrows no bullet of `## Do not narrow`**; numbers are **never invented**: `___` + an Open Question + an interim decision, and the design makes it a parameter.

Every time an L3 question is decided this way: the ticket's `Approve:` box records
`A under delegation <date> · source <file:line>`; a normal `specs/decisions.md` line (Decision · Rejected ·
Detail) says "A under delegation"; and one row goes into `## Ledger`.

## Stop points — the coordinator stops THAT LANE, records STATE, says one sentence, and does not wait on other lanes
| # | Stop when | Who releases it |
|---|---|---|
| S1 | A `git push` / deploy / write to an outside machine is needed | owner |
| S2 | Real data or a real customer account must be touched | owner |
| S3 | Money, keys or a new account are needed | owner |
| S4 | The question changes the **meaning** of `specs/vision.md` | owner |
| S5 | A UC has had ___ re-read rounds and the next one still finds a blocker — a sign the BR or the axis changed, not that wording is missing | the coordinator files a "rounds exhausted" ticket; the owner settles the axis; other lanes keep running |

## Ledger — L3 questions the coordinator decided instead (newest at the bottom)
| Date | Question | Choice | Source | Ticket / decisions |
|---|---|---|---|---|
