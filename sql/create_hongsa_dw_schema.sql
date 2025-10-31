-- =====================================================
-- HongsaDW - Dimensional Model (Star Schema)
-- สำหรับ SQL Server Analysis Services Tabular Data Model
-- =====================================================
-- Database: HongsaDW
-- Schema Type: Star Schema (Dimensional Model)
-- =====================================================

USE master;
GO

-- Create HongsaDW database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'HongsaDW')
BEGIN
    CREATE DATABASE HongsaDW;
END
GO

USE HongsaDW;
GO

-- =====================================================
-- DROP EXISTING TABLES (in order of dependencies)
-- =====================================================

IF OBJECT_ID('FactCoalAnalysis', 'U') IS NOT NULL DROP TABLE FactCoalAnalysis;
IF OBJECT_ID('FactLithology', 'U') IS NOT NULL DROP TABLE FactLithology;
IF OBJECT_ID('DimHole', 'U') IS NOT NULL DROP TABLE DimHole;
IF OBJECT_ID('DimSeam', 'U') IS NOT NULL DROP TABLE DimSeam;
IF OBJECT_ID('DimRock', 'U') IS NOT NULL DROP TABLE DimRock;
IF OBJECT_ID('DimDate', 'U') IS NOT NULL DROP TABLE DimDate;
GO

-- =====================================================
-- DIMENSION TABLES
-- =====================================================

-- DimHole: Dimension table for drilling holes
CREATE TABLE DimHole (
    HoleKey INT IDENTITY(1,1) PRIMARY KEY,
    HoleID NVARCHAR(50) NOT NULL,
    
    -- Location attributes
    Easting FLOAT NULL,
    Northing FLOAT NULL,
    Elevation FLOAT NULL,
    
    -- Drilling attributes
    Azimuth FLOAT NULL,
    Dip FLOAT NULL,
    FinalDepth FLOAT NULL,
    Contractor NVARCHAR(100) NULL,
    
    -- Date attributes (will link to DimDate)
    DrillingDateKey INT NULL,
    DrillingYear INT NULL,
    DrillingMonth INT NULL,
    DrillingQuarter INT NULL,
    
    -- Additional attributes
    Remarks NVARCHAR(MAX) NULL,
    
    -- Audit fields
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE(),
    
    CONSTRAINT UQ_DimHole_HoleID UNIQUE (HoleID)
);

-- DimSeam: Dimension table for seam codes
CREATE TABLE DimSeam (
    SeamKey INT IDENTITY(1,1) PRIMARY KEY,
    SeamID INT NOT NULL,  -- Original seam_id from relational model
    
    -- Seam attributes
    SystemID NVARCHAR(20) NOT NULL,
    SystemName NVARCHAR(50) NOT NULL,
    SeamLabel NVARCHAR(50) NOT NULL,
    SeamCode INT NOT NULL,
    Priority INT NOT NULL DEFAULT 0,
    Description NVARCHAR(255) NULL,
    
    -- Hierarchy attributes for SSAS
    SystemHierarchy NVARCHAR(100) NULL,  -- e.g., "Quality > H3c"
    
    -- Audit fields
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    
    CONSTRAINT UQ_DimSeam_SeamID UNIQUE (SeamID)
);

-- DimRock: Dimension table for rock/lithology types
CREATE TABLE DimRock (
    RockKey INT IDENTITY(1,1) PRIMARY KEY,
    RockCode INT NOT NULL,
    
    -- Rock attributes
    Lithology NVARCHAR(20) NOT NULL,
    Detail NVARCHAR(100) NOT NULL,
    
    -- Hierarchy attributes for SSAS
    RockCategory NVARCHAR(50) NULL,  -- Could be derived from lithology
    
    -- Audit fields
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    
    CONSTRAINT UQ_DimRock_RockCode UNIQUE (RockCode)
);

-- DimDate: Time dimension table
CREATE TABLE DimDate (
    DateKey INT PRIMARY KEY,  -- Format: YYYYMMDD (e.g., 20250101)
    
    -- Date attributes
    FullDate DATE NOT NULL,
    Day INT NOT NULL,
    Month INT NOT NULL,
    MonthName NVARCHAR(20) NOT NULL,
    MonthShortName NVARCHAR(10) NOT NULL,
    Quarter INT NOT NULL,
    QuarterName NVARCHAR(10) NOT NULL,  -- e.g., "Q1 2025"
    Year INT NOT NULL,
    YearQuarter INT NOT NULL,  -- e.g., 20251
    
    -- Week attributes
    WeekOfYear INT NOT NULL,
    DayOfWeek INT NOT NULL,  -- 1=Monday, 7=Sunday
    DayName NVARCHAR(20) NOT NULL,
    DayShortName NVARCHAR(10) NOT NULL,
    
    -- Fiscal attributes (if needed)
    IsWeekend BIT NOT NULL DEFAULT 0,
    IsHoliday BIT NOT NULL DEFAULT 0,
    
    -- Audit fields
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    
    CONSTRAINT UQ_DimDate_FullDate UNIQUE (FullDate)
);

-- =====================================================
-- FACT TABLES
-- =====================================================

