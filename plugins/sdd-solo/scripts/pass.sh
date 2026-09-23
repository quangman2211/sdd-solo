#!/usr/bin/env bash
# pass.sh <gate|close|change> <ID> — chạy SAU khi phép kiểm tương ứng exit 0.
#
# Gộp từ gate-pass.sh + close-pass.sh + change-pass.sh (4.0.0). Ba script cũ
# cùng một hình: đổi Status, ghi dấu vết, commit riêng. Giữ NGUYÊN từng câu chữ
# commit message và từng dòng in ra — githook và `gate-check` §9 nhận diện commit
# bằng tiêu đề, nên đổi một ký tự ở đây là mở một lỗ im lặng ở chỗ khác.
#
# Vì sao mode tường minh chứ không đoán theo tiền tố ID: `UC-###` đi qua HAI pass
# khác nhau (⑨ gate và ⑭ close). Tiền tố không phân biệt được hai cái đó, và một
# script tự đoán sai giữa "reviewed" với "implemented" thì hỏng im lặng.
set -e
MODE="${1:-}"; ID="${2:-}"
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
case "$MODE" in
  gate|close|change|deprecate) ;;
  *) echo "Dùng: pass.sh <gate|close|change|deprecate> <ID>" >&2; exit 2;;
esac
[ -z "$ID" ] && { echo "Dùng: pass.sh $MODE <ID>" >&2; exit 2; }
ROOT="$(project_root)"

# marker + commit marker — chung cho gate và change
mark() {
  mkdir -p "$ROOT/.sdd/gate"
  git -C "$ROOT" rev-parse HEAD > "$ROOT/.sdd/gate/$1.ok"
  git -C "$ROOT" add ".sdd/gate/$1.ok" \
    && git -C "$ROOT" commit -q --only -m "chore(sdd): gate marker $1" -- ".sdd/gate/$1.ok" || true
}

case "$MODE" in

gate)
  F="$(find_uc "$ID" "$ROOT")"; [ -z "$F" ] && exit 1
  sed -i.bak -E 's/(\*\*Status:\*\* *)draft/\1reviewed/' "$F" && rm -f "$F.bak"
  sed -i.bak -E "s/(\*\*Last updated:\*\* *).*/\1$(today)/" "$F" && rm -f "$F.bak"
  # #44: bảng use-cases.md của context nói cùng một trạng thái, cùng một commit.
  T="$(uc_table_file "$ID" "$ROOT")"; TF=""
  if uc_table_set "$ID" reviewed "$ROOT"; then TF="$T"; else
    printf '  ! bảng %s không có dòng %s — thêm dòng cho /sdd-solo:state gợi đúng UC tiếp theo\n' "${T#$ROOT/}" "$ID"; fi
  git -C "$ROOT" commit -q --only -m "docs($ID): spec reviewed — $(kw_w c_dor "$ROOT")" -- "$F" $TF || true
  mark "$ID"
  printf 'QUA CỔNG. Status -> reviewed · marker .sdd/gate/%s.ok · đã commit.\n' "$ID"
  printf 'Bước tiếp: /sdd-solo:design %s — thiết kế trước khi viết dòng code đầu tiên.\n' "$ID"
  ;;

