# P-25: br-check đếm dấu chấm cả đoạn khai nguồn dưới câu Goal
nr p25
rep specs/orders/br-001/br.md '<Một câu. Tránh "tối ưu", "cải thiện", "nâng cao" nếu Success Metrics chưa có số>' 'Seller biết đơn mới ngay.

*Nguồn: chủ dự án chốt 2026-01-01. Đo tay. Ba lần.*'
S br-check.sh BR-001
xfail P-25 "không cảnh báo dấu chấm khi câu Goal là một câu, phần sau là khai nguồn" '! has "dấu chấm"'
