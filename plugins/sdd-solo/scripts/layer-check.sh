#!/usr/bin/env bash
# layer-check.sh [--staged] [--file <path> ...] — luật ranh giới lõi/nghề (7.0, plan §3).
#
#   Lõi không biết nghề; nghề biết lõi. Cụ thể, đo được:
#   ① gốc specs/*.md · specs/adr/ · specs/core/**  KHÔNG trích ID của nghề: RULE/ADR/UC/BR sống trong
#      specs/<nghề>/ → ĐỎ. Tên entity ở specs/<nghề>/entities/ (Channel, Product…) → chỉ CẢNH BÁO: hiến pháp
#      kỹ thuật và ADR gốc nhắc tên entity là chuyện thường; đỏ nhiều thì hook thành nhiễu và người tắt nó
#      (peer runxops chốt 2026-09-18).
#   ② src/core/**  KHÔNG import từ src/<nghề>/ (đường tương đối `../<nghề>/`, tuyệt đối `src/<nghề>/`,
#      hay alias `@/<nghề>/`).
#   Trừ: specs/vision.md (bảng Nghề và lát kể tên BR của nghề là việc của nó) · specs/decisions.md (một sổ
#   cho cả dự án) · specs/traceability.md (script sinh) · *.trace.md · evidence.md · file dưới notes/ ·
#   và trong mọi file: mục vết `## History` · `## Adversarial pass` · `## Đọc lại` (7.0.1).
#
# Mặc định quét cả repo → in từng chỗ, exit 1 nếu có. `--staged` chỉ xét file đang stage (githook
# pre-commit.d/20-layer-boundary dùng — chỉ chặn vi phạm MỚI, không bắt repo vừa migrate phải sạch
# ngay). `--file` xét đúng những file nêu tên (gate-check/design-check gọi cho UC ở core, chỉ cảnh báo).
# Repo 6.x (chưa có nghề) → không có gì để kiểm, exit 0.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"
MODE=all; FILES=""
PREV=""
for a in "$@"; do
  case "$PREV" in --file) FILES="$FILES $a"; PREV=""; continue;; esac
  case "$a" in --staged) MODE=staged;; --file) MODE=files; PREV="$a";; *) [ "$MODE" = files ] && FILES="$FILES $a";; esac
done
[ "$(layout "$ROOT")" = v7 ] || { info "repo chưa ở bố cục 7.0 — không có nghề để kiểm ranh giới"; exit 0; }
NGHE="$(nghe_list "$ROOT")"
[ -n "$NGHE" ] || { info "chưa có nghề nào (nghe_paths trống, specs/<nghề>/ chưa có) — không có gì để kiểm"; exit 0; }
NRE="$(printf '%s' "$NGHE" | tr -s ' ' '|')"

# ── ID của nghề: gom từ cây specs/<nghề>/ ────────────────────────────────
NIDS="$(for n in $NGHE; do
  [ -f "$ROOT/specs/$n/rules.md" ] && grep -oE '^## RULE-[0-9]+' "$ROOT/specs/$n/rules.md" | awk '{print $2}'
  ls "$ROOT/specs/$n/adr/"ADR-[0-9]*.md 2>/dev/null | xargs -n1 basename 2>/dev/null | grep -oE '^ADR-[0-9]+'
  ls -d "$ROOT/specs/$n"/br-[0-9]*/ 2>/dev/null | sed -E 's#.*/br-([0-9]+)/$#BR-\1#'
  ls -d "$ROOT/specs/$n"/br-[0-9]*/use-cases/UC-[0-9]*/ 2>/dev/null | sed -E 's#.*/(UC-[0-9]+)-[^/]*/$#\1#'
done | sort -u)"
# 7.4 (P-24): CON-### sống trong br.md của lát (`- **CON-001 Technical:**`) — lát của nghề thì CON là của nghề. Trừ số
# cũng có ở gốc/core (CON đánh số theo BR nên trùng số là thường; trùng thì không quy được cho ai, bỏ qua).
NCON="$(for n in $NGHE; do cat /dev/null "$ROOT/specs/$n"/br-[0-9]*/br.md 2>/dev/null | grep -oE '\*\*CON-[0-9]+' | tr -d '*'; done | sort -u)"
CCON="$(cat /dev/null "$ROOT"/specs/core/br-[0-9]*/br.md "$ROOT/specs/br.md" 2>/dev/null | awk '/^# BR-000:/{s=1;next} /^# BR-/{s=0} !s' | grep -oE '\*\*CON-[0-9]+' | tr -d '*' | sort -u)"   # bỏ BR-000 mẫu: CON-001..003 của khuôn không phải của ai
NCON="$(printf '%s\n' "$CCON" | awk 'NR==FNR{a[$0];next} NF && !($0 in a)' - <(printf '%s\n' "$NCON"))"
NIDS="$(printf '%s\n%s\n' "$NIDS" "$NCON" | awk 'NF' | sort -u)"
NENT="$(for n in $NGHE; do
  ls "$ROOT/specs/$n/entities/"*.md 2>/dev/null | xargs -n1 basename 2>/dev/null | sed 's/\.md$//' | grep -vE '^(README|_.*)$'
