# sdd-solo — Spec-Driven Development cho một dev + AI

Plugin Claude Code đóng gói quy trình SDD-Solo: giữ nguyên bốn tầng yêu cầu của Spec-Driven Development (BR → Use Case → Entity → Acceptance Criteria), thêm biểu đồ chuẩn ở mỗi tầng (flow và state bằng Mermaid, DMN, UML, Impact Map, Story Map), chèn Claude Design thành một bước chính thức, và thay mọi cơ chế cần người thứ hai bằng cơ chế một người làm được: adversarial pass ba vai, cổng Definition of Ready trước khi viết code, tầng thiết kế hai mức, `STATE.md` thay standup, git hook thay reviewer.

Nền: ebook *Spec Driven Development* (Nguyễn Thế Huy) · AI Unified Process · GitHub Spec Kit · OpenSpec — đọc để học **hình dạng artifact**; từ 4.0.0 plugin không phụ thuộc lệnh của cái nào.

## Cài

```
/plugin marketplace add quangman2211/sdd-solo
/plugin install sdd-solo@sdd-solo
```

Rồi trong repo dự án: `/sdd-solo:init`. Phụ thuộc bắt buộc chỉ có `git` — không cần cài thêm plugin nào.

Rồi **`/sdd-solo:intake`** — nó hỏi bảy câu (khổ gì · ai khổ · tốn gì · không làm thì sao · có cách nào không xây phần mềm · cố ý không làm gì · đo bằng gì) và viết `specs/br.md` giúp bạn. Đang cầm brief do một AI khác viết thì `/sdd-solo:intake brief.md`.

