# 8.5.0 — hai thay đổi:
# (a) rr_max mặc định 3 → 2. Số đo trên runxops: UC chạy 1 vòng giải quyết 79% phát hiện với 1,0 KB mỗi cái;
#     UC chạy 4+ vòng chỉ 34% với 3,5 KB. Thêm vòng không mua được gì, nó mua chữ.
# (b) Học cách BÁO của Spec Kit: cổng đỏ phải nói QUAY LẠI BƯỚC NÀO, không chỉ "NOT THROUGH — N errors".
nr cbao
chk "rr_max mặc định là 2, kể cả repo không khai dòng nào" \
  '[ "$(cd . && bash -c ". \"$P/scripts/lib.sh\"; rr_max \"$PWD\"")" = 2 ]'
chk "dự án MỚI được scaffold ghi rr_max=2" \
  'bash "$P/scripts/scaffold.sh" "$P" "$W/cbmoi" >/dev/null 2>&1; grep -qx "rr_max=2" "$W/cbmoi/.sdd/config"'
# ── dựng UC đỏ ở hai mục khác nhau: §5 (flow) và §7 (adversarial) ──
rm -f "$FL1"
# fixture nền giữ dấu vết TRONG THÂN UC (hình trước 8.0.0), không có file .trace.md
node -e 'const f=require("fs"),p=process.argv[1];f.writeFileSync(p,f.readFileSync(p,"utf8").replace(/^## Adversarial pass[\s\S]*?(?=^## )/m,"## Adversarial pass\n\n"))' "$UC1"
cm "docs(UC-001): bỏ flow và adversarial" 2026-01-06
S gate-check.sh UC-001
chk "cổng đỏ (exit $R)" '[ $R = 1 ]'
chk "kết bằng danh sách bước phải quay lại, không chỉ đếm lỗi" 'has "Next, in this order"'
chk "nêu đúng bước ④ vẽ luồng" 'has "④"'
chk "nêu đúng bước ⑦ adversarial, kèm lệnh gõ được" 'has "/sdd-solo:adversarial UC-001"'
chk "⑧ verify cũng đỏ, đúng luật — spec đổi sau lần đọc lại" 'has "/sdd-solo:verify UC-001"'
chk "không nêu bước đang XANH (③ RULE + entity + glossary)" '! has "RULE + entity + glossary"'
chk "mỗi bước chỉ in một lần dù mục đó đỏ nhiều dòng" \
  '[ "$(printf "%s\n" "$O" | grep -c "sdd-solo:adversarial UC-001")" = 1 ]'
# cổng xanh thì không in gì thêm
nr cbao2
S gate-check.sh UC-001
chk "cổng xanh → không in mục 'Next' (exit $R)" '[ $R = 0 ] && ! has "Next, in this order"'
