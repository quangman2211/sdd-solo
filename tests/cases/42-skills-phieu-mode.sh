# 7.3: bốn skill còn hỏi có chế độ phiếu; close/gate nói rõ không giao agent
for s in start design intake deprecate; do
  chk "skill $s có 'Chế độ phiếu (7.3)'" 'grep -q "Chế độ phiếu (7.3)" "$P/skills/$s/SKILL.md"'
done
chk "close · gate: không giao agent" 'grep -q "Không giao agent" "$P/skills/close/SKILL.md" && grep -q "Không giao agent" "$P/skills/gate/SKILL.md"'
chk "scaffold KEEP có role phieu queue hoi-check" 'for x in role.sh phieu.sh queue.sh hoi-check.sh; do grep -qE "^KEEP=\".*[\" ]$x[\" ]" "$P/scripts/scaffold.sh" || exit 1; done'
nr keep
chk "bản sao .sdd/scripts/ có bốn script mới" '[ -x .sdd/scripts/role.sh ] && [ -x .sdd/scripts/phieu.sh ] && [ -x .sdd/scripts/queue.sh ] && [ -x .sdd/scripts/hoi-check.sh ]'
