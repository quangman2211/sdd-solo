# sdd-solo — hướng dẫn cho session làm việc TRONG repo plugin này

Repo này là **plugin Claude Code** (đồng thời là marketplace một plugin). Nó chứa *hành vi* của quy trình SDD-Solo; *nội dung* (spec, STATE) nằm ở từng repo dự án. Khi sửa ở đây, đừng bao giờ đụng tới bản đã cài trong `~/.claude/plugins/` — sửa ở đây, bump version, push, rồi `/plugin update` ở dự án.

## Cấu trúc
```
.claude-plugin/marketplace.json      version phải khớp plugin.json
plugins/sdd-solo/
  .claude-plugin/plugin.json         version
  skills/<name>/SKILL.md             lệnh /sdd-solo:<name> — init · intake · start · adversarial · verify · gate · design · change · close · deprecate · orchestrate · role · phieu · queue · state · status
  skills/sdd-process/SKILL.md        kiến thức nền, AI tự gọi khi user viết spec (không phải lệnh)
  hooks/hooks.json                   SessionStart → scripts/session-start.sh (đọc STATE.md của dự án)
  scripts/                           bash 3.2-compatible (macOS): lib.sh · scaffold · br-check · gate-check (có --pre) · design-check · change-check · close-check · pass (gate|close|change) · status · metrics · decisions · context (có --why) · uc-steps · version-check · update · migrate · deps-check · session-start · role (vai · worktree · lời giao · KETQUA, 7.2) · phieu (cấp số có khoá · hoi, 7.2–7.3) · queue (hàng đợi trong git, 7.3) · hoi-check (sổ hỏi có địa chỉ, 7.3)
  templates/project/                 19 file copy vào dự án bởi scaffold.sh, có manifest sha ở .sdd/manifest (5.0.0: 43 → 16; 7.2–7.3: + .sdd/roles · notes/hang-doi.md · notes/uy-quyen.md)
  templates/skel/                    khuôn use-case/ · br/ · nghe/ · entity.md · change/ · hoi-dap.md · hoi-vai.md — skill/script copy khi tạo, KHÔNG rơi vào dự án
  templates/CLAUDE.md.tmpl           khối chèn vào CLAUDE.md của dự án giữa <!-- sdd-solo:begin/end -->
  templates/githooks/                commit-msg · pre-commit — chặn cứng; pre-commit.d/ commit-msg.d/ README + .example (luật riêng của repo, 6.2.0) + commit-msg.d/10-vai.sh (ranh giới vai theo .sdd/roles, 7.2)
  docs/playbook-example-khoskill.html
CHANGELOG.md                         mỗi bản một mục — đây là ## History của plugin
tests/                               bộ test (7.1): run.sh · lib.sh · fixtures/v7 · cases/NN-<slug>.sh · snap.sh — PASS/FAIL/XFAIL/XPASS, xem tests/README.md
```

## Ranh giới — quyết định đã chốt, không mở lại tuỳ tiện
- **Plugin giữ NGUỒN của hành vi; dự án giữ một bản sao có đánh version của phần hành vi cần chạy được khi không có plugin** (githook, script kiểm ở `.sdd/scripts/`). Bản sao do `init --update` phát; lệch version thì hook SessionStart và `/sdd-solo:status` cảnh báo. Đổi từ 2.0.0 — giá phải trả là bản sao có thể trôi, đổi lại cổng DoR chạy được ở CI và trên máy người clone repo, chứ không dừng ở máy tác giả.
- **Dự án giữ nội dung.** `scaffold.sh` chỉ ghi đè file có sha khớp manifest (user chưa sửa tay); file đã sửa → tạo `.new`, không ghi đè. Không đổi quy tắc này.
- **Không có cờ bỏ qua** cho `gate-check.sh`, `commit-msg`, `pre-commit`. Đây là tính năng. Nếu một quy tắc sai thật, sửa quy tắc và ghi CHANGELOG — không thêm `--skip`.
- **Không gọi tên lệnh của plugin khác trong quy tắc cứng** (từ 4.0.0). Quy tắc nói về *trạng thái repo* — `.sdd/gate/UC-###.ok` có chưa, `design.md` có chưa — chứ không nói `/speckit-*`. Lý do đo được: bốn repo trên cùng máy có 10 / 24 / 25 / 35 lệnh `speckit-*`; một quy tắc gọi tên lệnh người khác thì hỏng theo lịch release của người khác. Spec Kit vẫn là nguồn tham khảo tốt — chỉ cần nó ghi vào `.speckit/`, không ghi vào `specs/`.
- **`speckit-decompose` để ngoài** plugin này (quyết định 09/2026).
- Không bịa số liệu trong template hay skill: chỗ chưa có dữ liệu để `___`.
- **Một bước là công cụ để nghĩ thì để lại một quyết định, không để lại một tài liệu** (5.0.0). Adversarial · đọc lại ·
  history là giấy nháp: khi UC đóng, `pass.sh close` dời thân sang `UC-###.trace.md`, để lại một dòng có số đếm bằng máy.
  Đo ở runxops: 44.761 từ spec đổi lấy 0 UC implemented, `57 docs : 1 feat`; hơn 60% của 210 KB một agent phải đọc là
  dấu vết. Không thêm mục mới vào file UC/BR mà không trả lời được *ai đọc lại nó sau khi UC đóng*.
