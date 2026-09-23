# I-8: design-check coi quy ước đường dẫn `<core|craft>` trong architecture.md là placeholder
nr i8
node - <<'JS'
const fs = require('fs');
const p = 'specs/architecture.md';
let s = fs.readFileSync(p, 'utf8');
s = s.replace(/<!--[\s\S]*?-->/g, '');
s = s.replace(/^<[^`\n]*$/gm, '');          // dòng placeholder mở đầu bằng <
s = s.replace(/^\*\*Status:\*\* draft[\s\S]*?(?=## Stack)/, '**Status:** draft\n**Last updated:** 2026-01-01\n\n');
s = s.replaceAll('## Stack\n', '## Stack\nNode 20. Test: `tests/use-cases/<core|craft>/UC-###/AC-#.test.ts`.\n');
s = s.replaceAll('## Runs where\n', '## Runs where\nServer mình dựng.\n');
s = s.replaceAll('## Callers\n', '## Callers\nCron mỗi phút.\n');
s = s.replaceAll('K["<caller>"] --> A["<entry point: CLI · API · MCP>"]', 'K["cron"] --> A["CLI"]').replaceAll('P1["Port: <name>"] --> X1["Adapter: <the real outside thing>"]', 'P1["Port: Notify"] --> X1["Adapter: Telegram"]');
s = s.replace(/^## Forbidden\n[\s\S]*?(?=^## )/gm, '## Forbidden\n- no marketplace API calls — because the account is personal\n  - From: 2026-01-01 · State: active\n\n');   // cả lời giảng + dòng ví dụ của khuôn
s = s.replaceAll('## Settled from brief\n', '## Settled from brief\n- none\n');
fs.writeFileSync(p, s);
JS
printf '# Design UC-001\n\n## Stack\nNode\n' > "$UCD/design.md"
S design-check.sh UC-001
chk "I-8 · architecture.md có \`<core|craft>\` trong nháy mã không bị coi là placeholder" '! has "architecture.md còn placeholder"'
