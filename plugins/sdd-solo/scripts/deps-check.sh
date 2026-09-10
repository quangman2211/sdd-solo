#!/usr/bin/env bash
# deps-check.sh — phụ thuộc ngoài của SDD-Solo.
#
# Từ 4.0.0 danh sách này gần như rỗng, và đó là chủ đích: quy trình chạy trọn
# vòng bằng chính nó. Phụ thuộc BẮT BUỘC chỉ còn `git` và `bash`.
#
# Vì sao Spec Kit rời khỏi cột bắt buộc — ba phép đo, không phải sở thích:
#   ① `.specify/scripts/bash/create-new-feature.sh` hardcode SPECS_DIR=$REPO_ROOT/specs
#      và `get_highest_from_specs` quét `specs/*` để lấy số kế tiếp. Nó và ta dùng
#      chung một thư mục với hai hệ ID (`001-` vs `UC-###`), không bên nào biết bên kia.
#   ② `/speckit-plan` đọc đúng hai thứ: FEATURE_SPEC + `.specify/memory/constitution.md`.
#      Ở repo thật, FEATURE_SPEC là bản mỏng chỉ có ID còn constitution.md vẫn nguyên
#      placeholder. Bước quyết kiến trúc chạy trên hai đầu vào rỗng — đó là #34.
#   ③ Bốn repo trên cùng một máy có 10 / 24 / 25 / 35 lệnh speckit-*. Đặt tên lệnh
#      của người khác vào quy tắc cứng là để quy tắc hỏng theo lịch release của họ.
#
# Spec Kit VẪN đáng cài và đáng đọc — nó là nguồn tham khảo thiết kế tốt, update
# thường xuyên. Chỉ là không repo nào được gãy khi nó đổi.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"

echo "=== Phụ thuộc ==="

# ── bắt buộc ────────────────────────────────────────────────────────────
command -v git >/dev/null 2>&1 && ok "git" || bad "git — chưa có; githook và mọi phép đếm đều cần"
[ -d "$ROOT/.git" ] && ok "repo đã git init" || bad "chưa git init — githook không gắn được"

# ── tuỳ chọn: nói một dòng, không bao giờ đỏ ────────────────────────────
if [ -d "$ROOT/.specify" ]; then
  info "Spec Kit — có .specify/. Tuỳ chọn, KHÔNG nằm trong 14 bước từ 4.0.0."
  # Chỉ nhắc khi hai cây thật sự đang chung thư mục — nói khi không có gì để dọn
  # là dạy người ta phớt lờ dòng này.
  if find "$ROOT/specs" -maxdepth 1 -type d -name '[0-9][0-9][0-9]-*' 2>/dev/null | grep -q .; then
    warn "specs/ đang chứa cả cây của Spec Kit (thư mục 00N-*) lẫn cây của sdd-solo"
    info "→ bash .sdd/scripts/migrate.sh --dry-run   (dời sang .speckit/work/, giữ git history)"
  fi
else
  info "Spec Kit — chưa cài. Không cần cho 14 bước; cài nếu muốn đọc nó làm tham khảo thiết kế."
fi

find "$HOME/.claude/plugins/cache" -maxdepth 2 -type d -name 'aiup-core' 2>/dev/null | grep -q . \
  && info "AIUP — đã cài. Không dùng cho bước ② ③ ④: bốn lệnh của nó ghi ra cây docs/, và /use-case-spec đụng hệ ID (#29)." \
  || info "AIUP — chưa cài, và không cần."

[ -d "/Applications/Camunda Modeler.app" ] \
  && info "Camunda Modeler — có (tuỳ chọn: DMN engine, mở .bpmn cũ)" \
  || info "Camunda Modeler — không có, và không cần: bước ④ vẽ mermaid trong UC-###.flow.md"

info "Claude Design — không kiểm được bằng script; cần cho Phase 0 và bước ⑤"

echo
if [ "$FAIL" -gt 0 ]; then echo "Thiếu $FAIL phụ thuộc bắt buộc."; exit 1; fi
echo "Đủ phụ thuộc."
