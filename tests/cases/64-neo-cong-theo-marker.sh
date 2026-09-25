# 8.8.0 (P-64) — cái neo của cổng phải là cái ĐÃ GHI, không phải cái grep được từ tiêu đề commit.
#
# Ký lại cổng cho UC đã `reviewed` và đã ghi ngày hôm nay thì hai lệnh sed không đổi gì, nên
# `git commit --only` không có gì để commit. Tới 8.7.0: git để lọt nguyên câu "nothing to commit",
# rồi pass.sh vẫn in "committed." — một câu sai — và không có commit `docs(UC-###): spec reviewed`
# mới nào. Từ đó close-check (P-10) grep tiêu đề nên neo mãi vào commit cổng ĐẦU, và báo
# "spec changed BEHAVIOUR after passing the gate" không có cách nào dập (runxops 25/09).
# Marker biết câu trả lời đúng suốt thời gian đó — dòng 1 của nó là `rev-parse HEAD` lúc qua cổng,
# từ 1.0.0. Không ai hỏi nó.
nr p64
S pass.sh gate UC-001
chk "dựng: cổng lần 1 xanh" '[ $R = 0 ]'
MK1="$(head -1 .sdd/gate/UC-001.ok)"
GREP1="$(git log -1 --format=%H --grep='spec reviewed')"
chk "dựng: lần 1 thì marker và commit cổng là MỘT" '[ "$MK1" = "$GREP1" ]'

S pass.sh gate UC-001
chk "cổng lần 2 vẫn xanh (exit $R)" '[ $R = 0 ]'
chk "P-64 · không còn nói dối 'committed' khi không commit gì" '! has "· committed."'
chk "P-64 · nói thẳng là không có gì để commit, và marker mới trỏ đâu" \
  'has "nothing to commit" && has "The marker moved"'
chk "P-64 · không để lọt câu của git ra ngoài" '! has "working tree clean"'
MK2="$(head -1 .sdd/gate/UC-001.ok)"
chk "marker ĐÃ dời, còn grep tiêu đề thì không" \
  '[ "$MK2" != "$MK1" ] && [ "$(git log -1 --format=%H --grep="spec reviewed")" = "$GREP1" ]'
chk "P-64 · gate_commit đọc marker, không đọc tiêu đề" \
  '[ "$(bash -c ". \"$P/scripts/lib.sh\"; gate_commit UC-001 \"$PWD\"")" = "$MK2" ]'

# Hậu quả thật: sửa một AC rồi ký lại cổng. Neo phải đi qua chỗ sửa, nếu không close-check đỏ mãi.
nr p64b
S pass.sh gate UC-001
rep "$UC1" 'Then:  một tin báo được gửi' 'Then:  hai tin báo được gửi'
cm "docs(UC-001): sửa AC-1"
# đây đúng là trạng thái một lần ký lại im lặng để lại: marker dời tới HEAD, không commit cổng mới
git rev-parse HEAD > .sdd/gate/UC-001.ok
cm "chore(sdd): gate marker UC-001"
S close-check.sh UC-001
chk "P-64 · neo đi qua chỗ sửa → không còn 'changed BEHAVIOUR' mãi" \
  '! has "changed BEHAVIOUR after passing the gate"'
chk "P-64 · và nói rõ là đã so, không phải bỏ qua" 'has "unchanged since the gate commit"'

# Chốt ngược: luật KHÔNG bị làm mù. Marker còn ở cổng CŨ thì sửa AC vẫn phải đỏ.
nr p64c
S pass.sh gate UC-001
MKOLD="$(head -1 .sdd/gate/UC-001.ok)"
rep "$UC1" 'Then:  một tin báo được gửi' 'Then:  hai tin báo được gửi'
cm "docs(UC-001): sửa AC-1"
S close-check.sh UC-001
chk "P-64 · marker còn ở cổng cũ → 'changed BEHAVIOUR' vẫn đỏ (luật không bị làm mù)" \
  'has "changed BEHAVIOUR after passing the gate"'

# marker mất hoặc hash không còn trong lịch sử → rơi về grep tiêu đề, không im lặng
nr p64d
S pass.sh gate UC-001
G="$(git log -1 --format=%H --grep='spec reviewed')"
printf 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef\n' > .sdd/gate/UC-001.ok
chk "P-64 · hash không có trong lịch sử → rơi về grep tiêu đề" \
  '[ "$(bash -c ". \"$P/scripts/lib.sh\"; gate_commit UC-001 \"$PWD\"")" = "$G" ]'
rm -f .sdd/gate/UC-001.ok
chk "P-64 · không có marker → vẫn rơi về grep tiêu đề" \
  '[ "$(bash -c ". \"$P/scripts/lib.sh\"; gate_commit UC-001 \"$PWD\"")" = "$G" ]'
