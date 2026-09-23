# Uỷ quyền — điều phối quyết thay chủ dự án

<!-- Khuôn (7.3). Chủ dự án viết Phạm vi; điều phối chỉ được quyết trong đó. Đây là CHÍNH SÁCH của repo, plugin
     không ship điểm dừng thật — năm dòng dưới là mẫu lấy từ runxops, đổi tên tuỳ ý. Hai phép kiểm chạy ở
     .sdd/scripts/status.sh: mọi `DỪNG-<tên>` trong notes/hang-doi.md phải có tên ở bảng Điểm dừng; mỗi dòng Sổ trỏ
     `#n` hay decisions thì specs/decisions.md phải có dòng khớp — không thì quyết định vô hình với mọi phiên sau. -->

## Phạm vi
<Chủ dự án viết, nguyên văn: uỷ quyền cho điều phối quyết gì, tới khi nào. Ví dụ: "bốn BR đã chốt, chạy tới khi mọi UC
implemented". Trống mục này thì điều phối KHÔNG quyết câu L3 nào.>

## Thứ tự nguồn — dừng ở nguồn đầu tiên có câu trả lời
1. `specs/decisions.md` — đã chốt thì không hỏi lại.
2. `specs/vision.md` — tầng 0; điều phối **không sửa, không lật**. Vision sai → một dòng `## Sổ sửa ngược` + dòng Sổ dưới, đi tiếp bằng `___`.
3. <tài liệu làm rõ của dự án, theo thứ tự ưu tiên — hoặc bỏ dòng này>
4. Brief nguồn (`brief_path` trong `.sdd/config`).
5. Không nguồn nào nói → phương án **đảo ngược được, rẻ nhất, không thu hẹp một gạch `## Không thu hẹp`**; con số thì
   **không bịa**: `___` + Open Question + quyết định tạm, design để nó thành tham số.

Mỗi lần quyết một câu L3: ô `Duyệt:` của phiếu ghi `A theo uỷ quyền <ngày> · nguồn <file:dòng>`; một dòng
`specs/decisions.md` như thường (Loại · Bị loại · Chi tiết) ghi rõ "A theo uỷ quyền"; và một dòng ở `## Sổ`.

## Điểm dừng — điều phối dừng LÀN đó, ghi STATE, nói một câu, không chờ ở làn khác
| # | Dừng khi | Ai gỡ |
|---|---|---|
| S1 | Cần `git push` / deploy / ghi lên máy ngoài | chủ dự án |
| S2 | Cần chạm dữ liệu thật, tài khoản thật của khách | chủ dự án |
| S3 | Cần tiền, khoá, tài khoản mới | chủ dự án |
| S4 | Câu hỏi đổi **nghĩa** của `specs/vision.md` | chủ dự án |
| S5 | UC đã ___ vòng đọc lại mà vòng sau vẫn có chặn — dấu hiệu BR/trục đổi, không phải thiếu chữ | điều phối ghi phiếu "hết vòng"; chủ dự án chốt trục; làn khác chạy tiếp |

## Sổ — câu L3 điều phối đã quyết thay (mới nhất dưới cùng)
| Ngày | Câu | Chọn | Nguồn | Phiếu / decisions |
|---|---|---|---|---|
