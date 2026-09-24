# 8.6.0 — P-58 · P-57 · P-59, plus the role name a coordinator actually sets.
#
# P-58: there were TWO readers of one KETQUA line and they disagreed. `queue.sh done` used `grep -oE 'ket=[a-z]+'`,
# which prints EVERY match, so a kiem= quoting another role's `ket=xong` made KET two lines and done refused with
# "xong, not xong"; `board` read the same line with a `*ket=xong*` glob and said "✓ KETQUA says xong". Measured at
# runxops on KETQUA b-032-ap-232 at 20:31. The fix is one reader (kq_field), not two careful ones.
nr kqf
H="$(git rev-parse HEAD)"
S queue.sh add b-032-ap-232 spec B
S queue.sh take b-032-ap-232
S role.sh --ketqua b-032-ap-232 ket=xong "neo=$H" "kiem=gate:0đ · N7: R ket=xong nợ chữ · T ket=chan"
chk "a KETQUA whose kiem= quotes another ket= is accepted (exit $R)" '[ $R = 0 ]'
S queue.sh board
chk "board: reads the ket= FIELD, so it says xong" 'has "says xong"'
S queue.sh done b-032-ap-232
chk "done: reads the same field, so it agrees — no 'xong, not xong' (P-58) (exit $R)" \
  '[ $R = 0 ] && ! has "not xong"'
chk "the row is done, anchored to the real hash" 'grep -E "^\| *b-032-ap-232 *\|" notes/hang-doi.md | grep -q "'"$H"'"'
# the other direction: a blocked KETQUA whose kiem= quotes an old ket=xong must NOT read as done
nr kqf2
S queue.sh add b2 spec B; S queue.sh take b2
S role.sh --ketqua b2 ket=chan hoi=#7 "kiem=lần trước ket=xong rồi"
S queue.sh board
chk "board: chan stays chan, the quoted ket=xong does not win" 'has "blocked" && has "hoi=#7" && ! has "says xong"'
S queue.sh done b2
chk "done: refuses, and names the real value (exit $R)" '[ $R = 1 ] && has "ket=chan"'

# (b) SDD_ROLE as a coordinator sets it: "<role> <job> <model>". The role is the first token.
chk "SDD_ROLE='R soi opus' → role R" \
  '[ "$(SDD_ROLE="R soi opus" bash -c ". \"$P/scripts/lib.sh\"; role_current \"$PWD\"")" = R ]'
O="$(SDD_ROLE='R soi opus' SDD_STAGED='specs/core/uc.md' bash "$P/scripts/role.sh" --staged 2>&1)"
chk "the commit hook path no longer says the role is not in .sdd/roles" \
  '! printf "%s" "$O" | grep -q "is not in .sdd/roles"'

# P-59: the Stop hook. Silent unless a role is holding an unreported job; blocks once; lets go the second time.
nr stop
chk "no role inferred → the Stop hook says nothing at all" \
  'O="$(echo "{\"stop_hook_active\":false}" | bash "$P/scripts/stop-ketqua.sh" 2>&1)"; [ -z "$O" ]'
S queue.sh add b-hold spec B
S queue.sh take b-hold B
O="$(echo '{"stop_hook_active":false}' | SDD_ROLE=B bash "$P/scripts/stop-ketqua.sh" 2>&1)"
chk "holding a job with no KETQUA → blocks, and names the job" \
  'printf "%s" "$O" | grep -q "\"decision\":\"block\"" && printf "%s" "$O" | grep -q "b-hold"'
chk "the block prints the exact --ketqua line to write" 'printf "%s" "$O" | grep -q -- "--ketqua b-hold ket=xong"'
chk "the reason is one JSON string — no raw newline breaks it" \
  'printf "%s" "$O" | node -e "let s=\"\";process.stdin.on(\"data\",d=>s+=d).on(\"end\",()=>{JSON.parse(s)})"'
O2="$(echo '{"stop_hook_active":true}' | SDD_ROLE=B bash "$P/scripts/stop-ketqua.sh" 2>&1)"
chk "second attempt: warns on stderr, does not block" \
  '! printf "%s" "$O2" | grep -q "block" && printf "%s" "$O2" | grep -q "b-hold"'
S role.sh --ketqua b-hold ket=chan hoi=#3
chk "once the KETQUA is there, silent again" \
  'O="$(echo "{\"stop_hook_active\":false}" | SDD_ROLE=B bash "$P/scripts/stop-ketqua.sh" 2>&1)"; [ -z "$O" ]'

# P-57: --don never forces, names the lane stashes without dropping them; done says whether a lane is finished
chk "--don refuses --force by name instead of ignoring it" \
  'O="$(bash "$P/scripts/role.sh" --don UC-012 --force 2>&1)"; printf "%s" "$O" | grep -q "no --force"'
S queue.sh add b-uc-012 spec B
S queue.sh take b-uc-012
S role.sh --ketqua b-uc-012 ket=xong "neo=$H"
S queue.sh done b-uc-012
chk "done on the last item of UC-012 looks at the lane, read-only" 'has "UC-012 has no open item left"'
chk "and prints the command instead of running it" 'has -- "--don UC-012"'

# the third reader of the same line: the session brief. It blocks nothing, so nobody would have reported it.
nr ss
S queue.sh add b-ss spec B; S queue.sh take b-ss
S role.sh --ketqua b-ss ket=xong "neo=$(git rev-parse HEAD)" "kiem=R said ket=chan earlier"
O="$(SDD_ROLE=B bash "$P/scripts/session-start.sh" 2>&1)"
# Two matches make the value "xong\nxong", which splits the brief line in two: the word then appears on a line of
# its own. Counting the lines that carry it is the test grep can actually perform.
chk "session-start reads the ket= field too - one value, not two" \
  'printf "%s" "$O" | grep -q "b-ss=xong" && [ "$(printf "%s" "$O" | grep -c xong)" = 1 ]'
