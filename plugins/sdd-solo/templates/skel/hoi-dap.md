# Hỏi đáp giữa các agent

Sổ append-only. Agent (B · spec, C · soi, D · code, T · test, Q · QA) gặp điều spec chưa nói thì **ghi phiếu
rồi dừng** — không `AskUserQuestion`, không nhắn agent khác. R · trọng tài xếp mức và trả lời ngay dưới phiếu;
A · điều phối chuyển phần `Cho:` tới từng vai, hoặc hỏi chủ dự án khi L3. Không phải spec: quyết định nào
thành luật thì B đưa vào `specs/`, A ghi `specs/internal/decisions.md`.

Quyền tự quyết mặc định: R tự quyết tới **L2**; L2 là quyết **tạm**, ô `Duyệt:` để trống chờ chủ dự án.
Lật quá ___ quyết định của R trong một tuần thì hạ quyền R xuống L1.

## Bốn mức

| Mức | Loại câu | R làm gì |
|---|---|---|
| **L0 · Tra được** | Đáp án đã có trong spec / ADR / decisions / glossary / design | Trả lời, **bắt buộc kèm `file:dòng`**. Không có nguồn → không phải L0 |
| **L1 · Kỹ thuật cục bộ** | Trong phạm vi `architecture.md` / `design.md` đã chốt; sai thì sửa < 30 phút, không ai ngoài repo thấy | Tự quyết, ghi lý do |
| **L2 · Diễn giải** | Spec đọc được hai cách, nhưng cách nào **khách cũng không thấy khác** | Quyết **tạm**, việc chạy tiếp; ô `Duyệt:` để trống chờ chủ dự án |
| **L3 · Chủ dự án** | Số · ngưỡng · enum · quyền · giá · hình dạng UC · thư viện/nơi chạy mới · đổi hành vi UC đã implemented · bỏ bước quy trình · gate/close · push/deploy/xoá/gửi ra ngoài · khoá, dữ liệu thật | **Không quyết.** Soạn câu hỏi 2–4 lựa chọn, mỗi lựa chọn một câu hệ quả, lựa chọn đề xuất đặt đầu, luôn có "Chưa quyết — ghi Open Question" |

**Luật xếp mức**
1. Không có nguồn thì không phải L0.
2. Phân vân giữa hai mức → chọn mức **cao hơn**.
3. Bài kiểm một câu: *nếu quyết sai, khách có thấy khác, hoặc Main Flow có phải viết lại không?* Có → L3.
4. Hộp thoại xin quyền của Claude Code không phải câu hỏi của sổ này — luôn chuyển chủ dự án.
5. R không sửa file nào ngoài sổ này, và không commit — A commit.
6. C hay đẩy lên chủ dự án cái `design.md` đã quyết: R **tra design trước** khi xếp; câu "cần chủ dự án
   chốt" của C chỉ tới chủ dự án **sau khi R xác nhận L3**.

## Khuôn phiếu

```
### #<n> · từ: <spec|soi|code|test|qa> · việc: <BR-###|UC-###|…> · <YYYY-MM-DD>
Câu: <một câu>
Đã tra: <file:dòng, …>
Nếu chọn sai thì: <hậu quả>
Agent nghiêng về: <lựa chọn + vì sao>

**Trả lời (R):** <mức L0–L3> · <câu trả lời, hoặc câu hỏi soạn sẵn cho chủ dự án>
Nguồn / lý do: <file:dòng hoặc lý do>
Cho: <spec · D · T — mỗi vai một dòng nói phải làm gì; thứ tự áp nếu có>
Duyệt: <để trống · chủ dự án ghi "nhận" hoặc "lật: …" — bắt buộc với L2 và L3>
```

Một phiếu có thể gom nhiều phát hiện (K1…Kn của một lượt soát): R xếp mức từng K trong một bảng
`| K | Mức | Quyết tạm | Cho |`, cuối phiếu ghi **thứ tự áp** (spec trước · D · T) — ba vai áp song song vì chỉ
cần chữ của phiếu.

## Phiếu

