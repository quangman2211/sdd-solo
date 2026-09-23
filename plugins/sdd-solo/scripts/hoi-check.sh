#!/usr/bin/env bash
# hoi-check.sh <vai | file> [--lich-su] — kiểm sổ hỏi có địa chỉ notes/hoi-dap/hoi-<V>.md (7.3). exit 1 nếu có ✗.
#   1. mỗi mục HỎI-<V>n có đủ bốn ô (Nguồn · Chặn không · Đang làm gì trong lúc chờ · Việc cho spec khi trả lời), không còn <…>
#   2. `Chặn không:` là chặn | không chặn
#   3. mục đã trả lời phải có `đích:`; cổng của UC-### đã mở (.sdd/gate/UC-###.ok) mà đích trỏ vào THÂN UC (không phải
#      design.md / decisions.md, không nói "AC") → ✗ — luật: sau cổng câu của D/T trả ở design.md hoặc decisions.md,
#      thân UC chỉ mở lại khi một AC đổi (runxops _chung.md luật 6; 25 câu HỎI của UC-025 mỗi câu kéo một lượt verify)
#   4. số HỎI-<V>n không trùng; nhảy số thì cảnh báo
#   --lich-su: soi `git log -p` — commit nào SỬA một dòng `### HỎI-` đã có (sổ chỉ-thêm); chạy ở status, không ở githook
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"; A="${1:-}"; [ -z "$A" ] && { sed -n '2,9p' "$0" | sed 's/^# \{0,3\}//'; exit 2; }
if [ -f "$A" ]; then F="$A"; V="$(basename "$A" .md | sed 's/^hoi-//')"; else V="$A"; F="$ROOT/notes/hoi-dap/hoi-$V.md"; fi
[ -f "$F" ] || { info "chưa có ${F#$ROOT/}"; exit 0; }
echo "Sổ hỏi vai $V — ${F#$ROOT/}"
if [ "$2" = --lich-su ] || [ "$3" = --lich-su ]; then
  N=0
  for h in $(git -C "$ROOT" log --format=%h --diff-filter=M -- "${F#$ROOT/}" 2>/dev/null); do
    if git -C "$ROOT" show "$h" -- "${F#$ROOT/}" | grep -qE "^-### ($(kw ask))-"; then N=$((N+1)); bad "$h sửa một dòng '### HỎI-' đã có — sổ chỉ-thêm: $(git -C "$ROOT" log -1 --format=%s "$h" | cut -c1-60)"; fi
  done
  [ "$N" = 0 ] && ok "không commit nào sửa dòng HỎI đã có"
fi
node "$HERE/js/hoi.mjs" "$F" "$V" "$ROOT"
R=$?; [ "$R" != 0 ] && FAIL=$((FAIL+1))
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
