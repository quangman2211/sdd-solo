# P-52 (8.4.0): pass.sh KHÔNG kiểm gì — đầu file ghi "run AFTER the matching check exits 0", nó tin người gọi.
# Nên `pass.sh gate UC-###` đóng dấu .sdd/gate/UC-###.ok lên một UC đỏ rực, và githook commit-msg tin cái dấu đó.
# Thứ giữ marker trung thực tới 8.3.0 là VĂN SKILL, không phải phím bấm của chủ dự án.
nr passk
# ── làm UC-001 đỏ: xoá mục Acceptance Criteria ──
node -e 'const f=require("fs"),p=process.argv[1];f.writeFileSync(p,f.readFileSync(p,"utf8").replace(/^## Acceptance Criteria[\s\S]*?(?=^## )/m,""))' "$UC1"
cm "docs(UC-001): bỏ AC" 2026-01-06
S gate-check.sh UC-001
chk "dựng được trạng thái đỏ thật (exit $R)" '[ $R = 1 ]'
S pass.sh gate UC-001
chk "pass.sh gate TỪ CHỐI khi gate-check đỏ (P-52) (exit $R)" '[ $R != 0 ]'
chk "không đóng dấu marker lên UC đỏ — githook tin cái dấu này" '[ ! -f .sdd/gate/UC-001.ok ]'
chk "nói rõ phải chạy gì" 'has "gate-check.sh"'
# ── xanh trở lại thì qua như cũ ──
nr passk2
S gate-check.sh UC-001
chk "UC-001 nền là xanh (exit $R)" '[ $R = 0 ]'
S pass.sh gate UC-001
chk "gate-check xanh → pass.sh gate chạy như cũ (exit $R)" '[ $R = 0 ] && [ -f .sdd/gate/UC-001.ok ] && has "THROUGH THE GATE"'
# ── ai được ký: vắng mọi dòng .ky thì y hệt hôm nay ──
nr passk3
printf 'A\n' > "$(git rev-parse --git-path sdd-role)"
S pass.sh gate UC-001
chk "có dấu vai nhưng repo chưa khai .ky nào → không đổi hành vi (exit $R)" \
  '[ $R = 0 ] && [ -f .sdd/gate/UC-001.ok ]'
# ── khai .ky → chữ ký thành một quyền có khai báo ──
nr passk4
printf 'B\n' > "$(git rev-parse --git-path sdd-role)"
printf 'A.ky=gate close\n' >> .sdd/roles
S pass.sh gate UC-001
chk "vai B không có .ky → TỪ CHỐI ký, nói tên vai (exit $R)" \
  '[ $R != 0 ] && [ ! -f .sdd/gate/UC-001.ok ] && has "B" && has "ky"'
printf 'A\n' > "$(git rev-parse --git-path sdd-role)"
S pass.sh gate UC-001
chk "vai A có .ky=gate → ký được (exit $R)" '[ $R = 0 ] && [ -f .sdd/gate/UC-001.ok ]'
chk "marker ghi ai ký, để sáu tháng sau còn biết" 'grep -q "A" .sdd/gate/UC-001.ok && [ "$(head -1 .sdd/gate/UC-001.ok | wc -c | tr -d " ")" = 41 ]'
chk "commit của cổng mang dòng ai ký (đuôi Vai:)" \
  'git log --format=%B -20 | grep -qE "^(Vai|Role): A$"'
chk "dòng chủ đề commit KHÔNG đổi — gate-check §9 và githook nhận commit theo chủ đề" \
  'git log --format=%s -20 | grep -q "docs(UC-001): spec reviewed"'

