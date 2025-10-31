-- =====================================================
-- Complete Setup Script for HongsaDW
-- Star Schema Dimensional Data Warehouse
-- =====================================================
-- This script:
--   1. Creates HongsaDW database and schema
--   2. Populates all dimension and fact tables
-- =====================================================
-- Usage:
--   sqlcmd -S <server> -i sql/setup_hongsa_dw_complete.sql -v SourceDbName="Hongsa"
-- =====================================================

USE master;
GO

-- Get source database name from parameter or use default
DECLARE @SourceDbName NVARCHAR(100) = 'Hongsa';  -- Default source database name

-- If you're running via sqlcmd with -v parameter:
-- DECLARE @SourceDbName NVARCHAR(100) = '$(SourceDbName)';

PRINT '=====================================================';
PRINT 'Starting HongsaDW Setup';
PRINT 'Source Database: ' + @SourceDbName;
PRINT '=====================================================';
GO

-- Run schema creation
:r sql/create_hongsa_dw_schema.sql
GO

-- Note: The populate script needs to be run separately because
-- it requires the source database to exist
-- You can run it manually:
-- sqlcmd -S <server> -d HongsaDW -i sql/populate_hongsa_dw_data.sql

PRINT '=====================================================';
PRINT 'Schema creation completed!';
PRINT 'Next step: Run populate_hongsa_dw_data.sql';
PRINT '=====================================================';
GO

