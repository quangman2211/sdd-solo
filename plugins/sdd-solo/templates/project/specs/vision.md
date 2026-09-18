# Hướng — tầng 0

- **Status:** draft
- **Nguồn:** <lời chủ dự án · brief `<đường/dẫn>`>
- **Last updated:** ___

> Tầng trên BR. BR trả lời *vì sao làm lát này*; file này trả lời *đi về đâu* và *cái gì không được
> co lại* khi bộ lọc bằng chứng của BR làm việc. Ca thật đẻ ra nó: một BR bị co ba lần qua ba
> lượt adversarial — mỗi lần đều đúng luật "không số thì không vào Background" — cho tới khi thứ
> còn lại nhỏ hơn hẳn ý định ban đầu, và không phép kiểm nào thấy, vì không tầng nào giữ ý định.
>
> **Miễn luật "không số".** Ở đây số là ý muốn của chủ dự án, không phải sự thật cần nguồn.
> Chỗ chưa biết vẫn để `___`, nhưng không ai đòi bằng chứng cho một hướng đi.
>
> Người viết là **chủ dự án**, bằng lời thường. `/sdd-solo:intake` chỉ hỏi và chép lại; không
> agent nào tự viết mục nào ở đây. Sửa file này là commit `docs(vision): …`.

## Định vị
<Một câu: sản phẩm này là gì, cho ai, và điều gì làm nó khác.>

## Không thu hẹp
<3–5 điều. Mỗi dòng một điều BR nào cũng không được đưa vào Out of Scope. `br-check` đỏ khi một
dòng Out of Scope của BR chứa cụm trong mục này — trừ khi dòng đó ghi
`cố ý thu hẹp — chủ dự án chốt YYYY-MM-DD`.>
- <điều 1>
- <điều 2>
- <điều 3>

## Nghề và lát
<Mỗi nghề là một thư mục `specs/<nghề>/`; `core` là lõi dùng chung, ngang hàng với nghề. Mỗi lát
là một `br-###/` trong thư mục đó. BR khai `**Lát:** <nghề> · <tên lát>` — tên lát phải có ở bảng này.>

| Nghề | Lát | BR | Trạng thái | Mở khi |
|---|---|---|---|---|
| core | <đăng nhập · console> | BR-### | đang làm | — |
| <nghề 1> | lát 1 "<phát hiện>" | BR-### | đang làm | — |
| <nghề 1> | lát 2 "<vận hành>" | ___ | chờ | lát 1 xong |
| <nghề 2> | ___ | ___ | điều kiện mở | <nghề 1> "xong" (mục dưới) |

Mỗi thời điểm **một nghề** đang mở. Nghề sau mở khi nghề trước "xong" theo mục dưới — không phải
khi thấy hứng.

## "Xong" của mỗi nghề
<Điều kiện đóng một nghề để mở nghề kế. Hai vế: pack chạy được không cần dev, và đã có ít nhất
một lát vận hành (chiều ghi) giao xong. Số ngày là ý muốn của chủ dự án — ví dụ runxops chốt
2026-09-18: 7 ngày liên tục.>
- <nghề 1>: pack chạy ___ ngày liên tục không dev sửa gì **và** ít nhất một lát vận hành đã giao (BR-___ implemented)
- <nghề 2>: ___

## Sổ sửa ngược
<Append-only. Một UC hay BR phát hiện tầm nhìn sai ở điểm nào thì ghi ở đây, không sửa lặng lẽ
mục trên. Mỗi dòng: ngày · ai phát hiện · trước → sau.>
- YYYY-MM-DD — UC-### sửa tầm nhìn ở điểm ___: <trước> → <sau>

## Open Questions
- [ ] <câu hỏi về hướng đi mà chủ dự án chưa quyết> (quyết định tạm: ___)

## History
- v1 (YYYY-MM-DD): initial
