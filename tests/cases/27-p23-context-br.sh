# P-23: context.sh không nhận BR-###
nr p23
S context.sh BR-001
chk "P-23 · context.sh BR-001 chạy được (được exit $R)" '[ $R = 0 ]'
