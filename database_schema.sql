-- =========================================================
-- Schema: SaaS Customer Churn & Retention (PostgreSQL DDL)
-- Tables derived from:
--   ravenstack_accounts.csv
--   ravenstack_subscriptions.csv
--   ravenstack_churn_events.csv
--   ravenstack_feature_usage.csv
--   ravenstack_support_tickets.csv
-- =========================================================

-- =============== ACCOUNTS ================================
CREATE TABLE IF NOT EXISTS accounts(
account_id			  TEXT PRIMARY KEY,
account_name		  TEXT NOT NULL,
industry			    TEXT,
country				    TEXT,
signup_date			  DATE,
referral_source		TEXT,
plan_tier			    TEXT,
seats				      INT,
is_trial 			    BOOLEAN,
churn_flag		    BOOLEAN
);

CREATE INDEX IF NOT EXISTS idx_accounts_plan_tier ON accounts(plan_tier);
CREATE INDEX IF NOT EXISTS idx_accounts_signup_date ON accounts(signup_date);


-- =============== SUBSCRIPTIONS ===========================
CREATE TABLE IF NOT EXISTS subscriptions(
subscription_id 	TEXT PRIMARY KEY,
account_id			  TEXT NOT NULL REFERENCES accounts(account_id),
start_date			  DATE,
end_date			    DATE,
plan_tier			    TEXT,
seats				      INT,
mrr_amount			  NUMERIC(10,2),
arr_amount			  NUMERIC(12,2),
is_trial			    BOOLEAN,
upgrade_flag		  BOOLEAN,
downgrade_flag		BOOLEAN,
churn_flag			  BOOLEAN,
billing_frequency TEXT,
auto_renew_flag		BOOLEAN
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_account_id ON subscriptions(account_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_start_end ON subscriptions(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_subscriptions_plan ON subscriptions(plan_tier);
CREATE INDEX IF NOT EXISTS idx_subscriptions_billing ON subscriptions(billing_frequency);


-- =============== CHURN EVENTS ============================
CREATE TABLE IF NOT EXISTS churn_events (
  churn_event_id            TEXT PRIMARY KEY,         
  account_id                TEXT NOT NULL REFERENCES accounts(account_id),
  churn_date                DATE,
  reason_code               TEXT,                     
  refund_amount_usd         NUMERIC(10,2),
  preceding_upgrade_flag    BOOLEAN,
  preceding_downgrade_flag  BOOLEAN,
  is_reactivation           BOOLEAN,
  feedback_text             TEXT
);

CREATE INDEX IF NOT EXISTS idx_churn_events_account_id ON churn_events(account_id);
CREATE INDEX IF NOT EXISTS idx_churn_events_date ON churn_events(churn_date);
CREATE INDEX IF NOT EXISTS idx_churn_events_reason ON churn_events(reason_code);


-- =============== FEATURE USAGE ===========================
-- usage_id is not unique; add a surrogate key.
CREATE TABLE IF NOT EXISTS feature_usage (
  id                      BIGSERIAL PRIMARY KEY,
  usage_id                TEXT,                       
  subscription_id         TEXT NOT NULL REFERENCES subscriptions(subscription_id),
  usage_date              DATE,
  feature_name            TEXT,                       
  usage_count             INT,
  usage_duration_secs     INT,
  error_count             INT,
  is_beta_feature         BOOLEAN
);

CREATE INDEX IF NOT EXISTS idx_feature_usage_subscription ON feature_usage(subscription_id);
CREATE INDEX IF NOT EXISTS idx_feature_usage_date ON feature_usage(usage_date);
CREATE INDEX IF NOT EXISTS idx_feature_usage_feature ON feature_usage(feature_name);


-- =============== SUPPORT TICKETS =========================
CREATE TABLE IF NOT EXISTS support_tickets (
  ticket_id                   TEXT PRIMARY KEY,       
  account_id                  TEXT NOT NULL REFERENCES accounts(account_id),
  submitted_at                TIMESTAMPTZ,
  closed_at                   TIMESTAMPTZ,
  resolution_time_hours       NUMERIC(10,2),          
  priority                    TEXT,                   
  first_response_time_minutes INT,
  satisfaction_score          NUMERIC(2),                    
  escalation_flag             BOOLEAN
);

CREATE INDEX IF NOT EXISTS idx_tickets_account_id ON support_tickets(account_id);
CREATE INDEX IF NOT EXISTS idx_tickets_submitted ON support_tickets(submitted_at);
CREATE INDEX IF NOT EXISTS idx_tickets_priority ON support_tickets(priority);
