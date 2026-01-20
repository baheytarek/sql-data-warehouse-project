/* ===============================================================================
Product Performance & Year-Over-Year (YoY) Analysis
===============================================================================
Purpose: 
    - To assess how each product is performing compared to its own historical average.
    - To track annual sales fluctuations (Increase/Decrease) vs. the previous year.

Key Metrics:
    1. current_sales: Total revenue for the product in the specific year.
    2. avg_sales: The lifetime average yearly sales for that product.
    3. py_sales: Revenue from the previous calendar year (Year-over-Year).
    4. Performance Tags: Qualitative labels (Above/Below Average, Increase/Decrease).
===============================================================================
*/

WITH yearly_product_sales AS (
SELECT
YEAR(order_date) as order_year,
p.product_name,
SUM(sales_amount) as current_sales
FROM gold.fact_sales s
LEFT JOIN 
	gold.dim_products p ON s.product_key = p.product_key
WHERE order_date IS NOT NULL
GROUP BY 
YEAR(order_date),
p.product_name
)

SELECT 
order_year,
product_name,
current_sales,
AVG(current_sales) OVER (PARTITION BY product_name) avg_sales,
current_sales - AVG(current_sales) OVER (PARTITION BY product_name) as diff_avg,
CASE WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Average'
	WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Average'
	ELSE 'Average'
	END AS avg_change,
-- Year-over-Year Analysis
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) as py_sales,
current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) as diff_py,
CASE WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
	WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
	ELSE 'No change'
	END AS py_change
FROM yearly_product_sales
