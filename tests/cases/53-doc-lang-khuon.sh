# P-45 (8.1.1): plugin chỉ còn khuôn tiếng Anh từ 7.8.0, nhưng `init --update` vẫn áp bản dịch lên
# nội dung của dự án. Ở runxops: 3 file bị ghi đè thẳng (khối CLAUDE.md · specs/adr/_adr-template.md ·
# specs/core/br-000/br.md) và 11 file .new là khuôn tiếng Anh trống, không có gì để gộp.
# Đo phía plugin: cả diff templates/project 7.7.0 → 8.1.0 là THUẦN DỊCH — 0 file mới, 0 mục mới.
nr lang
SHA() { bash -c ". \"$P/scripts/lib.sh\"; sha \"$1\""; }
SC() { O="$(bash "$P/scripts/scaffold.sh" "$P" "$PWD" --update 2>&1)"; R=$?; }
VN='# Quyết định — bảng tra'
DEC=specs/decisions.md
# ① file CHƯA ai sửa (sha khớp manifest) mà khuôn đã đổi → tới 8.1.0 là ghi đè thẳng
printf '%s\n\nMột dòng một quyết định.\n' "$VN" > "$DEC"
grep -v "^specs/decisions.md " .sdd/manifest > .sdd/manifest.t && mv .sdd/manifest.t .sdd/manifest
echo "$DEC $(SHA "$DEC") 0000000000000000000000000000000000000000000000000000000000000000" >> .sdd/manifest
# ② file KHÔNG có dòng manifest → tới 8.1.0 là sinh .new
ADR=specs/adr/_adr-template.md
mkdir -p specs/adr; printf '# ADR-### — <tên quyết định>\n' > "$ADR"
grep -v "^specs/adr/_adr-template.md " .sdd/manifest > .sdd/manifest.t && mv .sdd/manifest.t .sdd/manifest
# ③ khối CLAUDE.md tiếng Việt
node -e '
const fs=require("fs"); const p="CLAUDE.md"; let s=fs.readFileSync(p,"utf8");
s=s.replace(/<!-- sdd-solo:begin -->[\s\S]*?<!-- sdd-solo:end -->/,
  "<!-- sdd-solo:begin -->\n## Quy trình SDD-Solo\nKhông viết code trước khi UC qua cổng DoR.\n<!-- sdd-solo:end -->");
fs.writeFileSync(p,s);'
sed -i.bak 's/^doc_lang=.*/doc_lang=vi/' .sdd/config && rm -f .sdd/config.bak

SC
chk "doc_lang=vi: file chưa sửa KHÔNG bị ghi đè bằng bản dịch (exit $R)" \
  '[ $R = 0 ] && head -1 "$DEC" | grep -qF "Quyết định"'
chk "doc_lang=vi: không sinh .new cho file không có dòng manifest" \
  '[ ! -f "$ADR.new" ] && head -1 "$ADR" | grep -qF "tên quyết định"'
chk "doc_lang=vi: khối CLAUDE.md giữ nguyên" \
  'grep -qF "Không viết code trước khi UC qua cổng DoR" CLAUDE.md'
chk "và nói rõ vì sao, kèm cách chọn ngược lại" \
  'printf "%s\n" "$O" | grep -qF "doc_lang=vi" && printf "%s\n" "$O" | grep -qF "put doc_lang=en in .sdd/config"'
chk "chạy lần hai không hỏi lại (dòng manifest đã ghi lại sha khuôn mới)" \
  'SC; [ $R = 0 ] && ! printf "%s\n" "$O" | grep -qF "keep    $DEC"'
# file THIẾU thì vẫn tạo — tiếng Anh vẫn hơn là không có
rm -f specs/traceability.md
SC
chk "doc_lang=vi: file thiếu thì vẫn tạo" '[ -f specs/traceability.md ]'

# doc_lang=en là cách chọn ngược lại, và nó vẫn ghi đè như cũ
sed -i.bak 's/^doc_lang=.*/doc_lang=en/' .sdd/config && rm -f .sdd/config.bak
grep -v "^specs/decisions.md " .sdd/manifest > .sdd/manifest.t && mv .sdd/manifest.t .sdd/manifest
printf '%s\n\nMột dòng một quyết định.\n' "$VN" > "$DEC"
echo "$DEC $(SHA "$DEC") 0000000000000000000000000000000000000000000000000000000000000000" >> .sdd/manifest
SC
chk "doc_lang=en: file chưa sửa ĐƯỢC cập nhật như cũ (exit $R)" \
  '[ $R = 0 ] && head -1 "$DEC" | grep -qF "lookup table"'
chk "doc_lang=en: khối CLAUDE.md được thay như cũ" \
  '! grep -qF "Không viết code trước khi UC qua cổng DoR" CLAUDE.md'
