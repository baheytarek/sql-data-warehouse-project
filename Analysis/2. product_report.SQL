/*
=============================================================================
Product Report
=============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
        - total orders
        - total sales
        - total quantity sold
        - total customers (unique)
        - lifespan (in months)
    4. Calculates valuable KPIs:
        - recency (months since last sale)
        - average order revenue (AOR)
        - average monthly revenue
=============================================================================
*/

CREATE VIEW gold.report_products AS 
WITH base_query AS(
/* -------------------------------------------------
--- 1. Base query: Retrieves Core Column from tables
--------------------------------------------------*/
SELECT 
s.order_number,
p.product_key,
s.customer_key,
s.order_date,
s.sales_amount,
s.quantity,
p.product_name,
p.category,
p.subcategory,
p.product_cost
FROM gold.fact_sales s
LEFT JOIN 
	gold.dim_products p ON s.product_key = p.product_key
	WHERE order_date IS NOT NULL),

product_aggregations AS (
/* ----------------------------------------------
2- Product Aggregations: Summarizes Key Metrics at the product level
------------------------------------------------*/
SELECT
product_key,
product_name,
category,
subcategory,
product_cost,
DATEDIFF(MONTH, MIN(order_date),MAX(order_date)) as lifespan,
MAX(order_date) as last_order,
SUM(sales_amount) as total_sales,
SUM(quantity) as total_quantity,
COUNT(DISTINCT order_number) as total_orders,
COUNT(DISTINCT customer_key) as total_customers
FROM base_query
GROUP BY 
product_key,
product_name,
product_cost,
category,
subcategory
)

/* -------------------------------------------
3- Final Query: Combines all product results in one query
---------------------------------------------*/

SELECT 
product_key,
product_name,
category,
subcategory,
product_cost,
last_order,
DATEDIFF(MONTH,last_order,GETDATE()) as recency,
CASE WHEN total_sales > 50000 THEN 'High Performers'
	WHEN total_sales >= 10000 THEN 'Mid-Range'
	ELSE 'Low Performers'
END AS product_segment,
lifespan,
total_sales,
total_quantity,
total_customers,
total_orders,
--- average order revenue AOR
CASE WHEN total_orders = 0 THEN 0
	ELSE total_sales / total_orders
END AS average_order_revenue,
--- average monthly revenue
CASE WHEN lifespan = 0 THEN 0
	ELSE total_sales / lifespan
END AS average_monthly_revenue
FROM product_aggregations
