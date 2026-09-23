# ASK from role <V> · <role name>

<!-- ADDRESSED question log (7.3). Four boxes filled by the asking role, one box answered by the
     coordinator/arbiter. Open an entry with
     `bash .sdd/scripts/phieu.sh hoi <V> "<one-line question>"` — it allocates ASK-<V>n and copies
     the skeleton. Check: `hoi-check.sh <V>`.
     Rule: the coordinator answers into design.md / specs/decisions.md and does NOT edit the
     question text; the body of a UC reopens only when an AC changes (once the gate is open, a
     `target:` pointing into the body of UC-### makes hoi-check red). Changing the question means
     opening a new ASK that says "replaces ASK-<V>n". -->

### ASK-<V>1 · <one-line question> — YYYY-MM-DD
- **Source:** <file:section already looked up — UC-### ## AC-#, RULE-###, design.md ## …>
- **Blocking:** <blocking | not blocking> — <why: which case cannot be written until this is answered>
- **Doing while waiting:** <another case · a stated assumption marked "GUESS" in the code · stopped>
- **Spec work when answered:** <RULE-### parameter line … · UC-### Open Question ticked [x] · design.md ## …>
- **Answer (A/R):** <leave empty> · **target:** <design.md ## … | specs/decisions.md | UC-### AC-# (only when an AC changes)>
