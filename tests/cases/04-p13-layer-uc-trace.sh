# P-13: UC core trích RULE nghề chỉ trong ba mục vết → layer-check không tính
nr p13
printf '# Business Rules — orders\n\n## RULE-012: Đơn eBay\n- Phát biểu: x\n' > specs/orders/rules.md
mkdir -p specs/core/br-003/use-cases/UC-003-login
printf '# UC-003: Đăng nhập\n\n## Main Flow\n1. Người dùng đăng nhập\n\n## Adversarial pass\n- Q1 có đụng RULE-012 không → Open Question\n\n## Đọc lại\n- F1 x [neo: RULE-012] → không phải lỗi vì y\n\n## History\n- v1: từ RULE-012\n' > specs/core/br-003/use-cases/UC-003-login/UC-003.md
S layer-check.sh --file specs/core/br-003/use-cases/UC-003-login/UC-003.md
chk "UC core chỉ trích nghề ở mục vết → exit 0 (được $R)" '[ $R = 0 ]'
rep specs/core/br-003/use-cases/UC-003-login/UC-003.md '1. Người dùng đăng nhập' '1. Người dùng đăng nhập theo RULE-012'
S layer-check.sh --file specs/core/br-003/use-cases/UC-003-login/UC-003.md
chk "Main Flow trích RULE-012 → exit 1 (được $R)" '[ $R = 1 ]'
