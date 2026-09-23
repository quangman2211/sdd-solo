# Business Rules

The single place each rule lives. UCs and ACs cite `RULE-###`; they never copy the text.
A rule with 3 or more input conditions → write a DMN decision table (state the hit policy).

---

## RULE-000: <rule name — THIS IS A SAMPLE, delete it or renumber before use>
- **Statement:** <one sentence, unambiguous>
- **Applies to:** UC-###, UC-###
- **From:** YYYY-MM-DD
- **Why:** <the reason this rule exists>
- **Source:** <BR-### · decision of ___ · legal requirement ___>
- **Status:** active | deprecated (from YYYY-MM-DD, replaced by RULE-###)

<!-- `Why` is the most valuable field at the 5–10 year mark, and the one most often left empty,
     because at the time of writing the reason is obvious. It is NOT `Source`: the source says
     where this rule CAME FROM, the why says what it EXISTS TO DO. A rule that loses its `Why`
     is a rule nobody dares delete five years later — not because it is still right, but because
     nobody knows what breaks without it. Rules like that pile up into something nobody can undo.

     `Source ... verbatim: "..."` — when the source is another ID (BR-###, CON-###), COPY THE
     SOURCE'S OWN WORDS, do not paraphrase. Real case in CHANGELOG 4.x: a line labelled `BR-001`
     for a sentence `BR-001` never said, and it INVERTED the prohibition. It read perfectly and
     passed every check — because every rule only checks that an ID EXISTS, never that the ID
     SAYS what is attached to it. Copying the words verbatim is the only move that exposes it. -->

## RULE-000b: <multi-condition rule — DMN — SAMPLE>
- **Statement:** <one sentence>
- **Hit policy:** First (stop at the first matching row) | Unique | Collect
- **Applies to:** UC-###
- **From:** YYYY-MM-DD
- **Why:** <reason>
- **Status:** active

| # | Input A | Input B | Input C | → Result | Exception / AC |
|---|---|---|---|---|---|
| 1 | ... | — | — | ... | E# · AC-# |
| 2 | ... | ... | — | ... | ... |

### Rule parameters
| Parameter | Value | Note |
|---|---|---|
| <e.g. Plan.maxDevices per plan> | ___ | leave empty until it is settled |

## History
- YYYY-MM-DD: RULE-### initial
