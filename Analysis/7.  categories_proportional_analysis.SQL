/* ===============================================================================
Product Category Contribution Analysis
===============================================================================
Purpose: 
    - To determine which product categories drive the most revenue.
    - To visualize the 'Sales Mix' by calculating each category's percentage of 
      total overall sales.

Key Features:
    - Grand Total: Uses SUM() OVER () to get the denominator for all rows.
    - Precision: Casts values to FLOAT to ensure accurate decimal division.
    - Ranking: Orders results by sales to highlight the top-performing categories.
===============================================================================
*/

WITH category_sales AS(
SELECT 
p.category,
SUM(s.sales_amount) as total_sales
FROM gold.fact_sales s
LEFT JOIN
	gold.dim_products p ON s.product_key = p.product_key
WHERE p.category IS NOT NULL
GROUP BY p.category)

SELECT
category,
total_sales,
SUM(total_sales) OVER () overall_sales,
CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER ()*100),2),'%') as category_contribution ---- convert from integer to get a percentage
FROM category_sales
ORDER BY total_sales DESC
