---
name: design
description: Bước ⑩ — thiết kế kỹ thuật cho một UC đã qua cổng DoR. Sinh design.md + tasks.md trong thư mục UC, đối chiếu ngược lên specs/internal/architecture.md và lên brief nguồn. Dùng sau /sdd-solo:gate và TRƯỚC khi viết dòng code đầu tiên.
disable-model-invocation: true
argument-hint: "UC-###"
allowed-tools: Bash Read Write Edit Grep Glob AskUserQuestion
---

Thiết kế cho `$1`.

**Vì sao bước này thuộc về sdd-solo chứ không thuê ngoài:** bốn tầng yêu cầu (BR · UC · Entity · AC)
trả lời *vì sao · ai làm gì · khái niệm nào · biết đúng bằng cách nào*. **Không tầng nào trả lời
*dựng bằng gì · chạy ở đâu · ai gọi*.** Trước 4.0.0 câu đó rơi vào một công cụ ngoài, và công cụ ấy
đọc đúng hai thứ: một file mỏng chỉ chứa ID, và một `constitution.md` mà ở repo thật vẫn nguyên
placeholder. **Brief không nằm trong hai đầu vào đó và chưa bao giờ nằm** — nên bản thiết kế nói
ngược lại brief suốt hai ngày mà không ai thấy, vì mỗi tài liệu tự nó nhất quán (#34).

---

## 1. Cổng vào

```bash
ls "$(git rev-parse --show-toplevel)/.sdd/gate/$1.ok"
```

Không có → **dừng**. Bảo user chạy `/sdd-solo:gate $1` trước. Thiết kế cho một UC chưa qua cổng là
thiết kế cho một spec còn đang đổi. **Không sinh file nào** trong lượt này.

## 2. Đọc — sáu nguồn, đọc hết rồi mới viết

1. `UC-###.md` (Main Flow · Exceptions · AC · `**Giả định triển khai:**`) + `UC-###.flow.md`
2. các `RULE-###` mà UC trích, đọc trong `specs/rules.md` — **chỉ những cái được trích**
3. `entities.md` + `glossary.md` của context
4. mục `BR-###` mà UC trỏ tới trong `specs/br.md`, **gồm cả `## Đã loại khỏi brief`**
5. **brief nguồn** — `grep '^brief_path=' .sdd/config`; có thì đọc file đó. Đây là nguồn duy nhất
   mà không phép kiểm nào khác trong plugin được giao nhìn tới.
6. `specs/internal/architecture.md` + các `ADR-###` liên quan

Thiếu (6) hoặc nó còn `<...>` → **dừng và làm nó trước**, cùng user. Một `design.md` đối chiếu lên
một hiến pháp trống là một lượt đối chiếu rỗng, và phép thử rỗng trông y hệt phép thử qua.

## 3. Viết `design.md`

Copy `.sdd/templates/use-case/UC-000.design.md` sang `<thư mục UC>/design.md`, đổi `UC-000` thành
`$1`, rồi điền cùng user. Sáu mục, và hai mục giữa là lý do cả bước này tồn tại:

- `## Tóm tắt` · `## Bối cảnh kỹ thuật` (ngôn ngữ · phụ thuộc · lưu trữ · test · nền chạy)
- **`## Đối chiếu architecture.md`** — bảng sáu dòng. Mỗi chỗ **đi khác** hiến pháp phải nằm ở đây
  kèm lý do và một `ADR-###` có thật. Không lệch chỗ nào thì vẫn phải viết ra là không lệch.
- **`## Đối chiếu brief`** — brief đòi gì mà thiết kế này **không** làm, và vì sao. Không có brief
  thì ghi thẳng *"dự án không có brief nguồn"*.
- `## Cấu trúc code` (đường dẫn thật) · `## Rủi ro & độ phức tạp`

**Gặp quyết định kỹ thuật mà cả UC lẫn `architecture.md` đều chưa nói** (chọn thư viện, chọn kiểu
lưu trữ, chọn giao thức) → **DỪNG và hỏi user** bằng `AskUserQuestion`, đúng luật đã áp cho quyết
định nghiệp vụ. Đừng chọn mặc định rồi ghi vào file như thể đã bàn.

Quyết định nào **đổi hiến pháp** chứ không chỉ áp dụng nó → ghi vào `architecture.md`, không giấu
trong `design.md` của một UC. Một quyết định cấp dự án nằm trong thư mục một UC là chỗ UC thứ hai
sẽ không bao giờ tìm thấy.

## 4. Viết `tasks.md`

Copy `.sdd/templates/use-case/UC-000.tasks.md` sang `<thư mục UC>/tasks.md`. **Mỗi AC một dòng,
một việc, một file test** `tests/use-cases/<ctx>/$1/AC-#.test.*`. Không chép nội dung AC sang —
chép là tạo bản thứ hai để sau này lệch nhau. Việc không gắn AC nào (dựng khung, cấu hình) xuống
mục riêng ở cuối.

## 5. Kiểm bằng máy, in nguyên output

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/design-check.sh" $1
```
(nếu `${CLAUDE_PLUGIN_ROOT}` không được thay: `find ~/.claude/plugins -type f -name design-check.sh -path '*sdd-solo*' | head -1`)

Đỏ → sửa rồi chạy lại. Không viết code khi còn một dòng ✗.

## 6. Commit riêng

```bash
git add specs/ && git commit -m "docs($1): thiết kế — design.md + tasks.md"
```

## 7. Nói với user

Bước tiếp là ⑪ **viết code theo `tasks.md`**, test đỏ trước. Nhắc ba chỗ hay sai khi đọc `design.md`:
RULE có được kiểm **trước** khi tạo record không · logic RULE nằm ở domain hay lỡ rơi xuống adapter ·
chuyển trạng thái có đúng state diagram trong `entities.md` không.

---

## Giới hạn — nói với user, không giấu

1. **`design-check` đo sự CÓ MẶT, không đo sự ĐÚNG.** Nó biết mục `## Đối chiếu architecture.md`
   có nội dung; nó **không** biết nội dung ấy có thật là kết quả của một lượt đối chiếu hay không.
   Thứ duy nhất bắt được chỗ đó là user đọc. Đừng nói "đã đối chiếu xong" khi ý là "script xanh".
2. **Không viết code trong bước này.** Kể cả một hàm nhỏ để "thử xem có chạy không".
3. **Không tự sửa spec.** Thiết kế lộ ra một chỗ UC sai → nói ra, để user quyết; sửa UC đã qua cổng
   là việc của `/sdd-solo:gate` chạy lại, hoặc của Phase 5 nếu UC đã `implemented`.
