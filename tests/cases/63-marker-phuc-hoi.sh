# 8.7.0 — P-62 (gate-check --pre đọc HTML comment là ô trống) và P-61 (UC sống lại sau deprecate thì mất
# marker cổng, và không cửa nào cấp lại được).

# ── P-62 ────────────────────────────────────────────────────────────────────────────────────────────
# Guard tới 8.6.0 chỉ bỏ qua dòng BẮT ĐẦU bằng `<!--`. Một chú thích ở CUỐI dòng Metadata thì `<[^>]+>`
# khớp ngay, và --pre gọi nó là "ô chưa điền" — không có cách nào điền một chú thích.
nr p62
rep "$UC1" '- **Owner:** anh' '- **Owner:** ai <!-- tạm để đây, hỏi lại ở vòng sau -->'
S gate-check.sh --pre UC-001
chk "P-62 · chú thích HTML cuối dòng Metadata không phải ô trống (exit $R)" \
  'has "no placeholder left" && ! has "tạm để đây"'
# khối chú thích nhiều dòng: dòng giữa có <...> cũng không tính
nr p62b
ins_after "$UC1" '## Metadata' '<!--
  khuôn cũ: **Owner:** <tên người>
  bỏ khi nào chốt
-->'
S gate-check.sh --pre UC-001
chk "P-62 · khối chú thích nhiều dòng: <tên người> bên trong không tính" 'has "no placeholder left"'
# và không nới tay: một ô trống THẬT ngoài chú thích vẫn đỏ
nr p62c
rep "$UC1" '- **Owner:** anh' '- **Owner:** <tên người> <!-- chưa ai nhận -->'
S gate-check.sh --pre UC-001
chk "P-62 · ô <...> THẬT ngoài chú thích vẫn đỏ (không nới tay)" 'has "still unfilled" && has "<tên người>"'

# ── P-61 ────────────────────────────────────────────────────────────────────────────────────────────
# deprecate gỡ .sdd/gate/UC-###.ok (đúng — UC bị bỏ không giữ cổng), nhưng UC sống lại thì hai cửa cùng
# đóng: gate-check gọi status implemented là đỏ nên pass.sh gate không chạy được, còn change-check đỏ
# "implemented mà không có .ok". Ở runxops 25/09 lối ra duy nhất là moi blob cũ khỏi git bằng tay.
nr p61
S pass.sh gate UC-001
chk "dựng: UC-001 qua cổng, có marker (exit $R)" '[ $R = 0 ] && [ -f .sdd/gate/UC-001.ok ]'
HASH0="$(head -1 .sdd/gate/UC-001.ok)"
S pass.sh deprecate UC-001 "gộp vào UC-002" -
chk "dựng: deprecate gỡ marker" '[ ! -f .sdd/gate/UC-001.ok ]'
# UC sống lại: status về implemented (đúng cách runxops làm — sửa Status + ## History)
rep "$UC1" '**Status:** deprecated' '**Status:** implemented'
S pass.sh gate UC-001
chk "cửa cũ vẫn đóng: pass.sh gate từ chối UC implemented (exit $R)" '[ $R = 1 ]'
S pass.sh restore UC-001
chk "P-61 · pass.sh restore lấy lại marker (exit $R)" '[ $R = 0 ] && [ -f .sdd/gate/UC-001.ok ]'
chk "P-61 · dòng 1 vẫn ĐÚNG hash cổng cũ, không phải hash mới" '[ "$(head -1 .sdd/gate/UC-001.ok)" = "'"$HASH0"'" ]'
chk "P-61 · file ghi lại nó là bản phục hồi, lấy từ đâu" 'grep -q "restored:" .sdd/gate/UC-001.ok'
chk "P-61 · marker được commit" '[ -z "$(git status --porcelain .sdd/gate/UC-001.ok)" ]'
S pass.sh restore UC-001
chk "P-61 · chạy lần hai: từ chối, đã có marker (exit $R)" '[ $R = 1 ] && has "nothing to restore"'

# restore KHÔNG bịa: không có gì trong lịch sử thì đỏ
nr p61b
rep "$UC1" '**Status:** draft' '**Status:** implemented'
S pass.sh restore UC-001
chk "P-61 · git không có marker nào trong lịch sử → đỏ, không tạo file (exit $R)" \
  '[ $R = 1 ] && [ ! -f .sdd/gate/UC-001.ok ] && has "does not invent"'
# UC chưa qua cổng thì chỉ đường về cổng thật, không về restore
nr p61c
S pass.sh restore UC-001
chk "P-61 · UC còn draft → chỉ về cổng thật, không phục hồi" '[ $R = 1 ] && has "pass.sh gate UC-001"'

# hai cửa đang đóng phải NÓI ra lối này (8.5.0: một phát hiện phải nói đi đâu tiếp)
nr p61d
S pass.sh gate UC-001
rep "$UC1" '**Status:** reviewed' '**Status:** implemented'
rm -f .sdd/gate/UC-001.ok
S gate-check.sh UC-001
chk "P-61 · gate-check trên UC implemented thiếu marker chỉ sang restore" 'has "pass.sh restore UC-001"'

# ── lỗi kèm theo, của 8.4.0 ─────────────────────────────────────────────────────────────────────────
# `role_current` kết thúc bằng `grep -q` của vòng lặp, nên KHÔNG tìm thấy vai là trả exit 1. pass.sh chạy
# `set -e`, và khối chữ ký 8.4.0 gọi `SV="$(role_current "$ROOT")"` như một lệnh đứng một mình → repo có
# khai `<vai>.ky` mà không suy được vai thì pass.sh CHẾT IM LẶNG, exit 1, không một dòng. Chính ca mà
# comment 8.4.0 nói là "vẫn cho phép — đó là chủ dự án ở checkout không đánh dấu".
nr kychet
app .sdd/roles 'A.ky=gate close'
git add -A && git commit -q --no-verify -m "roles: A ký được"
chk "role_current không tìm thấy vai thì vẫn exit 0 (không phải mìn cho set -e)" \
  'bash -c ". \"$P/scripts/lib.sh\"; role_current \"$PWD\" >/dev/null"'
S pass.sh gate UC-001
chk "pass.sh gate: khai .ky mà không suy được vai → vẫn chạy, không chết im lặng (exit $R)" \
  '[ $R = 0 ] && [ -f .sdd/gate/UC-001.ok ] && [ -n "$O" ]'