- **Không có cửa "qua đêm" ở cổng nào** (6.0.0, #38). Bước ⑧ và cổng Phase 5 chỉ qua bằng `/sdd-solo:verify` — mục
  `## Đọc lại` có dòng `F#` đủ `[neo]` + đầu ra, commit riêng là commit spec mới nhất. Lý do đo được: một đêm đo thời
  gian trôi qua, không đo việc đọc có xảy ra không (#27); giữ hai cửa song song hai bản lớn thì cửa rẻ hơn vẫn là cửa
  được đi. Đọc không ra gì thì cổng không mở — đó là chủ ý, không thêm cửa thoát.
- **Mọi đường dẫn trong `specs/` tra qua `lib.sh`** (7.0, #55). `find_uc` · `owner_of` · `br_file` · `rules_files` · `adr_file` ·
  `entity_files` · `glossary_files`… mỗi hàm tra bố cục 7.0 (`core|<nghề>` × `br-###/`) trước rồi rơi về 6.x
  (`specs/contexts/<ctx>/`, `specs/br.md`, `specs/internal/`). Script không được `find`/`grep` thẳng đường dẫn — tới 6.6.x
  có 11 script + 2 githook làm thế, đổi cây là đổi 13 chỗ và hụt thì im. Githook chạy bash trần nên chép danh sách
  đường dẫn của `id_exists`; đổi một nơi thì đổi cả hai. Kiểm tương thích 6.x bằng snapshot output mọi script trên
  bản sao runxops chưa migrate (CHANGELOG 7.0.0).
- **`specs/vision.md` là của chủ dự án** (7.0, T1–T3): skill hỏi và chép, không tự viết; số ở đó miễn luật "không số".
  Nghề là thư mục ngang hàng `core/`; lát là một BR; không còn context như đơn vị thư mục. Lõi không biết nghề.
- **Plugin giữ cơ chế, repo giữ chính sách của đội agent** (7.2). Có vai nào · ghi đâu · cấm đâu · bật chặn hay chưa nằm
  ở `.sdd/roles` của dự án; plugin chỉ có `role.sh` · `phieu.sh` · hook `10-vai.sh` · KETQUA. Không có `.sdd/roles` thì
  mọi thứ im lặng. Khoá nguyên tử và KETQUA đặt ở `$(git rev-parse --git-common-dir)/` — chung mọi worktree, ngoài git;
  `.sdd/` là file trong cây làm việc nên mỗi worktree một bản. Dấu vai theo worktree (`--git-path sdd-role`), không theo
  nhánh. Vai spec giữ checkout chính trên `main`. Plugin **không cấp runner** (ai mở pane, đổi model) — đúng luật không
  gọi tên lệnh của plugin khác.
- **`scaffold.sh` không bao giờ ghi đè file không có trong manifest** (7.0). Bản tới 6.6.x coi "không có dòng manifest"
  là "chưa cài" và chép đè — trên repo vừa migrate, `specs/architecture.md` thật (dời từ `internal/`) bị thay bằng khuôn
  trong im lặng. Giờ: không dòng manifest mà file đã có → `.new` + cảnh báo; `migrate --layout v7` đổi tên đường dẫn
  trong manifest cho file khuôn vừa dời để lần `init --update` sau vẫn phân biệt được "chưa sửa" với "đã sửa".
- Khuôn không rơi vào dự án trừ khi có script/skill đọc hoặc user điền — 13 "ngăn kéo trống" bỏ ở 5.0.0 sau khi đo
  chúng nguyên byte ở runxops nhiều tuần. Muốn thêm file khuôn thì nêu được ai đọc nó.

## Quy trình sửa
1. Sửa file trong repo này.
2. Test:
   - **`bash tests/run.sh` — bắt buộc trước mỗi bản (7.1).** FAIL là chặn phát hành; XPASS nghĩa là một lỗi đã hết —
     đổi ca sang `chk` và ghi CHANGELOG. Sửa một lỗi P-## thì viết ca `xfail` **trước**, thấy XFAIL, sửa, thấy XPASS.
   - script: `cd <repo dự án> && bash <đường dẫn repo này>/plugins/sdd-solo/scripts/gate-check.sh UC-###`
   - skill/hook: `cd <repo dự án> && claude --plugin-dir <đường dẫn repo này>/plugins/sdd-solo`
   - smoke test đầy đủ: tạo repo tạm, chạy scaffold → viết UC giả → gate (đỏ) → điền đủ, commit docs lùi ngày → gate (xanh) → gate-pass → commit feat (hook phải chặn khi thiếu marker, cho qua khi có) → close-check/-pass. Xem CHANGELOG 1.0.0 cho kịch bản gốc.
3. `claude plugin validate .` và `claude plugin validate plugins/sdd-solo` — cả hai phải pass.
4. **Bump version — bắt buộc, không có ngoại lệ.** Sửa ở **hai** file: `plugins/sdd-solo/.claude-plugin/plugin.json` và `.claude-plugin/marketplace.json`. Hai số phải khớp nhau. Thêm một mục CHANGELOG.
5. Commit `fix(sdd-solo): …` / `feat(sdd-solo): …`, push.
6. Ở dự án: `/plugin marketplace update sdd-solo` → `/plugin update sdd-solo`; nếu đụng `templates/` → `/sdd-solo:init --update`.

### Vì sao không được quên bump
Claude Code cache plugin theo **thư mục tên version**:

```
~/.claude/plugins/cache/sdd-solo/sdd-solo/1.0.0/
                                        └── version ở đây
```

Push mà không bump → `/plugin update` thấy version trùng, **không tải lại gì cả**. Dự án vẫn chạy code cũ trong khi git đã có code mới. Không có thông báo lỗi — đây là loại hỏng im lặng tốn nhiều giờ nhất để tìm ra.

Kiểm bằng script (1.2.0+), nó so cả bốn mắt xích và chỉ đúng lệnh cho từng chỗ lệch:
```bash
bash plugins/sdd-solo/scripts/version-check.sh --remote
```
Chuỗi là `GitHub → marketplace clone → plugin đã cài → .sdd/ của dự án`; mỗi khe một lệnh sửa khác nhau, đừng gõ cả ba. Không có `--remote` thì nó thuần cục bộ — và **cục bộ không bao giờ thấy được khe ①**, vì máy chỉ biết có bản mới sau khi hỏi GitHub.

**Khi nào KHÔNG cần bump:** chỉ khi thay đổi nằm hoàn toàn ngoài `plugins/sdd-solo/` — `README.md`, `CLAUDE.md` gốc, `.github/`, `LICENSE`. Đụng bất cứ file nào **trong** `plugins/sdd-solo/` (skill, hook, script, template, docs của plugin) → bump.

Quy tắc bump: sửa lỗi → patch (1.0.0 → 1.0.1) · thêm lệnh, thêm kiểm tra, đổi template → minor (1.0.0 → 1.1.0) · đổi quy tắc khiến dự án đang chạy phải sửa tay → major.

## Cái gì lan tới dự án bằng cách nào
| Sửa | Sau `/plugin update` | Cần thêm |
|---|---|---|
| skills/ hooks/ scripts/ | có hiệu lực ngay | — |
| templates/project/* | chưa | `/sdd-solo:init --update` |
| templates/CLAUDE.md.tmpl | chưa | `init --update` thay khối giữa marker |
| templates/githooks/* | chưa | `init --update` ghi đè `.githooks/` |

Cả bảng này chỉ đúng khi đã bump version. Chưa bump thì `/plugin update` không tải gì, mọi dòng trên thành vô nghĩa.

## Khi viết script
- bash 3.2: không dùng mảng kết hợp, `mapfile`, `${var,,}`. `sed -i.bak` rồi `rm .bak`. `shasum -a 256` có fallback `sha256sum` trong `lib.sh`.
- **Không đặt biến sát ký tự nhiều byte.** `echo "$VAR…"` trong bash 3.2 (macOS) dưới locale UTF-8 nuốt mất nội dung biến và byte đầu của ký tự theo sau — không riêng `…`, mà cả `→`, `✓`, chữ có dấu. Dùng `printf '…%s…\n' "$VAR"`, hoặc chèn một ký tự ASCII vào giữa. Bảng đo ở CHANGELOG 1.6.2 và issue #6. Mọi script ở đây đều bash và mọi thông điệp đều tiếng Việt, nên bẫy này còn lặp lại.
- Mọi kiểm cơ học in `✓ / ✗ / !` qua `ok/bad/warn` của `lib.sh`; exit 1 nếu có ✗.
- Commit từ script dùng `git commit --only -- <file>` để không kéo theo thứ user đang stage.
- Đường dẫn dự án lấy từ `project_root()` (`$CLAUDE_PROJECT_DIR` → `git rev-parse --show-toplevel` → `pwd`).

## Khi viết skill
- Skill lệnh: `disable-model-invocation: true`, có `argument-hint`, gọi script qua `${CLAUDE_PLUGIN_ROOT}/scripts/…` và kèm fallback `find ~/.claude/plugins -name <script> -path '*sdd-solo*'`.
- Skill không được tự sửa spec thay user trừ khi user bảo; không đề xuất viết code ở các bước spec.
- Văn tiếng Việt, xưng "anh"/"em" như user quen; tên file, ID, slug tiếng Anh.
