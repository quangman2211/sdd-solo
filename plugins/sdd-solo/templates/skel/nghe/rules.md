# Business Rules — <craft>

Rules for this craft only. Cross-cutting rules live in the root `specs/rules.md`. **IDs never
collide with the root**: one `RULE-###` sequence for the whole project; `id_exists` looks in the
root and then in every `specs/<craft>/rules.md`, and a repeated number is red at the gate.

## RULE-###: <rule name>
- **Statement:** <one sentence, checkable>
- **Applies to:** UC-###
- **Exceptions:** <none | ...>
- **Source:** BR-### · CON-### · <who said it, when>
