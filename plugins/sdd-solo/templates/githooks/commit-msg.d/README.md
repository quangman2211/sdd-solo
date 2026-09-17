# commit-msg.d/ — luật riêng của repo về thông điệp commit (#50)

Mọi file **thực thi** ở đây chạy sau `.sdd/hooks/commit-msg`, nhận **đường dẫn file thông điệp** làm
`$1` (như hook gốc); hook mẹ export thêm `SDD_MSG` (dòng đầu), `SDD_ROOT`, `SDD_STAGED`,
`SDD_CODE_PATHS`, `SDD_TEST_PATHS`, `SDD_UC_TEST_DIR`. Exit ≠ 0 là chặn. `.example` và `README.md`
không chạy; plugin không đụng file của anh khi `init --update`. Hook theo nhánh khi dùng worktree —
xem `pre-commit.d/README.md`.
