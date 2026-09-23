# tests/ — bộ test của plugin (7.1.0)

```
bash tests/run.sh            # mọi ca; exit 1 khi có FAIL
bash tests/run.sh p18        # ca có tên chứa p18
SDD_TEST_KEEP=1 bash tests/run.sh   # giữ thư mục làm việc để xem repo giả
bash tests/snap.sh <repo thật> <thư mục ra>   # chụp đầu ra mọi script để diff trước/sau
```

Bốn kết quả: **PASS** · **FAIL** (hồi quy — chặn phát hành) · **XFAIL** (lỗi còn mở, ca mô tả hành vi *đúng*
mà bản này chưa có) · **XPASS** (lỗi đã hết — đổi `xfail` sang `chk`, ghi CHANGELOG).

- `lib.sh` — helper: `nr` (repo giả mới), `S` (chạy script, `$O` đầu ra, `$R` exit), `has`, `chk`, `xfail`,
  `cm` (commit `--no-verify` có ngày), `cmv` (commit CÓ hook), `rep`/`ins_after`/`app` (sửa file), `gate_pass`, `code_uc1`.
- `fixtures/v7/` — nội dung repo giả 7.0 (một nghề `orders`, một lát `BR-001`, `UC-001` đã adversarial + đọc lại,
  qua cổng DoR xanh). `mkbase` chạy `scaffold.sh` thật rồi chép đè, dựng 4 commit có ngày cố định.
- `cases/NN-<slug>.sh` — mỗi ca một file, tên mang số lỗi (`P-##` của `runxops/notes/sdd-solo-issues.md`, `#nn` của
  CHANGELOG). Thêm lỗi mới: viết ca `xfail` **trước** khi sửa script, chạy thấy XFAIL, sửa, thấy XPASS, đổi sang `chk`.

Luật viết ca: không `cd` ra ngoài `$W`; mọi commit qua `cm` trừ khi ca đo githook; không pipe sau `S` (exit code
của pipe là của lệnh cuối). bash 3.2: không mảng kết hợp, không `case` trong `$( )`, biến không đặt sát ký tự
nhiều byte trong `echo`.
