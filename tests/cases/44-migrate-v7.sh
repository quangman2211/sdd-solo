# migrate.sh — tới 7.5.0 KHÔNG có ca test nào, trong khi nó là script duy nhất dời cây thật của người ta
# (75 phép dời trên runxops) và là script khó hoàn tác nhất. Ca này dựng một repo 6.x thu nhỏ có đủ mặt
# từng nhánh: context → nghề, br.md → lát, internal/ → gốc + notes/, entities.md → mỗi entity một file,
# rules/glossary theo nghề, test UC dời theo nghề, đường dẫn trong code được sửa, index trả về trống (#57).
# 7.6.0: cả hai khối của migrate.sh chuyển từ python sang js/migrate.mjs — đối chiếu bản python 7.5.0 và
# bản node trên bản sao runxops 6.x cho đầu ra khớp TỪNG BYTE và cây khớp hoàn toàn (CHANGELOG 7.6.0).

# mk6x <tên> — dựng repo 6.x thu nhỏ trong $W/<tên>, cd vào
mk6x() {
  rm -rf "$W/$1"; mkdir -p "$W/$1"; cd "$W/$1" || exit 1
  export CLAUDE_PROJECT_DIR="$W/$1"
  git init -q; git config user.email test@sdd; git config user.name sdd-test; git config commit.gpgsign false
  mkdir -p .sdd specs/contexts/orders/use-cases/UC-001-notify-order specs/contexts/console \
           specs/internal/adr tests/use-cases/orders/UC-001 src/orders
  printf 'code_paths=src\ntest_paths=tests\nuc_test_dir=tests/use-cases\n' > .sdd/config
  cat > specs/br.md <<'EOF'
# Business Requirements

Mỗi BR một mục.

# BR-001: Báo đơn mới

## Metadata
- **Status:** approved
- **Last updated:** 2026-01-02

## Goal
Đơn mới về thì có người biết.

## Background
### Số đo tháng 9
Trong 1.986 ô thì 982 ô có nhiều hơn một dòng, nên đếm dòng không ra số đơn.
Đoạn chứng cứ dài thứ hai, cũng là dấu vết.

**Vì sao vẫn xây:** vì không ai ngồi canh trang đơn cả ngày.

## Related Use Cases
| UC | Tên | Actor | BR | Status |
|---|---|---|---|---|
| UC-001 | Báo đơn | Hệ thống | BR-001 | implemented |

## Adversarial pass
- Ngày chạy: 2026-01-03 · 3 vai · trên v2
- Q1 đơn trùng thì sao → gộp theo mã đơn
- Q2 đơn huỷ thì sao → `___`

# BR-002: Bảng điều khiển

## Metadata
- **Status:** draft
- **Last updated:** 2026-01-02

## Goal
Xem được trạng thái chạy.
EOF
  cat > specs/contexts/orders/use-cases.md <<'EOF'
# Use Cases — orders

| UC | Tên | Actor | BR | Status |
|---|---|---|---|---|
| UC-001 | Báo đơn | Hệ thống | BR-001 | implemented |
| UC-009 | Gộp đơn | Hệ thống | BR-001 | draft |
EOF
  cat > specs/contexts/orders/entities.md <<'EOF'
# Entities — orders

## Domain Model
Hai thực thể, một quan hệ.

## `Order` — đơn hàng
- **id**: mã đơn
- **state**: new | sent

## `Channel` — kênh bán
- **name**: tên kênh
EOF
  cat > specs/contexts/orders/use-cases/UC-001-notify-order/UC-001.md <<'EOF'
# UC-001: Báo đơn

## Metadata
- **Status:** implemented
- **Bounded Context:** orders
- **Liên quan tới BR:** BR-001

## Main Flow
1. Đơn về → gửi tin.
EOF
  printf '# Use Cases — console\n\n| UC | Tên | Actor | BR | Status |\n|---|---|---|---|---|\n' \
    > specs/contexts/console/use-cases.md
  printf '# Entities — console\n\n## Domain Model\nChưa có.\n' > specs/contexts/console/entities.md
  printf '# Architecture\nMột tiến trình.\n' > specs/internal/architecture.md
  printf '# Decisions\n- 2026-01-02: chọn node\n' > specs/internal/decisions.md
  printf '# ADR-001: hình của plugin\n' > specs/internal/adr/ADR-001-hinh-cua-plugin.md
  printf '# Hỏi đáp\n- Q1 → A1\n' > specs/internal/hoi-dap.md
  cat > specs/rules.md <<'EOF'
# Business Rules

## RULE-001: đơn trùng mã thì gộp
Gộp theo mã đơn.

## RULE-009: chưa xếp nghề
Để lại ở gốc.
EOF
  cat > specs/glossary.md <<'EOF'
# Glossary

## orders
- **Đơn** (`Order`): một lần mua.
- **Kênh** (`Channel`): nơi bán.

## History
- 2026-01-02: khai sinh
EOF
  printf 'export const notify = () => 1;  // xem specs/contexts/orders/use-cases/UC-001-notify-order/UC-001.md\n' \
    > src/orders/notify.js
  printf 'import { fakes } from "../use-cases/orders/UC-001/fakes";\ndescribe("UC-001", () => {});\n' \
    > tests/use-cases/orders/UC-001/AC-1.test.js
  printf 'export const fakes = {};\n' > tests/use-cases/orders/UC-001/fakes.js
  git add -A
  GIT_AUTHOR_DATE=2026-01-02T10:00:00 GIT_COMMITTER_DATE=2026-01-02T10:00:00 \
    git commit -q --no-verify -m "chore: repo 6.x"
}
mkmap() { printf 'context orders ebay\ncontext console core\nbr BR-001 ebay\nbr BR-002 core\nrule RULE-001 ebay\n' > .sdd/migrate-v7.map; }

