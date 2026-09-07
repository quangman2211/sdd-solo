# Business Rules

Nơi duy nhất của mỗi rule. UC và AC trích `RULE-###`, không chép nội dung.
Rule có ≥ 3 điều kiện đầu vào → viết DMN decision table (hit policy ghi rõ).

---

## RULE-001: <Tên rule>
- **Phát biểu:** <một câu, không mơ hồ>
- **Áp dụng cho:** UC-###, UC-###
- **Nguồn:** <BR-### · quyết định ngày ___ · quy định pháp lý ___>
- **Status:** active | deprecated (từ YYYY-MM-DD, thay bằng RULE-###)

## RULE-002: <Rule nhiều điều kiện — DMN>
- **Phát biểu:** <một câu>
- **Hit policy:** First (dòng đầu khớp thì dừng) | Unique | Collect
- **Áp dụng cho:** UC-###

| # | Đầu vào A | Đầu vào B | Đầu vào C | → Kết quả | Exception / AC |
|---|---|---|---|---|---|
| 1 | ... | — | — | ... | E# · AC-# |
| 2 | ... | ... | — | ... | ... |

### Tham số của rule
| Tham số | Giá trị | Ghi chú |
|---|---|---|
| <ví dụ Plan.maxDevices theo gói> | ___ | để trống tới khi chốt |

## History
- YYYY-MM-DD: RULE-001 initial
