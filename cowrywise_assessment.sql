RENAME TABLE plans_plan TO plans;

RENAME TABLE users_customuser TO customer;

RENAME TABLE withdrawals_withdrawal TO withdrawal;

DELIMITER //
CREATE PROCEDURE view_withdrawal()
BEGIN
	SELECT *
    FROM withdrawal
    LIMIT 5;
END //
DELIMITER ;

call view_user;
call view_savings;
call view_plan;

DESCRIBE savings;
DESCRIBE plans;
/*
1. High-Value Customers with Multiple Products
Scenario: The business wants to identify customers who have both a savings and an investment plan (cross-selling opportunity).
Task: Write a query to find customers with at least one funded savings plan AND one funded investment plan, sorted by total deposits.
Tables:
●	users_customuser
●	savings_savingsaccount
●	plans_plan

*/
WITH CTE AS (
SELECT plan.id, plan.owner_id,name , is_regular_savings,is_a_fund, sav.total_deposit
FROM (
SELECT id,owner_id, is_regular_savings,is_a_fund
FROM plans
WHERE is_regular_savings !=0 OR is_a_fund !=0
GROUP BY id, owner_id ) AS plan
JOIN (
SELECT id, CONCAT(first_name,' ',last_name) AS name
FROM customer
WHERE first_name != '') AS us
ON plan.owner_id = us.id
JOIN (
SELECT plan_id,(SUM(confirmed_amount)/100) AS total_deposit
FROM savings
WHERE transaction_status LIKE 'success%'
GROUP BY plan_id ) AS sav
ON plan.id = sav.plan_id
)
SELECT owner_id,name, SUM(is_regular_savings)AS savings_count, 
SUM(is_a_fund) AS investment_count, 
FORMAT(SUM(total_deposit),'N0')  AS total_deposit
FROM CTE
group by owner_id, name
ORdeR BY savings_count DESC;

call view_savings();


SELECT plan_id,SUM(confirmed_amount) AS total_deposit
FROM savings
WHERE transaction_status LIKE 'success%'
GROUP BY plan_id;

SELECT DISTINCT transaction_status
from savings
WHERE transaction_status LIKE 'success%';

call view_savings();

/*
2. Transaction Frequency Analysis
Scenario: The finance team wants to analyze how often customers transact to segment them (e.g., frequent vs. occasional users).
Task: Calculate the average number of transactions per customer per month and categorize them:
●	"High Frequency" (≥10 transactions/month)
●	"Medium Frequency" (3-9 transactions/month)
●	"Low Frequency" (≤2 transactions/month)
Tables:
●	users_customuser
●	savings_savingsaccount
*/
WITH final AS (
WITH category AS (
WITH CTE AS (
SELECT owner_id,DATE_FORMAT(transaction_date, '%M-%Y') as month_year, COUNT(*) AS trans_per_cust
FROM savings
GROUP BY owner_id, month_year)
SELECT owner_id, AVG(trans_per_cust) AS avg_tran_per_month
FROM CTE
group by owner_id)
SELECT *,
	CASE
		WHEN avg_tran_per_month >=10 THen 'High Frequency'
        WHEN avg_tran_per_month BETWEEN 3 AND 9 THEN 'Medium Frequency'
        ELSE 'Low Frequency'
	END AS frequency_category
FROM category )
SELECT frequency_category, 
COUNT(owner_id) AS customer_count, 
ROUND(AVG(avg_tran_per_month),1) AS avg_transaction_per_month
FROM final
GROUP BY frequency_category;

