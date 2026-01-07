/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' schema. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- ============================================================================
-- Checking 'silver.crm_cust_info'
-- ============================================================================

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT 
    cst_id,
    COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) != 1 or cst_id IS NULL;
GO

-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

-- Reviewing Data
SELECT * FROM silver.crm_cust_info;


-- ============================================================================
-- Checking 'silver.crm_prd_info'
-- ============================================================================

-- Check for duplicates or Null in Primary key
-- Expectation: No Results
SELECT 
	prd_id,
	COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING count(*) != 1;

-- Check for Spaces in prd_nm
-- Expectation: No Results
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Check numbers quality (nulls, negative)
-- Expectation: No Results
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Data Standardization & Consistency
-- Expectation: Standardized Values ('Mountain', 'Road', etc.)
SELECT DISTINCT prd_line
FROM silver.crm_prd_info;

-- Check Invalid dates (End > Start)
-- Expectation: No Results
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;


-- ============================================================================
-- Checking 'silver.crm_sales_details'
-- ============================================================================

-- Check for Unwanted Spaces in Order Numbers
-- Expectation: No Results
SELECT *
FROM silver.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

-- Validate Product Key (Referential Integrity)
-- Expectation: No Results
SELECT *
FROM silver.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);
GO

-- Validate Customer Key (Referential Integrity)
-- Expectation: No Results
SELECT *
FROM silver.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);

-- Check for Invalid Dates (Order Date)
-- Expectation: No Results
SELECT NULLIF(sls_order_dt,0) as sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt <= 0 
	OR LEN(sls_order_dt) != 8
	OR sls_order_dt > 20500101
	OR sls_order_dt < 19000101;
GO

-- Check for Invalid Dates (Shipping Date)
-- Expectation: No Results
SELECT NULLIF(sls_ship_dt,0) as sls_ship_dt
FROM silver.crm_sales_details
WHERE sls_ship_dt <= 0 
	OR LEN(sls_ship_dt) != 8
	OR sls_ship_dt > 20500101
	OR sls_ship_dt < 19000101;
GO


-- ============================================================================
-- Checking 'silver.erp_CUST_AZ12'
-- ============================================================================

-- Validate BDATE (Birth Date)
-- Expectation: No future dates or impossible historical dates
SELECT DISTINCT 
BDATE
FROM silver.erp_CUST_AZ12
WHERE BDATE > GETDATE() OR BDATE < '1900-01-01';

-- Check gender consistency & standardization
-- Expectation: Standardized Values ('Male', 'Female', 'n/a')
SELECT DISTINCT Gen,
CASE WHEN UPPER(TRIM(Gen)) IN ('F','FEMALE') THEN 'Female'
WHEN UPPER(TRIM(Gen)) IN ('M','MALE') THEN 'Male'
ELSE 'n/a'
END AS Gen_Standardized
FROM silver.erp_cust_AZ12;
