
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


-- ============ Create Analytics SQL Views ==============

-- ============ Monthly active customers ============
CREATE OR REPLACE VIEW monthly_active_customers AS
WITH bounds AS (
  SELECT
    date_trunc('month', MIN(start_date))::date AS first_month,
    date_trunc('month', MAX(COALESCE(end_date, CURRENT_DATE)))::date AS last_month
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
	c.churned_customers,
	ROUND(
		(c.churned_customers::numeric/NULLIF(a.active_customers,0))*100,2
	) AS churn_rate
FROM monthly_active_customers AS a
LEFT JOIN churned AS c
ON a.month_start = c.churned_month
ORDER BY a.month_start;


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


-- ============ Retention cohort ================
CREATE OR REPLACE VIEW retention_cohort AS
WITH cohort AS (
    SELECT account_id,
           DATE_TRUNC('month', signup_date) AS cohort_month
    FROM accounts
),
activity AS (
    SELECT account_id,
           DATE_TRUNC('month', start_date)  AS active_month
    FROM subscriptions
)
SELECT
    c.cohort_month,
    a.active_month,
    COUNT(DISTINCT a.account_id) AS active_users
FROM cohort c
JOIN activity a USING (account_id)
GROUP BY 1, 2
ORDER BY 1, 2;


