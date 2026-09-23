# P-15: close-check tìm code theo commit (UC-###) chứ không theo slug
nr close15
mkdir -p src/core/session tests/core/session
printf 'export const TTL = { maxAge: 900 };\n// thời hạn: 900 giây\n' > src/core/session/token.ts
printf 'import {TTL} from "../../../src/core/session/token";\nexpect(TTL.maxAge).toBe(900);\n' > tests/core/session/token.test.ts
cm "feat(UC-001): phiên đăng nhập"
printf 'export const retry = { max: 5 };\n' > src/other.ts
git add -A; git commit -q --no-verify -m "fix: khác" -m "nhắc (UC-001) trong thân"
S close-check.sh UC-001
chk "tìm được code theo commit (1 file)" 'has "the code of UC-001: 1 files — 1 touched by a"'
chk "literal maxAge: 900 được soi" 'has "src/core/session/token.ts:1:"'
chk "bỏ chú thích, bỏ test, bỏ commit chỉ nhắc ID ở thân" '! hasE "token.ts:2:|token.test|other.ts"'
chk "không đỏ 'không đọc được file code'" '! has "no code file can be read"'
