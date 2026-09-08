# changes/ — thay đổi trên baseline (Phase 5)

Bắt buộc đi qua đây khi: UC có `Status: implemented` **và** thay đổi làm một AC cũ không còn đúng.
Thêm AC mới mà không phá AC cũ → vẫn là Phase 3, History v+1.

Vòng đời: proposed → specified → designed → applying → verified → archived.
Baseline trong `specs/` chỉ đổi ở bước archive. Delta dùng `ADDED / MODIFIED / REMOVED`.
`REMOVED` không xoá AC khỏi baseline khi archive — đánh dấu `deprecated` kèm ngày.

Copy `.sdd/templates/change/` thành `CHG-###-slug/` (2.0.0 dời template ra khỏi cây nội dung).

## Cổng Phase 5

Copy template xong, điền, commit `docs(CHG-###)`, để qua một đêm, rồi:

    /sdd-solo:change CHG-###

Cổng kiểm cơ học: Why/Impact không còn placeholder · mọi UC trong Scope có thật, đã
`implemented`, đã qua cổng DoR · design có hướng kỹ thuật và đường lùi · mỗi UC trong
Scope có một `delta/UC-###.delta.md` · delta nói đúng về baseline (không `REMOVED` một AC
không tồn tại, không `ADDED` trùng số AC đã có) · có ít nhất một mục `MODIFIED`/`REMOVED`
— không có thì đây là Phase 3, đừng mở change.

Xanh thì `Status` → `applying` và ghi `.sdd/gate/CHG-###.ok`. **Không có marker đó thì
githook chặn mọi commit code gắn `(CHG-###)`.** Không có cờ bỏ qua.
