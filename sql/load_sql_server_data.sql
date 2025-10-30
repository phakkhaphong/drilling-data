-- =====================================================
-- Load Coal Drilling Database Data to SQL Server
-- Complete System with All Data from DH70.xlsx
-- =====================================================
-- Updated: Based on actual data from DH70.xlsx
-- =====================================================

-- Load seam codes lookup (CSV includes seam_id identity)
SET IDENTITY_INSERT seam_codes_lookup ON;
BULK INSERT seam_codes_lookup
FROM 'data/normalized_sql_server/seam_codes_lookup.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2,
    TABLOCK
);
SET IDENTITY_INSERT seam_codes_lookup OFF;

-- Load rock types (rock_code is PRIMARY KEY, no identity)
BULK INSERT rock_types
FROM 'data/normalized_sql_server/rock_types.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2,
    TABLOCK
);

-- Load collars (CSV includes collar_id identity)
SET IDENTITY_INSERT collars ON;
BULK INSERT collars
FROM 'data/normalized_sql_server/collars.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2,
    TABLOCK
);
SET IDENTITY_INSERT collars OFF;

-- Load lithology logs (CSV includes log_id identity)
SET IDENTITY_INSERT lithology_logs ON;
BULK INSERT lithology_logs
FROM 'data/normalized_sql_server/lithology_logs.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2,
    TABLOCK
);
SET IDENTITY_INSERT lithology_logs OFF;

-- Load sample analyses (CSV includes sample_id identity)
SET IDENTITY_INSERT sample_analyses ON;
BULK INSERT sample_analyses
FROM 'data/normalized_sql_server/sample_analyses.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2,
    TABLOCK
);
SET IDENTITY_INSERT sample_analyses OFF;

-- Verify data loading
SELECT 'Seam Codes Count:' as info, COUNT(*) as count FROM seam_codes_lookup
UNION ALL
SELECT 'Rock Types Count:', COUNT(*) FROM rock_types
UNION ALL
SELECT 'Collars Count:', COUNT(*) FROM collars
UNION ALL
SELECT 'Lithology Logs Count:', COUNT(*) FROM lithology_logs
UNION ALL
SELECT 'Sample Analyses Count:', COUNT(*) FROM sample_analyses;

-- Show seam code system summary
SELECT 'Seam Codes by System:' as info;
SELECT system_id, system_name, COUNT(*) as count, MIN(priority) as priority
FROM seam_codes_lookup 
GROUP BY system_id, system_name 
ORDER BY priority;

-- Show sample analyses seam code mapping
SELECT 'Sample Analyses Seam Code Mapping:' as info;
SELECT 
    'Quality System' as system_name,
    COUNT(*) as samples_with_seam_codes
FROM sample_analyses 
WHERE seam_quality_id IS NOT NULL
UNION ALL
SELECT 
    'System 73',
    COUNT(*)
FROM sample_analyses 
WHERE seam_73_id IS NOT NULL;
