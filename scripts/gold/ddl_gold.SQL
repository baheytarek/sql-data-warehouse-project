/*
=================================================
DDL script : Create Gold Views
=================================================
Script Purpose:
	This Script create Gold views for Data Warehouse.
	The Gold layer represents the final dimension and fact tables (Star Schema)

	Each view performs transformations and combines data from silver layer
	to produce clean, enriched and business-ready dataset.

Usage: 
	- These Views can be queried directly for analytics & reporting

==================================================
*/

---- ====================================================
-- Create Dimension: gold.dim_customers
---- ====================================================


IF OBJECT_ID ('gold.dim_customers', 'V') IS NOT NULL
	DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS (
SELECT 
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	la.cntry AS country,
	ci.cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr --- CRM is the master info for gndr
		ELSE COALESCE(ca.gen, 'n/a')
		END AS gender,
	ca.bdate AS birth_date,
	ci.cst_create_date AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN 
	silver.erp_CUST_AZ12 ca ON ci.cst_key = ca.cid
LEFT JOIN 
	silver.erp_LOC_A101 la ON ci.cst_key = la.cid
) 
GO


---- ====================================================
-- Create Dimension: gold.dim_products
---- ====================================================


IF OBJECT_ID ('gold.dim_products', 'V') IS NOT NULL
	DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS (
SELECT
	ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt,pn.prd_key) AS product_key,
	pn.prd_id AS product_id,
	pn.prd_key AS product_number,
	pn.prd_nm AS product_name,
	pn.cat_id AS category_id,
	pc.CAT AS category,
	pc.SUBCAT AS subcategory,
	pc.MAINTENANCE AS maintenance,
	pn.prd_cost AS product_cost,
	pn.prd_line AS product_line,
	pn.prd_start_dt AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN 
	silver.erp_PX_CAT_G1V2 pc ON pn.cat_id = pc.ID
WHERE pn.prd_end_dt IS NULL  --- Get current products only
)
GO

---- ====================================================
-- Create Dimension: gold.fact_sales
---- ====================================================

IF OBJECT_ID ('gold.fact_sales', 'V') IS NOT NULL
	DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS (
SELECT
	sls_ord_num order_number,
	pr.product_key,
	cu.customer_key,
	sls_order_dt order_date,
	sls_ship_dt	shipping_date,
	sls_due_dt due_date,
	sls_sales sales_amount,
	sls_quantity quantity,
	sls_price price
FROM silver.crm_sales_details sd
LEFT JOIN
	gold.dim_products pr ON sd.sls_prd_key = pr.product_number
LEFT JOIN
	gold.dim_customers cu ON sd.sls_cust_id = cu.customer_id
	)
GO
