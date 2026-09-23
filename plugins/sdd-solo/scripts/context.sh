#!/usr/bin/env bash
# context.sh UC-### [--why] — MỘT lệnh in ra đúng đủ bối cảnh của một UC.
#
# Vì sao có file này. Tới 4.2.0, /sdd-solo:design dặn agent đọc 13 tên file bằng lời
# văn, và không phép kiểm nào đo được nó đã đọc chưa. Lời dặn đọc 13 file là lời dặn
# hỏng theo xác suất — và hỏng im lặng, vì bản thiết kế viết ra vẫn trôi chảy, chỉ
# thiếu một nguồn (#34: design.md nói ngược brief hai ngày không ai thấy).
# Đo ở runxops: hiểu UC-009 phải mở 15 file / 6 thư mục / 210 KB ≈ 53k token, mà
# hơn 60% là dấu vết (adversarial, đọc lại, history, chứng cứ) không phải hiệu lực.
#
# Script này gom ĐÚNG những gì đang hiệu lực và ĐÚNG những ID UC này trích:
#   UC (bỏ 3 mục dấu vết) · flow · RULE được trích · CON được trích · ADR được trích
#   · mục BR cha (không Background) · architecture (4 mục) · entity/glossary có nhắc
#   · dòng brief để agent đọc riêng (ngoài specs/, luật #34 giữ nguyên).
# In ra, không ghi file. Cuối có dòng đo KB — agent và người đều thấy giá phải trả.
#
# --why: chỉ in RULE · CON · ADR · ## Cấm — trả lời "tính năng này do cái gì quyết
# định" cho người bảo trì, một màn hình. Đây là nửa còn lại của decisions.sh:
# decisions.sh đi từ thời gian xuống quyết định; --why đi từ một UC lên quyết định.
#
# --brief (6.5.0, #43 phần còn lại, chủ dự án uỷ quyền): bản cho subagent ⑦/⑧ — họ đọc HÀNH VI
# và RÀNG BUỘC, không đọc "dựng bằng gì". Khác bản trọn ở hai chỗ: ADR chỉ in đoạn đầu của
# ## Decision + tên các mục con (con trỏ, không thân); architecture chỉ ## Cấm · ## Ranh giới ·
# ## Nơi chạy (bỏ Ngăn xếp, Ai gọi). Đo runxops UC-014: 9 ADR Decision 53 KB, đoạn đầu ~21 KB;
# architecture 45 → ~22 KB. KHÔNG cắt RULE (mâu thuẫn nấp trong văn xuôi của rule), không lọc
# glossary theo thuật ngữ UC nhắc (đo: bỏ 24 mục mà không bớt KB). Bước ⑩ design đọc bản trọn.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"
ID=""; WHY=0; BRIEF=0
for a in "$@"; do case "$a" in --why) WHY=1;; --brief) BRIEF=1;; UC-[0-9]*|BR-[0-9]*) ID="$a";; esac; done
[ -z "$ID" ] && { echo "Dùng: context.sh <UC-###|BR-###> [--why | --brief]" >&2; exit 2; }
# 7.4 (P-23): BR-### — bối cảnh của một LÁT: mục quyết định của BR (không Background), dòng của lát ở vision.md,
# RULE/ADR BR trích, architecture, entity/glossary BR nhắc. Cùng js/context.mjs, cùng luật cắt dấu vết; khác ở chỗ chủ thể
# là br.md thay vì UC-###.md. 6.x: specs/br.md chứa nhiều BR — chỉ lấy mục của ID.
case "$ID" in
  BR-*)
    F="$(br_file "$ID" "$ROOT")"
    { [ -f "$F" ] && [ -n "$(br_title "$ID" "$ROOT")" ]; } || { printf '  \033[31m✗\033[0m không tìm thấy %s trong %s\n' "$ID" "${F#$ROOT/}" >&2; exit 1; }
    CTX="$(owner_of_br "$ID" "$ROOT")";;
  *)
    F="$(find_uc "$ID" "$ROOT")"
    [ -z "$F" ] && { printf '  \033[31m✗\033[0m không tìm thấy file %s\n' "$ID" >&2; exit 1; }
    CTX="$(owner_of "$F")";;
esac
DIR="$(dirname "$F")"
BP="$(brief_path "$ROOT")"; BS=""; [ -n "$BP" ] && BS="$(brief_sha "$ROOT" 2>/dev/null)"
# 7.0 (#55): mọi đường dẫn nguồn tra ở lib.sh rồi đưa vào js/context.mjs qua env, mỗi dòng một file —
# nó không tự biết bố cục. 6.x: rules.md · br.md · internal/{adr,architecture.md} ·
# contexts/<ctx>/entities.md; 7.0: rules.md của gốc + nghề · br.md của lát · adr/ · architecture.md ·
# entities/<Tên>.md mà UC nhắc tên (entity_cited). OTHERS = tên context/nghề KHÁC, để cắt khỏi glossary.
export SDD_RULES="$(rules_files "$ROOT")" SDD_BRS="$(br_files "$ROOT")" SDD_ADRS="$(adr_dirs "$ROOT")"
export SDD_ARCH="$(arch_file "$ROOT")" SDD_ENTS="$(entity_cited "$F" "$ROOT")" SDD_GLOS="$(glossary_files "$CTX" "$ROOT")"
if [ "$(layout "$ROOT")" = v7 ]; then OTHERS="$(nghe_list "$ROOT" | tr ' ' '\n' | grep -vx "${CTX:-core}")"
else OTHERS="$(ls -d "$ROOT"/specs/contexts/*/ 2>/dev/null | xargs -n1 basename | grep -v '^_' | grep -vx "$CTX")"; fi
export SDD_OTHERS="$OTHERS"

need_node "context.sh"
node "$HERE/js/context.mjs" "$ROOT" "$F" "$ID" "$CTX" "$WHY" "$BP" "$BS" "$BRIEF"
