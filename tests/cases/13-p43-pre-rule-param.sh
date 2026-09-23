# P-43: ___ trong thân AC trích một tham số RULE cố ý bỏ trống (RULE-001 `phút` = ___) bị --pre chặn
nr p43
rep "$UC1" 'Then:  một tin báo được gửi' 'Then:  một tin báo được gửi trong ___ phút theo RULE-001'
S gate-check.sh --pre UC-001
xfail P-43 "--pre miễn ___ trích tham số RULE còn trống (được exit $R)" '[ $R = 0 ]'
