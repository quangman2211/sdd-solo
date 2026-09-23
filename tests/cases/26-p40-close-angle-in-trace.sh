# P-40: pass.sh close không nén mục vết khi thân có <...> không phải khuôn (ví dụ <hash>, <label>)
nr p40
ins_after "$UC1" "- F1 Main 2" "- F2 màn hình chép nguyên HTML [neo: Screens] → không phải lỗi vì commit <hash> đã bỏ <label for=\"np-go\">"
cm "docs(UC-001): đọc lại — F2" 2026-01-06
S pass.sh gate UC-001; code_uc1
S pass.sh close UC-001
chk "P-40 · ## Đọc lại có <hash> vẫn được dời sang trace.md" '[ -f "$UCD/UC-001.trace.md" ] && grep -q "^## Đọc lại" "$UCD/UC-001.trace.md"'
