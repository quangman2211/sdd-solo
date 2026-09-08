# Intake — bộ câu hỏi để moi ý tưởng ra thành BR

Dùng khi `specs/br.md` còn trắng và chưa biết bắt đầu từ đâu.
Có Claude Code thì gõ `/sdd-solo:intake` — nó hỏi từng câu và tự viết ra `br.md`.
Không có thì tự trả lời bảy câu dưới đây bằng giấy bút, rồi điền vào `br.md` theo cột bên phải.

**Ba quy tắc khi trả lời:**

1. **"Không biết" là câu trả lời hợp lệ.** Ghi `___` và đánh dấu thành Open Question.
   Một con số đoán bừa ở đây sẽ được cả bộ 24 kiểm ở cổng DoR bảo vệ suốt phần đời còn lại của dự án.
2. **Kể chuyện, đừng kê tính năng.** Nếu câu trả lời bắt đầu bằng "xây một cái…" thì đó là
   giải pháp, không phải vấn đề. Hỏi ngược mình: *cái đó để tôi biết hoặc làm được chuyện gì mà giờ không?*
3. **Một câu một lượt.** Đọc cả bảy câu rồi ngồi nghĩ chung sẽ ra bảy câu trả lời chung chung.

---

## Ba câu bắt buộc

Chưa xong ba câu này thì chưa viết `br.md`.

| # | Câu hỏi | Vào đâu trong br.md |
|---|---|---|
| 1 | Hiện đang khổ chuyện gì? Kể tự nhiên, không cần trau chuốt. | `## Background` · `## Goal` |
| 2 | Ai khổ? (tôi · khách · người vận hành · hệ thống khác) | `## Goal` · WHO trên Impact Map |
| 3 | Giờ họ xoay xở thế nào, và tốn gì? (thời gian · số lần sai · tiền) | `## Background` |

Chỗ trả lời — viết thẳng vào đây:

> **1.**
>
> **2.**
>
> **3.**

Câu 3 là chỗ ra con số baseline. Chưa đếm bao giờ thì ghi `___` **và ghi luôn cách sẽ đếm** —
"đếm thread trong inbox mỗi thứ Hai" là một cách đo hợp lệ, không cần analytics.

## Bốn câu đào sâu

Chỉ hỏi khi ba câu trên đã có. Được phép kết thúc bằng `___`.

| # | Câu hỏi | Vào đâu trong br.md |
|---|---|---|
| 4 | Nếu không làm gì cả trong sáu tháng nữa thì chuyện gì xảy ra? | `## Background` hoặc `CON-###` |
| 5 | Có cách nào đạt được điều đó mà **không xây phần mềm** không? (mua sẵn? đổi quy trình? thuê người?) | `## Background` — ghi lý do vẫn chọn xây |
| 6 | Cái gì mình **cố ý không làm** ở bản đầu? | `## Out of Scope` + nhánh `-.->` trên Impact Map |
| 7 | Làm sao biết là đã xong? Đo bằng con số nào, lấy ở đâu? | `## Success Metrics` |

**Câu 5 là câu đáng giá nhất và hay bị bỏ nhất.** Nó là thứ duy nhất chặn được việc xây một
phần mềm không cần tồn tại. Đang hào hứng thì càng phải hỏi.

Chỗ trả lời:

> **4.**
>
> **5.**
>
> **6.**
>
> **7.**

**Câu 6 không có câu trả lời = BR chưa nghĩ xong.** Team có PO cản scope; làm một mình thì
chỉ có dòng Out of Scope đó cản.

---

## Xong rồi thì

```bash
.sdd/scripts/br-check.sh BR-001
```

Cảnh báo về `___` là **bình thường ở Phase 1** — đó là nợ đã ghi sổ, không phải lỗi.
Dòng ✗ mới là thứ phải sửa.

Rồi `/sdd-solo:adversarial BR-001` — ba vai đọc ngược lại BR vừa viết. Vai hoài nghi hỏi đúng
một câu đáng sợ: *BR này có thật là một BR, hay là một giải pháp đã chọn sẵn rồi viết ngược
thành lý do?*

---

## Nếu đang cầm một brief do agent khác viết

```
/sdd-solo:intake đường/dẫn/brief.md
```

Đừng chép thẳng vào `specs/`. Brief do LLM viết gần như luôn kèm số nghe hợp lý mà không ai
quyết — *"khoá 15 phút sau 5 lần sai"*, *"giữ tồn kho 30 phút"*, *"hỗ trợ 100 người dùng đồng
thời"*. Không con số nào có nguồn. Chép vào rồi thì từ đó trở đi cả bộ kiểm ở cổng DoR sẽ bảo
vệ chúng rất kỷ luật.

Bốn luật khi chuyển:

1. Số không nguồn → `___` + Open Question. Brief **đề xuất** một con số ≠ ai đó **đã duyệt** nó.
2. Mọi "xây X" phải đẩy ngược lên được một mục tiêu đo được. Không ra → tính năng mồ côi,
   vào Out of Scope hoặc Open Question, không giữ im lặng.
3. Khẳng định không bằng chứng ("khách phàn nàn nhiều") → Open Question, không vào Background.
4. Thứ đã **bỏ** phải ghi vào mục `## Đã loại khỏi brief` trong BR, mỗi dòng một lý do — không
   phải chỉ nói miệng rồi thôi. Sáu tháng sau, thứ duy nhất còn lại là file.