-- FactCoalAnalysis: Main fact table for coal sample analyses
CREATE TABLE FactCoalAnalysis (
    -- Surrogate Key
    FactCoalAnalysisKey BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Dimension Keys
    HoleKey INT NOT NULL,
    SeamQualityKey INT NULL,      -- Primary seam (Quality system)
    Seam73Key INT NULL,            -- Secondary seam (System 73)
    AnalysisDateKey INT NULL,
    
    -- Grain attributes (identifiers)
    SampleID INT NOT NULL,
    HoleID NVARCHAR(50) NOT NULL,
    SampleNo NVARCHAR(50) NOT NULL,
    
    -- Depth attributes
    DepthFrom FLOAT NOT NULL,
    DepthTo FLOAT NOT NULL,
    DepthThickness AS (DepthTo - DepthFrom) PERSISTED,  -- Calculated measure
    
    -- MEASURES - Proximate Analysis
    IM FLOAT NULL,          -- Inherent Moisture (%)
    TM FLOAT NULL,          -- Total Moisture (%)
    Ash FLOAT NULL,         -- Ash Content (%)
    VM FLOAT NULL,          -- Volatile Matter (%)
    FC FLOAT NULL,          -- Fixed Carbon (%)
    
    -- MEASURES - Ultimate Analysis
    Sulphur FLOAT NULL,     -- Sulphur Content (%)
    
    -- MEASURES - Calorific Value
    GrossCV FLOAT NULL,     -- Gross Calorific Value (kcal/kg)
    NetCV FLOAT NULL,       -- Net Calorific Value (kcal/kg)
    
    -- MEASURES - Physical Properties
    SG FLOAT NULL,          -- Specific Gravity
    RD FLOAT NULL,          -- Relative Density
    HGI FLOAT NULL,         -- Hardgrove Grindability Index
    
    -- Additional attributes
    LabName NVARCHAR(100) NULL,
    Remarks NVARCHAR(MAX) NULL,
    
    -- Audit fields
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE(),
    
    -- Foreign key constraints
    CONSTRAINT FK_FactCoalAnalysis_HoleKey FOREIGN KEY (HoleKey) REFERENCES DimHole(HoleKey),
    CONSTRAINT FK_FactCoalAnalysis_SeamQualityKey FOREIGN KEY (SeamQualityKey) REFERENCES DimSeam(SeamKey),
    CONSTRAINT FK_FactCoalAnalysis_Seam73Key FOREIGN KEY (Seam73Key) REFERENCES DimSeam(SeamKey),
    CONSTRAINT FK_FactCoalAnalysis_AnalysisDateKey FOREIGN KEY (AnalysisDateKey) REFERENCES DimDate(DateKey),
    
    -- Data validation constraints
    CONSTRAINT CK_FactCoalAnalysis_Depth CHECK (DepthTo > DepthFrom),
    CONSTRAINT CK_FactCoalAnalysis_Ash CHECK (Ash IS NULL OR (Ash >= 0 AND Ash <= 100)),
    CONSTRAINT CK_FactCoalAnalysis_VM CHECK (VM IS NULL OR (VM >= 0 AND VM <= 100)),
    CONSTRAINT CK_FactCoalAnalysis_FC CHECK (FC IS NULL OR (FC >= 0 AND FC <= 100)),
    CONSTRAINT CK_FactCoalAnalysis_IM CHECK (IM IS NULL OR (IM >= 0 AND IM <= 100)),
    CONSTRAINT CK_FactCoalAnalysis_TM CHECK (TM IS NULL OR (TM >= 0 AND TM <= 100))
);

