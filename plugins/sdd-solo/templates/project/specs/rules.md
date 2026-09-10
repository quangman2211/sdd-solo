# Business Rules

Nơi duy nhất của mỗi rule. UC và AC trích `RULE-###`, không chép nội dung.
Rule có ≥ 3 điều kiện đầu vào → viết DMN decision table (hit policy ghi rõ).

---

## RULE-000: <Tên rule — ĐÂY LÀ MẪU, xoá hoặc đổi số trước khi dùng>
- **Phát biểu:** <một câu, không mơ hồ>
- **Áp dụng cho:** UC-###, UC-###
- **Từ:** YYYY-MM-DD
- **Vì sao:** <lý do đặt ra rule này>
- **Nguồn:** <BR-### · quyết định ngày ___ · quy định pháp lý ___>
- **Status:** active | deprecated (từ YYYY-MM-DD, thay bằng RULE-###)

<!-- `Vì sao` là trường đắt nhất cho mốc 5–10 năm, và là trường dễ bỏ trống nhất vì lúc viết
     thì lý do đang hiển nhiên. Nó KHÁC `Nguồn`: nguồn nói rule này TỪ ĐÂU RA, vì sao nói
     rule này TỒN TẠI ĐỂ LÀM GÌ. Một rule mất `Vì sao` thì năm năm sau không ai dám bỏ nó —
     không phải vì nó còn đúng, mà vì không ai biết bỏ đi thì hỏng chuyện gì. Rule kiểu đó
     tích lại thành thứ không ai gỡ được.

     `Nguồn ... nguyên văn: "..."` — khi nguồn là một ID khác (BR-###, CON-###), CHÉP ĐÚNG
     CHỮ của nguồn vào, đừng diễn đạt lại. Ca thật ở CHANGELOG 4.x: một dòng dán nhãn
     `BR-001` cho một câu mà `BR-001` không hề nói, và nó ĐẢO NGHĨA điều cấm. Đọc vẫn trôi
     chảy, qua mọi phép kiểm — vì mọi luật chỉ kiểm ID CÓ TỒN TẠI, không kiểm ID CÓ NÓI ĐÚNG
     THỨ ĐANG GẮN NÓ. Chép nguyên văn là động tác duy nhất làm nó lộ ra. -->

## RULE-000b: <Rule nhiều điều kiện — DMN — MẪU>
- **Phát biểu:** <một câu>
- **Hit policy:** First (dòng đầu khớp thì dừng) | Unique | Collect
- **Áp dụng cho:** UC-###
- **Từ:** YYYY-MM-DD
- **Vì sao:** <lý do>
- **Status:** active

| # | Đầu vào A | Đầu vào B | Đầu vào C | → Kết quả | Exception / AC |
|---|---|---|---|---|---|
| 1 | ... | — | — | ... | E# · AC-# |
| 2 | ... | ... | — | ... | ... |

### Tham số của rule
| Tham số | Giá trị | Ghi chú |
|---|---|---|
| <ví dụ Plan.maxDevices theo gói> | ___ | để trống tới khi chốt |

## History
- YYYY-MM-DD: RULE-### initial
