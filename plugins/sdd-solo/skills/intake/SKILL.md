---
name: intake
description: Bước đầu của Phase 1 — cửa vào của cả quy trình. Không tham số thì phỏng vấn từng câu để moi ý tưởng ra thành BR-###; có đường dẫn brief thì chuyển brief của agent khác thành BR chuẩn theo bộ luật không-bịa-số. Đầu ra là specs/br.md qua được br-check.sh.
disable-model-invocation: true
argument-hint: "[đường-dẫn-brief]"
allowed-tools: Bash Read Write Edit Grep AskUserQuestion
---

Cửa vào Phase 1. `/sdd-solo:start` là bước ① của một UC; đây là bước ① của cả dự án.

Xác định chế độ:
- **`$1` rỗng → phỏng vấn.** Đây là chế độ mặc định và là tình huống hay gặp nhất.
- **`$1` là đường dẫn file → chuyển đổi.** Đọc brief, tách thành BR theo bộ luật ở phần B.

Trước khi bắt đầu, đọc `specs/_intake.md` trong repo (bộ câu hỏi bản giấy) và `specs/br.md`
(xem `BR-000` mẫu). Nếu `br.md` đã có BR thật (khác `BR-000`), hỏi user muốn thêm BR mới hay
sửa BR đang có.

---

## A. Chế độ phỏng vấn

**Kỷ luật của chế độ này — quan trọng hơn bộ câu hỏi:**

- **Một câu một lượt.** Hỏi, chờ trả lời, mới hỏi tiếp. Không bao giờ đưa cả bảy câu ra một lần —
  người đang mơ hồ nhìn bảy câu sẽ không trả lời câu nào.
- **Nhắc lại điều vừa nghe bằng một câu, rồi mới hỏi tiếp.** "Vậy là ___, đúng không anh?"
  Đây là chỗ bắt hiểu nhầm rẻ nhất, và nó cho user thấy mình đang được nghe.
- **"Không biết" là câu trả lời hợp lệ.** Ghi `___` và một dòng Open Question. Không ép.
- **Được gợi ý KHUNG ĐẾM, không được gợi ý NGƯỠNG.** Hai luật "đừng gợi ý số" và "cách đo không
  được để trống" đá nhau với người chưa từng đo cái gì — họ cần một ví dụ, mà ví dụ nào cũng kèm
  con số. Ranh giới: *đếm ở đâu · đếm cái gì · bao lâu một lần* thì được nêu; **ngưỡng bên trong
  khung đó thì không**, luôn để `___` kể cả khi user đã gật.
  Mẫu câu an toàn: *"cách đếm thì kiểu mỗi Chủ nhật mở lại từng kênh, đếm tin để lâu mới trả lời —
  anh thấy làm được không? Còn 'lâu' là bao lâu thì mình chưa chốt, để trống đã."*
- **User gật với con số do MÌNH nêu ra thì con số đó chưa phải của user.** Người đang mơ hồ sẽ gật
  cho xong. Bắt buộc: để `___` ở chỗ ngưỡng, **và** ghi một dòng Open Question nói rõ *"số này do
  người phỏng vấn nêu, user chưa quyết"*. Không có dòng đó thì sáu tháng sau không ai phân biệt
  được số của user với số của máy.
- **Không đề xuất tính năng.** Nếu user hỏi "nên làm gì", trả lời bằng câu hỏi về vấn đề.
  Việc của bước này là hiểu, không phải thiết kế.
- **Nếu user trả lời câu 1 bằng một giải pháp** ("em muốn làm một cái dashboard"), đừng ghi nó
  vào Goal. Hỏi ngược: *"cái dashboard đó để anh biết được chuyện gì mà giờ anh không biết?"*
  BR viết ngược từ giải pháp là lỗi đắt nhất của tầng này.

**Ba câu bắt buộc** — chưa xong ba câu này thì chưa viết file:

