# Adversarial pass — run it in a FRESH session, not the one that wrote the spec

Two sets of roles: the **UC layer** asks about behaviour, the **BR layer** asks about the reason for
existing. Do not mix them.

Paste the glossary + the relevant rules + the UC. Run three roles, one pass each. The AI may only ASK.

---
Read the use case below in the role of **<ROLE>**. Your only job: list the questions the spec does not
answer, the rules that are "obvious to anyone in this business" but are not written down, and the places
where the message to the customer is hard to understand.

Constraints:
- Do not propose code. Do not propose architecture. Do not edit the spec.
- One question per line, naming the step/E#/AC it relates to.
- Do not repeat what the spec already says. No praise.
- At most 12 questions, ordered by what it costs to miss them (money / permissions / customer data first).

Roles:
1. **End customer** — a business or marketing person, not technical, in a hurry. Asks: where do I not know what to do next? which message can I not read? where do I find that?
2. **Operations / accounting** — the person answering tickets and reconciling money. Asks: which "everyone knows that" rule is not written down? on a refund / expiry / plan change, what happens to what? which data do I answer the customer with?
3. **Abuser** — wants more than they paid for. Asks: what if I click twice? what if two requests arrive at once? what if I change the data on the client? what happens exactly at the boundary value?

<paste UC-###.md>
---

Running in the multi-agent model (`/sdd-solo:orchestrate`, with role R): give each question the three
skeleton lines of `notes/hoi-dap/hoi-dap.md` — `Already looked up` · `If chosen wrong` · `The agent leans
towards` — so R can grade it without translating it again (#39).

Valid outputs for each question (written into the UC, section Adversarial pass):
- Answered in the spec → add a RULE / AC / E# / SCR, History v+1
- Cannot be decided yet → `## Open Questions` with an interim decision
- Not part of v1 → the BR's Out of Scope
There is no "leave it" output.

---

# The three BR-layer roles — for `/sdd-solo:adversarial BR-###`

Paste the slice's whole `br.md` (`specs/<core|craft>/br-###/br.md`) and the `## Do not narrow` section of
`specs/vision.md`. Run three roles, one pass each. The AI may only ASK.

---
Read the business requirement below in the role of **<ROLE>**. Your only job: list the questions the BR
does not answer, the places where it asserts something with no source, and the places where it describes a
solution instead of a problem.

Constraints:
- Do not propose solutions. Do not propose features. Do not edit the spec.
- One question per line, **with a source label in square brackets**: which section of the BR produced this
  question — `[Background]` · `[Success Metrics]` · `[Out of Scope]` · `[CON-002]` · `[Impact Map]`.
  The UC roles required the label from the start and landed 24 out of 24; the BR roles did not, so 36 of 40
  questions left hanging in `br.md` could not be traced back to anything. That label is what lets you paste
  the spec's exact words when you put a question to whoever decides.
- Do not repeat what the BR already says. No praise.
- At most 8 questions per role, ordered by what it costs to miss them.

Roles:
1. **The one who pays** — the person spending money and time on this. Asks: why is this worth doing
   **before** something else? what does doing nothing cost, **measured how**? where did the baseline number
   in Background come from? once this Success Metric is measured, who reads it, and to decide what?
2. **The one who will operate it forever** — the person on ticket duty who fixes it at midnight. **Required
   question, asked first (#47): *"once v1 is done, what do you open every day to do your work? what can you
   change yourself without a developer?"* — compare the answer against In Scope; if In Scope does not
   contain that "thing you open every day", the scope is cut wrong.** Then: who is on the hook at 2am? what
   in today's Out of Scope comes back as a ticket next week? how much manual work per month does this
   create? who handles data that was wrong on the way in?
   Real runxops case: BR-003 v2.x said *"v1 has no human step on runX"*, inferred from one narrow sentence;
   then the owner said *"of course there has to be an app to manage it… it is only an MVP if the features
   are all there"* → overturned, and a management app M1–M8 went into v1. Three roles had run; nobody asked
   this question.
3. **The sceptic** — the person who does not believe anything needs building. **Read the
   `**Why still build:**` line in Background first; if it says "no reason yet", that is your question
   number one.** Then: is there a way to reach the Goal **without writing software** (buy one, change the
   process, hire someone, do it by hand in batches)? Is this really a BR, or a solution already chosen and
   written backwards into a reason? If this BR were deleted outright, who would complain, and how soon?

<paste the BR-### section of br.md>
---

Valid outputs for each question (written into the BR's `## Adversarial pass`):
- Has a number and a source → `## Background`
- Cannot be decided yet → `## Open Questions` with an interim decision
- Not in this release → `## Out of Scope` + a `-.->` branch on the Impact Map
- It is a constraint → a new `CON-###`
There is no "leave it" output.

**If the sceptic concludes the BR is a solution written backwards into a reason — stop, say exactly what the
BR would shrink from and to (`br-scope-diff.sh BR-###` prints the added/removed lines of In Scope · Out of
Scope), ask the owner, and only then rewrite.** All three roles also read `## Do not narrow` in
`specs/vision.md`: any question that would push an item from there into Out of Scope must output "ask the
owner", not "shrink the BR" (7.0).
Do not record it as an Open Question and move on: every UC born from that BR inherits the same mistake.
