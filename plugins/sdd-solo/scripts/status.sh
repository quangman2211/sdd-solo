#!/usr/bin/env bash
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"; ROOT="$(project_root)"
echo "=== STATE.md ==="; cat "$ROOT/STATE.md" 2>/dev/null || echo "(chưa có)"
# Phase 1: BR có gì, và có đang xây trên nền chưa viết không
echo; echo "=== BR (Phase 1) ==="
BRS="$(br_ids "$ROOT")"
if [ -z "$BRS" ]; then
  warn "chưa có BR nào — chạy /sdd-solo:intake"
else
  for b in $BRS; do
    [ "$b" = "BR-000" ] && { printf '  %-9s %s\n' "$b" "(mẫu của template)"; continue; }
    # Khung chưa đụng tới in ra "draft" trông y hệt một BR thật đang viết dở.
    if br_title "$b" "$ROOT" | grep -qE "^# $b: *<"; then
      printf '  %-9s %s\n' "$b" "(khung trống — /sdd-solo:intake)"; continue
    fi
    st="$(br_body "$b" "$ROOT" | sed -n 's/.*\*\*Status:\*\* *//p' | head -1 | awk '{print $1}')"
    printf '  %-9s %s\n' "$b" "${st:-?}"
  done
fi
UCN="$(all_uc_files "$ROOT" | wc -l | tr -d ' ')"
if br_untouched "$ROOT"; then
  # (d) của #18 — xây trên nền chưa viết là loại sai đắt nhất vì nó ở gốc
  if [ "$UCN" -gt 0 ]; then
    bad "br.md vẫn là template mà đã có $UCN UC — đang xây trên nền chưa viết. Chạy /sdd-solo:intake."
  else
    info "br.md còn là template — bắt đầu bằng /sdd-solo:intake"
  fi
  # (e) của #19 — AIUP nhảy thẳng vào 'hệ thống làm gì', bỏ qua tầng 'vì sao làm'
  [ -f "$ROOT/docs/requirements.md" ] && \
    warn "có docs/requirements.md của AIUP mà BR chưa có — /requirements đã đi vòng qua tầng BR. Chạy /sdd-solo:intake trước."
fi

echo; echo "=== UC theo status ==="
# Chỉ file UC: bỏ .flow.md · .sequence.md · .trace.md (5.0.0 sinh trace sau close) — trước
# 6.1.0 dòng 'UC-###.flow ?' và 'UC-###.trace ?' in lẫn vào danh sách như hai UC không status.
for f in $(all_uc_files "$ROOT"); do
  id="$(basename "$f" .md)"; st="$(grep -oE '\*\*Status:\*\* *[a-z]+' "$f" | head -1 | awk '{print $2}')"
  g=""; [ -f "$ROOT/.sdd/gate/$id.ok" ] && g=" · gate ✓"
  printf '  %-8s %-12s%s\n' "$id" "${st:-?}" "$g"
  # #45: UC bỏ rồi mà marker còn → githook vẫn cho feat($id). Ca thật runxops UC-009/UC-012.
  [ "$st" = "deprecated" ] && [ -f "$ROOT/.sdd/gate/$id.ok" ] && \
    warn "$id deprecated nhưng .sdd/gate/$id.ok còn — githook vẫn cho commit code gắn $id. Gỡ: /sdd-solo:deprecate $id (hoặc git rm .sdd/gate/$id.ok)"
  # #44: bảng use-cases.md của context phải nói cùng trạng thái — /sdd-solo:state gợi
  # UC tiếp theo từ bảng, nên bảng lệch là gợi sai. Không có bảng/dòng thì chỉ nhắc.
  ts="$(uc_table_status "$id" "$ROOT")"
  if [ -n "$ts" ] && [ "$ts" != "$st" ]; then
    warn "$id: file UC nói '$st' nhưng bảng UC ($(uc_table_file "$id" "$ROOT" | sed "s#$ROOT/##")) nói '$ts' — sửa bảng cho khớp (pass.sh gate/close từ 6.1.0 tự sửa)"
  elif [ -z "$ts" ] && [ -f "$(uc_table_file "$id" "$ROOT")" ]; then
    info "$id không có dòng trong bảng UC ($(uc_table_file "$id" "$ROOT" | sed "s#$ROOT/##"))"
  fi