# ① không có map → đỏ, và nói rõ phải viết gì, không dời gì cả
mk6x mig1
S migrate.sh --layout v7
chk "migrate · không có map thì đỏ, không đụng đĩa (exit $R)" \
  '[ $R = 1 ] && has "viết file map trước" && [ -d specs/contexts ]'

# ② map thiếu một dòng → kê đích danh chỗ thiếu, KHÔNG CHẠY
printf 'context orders ebay\nbr BR-001 ebay\n' > .sdd/migrate-v7.map
S migrate.sh --layout v7
chk "migrate · map thiếu context/BR thì kê đích danh (exit $R)" \
  '[ $R = 1 ] && has "KHÔNG CHẠY" && has "context \`console\`" && has "BR-002 chưa có dòng" && [ -f specs/br.md ]'

# ③ --dry-run: in kế hoạch, không đụng một byte nào
mkmap
S migrate.sh --layout v7 --dry-run
chk "migrate · --dry-run in kế hoạch, đĩa y nguyên (exit $R)" \
  '[ $R = 0 ] && has "SẼ dời" && has "chưa đụng đĩa" && [ -f specs/br.md ] && [ ! -d specs/ebay ] && git diff --quiet'

# ④ chạy thật: cây 7.0 dựng đúng, mỗi BR một lát dưới nghề của nó
S migrate.sh --layout v7
chk "migrate · BR → lát của nghề, UC vào use-cases/ của lát (exit $R)" \
  '[ $R = 0 ] && [ -f specs/ebay/br-001/br.md ] && [ -f specs/core/br-002/br.md ] &&
   [ -f specs/ebay/br-001/use-cases/UC-001-notify-order/UC-001.md ] && [ ! -d specs/contexts ]'
chk "migrate · UC ghi Nghề · Lát, giữ dấu vết context cũ trong <!-- -->" \
  'grep -q "^- \*\*Nghề:\*\* ebay · \*\*Lát:\*\* BR-001 <!--" specs/ebay/br-001/use-cases/UC-001-notify-order/UC-001.md'
chk "migrate · bảng Related Use Cases có cả UC chưa mở (UC-009 chỉ có trong use-cases.md)" \
  'grep -q "| UC-001 | Báo đơn | Hệ thống | BR-001 | implemented |" specs/ebay/br-001/br.md &&
   grep -q "| UC-009 | Gộp đơn | Hệ thống | BR-001 | draft |" specs/ebay/br-001/br.md'
