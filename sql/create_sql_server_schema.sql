-- =====================================================
-- Coal Drilling Database Schema for Microsoft SQL Server
-- Complete System with All Data from DH70.xlsx
-- =====================================================
-- Created: 2025-10-30 08:50:00
-- Updated: Based on actual data from DH70.xlsx
-- =====================================================

-- Drop existing tables if they exist (in correct order due to foreign keys)
IF OBJECT_ID('sample_analyses', 'U') IS NOT NULL DROP TABLE sample_analyses;
IF OBJECT_ID('lithology_logs', 'U') IS NOT NULL DROP TABLE lithology_logs;
IF OBJECT_ID('collars', 'U') IS NOT NULL DROP TABLE collars;
IF OBJECT_ID('seam_codes_lookup', 'U') IS NOT NULL DROP TABLE seam_codes_lookup;
IF OBJECT_ID('rock_types', 'U') IS NOT NULL DROP TABLE rock_types;

-- =====================================================
-- 1. LOOKUP TABLES
-- =====================================================

-- Seam Codes Lookup Table (Complete system from DH70.xlsx)
CREATE TABLE seam_codes_lookup (
    seam_id INT IDENTITY(1,1) PRIMARY KEY,
    system_id NVARCHAR(20) NOT NULL,
    system_name NVARCHAR(50) NOT NULL,
    seam_label NVARCHAR(50) NOT NULL,
    seam_code INT NOT NULL,
    priority INT NOT NULL DEFAULT 0,  -- Quality=1, 73=2, 30=6, etc.
    description NVARCHAR(255) NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT UQ_seam_codes_system_label_code UNIQUE(system_id, seam_label, seam_code)
);

-- Rock Types Lookup Table (Combined rock codes and types)
CREATE TABLE rock_types (
    rock_code INT PRIMARY KEY,
    lithology NVARCHAR(20) NOT NULL,
    detail NVARCHAR(100) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE()
);

-- =====================================================
-- 2. CORE DRILLING TABLES
-- =====================================================

-- Collars Table
CREATE TABLE collars (
    collar_id INT IDENTITY(1,1) PRIMARY KEY,
    hole_id NVARCHAR(50) UNIQUE NOT NULL,
    easting FLOAT NULL,
    northing FLOAT NULL,
    elevation FLOAT NULL,
    azimuth FLOAT NULL,
    dip FLOAT NULL,
    final_depth FLOAT NULL,
    drilling_date DATE NULL,
    contractor NVARCHAR(100) NULL,
    remarks NVARCHAR(MAX) NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);

-- Lithology Logs Table
CREATE TABLE lithology_logs (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    hole_id NVARCHAR(50) NOT NULL,
    depth_from FLOAT NOT NULL,
    depth_to FLOAT NOT NULL,
    rock_code INT NULL,
    description NVARCHAR(MAX) NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_lithology_logs_hole_id FOREIGN KEY (hole_id) REFERENCES collars(hole_id),
    CONSTRAINT FK_lithology_logs_rock_code FOREIGN KEY (rock_code) REFERENCES rock_types(rock_code),
    CONSTRAINT CK_lithology_logs_depth CHECK (depth_to > depth_from)
);

-- Sample Analyses Table (Complete data from DH70.xlsx)
CREATE TABLE sample_analyses (
    sample_id INT IDENTITY(1,1) PRIMARY KEY,
    hole_id NVARCHAR(50) NOT NULL,
    depth_from FLOAT NOT NULL,
    depth_to FLOAT NOT NULL,
    sample_no NVARCHAR(50) NOT NULL,
    
    -- Proximate Analysis
    im FLOAT NULL,                    -- Inherent Moisture (%)
    tm FLOAT NULL,                    -- Total Moisture (%)
    ash FLOAT NULL,                   -- Ash Content (%)
    vm FLOAT NULL,                    -- Volatile Matter (%)
    fc FLOAT NULL,                    -- Fixed Carbon (%)
    
    -- Ultimate Analysis
    sulphur FLOAT NULL,               -- Sulphur Content (%)
    
    -- Calorific Value
    gross_cv FLOAT NULL,              -- Gross Calorific Value (kcal/kg)
    net_cv FLOAT NULL,                -- Net Calorific Value (kcal/kg)
    
    -- Physical Properties
    sg FLOAT NULL,                    -- Specific Gravity
    rd FLOAT NULL,                    -- Relative Density
    hgi FLOAT NULL,                   -- Hardgrove Grindability Index
    
    -- Seam Classifications (Foreign Keys)
    seam_quality_id INT NULL,         -- Quality system (priority 1)
    seam_73_id INT NULL,              -- System 73 (priority 2)
    
    -- Original seam codes for reference
    seam_code_quality_original FLOAT NULL,
    
    -- Metadata
    analysis_date DATE NULL,
    lab_name NVARCHAR(100) NULL,
    remarks NVARCHAR(MAX) NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    
    -- Foreign key constraints
    CONSTRAINT FK_sample_analyses_hole_id FOREIGN KEY (hole_id) REFERENCES collars(hole_id),
    CONSTRAINT FK_sample_analyses_seam_quality FOREIGN KEY (seam_quality_id) REFERENCES seam_codes_lookup(seam_id),
    CONSTRAINT FK_sample_analyses_seam_73 FOREIGN KEY (seam_73_id) REFERENCES seam_codes_lookup(seam_id),
    
    -- Data validation constraints
    CONSTRAINT CK_sample_analyses_depth CHECK (depth_to > depth_from),
    CONSTRAINT CK_sample_analyses_ash CHECK (ash >= 0 AND ash <= 100),
    CONSTRAINT CK_sample_analyses_vm CHECK (vm >= 0 AND vm <= 100),
    CONSTRAINT CK_sample_analyses_fc CHECK (fc >= 0 AND fc <= 100),
    CONSTRAINT CK_sample_analyses_im CHECK (im >= 0 AND im <= 100),
    CONSTRAINT CK_sample_analyses_tm CHECK (tm >= 0 AND tm <= 100)
);

