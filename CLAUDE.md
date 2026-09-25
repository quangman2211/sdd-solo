# sdd-solo — hướng dẫn cho session làm việc TRONG repo plugin này

Repo này là **plugin Claude Code** (đồng thời là marketplace một plugin). Nó chứa *hành vi* của quy trình SDD-Solo; *nội dung* (spec, STATE) nằm ở từng repo dự án. Khi sửa ở đây, đừng bao giờ đụng tới bản đã cài trong `~/.claude/plugins/` — sửa ở đây, bump version, push, rồi `/plugin update` ở dự án.

## Cấu trúc
```
.claude-plugin/marketplace.json      version phải khớp plugin.json
plugins/sdd-solo/
  .claude-plugin/plugin.json         version
  skills/<name>/SKILL.md             lệnh /sdd-solo:<name> — init · intake · start · adversarial · verify · gate · design · change · close · deprecate · orchestrate · role · phieu · queue · numbers · state · status
  skills/<name>/references/*.md      nhánh loại trừ nhau, chỉ đọc khi cần (8.1): adversarial uc-layer|br-layer ·
                                     intake interview-mode|brief-conversion · verify tree-sweep · orchestrate herdr-traps
  skills/sdd-process/SKILL.md        kiến thức nền, AI tự gọi khi user viết spec (không phải lệnh) — KHÔNG tách
  hooks/hooks.json                   SessionStart → scripts/session-start.sh (đọc STATE.md của dự án)
  scripts/                           bash 3.2-compatible (macOS): lib.sh · scaffold · br-check · gate-check (có --pre) · design-check · change-check · close-check · pass (gate|close|change) · status · metrics · decisions · context (có --why) · uc-steps · version-check · update · migrate · deps-check · session-start · role (vai · worktree · lời giao · KETQUA, 7.2) · phieu (cấp số có khoá · hoi, 7.2–7.3) · queue (hàng đợi trong git, 7.3) · hoi-check (sổ hỏi có địa chỉ, 7.3) · mermaid.sh (vỏ của parser mermaid, 7.5) · numbers.sh (gom ô `___` còn nợ số, 8.0)
  scripts/kw.tsv                     **bảng từ khoá tài liệu song ngữ** (7.7) — bash và node đọc chung
  scripts/js/                        **mã node của plugin** (7.6, ESM, 0 gói npm): mermaid · mermaid-real (mượn mermaid của dự án khi có) · context · migrate · pass · brief · hoi · phieu (mục lục sinh từ file phiếu, 8.3) · table · util · kw
  templates/project/                 19 file copy vào dự án bởi scaffold.sh, có manifest sha ở .sdd/manifest (5.0.0: 43 → 16; 7.2–7.3: + .sdd/roles · notes/hang-doi.md · notes/uy-quyen.md)
  templates/skel/                    khuôn use-case/ (kèm UC-000.trace.md, 8.0) · br/ · nghe/ · entity.md · change/ · hoi-dap.md · hoi-vai.md — skill/script copy khi tạo, KHÔNG rơi vào dự án
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
- **Phần đọc/sửa file có cấu trúc viết bằng node, phần gọi hệ thống viết bằng bash** (7.6). Tới 7.5.0 đó là 1.193
  dòng python nhúng trong heredoc; giờ là `scripts/js/*.mjs`, không gói npm nào. Lý do là của DỰ ÁN dùng plugin, không
  phải của plugin: dự án viết bằng node, và plugin dùng mermaid rất nhiều để kiểm luồng — một ngôn ngữ thứ hai chỉ để
  đọc sơ đồ là một thứ nữa phải cài trên mọi máy clone repo. Đừng thêm python trở lại. Chỗ nào CÓ đường lùi (mermaid,
  đọc JSON) thì không có node vẫn chạy; chỗ nào SỬA file thì gọi `need_node` để dừng có lời.
- **Từ khoá tài liệu là song ngữ, và vế tiếng Việt KHÔNG bao giờ được bỏ** (7.7). Bảng ở
  `scripts/kw.tsv` (tên · kiểu dùng · tiếng Việt · tiếng Anh); bash đọc qua `kw` · `kwh` · `kwl` · `kw_w`,
  node qua `js/kw.mjs`. Khuôn sinh ra tài liệu tiếng Anh, repo đang viết tiếng Việt qua cổng y hệt. Không
  viết thẳng chuỗi tiếng Việt vào `grep`/`sed`/`awk` nữa — thêm dòng vào bảng rồi gọi hàm.
  Lý do KHÔNG đổi hẳn: lịch sử git bất biến. runxops có 50 commit subject tiếng Việt mà gate-check §9 grep
  vào chính chúng (`docs(UC-###): đọc lại`) — bỏ vế cũ là mọi UC đã đóng mất bằng chứng đọc lại, và không
  migrate nào chữa được. Hướng GHI theo `doc_lang` của `.sdd/config` (mặc định `vi`; `scaffold` ghi `en`
  cho dự án MỚI), nên repo đang chạy không đổi một byte.
  Phép đo là ca 45: chép repo, viết lại mọi từ khoá sang tiếng Anh theo bảng, rồi đòi cổng cho CÙNG verdict.
  Thêm từ khoá mà quên định tuyến một chỗ khớp thì ca 45 đỏ — và chỉ ca 45 đỏ, vì bản tiếng Việt vẫn xanh.
- **Luật lint mermaid đo bằng mermaid thật, không đoán** (7.5). `js/mermaid.mjs` chỉ báo những gì đã kiểm bằng
  `mermaid.parse` + `getDiagramFromText` (node 25, jsdom) trên 88 khối thật của runxops cộng ma trận 27 ký tự ×
  13 ngữ cảnh: 17/17 khối vỡ bắt được, 0 khối lành báo oan. Thêm luật mới thì thêm bằng cách ĐO lại, không bằng
  suy đoán từ tài liệu mermaid — nới tay ở đây là đổi đỏ oan lấy hụt đỏ thật. Không có `node` thì mọi chỗ gọi
  rơi về đường grep của bản trước: một phép kiểm không chạy được không bao giờ được thành một phép kiểm đỏ.
- **Dấu vết ở file CẠNH, không ở trong thân UC** (8.0.0). `## Adversarial pass` · `## Đọc lại` · `## History` ghi
  vào `UC-###.trace.md` ngay từ dòng đầu; thân UC giữ một mục `## Evidence` trỏ sang. 5.0.0 đã nén chúng KHI UC
  ĐÓNG, nhưng UC đóng không phải ca đắt — UC đang mở mới là file mọi phiên nạp lại. Đo trên bản sao runxops:
  56% của 2,33 MB thân UC là dấu vết, file lớn nhất 455 KB trong đó 72% là dấu vết; sau khi dời còn 1,01 MB.
  Mọi chỗ ĐỌC dấu vết đi qua `ev_body` của `lib.sh`, và **thân thắng file cạnh** khi thân còn mục đó: repo viết
  trước 8.0.0 không nhận ra 8.0.0 tồn tại. Đọc file cạnh trước làm cổng trả lời từ bản lưu trữ thay vì bản sống,
  và verdict trôi trên UC không ai đụng (đo được: +28 ✓ trên một UC). `migrate.sh --trace` dời một repo sang,
  quyết theo NỘI DUNG từng file nên chạy bao nhiêu lần cũng ra một kết quả.
- **Trần vòng đọc lại là một điểm DỪNG, không phải một cửa** (8.0.0). `rr_max` ở `.sdd/config`, mặc định **2**
  (8.5.0, hạ từ 3) kể cả cho repo chưa có dòng đó. Số đo trên 18 UC · 1.048 phát hiện của runxops: UC chạy MỘT
  vòng giải quyết **79%** ở **1,0 KB** dấu vết mỗi phát hiện; UC chạy **4+** vòng giải quyết **34%** ở **3,5 KB**
  — gấp ba số phát hiện, chưa bằng nửa tỉ lệ xử lý, gấp mười tồn đọng. UC-024: 13 vòng, 109 phát hiện, **0** xử lý. Tới 7.8 `→ Chưa quyết` chỉ được ĐẾM (#53), và đo trên runxops thì đó là lỗ hổng:
  số vòng và số tồn đọng lên cùng nhau — 13 vòng / 105 Chưa quyết (UC-024), 13 / 74 (UC-029), 12 / 71 (UC-026) —
  còn mọi UC dừng ở một vòng thì không tồn một cái nào. Chạm trần mà còn tồn thì đỏ, và **thêm một vòng không mở
  được cổng**: số chỉ xuống bằng cách quyết. Mặc định là một con số chứ không phải "tắt", vì một cái trần không ai
  đứng dưới thì không phải cái trần.
- **Ô `___` là câu hỏi số, và phải gặp chúng CÙNG MỘT LÚC** (8.0.0). Luật "không bịa số" cộng cổng chặn `___`
  sinh ra 588 ô trống rải trên 34 file ở runxops, và chủ dự án gặp từng cái một giữa một lượt chạy cổng — lúc đó
  đường rẻ nhất luôn là điền bừa, tức là đúng cái thất bại mà luật kia sinh ra để chặn. `numbers.sh` in tất cả
  một lượt, phân loại **theo cấu trúc chứ không theo tên mục** (ô trống đứng một mình trong ô bảng = tham số),
  kèm dòng `blocks:` nói UC nào đang chờ. Không thêm luật mới, không chặn gì: đây là bảng việc, không phải cổng.
- **Nhánh loại trừ nhau của skill nằm ở `skills/<tên>/references/`, không nằm trong `SKILL.md`** (8.1.0). Cơ chế là
  *progressive disclosure* của Claude Code, đã kiểm ở `skill-creator` của Anthropic: **metadata luôn trong ngữ cảnh →
  `SKILL.md` nạp trọn mỗi lần skill chạy → file trong `references/` chỉ đọc khi cần** ("Claude reads only the relevant
  reference file"). Lý do đo được: `adversarial` có 87% thân là hai tầng UC/BR loại trừ nhau, `intake` 60% là hai chế
  độ — mỗi lượt chạy nạp cả nhánh nó không bao giờ dùng. Sau khi tách: `adversarial BR-###` **−49%**, `intake` −27%,
  `adversarial UC-###` −25% byte mỗi lượt.
  Ba luật khi tách: ① router phải **mệnh lệnh và nêu đường dẫn đầy đủ** `${CLAUDE_PLUGIN_ROOT}/skills/<tên>/references/…`
  kèm đường lùi `find ~/.claude/plugins …`, đúng khuôn skill đã dùng cho script — đọc hụt là mất trắng luật, không phải
  chậm hơn. ② tách xong phải **xoá hẳn** khỏi thân, không để hai bản. ③ ca 51 giữ hai chiều: file được nhắc phải có thật,
  file có thật phải được nhắc. Bẻ chiều nào ca 51 cũng đỏ đúng chiều đó.
  **KHÔNG tách** khi skill là một mạch tuyến tính (`design`: 7 bước, ai chạy cũng qua đủ) hay khi payload CHÍNH LÀ khối
  kiến thức (`sdd-process`: model tự gọi nó *vì* muốn khối đó — tách ra là bắt đọc hai lần). Và **không rút ngắn
  `description`**: tài liệu nói mọi thông tin "khi nào dùng" phải nằm ở đó và nên viết "hơi thúc", vì Claude có xu hướng
  *bỏ sót* skill chứ không phải gọi thừa. Cả 18 mô tả cộng lại mới ~1.500 token, cắt ở đó là đổi đúng thứ đang có tác dụng.
- **Một phát hiện phải nói ĐƯỢC ĐI ĐÂU TIẾP, không chỉ nói sai cái gì** (8.5.0). Mỗi phép kiểm gọi `step` một lần ở
  đầu mỗi mục; `bad` ghi nhận mục đang chạy; cuối lượt `nexts` in các bước phải quay lại, mỗi bước một lần, theo
  thứ tự mục. Cơ chế theo MỤC chứ không theo lời nhắn: sửa 142 lời nhắn là đắt, và mỗi lần sửa là một dịp đổi
  nhầm câu mà githook hoặc §9 đang khớp vào. `bad_at <file:dòng> <lời>` cho chỗ biết được toạ độ.
  Mượn cách BÁO của GitHub Spec Kit (`analyze` của nó kết bằng lệnh cụ thể phải gõ — `templates/commands/analyze.md:198`,
  v1.0.11), **không mượn cách làm**: Spec Kit chỉ cưỡng chế "file tiền đề có tồn tại không" (`check-prerequisites.sh:139-162`,
  toàn `[[ ! -f ]]`), không githook, và `analyze` của nó không để lại dấu vết nào — đúng lỗi #29 đã chẩn.
- **Một dòng KETQUA chỉ được CÓ MỘT người đọc** (8.6.0, P-58). `kq_field` của `lib.sh` đọc **lần xuất hiện đầu** của
  mỗi trường; `role.sh --ketqua` ghi trường theo thứ tự cố định và chỉ `kiem=` có dấu cách, nên trường đầu luôn là trường
  thật. Tới 8.5.0 có hai người đọc và họ nói ngược nhau: `queue.sh done` dùng `grep -oE 'ket=[a-z]+'` — `-o` in MỌI khớp,
  nên một `kiem=` có trích `ket=xong` của vai khác làm `KET` thành hai dòng và `done` từ chối "xong, not xong"; `board`
  đọc đúng dòng đó bằng glob `*ket=xong*` và nói xong (runxops, b-032-ap-232, 20:31). Hai câu trả lời cho một việc, ở
  đúng cửa đánh dấu việc đã xong. Thêm chỗ đọc KETQUA thì gọi `kq_field`, đừng viết phép đọc thứ hai dù nó cẩn thận hơn.
- **Tên vai là TỪ ĐẦU TIÊN của `SDD_ROLE`** (8.6.0). Điều phối mở pane với `SDD_ROLE="C review opus"` (vai · việc · model)
  là đang nói vai C. `role_norm` dùng ở `role_current` **và** ở nhánh `--staged|--commit` của `role.sh` — nhánh sau đọc
  thẳng `$SDD_ROLE`, nên sửa mỗi `role_current` thì hook vẫn báo "the role 'C review opus' is not in .sdd/roles" trong
  khi commit vẫn đi qua: một thông điệp sai cả hai chiều.
- **Hai bố trí worktree, cả hai chính thức** (8.6.0). Làn code (D, T) mỗi vai một worktree — hai agent sửa chung một cây
  nguồn thì đè trạng thái làm việc của nhau. Làn chữ (B, C, R, G) **một worktree chung, mỗi pane một `SDD_ROLE`**: đo ở
  runxops 24/09 từ 19:10 — bốn vai, hai giờ, 9 việc xong, 2 cổng ký, 0 xung đột file. Chạy được vì các vai này ghi **file
  khác nhau** và cần đọc chữ của nhau **ngay**; vai spec ngồi worktree riêng là mọi vai khác đọc `main` cũ tới lúc merge.
  `SDD_ROLE` khó giả đúng bằng dấu worktree và vì cùng lý do: môi trường của pane do người mở pane đặt, ngoài git, agent
  bên trong không đổi được. Đừng bỏ bố trí nào để có "một quy tắc duy nhất" — hai làn hỏng theo hai kiểu khác nhau.
- **Hook `Stop` chặn MỘT lần, không chặn mãi** (8.6.0, P-59). `stop-ketqua.sh` chặn khi một vai kết lượt mà việc đang giữ
  chưa có KETQUA cuối, in đúng dòng lệnh phải gõ; lần hai (`stop_hook_active`) cảnh báo rồi buông. Một cửa không bao giờ
  mở là cửa chặn VIỆC chứ không chặn lỗi — khác với cổng DoR, nơi không đạt là không qua. Nó **im lặng** trừ khi đủ cả bốn:
  có `.sdd/roles` · suy được vai · hàng đợi nói vai đó đang giữ việc · việc đó chưa có `ket=` cuối. Hook chạy ở MỌI phiên cài
  plugin, nên nghi ngờ gì là `exit 0` không một lời, và nó không dùng node: hook cần runtime là hook hỏng im lặng trên máy
  không có runtime.
- **Marker cổng được PHỤC HỒI, không được CẤP LẠI** (8.7.0, P-61). `pass.sh restore <UC>` đọc blob cũ từ lịch sử nhánh;
  lịch sử không có thì đỏ và không tạo file nào — cùng luật 8.4.0 ("không đóng dấu một lần qua mà nó chưa thấy"), chỉ là
  chĩa vào lịch sử thay vì vào một phép kiểm. **Dòng 1 giữ nguyên hash cổng gốc**: mọi người đọc lần theo marker phải tới commit
  cổng đã xảy ra, không tới ngày phục hồi. Đừng biến nó thành một cửa cấp marker (`--force`, `--new`): lúc đó nó là đúng cái cửa
  8.4.0 vừa đóng. Số commit động vào thân UC kể từ cổng đó chỉ được **cảnh báo**, không chặn — đó là việc để nhìn, không phải luật mới.
- **Làn và vai là hai từ vựng, và `queue.sh add` chỉ chặn cái chứng minh được** (8.9.0, P-66). Làn là thứ có sức chứa
  (`## Lanes`), vai là tên trong `.sdd/roles`. Chặn: vai đứng chỗ làn · ID đứng chỗ làn · vai không khai. Chỉ cảnh báo:
  làn chưa khai — vì chặn chỗ đó bắt mọi repo đang chạy sửa bảng trước khi được xếp việc. Đừng đổi tên tham số thành
  `<uc>`: cột Lane chứa làn thật và đổi tên là phá `lane_cap`/`lane_busy`/`ready_list`. Cái hỏng là không kiểm dạng, không phải cái tên.
- **Thêm trường vào KETQUA thì đặt TRƯỚC `kiem=`** (8.9.0). `kiem=` là trường duy nhất có dấu cách, mà `kq_field` đọc
  lần xuất hiện ĐẦU (P-58) — một trường đặt sau `kiem=` sẽ bị chính nội dung của `kiem=` cướp mất. Và trước khi thêm,
  hỏi nó có trùng trường cũ không: `baocao=<file>` của P-65 chính là `neo=`, vốn đã nhận đường dẫn file và vốn bắt buộc
  với `ket=xong`. Một trường được thêm là trường được BÁO, không phải một cổng: `dat=` thiếu thì `done` nói ra rồi vẫn đóng.
- **Neo của cổng đọc từ MARKER, không grep tiêu đề commit** (8.8.0, P-64). `gate_commit` của `lib.sh` lấy dòng 1 của
  `.sdd/gate/UC-###.ok` (là `rev-parse HEAD` lúc qua cổng, từ 1.0.0), rơi về grep tiêu đề khi không có marker hoặc hash
  không còn trong lịch sử. Lý do đo được: ký lại cổng cho UC đã `reviewed` **cùng ngày** thì `sed` không đổi gì nên không
  có commit cổng mới, mà marker thì **có** dời — grep tiêu đề neo mãi vào cổng đầu và close-check đỏ "changed BEHAVIOUR"
  không cách nào dập. Đây là cùng bài học P-58: **cái đã ghi thắng cái suy ra được**. Kèm theo: dòng 1 của marker giờ được
  ĐỌC — ghi thêm gì vào đó phải để từ dòng 2, và **không dùng `--allow-empty`** để chữa loại lỗi này: một commit rỗng chỉ
  tồn tại để một grep tìm ra, mà grep đó chính là thứ vừa bị thay.
- **Hàm tra cứu trả RỖNG phải `return 0`** (8.7.0). "Không có" là một câu trả lời, không phải một lỗi. `role_current`
  kết thúc bằng `grep -q` của vòng lặp nên trả exit 1 khi không suy được vai, và `pass.sh` chạy `set -e`: repo khai
  `<vai>.ky` mà không suy được vai làm `pass.sh gate` chết im lặng ở đúng ca comment 8.4.0 gọi là được phép. Biết `[ c ] && lệnh`
  cuối danh sách là mìn thôi chưa đủ — một phép GÁN từ `$(hàm)` cũng là một lệnh, và status của nó là status của hàm.
- **Chú thích HTML không bao giờ là ô trống** (8.7.0, P-62). Một `<!-- ... -->` không có gì để điền, nên đỏ ở đó là đỏ
  không lối ra — đúng loại đỏ CLAUDE.md cấm từ #23 và P-43. GỠ chú thích trước khi so, đừng đoán theo hình dạng dòng: guard cũ
  chỉ bỏ qua dòng BẮT ĐẦU bằng `<!--` nên một chú thích cuối dòng Metadata vẫn đỏ, và giữa một khối trải nhiều dòng chính là chỗ
  một `<Tên>` của khuôn cũ nằm lại. Nhưng không nới tay: `<...>` thật ngoài chú thích vẫn đỏ, và ca 63 giữ cả hai chiều.
- **Khuôn CÓ trong `templates/skel/` không có nghĩa là `start` phải chép nó** (8.10.0). `screens/README.md` nằm trong
  khuôn là đúng — người vế cần một cái để chép ở bước ⑤ — nhưng chép nó cho **mọi** UC là phát một ngăn kéo trống cho UC
  không có giao diện: đo ở runxops, 10 trên 21 UC có `screens/` chỉ chứa mỗi README. Luật 5.0.0 hỏi "ai đọc nó" — câu
  hỏi đó phải hỏi ở chỗ **CHÉP**, không phải chỉ ở chỗ thêm khuôn. Kiểm trước khi bỏ một thư mục: `mmd_lint` bỏ qua file
  không có, `uc-steps` bước ⑤ tìm file khác README, và cổng đọc **bảng** `## Screens` trong thân UC chứ không đọc thư mục.
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
### Bash hay node
Bash: gọi git, gọi script khác, đọc `.sdd/*`, in kết quả. Node (`scripts/js/*.mjs`): đọc/sửa file có cấu trúc —
markdown theo heading, bảng, mermaid, JSON. Mỗi `.mjs` là một lệnh có lệnh con, bash truyền tham số và đọc stdout;
không nhúng mã node vào heredoc trong bash (đó chính là thứ 7.6.0 vừa dọn). Không thêm gói npm: plugin phải chạy trên
repo trắng. **Bẫy tiếng Việt khi viết regex trong JS** — `\b` chỉ biết `[A-Za-z0-9_]`, nên nó cho kết quả NGƯỢC với
python/grep quanh chữ có dấu (đo được: 126 dòng lệch ở `context.sh`, xem CHANGELOG 7.6.0). Dùng
`(?<![\p{L}\p{N}_])` … `(?![\p{L}\p{N}_])` với cờ `u`. Ba bẫy khác: không có cờ inline `(?m)` `(?s)`; `$` với cờ
`m` là cuối DÒNG; `String.split` bỏ lát rỗng đầu khi khớp rỗng ở vị trí 0, `re.split` thì không.

- bash 3.2: không dùng mảng kết hợp, `mapfile`, `${var,,}`. `sed -i.bak` rồi `rm .bak`. `shasum -a 256` có fallback `sha256sum` trong `lib.sh`.
- **Không đặt biến sát ký tự nhiều byte.** `echo "$VAR…"` trong bash 3.2 (macOS) dưới locale UTF-8 nuốt mất nội dung biến và byte đầu của ký tự theo sau — không riêng `…`, mà cả `→`, `✓`, chữ có dấu. Dùng `printf '…%s…\n' "$VAR"`, hoặc chèn một ký tự ASCII vào giữa. Bảng đo ở CHANGELOG 1.6.2 và issue #6. Vỏ ngoài mọi script đều bash và mọi thông điệp đều tiếng Việt, nên bẫy này còn lặp lại.
- **`awk -v` xử lý escape của CHUỖI trước khi mẫu tới máy regex.** `-v re="…\\]…"` tới nơi còn `\]` và mẫu hụt
  im lặng. Viết ngoặc vuông bằng `[[]` và `[]]` — trong ngoặc vuông không còn escape nào để nuốt. Đo được ở 7.7.0:
  định tuyến `rr_count` theo lối `\\[` làm bản tiếng Việt đang xanh thành đỏ "chưa đọc lại", ở đúng cửa duy nhất
  mở cổng Phase 5.
- **Mẫu sinh từ `kw`/`kwl`/`kwh` dùng nhóm KHÔNG bắt.** `.source` của chúng hay được nối vào một mẫu lớn hơn, và
  một nhóm bắt lạc vào đó đẩy số thứ tự của mọi nhóm sau. Đo được ở 7.7.0: `hoi.mjs` đọc `mm[1]` ra chính từ khoá
  thay vì giá trị ô, nên phép kiểm bốn ô của sổ hỏi coi ô trống nào cũng là "có điền".
- Mọi kiểm cơ học in `✓ / ✗ / !` qua `ok/bad/warn` của `lib.sh`; exit 1 nếu có ✗.
- Commit từ script dùng `git commit --only -- <file>` để không kéo theo thứ user đang stage.
- Đường dẫn dự án lấy từ `project_root()` (`$CLAUDE_PROJECT_DIR` → `git rev-parse --show-toplevel` → `pwd`).

## Khi viết skill
- Skill lệnh: `disable-model-invocation: true`, có `argument-hint`, gọi script qua `${CLAUDE_PLUGIN_ROOT}/scripts/…` và kèm fallback `find ~/.claude/plugins -name <script> -path '*sdd-solo*'`.
- **Skill có hai nhánh loại trừ nhau thì nhánh đi vào `references/`, thân giữ router** (8.1.0, xem Ranh giới). Router
  là một bảng `<điều kiện> | <file> | <nó chứa gì>`, nói "read exactly one, now", và nêu đủ đường dẫn + đường lùi.
  Thêm/đổi tên file trong `references/` thì ca 51 bắt cả hai chiều — đừng sửa ca cho khớp, sửa router.
- Skill không được tự sửa spec thay user trừ khi user bảo; không đề xuất viết code ở các bước spec.
- **Skill viết bằng tiếng Anh** (7.8.0), và mở đầu bằng dòng `Reply in whatever language the user writes in; keep
  file names, IDs and slugs in English.` — plugin là tiếng Anh, còn giọng trả lời đi theo ngôn ngữ user gõ.
  Đừng viết thân skill bằng tiếng Việt nữa: từ khoá tài liệu đã song ngữ ở `kw.tsv`, nên văn skill không
  còn là chỗ giữ tiếng Việt.
