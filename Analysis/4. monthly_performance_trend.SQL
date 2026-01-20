/* ===============================================================================
Monthly Performance Trend Analysis
===============================================================================
Purpose: 
    To analyze how key business metrics (Sales, Customers, and Quantity) 
    evolve month-over-month to identify seasonality and growth trends.
    
Granularity: 
    Monthly (Ordered chronologically).
===============================================================================
*/

SELECT 
DATETRUNC(MONTH ,order_date) as order_date,
SUM(sales_amount) as total_sales,
COUNT(DISTINCT customer_key) as no_of_customers,
SUM(quantity) as total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH ,order_date)
ORDER BY DATETRUNC(MONTH ,order_date)
