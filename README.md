1. SELECT job_industry_category AS industry_category, COUNT(customer_id) AS customer_count
FROM customer GROUP BY job_industry_category ORDER BY customer_count DESC;

![image](https://github.com/user-attachments/assets/27642509-2835-4a6c-bbd1-7b4c4fc67e25)
2. SELECT customer.job_industry_category ,date_trunc('month', to_date(transaction.transaction_date, 'DD.MM.YYYY')) 
AS transaction_month ,sum(transaction.list_price) AS transaction_sum FROM transaction JOIN customer ON customer.customer_id = transaction.customer_id 
GROUP BY customer.job_industry_category, transaction_month ORDER BY customer.job_industry_category, transaction_month;

![image](https://github.com/user-attachments/assets/4c2ac690-cc29-48e3-9bf5-b68180bd909d)
3. SELECT transaction.brand AS brand, COUNT(transaction.transaction_id) AS online_order_count
FROM transaction JOIN customer ON transaction.customer_id = customer.customer_id
WHERE customer.job_industry_category = 'IT' AND transaction.online_order = 'True' AND transaction.order_status = 'Approved'
GROUP BY transaction.brand;

![image](https://github.com/user-attachments/assets/f54d510e-8642-48fd-bdab-ac5cdf2e5a9a)
4.SELECT customer.customer_id, 
    SUM(transaction.list_price) AS total_transaction_amount,
    MAX(transaction.list_price) AS max_transaction_amount, 
    MIN(transaction.list_price) AS min_transaction_amount,
    COUNT(transaction.transaction_id) AS transaction_count
FROM transaction JOIN customer ON transaction.customer_id = customer.customer_id
GROUP BY customer.customer_id ORDER BY total_transaction_amount DESC, transaction_count DESC;

![image](https://github.com/user-attachments/assets/18774b42-279e-49f1-9ce8-8f5b40398580)
SELECT DISTINCT customer.customer_id,
    SUM(transaction.list_price) OVER (PARTITION BY customer.customer_id) AS total_transaction_amount,
    MAX(transaction.list_price) OVER (PARTITION BY customer.customer_id) AS max_transaction_amount,
    MIN(transaction.list_price) OVER (PARTITION BY customer.customer_id) AS min_transaction_amount,
    COUNT(transaction.transaction_id) OVER (PARTITION BY customer.customer_id) AS transaction_count
FROM transaction JOIN customer ON transaction.customer_id = customer.customer_id 
ORDER BY total_transaction_amount DESC, transaction_count DESC;

![image](https://github.com/user-attachments/assets/7b98db89-fbe0-4c3d-9537-45f658810f26)
5. Максимум:
 SELECT customer.first_name, customer.last_name, SUM(transaction.list_price) AS total_transaction_amount
FROM transaction JOIN customer ON transaction.customer_id = customer.customer_id
GROUP BY customer.customer_id, customer.first_name, customer.last_name
HAVING SUM(transaction.list_price) = (SELECT MAX(total_amount)
FROM (SELECT SUM(transaction.list_price) AS total_amount FROM transaction GROUP BY transaction.customer_id) AS max_transactions);

![image](https://github.com/user-attachments/assets/4a09b4a4-477e-4c04-b986-4cbbe61dc339)

Минимум: 
SELECT customer.first_name, customer.last_name, SUM(transaction.list_price) AS total_transaction_amount 
FROM transaction JOIN customer ON transaction.customer_id = customer.customer_id 
GROUP BY customer.customer_id, customer.first_name,customer.last_name 
HAVING SUM(transaction.list_price) = (SELECT MIN(total_amount)
FROM (SELECT SUM(transaction.list_price) AS total_amount FROM transaction GROUP BY transaction.customer_id) AS min_transactions);

![image](https://github.com/user-attachments/assets/be0975a3-3341-4e3e-825b-90d6ff58c84d)
6.WITH ranked_transactions AS (SELECT transaction.transaction_id, transaction.customer_id, transaction.transaction_date, transaction.list_price,
ROW_NUMBER() OVER (PARTITION BY transaction.customer_id ORDER BY transaction.transaction_date) AS rn
FROM transaction)
SELECT transaction_id,customer_id,transaction_date, list_price
FROM ranked_transactions WHERE rn = 1;

![image](https://github.com/user-attachments/assets/7352da73-45f8-41bc-b7a5-7bf3c0d60341)

7.WITH transaction_date AS (select transaction.customer_id,  customer.first_name,  customer.last_name,  customer.job_title, TO_DATE(transaction.transaction_date, 'DD.MM.YYYY') AS transaction_date
FROM transaction  JOIN customer ON customer.customer_id = transaction.customer_id),
lagged_date AS (select transaction_date.customer_id,transaction_date.first_name, transaction_date.last_name, transaction_date.job_title,transaction_date.transaction_date,
LAG(transaction_date.transaction_date) 
OVER (PARTITION BY transaction_date.customer_id ORDER BY transaction_date.transaction_date) AS prev_transaction_date FROM transaction_date),
date_difference AS (select lagged_date.customer_id,lagged_date.first_name,lagged_date.last_name,lagged_date.job_title, lagged_date.transaction_date,lagged_date.prev_transaction_date,
(lagged_date.transaction_date - lagged_date.prev_transaction_date) 
AS day_difference FROM lagged_date WHERE lagged_date.prev_transaction_date IS NOT NULL),
max_difference AS (SELECT MAX(date_difference.day_difference) AS max_day_difference FROM date_difference)
SELECT date_difference.first_name,date_difference.last_name,date_difference.job_title,date_difference.day_difference
FROM date_difference JOIN max_difference ON max_difference.max_day_difference = date_difference.day_difference
ORDER BY date_difference.day_difference DESC;

![image](https://github.com/user-attachments/assets/6d939068-a489-4e28-aefd-c5de98f439d6)