WITH CTE AS (
SELECT owner_id,DATE_FORMAT(transaction_date, '%M-%Y') as month_year, COUNT(*) AS trans_per_cust
FROM savings
GROUP BY owner_id, month_year
), 
category AS (
SELECT owner_id, AVG(trans_per_cust) AS avg_tran_per_month
FROM CTE
group by owner_id), 
final AS (
SELECT *,
	CASE
		WHEN avg_tran_per_month >=10 THen 'High Frequency'
        WHEN avg_tran_per_month BETWEEN 3 AND 9 THEN 'Medium Frequency'
        ELSE 'Low Frequency'
	END AS frequency_category
FROM category 
)
SELECT frequency_category, 
COUNT(owner_id) AS customer_count, 
ROUND(AVG(avg_tran_per_month),1) AS avg_transaction_per_month
FROM final
GROUP BY frequency_category;

/*
3. Account Inactivity Alert
Scenario: The ops team wants to flag accounts with no inflow transactions for over one year.
Task: Find all active accounts (savings or investments) with no transactions in the last 1 year (365 days) .
Tables:
●	plans_plan
●	savings_savingsaccount

*/
SELECT trans.plan_id,plan.owner_id, plan.account_type, DATE_FORMAt(last_transaction_date,'%Y-%m-%d') AS last_transaction_date, (number_of_inactive_days - 365) as inactivity_days
FROM (
SELECT owner_id, id,
	CASE
		WHEN is_regular_savings = 1 THEN 'savings'
        WHEN is_a_fund =1 THEN 'investment'
        ELSE 'others'
	END as account_type
FROM plans
WHERE is_a_fund !=0 OR is_regular_savings !=0) as plan
JOIN (



SELECT plan_id,owner_id, last_transaction_date,datediff(currentdate, last_transaction_date) AS number_of_inactive_days
FROM (
SELECT plan_id, owner_id, MAX(transaction_date) as last_transaction_date, (SELECT MAX(transaction_date)
FROM savings) as currentdate
FROM savings
GROUP BY plan_id, owner_id) AS transaction
HAVING number_of_inactive_days >365) AS trans
ON plan.id = trans.plan_id;

SELECT cust.id AS customer_id, 
name, 
TIMESTAMPDIFF(MONTH,date_joined, last_transaction_date) As tenure_month, 
total_transactions, ROUND((total_transactions/TIMESTAMPDIFF(MONTH,date_joined, last_transaction_date))*12*avg_profit_per_transaction,2) as CLV 
FROM (
SELECT id, concat(first_name,' ',last_name) AS name, date_joined
FROM customer ) AS cust
JOIN (
SELECT owner_id,COUNT(transaction_date) AS total_transactions, MAX(transaction_date) AS last_transaction_date, (AVG(confirmed_amount)/100)*.01 AS avg_profit_per_transaction
FROM cowrywise.savings
GROUP BY owner_id) AS sav
ON cust.id=sav.owner_id;


SELECT id, concat(first_name,' ',last_name) AS name, date_joined, total_transactions, last_transaction_date, avg_profit_per_transaction
FROM customer  AS cust
RIGHT JOIN (
SELECT owner_id,COUNT(transaction_date) AS total_transactions, 
MAX(transaction_date) AS last_transaction_date, 
(AVG(confirmed_amount)/100)*.01 AS avg_profit_per_transaction
FROM cowrywise.savings
GROUP BY owner_id
ORDER BY owner_id) AS sav
ON cust.id=sav.owner_id;





SELECT cust.id AS customer_id, 
name, 
TIMESTAMPDIFF(MONTH,date_joined, last_transaction_date) As tenure_month, 
T.total_transactions, ROUND((T.total_transactions/TIMESTAMPDIFF(MONTH,date_joined, last_transaction_date))*12*avg_profit_per_transaction,2) as CLV
FROM (
SELECT owner_id,COUNT(transaction_date) AS total_transactions, 
MAX(transaction_date) AS last_transaction_date, 
(AVG(confirmed_amount)/100)*.01 AS avg_profit_per_transaction
FROM cowrywise.savings
GROUP BY owner_id
ORDER BY owner_id) AS T
join (
SELECT id, concat(first_name,' ',last_name) AS name, date_joined
FROM customer)  AS cust
ON T.owner_id=cust.id;