close)
  F="$(find_uc "$ID" "$ROOT")"; [ -z "$F" ] && exit 1
  CTX="$(owner_of "$F")"
  sed -i.bak -E 's/(\*\*Status:\*\* *)(draft|reviewed)/\1implemented/' "$F" && rm -f "$F.bak"
  # 5.0.0 — dấu vết rời khỏi file đang hiệu lực. Đo ở runxops: UC-009.md 56 KB thì
  # ## Adversarial pass 11,0 + ## Đọc lại 11,3 + ## History 6,3 = 28,6 KB, và không ai
  # đọc lại ba mục đó sau khi UC đóng — chúng là giấy nháp của một bài toán đã giải.
  # Trong đội, biên bản rà soát là bằng chứng cho người thứ hai; làm một mình thì
  # không có người thứ hai. Nhưng KHÔNG XOÁ: thân dời sang UC-###.trace.md cùng thư
  # mục (git giữ, tranh chấp thì mở), tại chỗ để lại MỘT dòng có số đếm bằng máy.
  # Nén ở ⑭ chứ không ở ⑨: lúc UC còn mở, F# là danh sách việc và cổng đọc nó bằng
  # máy. Idempotent — dòng tóm tắt đã có đuôi "→ UC-###.trace.md" thì không nén lại.
  TRACE="$(dirname "$F")/$ID.trace.md"
  need_node "pass.sh"
  node "$HERE/js/pass.mjs" trace "$F" "$TRACE" "$ID" "$(today)"
  BR="$(grep -oE 'BR-[0-9]+' "$F" | head -1)"
  RULES="$(grep -oE 'RULE-[0-9]+' "$F" | sort -u | tr '\n' ' ')"
  ADRS="$(grep -oE 'ADR-[0-9]+' "$F" | sort -u | tr '\n' ' ')"
  TR="$ROOT/specs/traceability.md"
  for n in $(grep -oE '^### AC-[0-9]+' "$F" | grep -oE '[0-9]+'); do
    SCRS="$(sed -n '/^## Screens/,/^## /p' "$F" | grep -oE 'SCR-[0-9]+-[0-9]+' | sort -u | tr '\n' ' ')"
    echo "| $BR | $ID | AC-$n | $RULES | $SCRS | tests/use-cases/$CTX/$ID/AC-$n.test.* | $ADRS | implemented |" >> "$TR"
  done
  # #44: bảng use-cases.md — ca thật runxops UC-014: file UC implemented, bảng vẫn draft,
  # /sdd-solo:state gợi UC tiếp theo sai, phải sửa tay một commit riêng (cfbead4).
  T="$(uc_table_file "$ID" "$ROOT")"; TF=""
  if uc_table_set "$ID" implemented "$ROOT"; then TF="$T"; else
    printf '  ! bảng %s không có dòng %s — thêm dòng cho /sdd-solo:state gợi đúng UC tiếp theo\n' "${T#$ROOT/}" "$ID"; fi
  [ -f "$TRACE" ] && git -C "$ROOT" add "$TRACE"
  git -C "$ROOT" commit -q --only -m "docs($ID): implemented — traceability" -- "$F" "$TR" $TF $( [ -f "$TRACE" ] && printf '%s' "$TRACE" ) || true
  echo "ĐÃ ĐÓNG $ID. Status → implemented${TF:+ (file UC + bảng UC)} · traceability +$(grep -cE '^### AC-' "$F") dòng · commit xong."
  echo "Nhớ: cập nhật STATE.md (/sdd-solo:state) trước khi đóng máy."
  ;;

