
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



-- =================== 2. Churn Analysis ====================
-- =================== 2.1 Monthly churn reate trend ========
SELECT 
	month_start,
	churned_customers,
	churn_rate
FROM monthly_churn_rate
ORDER BY month_start;


-- =================== 2.2 Churn rate by plan tier ==========
SELECT 
  plan_tier,
  ROUND(
    COUNT(*) FILTER (WHERE churn_flag = TRUE)::numeric / COUNT(*) * 100, 2
  ) AS churn_rate_by_plan
FROM subscriptions
GROUP BY plan_tier
ORDER BY churn_rate_by_plan ASC;



-- ================= 3. Revenue Analysis ===================
-- ================= 3.1 MRR and ARR trends ================
SELECT
	month, 
	total_mrr,
	total_arr,
	ROUND(
		(total_mrr - LAG(total_mrr) OVER (ORDER BY month)) /
		NULLIF(LAG(total_mrr) OVER (ORDER BY month), 0)*100,2
	) AS mrr_growth
FROM monthly_revenue
ORDER BY month;


-- ================ 3.2 Revenue by plan ====================
SELECT * FROM revenue_by_plan;



-- ================ 4. Retention analysis ==================
SELECT * FROM monthly_retention_summary ORDER BY month_start;



-- ================ 5. Executive KPI Summary ===============
CREATE OR REPLACE VIEW saas_kpi_summary AS
SELECT
  a.month_start,
  COALESCE(n.new_accounts, 0) AS new_accounts,
  a.active_customers,
  COALESCE(c.churned_customers, 0) AS churned_customers,
  c.churn_rate,
  r.total_mrr,
  r.total_arr,
  t.retention_pct_estimate
FROM monthly_active_customers a
LEFT JOIN monthly_new_accounts n USING (month_start)
LEFT JOIN monthly_churn_rate c USING (month_start)
LEFT JOIN monthly_revenue r ON a.month_start = r.month
LEFT JOIN monthly_retention_summary t USING (month_start)
ORDER BY a.month_start;

SELECT * FROM saas_kpi_summary;




