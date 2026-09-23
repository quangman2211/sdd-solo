# 7.2: lib đọc .sdd/roles — nở @code_paths, cấm thắng ghi, role_of_path, không có file thì rỗng
nr roles
chk "scaffold phát .sdd/roles mẫu" '[ -f .sdd/roles ] && grep -q "^vai=A B R D T" .sdd/roles'
L="$(bash -c ". $P/scripts/lib.sh; R=\$PWD; echo \"paths=\$(role_paths D \$R)\"; echo \"deny=\$(role_deny D \$R)\"; echo \"of=\$(role_of_path tests/use-cases/orders/UC-001/AC-1.test.js \$R)\"; echo \"ofs=\$(role_of_path src/a.js \$R)\"; role_allows D tests/use-cases/x.js \$R && echo D-yes || echo D-no; role_may_commit R \$R && echo R-commit || echo R-nocommit; echo \"req=\$(role_required \$R)\"")"
chk "D.ghi nở @code_paths @test_paths" 'printf "%s" "$L" | grep -q "^paths=src tests notes/hoi-dap/hoi-D.md"'
chk "D.cam nở @uc_test_dir" 'printf "%s" "$L" | grep -q "^deny=tests/use-cases specs/\*\* STATE.md"'
chk "cấm thắng ghi: D không được ghi uc_test_dir" 'printf "%s" "$L" | grep -q "^D-no"'
chk "role_of_path: file test cổng là của T" 'printf "%s" "$L" | grep -q "^of=T$"'
chk "role_of_path: src là của D" 'printf "%s" "$L" | grep -q "^ofs=D$"'
chk "R không commit · vai_bat_buoc mặc định khong" 'printf "%s" "$L" | grep -q "^R-nocommit" && printf "%s" "$L" | grep -q "^req=khong"'
rm .sdd/roles
L2="$(bash -c ". $P/scripts/lib.sh; echo \"[\$(role_list \$PWD)][\$(role_current \$PWD)]\"")"
chk "không có .sdd/roles → role_list và role_current rỗng" '[ "$L2" = "[][]" ]'
