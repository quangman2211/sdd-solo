---
name: role
description: Vai của đội agent (7.2) — đặt dấu vai cho worktree, dựng worktree riêng cho vai, in lời giao sáu phần từ một phiếu, ghi KETQUA. Dùng khi điều phối giao việc cho agent spec/trọng tài/code/test, hoặc một phiên agent cần biết mình là vai nào.
disable-model-invocation: true
argument-hint: "<vai> | <vai> <file phiếu> [--luot N] | --xem | --worktree <vai> [UC-###] | --ketqua <khoá> ket=… neo=…"
allowed-tools: Bash Read
---

Chạy `role.sh` với `$ARGUMENTS`:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/role.sh" $ARGUMENTS
```
(nếu `${CLAUDE_PLUGIN_ROOT}` không được thay: `find ~/.claude/plugins -type f -name role.sh -path '*sdd-solo*' | head -1`;
trong dự án đã `init --update` thì `.sdd/scripts/role.sh` là bản sao chạy được không cần plugin).

Cơ chế ở plugin, chính sách ở `.sdd/roles` của repo (vai nào · ghi đâu · cấm đâu · nhánh · có commit không). Chưa có
`.sdd/roles` → bảo user chạy `/sdd-solo:init --update` rồi sửa bộ vai mẫu (A điều phối · B spec · R trọng tài · D code · T test).

| Lệnh | Làm gì | Nói với user |
|---|---|---|
| `<vai>` | ghi dấu vai cho **worktree này** (`.git[/worktrees/<tên>]/sdd-role`, không vào git, không theo nhánh) và in hợp đồng | vai này được ghi gì, cấm gì; hook `commit-msg.d/10-vai.sh` chỉ nhắc khi `vai_bat_buoc=khong` |
| `--xem` | vai hiện tại: `$SDD_ROLE` → dấu worktree → mẫu nhánh | không suy được thì chưa có gì ép |
| `--worktree <vai> [UC-###]` | dựng worktree `../<repo>-<vai>[-uc-###]` trên nhánh theo `<V>.nhanh`, đặt dấu | **vai spec giữ checkout chính trên `main`** — cái B viết là sự thật chung, ngồi worktree riêng thì vai khác đọc `main` cũ tới khi merge; hook trong worktree là bản lúc tách, mở lượt bằng `git merge main` |
| `<vai> <file phiếu>` | in **lời giao sáu phần**: mục tiêu · gói đọc `file:mục` · việc chép nguyên phần `Cho: <vai>` + neo · vùng cấm · lệnh kiểm + cách commit · dòng KETQUA | chỉ nhận **file phiếu**, không nhận chuỗi tự do — neo chỉ có trong phiếu. Dài > 1.500 ký tự thì ghi file rồi `prompt "$(cat file)"`. Sửa câu mục tiêu nếu cần, rồi gửi |
| `--ketqua <khoá> ket=xong neo=<hash>` | ghi một dòng KETQUA vào `$(git rev-parse --git-common-dir)/sdd-ketqua/<khoá>.txt` — chung mọi worktree, ngoài git | agent gọi **trước** khi gửi tin về; `ket=xong` bắt buộc `neo` có thật, `ket=chan` bắt buộc `hoi=`. Tin nhắn mất thì file còn (P-26) |
| `--kiem-lich-su [range]` | chỉ đọc: chạy luật vùng ghi qua lịch sử, đếm commit không vai nào được ghi đủ | chạy **trước** khi bật `vai_bat_buoc` để biết ranh giới là thật hay diễn |

Luật của skill: không tự sửa `.sdd/roles` thay user; không giao việc cho vai từ chuỗi tự do; không đề xuất viết code.
Vai spec/trọng tài/code/test chạy dưới lời giao: gặp điều spec chưa nói → `bash .sdd/scripts/phieu.sh new "<việc>" <vai>` rồi
**dừng**, không `AskUserQuestion`.
