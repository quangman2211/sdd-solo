# pre-commit.d/ — luật riêng của repo (#50)

Mọi file **thực thi** (`chmod +x`) trong thư mục này chạy sau các kiểm của `.sdd/hooks/pre-commit`,
theo thứ tự tên. Exit ≠ 0 là chặn commit. `.example` và `README.md` không chạy. Plugin **không đụng**
file của anh ở đây khi `init --update` — chỉ làm mới `README.md` và các `.example`.

Hook mẹ export cho script con: `SDD_ROOT` · `SDD_STAGED` (file đã stage, mỗi dòng một file) ·
`SDD_CODE_PATHS` · `SDD_TEST_PATHS` · `SDD_UC_TEST_DIR` (đọc từ `.sdd/config`).

Hook nằm trong git, nên **mỗi worktree chạy bản hook của nhánh nó**: luật mới thêm trên `main`
chỉ có hiệu lực ở nhánh khác sau khi nhánh đó `merge main`. Ca thật: sửa hook trên `main`, commit thử
ở worktree `code/uc-014` → không chặn, phải `reset --hard`.

**Thử luật `.d` ở worktree:** hook mẹ tìm `.d/` dưới `git rev-parse --show-toplevel` **của worktree đó**,
nên `git -c core.hooksPath=<repo chính>/.sdd/hooks commit` ở worktree vẫn **không** chạy luật `.d` (thư mục
`.d` của worktree chưa có file) — commit lọt. Hai cách đúng: `merge main` vào worktree trước, hoặc gọi thẳng
script với env: `SDD_STAGED="$(git diff --cached --name-only)" SDD_CODE_PATHS=src SDD_UC_TEST_DIR=tests/use-cases
bash .sdd/hooks/pre-commit.d/10-role-boundary.sh`.