Tuỳ chọn, **không cái nào nằm trong 14 bước** (từ 4.0.0):
- **Claude Design** — cần cho Phase 0 và bước ⑤ (Design System, màn hình SCR). Đây là thứ tuỳ chọn đáng cài nhất.
- **GitHub Spec Kit** — nguồn tham khảo thiết kế tốt và update thường xuyên; cứ cài và cứ đọc. Chỉ một luật: nó ghi vào `.speckit/`, không ghi vào `specs/`. Xem [Vì sao Spec Kit ra khỏi chuỗi](#vì-sao-spec-kit-ra-khỏi-chuỗi).
- **AIUP** · **Camunda Modeler** — không cần. AIUP ghi ra cây `docs/` và đụng hệ ID; sơ đồ luồng vẽ bằng Mermaid nên không cần app nào.

## Dùng

Trong repo dự án:

| Lúc nào | Lệnh |
|---|---|
| Lần đầu / sau khi update plugin | `/sdd-solo:init` · `/sdd-solo:init --update` |
| Mở session | hook tự đọc `STATE.md`, nói đang ở bước nào |
| **Bắt đầu dự án — chưa biết viết gì** | `/sdd-solo:intake` (phỏng vấn 7 câu) hoặc `/sdd-solo:intake brief.md` (chuyển brief của agent khác) |
| BR viết xong | `/sdd-solo:adversarial BR-###` — ba vai người trả tiền / vận hành mãi / hoài nghi |
| Bắt đầu một use case | `/sdd-solo:start UC-### [ctx] [slug]` rồi viết nội dung UC cùng AI |
| Sau khi viết RULE, AC, vẽ flow, vẽ màn hình | `/sdd-solo:adversarial UC-###` → `/sdd-solo:verify UC-###` (hoặc **đóng máy**, đọc lại buổi sau) |
| Đọc lại xong | `/sdd-solo:gate UC-###` → xanh thì `/sdd-solo:design UC-###` → viết code theo `tasks.md` |
| Code xong | `/sdd-solo:close UC-###` |
| Cuối buổi | `/sdd-solo:state` |
| Đang tới đâu · có đang chạy bản cũ không | `/sdd-solo:status` |
| Có bản mới | `/sdd-solo:init --plugin` — chạy trọn ba khe, rồi mở session mới |

Bốn câu để nhớ: **Viết xong chưa? Vẽ xong chưa? Soi xong chưa? Qua cổng chưa?**

## Cái gì nằm ở đâu

Từ 2.0.0, repo dự án chỉ còn **hai thư mục của quy trình**:

```
.sdd/     bộ máy — config, gate/, scripts/, hooks/, checklists/, prompts/, templates/
specs/    toàn bộ nội dung — br.md rules.md contexts/ internal/ changes/
STATE.md  CLAUDE.md  <code>/  <tests>/
```

- **`.sdd/`** giữ bộ máy, kể cả **một bản sao script kiểm** — nên `bash .sdd/scripts/gate-check.sh UC-###` chạy được ở CI và trên máy người clone repo, không cần cài plugin. Lệch version so với plugin thì hook và `status` cảnh báo.
- **`specs/`** giữ mọi thứ mô tả hệ thống. Ranh giới spec↔doc không mất, nó tụt một tầng: khách cảm nhận được → `contexts/`, chỉ người xây quan tâm → `internal/`. Đang sửa dở → `changes/`.
- Artifact của một UC nằm **trọn trong thư mục UC**: `UC-###.md` · `UC-###.flow.md` · `screens/` · và từ 4.0.0 là `design.md` + `tasks.md` (bước ⑩).
- Thiết kế kỹ thuật có **hai mức**: `specs/internal/architecture.md` cho cả dự án (ngăn xếp · nơi chạy · ai gọi · ranh giới · cái gì cấm), và `design.md` mỗi UC đối chiếu ngược lên nó.
- Plugin không bao giờ ghi đè file bạn đã sửa — `init --update` để bản mới cạnh dưới tên `.new`.

## Vì sao Spec Kit ra khỏi chuỗi

Tới 3.x, bước ⑩ của vòng 14 bước là `/speckit-plan`. Từ **4.0.0** nó là `/sdd-solo:design`. Đổi vì
ba thứ đo được, không phải vì sở thích:

**① Hai hệ tranh nhau một thư mục.** `speckit-specify/SKILL.md:84,88,91,93` dặn agent **bằng lời văn**:
specs nằm dưới `specs/`, số tiếp theo lấy bằng cách *"scanning existing directories in `specs/`"*, rồi
`mkdir -p specs/<NNN>-<slug>`. Ở `runxops`: `specs/001-assign-product-key/` nằm cạnh `specs/contexts/`.
Hai hệ ID (`001-` và `UC-###`), một thư mục, không bên nào biết bên kia — và phép đếm số của họ đang
quét cả `br.md`, `contexts/`, `changes/` của mình.

**② Bước quyết kiến trúc chạy trên hai đầu vào rỗng.** `speckit-plan` đọc đúng hai thứ: `FEATURE_SPEC`
và `.specify/memory/constitution.md`. `FEATURE_SPEC` là bản mỏng sdd-solo sinh ra, **chỉ chứa ID**.
Còn `constitution.md` ở repo thật vẫn nguyên placeholder `[PROJECT_NAME]`. **Brief không nằm trong
hai đầu vào đó và chưa bao giờ nằm** — nên bản thiết kế nói ngược lại brief suốt hai ngày mà không
ai thấy, vì mỗi tài liệu tự nó nhất quán.

**③ "Spec Kit" không phải một thứ.** Bốn repo trên cùng một máy: 10 · 24 · 25 · 35 lệnh `speckit-*`.
Đặt tên lệnh của người khác vào **quy tắc cứng** là để quy tắc hỏng theo lịch release của người khác.

Nên: quy tắc cứng của sdd-solo giờ nói về **trạng thái repo** (`.sdd/gate/UC-###.ok` có chưa,
`design.md` có chưa), không nói về tên lệnh nào cả. Spec Kit vẫn đáng cài và đáng đọc — chỉ cần nó
ghi vào `.speckit/`. Repo đang trộn hai cây thì `bash .sdd/scripts/migrate.sh --dry-run` tách ra,
giữ nguyên git history.

## Repo của bạn đặt code ở đâu

`.sdd/config` — sinh một lần lúc `init` bằng cách dò repo, và `init --update` **không bao giờ ghi đè**:

```
code_paths=src app lib
test_paths=tests
uc_test_dir=tests/use-cases
```

Githook và mọi script kiểm đều đọc file này. Trước 1.5.0 hai đường dẫn viết chết là `src`/`tests`, nên repo đặt code ở `app/` thì hook **cho qua mọi commit code không ID mà không nói một lời** — chặn cứng thành không chặn gì. Giờ commit có file nguồn mà không thư mục nào trong `code_paths` tồn tại thì hook **chặn** và chỉ vào `.sdd/config`; `/sdd-solo:status` cũng kiểm lại.

## Nâng cấp 1.x → 2.0.0

**Thứ tự bắt buộc: migrate TRƯỚC, `init --update` SAU.** Ngược lại thì `init` dựng sẵn cây đích bằng template rỗng, migrate thấy đích đã có nên bỏ qua, và nội dung thật kẹt ở chỗ cũ. Từ 2.0.1 cả hai lệnh đều tự chặn nếu gọi sai thứ tự.

```bash
/plugin marketplace update sdd-solo && /plugin update sdd-solo   # lấy 2.0.x
bash <plugin>/scripts/migrate.sh --dry-run                       # xem trước
bash <plugin>/scripts/migrate.sh                                 # git mv, giữ history
/sdd-solo:init --update                                          # rồi mới tới bước này
git add -A && git commit -m "chore(sdd): migrate bố cục 2.0.0"
```

Script dừng ngay từ đầu nếu working tree bẩn hoặc nếu cây cũ và cây mới cùng tồn tại — trong cả hai ca nó chưa đụng file nào.

## Nâng cấp 4.x → 5.0.0

5.0.0 đổi **thứ mỗi bước để lại**, không đổi 14 bước. Đo trên một dự án thật (runxops): 44.761 từ spec,
0 UC implemented, `57 docs : 1 feat`; 55 file thì 34 vẫn nguyên khuôn; hiểu một UC phải đọc 210 KB mà hơn
60% là dấu vết. Ba việc:

1. **Bớt file** — khuôn 43 → 16. Khuôn UC/context/change về plugin (`templates/skel/`), 13 ngăn kéo trống bỏ.
2. **Dấu vết rời file hiệu lực** — `pass.sh close` dời `## Adversarial pass` · `## Đọc lại` · `## History` sang
   `UC-###.trace.md`, để lại một dòng có số đếm. `migrate.sh --evidence BR-###` dời thân `## Background` sang
   `br.evidence.md`, giữ mục lục `###`.
3. **Một lệnh cho agent** — `context.sh UC-###` in đúng phần đang hiệu lực + đúng RULE/CON/ADR được trích;
   `--why` trả lời *"tính năng này do cái gì quyết định"*.

Ở dự án:

```
/plugin marketplace update sdd-solo → /plugin update sdd-solo → /sdd-solo:init --update → session mới
bash .sdd/scripts/migrate.sh --evidence BR-001 --dry-run      # xem trước, rồi chạy thật
bash .sdd/scripts/decisions.sh                                 # dự án đã quyết gì
bash .sdd/scripts/context.sh UC-### --why                      # UC này do cái gì quyết định
```

`init --update` xoá file khuôn cũ **chỉ khi anh chưa sửa tay** (sha khớp manifest); đã sửa thì giữ và báo.
`br.md` đã có BR thật mà còn `BR-000` mẫu → `br-check` đỏ: xoá mục `BR-000` đi (từ 4.2.0).

## Đang chạy bản nào

Bốn chỗ giữ version, lệch chỗ nào thì lệnh sửa khác nhau:

```
GitHub ─①─▶ marketplace đã tải ─②─▶ bản đã cài ─③─▶ .sdd/ của dự án
                                        └───④─▶ phiên Claude Code đang mở
```

| Khe | Lệnh |
|---|---|
| ③ `.sdd/` cũ hơn bản đã cài | `/sdd-solo:init --update` |
| ② bản đã cài cũ hơn bản đã tải | `/plugin update sdd-solo` |
| ① GitHub có bản mới | `/plugin marketplace update sdd-solo` |
| ④ phiên đang mở còn chạy bản cũ | **không lệnh nào sửa được** — mở session mới |

Khe ④ là khe nguy hiểm nhất: vừa `/plugin update` xong, `.sdd/` đã mới, mọi thứ trên đĩa đều đúng, nhưng phiên đang mở vẫn chạy code cũ nạp lúc mở — gõ `/sdd-solo:gate` là nhận logic cũ. Chỉ hook SessionStart biết được phiên nạp bản nào, nên nó ghi lại để `version-check` đọc.

`/sdd-solo:status` tự kiểm cả ba (hỏi GitHub tối đa 3 giây, nhớ 24 tiếng) và chỉ nói khi lệch. `/sdd-solo:init --plugin` chạy đúng những khe đang lệch trong một lệnh — nhưng **bản mới chỉ có hiệu lực ở session sau**, giống hệt cách Claude Code tự update chính nó. Hook mở session cũng cảnh báo, nhưng **chỉ so cục bộ, không gọi mạng** — nên khe ① chỉ lộ ra khi chạy `status`.

## Mức chặn — nói thật

- **Chặn cứng**: git hook `commit-msg` từ chối commit code không có ID hoặc UC chưa qua cổng; `pre-commit` từ chối trộn spec và code. Không có cờ bỏ qua.
- **Chặn mềm**: không lệnh nào của công cụ ngoài bị gọi tên nữa (từ 4.0.0). Khối `CLAUDE.md` và hook SessionStart dạy session từ chối **viết code** khi chưa có marker `.sdd/gate/UC-###.ok` hoặc chưa có `design.md`; AI tuân, người thì có thể ép.

## Báo lỗi · yêu cầu sửa

Mở issue tại [github.com/quangman2211/sdd-solo/issues/new/choose](https://github.com/quangman2211/sdd-solo/issues/new/choose) — có sẵn hai form:

- **Báo lỗi** — plugin cài không được, lệnh chạy sai, script hoặc git hook chặn nhầm. Cần: lệnh đã chạy, output nguyên văn, cách tái hiện, môi trường.
- **Yêu cầu sửa / thêm** — đổi một quy tắc, thêm kiểm tra, thêm lệnh. Mô tả *vấn đề đang gặp* trước, giải pháp sau.

Ba loại yêu cầu bị từ chối theo thiết kế, đọc phần Ranh giới trong [CLAUDE.md](CLAUDE.md) trước khi mở issue: thêm cờ bỏ qua cho gate/hook, cho plugin ghi đè file dự án đã sửa tay, hook vào lệnh của công cụ ngoài.

## Tài liệu

- `plugins/sdd-solo/docs/playbook-example-khoskill.html` — playbook đầy đủ với ví dụ xuyên suốt (luồng license của một dự án mẫu).
- `plugins/sdd-solo/skills/sdd-process/SKILL.md` — kiến thức nền, cũng là thứ AI đọc khi làm việc trong repo.

## Cấu trúc

```
sdd-solo/
├── .claude-plugin/marketplace.json
└── plugins/sdd-solo/
    ├── .claude-plugin/plugin.json
    ├── skills/  sdd-process · init · intake · start · adversarial · verify · gate · design · change · close · state · status
    ├── hooks/hooks.json            SessionStart → scripts/session-start.sh
    ├── scripts/                    scaffold · br-check · gate-check · design-check · change-check · close-check · pass · status · metrics · migrate
    ├── templates/
    │   ├── project/                specs/ docs/ changes/ checklists/ prompts/ STATE.md .gitmessage
    │   ├── CLAUDE.md.tmpl          khối quy tắc, ghép vào CLAUDE.md của repo
    │   └── githooks/               commit-msg · pre-commit
    └── docs/
```

MIT.
