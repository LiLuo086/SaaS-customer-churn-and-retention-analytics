# SaaS-customer-churn-and-retention-analytics

## Project Goal

The goal of this project is to perform a comprehensive analysis of customer churn, retention, and revenue growth for a SaaS company using PostgreSQL.
Through SQL queries and analytical views, the project transforms raw subscription data into actionable business metrics, laying the foundation for dashboard visualization in Tableau Public.

## 1. Database Design

Schema: `SaaS_Customer_Churn_Retention`
Defined in `database_schema.sql`, the database models core SaaS operations across multiple dimensions:

|Table     | Description|
|----------|------------|
|accounts  |Customer profiles with signup date, plan tier, and trial flags.|
|subscriptions| Subscription periods, plan upgrades/downgrades, billing frequency, and recurring revenue (`MRR`, `ARR`).|
|churn_events| Churn occurrences and reactivations, including refund and feedback data.|
|feature_usage| Feature engagement metrics (`usage_date`, `feature_name`, `usage_count`, `duration`).|
|support_tickets| Customer support interactions with response times and satisfaction scores.|

Indexes were created on key attributes (`plan_tier`, `signup_date`, `account_id`, `churn_date`) to optimize performance for analytical queries.

## 2. SQL Views — Analytical Foundation

Defined in `views.sql`, these views consolidate key SaaS performance indicators:

|View  | Description|
|------|------------|
|monthly_active_customers|Counts distinct customers with at least one active subscription in each month.|
|monthly_churn_rate|Calculates monthly churn volume and churn percentage based on active customers.|
|monthly_revenue|Aggregates Monthly Recurring Revenue (MRR) and Annual Recurring Revenue (ARR).|
|monthly_new_accounts|Tracks new customer signups by month.|
|monthly_retention_summary|Estimates cumulative customer retention percentage over time.|
|revenue_by_plan|Summarizes total revenue by subscription plan tier.|

These modular views form the backbone of all downstream analysis — making it easy to audit, extend, and visualize data.

## 3. Metrics Analysis

Performed in `metrics_analysis.sql`, the analytical layer explores the company’s growth, retention, and revenue patterns.

### 3.1 Customer Growth & Retention

- **Growth trend of active customers:**

    ```sql
        active_customers - LAG(active_customers) OVER (ORDER BY month_start) AS net_growth
    ```

    Measures net change in total active customer base month-over-month.

- **Retention trend:**

    Extracted from `monthly_retention_summary` to assess long-term customer retention stability.

### 3.2 Churn Analysis

- **Monthly churn trend:**

    Tracks churn count and rate from `monthly_churn_rate`.

- **Churn rate by plan tier:**

    Identifies which pricing tiers experience higher churn:

    ```sql
        COUNT(*) FILTER (WHERE churn_flag = TRUE)::numeric / COUNT(*) * 100
    ```

### 3.3 Revenue Analysis

- **MRR & ARR trends:**

    Uses `LAG()` to calculate month-over-month MRR growth:

    ```sql
        (total_mrr - LAG(total_mrr)) / LAG(total_mrr)
    ```

- **Revenue by plan:**

    Reveals which subscription plans contribute the most to recurring revenue.

### 3.4 Executive KPI Summary

A unified view (`saas_kpi_summary`) combines all major KPIs:

- New Accounts

- Active Customers

- Churned Customers

- Churn Rate (%)

- MRR / ARR

- Retention (%)

## 4. Example Insights (from SQL outputs)

|Metric|Example Insight|
|------|---------------|
|Active Customers|Steady monthly growth, indicating strong user retention.|
|Churn Rate|Averaged ~5%, with minor spikes in mid-year months.|
|Retention|Stabilized around 85%, suggesting loyal long-term users.|
|Revenue|MRR and ARR show consistent growth, driven primarily by the Enterprise tier.|
|Plan Analysis|Enterprise customers churn least, while Basic plan shows highest churn.|

## 5. Tools & Technologies

|Tool|Purpose|
|----|-------|
|PostgreSQL|Core SQL database for analysis|
|pgAdmin 4|Query execution and CSV export|
|SQL Window Functions|Used for time-based metrics (LAG, SUM OVER)|
|Tableau Public (Planned)|Final visualization layer for KPIs and trends|

## 6. Project Flow Summary

1. **Data modeling**: Build normalized SaaS database schema (database_schema.sql).

2. **View creation**: Define modular analytical views (views.sql).

3. **Metric exploration**: Calculate churn, retention, and revenue KPIs (metrics_analysis.sql).

4. **Export results**: Output all views as CSVs for Tableau visualization.

5. **Next step**: Design an interactive dashboard in Tableau Public.
