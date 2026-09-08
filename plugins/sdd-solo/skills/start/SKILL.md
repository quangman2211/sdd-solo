---
name: start
description: Bước ① của vòng lặp UC — tạo folder use case từ template, gán ID, kiểm ID chưa trùng và BR tồn tại, ghi STATE.md. Dùng khi user bắt đầu một use case mới.
disable-model-invocation: true
argument-hint: "UC-### [<ctx>] [<slug-tieng-anh>]"
allowed-tools: Bash Read Write Edit Glob Grep
---

Tạo khung cho use case `$1`.

1. Xác định root repo (`git rev-parse --show-toplevel`). Nếu thiếu `specs/` → bảo chạy `/sdd-solo:init` trước.
2. ID: `$1` phải dạng `UC-###`. Kiểm chưa tồn tại: `find specs/contexts -path "*use-cases/$1-*"`. Trùng → dừng, báo.
3. Context (`$2`): nếu không có, liệt kê `specs/contexts/*/` và hỏi user chọn. Nếu context chưa có → hỏi có tạo từ `.sdd/templates/context/` không.
4. Slug (`$3`): tiếng Anh, kebab-case, là động từ + danh từ theo glossary (ví dụ `activate-device`). Không có → đề xuất từ tên UC trong `specs/contexts/<ctx>/use-cases.md` nếu UC đã có stub ở đó, rồi hỏi xác nhận.
5. Tạo:
   - `specs/contexts/<ctx>/use-cases/$1-<slug>/` từ `.sdd/templates/use-case/` (copy `UC-000.md` → `$1.md`, `UC-000.sequence.md` → `$1.sequence.md`, `screens/README.md`). Thay mọi `UC-000` thành `$1`, `<ctx>` thành context, `Last updated` thành hôm nay, `Status: draft`.
   - Kiểm BR: hỏi user UC này phục vụ BR nào; phải có heading `# BR-###` trong `specs/br.md`. Điền vào Metadata.
   - Thêm/cập nhật dòng của UC trong bảng `specs/contexts/<ctx>/use-cases.md`.
6. STATE.md: sửa dòng `Đang làm:` thành `$1 · bước ① — khung đã tạo, chưa có nội dung`; `Việc tiếp theo:` thành `/use-case-spec $1 (AIUP) rồi viết RULE + AC`.
7. Báo user: đường dẫn file, và bước tiếp là `/use-case-spec $1` — **ghi vào file vừa tạo**, không tạo file mới. Nếu user không dùng AIUP, viết Main Flow cùng user theo skill `sdd-process`.
8. Không viết code. Không commit (commit docs đầu tiên do `/sdd-solo:adversarial` làm).
