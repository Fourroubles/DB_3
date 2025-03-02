create table customer (
	customer_id int4,
	first_name varchar(50),
	last_name varchar(50),
	gender varchar(30),
	dob varchar(50),
	job_title varchar(50),
	job_industry_category varchar(50),
	wealth_segment varchar(50),
	deceased_indicator varchar(50),
	owns_car varchar(30),
	address varchar(50),
	postcode varchar(30),
	state varchar(30),
	country varchar(30),
	property_valuation int4
);

create table transaction (
	transaction_id int4 primary key,
	product_id int4,
	customer_id int4,
	transaction_date varchar(30),
	online_order varchar(30),
	order_status varchar(30),
	brand varchar(30),
	product_line varchar(30),
	product_class varchar(30),
	product_size varchar(30),
	list_price float4 ,
	standard_cost float4
);

SELECT job_industry_category AS industry_category, COUNT(customer_id) AS customer_count
FROM customer GROUP BY job_industry_category ORDER BY customer_count DESC;

SELECT customer.job_industry_category ,date_trunc('month', to_date(transaction.transaction_date, 'DD.MM.YYYY')) 
AS transaction_month ,sum(transaction.list_price) AS transaction_sum FROM transaction JOIN customer ON customer.customer_id = transaction.customer_id 
GROUP BY customer.job_industry_category, transaction_month ORDER BY customer.job_industry_category, transaction_month;

SELECT transaction.brand AS brand, COUNT(transaction.transaction_id) AS online_order_count
FROM transaction JOIN customer ON transaction.customer_id = customer.customer_id
WHERE customer.job_industry_category = 'IT' AND transaction.online_order = 'True' AND transaction.order_status = 'Approved'
GROUP BY transaction.brand;

SELECT customer.customer_id, 
    SUM(transaction.list_price) AS total_transaction_amount,
    MAX(transaction.list_price) AS max_transaction_amount, 
    MIN(transaction.list_price) AS min_transaction_amount,
    COUNT(transaction.transaction_id) AS transaction_count
FROM transaction JOIN customer ON transaction.customer_id = customer.customer_id
GROUP BY customer.customer_id ORDER BY total_transaction_amount DESC, transaction_count DESC;

SELECT DISTINCT customer.customer_id,
    SUM(transaction.list_price) OVER (PARTITION BY customer.customer_id) AS total_transaction_amount,
    MAX(transaction.list_price) OVER (PARTITION BY customer.customer_id) AS max_transaction_amount,
    MIN(transaction.list_price) OVER (PARTITION BY customer.customer_id) AS min_transaction_amount,
    COUNT(transaction.transaction_id) OVER (PARTITION BY customer.customer_id) AS transaction_count
FROM transaction JOIN customer ON transaction.customer_id = customer.customer_id 
ORDER BY total_transaction_amount DESC, transaction_count DESC;

SELECT customer.first_name, customer.last_name, SUM(transaction.list_price) AS total_transaction_amount
FROM transaction JOIN customer ON transaction.customer_id = customer.customer_id
GROUP BY customer.customer_id, customer.first_name, customer.last_name
HAVING SUM(transaction.list_price) = (SELECT MAX(total_amount)
FROM (SELECT SUM(transaction.list_price) AS total_amount FROM transaction GROUP BY transaction.customer_id) AS max_transactions);

SELECT customer.first_name, customer.last_name, SUM(transaction.list_price) AS total_transaction_amount 
FROM transaction JOIN customer ON transaction.customer_id = customer.customer_id 
GROUP BY customer.customer_id, customer.first_name,customer.last_name 
HAVING SUM(transaction.list_price) = (SELECT MIN(total_amount)
FROM (SELECT SUM(transaction.list_price) AS total_amount FROM transaction GROUP BY transaction.customer_id) AS min_transactions);

WITH ranked_transactions AS (SELECT transaction.transaction_id, transaction.customer_id, transaction.transaction_date, transaction.list_price,
ROW_NUMBER() OVER (PARTITION BY transaction.customer_id ORDER BY transaction.transaction_date) AS rn
FROM transaction)
SELECT transaction_id,customer_id,transaction_date, list_price
FROM ranked_transactions WHERE rn = 1;



WITH transaction_date AS (
    SELECT
        transaction.customer_id,
        customer.first_name,
        customer.last_name,
        customer.job_title,
        TO_DATE(transaction.transaction_date, 'DD.MM.YYYY') AS transaction_date
    FROM transaction
    JOIN customer ON customer.customer_id = transaction.customer_id
),
lagged_date AS (
    SELECT
        transaction_date.customer_id,
        transaction_date.first_name,
        transaction_date.last_name,
        transaction_date.job_title,
        transaction_date.transaction_date,
        LAG(transaction_date.transaction_date) OVER (PARTITION BY transaction_date.customer_id ORDER BY transaction_date.transaction_date) AS prev_transaction_date
    FROM transaction_date
),
date_difference AS (
    SELECT
        lagged_date.customer_id,
        lagged_date.first_name,
        lagged_date.last_name,
        lagged_date.job_title,
        lagged_date.transaction_date,
        lagged_date.prev_transaction_date,
        (lagged_date.transaction_date - lagged_date.prev_transaction_date) AS day_difference
    FROM lagged_date
    WHERE lagged_date.prev_transaction_date IS NOT NULL
),
max_difference AS (
    SELECT
        MAX(date_difference.day_difference) AS max_day_difference
    FROM date_difference
)
SELECT
    date_difference.first_name,
    date_difference.last_name,
    date_difference.job_title,
    date_difference.day_difference
FROM date_difference
JOIN max_difference ON max_difference.max_day_difference = date_difference.day_difference
ORDER BY date_difference.day_difference DESC;