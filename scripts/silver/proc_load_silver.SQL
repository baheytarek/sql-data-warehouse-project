/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to
    populate the 'silver' schema tables from the 'bronze' schema.
Action Performed:
    - Truncates Silver tables.
    - Inserts transformed and cleansed data from Bronze into Silver tables.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC silver.load_silver;
===============================================================================
*/




CREATE OR ALTER PROCEDURE silver.load_silver AS 
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
    
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '===================================================';
        PRINT 'Loading Silver Layer (Transformation & Cleansing)';
        PRINT '===================================================';

        ---------------------------------------------------
        -- CRM Tables
        ---------------------------------------------------
        PRINT '---------------------------------------------------';
        PRINT 'Loading CRM tables';
        PRINT '---------------------------------------------------';

        -- 1. crm_cust_info
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;
        PRINT '>> Inserting Data Into: silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info (cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date)
        SELECT 
            cst_id,
            cst_key,
            TRIM(cst_firstname),
            TRIM(cst_lastname),
            CASE WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                 WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                 ELSE 'n/a' END,
            CASE WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                 WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                 ELSE 'n/a' END,
            cst_create_date
        FROM (
            SELECT *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
            FROM bronze.crm_cust_info
        ) t WHERE flag_last = 1;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds';

        -- 2. crm_prd_info
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;
        PRINT '>> Inserting Data Into: silver.crm_prd_info';
        INSERT INTO silver.crm_prd_info(prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt)
        SELECT
            prd_id,
            REPLACE(SUBSTRING(prd_key,1,5), '-', '_') as cat_id,
            SUBSTRING(prd_key,7,LEN(prd_key)) as prd_key,
            prd_nm,
            ISNULL(prd_cost,0) AS prd_cost,
            CASE UPPER(TRIM(prd_line)) 
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a' END,
            prd_start_dt,
            DATEADD(day,-1,LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) as prd_end_dt
        FROM bronze.crm_prd_info;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds';

        -- 3. crm_sales_details
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;
        PRINT '>> Inserting Data Into: silver.crm_sales_details';
        INSERT INTO silver.crm_sales_details(sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price)
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) END,
            CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) END,
            CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) END,
            CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) THEN sls_quantity * ABS(sls_price) ELSE sls_sales END,
            sls_quantity,
            CASE WHEN sls_price IS NULL or sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity,0) ELSE sls_price END
        FROM bronze.crm_sales_details;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds';

        ---------------------------------------------------
        -- ERP Tables
        ---------------------------------------------------
        PRINT '---------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '---------------------------------------------------';

        -- 4. erp_CUST_AZ12
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_CUST_AZ12';
        TRUNCATE TABLE silver.erp_CUST_AZ12;
        PRINT '>> Inserting Data Into: silver.erp_CUST_AZ12';
        INSERT INTO silver.erp_CUST_AZ12(cid, bdate, gen)
        SELECT 
            CASE WHEN CID LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) ELSE CID END,
            CASE WHEN BDATE > GETDATE() THEN NULL ELSE BDATE END,
            CASE WHEN UPPER(TRIM(Gen)) IN ('F','FEMALE') THEN 'Female'
                 WHEN UPPER(TRIM(Gen)) IN ('M','MALE') THEN 'Male'
                 ELSE 'n/a' END
        FROM bronze.erp_CUST_AZ12;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds';

        -- 5. erp_LOC_A101
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_LOC_A101';
        TRUNCATE TABLE silver.erp_LOC_A101;
        PRINT '>> Inserting Data Into: silver.erp_LOC_A101';
        INSERT INTO silver.erp_LOC_A101(cid, cntry)
        SELECT
            REPLACE(cid, '-', '') as cid,
            CASE WHEN TRIM(CNTRY) = 'DE' THEN 'Germany'
                 WHEN TRIM(CNTRY) IN ('US' ,'USA') THEN 'United States'
                 WHEN TRIM(CNTRY) = '' OR CNTRY IS NULL THEN 'n/a'
                 ELSE TRIM(CNTRY) END
        FROM bronze.erp_LOC_A101;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds';

        -- 6. erp_PX_CAT_G1V2
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_PX_CAT_G1V2';
        TRUNCATE TABLE silver.erp_PX_CAT_G1V2;
        PRINT '>> Inserting Data Into: silver.erp_PX_CAT_G1V2';
        INSERT INTO silver.erp_PX_CAT_G1V2 (ID, CAT, SUBCAT, MAINTENANCE)
        SELECT ID, CAT, SUBCAT, MAINTENANCE FROM bronze.erp_PX_CAT_G1V2;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds';

        SET @batch_end_time = GETDATE();
        PRINT '===========================================';
        PRINT 'Loading Silver Layer is Completed';
        PRINT '>> - Total Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' Seconds';
        PRINT '===========================================';
    END TRY
    BEGIN CATCH
        PRINT '==========================================';
        PRINT 'ERROR OCCURRED DURING SILVER LOAD';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==========================================';
    END CATCH
END;
