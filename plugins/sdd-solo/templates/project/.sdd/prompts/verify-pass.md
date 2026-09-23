# Verify pass — reading the documents with an unprimed head

This prompt runs in **its own subagent**, not in the context of the session that wrote the spec. That is
the whole value of it: the writer cannot read what they just wrote, because the eye reads **intent**, not
**words**.

Same need as the three roles at step ⑦. The difference: the three roles ask *"what has the spec not
answered"*; a verify pass asks *"does the spec contradict itself, and does it claim things that are not
true"*.

## Rules

1. **Report only, never fix.** Do not edit files, do not propose code, do not helpfully rewrite. Fixing is
   the job of whoever decides, after reading the findings.
2. **Every finding must quote VERBATIM the two places that disagree**, with path and line number. A summary
   is not allowed — a summary is where an assumption sneaks in, and a finding without verbatim quotes
   cannot be re-checked by the reader, so all they can do is believe it. (Same rule as #25.)
3. **Every finding must have an output carrying an ID**: `→ fix UC-009 Main 7` · `→ fix RULE-001` ·
   `→ Open Question` · `→ false positive because <reason>`. There is no "leave it". (Same rule as #12.)
4. **The scope is the whole tree, not one file.** Most of this class of error lives **between** files — each
   file on its own reads perfectly. Checking files one at a time finds nothing.

## The kinds of error to look for

*(This heading deliberately **carries no count**. Version 3.6.0 added a row to the table below and forgot to
change the word "Six" two lines above it — a label carrying a number can rot every time a row is added.)*

| # | Kind | Question |
|---|---|---|
| 1 | **Claiming something untrue** | The document says *"X does not exist yet"* / *"Y was added"* — do X and Y exist? Open the file and look; do not trust the sentence. |
| 2 | **The commit says one thing, the file another** | The commit message claims which **content** was added or changed — is that content in the diff? `git show <hash>` and compare **the claimed content against the diff**, not the file list. |
| 3 | **Two layers saying opposite things** | BR ↔ RULE ↔ UC ↔ AC. A decision changed at a lower layer while the upper layer still carries the old sentence is the most common case. |
| 4 | **Rejected but still being taught** | An option rejected in a Q#/CON-###/History while somewhere else still instructs people to do it. Whoever reads that place will rebuild exactly what was just rejected. |
| 5 | **The ordering contradicts the content** | Read steps 1→N in order: is that really the sequence? Change the content and keep the numbers and every mechanical check stays green. |
| 6 | **A promise with no path** | An AC/Postcondition promises the system *knows* or *does not change* something — is there actually a step that fetches it, or that really does not write? |
| 7 | **A rotted number** | A number describing **real data** (line counts, ratios, "427 rows", "10/1986") — measured again today, does it still come out the same? |
| 8 | **The label did not follow the content** | Headings, summary sentences, counts inside headings — are they still true of the body below? Whoever edits the body usually does not edit the label. |
| 9 | **Right number, wrong subject** | A valid measurement, but it answers a **different** question from the one in the text. Measure again and you get the same number, forever. |

Kind #2 has **two halves, and only one is an error** (#42). Claiming a block the diff does not contain, or a
diff that changes `AC-3` while the message says `AC-5` → **a real error**, and it becomes an `F#`. A diff that
also touches a neighbouring file (glossary, flow, entities) the message does not name → **not this kind**:
the message still describes correctly what it did, it just did not list everything. Collect all such cases
into **one low-level warning line** at the end of the report — *"3 commits also touched neighbouring files not
named in the message: `7b452e1` (glossary) …"* — not an `F#`. Real runxops case, UC-014 F16: two commits were
classed as #2 for "not naming glossary, flow"; `git show` showed both contained exactly the block they
claimed; the main agent could reject it, but it cost a round of checking. The right method: read the message,
list **what it claims it did**, then find each of those in the diff — do not count files.

Kind #9 is **not** kind #7. Kind #7 is *"the number was right, the data changed underneath"* — cured by
**measuring again**. Kind #9 measures the same every time: what is broken is not the number, it is **the
sentence it is attached to**. Cured by **re-reading the sentence**, not by measuring.

And none of the four layers guarding kind #7 catch it: the fingerprint matches · the measuring command exists
and prints the right number · the structure is unchanged · the addition works out. **All four check the
relationship between the number and the data; none checks the relationship between the number and the SENTENCE.**

Real case (`runxops`): the same `Variant` column produced **three equally valid denominators** — `249` rows
whose *total value* > 1 · `215` rows *grouping several Variants* · `469` rows *with or without* an axis. The
sentence in the document was about listings that **group several Variants**, so `215` is the right one; `249`
got pasted in along the way. Same shape: `1006` (total values, an **addition**) and `920` (combinations, a
**multiplication**) — using `1006` for the expansion is wrong, using it for total value is right.

**The cheap check:** any column producing **more than one valid denominator** means every number taken from it
**must carry the denominator's label and never stand bare**. And the question to ask is: *which question does
this number answer, and which question is the sentence in the document asking?*

Kind #8 deserves its own row apart from #3 because it has **its own signature and its own hiding place**: the
error is caused by the previous fix itself, and it sits anywhere from a few lines to a few hundred lines away
from the edit, so it never enters the eye of the person who just made it. Three measured cases in one day, in
`runxops` and in this plugin, by three different people, all the same shape: *"Six kinds of error"* over a
seven-row table · an `AC` whose heading says one thing and whose body says another · `entities.md` updated
`7 → 10` in the table and in History while missing a prose sentence **190 lines** away.

How to look: for every number or decision that just changed, **sweep the whole tree for every other place that
mentions it** — do not fix the places you remember. The memory of whoever just made the edit is the worst thing
to rely on, because it remembers the **intent**, not the **words**.

**CLASSIFY the hits, do not just find them** — and do not skip any. This rule pulls against rule 9 of kind #7
(*keep the old number with the reason it differs*): the better rule 9 is followed, the more the tree fills with
**legitimate** old numbers, so sweeping for old numbers produces more and more correct-but-must-be-rejected
hits. After a few months, every changed number drags dozens of historical hits with it, and at that point
*"rejecting a finding must be cheap"* is no longer enough — **what must be cheap is not having to reject at all.**

The fix: split the hits into two kinds the moment they are found, **labelled by machine**, and only the second
kind becomes an `F#`:

| Hit sitting in | Handling |
|---|---|
| A `## History` section, or a sentence shaped `<old number> → <new number>` / *"the old number … because …"* | **a legitimate historical hit** — list them compactly as one counted line, not an `F#` |
| Anywhere else — live prose, tables, headings, a `RULE`, an `AC` | **an `F#`** — this is a dead number inside a live sentence |

Do not **exclude** the first kind from the sweep, only **demote** it to one counted line: *"12 hits in History
and in `old → new` sentences — legitimate under rule 9"*. Excluding it outright makes a live prose sentence that
happens to contain a `→` invisible forever, and that is exactly the class of error this whole document exists
to catch.

**A qualitative phrase standing in for a number is also a hit.** *"will be more than 1986 rows"* is not wrong —
but the real number is **2437**, that is **+23%**, and *"more than"* hides precisely the part that would make
someone decide differently. Same shape as `13/13` in rule 10: the sentence is not wrong, it is just not enough
for anyone to decide anything.

## The second role: checking the documents against REAL DATA

Everything above reads documents against documents. Kind #7 is different and needs its own role, because **a
number is the fastest-rotting thing in a whole spec**: it was right when written, nobody updates it when the
data changes, and a rotted number **looks exactly like** a correct one. No structural check can tell them apart.

Real case (`runxops`, 2026-09-09): `entities.md` said *"427 rows currently have an axis stuck inside
`Product Name`"*. That sentence **passed an adversarial pass and three gate runs**. What caught it was not a
script but a sentence from someone who knew the data: *"the data isn't clean"*. Measured again — and note that
this worked example deliberately shows **two levels**, because each teaches something different:

```
UNIT = CELL         (a partition; the groups are disjoint and must add up)
  cells with content beyond name + link   982
    identifier only                        513
    variant axis only                      454
    BOTH                                    15
    in no group                              0
                                  sum →    982  ✓

UNIT = CODE / ROW   (NOT a partition — larger than the cell count, since one cell can hold several)
  identifier codes                         545
  variant axis rows                        601
  variant values (SUM)                    1006
  variant combinations (PRODUCT)            920   ← the real Variant count when expanded
```

**Three numbers in one sentence can carry three different units, and nothing in the text says so.** The old
sentence *"982 cells — 545 identifiers and 601 axes"* reads like a split in two; anyone doing the arithmetic
gets `545 + 601 − 982 = 164` cells carrying both, while **the real number is 15**. Off by more than ten times,
purely because three units stood side by side and nobody declared them.

**Try the partition on BOTH sides — and this is where the worked example teaches most, because one side breaks:**

```
variant side      454 + 15 = 469  ✓ matches the independently measured count of cells with a Variant
identifier side   513 + 15 = 528  ✗ the count of cells with Identifiers is 555 — 27 short
```

The set of numbers is not broken. **Two terms are missing that `982` cannot contain by definition**:

```
513  identifier only, within 982
 15  both, within 982
 10  from the file's original `Product ID` column — not in the name cell at all
 17  ONE-line cells where the identifier trails after a `|` on the name line itself
     ("The Early Church Was the Catholic Church | 9781683572466")
───
555  ✓
```

The number **17** is the expensive one: it falls outside `982` **by the very definition of 982** — `982` counts
cells *with content beyond name+link*, and these 17 cells have only **one** line; the identifier shares the line
with the name, after a `|`.

So the correct statement is: **`982` is NOT the parent set of identifiers.** It is the parent set of the
*variant axis* (469 sits entirely inside it), but it holds only 528 of the 555 cells carrying an identifier.
The old numbers read as if `982` covered both — **that is exactly the illusion `536 + 525` created in the first
place, and it survived three rounds of fixes intact.**

This case is one level beyond the `13/13` case: `13/13` is a filtered denominator that **does not say what was
filtered** — it *hides information*. `982` is a denominator **believed to cover two things while covering one** —
it *creates a relationship that does not exist*, and a wrong relationship drags **every inference built on it**
with it, not just one number.

The relationship between `555` and `545` — **two sentences, two different reasons, and the second is the one
most easily mistaken for obvious in the whole table:**

```
545 codes extracted from the `Name Product` cell  +  10 from the original `Product ID` column  =  555 codes
555 codes = 555 cells     BECAUSE IT WAS MEASURED that every cell carries exactly ONE code ({1: 555})
```

The first sentence is addition. The second **cannot be derived** — it is a property of the data that has to be
measured: one cell carrying two ISBNs breaks the equality, and with this data that is entirely possible.
`545` and `555` share the **same unit (codes)** and differ in **source scope**, not in unit.

Version 3.14.0 left this spot as **a labelled empty box** saying *"no measurement yet"* instead of writing
*"555 cells correspond to 545 codes plus 10"*. That sentence is **true** — and would still have been invented,
because the one-cell-one-code property holding the whole sentence up had not been measured at the time.
**The same result, an entirely different value.** That is why a labelled blank beats a plausible relationship:
**do not write down what you have not measured, even when it is certainly true.**

This worked example once carried the very error it teaches you to catch. Versions 3.6.0–3.11.0 recorded
`536 / 525`, two numbers out of the **first survey script** — run before the invisible `U+200E` characters were
stripped and before 32 variant values with no axis name were caught. Wrong in **the same direction, from the
same cause**, exactly the signature this section describes. `/sdd-solo:verify` found it on its first real run —
while `536 + 525 ≠ 982` **should have caught it six versions earlier, with no verify needed.**

And `601 rows` next to `1006 values` is the *two denominators for the same thing* case: one cell saying
`Color: Brown | Dark Grey` is **one** axis row but **two** values. Paste one into the other's sentence and both
are real numbers, the sentence still reads well, and no comparison catches it — **always say which UNIT is being
counted.**

How to do it:

**A re-checkable number needs THREE things, and missing one means it rots silently:** *which data* (fingerprint) ·
*which command* (rule 5b) · *is that command still right for the current shape* (the structure assertion, below).
**The first two catch a wrong number; only the third catches a number that is right about a world that is gone.**

1. **Find every number describing real data** within the reading scope. A settled business number (a threshold,
   a deadline in a `RULE-###`) is **not** one of these — that is a decision, not a measurement.
2. **Each of those numbers must have a command that re-measures it.** None → **that is already a finding**:
   `F# the number <X> has no way to be re-measured → fix <file> to record the measuring command`. Do not invent
   a command and call it done; a command you thought up is not the command the author used.
3. **Run the command, compare the result.** Matches → say nothing. Differs → an `F#` with two sides: **A** is the
   verbatim line in the spec with `path:line`, **B** is **the command you just ran and its output today**. This
   is exactly the "quote both sides verbatim" rule; only side B is a command rather than a line in a file.
4. **A difference does not mean the spec is wrong.** The data may have changed, or the old command may have
   undercounted. Report both numbers and **do not conclude which one is right** — whoever knows the data decides.

   **A measuring command should print a fingerprint of the very data it reads**, and the spec records that
   fingerprint next to the table of numbers:

   ```
   Source: itemsell-flat.csv · 1986 rows · sha256 70daf43f · last modified 2026-09-09 22:22
   Measured at: 2026-09-09 22:26
   ```

   With a fingerprint, *"a difference does not mean the spec is wrong"* stops being a rule a person has to
   remember and becomes **a line the machine prints**: different fingerprint → the data changed; matching
   fingerprint but a different number → the spec is wrong or the command is wrong. Without one, every difference
   has to be guessed at from scratch.

   What a fingerprint **cannot** close, say so plainly in the `F#` when it comes up: it catches **the data**
   changing, **not the command** changing. Edit the measuring command so that it counts wrongly and the
   fingerprint still matches while the whole table rots the same direction — harder to see this time, because the
   document looks *as if it had been checked*. **A measuring command makes a number re-checkable; it does not
   make it right.**
4b. **The structure assertion: a measuring command must declare the shape it assumes, and check it before
   counting.** This is the third kind of rot, unlike the other two: not *the data changed*, not *the command is
   wrong*, but **the command is right about a world that is gone**. It runs cleanly and produces a perfectly
   plausible number — so no numeric comparison catches it. Real case: a count returned `132` instead of `215`
   because it only saw `|` characters on the same line as `Color:`; the regex was not wrong, **the structure it
   was counting did not exist yet**.

   How to block **half** of it: make the command declare its assumptions (which column must exist · what the axis
   separator is · whether cells still contain newlines), check them before counting, and **on a mismatch STOP and
   print no number at all**:

   ```
   itemsell-flat.csv no longer has the shape this command assumes — NOT counting,
   because a number counted on a changed structure looks exactly like a correct one:
     ✗ no Variant cell contains ' ; ' — the axis separator may have changed
   EXIT = 1
   ```

   This is the whole repo's founding principle applied at its narrowest point: **a wrong green is worse than no
   check**, so a measuring command that is not sure it is measuring the right thing should **stay silent, not
   guess**.

   The half that stays open, declared in full: the structure assertion catches **the data structure** changing. It
   does **not** catch someone editing both the command and its declared assumptions at once to match — at that
   point it is again a command that is right about a world that is gone, except the old world has just been
   rewritten to fit. **Three layers, and each only pushes the blind spot back one step rather than removing it.**
   Name the remaining blind spot; do not promise it is gone.

5. **Look hard at what a count cannot see.** This is where the real case above slipped: the old count was **not
   wrong as a formula**, it grepped `Color:`/`Size:` and correctly counted what it grepped. It slipped because two
   things are out of reach of any grep:
   - **invisible characters** (`U+200E`, `U+FEFF`, non-breaking space) stuck to a value — an ISBN with a leading
     `U+200E` **looks exactly like** an ordinary digit string;
   - **values with no label** — `Paperback`, `M | L | XL` are variant values carrying no axis name, so every count
     keyed on `<axis name>:` misses them.

   When a re-measured number differs from the one in the spec, ask first: *what can this count not see?*

6. **Several numbers from one source with no measuring command → ONE `F#`, not five.** Five identical red lines are
   what people learn to ignore fastest, and once they are ignored the sixth, quite different, line is ignored too.
   The right shape: *"5 numbers in `entities.md` (1459 names · 281 groups · 7 flag mismatches · 427 variants · 1559
   degenerate) all derive from `itemsell-flat.csv` and none has a measuring command"*. The phrase circles the right
   area, and **circling the right area is enough for whoever knows the data to go and check** — this role does not
   have to find the correct number itself.

7. **Look at the DIRECTION of the difference, not just whether there is one.** Several numbers all off in **one
   direction** is the signature of a shared source that has rotted, not of several unrelated mistakes. Real case
   (`runxops`): all five numbers **undercounted**, and all of them in the direction that made the problem look
   **smaller** than it was — `7 groups with stock-flag mismatches` was the number used to argue for splitting an
   entity, and it was 43% below the truth. State the direction in the `F#`: an argument standing on undercounted
   numbers can still be right, but whoever decides has to know what it is standing on.

8. **A number that looks implausible is a finding, even when it DOES have a measuring command.** A wrong command
   runs cleanly too. Real case: joining every variant row with ` | ` while ` | ` already meant *"several values on
   the same axis"* — `Color: Brown | Dark Grey` (one axis) read as two, and the count returned `437 rows with no
   axis name` instead of `32`. What caught it was **a number that looked implausible**, not any check. So: a number
   an order of magnitude away from others in the same document is a question, not something to copy.

   **And a TEST is a measurement too — an empty test looks exactly like a passing one.** Real case: a githook test
   returned `exit=0` on all three lines and concluded *"the hook lets it through, no problem"* — in fact it used
   `touch`, so **no file was staged** and the hook had nothing to check. Believing that result would have meant the
   issue never existed and the conclusion would have been **exactly backwards**. What caught it: three `exit=0`
   lines looking implausible next to an `exit 1` branch plainly visible in the code. So before believing a test,
   **print what it is actually measuring** — the staged file list, the number of input lines, the real path of the
   command.

9. **When fixing a number, KEEP the old one with the reason it differs; do not delete it.** *"1459 → 1388 (the old
   number grouped by `Product Name` while that column still had the variant axis stuck in it, so one product in two
   colours counted as two names)"* teaches far more than a bare `1388`: it says where the old measurement broke, so
   it does not break the same way next time. It is also the only thing left after the terminal is closed.

10. **A number that is RIGHT is still a finding, if it is a filtered denominator that does not say what was
   filtered.** The nine rules above all hunt **wrong** numbers; this one is different, and it is the only one step 3
   (*"matches → say nothing"*) will **miss**, because re-running produces exactly the same number.

   Real case (`runxops`): `RULE-004` claimed *"13/13 groups can be distinguished"*. Measured again: **13/13, exactly**.
   But the raw denominator is **16** — three groups were excluded because their key was a placeholder string
   (`Does not apply`, what eBay fills in when a seller leaves it blank). Excluding them is **the right decision**. The
   problem is that `13` alone hides **9 listings that cannot be grouped by any key at all** — and those nine are
   precisely the manual key-assignment work of `UC-009`, that is, the central pain of the whole BR.

   Ask two questions: *how much does this count throw away?* and *is what it throws away exactly the thing the
   document is discussing?* If yes → `F#`, even though the number is right to the letter.

   **What follows for the measuring command:** print **the raw and the filtered denominator together**, with what was
   filtered and why — do not print only the result. A ratio of `13/13` looks perfect; `16 raw → 3 placeholders
   removed → 13` tells the truth. Same family as the `437 / 32` case: what catches it is **a second number standing
   next to it**. The difference is that there the number looked implausible, while here **both look plausible** — so
   without a second number there is nothing to be suspicious of.

11. **A measuring command must ACTUALLY print the number it is attached to.** Check by running it and looking for that
   number in the output. Not there → **the label is wrong**, and a **wrong authenticity label is worse than none**:
   with no label the number looks unchecked, which is exactly what it is; with a wrong one it looks **as if it had
   been checked**.

   Real case (`runxops`): two numbers carried `python3 scripts/measure-catalog.py` as their measuring command, and that
   command **printed neither of them**. The person who attached the labels was the person who had just spent a day
   arguing that every number needs a measuring command.

   **The third part — cheaper than either of the other two: try the partition on BOTH sides.** One side adding up
   **proves nothing** — it only proves that side. **The side that breaks is the side that shows what the parent set
   really covers.** See the worked example above: one side matched neatly, the other was 27 short, and that shortfall
   is what revealed that the supposed parent set was not one.

   **The second part:** any number **claiming to be a partition** of another number **must add up**, and wherever it is
   presented, the addition must be **shown**. It does not add up → either a group is missing, or the groups overlap,
   or — most often — **they are not the same unit**. Machine-checkable, and cheaper than anything else on this list.

   This rule closes the gap **the other three layers cannot reach**: the fingerprint asks *which data* · rule 5b asks
   *which command* · the structure assertion asks *is the command still right for the shape* — all three **assume the
   command and the number are a correct pair**, and none of them checks that pair. It is cheap and machine-checkable.

## The stop rule — blocking or wording debt (6.3.0, #49)

Every `F#` carries **one of two levels**, written right after the number. The owner settled this after six re-reads
of UC-014 in runxops (19 → 23 → 11 → 7 → 7 → 10 findings, each round of fixes exposing new wording or labels in
neighbouring files): *repeat until **blocking = 0***, and only two things block.

| Level | What it is | After applying |
|---|---|---|
| **blocking** | (a) **two places contradicting each other about behaviour** — Main Flow · Alternative · Exceptions · Postconditions · AC · flow · a RULE statement · an entity's state/class diagram saying opposite things; (b) **an AC that cannot be tested** — Given/When/Then missing a measurable half, or promising something no step produces (kind #6) | must be verified again (`--since`) |
| **wording debt** | labels, names, headings, counts inside headings, `Applies to`, the glossary, a prose sentence repeating a decision that changed, a neighbouring file missing from a commit message (#42) — once fixed, **no** behaviour is different | apply directly; the gate passes with no re-verification |

The one-sentence test: *once this is fixed, which test has to be written differently, or what does the customer see
differently?* Yes → blocking. No → wording debt. Unsure → **blocking** (one extra read is cheaper than a wrong AC
reaching the code). Kind #7 (a rotted number) is blocking when the number stands in a RULE/AC, wording debt when it
stands in Background or a note.

## Output

A list of `F#`, **blocking first, wording debt after**, and within each level ordered by consequence (money ·
permissions · customer data first). One counted line at the end of the report:
`<n> findings · <m> blocking · <k> wording debt`. Each line:

```
F1 [blocking] <the finding in one sentence>
   A: <path:line> "<verbatim>"
   B: <path:line> "<verbatim>"
   [anchor: Main 7 · RULE-003]
   → output: ___
F2 [wording debt] <the finding in one sentence>
   …
```

`output: ___` is for **whoever decides** to fill in; do not fill it in yourself.

**Running in the multi-agent model** (`/sdd-solo:orchestrate`, with role R grading): give each `F#` the three lines of
the `notes/hoi-dap/hoi-dap.md` ticket skeleton — `Already looked up: <file:line>` · `If chosen wrong: <consequence>` ·
`The agent leans towards: <option + why>` — so R can grade L0–L3 without translating it again (#39).

## Limits — stated plainly, not hidden

1. **The reason to reject must come from the person READING the findings, not from the person who WROTE the spec.**
   Handing verify a list of *"context to help you reject quickly"* written by the spec's author takes away its
   standing: it will reject exactly those findings the author already has an answer for — that is, exactly the places
   the author believes they are not wrong. Real case: such a list was refused, and **two of its items landed in the
   "matches / already rejected" group by verify's own measurement** — evidence that exists only **because** it did not
   listen.

2. **It produces false positives.** That is the price of reading meaning rather than counting. So **rejecting a finding
   must be cheap** — one line `→ false positive because <reason>` is enough, and **that reason is recorded**, so the
   next run does not dig up the same sentence again.
3. **"Found nothing" is weak evidence.** Never print anything that sounds like a guarantee — no *"the documents are
   consistent"*, no *"everything was checked"*. The one sentence allowed is: *"this reading found nothing within the
   scope read"*, together with **a list of the scope read**.
4. **Cost grows with the tree.** A 2,000-line tree can be read whole; a 20,000-line one cannot. When the tree is large,
   narrow the scope to **what just changed** (`git diff` since the last verify) plus every file whose IDs it cites —
   do not skim the whole tree, because skimming is the surest way to miss kinds 3 and 4.
