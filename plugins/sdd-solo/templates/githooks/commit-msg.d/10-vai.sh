#!/usr/bin/env bash
# Ranh giới VAI (7.2) — chạy từ commit-msg vì chỉ ở đây đọc được CẢ message (đuôi `Vai: <V>`) lẫn file đã stage.
# Vai suy theo thứ tự: $SDD_ROLE → đuôi `Vai: <V>` → dấu worktree (role.sh <vai>) → mẫu nhánh <V>.nhanh.
# Không có .sdd/roles → im lặng. vai_bat_buoc=khong (mặc định) → chỉ nhắc. Commit merge → bỏ qua.
# Thay cho pre-commit.d/10-role-boundary.sh (chặn theo nhánh, tới 7.1): XOÁ bản đó nếu còn, kẻo hai mảnh cùng chặn.
RS="$SDD_ROOT/.sdd/scripts/role.sh"
[ -f "$RS" ] || { [ -f "$SDD_ROOT/.sdd/roles" ] && echo "! role.sh chưa có ở .sdd/scripts/ — chạy /sdd-solo:init --update" >&2; exit 0; }
bash "$RS" --commit "$1"
