---
name: phieu
description: Phiếu hỏi đáp có khoá số (7.2) — cấp số kế tiếp bằng máy (khoá nguyên tử chung mọi worktree, commit dòng giữ chỗ ngay), đóng phiếu đếm F#/K# trên file và đòi KETQUA từng vai, soát mục lục. Dùng khi agent cần mở phiếu mới, khi điều phối đóng phiếu, hoặc khi nghi mục lục lệch.
disable-model-invocation: true
argument-hint: "new \"<việc>\" <từ-vai> [slug] | close <n> | muc-luc | list [--mo]"
allowed-tools: Bash Read
---

Chạy `phieu.sh` với `$ARGUMENTS`:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/phieu.sh" $ARGUMENTS
```
(không thay được biến: `find ~/.claude/plugins -type f -name phieu.sh -path '*sdd-solo*' | head -1`; trong dự án đã
`init --update`: `.sdd/scripts/phieu.sh`).

- `new "<việc>" <từ-vai>` — **giữ số trước, viết thân sau.** Script khoá bằng `mkdir` ở `git-common-dir` (chung mọi
  worktree), số = max của mục lục ∪ tên file ∪ `git log --all "phiếu #n"` (bắt cả phiếu ở worktree chưa merge), tạo
  `notes/hoi-dap/phieu/NNN-<slug>.md` theo khuôn, thêm dòng mục lục, **commit ngay** dòng giữ chỗ bằng `--only`. In `#n
  <đường dẫn>`. Sau đó agent điền Câu · Đã tra · Nếu chọn sai thì · Agent nghiêng về, commit riêng
  `chore(sdd): phiếu #n — <việc>` kê đích danh file. Sổ 6.x ở `specs/internal/hoi-dap.md` cũng nhận.
- `close <n>` — đếm `F#`/`K#` **trên file**, so với số phiếu tự khai (lệch → đỏ, kê số thiếu — P-33); mỗi vai có việc
  trong `Cho:` phải có `KETQUA ket=xong` (`role.sh --ketqua`) — thiếu → đỏ. Đủ thì mục lục → `đã áp`, commit.
- `muc-luc` — số trùng · số nhảy · file không dòng · dòng không file. Chạy chỉ đọc trên sổ hiện có trước khi tin nó.
- `list [--mo]` — in mục lục; `--mo` chỉ phiếu chưa `đã áp`/`đóng`.

Không tự viết thân phiếu thay agent; không xếp mức L0–L3 (việc của R); không hỏi user bằng `AskUserQuestion` khi chạy
dưới lời giao — phiếu chính là câu hỏi.
