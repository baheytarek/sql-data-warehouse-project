/*
===============================================================================
GOLD LAYER QUALITY ASSURANCE (QA) TESTS
===============================================================================
Purpose:
    This script contains a suite of data quality checks to validate the 
    integrity, uniqueness, and referential consistency of the Gold Layer tables.
    
Checks include:
    - Customer Uniqueness & Gender Logic
    - Product Uniqueness (Current Products)
    - Fact-Dimension Referential Integrity (Foreign Key Checks)
===============================================================================
*/

---- Quality checks on Gold layer
-- No duplications 
---- Customer related tables checks

SELECT 
	cst_id,
	count(*)
FROM (
	SELECT 
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_lastname,
	ci.cst_marital_status,
	ci.cst_gndr,
	ci.cst_create_date,
	ca.bdate,
	ca.gen,
	la.cntry
FROM Silver.crm_cust_info ci
LEFT JOIN 
	silver.erp_CUST_AZ12 ca ON ci.cst_key = ca.cid
LEFT JOIN 
	silver.erp_LOC_A101 la ON ci.cst_key = la.cid
	)t GROUP BY cst_id
	HAVING count(*) > 1;
GO

---- check ci gndr, ca gen
SELECT DISTINCT 
	ci.cst_gndr,
	ca.gen,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr --- CRM is the master info for gndr
		ELSE COALESCE(ca.gen, 'n/a')
		END AS new_gen
FROM silver.crm_cust_info ci
LEFT JOIN 
	silver.erp_CUST_AZ12 ca ON ci.cst_key = ca.cid
ORDER BY 1,2

SELECT DISTINCT gender FROM gold.dim_customers

---- Product related tables checks
---- Unique prd_key

SELECT prd_key,COUNT(*) FROM(
SELECT
	pn.prd_id,
	pn.cat_id,
	pn.prd_key,
	pn.prd_nm,
	pn.prd_cost,
	pn.prd_line,
	pn.prd_start_dt,
	pn.prd_end_dt,
	pc.CAT,
	pc.SUBCAT,
	pc.MAINTENANCE
FROM silver.crm_prd_info pn
LEFT JOIN 
	silver.erp_PX_CAT_G1V2 pc ON pn.cat_id = pc.ID
WHERE pn.prd_end_dt IS NULL  --- Get current products only
) t GROUP BY prd_key
HAVING COUNT(*) > 1

---- fact sales check
SELECT * FROM gold.fact_sales

----- Foreign Keys integrity 
SELECT *
FROM gold.fact_sales f
LEFT JOIN 
	gold.dim_customers c on f.customer_key = c.customer_key
LEFT JOIN
	gold.dim_products p on f.product_key = p.product_key
	WHERE p.product_key IS NULL