1. Hiện đang khổ chuyện gì? (kể tự nhiên, không cần trau chuốt)
2. Ai khổ? (anh · khách · người vận hành · hệ thống khác)
3. Giờ họ xoay xở thế nào, và tốn gì? (thời gian · số lần sai · tiền — không biết thì `___`)

**Bốn câu đào sâu** — chỉ hỏi khi ba câu trên đã có, được phép kết thúc bằng `___`:

4. Nếu không làm gì cả trong sáu tháng nữa thì chuyện gì xảy ra?
5. Có cách nào đạt được điều đó mà **không xây phần mềm** không? (mua sẵn? đổi quy trình? thuê người?)
6. Cái gì mình **cố ý không làm** ở bản đầu?
7. Làm sao biết là đã xong? Đo bằng con số nào, lấy ở đâu?

Câu 5 là câu hay bị bỏ nhất và là câu đáng giá nhất — nó là thứ duy nhất chặn được việc xây
một phần mềm không cần tồn tại. Đừng lướt qua nó vì user đã hào hứng.
Câu 6 sinh ra Out of Scope; câu 7 sinh ra Success Metrics.

**Riêng câu 5 được phép nêu phương án** — đây là ngoại lệ có chủ ý của luật "không đề xuất tính
năng". Người chưa nghĩ tới thì không tự liệt kê được cách làm không-phần-mềm, nên không nêu gì
là bỏ luôn câu hỏi. Hai ràng buộc: chỉ nêu phương án **không-phần-mềm** (đổi quy trình, làm tay
theo lô, mua sẵn, thuê người, một cái kệ và tờ nhãn), và nêu **ít nhất ba** để user không bị dẫn
vào đúng một cái rồi gật.

**Câu 5 trả lời "chưa nghĩ tới" là một kết quả, không phải một chỗ trống.** Ghi vào `## Background`
một dòng `**Vì sao vẫn xây:** chưa có lý do — user chưa cân phương án không-phần-mềm nào` và một
Open Question. Đừng viết dòng đó thành một câu nghe như đã cân nhắc xong. `br-check` cảnh báo khi
thiếu dòng này, và vai hoài nghi ở `/sdd-solo:adversarial BR-###` sẽ bấu thẳng vào nó.

**Viết ra:**

- Câu 1 + 3 → `## Background`. Chỉ những gì user thật sự nói. Con số user nêu thì ghi kèm nguồn
  ("anh đếm tay trong inbox tuần rồi"). Không có nguồn → xuống Open Questions.
- Câu 1 + 2 → `## Goal`, **một câu**, dạng "ai làm được gì mà giờ chưa làm được".
- Câu 7 → `## Success Metrics`. Số để `___` thoải mái; **cách đo thì không được để trống**.
  Chưa có analytics thì viết cách đếm tay — "đếm thread trong inbox mỗi thứ Hai" là một cách đo hợp lệ.
- Câu 6 → `## Out of Scope`, và mỗi dòng thành một nhánh `-.->` trên Impact Map.
- Câu 5 → **luôn** ghi một dòng `**Vì sao vẫn xây:** ...` vào `## Background`, dù câu trả lời là
  gì. Có phương án không-phần-mềm mà user vẫn chọn xây → ghi lý do. Chưa nghĩ tới → ghi thẳng
  *"chưa có lý do"* + Open Question. Dòng này là thứ duy nhất trong BR nói được rằng phần mềm
  này đã được chứng minh là cần tồn tại.
- Câu 4 → `## Background` hoặc một `CON-###` nếu nó là ràng buộc thời gian.
- UC ứng viên → `## Related Use Cases`, **chỉ ID + tên**. Không viết chi tiết UC ở đây.

---

## B. Chế độ chuyển brief

Đọc file, rồi tách thành bốn tầng: vì sao (BR) · ai làm gì (UC ứng viên) · ràng buộc (CON) ·
chưa rõ (Open Questions).

**Bộ luật bắt buộc — không có ngoại lệ:**

