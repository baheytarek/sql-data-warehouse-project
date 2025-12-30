/*

==================================================

Create Database & Schemas

==================================================

Script Purpose:

This script creates a new database called 'DataWarehouse',in addition to setup three schemas within the database: 'bronze', 'silver' and 'gold'.

*/


 USE master;
 GO

  -- Create Database 'DataWarehouse'
 CREATE DATABASE DataWarehouse;
 GO


 USE DataWarehouse;
 GO

 -- Create Schemas
 CREATE SCHEMA bronze;
 GO
 CREATE SCHEMA silver;
 GO
 CREATE SCHEMA gold;
 GO
