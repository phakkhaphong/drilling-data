-- =====================================================
-- Populate HongsaDW - Dimensional Model Data
-- Transfer data from relational model to dimensional model
-- =====================================================
-- Prerequisites:
--   1. Relational database must exist and be populated
--   2. HongsaDW database schema must be created
-- =====================================================

USE HongsaDW;
GO

-- =====================================================
-- CONFIGURATION: Set Source Database Name
-- =====================================================
-- Option 1: Set manually (uncomment and set your database name)
DECLARE @SourceDbName NVARCHAR(100) = 'HongsaNormalized';  -- Change this to your source database name

-- Option 2: Use sqlcmd parameter (if running via sqlcmd with -v SourceDbName="YourDb")
-- DECLARE @SourceDbName NVARCHAR(100) = 'HongsaNormalized';

-- Verify source database exists
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = @SourceDbName)
BEGIN
    PRINT 'ERROR: Source database ''' + @SourceDbName + ''' does not exist!';
    PRINT 'Please update @SourceDbName variable to point to your relational database.';
    RAISERROR('Source database not found', 16, 1);
END
ELSE
BEGIN
    PRINT 'Using source database: ' + @SourceDbName;
END
GO

-- =====================================================
-- STEP 1: Populate DimDate (Time Dimension)
-- =====================================================

-- Generate date dimension for years 2000-2100 (adjust as needed)
-- This creates a comprehensive date dimension for SSAS

-- Get date range from source data or use default range
DECLARE @MinDate DATE, @MaxDate DATE;
DECLARE @SQL NVARCHAR(MAX);

SET @SQL = '
SELECT 
    @MinDate = MIN(COALESCE(drilling_date, analysis_date, CAST(''2000-01-01'' AS DATE))),
    @MaxDate = MAX(COALESCE(drilling_date, analysis_date, CAST(''2100-12-31'' AS DATE)))
FROM (
    SELECT drilling_date, NULL AS analysis_date FROM [' + @SourceDbName + '].[dbo].[collars] WHERE drilling_date IS NOT NULL
    UNION ALL
    SELECT NULL, analysis_date FROM [' + @SourceDbName + '].[dbo].[sample_analyses] WHERE analysis_date IS NOT NULL
) dates';

DECLARE @Params NVARCHAR(500) = '@MinDate DATE OUTPUT, @MaxDate DATE OUTPUT';
EXEC sp_executesql @SQL, @Params, @MinDate OUTPUT, @MaxDate OUTPUT;

-- Fallback to default range if no dates found
IF @MinDate IS NULL SET @MinDate = '2000-01-01';
IF @MaxDate IS NULL SET @MaxDate = '2100-12-31';

PRINT 'Generating DimDate from ' + CAST(@MinDate AS VARCHAR(10)) + ' to ' + CAST(@MaxDate AS VARCHAR(10));

-- Generate date dimension
WITH DateSeries AS (
    SELECT @MinDate AS DateValue
    UNION ALL
    SELECT DATEADD(DAY, 1, DateValue)
    FROM DateSeries
    WHERE DateValue < @MaxDate
)
INSERT INTO DimDate (
    DateKey, FullDate, Day, Month, MonthName, MonthShortName,
    Quarter, QuarterName, Year, YearQuarter,
    WeekOfYear, DayOfWeek, DayName, DayShortName,
    IsWeekend, IsHoliday
)
SELECT 
    -- DateKey as YYYYMMDD
    CAST(CONVERT(VARCHAR(8), DateValue, 112) AS INT) AS DateKey,
    DateValue AS FullDate,
    DAY(DateValue) AS Day,
    MONTH(DateValue) AS Month,
    DATENAME(MONTH, DateValue) AS MonthName,
    LEFT(DATENAME(MONTH, DateValue), 3) AS MonthShortName,
    DATEPART(QUARTER, DateValue) AS Quarter,
    'Q' + CAST(DATEPART(QUARTER, DateValue) AS VARCHAR(1)) + ' ' + CAST(YEAR(DateValue) AS VARCHAR(4)) AS QuarterName,
    YEAR(DateValue) AS Year,
    CAST(YEAR(DateValue) AS VARCHAR(4)) + CAST(DATEPART(QUARTER, DateValue) AS VARCHAR(1)) AS YearQuarter,
    DATEPART(WEEK, DateValue) AS WeekOfYear,
    CASE 
        WHEN DATEPART(WEEKDAY, DateValue) = 1 THEN 7  -- Sunday = 7
        ELSE DATEPART(WEEKDAY, DateValue) - 1  -- Monday = 1
    END AS DayOfWeek,
    DATENAME(WEEKDAY, DateValue) AS DayName,
    LEFT(DATENAME(WEEKDAY, DateValue), 3) AS DayShortName,
    CASE 
        WHEN DATEPART(WEEKDAY, DateValue) IN (1, 7) THEN 1 
        ELSE 0 
    END AS IsWeekend,
    0 AS IsHoliday  -- You can update this with actual holidays if needed
FROM DateSeries
OPTION (MAXRECURSION 0);

PRINT 'DimDate populated: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows';

-- =====================================================
-- STEP 2: Populate DimSeam
-- =====================================================

-- Get seam data from source database
-- @SourceDbName is already declared at the top

DECLARE @SQL NVARCHAR(MAX);
SET @SQL = '
INSERT INTO DimSeam (
    SeamID, SystemID, SystemName, SeamLabel, SeamCode, Priority, Description, SystemHierarchy
)
SELECT 
    seam_id AS SeamID,
    system_id AS SystemID,
    system_name AS SystemName,
    seam_label AS SeamLabel,
    seam_code AS SeamCode,
    ISNULL(priority, 0) AS Priority,
    description AS Description,
    system_name + '' > '' + seam_label AS SystemHierarchy
FROM [' + @SourceDbName + '].[dbo].[seam_codes_lookup]';
EXEC sp_executesql @SQL;

PRINT 'DimSeam populated: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows';

-- =====================================================
-- STEP 3: Populate DimRock
-- =====================================================

SET @SQL = '
INSERT INTO DimRock (
    RockCode, Lithology, Detail, RockCategory
)
SELECT 
    rock_code AS RockCode,
    lithology AS Lithology,
    detail AS Detail,
    CASE 
        WHEN lithology LIKE ''%CLAY%'' OR lithology LIKE ''%CL%'' THEN ''Clay''
        WHEN lithology LIKE ''%SAND%'' OR lithology LIKE ''%SD%'' THEN ''Sandstone''
        WHEN lithology LIKE ''%COAL%'' OR lithology LIKE ''%CBCL%'' THEN ''Coal''
        WHEN lithology LIKE ''%SHALE%'' OR lithology LIKE ''%SH%'' THEN ''Shale''
        ELSE ''Other''
    END AS RockCategory
FROM [' + @SourceDbName + '].[dbo].[rock_types]';
EXEC sp_executesql @SQL;

PRINT 'DimRock populated: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows';

-- =====================================================
-- STEP 4: Populate DimHole
-- =====================================================

SET @SQL = '
INSERT INTO DimHole (
    HoleID, Easting, Northing, Elevation, Azimuth, Dip, FinalDepth, 
    Contractor, DrillingDateKey, DrillingYear, DrillingMonth, DrillingQuarter, Remarks
)
SELECT 
    c.hole_id AS HoleID,
    c.easting AS Easting,
    c.northing AS Northing,
    c.elevation AS Elevation,
    c.azimuth AS Azimuth,
    c.dip AS Dip,
    c.final_depth AS FinalDepth,
    c.contractor AS Contractor,
    CASE 
        WHEN c.drilling_date IS NOT NULL 
        THEN CAST(CONVERT(VARCHAR(8), c.drilling_date, 112) AS INT)
        ELSE NULL 
    END AS DrillingDateKey,
    YEAR(c.drilling_date) AS DrillingYear,
    MONTH(c.drilling_date) AS DrillingMonth,
    DATEPART(QUARTER, c.drilling_date) AS DrillingQuarter,
    c.remarks AS Remarks
FROM [' + @SourceDbName + '].[dbo].[collars] c';
EXEC sp_executesql @SQL;

PRINT 'DimHole populated: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows';

-- =====================================================
-- STEP 5: Populate FactCoalAnalysis
-- =====================================================

SET @SQL = '
INSERT INTO FactCoalAnalysis (
    HoleKey, SeamQualityKey, Seam73Key, AnalysisDateKey,
    SampleID, HoleID, SampleNo,
    DepthFrom, DepthTo,
    IM, TM, Ash, VM, FC, Sulphur,
    GrossCV, NetCV, SG, RD, HGI,
    LabName, Remarks
)
SELECT 
    h.HoleKey,
    sq.SeamKey AS SeamQualityKey,
    s73.SeamKey AS Seam73Key,
    CASE 
        WHEN sa.analysis_date IS NOT NULL 
        THEN CAST(CONVERT(VARCHAR(8), sa.analysis_date, 112) AS INT)
        ELSE h.DrillingDateKey  -- Fallback to drilling date if analysis date is null
    END AS AnalysisDateKey,
    sa.sample_id AS SampleID,
    sa.hole_id AS HoleID,
    sa.sample_no AS SampleNo,
    sa.depth_from AS DepthFrom,
    sa.depth_to AS DepthTo,
    sa.im AS IM,
    sa.tm AS TM,
    sa.ash AS Ash,
    sa.vm AS VM,
    sa.fc AS FC,
    sa.sulphur AS Sulphur,
    sa.gross_cv AS GrossCV,
    sa.net_cv AS NetCV,
    sa.sg AS SG,
    sa.rd AS RD,
    sa.hgi AS HGI,
    sa.lab_name AS LabName,
    sa.remarks AS Remarks
FROM [' + @SourceDbName + '].[dbo].[sample_analyses] sa
INNER JOIN DimHole h ON sa.hole_id = h.HoleID
LEFT JOIN DimSeam sq ON sa.seam_quality_id = sq.SeamID
LEFT JOIN DimSeam s73 ON sa.seam_73_id = s73.SeamID';
EXEC sp_executesql @SQL;

PRINT 'FactCoalAnalysis populated: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows';

-- =====================================================
-- STEP 6: Populate FactLithology
-- =====================================================

SET @SQL = '
INSERT INTO FactLithology (
    HoleKey, RockKey, LogDateKey,
    LogID, HoleID,
    DepthFrom, DepthTo,
    Description
)
SELECT 
    h.HoleKey,
    r.RockKey,
    h.DrillingDateKey AS LogDateKey,  -- Use drilling date as default
    ll.log_id AS LogID,
    ll.hole_id AS HoleID,
    ll.depth_from AS DepthFrom,
    ll.depth_to AS DepthTo,
    ll.description AS Description
FROM [' + @SourceDbName + '].[dbo].[lithology_logs] ll
INNER JOIN DimHole h ON ll.hole_id = h.HoleID
LEFT JOIN DimRock r ON ll.rock_code = r.RockCode';
EXEC sp_executesql @SQL;

PRINT 'FactLithology populated: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows';

-- =====================================================
-- DATA VALIDATION QUERIES
-- =====================================================

PRINT '=====================================================';
PRINT 'Data Population Summary';
PRINT '=====================================================';

SELECT 'DimDate' AS TableName, COUNT(*) AS RowCount FROM DimDate
UNION ALL
SELECT 'DimSeam', COUNT(*) FROM DimSeam
UNION ALL
SELECT 'DimRock', COUNT(*) FROM DimRock
UNION ALL
SELECT 'DimHole', COUNT(*) FROM DimHole
UNION ALL
SELECT 'FactCoalAnalysis', COUNT(*) FROM FactCoalAnalysis
UNION ALL
SELECT 'FactLithology', COUNT(*) FROM FactLithology;

PRINT '';
PRINT '=====================================================';
PRINT 'Data Quality Checks';
PRINT '=====================================================';

-- Check for orphaned records
SELECT 'FactCoalAnalysis with invalid HoleKey' AS CheckName, COUNT(*) AS IssueCount
FROM FactCoalAnalysis f
LEFT JOIN DimHole h ON f.HoleKey = h.HoleKey
WHERE h.HoleKey IS NULL

UNION ALL

SELECT 'FactCoalAnalysis with invalid SeamQualityKey', COUNT(*)
FROM FactCoalAnalysis f
LEFT JOIN DimSeam s ON f.SeamQualityKey = s.SeamKey
WHERE f.SeamQualityKey IS NOT NULL AND s.SeamKey IS NULL

UNION ALL

SELECT 'FactLithology with invalid HoleKey', COUNT(*)
FROM FactLithology f
LEFT JOIN DimHole h ON f.HoleKey = h.HoleKey
WHERE h.HoleKey IS NULL;

PRINT '';
PRINT '=====================================================';
PRINT 'HongsaDW Data Population Completed!';
PRINT 'Ready for SSAS Tabular Data Model Import';
PRINT '=====================================================';
GO