deprecate)
  # #45: bỏ UC cho tử tế — năm việc rời nhau (Status · History · marker · bảng · decisions) thì
  # một việc luôn bị bỏ sót. Ca thật runxops: UC-009/UC-012 deprecated bằng tay, marker cổng còn
  # nguyên (githook vẫn cho feat(UC-009)), History/decisions ghi tay, STATE ghi nợ nhiều ngày.
  # 7.0.1 (#51): UC chỉ có dòng trong bảng (dự kiến rồi bỏ, chưa từng có file) — vẫn phải sửa bảng + decisions;
  # tới 7.0.0 nhánh này exit 1 im lặng và bảng cứ nói draft mãi.
  F="$(find_uc "$ID" "$ROOT")"
  if [ -z "$F" ] && [ -z "$(uc_table_file "$ID" "$ROOT")" ]; then
    printf '✗ %s không có file UC lẫn dòng trong bảng UC nào — ID sai?\n' "$ID" >&2; exit 1
  fi
  shift 2; BY="-"; REASON=""
  while [ $# -gt 0 ]; do case "$1" in --by) BY="${2:--}"; shift 2;; *) REASON="$REASON $1"; shift;; esac; done
  REASON="$(printf '%s' "$REASON" | sed 's/^ *//')"
  [ -z "$REASON" ] && { echo "Dùng: pass.sh deprecate UC-### [--by UC-###] <lý do>" >&2; exit 2; }
  case "$BY" in UC-[0-9]*|-) ;; *) echo "--by phải là UC-### hoặc -" >&2; exit 2;; esac
  if [ -n "$F" ]; then
  sed -i.bak -E 's/(\*\*Status:\*\* *)(draft|reviewed|implemented)/\1deprecated/' "$F" && rm -f "$F.bak"
  sed -i.bak -E "s/(\*\*Last updated:\*\* *).*/\1$(today)/" "$F" && rm -f "$F.bak"
  need_node "pass.sh"
  node "$HERE/js/pass.mjs" deprecate "$F" "$(today)" "$REASON" "$BY"
  fi
  T="$(uc_table_file "$ID" "$ROOT")"; TF=""
  if uc_table_set "$ID" deprecated "$ROOT"; then TF="$T"; else
    printf '  ! bảng %s không có dòng %s\n' "${T#$ROOT/}" "$ID"; fi
  MK="$ROOT/.sdd/gate/$ID.ok"; MKF=""
  if [ -f "$MK" ]; then
    git -C "$ROOT" rm -q --cached ".sdd/gate/$ID.ok" 2>/dev/null || true
    rm -f "$MK"; MKF=".sdd/gate/$ID.ok"
  fi
  DEC="$(decisions_file "$ROOT")"; DF=""
  # Đã có dòng "Bỏ UC-###" (deprecate lần hai, hoặc ghi tay trước đó) thì không thêm dòng trùng.
  if [ -f "$DEC" ] && ! grep -qE -- "($(kw dropped)) $ID \(" "$DEC"; then
    printf -- '- %s — %s %s (%s). Loại: giữ %s. Chi tiết: %s\n' "$(today)" "$(kw_w dropped "$ROOT")" "$ID" "$REASON" "$ID" "$( [ "$BY" = "-" ] && printf 'không có UC thay thế' || printf '%s' "$BY" )" >> "$DEC"
    DF="$DEC"
  fi
  git -C "$ROOT" commit -q --only -m "docs($ID): deprecated — $REASON" -- $F $TF $DF $MKF || true
  [ -z "$F" ] && printf '%s chưa có file UC — chỉ sửa bảng UC và decisions.md, không có History/Status để ghi.\n' "$ID"
  printf 'ĐÃ BỎ %s. Status -> deprecated · History v+1 · marker cổng %s · bảng UC %s · decisions.md %s · đã commit.\n' \
    "$ID" "$( [ -n "$MKF" ] && printf 'đã gỡ' || printf 'không có' )" "$( [ -n "$TF" ] && printf 'đã sửa' || printf 'không có dòng' )" "$( [ -n "$DF" ] && printf '+1 dòng' || printf 'không có file' )"
  [ "$BY" != "-" ] && printf 'Thay bằng %s — chưa có thư mục thì /sdd-solo:start %s.\n' "$BY" "$BY"
  BRP="$(grep -oE 'BR-[0-9]+' ${F:-/dev/null} | head -1)"; [ -z "$BRP" ] && [ -n "$TF" ] && BRP="$(grep -oE '^# BR-[0-9]+' "$TF" | head -1 | tr -d '# ')"; BRST="$(br_body "$BRP" "$ROOT" | sed -n 's/.*\*\*Status:\*\* *//p' | head -1 | awk '{print $1}')"
  if [ -n "$BRP" ] && [ "$BRST" != "deprecated" ]; then
    echo "Nhớ: ## Related Use Cases của $BRP và STATE.md còn trỏ $ID thì sửa tay (/sdd-solo:state)."
  else
    echo "Nhớ: STATE.md còn trỏ $ID thì cập nhật (/sdd-solo:state)."
  fi
  ;;

change)
  D="$(find_chg "$ID" "$ROOT")"; [ -z "$D" ] && exit 1
  P="$D/proposal.md"
  need_node "pass.sh"
  node "$HERE/js/pass.mjs" change "$P" "$(today)"
  git -C "$ROOT" commit -q --only -m "docs($ID): change reviewed — $(kw_w c_p5 "$ROOT")" -- "$P" || true
  mark "$ID"
  printf 'QUA CỔNG PHASE 5. Status -> applying · marker .sdd/gate/%s.ok · đã commit.\n' "$ID"
  echo "Bước tiếp: viết test cho AC mới (đỏ trước) rồi sửa code. Commit code gắn ($ID)."
  echo "Xong hết thì merge delta vào specs/, History UC v+1, và chore($ID): archive."
  ;;

esac
