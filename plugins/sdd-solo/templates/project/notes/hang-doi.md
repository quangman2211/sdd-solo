# Hàng đợi — bảng chạy của điều phối

<!-- File CỦA điều phối (vai A), trong git, máy đọc bằng .sdd/scripts/queue.sh. Agent KHÔNG ghi file này — agent ghi
     KETQUA (role.sh --ketqua); `queue.sh done` đọc KETQUA, kiểm neo, rồi mới ghi dòng. Worktree phụ chỉ đọc, qua
     `git show main:notes/hang-doi.md`, để không đọc bản cũ của nhánh mình (queue.sh tự làm).
     Trạng thái là tập đóng: chờ · đang · xong · bỏ · DỪNG-<tên>  (tên khai ở notes/uy-quyen.md ## Điểm dừng).
     `xong` mà cột Neo trống là đỏ — thời gian trôi không phải bằng chứng. Cần: nhiều khoá cách nhau bằng dấu cách. -->

## Làn
| Làn | Sức chứa | Vùng ghi |
|---|---|---|
| spec | 1 | specs/** |
| code | 2 | src/** tests/** |

## Việc
| Khoá | Làn | Vai | Cần | Trạng thái | Neo | Ghi chú |
|---|---|---|---|---|---|---|
