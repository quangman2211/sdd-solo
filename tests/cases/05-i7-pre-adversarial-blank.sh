# #52 (I-7): ___ trong ## Adversarial pass không tính là chưa điền ở --pre
nr pre52
ins_after "$UC1" "## Adversarial pass" "- Vai kẻ lợi dụng: ___ (lượt 2 chưa chạy)"
S gate-check.sh --pre UC-001
chk "--pre: dòng ___ trong Adversarial pass không tính (exit $R)" '[ $R = 0 ] && ! has "lượt 2 chưa chạy"'
