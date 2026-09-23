# 8.0.0: dấu vết ở file cạnh — migrate --trace dời ra, cổng cho CÙNG verdict, chạy lại không đổi một byte
nr trace
# ── verdict TRƯỚC khi dời ──
S gate-check.sh UC-001; B4="$O"; R4=$R
S uc-steps.sh UC-001; S4="$O"
chk "cổng đọc được dấu vết trong THÂN UC (bản trước 8.0.0, exit $R4)" '[ $R4 = 1 ] || [ $R4 = 0 ]'
# ── dời ──
S migrate.sh --trace
chk "migrate --trace exit 0, báo đã dời UC-001" '[ $R = 0 ] && has "UC-001.md" && has "3 section(s)"'
chk "thân UC không còn ba mục dấu vết" '! grep -qE "^## (Adversarial pass|Đọc lại|History)$" "$UC1"'
chk "thân UC có con trỏ ## Evidence" 'grep -q "^## Evidence" "$UC1"'
# tiêu đề ở file cạnh là tiêu đề TRẦN — '## Đọc lại', không phải '## Đọc lại — <ngày>'. Tiêu đề có ngày là
# thứ pass.sh close viết cho một khối đã CẤT ĐI, và cổng chỉ đọc khối trần (ev_body). Đặt ngày ở đây thì mọi UC
# từng đóng một lần sẽ có dấu vết rỗng dưới mắt cổng.
chk "file cạnh UC-001.trace.md có đủ ba mục, tiêu đề trần" '[ -f "$UCD/UC-001.trace.md" ] && [ "$(grep -cE "^## (Adversarial pass|Đọc lại|History)$" "$UCD/UC-001.trace.md")" = 3 ]'
# khối đã cất đi (tiêu đề có ngày) không được gộp vào khối sống
app "$UCD/UC-001.trace.md" ""
app "$UCD/UC-001.trace.md" "## Đọc lại — 2025-01-01"
app "$UCD/UC-001.trace.md" "- F9 khối đã cất đi [neo: Main 1] → đã sửa AC-1"
S gate-check.sh UC-001
chk "khối lưu trữ có ngày KHÔNG bị đọc vào dấu vết sống" '! has "F9"'
chk "dòng F1 nguyên văn ở file cạnh, không ở thân" 'grep -q "^- F1 Main 2 nói gửi" "$UCD/UC-001.trace.md" && ! grep -q "^- F1 Main 2 nói gửi" "$UC1"'
# ── verdict SAU khi dời: phải giống hệt ──
# migrate KHÔNG commit (đúng thiết kế của mọi chế độ migrate), nên commit ở đây — không thì §9 đỏ vì
# "có thay đổi spec chưa commit", và phép đo sẽ đo cái khác chứ không đo việc dời.
cm "docs(UC-001): đọc lại — dời dấu vết sang file cạnh" 2026-01-04
S gate-check.sh UC-001; A4="$O"
chk "gate-check: cùng số ✓ và ✗ trước/sau khi dời" '[ "$(printf "%s\n" "$B4" | grep -c ✓)" = "$(printf "%s\n" "$A4" | grep -c ✓)" ] && [ "$(printf "%s\n" "$B4" | grep -c ✗)" = "$(printf "%s\n" "$A4" | grep -c ✗)" ]'
S uc-steps.sh UC-001
chk "uc-steps: cùng đầu ra trước/sau khi dời" '[ "$O" = "$S4" ]'
# ── chạy lại không đổi gì ──
H1="$(find specs -name '*.md' | sort | xargs shasum -a 256 | shasum -a 256)"
S migrate.sh --trace
chk "chạy lần hai: không còn gì để dời" '[ $R = 0 ] && has "already keeps its trail beside it"'
S migrate.sh --trace >/dev/null
H2="$(find specs -name '*.md' | sort | xargs shasum -a 256 | shasum -a 256)"
chk "ba lần chạy → cây specs/ giống nhau từng byte" '[ "$H1" = "$H2" ]'
# ── --dry-run không đụng đĩa ──
nr trace2
H1="$(find specs -name '*.md' | sort | xargs shasum -a 256 | shasum -a 256)"
S migrate.sh --trace --dry-run
H2="$(find specs -name '*.md' | sort | xargs shasum -a 256 | shasum -a 256)"
chk "--dry-run in ra việc sẽ làm nhưng không ghi gì" '[ $R = 0 ] && has "would move" && [ "$H1" = "$H2" ]'
# ── dự án MỚI: khuôn đã tách sẵn, không cần migrate ──
chk "khuôn UC-000.md không còn mục dấu vết nào" '! grep -qE "^## (Adversarial pass|Re-read|History)$" "$P/templates/skel/use-case/UC-000.md"'
chk "khuôn UC-000.trace.md có đủ ba mục" '[ "$(grep -cE "^## (Adversarial pass|Re-read|History)$" "$P/templates/skel/use-case/UC-000.trace.md")" = 3 ]'
