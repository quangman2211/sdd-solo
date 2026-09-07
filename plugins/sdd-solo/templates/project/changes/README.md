# changes/ — thay đổi trên baseline (Phase 5)

Bắt buộc đi qua đây khi: UC có `Status: implemented` **và** thay đổi làm một AC cũ không còn đúng.
Thêm AC mới mà không phá AC cũ → vẫn là Phase 3, History v+1.

Vòng đời: proposed → specified → designed → applying → verified → archived.
Baseline trong `specs/` chỉ đổi ở bước archive. Delta dùng `ADDED / MODIFIED / REMOVED`.
`REMOVED` không xoá AC khỏi baseline khi archive — đánh dấu `deprecated` kèm ngày.

Copy `_template/` thành `CHG-###-slug/`.