-- =====================================================
-- 3. INDEXES FOR PERFORMANCE
-- =====================================================

-- Collars indexes
CREATE INDEX idx_collars_hole_id ON collars(hole_id);
CREATE INDEX idx_collars_location ON collars(easting, northing);

-- Lithology logs indexes
CREATE INDEX idx_lithology_hole_id ON lithology_logs(hole_id);
CREATE INDEX idx_lithology_depth ON lithology_logs(hole_id, depth_from, depth_to);
CREATE INDEX idx_lithology_rock_code ON lithology_logs(rock_code);

-- Sample analyses indexes
CREATE INDEX idx_sample_analyses_hole_id ON sample_analyses(hole_id);
CREATE INDEX idx_sample_analyses_depth ON sample_analyses(hole_id, depth_from, depth_to);
CREATE INDEX idx_sample_analyses_seam_quality ON sample_analyses(seam_quality_id);
CREATE INDEX idx_sample_analyses_seam_73 ON sample_analyses(seam_73_id);
CREATE INDEX idx_sample_analyses_sample_no ON sample_analyses(hole_id, sample_no);

-- Lookup tables indexes
CREATE INDEX idx_seam_codes_system ON seam_codes_lookup(system_id);
CREATE INDEX idx_seam_codes_code ON seam_codes_lookup(seam_code);
CREATE INDEX idx_seam_codes_label ON seam_codes_lookup(seam_label);
CREATE INDEX idx_seam_codes_priority ON seam_codes_lookup(priority);
CREATE INDEX idx_rock_types_code ON rock_types(rock_code);
CREATE INDEX idx_rock_types_lithology ON rock_types(lithology);

-- =====================================================
-- 4. VIEWS FOR ANALYSIS
-- =====================================================

-- View: Complete Sample Analyses with Seam Information
GO
CREATE VIEW sample_analyses_complete AS
SELECT 
    sa.*,
    sqc.seam_label as quality_seam_label,
    sqc.system_name as quality_system_name,
    s73c.seam_label as seam_73_label,
    s73c.system_name as seam_73_system_name
FROM sample_analyses sa
LEFT JOIN seam_codes_lookup sqc ON sa.seam_quality_id = sqc.seam_id
LEFT JOIN seam_codes_lookup s73c ON sa.seam_73_id = s73c.seam_id;

-- View: Seam Summary by System
GO
CREATE VIEW seam_summary_by_system AS
SELECT 
    scl.system_id,
    scl.system_name,
    COUNT(*) as total_seam_codes,
    MIN(scl.seam_code) as min_code,
    MAX(scl.seam_code) as max_code,
    COUNT(DISTINCT sa.sample_id) as samples_with_seam_codes
FROM seam_codes_lookup scl
LEFT JOIN sample_analyses sa ON (
    sa.seam_quality_id = scl.seam_id OR 
    sa.seam_73_id = scl.seam_id
)
GROUP BY scl.system_id, scl.system_name, scl.priority
;

-- View: Sample Analyses with Location and Seam Information
GO
CREATE VIEW sample_analyses_with_location AS
SELECT 
    sa.*,
    c.easting,
    c.northing,
    c.elevation,
    c.final_depth as hole_final_depth,
    sqc.seam_label as primary_seam_label,
    sqc.system_name as primary_seam_system
FROM sample_analyses sa
LEFT JOIN collars c ON sa.hole_id = c.hole_id
LEFT JOIN seam_codes_lookup sqc ON sa.seam_quality_id = sqc.seam_id;
