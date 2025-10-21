
-- ================= 1. Customer Growth & Retention ===============
-- ================= 1.1 Growth trend of active customers =========
SELECT 
	a.month_start,
	n.new_accounts,
	a.active_customers,
	(a.active_customers-LAG(a.active_customers) OVER (ORDER BY a.month_start)) AS net_growth	
FROM monthly_active_customers AS a
LEFT JOIN monthly_new_accounts AS n
USING (month_start);


-- =================== 1.2 Retention trend ==================
SELECT * FROM monthly_retention_summary ORDER BY month_start;