done
# Phase 5: change nào đang mở, đã qua cổng chưa
CD="$(ls -d "$ROOT/specs/changes/CHG-"* "$ROOT/changes/CHG-"* 2>/dev/null)"
if [ -n "$CD" ]; then
  echo; echo "=== Change đang mở (Phase 5) ==="
  for d in $CD; do
    id="$(basename "$d" | grep -oE '^CHG-[0-9]+')"
    st="$(awk 'index($0,"## Status")==1{f=1;next} f&&/^## /{exit} f&&NF{print;exit}' "$d/proposal.md" 2>/dev/null | tr -d "[:space:]")"
    g=""; [ -f "$ROOT/.sdd/gate/$id.ok" ] && g=" · gate ✓"
    printf '  %-9s %-12s%s\n' "$id" "${st:-?}" "$g"
  done
fi
echo; "$HERE/metrics.sh"
# phụ thuộc: chỉ nói khi thiếu, đủ thì im
D="$("$HERE/deps-check.sh" 2>&1)" || { echo; echo "$D"; }
# đường dẫn code/test: sai là githook chặn hụt trong im lặng
UCT_="$(uc_test_dir "$ROOT")"
# Hai mối lo KHÁC NHAU, phải hỏi riêng. Tới 3.4.2 đây là một `if` HOẶC mà thân
# không kiểm lại vế nào đã đúng, nên `code_paths` bị tố "không thư mục nào tồn
# tại" kể cả khi has_code_path TRUE — chỉ vì vế uc_test_dir hỏng (#26). Đó là
# trạng thái MẶC ĐỊNH của mọi repo vừa scaffold: `src/README.md` có sẵn nên
# has_code_path true từ ngày đầu, còn `tests/use-cases/` chỉ sinh ra ở UC đầu
# tiên được implement. Dòng đỏ oan đó bảo người ta đi sửa một file đang đúng —
# sửa xong thì githook mới thật sự chặn hụt, tức nó tự tạo ra cái nó cảnh báo.
CP_OK=0; has_code_path "$ROOT" || CP_OK=1
UT_OK=0; [ -d "$ROOT/$UCT_" ] || UT_OK=1
# uc_test_dir chưa có ở Phase 1–2 là BÌNH THƯỜNG: chưa AC nào implement thì chưa
# có test nào để đặt vào. Chỉ nhắc khi đã có UC implemented mà thư mục vẫn vắng.
UT_SAY=0
if [ "$UT_OK" = 1 ] && all_uc_files "$ROOT" | xargs grep -lE '\*\*Status:\*\* *implemented' >/dev/null 2>&1; then
  UT_SAY=1
fi
if [ "$CP_OK" = 1 ] || [ "$UT_SAY" = 1 ]; then
  echo; echo "=== .sdd/config ==="
  if [ "$CP_OK" = 1 ]; then
    if repo_has_code "$ROOT"; then
      bad "code_paths=$(code_paths "$ROOT") — không thư mục nào tồn tại, mà repo đã có file nguồn."
      info "githook đang chặn hụt. Sửa .sdd/config cho khớp bố cục thật."
    else
      # "chưa có code" không còn đúng khi repo đã khai tool_paths: nó CÓ code,
      # chỉ là code công cụ không thuộc UC nào (#33).
      if [ -n "$(tool_paths "$ROOT")" ]; then
        warn "code_paths=$(code_paths "$ROOT") — chưa thư mục nào tồn tại (repo chưa có code sản phẩm; code công cụ đã khai ở tool_paths)."
      else
        warn "code_paths=$(code_paths "$ROOT") — chưa thư mục nào tồn tại (repo chưa có code)."
      fi
    fi
  fi
  # Nhắc lại chừng nào chưa khớp: `!` lúc init dễ trôi từ lần --update thứ hai
  # trở đi, khi người ta lướt qua output.
  if [ "$UT_SAY" = 1 ]; then
    warn "uc_test_dir=$UCT_ — có UC implemented mà thư mục chưa tồn tại, ac-coverage đang mù. Sửa cho khớp quy ước của repo."
  fi
