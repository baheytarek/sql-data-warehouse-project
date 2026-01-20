/*
================================
Customer Report
================================
Purpose:
	- This report consolidates key customer metrics and behaviors

Highlights:
	- Gathers essential fields such as names, ages, and transaction details.
	- Segments customers into categories (VIP, Regular, New) and age groups.
	- Aggregates customer-level metrics:
		1. total orders
		2. total sales
		3. total quantity purchased
		4. total products
		5. lifespan (in months)
	- Calculates valuable KPIs:
		1. recency (months since last order)
		2. average order value
		3. average monthly spend
*/

CREATE VIEW gold.report_customers AS
WITH base_query AS (
/* -------------------------------------------------
--- 1. Base query: Retrieves Core Column from tables
--------------------------------------------------*/
SELECT 
s.order_number,
s.product_key,
s.order_date,
s.sales_amount,
s.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name,' ',c.last_name) as customer_name,
DATEDIFF(YEAR,c.birth_date,GETDATE()) as customer_age
FROM gold.fact_sales s
LEFT JOIN
	gold.dim_customers c ON s.customer_key = c.customer_key
	WHERE order_date IS NOT NULL)

, customer_aggeregations AS (
/* ----------------------------------------------
2- Customer Aggregations: Summarizes Key Metrics at the customer level
------------------------------------------------*/
SELECT 
customer_key,
customer_number,
customer_name,
customer_age,
COUNT(DISTINCT order_number) as total_orders,
SUM(sales_amount) as total_sales,
SUM(quantity) as total_quantity,
COUNT(DISTINCT product_key) as total_products,
MAX(order_date) as last_order,
DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) as customer_lifespan
FROM base_query
GROUP BY 
	customer_key,
	customer_number,
	customer_name,
	customer_age)

/* -------------------------------------------
3- Final Query: Combines all customer results in one query
---------------------------------------------*/

SELECT 
customer_key,
	customer_number,
	customer_name,
	customer_age,
	CASE WHEN customer_age < 20 THEN 'Under 20'
		WHEN customer_age BETWEEN 20 AND 29 THEN '20-29'
		WHEN customer_age BETWEEN 30 AND 39 THEN '30-39'
		WHEN customer_age BETWEEN 40 AND 49 THEN '40-49'
		ELSE '50 & Above'
	END AS age_group,
	CASE WHEN customer_lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
	WHEN customer_lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
	ELSE 'New'
	END AS customer_segment,
	last_order,
	DATEDIFF(MONTH,last_order,GETDATE()) as recency,
	total_orders,
	total_sales,
	total_quantity,
	total_products,
	customer_lifespan,
	----- Compute average order value
	CASE WHEN total_orders = 0 THEN 0   --- avoid zero order customer affect analysis
	ELSE total_sales/total_orders
	END AS avg_order_value,
	------ Compute average monthly spend
	CASE WHEN customer_lifespan = 0 THEN total_sales
	ELSE total_sales / customer_lifespan
	END AS avg_monthly_spend
FROM customer_aggeregations