1. **Không bao giờ bịa số.** Mọi ngưỡng, thời hạn, quota, quyền mà brief không nêu **nguồn**
   → viết `___` và thêm một dòng Open Question hỏi cụ thể. Kể cả khi brief **có** ghi số:
   không nguồn thì nó là *đề xuất*, không phải quyết định. Ghi `___ (brief đề xuất 15, chưa ai duyệt)`.
2. **Đẩy ngược mọi tính năng lên một tầng.** Mỗi mục dạng "xây X" phải trả lời được *X phục vụ
   mục tiêu nào, đo bằng gì*. Đẩy ngược không ra mục tiêu → đánh dấu là **tính năng mồ côi**,
   đưa vào Out of Scope hoặc Open Question. Không lặng lẽ giữ lại.
3. **Khẳng định không bằng chứng không được vào Background.** Brief hay viết "khách hàng phàn nàn
   nhiều về…" mà không có số. Câu đó thành Open Question *"lấy ở đâu con số này?"*, không thành
   sự thật trong Background.
4. **Ghi ra cái đã bỏ — vào FILE, không phải ra màn hình.** Mọi câu/mục trong brief không được
   đưa vào spec phải thành một dòng `- <mục> — <lý do>` trong mục `## Đã loại khỏi brief` của BR,
   rồi mới đọc lại cho user nghe. Bản 3.2.0 chỉ bảo "in danh sách" nên toàn bộ sản phẩm của luật
   này sống trong lời nói: đóng terminal là mất, và sáu tháng sau không ai biết brief từng có
   những gì và vì sao chúng biến mất. Ba luật trên đều để lại `___` hoặc Open Question trong file;
   luật này cũng phải để lại dấu vết. Xem #21.

   **Bỏ hẳn và hoãn lại là hai việc khác nhau.** Lý do dạng *"thuộc tầng thiết kế"*, *"thuộc
   tầng thiết kế"*, *"thuộc ADR"*, *"thuộc Phase 5"*, *"để sau"* là **hoãn**, và hoãn thì phải
   ghi ĐÍCH: `→ chuyển: architecture.md · ADR-### · CHG-### · Open Question`. Không có
   đích thì không cơ chế nào mang nó đi: `design.md` của mỗi UC do `/sdd-solo:design` sinh ra, và
   nó đọc brief **chỉ khi** `brief_path` đã khai. Đích thường gặp nhất của một mục kiến trúc bị
   hoãn là `specs/internal/architecture.md`, mục `## Đã chốt từ brief`. Ca thật (`runxops`, #34): dòng *"toàn bộ kiến trúc ba lớp — thuộc tầng
   thiết kế"* nằm yên hai ngày trong khi `plan.md` được viết với kiến trúc **ngược lại brief**,
   và không ai thấy vì cả hai bên đều tự nhất quán. Một địa chỉ chuyển tiếp mà không ai giao hàng
   trông y hệt một việc đã bàn giao xong. `br-check` cảnh báo dòng hoãn thiếu `→ chuyển:`.

5. **Không tự viết UC.** Chỉ sinh ID + tên UC ứng viên.
6. **Ghi nguồn vào Metadata của BR:** dòng `- **Nguồn:** brief <đường/dẫn>`. Đó là thứ cho
   `br-check.sh` biết BR này phải có mục `## Đã loại khỏi brief`.
7. **Neo brief lại — hai việc, cả hai bắt buộc.** Sau intake, brief thành file **chỉ-ghi**: cả ba
   lớp kiểm của plugin (`gate-check`, `verify`, ba vai adversarial) đều chỉ nhìn trong `specs/`.
   Nên phải tự tay đưa nó vào tầm nhìn:

```bash
# a) khai vào .sdd/config — đưa brief vào THỨ TỰ ĐỌC BẮT BUỘC của mọi session sau.
#    Repo init trước 3.21.0 KHÔNG có sẵn dòng brief_path=, và `sed` trên một dòng
#    không tồn tại im lặng không làm gì — nên phải hỏi trước rồi mới chọn nhánh.
if grep -q '^brief_path=' .sdd/config; then
  sed -i.bak "s|^brief_path=.*|brief_path=$1|" .sdd/config && rm -f .sdd/config.bak
else
  printf 'brief_path=%s\n' "$1" >> .sdd/config
fi
grep '^brief_path=' .sdd/config        # in ra để thấy nó đã vào thật
# b) neo phiên bản brief vào br.md — brief đổi sau intake thì br-check báo đỏ
printf '**Nguồn brief:** %s · sha256 %s · nạp %s\n' \
  "$1" "$(shasum -a 256 "$1" | cut -c1-12)" "$(date +%F)"
```
   Dán dòng `**Nguồn brief:**` vào Metadata của BR, ngay dưới `- **Nguồn:**`. Thiếu (a) thì
   session sau không biết brief tồn tại; thiếu (b) thì brief sửa lúc nào cũng không ai biết, và
   hai tài liệu nói ngược nhau trong im lặng.

**Ranh giới số — số nào cấm, số nào không.** Luật 1 cấm số ở chỗ **quyết định nghiệp vụ**: ngưỡng,
thời hạn, quota, quyền. Nó **không** cấm số ở chỗ **cách đo**: "bấm giờ 20 lượt đặt bàn liên tiếp"
là một cách đo cụ thể và tốt hơn hẳn "bấm giờ vài lượt". Cách đo mơ hồ thì metric không kiểm được,
tức mất đúng thứ `BR-000` đang dạy. Cụ thể ở cách đo là đúng; cụ thể ở quyết định mà không có ai
duyệt là bịa.

Vì sao bộ luật này gắt: brief do LLM viết gần như luôn kèm số nghe hợp lý mà không ai quyết —
*"khoá 15 phút sau 5 lần sai"*, *"giữ tồn kho 30 phút"*. Chép thẳng vào `specs/` thì từ đó trở đi
cả bộ 24 kiểm ở cổng DoR sẽ bảo vệ những con số ngầm ấy rất kỷ luật. Đó đúng là thứ
`sdd-process` gọi là quyết định ngầm, chỉ khác là model đã lấp sẵn trước khi repo tồn tại.

---

## C. Kết thúc (cả hai chế độ)

1. Ghi vào `specs/br.md`: thêm mục `BR-###` mới **trước** khung `BR-001` trống, hoặc thay khung
   đó nếu nó chưa được đụng tới. Giữ nguyên `BR-000` mẫu.
2. Vẽ Impact Map: `WHY → WHO → HOW → WHAT`, và **ít nhất một nhánh `-.->`** cho Out of Scope.
   Không có nhánh đứt nào nghĩa là chưa map gì — chỉ là đường thẳng từ Goal xuống việc đã định sẵn.
3. Chạy kiểm và in nguyên output:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/br-check.sh" BR-###
```
(nếu `${CLAUDE_PLUGIN_ROOT}` không được thay: `find ~/.claude/plugins -type f -name br-check.sh -path '*sdd-solo*' | head -1`).
Còn ✗ thì sửa cùng user rồi chạy lại. Cảnh báo `___` là **bình thường ở Phase 1** — nói rõ điều
đó cho user, đừng để user tưởng mình làm sai.
4. Commit: `git add specs/br.md && git commit -m "docs(BR-###): intake — <tên BR>"`.
5. STATE.md: `Đang làm: BR-### · Phase 1 — BR đã viết`. `Việc tiếp theo: /sdd-solo:adversarial BR-### (ba vai tầng BR), rồi /sdd-solo:start UC-### cho UC đầu tiên`.
6. Nói với user hai điều: những chỗ còn `___` là nợ đã ghi sổ chứ không phải lỗi; và bước sau
   `/sdd-solo:adversarial BR-###` sẽ hỏi ngược lại chính BR này bằng ba vai, đặc biệt là vai
   hoài nghi — *"BR này có thật là BR, hay là một giải pháp đã chọn sẵn rồi viết ngược thành lý do?"*

Không viết code. Không thiết kế kỹ thuật. Không tạo thư mục UC — đó là việc của `/sdd-solo:start`.
