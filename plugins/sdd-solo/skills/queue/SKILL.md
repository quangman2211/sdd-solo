---
name: queue
description: Hàng đợi việc của điều phối (7.3) — notes/hang-doi.md trong git, máy đọc; add · next (việc phát được ngay) · take · done (chỉ khi có KETQUA + neo) · stop <tên dừng> · board. Dùng khi điều phối phát việc, hỏi "phát được gì tiếp", hay xem bảng giao việc.
disable-model-invocation: true
argument-hint: "add <khoá> <làn> <vai> [--can \"k1 k2\"] | next | take <khoá> [ai] | done <khoá> | stop <khoá> <tên> | board | list"
allowed-tools: Bash Read
---

Chạy `queue.sh` với `$ARGUMENTS`:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/queue.sh" $ARGUMENTS
```
(không thay được biến: `find ~/.claude/plugins -type f -name queue.sh -path '*sdd-solo*' | head -1`; trong dự án: `.sdd/scripts/queue.sh`).

- **Chỉ điều phối ở checkout chính ghi** — `add|take|done|stop` từ chối ở worktree phụ. Agent không ghi bảng; agent ghi
  KETQUA (`role.sh --ketqua`), `done` đọc KETQUA và kiểm neo rồi mới ghi dòng. Mỗi lần ghi là một commit `--only`.
- `next` = mọi `Cần` đã `xong` và làn còn chỗ (bảng `## Làn`, cột Sức chứa). Hỏi máy, không hỏi trí nhớ.
- `done` không có KETQUA `ket=xong` + neo → đỏ. `xong` mà Neo trống là đỏ ở `board`. Thời gian trôi không phải bằng chứng:
  việc `đang` quá hạn (mặc định 90 phút, `--qua-han N`) chỉ cắm cờ `nghi-chết` để điều phối đi nhìn.
- `stop <khoá> <tên>` → `DỪNG-<tên>`; tên phải có ở `notes/uy-quyen.md ## Điểm dừng`, `status.sh` kiểm.
- Khoá việc `[a-z0-9][a-z0-9._-]{1,39}` — đồng thời là tên file KETQUA. Gợi ý: `<vai>-<id>-p<phiếu>[-l<lượt>]` như
  `role.sh` in ở phần 6 của lời giao.

Không tự quyết thứ tự việc thay điều phối; không đổi trạng thái theo thời gian.
