# Cowrywise Data Analytics SQL Assessment

This repository contains my SQL solutions for a fintech data analytics case study modeled after Cowrywise's business operations. The queries address key business intelligence use cases including cross-selling opportunities, customer transaction frequency segmentation, account inactivity monitoring, and Customer Lifetime Value (CLV) estimation.

## Database Overview

The analysis is performed using MySQL across the following core tables (aliased/renamed for clarity in the scripts):
* `customer` (`users_customuser`): Customer demographic and account registration details.
* `plans` (`plans_plan`): Customer savings and investment plan configurations (`is_regular_savings`, `is_a_fund`).
* `savings` (`savings_savingsaccount`): Transaction logs tracking deposits, statuses, and amounts (stored in kobo and converted to Naira).
* `withdrawal` (`withdrawals_withdrawal`): Customer withdrawal records.

---

## Questions & Analytical Approach

### 1. High-Value Customers with Multiple Products
* **Scenario:** The business wants to identify customers who have both a savings and an investment plan (cross-selling opportunity).
* **Task:** Write a query to find customers with at least one funded savings plan AND one funded investment plan, sorted by total deposits.
* **Approach:**
  * Filtered the `plans` table to isolate active savings (`is_regular_savings != 0`) and investment (`is_a_fund != 0`) plans.
  * Aggregated confirmed inflows (`transaction_status LIKE 'success%'`) from the `savings` table per plan and converted values from kobo to Naira (`/ 100`).
  * Joined the plan, customer, and aggregated savings datasets inside a Common Table Expression (CTE).
  * Grouped by customer (`owner_id` and full name) to count the distinct savings and investment plans held, summing and formatting their total deposits.

---

### 2. Transaction Frequency Analysis
* **Scenario:** The finance team wants to analyze how often customers transact to segment them (e.g., frequent vs. occasional users).
* **Task:** Calculate the average number of transactions per customer per month and categorize them:
  * **High Frequency:** $\ge 10$ transactions/month
  * **Medium Frequency:** $3\text{–}9$ transactions/month
  * **Low Frequency:** $\le 2$ transactions/month
* **Approach:**
  * **Step 1 (Monthly Aggregation):** Grouped transactions in the `savings` table by `owner_id` and formatted transaction month/year (`%M-%Y`) to get monthly transaction counts per user.
  * **Step 2 (Customer Average):** Calculated the average monthly transaction volume for each customer across their active months.
  * **Step 3 (Segmentation):** Applied a `CASE` statement to classify each customer into the defined frequency tiers, then aggregated the final output to show the total customer count and average monthly transactions per category.

---

### 3. Account Inactivity Alert
* **Scenario:** The operations team wants to flag accounts with no inflow transactions for over one year.
* **Task:** Find all active accounts (savings or investments) with no transactions in the last 1 year ($365$ days).
* **Approach:**
  * Classified active accounts in the `plans` table into `'savings'` or `'investment'` using a `CASE` statement.
  * Determined the most recent transaction date (`MAX(transaction_date)`) per plan and compared it against the dataset's latest recorded date using `DATEDIFF`.
  * Filtered for accounts where the elapsed time exceeded $365$ days (`HAVING number_of_inactive_days > 365`) and calculated the exact number of days past the one-year inactivity threshold.


---

## Repository Structure

* `README.md` — Project overview, problem statements, and query logic documentation.
* `cowrywise_assessment.sql` — Complete MySQL script containing table setup, stored procedures, and analytical queries.