/* ===============================================================================
Cumulative Sales & Price Momentum Analysis
===============================================================================
Purpose: 
    1. Monthly Sales: Basic revenue per month.
    2. Running Total: Year-to-Date (YTD) accumulation of sales.
    3. Moving Average: Smoothing price fluctuations to identify long-term trends.

Techniques Used: 
    - CTE/Subquery for initial aggregation.
    - Window Functions (SUM OVER, AVG OVER) for cumulative analysis.
===============================================================================
*/

SELECT
order_date,
total_sales,
SUM(total_sales) OVER (PARTITION BY YEAR(order_date) ORDER BY order_date) as running_total_sales, --- Limit to one year
AVG(average_price) OVER (ORDER BY order_date) as moving_average_price
FROM
(
SELECT
	DATETRUNC(MONTH,order_date) as order_date,
	SUM(sales_amount) as total_sales,
	AVG(price) as average_price
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH,order_date)
) t