done | sort -u)"
IDRE="$(printf '%s\n' "$NIDS" | awk 'NF' | tr '\n' '|' | sed 's/|$//')"
# tên entity so nguyên từ, phân biệt hoa thường (`Order`, `Listing`)
ENRE="$(printf '%s\n' "$NENT" | awk 'NF' | tr '\n' '|' | sed 's/|$//')"

# ── danh sách file cần xét ────────────────────────────────────────────────
is_root_spec() { # 0 nếu file thuộc vùng "gốc + core" (① áp dụng)
  case "$1" in
    specs/vision.md|specs/decisions.md|specs/traceability.md) return 1;;
    *.trace.md|*/evidence.md|notes/*) return 1;;
    specs/adr/*|specs/core/*) return 0;;
    specs/*/*) return 1;;
    specs/*.md) return 0;;
  esac
  return 1
}
is_core_src() { case "$1" in src/core/*) return 0;; esac; return 1; }
case "$MODE" in
  staged) LIST="${SDD_STAGED:-$(git -C "$ROOT" diff --cached --name-only --diff-filter=d)}";;
  files)  LIST="$(for f in $FILES; do printf '%s\n' "${f#$ROOT/}"; done)";;
  *)      LIST="$( { find "$ROOT/specs" -maxdepth 1 -name '*.md'; find "$ROOT/specs/adr" "$ROOT/specs/core" -type f -name '*.md' 2>/dev/null
                     find "$ROOT/src/core" -type f 2>/dev/null; } | sed "s#^$ROOT/##")";;
esac
HITS=0; ENTW=0
for f in $LIST; do
  [ -f "$ROOT/$f" ] || continue
  if is_root_spec "$f"; then
    # bỏ khối <!-- --> và dòng trong ``` — trích dẫn ví dụ trong lời giảng không phải trích thật.
    # 7.0.1 (R phiếu #71, P-13): bỏ cả mục VẾT — `## History` · `## Adversarial pass` · `## Đọc lại`, tới heading
    # `## ` kế. Luật sổ cấm sửa dòng History, nên một glossary/ADR gốc có History cũ nhắc RULE nghề sẽ đỏ mỗi lần
    # ai chạm file — cùng loại với *.trace.md / evidence.md đã miễn theo file. Dòng bị bỏ in thành dòng trống để
    # số dòng in ra vẫn đúng số dòng trong file.
    BODY="$(strip_markup < "$ROOT/$f" | awk -v TR="$(kwh trace)[[:space:]]*$" '
      $0 ~ TR { v=1; print ""; next }
      /^## / { v=0 }
      /^```/ { c=!c; print ""; next }
      (c || v) { print ""; next }
      { print }')"
    H=""; [ -n "$IDRE" ] && H="$(printf '%s\n' "$BODY" | grep -nwE "($IDRE)" | head -5)"
    if [ -n "$H" ]; then
      HITS=$((HITS+1))
      bad "$f trích ID của nghề ($(printf '%s\n' "$H" | grep -owE "($IDRE)" | sort -u | tr '\n' ' ' | sed 's/ $//')) — gốc và core không biết nghề"
      printf '%s\n' "$H" | cut -c1-100 | sed 's/^/      /'
    fi
    E=""; [ -n "$ENRE" ] && E="$(printf '%s\n' "$BODY" | grep -nwE "($ENRE)" | head -3)"
    if [ -n "$E" ]; then
      ENTW=$((ENTW+1))
      warn "$f nhắc tên entity của nghề ($(printf '%s\n' "$E" | grep -owE "($ENRE)" | sort -u | tr '\n' ' ' | sed 's/ $//')) — thường là được, nhưng entity mọi nghề cần thì đặt ở specs/core/entities/"
    fi
  fi
  if is_core_src "$f"; then
    H="$(grep -nE "(import|require|from)[^\n]*['\"](\.\./)+($NRE)/|['\"](src|@|~)/($NRE)/" "$ROOT/$f" | head -5)"
    if [ -n "$H" ]; then
      HITS=$((HITS+1))
      bad "$f import từ src/<nghề> — src/core không được biết nghề ($NGHE)"
      printf '%s\n' "$H" | cut -c1-100 | sed 's/^/      /'
    fi
  fi
done
if [ "$HITS" -eq 0 ]; then
  ok "ranh giới lõi/nghề: không chỗ nào ở gốc/core trích ID của nghề ($(printf '%s\n' "$NIDS" | grep -c .) ID nghề, $(printf '%s\n' "$NENT" | grep -c .) entity nghề, $(printf '%s\n' "$LIST" | grep -c .) file xét${ENTW:+; $ENTW file nhắc tên entity nghề — cảnh báo})"
  exit 0
fi
info "sửa: thứ nghề cần mà lõi cũng cần thì đưa lên gốc/core (RULE xuyên suốt, entity chung); còn lại thì dòng đó về specs/<nghề>/"
exit 1
