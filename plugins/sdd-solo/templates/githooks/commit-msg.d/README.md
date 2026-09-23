# commit-msg.d/ — luật riêng của repo (#50)

Mọi file **thực thi** (`chmod +x`) trong thư mục này chạy sau các kiểm của `.sdd/hooks/commit-msg`, theo thứ tự tên,
nhận đường dẫn file message làm `$1`. Exit ≠ 0 là chặn commit. `.example` và `README.md` không chạy. Plugin **không
đụng** file của anh ở đây khi `init --update` — chỉ làm mới `README.md`, các `.example`, và **`10-vai.sh`** (của plugin).

Hook mẹ export: `SDD_ROOT` · `SDD_STAGED` · `SDD_CODE_PATHS` · `SDD_TEST_PATHS` · `SDD_UC_TEST_DIR` · `SDD_MSG` (dòng đầu).

`10-vai.sh` (7.2) — ranh giới **vai** theo `.sdd/roles`: gọi `.sdd/scripts/role.sh --commit <msg>`. Vai suy từ `$SDD_ROLE`
→ đuôi `Vai: <V>` trong message → dấu worktree (`role.sh <vai>`) → mẫu nhánh. Không có `.sdd/roles` thì im lặng;
`vai_bat_buoc=khong` (mặc định) chỉ nhắc, `nhanh-vai`/`moi` chặn. Hook ghi thêm đuôi `Vai: <V>` khi suy được, nên
`git log --grep '^Vai: '` đo được ai ghi gì. Bản 7.1 chặn theo nhánh ở `pre-commit.d/10-role-boundary.sh` — xoá nếu còn.
