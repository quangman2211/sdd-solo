# I-8: design-check coi quy ước đường dẫn `<core|nghề>` trong architecture.md là placeholder
nr i8
node - <<'JS'
const fs = require('fs');
const p = 'specs/architecture.md';
let s = fs.readFileSync(p, 'utf8');
s = s.replace(/<!--[\s\S]*?-->/g, '');
s = s.replace(/^<[^`\n]*$/gm, '');          // dòng placeholder mở đầu bằng <
s = s.replace(/^\*\*Status:\*\* draft[\s\S]*?(?=## Ngăn xếp)/, '**Status:** draft\n**Last updated:** 2026-01-01\n\n');
s = s.replaceAll('## Ngăn xếp\n', '## Ngăn xếp\nNode 20. Test: `tests/use-cases/<core|nghề>/UC-###/AC-#.test.ts`.\n');
s = s.replaceAll('## Nơi chạy\n', '## Nơi chạy\nServer mình dựng.\n');
s = s.replaceAll('## Ai gọi\n', '## Ai gọi\nCron mỗi phút.\n');
s = s.replaceAll('K["<ai gọi>"] --> A["<lối vào: CLI · API · MCP>"]', 'K["cron"] --> A["CLI"]').replaceAll('P1["Port: <tên>"] --> X1["Adapter: <thứ thật bên ngoài>"]', 'P1["Port: Notify"] --> X1["Adapter: Telegram"]');
s = s.replace(/^## Cấm\n[\s\S]*?(?=^## )/gm, '## Cấm\n- không gọi API sàn — vì tài khoản cá nhân\n  - Từ: 2026-01-01 · Trạng thái: active\n\n');   // cả lời giảng + dòng ví dụ của khuôn
s = s.replaceAll('## Đã chốt từ brief\n', '## Đã chốt từ brief\n- không có\n');
fs.writeFileSync(p, s);
JS
printf '# Design UC-001\n\n## Ngăn xếp\nNode\n' > "$UCD/design.md"
S design-check.sh UC-001
chk "I-8 · architecture.md có \`<core|nghề>\` trong nháy mã không bị coi là placeholder" '! has "architecture.md còn placeholder"'
