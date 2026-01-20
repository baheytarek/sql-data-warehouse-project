/* ===============================================================================
Business Metrics Summary Report
===============================================================================
Purpose: 
    To provide a comprehensive 'Pulse Check' of the business by aggregating 
    key metrics from Sales (Fact) and Customer/Product (Dimensions).
    
Usage:
    Ideal for populating KPI cards or high-level executive dashboards.
===============================================================================
*/


SELECT
'Total Sales' as measure_name,
SUM(sales_amount) as measure_value
FROM gold.fact_sales
UNION ALL
SELECT
'Total Quantity' as measure_name,
SUM(quantity) as measure_value
FROM gold.fact_sales
UNION ALL
SELECT 
'Total Orders' as measure_name,
COUNT(DISTINCT order_number) as measure_value 
FROM gold.fact_sales
UNION ALL
SELECT
'Total Customers' as measure_name,
COUNT(*) AS measure_value 
FROM gold.dim_customers
UNION ALL
SELECT 'Average Price' as measure_name ,AVG(price) as measure_value
FROM gold.fact_sales
UNION ALL
SELECT 'No. of Products' as measure_name, count(*) as measure_value 
FROM gold.dim_products