fi
# UC đang làm đi qua những bước nào — LIỆT KÊ, không chặn (#29). Mọi phép kiểm
# khác đo SẢN PHẨM; không cái nào đo BƯỚC, nên một bước bị bỏ hẳn vẫn đi trọn
# vòng mà không ai biết. Lấy ID từ dòng "Đang làm:" của STATE.md.
UCNOW="$(grep -oE 'UC-[0-9]+' "$ROOT/STATE.md" 2>/dev/null | head -1)"
if [ -n "$UCNOW" ]; then
  FN="$(find_uc "$UCNOW" "$ROOT")"
  [ -n "$FN" ] && grep -qE '\*\*Status:\*\* *deprecated' "$FN" && \
    warn "STATE.md ghi đang làm $UCNOW nhưng UC đó đã deprecated — cập nhật STATE sang UC thay thế (/sdd-solo:state)"
fi
# Bản .sdd/scripts/ cũ chưa có uc-steps.sh — im, đừng gãy cả status vì một mục thêm.
if [ -n "$UCNOW" ] && [ -f "$HERE/uc-steps.sh" ]; then echo; bash "$HERE/uc-steps.sh" "$UCNOW"; fi

# 7.3 — đội agent: chỉ nói khi repo có sổ. Hai phép kiểm của uỷ quyền chạy ở đây, KHÔNG ở cổng DoR hay githook: cổng đo
# chất lượng yêu cầu, không đo phối hợp. (1) mọi DỪNG-<tên> trong hàng đợi phải có tên khai ở ## Điểm dừng; (2) dòng Sổ
# trỏ #n hay decisions thì specs/decisions.md phải có dòng khớp — không thì A quyết xong mà quyết định vô hình với mọi
# phiên sau (đo runxops: 90 dòng Sổ, 81 ô Duyệt trống).
UY="$ROOT/notes/uy-quyen.md"; HQ="$ROOT/notes/hang-doi.md"
if [ -f "$UY" ] || [ -f "$HQ" ]; then
  echo; echo "=== Đội agent (7.3) ==="
  if [ -f "$HQ" ]; then
    for nm in $(grep -oE '\| *DỪNG-[^ |]+' "$HQ" | sed 's/.*DỪNG-//' | sort -u); do
      if [ -f "$UY" ] && grep -qE "^\| *$nm *\|" "$UY"; then ok "DỪNG-$nm có khai ở uy-quyen.md"
      else bad "hàng đợi có DỪNG-$nm nhưng notes/uy-quyen.md ## Điểm dừng không khai tên đó"; fi
    done
    NX="$(bash "$HERE/queue.sh" board 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E 'xong mà Neo trống|nghi-chết' | head -5)"
    [ -n "$NX" ] && printf '%s\n' "$NX" | sed 's/^ *//' | while IFS= read -r l; do warn "$l"; done
  fi
  if [ -f "$UY" ]; then
    DEC="$(decisions_file "$ROOT")"
    grep -E '^\| *[0-9]{4}-[0-9]{2}-[0-9]{2} *\|' "$UY" | while IFS= read -r row; do
      ref="$(printf '%s' "$row" | awk -F'|' '{print $6}')"
      for n in $(printf '%s' "$ref" | grep -oE '#[0-9]+'); do
        grep -qF -- "$n" "$DEC" 2>/dev/null || warn "Sổ uỷ quyền trỏ phiếu $n nhưng $(basename "$DEC") không có dòng nào nhắc $n — quyết định vô hình với phiên sau"
      done
      printf '%s' "$ref" | grep -qi decisions && ! printf '%s' "$ref" | grep -qE '#[0-9]+' && {
        d="$(printf '%s' "$row" | awk -F'|' '{print $2}' | tr -d ' ')"
        grep -qE "^- *$d" "$DEC" 2>/dev/null || warn "Sổ uỷ quyền ngày $d nói 'decisions' nhưng $(basename "$DEC") không có dòng ngày đó"; }
    done
    grep -qE '^<Chủ dự án viết' "$UY" && info "uy-quyen.md ## Phạm vi còn khuôn — điều phối KHÔNG quyết câu L3 nào cho tới khi chủ dự án viết"
  fi
  for hf in "$ROOT"/notes/hoi-dap/hoi-[A-Z]*.md; do [ -f "$hf" ] && bash "$HERE/hoi-check.sh" "$hf" 2>&1 | grep -E '✗|!' | head -3; done
fi

# version: hỏi GitHub tối đa 3s, nhớ 24h. Chỉ nói khi lệch.
V="$("$HERE/version-check.sh" --remote 2>&1)" || { echo; echo "$V"; }