chk "migrate · internal/ → gốc + notes/, ADR không khai nghề thì về specs/adr/" \
  '[ -f specs/architecture.md ] && [ -f specs/decisions.md ] &&
   [ -f specs/adr/ADR-001-hinh-cua-plugin.md ] && [ -f notes/hoi-dap/hoi-dap.md ] && [ ! -d specs/internal ]'
chk "migrate · entities.md tách mỗi entity một file, phần không phải entity vào README" \
  '[ -f specs/ebay/entities/Order.md ] && [ -f specs/ebay/entities/Channel.md ] &&
   grep -q "Domain Model" specs/ebay/entities/README.md && grep -q "^- \*\*Thuộc:\*\* ebay" specs/ebay/entities/Order.md'
chk "migrate · rules/glossary tách theo nghề, RULE chưa khai thì ở lại gốc" \
  'grep -q "RULE-001" specs/ebay/rules.md && ! grep -q "RULE-001" specs/rules.md &&
   grep -q "RULE-009" specs/rules.md && grep -q "Đơn" specs/ebay/glossary.md'
chk "migrate · vision.md + nghe_paths sinh ra" \
  '[ -f specs/vision.md ] && grep -q "^nghe_paths=ebay" .sdd/config'
chk "migrate · test UC dời theo nghề, import tương đối trong test được sửa (#56)" \
  '[ -d tests/use-cases/ebay/UC-001 ] && [ ! -d tests/use-cases/orders ] &&
   grep -q "use-cases/ebay/UC-001/fakes" tests/use-cases/ebay/UC-001/AC-1.test.js'
chk "migrate · đường dẫn trong code được sửa theo tên thật vừa dời" \
  'grep -q "specs/ebay/br-001/use-cases/UC-001-notify-order/UC-001.md" src/orders/notify.js'
chk "migrate · index trả về trống, in HAI lệnh commit tách theo ranh giới (#57)" \
  'git diff --cached --quiet && has "git add -A --" && has "dời test UC theo nghề"'

# ⑤ chạy lại trên cây đã 7.0 → nói không có gì để dời, không hỏng
S migrate.sh --layout v7
chk "migrate · chạy lại trên cây 7.0 thì dừng, không dời gì (exit $R)" \
  '[ $R = 0 ] && has "đã ở bố cục 7.0"'

# ⑥ --evidence: thân ## Background đi, mục lục ### và đoạn ** ở lại, ## Adversarial pass còn một dòng đếm
mk6x mig2
S migrate.sh --evidence BR-001
chk "migrate --evidence · thân Background sang evidence, ### và ** ở lại (exit $R)" \
  '[ $R = 0 ] && [ -f specs/br.evidence.md ] && grep -q "982 ô" specs/br.evidence.md &&
   ! grep -q "982 ô" specs/br.md && grep -q "^### Số đo tháng 9" specs/br.md &&
   grep -q "\*\*Vì sao vẫn xây:\*\*" specs/br.md'
chk "migrate --evidence · Adversarial pass còn một dòng có số ___ ra mặt tiền" \
  'grep -q "Ngày chạy: 2026-01-03 · 3 vai · trên v2 · 2 câu → 1 đã áp · 1 → ___" specs/br.md'
S migrate.sh --evidence BR-001
chk "migrate --evidence · chạy lại không nén lại (idempotent)" \
  '[ $R = 0 ] && has "đã tách rồi" && [ "$(grep -c "Ngày chạy: 2026-01-03" specs/br.md)" = 1 ]'
S migrate.sh --evidence BR-404
chk "migrate --evidence · BR không có thì đỏ (exit $R)" '[ $R = 1 ] && has "không thấy"'

# ⑦ không có node: migrate KHÔNG im lặng làm nửa vời — dừng có lời (khác mermaid, vì đây là script SỬA file)
mk6x mig3
mkmap
NODEDIR="$(dirname "$(command -v node)")"
O="$(PATH="$(printf '%s' "$PATH" | tr ':' '\n' | grep -vxF "$NODEDIR" | paste -sd: -)" \
     bash "$P/scripts/migrate.sh" --layout v7 2>&1)"; R=$?; O="$(printf '%s\n' "$O" | clean)"
chk "migrate · không có node thì dừng có lời, không dời nửa chừng (exit $R)" \
  '[ $R = 127 ] && has "cần Node.js" && [ -d specs/contexts ]'
cd "$T"
