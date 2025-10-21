
-- ============ Inspect Data ===============

-- ============ List all tables in the database ============
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;


-- ============= Preview a few rows in each talbe ==========
SELECT * FROM accounts LIMIT 5;
SELECT * FROM churn_events LIMIT 5;
SELECT * FROM feature_usage LIMIT 5;
SELECT * FROM subscriptions LIMIT 5;
SELECT * FROM support_tickets LIMIT 5;


-- ============ 1. Create Analytics SQL Views ==============

-- ============ Monthly active customers ============
CREATE OR REPLACE VIEW monthly_active_customers AS
WITH bounds AS (
  SELECT
    date_trunc('month', MIN(start_date))::date AS first_month,
    date_trunc('month', MAX(end_date))::date AS last_month
  FROM subscriptions
),
months AS (
  SELECT generate_series(first_month, last_month, interval '1 month')::date AS month_start
  FROM bounds
)
SELECT
  m.month_start,
  COUNT(DISTINCT s.account_id) AS active_customers
FROM months m
JOIN subscriptions s
  ON s.start_date < (m.month_start + interval '1 month')      -- started before next month
 AND (s.end_date IS NULL OR s.end_date >= m.month_start)      -- not ended before this month
GROUP BY m.month_start
ORDER BY m.month_start;

-- SELECT * FROM monthly_active_customers;


-- =========== Monthly churn rate ================
CREATE OR REPLACE VIEW monthly_churn_rate AS
WITH churned AS(
SELECT 
	date_trunc('month', churn_date)::date AS churned_month,
	COUNT(DISTINCT account_id) AS churned_customers
FROM churn_events
GROUP BY 1
)
SELECT 
	a.month_start,
	a.active_customers,
	COALESCE(c.churned_customers, 0) AS churned_customers,
	ROUND(
		(COALESCE(c.churned_customers, 0)::numeric/NULLIF(a.active_customers,0))*100,2
	) AS churn_rate
FROM monthly_active_customers AS a
LEFT JOIN churned AS c
ON a.month_start = c.churned_month
ORDER BY a.month_start;

-- SELECT * FROM monthly_churn_rate;

-- ============= Monthly revenue(MRR & ARR)
CREATE OR REPLACE VIEW monthly_revenue AS
SELECT
    DATE_TRUNC('month', start_date) AS month,
    SUM(mrr_amount)                 AS total_mrr,
    SUM(arr_amount)                 AS total_arr
FROM subscriptions
WHERE churn_flag = FALSE
GROUP BY 1
ORDER BY 1;

-- SELECT * FROM monthly_revenue;


-- ============= Monthly new accounts ==============
CREATE OR REPLACE VIEW monthly_new_accounts AS
SELECT 
	DATE_TRUNC('month', signup_date)::date AS month_start,
	COUNT(DISTINCT account_id) AS new_accounts
FROM accounts
GROUP BY 1
ORDER BY 1;

-- SELECT * FROM monthly_new_accounts


-- ============== Monthly retention summary ============
CREATE OR REPLACE VIEW monthly_retention_summary AS
SELECT 
	a.month_start,
	COALESCE(n.new_accounts, 0) AS new_accounts,
	a.active_customers,
	SUM(COALESCE(n.new_accounts,0)) OVER (ORDER BY a.month_start) AS cumulative_new_accounts,
	ROUND(
		(a.active_customers::numeric/NULLIF(SUM(COALESCE(n.new_accounts,0)) OVER (ORDER BY a.month_start),0))*100,2
	) AS retention_pct_estimate
FROM monthly_active_customers AS a
LEFT JOIN monthly_new_accounts AS n
ON a.month_start = n.month_start
GROUP BY 1,2,3
ORDER BY 1;


-- SELECT * FROM monthly_retention_summary


-- ============= Revenue by plan tier ==============
CREATE OR REPLACE VIEW revenue_by_plan AS
SELECT
    plan_tier,
    ROUND(SUM(mrr_amount), 2) AS total_mrr,
    ROUND(SUM(arr_amount), 2) AS total_arr,
    COUNT(DISTINCT account_id) AS customers
FROM subscriptions
WHERE churn_flag = FALSE
GROUP BY plan_tier
ORDER BY total_mrr DESC;

-- SELECT * FROM revenue_by_plan;


-- ================ 2. Validate Views ==================

-- Check monthly active customers trend
SELECT * FROM monthly_active_customers ORDER BY month_start;

-- Verify churn rate is reasonable 
SELECT * FROM monthly_churn_rate ORDER BY month_start;

-- Check revenue growth
SELECT * FROM monthly_revenue ORDER BY month;

-- Check monthly new customers 
SELECT * FROM monthly_new_accounts;

-- Compare new vs active accounts
SELECT * FROM monthly_retention_summary ORDER BY month_start;

-- Verify plan-level revenue breakdown
SELECT * FROM revenue_by_plan;
