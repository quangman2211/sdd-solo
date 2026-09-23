# 7.8: vỏ plugin là tiếng Anh. Ba phép đo cơ học, để bản sau không lặng lẽ trôi ngược về tiếng Việt.
# Vì sao ĐO ở templates/ chứ không ở scripts/: script còn phải KHỚP vào tài liệu 6.x viết tiếng Việt
# (migrate.mjs · uc-steps · brief.mjs), nên "không còn dấu tiếng Việt" ở đó là luật sai. Khuôn thì khác:
# nó chỉ SINH RA tài liệu, và từ 7.8 sinh ra tiếng Anh — một chữ có dấu lọt vào là một khuôn trôi ngược.
VN='[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđĐ]'

O="$(grep -rl "$VN" "$P/templates/" 2>/dev/null | sed "s#$P/##" | tr '\n' ' ')"
chk "khuôn không còn chữ tiếng Việt nào (được: ${O:-không có})" '[ -z "$O" ]'

M=""
for s in "$P"/skills/*/SKILL.md; do
  grep -q '^Reply in whatever language the user writes in' "$s" || M="$M $(basename "$(dirname "$s")")"
done
chk "mọi skill mở đầu bằng dòng 'Reply in whatever language…' (thiếu:${M:- không})" '[ -z "$M" ]'

# scaffold ghi doc_lang=en cho dự án MỚI — đây là thứ làm khuôn tiếng Anh có nghĩa: chiều GHI của
# kw_w theo nó. Repo cũ không có dòng này thì doc_lang mặc định vi, hành vi giữ nguyên (7.7.0).
# nr ghi đè doc_lang=vi (bản nền của bộ test là tiếng Việt), nên phải chạy scaffold trên một repo TRẮNG
# để đo đúng thứ dự án mới nhận được.
rm -rf "$W/voen"; mkdir -p "$W/voen"; ( cd "$W/voen" && git init -q )
bash "$P/scripts/scaffold.sh" "$P" "$W/voen" >/dev/null 2>&1
chk "dự án mới: scaffold ghi doc_lang=en vào .sdd/config" 'grep -qx "doc_lang=en" "$W/voen/.sdd/config"'
