# Self-review — five questions (section 6.4 of the book, solo edition)

Do this before committing a feat. Read the spec first, the code after.

1. **Spec first:** Is the flow clear? Are the ACs testable? Does any exception miss an obvious case?
2. **Trace:** Does the commit carry a UC ID? Does the docs commit for the same UC come first?
3. **Test ↔ AC:** Does every AC have a test? If an important AC has none, where is the reason written?
4. **Hidden rules:** Is there a number, an enum or a condition in the code that the spec never states? (grep)
5. **Who decided, the AI or me?** Where did this complicated piece of logic come from? A technical decision worth remembering → one line in `specs/decisions.md`; heavy enough → an ADR.