-- FactLithology: Fact table for lithology logs
CREATE TABLE FactLithology (
    -- Surrogate Key
    FactLithologyKey BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Dimension Keys
    HoleKey INT NOT NULL,
    RockKey INT NULL,
    LogDateKey INT NULL,  -- If we have date for log, otherwise use drilling date
    
    -- Grain attributes (identifiers)
    LogID INT NOT NULL,
    HoleID NVARCHAR(50) NOT NULL,
    
    -- Depth attributes
    DepthFrom FLOAT NOT NULL,
    DepthTo FLOAT NOT NULL,
    Thickness AS (DepthTo - DepthFrom) PERSISTED,  -- Calculated measure
    
    -- Additional attributes
    Description NVARCHAR(MAX) NULL,
    
    -- Audit fields
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    
    -- Foreign key constraints
    CONSTRAINT FK_FactLithology_HoleKey FOREIGN KEY (HoleKey) REFERENCES DimHole(HoleKey),
    CONSTRAINT FK_FactLithology_RockKey FOREIGN KEY (RockKey) REFERENCES DimRock(RockKey),
    CONSTRAINT FK_FactLithology_LogDateKey FOREIGN KEY (LogDateKey) REFERENCES DimDate(DateKey),
    
    -- Data validation constraints
    CONSTRAINT CK_FactLithology_Depth CHECK (DepthTo > DepthFrom)
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Dimension indexes
CREATE INDEX idx_DimHole_HoleID ON DimHole(HoleID);
CREATE INDEX idx_DimHole_DrillingDateKey ON DimHole(DrillingDateKey);
CREATE INDEX idx_DimHole_Location ON DimHole(Easting, Northing);

CREATE INDEX idx_DimSeam_SeamID ON DimSeam(SeamID);
CREATE INDEX idx_DimSeam_SystemID ON DimSeam(SystemID);
CREATE INDEX idx_DimSeam_SeamCode ON DimSeam(SeamCode);
CREATE INDEX idx_DimSeam_SystemHierarchy ON DimSeam(SystemHierarchy);

CREATE INDEX idx_DimRock_RockCode ON DimRock(RockCode);
CREATE INDEX idx_DimRock_Lithology ON DimRock(Lithology);

CREATE INDEX idx_DimDate_FullDate ON DimDate(FullDate);
CREATE INDEX idx_DimDate_YearMonth ON DimDate(Year, Month);
CREATE INDEX idx_DimDate_YearQuarter ON DimDate(YearQuarter);

-- Fact table indexes
CREATE INDEX idx_FactCoalAnalysis_HoleKey ON FactCoalAnalysis(HoleKey);
CREATE INDEX idx_FactCoalAnalysis_SeamQualityKey ON FactCoalAnalysis(SeamQualityKey);
CREATE INDEX idx_FactCoalAnalysis_Seam73Key ON FactCoalAnalysis(Seam73Key);
CREATE INDEX idx_FactCoalAnalysis_AnalysisDateKey ON FactCoalAnalysis(AnalysisDateKey);
CREATE INDEX idx_FactCoalAnalysis_HoleID_SampleNo ON FactCoalAnalysis(HoleID, SampleNo);
CREATE INDEX idx_FactCoalAnalysis_Depth ON FactCoalAnalysis(HoleKey, DepthFrom, DepthTo);

CREATE INDEX idx_FactLithology_HoleKey ON FactLithology(HoleKey);
CREATE INDEX idx_FactLithology_RockKey ON FactLithology(RockKey);
CREATE INDEX idx_FactLithology_LogDateKey ON FactLithology(LogDateKey);
CREATE INDEX idx_FactLithology_Depth ON FactLithology(HoleKey, DepthFrom, DepthTo);

-- =====================================================
-- VIEWS FOR SSAS TABULAR MODEL
-- =====================================================

-- View: Coal Analysis Cube (for SSAS Tabular)
GO
CREATE VIEW vwCoalAnalysisCube AS
SELECT 
    f.FactCoalAnalysisKey,
    -- Dimension Keys
    f.HoleKey,
    f.SeamQualityKey,
    f.Seam73Key,
    f.AnalysisDateKey,
    -- Dimension attributes (denormalized for SSAS)
    h.HoleID,
    h.Easting,
    h.Northing,
    h.Elevation,
    h.FinalDepth as HoleDepth,
    h.Contractor,
    sq.SystemName as QualitySystemName,
    sq.SeamLabel as QualitySeamLabel,
    s73.SystemName as Seam73SystemName,
    s73.SeamLabel as Seam73SeamLabel,
    d.FullDate as AnalysisDate,
    d.Year as AnalysisYear,
    d.Quarter as AnalysisQuarter,
    d.MonthName as AnalysisMonth,
    -- Measures
    f.DepthThickness,
    f.IM,
    f.TM,
    f.Ash,
    f.VM,
    f.FC,
    f.Sulphur,
    f.GrossCV,
    f.NetCV,
    f.SG,
    f.RD,
    f.HGI
FROM FactCoalAnalysis f
INNER JOIN DimHole h ON f.HoleKey = h.HoleKey
LEFT JOIN DimSeam sq ON f.SeamQualityKey = sq.SeamKey
LEFT JOIN DimSeam s73 ON f.Seam73Key = s73.SeamKey
LEFT JOIN DimDate d ON f.AnalysisDateKey = d.DateKey;

-- View: Lithology Cube (for SSAS Tabular)
GO
CREATE VIEW vwLithologyCube AS
SELECT 
    f.FactLithologyKey,
    -- Dimension Keys
    f.HoleKey,
    f.RockKey,
    f.LogDateKey,
    -- Dimension attributes (denormalized for SSAS)
    h.HoleID,
    h.Easting,
    h.Northing,
    h.Elevation,
    r.Lithology,
    r.Detail as RockDetail,
    d.FullDate as LogDate,
    d.Year as LogYear,
    d.Quarter as LogQuarter,
    -- Measures
    f.Thickness,
    f.DepthFrom,
    f.DepthTo
FROM FactLithology f
INNER JOIN DimHole h ON f.HoleKey = h.HoleKey
LEFT JOIN DimRock r ON f.RockKey = r.RockKey
LEFT JOIN DimDate d ON f.LogDateKey = d.DateKey;

GO

PRINT '=====================================================';
PRINT 'HongsaDW Star Schema Created Successfully!';
PRINT 'Database: HongsaDW';
PRINT 'Schema Type: Star Schema (Dimensional Model)';
PRINT 'Ready for SSAS Tabular Data Model';
PRINT '=====================================================';
GO

