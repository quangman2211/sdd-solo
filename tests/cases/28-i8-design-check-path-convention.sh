# I-8: design-check coi quy ước đường dẫn `<core|nghề>` trong architecture.md là placeholder
nr i8
python3 - <<'PY'
import io, re
p = 'specs/architecture.md'; s = io.open(p, encoding='utf-8').read()
s = re.sub(r'(?s)<!--.*?-->', '', s)
s = re.sub(r'(?m)^<[^`\n]*$', '', s)          # dòng placeholder mở đầu bằng <
s = re.sub(r'(?s)^\*\*Status:\*\* draft.*?(?=## Ngăn xếp)', '**Status:** draft\n**Last updated:** 2026-01-01\n\n', s)
s = s.replace('## Ngăn xếp\n', '## Ngăn xếp\nNode 20. Test: `tests/use-cases/<core|nghề>/UC-###/AC-#.test.ts`.\n')
s = s.replace('## Nơi chạy\n', '## Nơi chạy\nServer mình dựng.\n')
s = s.replace('## Ai gọi\n', '## Ai gọi\nCron mỗi phút.\n')
s = s.replace('K["<ai gọi>"] --> A["<lối vào: CLI · API · MCP>"]', 'K["cron"] --> A["CLI"]').replace('P1["Port: <tên>"] --> X1["Adapter: <thứ thật bên ngoài>"]', 'P1["Port: Notify"] --> X1["Adapter: Telegram"]')
s = s.replace('## Cấm\n', '## Cấm\n- không gọi API sàn — vì tài khoản cá nhân\n  - Từ: 2026-01-01 · Trạng thái: active\n')
s = s.replace('## Đã chốt từ brief\n', '## Đã chốt từ brief\n- không có\n')
io.open(p, 'w', encoding='utf-8').write(s)
PY
printf '# Design UC-001\n\n## Ngăn xếp\nNode\n' > "$UCD/design.md"
S design-check.sh UC-001
xfail I-8 "architecture.md có \`<core|nghề>\` trong nháy mã không bị coi là placeholder" '! has "architecture.md còn placeholder"'
