# 7.3: bốn skill còn hỏi có chế độ phiếu; close/gate nói rõ không giao agent
for s in start design intake deprecate; do
  chk "skill $s có 'Ticket mode (7.3)'" 'grep -q "Ticket mode (7.3)" "$P/skills/$s/SKILL.md"'
done
# 8.4.0 (P-52): mặc định vẫn là việc của chủ dự án, nhưng không còn tuyệt đối — repo khai `<vai>.ky` thì vai đó
# ký được, và pass.sh tự chạy phép kiểm trước khi đóng dấu. Ca giữ cả hai vế: mặc định, và ai cấp quyền.
chk "close · gate: mặc định vẫn là việc của chủ dự án" \
  'grep -q "job unless the repo says otherwise" "$P/skills/close/SKILL.md" && grep -q "job unless the repo says otherwise" "$P/skills/gate/SKILL.md"' 
chk "close · gate: nêu cửa uỷ quyền và ai cấp nó" \
  'grep -q "\.ky" "$P/skills/gate/SKILL.md" && grep -q "uy-quyen.md" "$P/skills/gate/SKILL.md" && grep -q "out of the coordinator" "$P/skills/gate/SKILL.md"' 
chk "scaffold KEEP có role phieu queue hoi-check" 'for x in role.sh phieu.sh queue.sh hoi-check.sh; do grep -qE "^KEEP=\".*[\" ]$x[\" ]" "$P/scripts/scaffold.sh" || exit 1; done'
nr keep
chk "bản sao .sdd/scripts/ có bốn script mới" '[ -x .sdd/scripts/role.sh ] && [ -x .sdd/scripts/phieu.sh ] && [ -x .sdd/scripts/queue.sh ] && [ -x .sdd/scripts/hoi-check.sh ]'
