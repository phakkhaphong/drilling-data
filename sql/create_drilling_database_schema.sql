-- =====================================================
-- Coal Drilling Database Schema
-- Following Best Practices for Mining/Drilling Data Management
-- =====================================================
-- Based on: DH70.xlsx lookup data
-- Final Version - Use this schema for the normalized database
-- =====================================================

-- Drop existing tables if they exist (in correct order due to foreign keys)
DROP TABLE IF EXISTS sample_analyses;
DROP TABLE IF EXISTS lithology_logs;
DROP TABLE IF EXISTS collars;
DROP TABLE IF EXISTS seam_codes_lookup;
DROP TABLE IF EXISTS rock_codes_lookup;
DROP TABLE IF EXISTS rock_types;

-- =====================================================
-- 1. LOOKUP TABLES
-- =====================================================

-- Seam Codes Lookup Table
-- Contains all seam codes from different classification systems
CREATE TABLE seam_codes_lookup (
    seam_id INTEGER PRIMARY KEY,
    system_id VARCHAR(20) NOT NULL,
    system_name VARCHAR(50) NOT NULL,
    seam_label VARCHAR(50) NOT NULL,
    seam_code INTEGER NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(system_id, seam_label, seam_code)
);

-- Rock Codes Lookup Table
-- Contains standard rock/lithology codes
CREATE TABLE rock_codes_lookup (
    rock_id INTEGER PRIMARY KEY,
    rock_code INTEGER UNIQUE NOT NULL,
    lithology VARCHAR(20) NOT NULL,
    detail VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Rock Types Lookup Table
CREATE TABLE rock_types (
    rock_type_id INTEGER PRIMARY KEY,
    rock_code INTEGER NOT NULL,
    rock_type VARCHAR(50) NOT NULL,
    FOREIGN KEY (rock_code) REFERENCES rock_codes_lookup(rock_code)
);

-- =====================================================
-- 2. CORE DRILLING TABLES
-- =====================================================

-- Collars Table
-- Contains drilling hole collar information (location, elevation, etc.)
CREATE TABLE collars (
    collar_id INTEGER PRIMARY KEY,
    hole_id VARCHAR(50) UNIQUE NOT NULL,
    easting REAL,
    northing REAL,
    elevation REAL,
    azimuth REAL,
    dip REAL,
    final_depth REAL,
    drilling_date DATE,
    contractor VARCHAR(100),
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Lithology Logs Table
-- Contains detailed lithology information for each depth interval
CREATE TABLE lithology_logs (
    log_id INTEGER PRIMARY KEY,
    hole_id VARCHAR(50) NOT NULL,
    depth_from REAL NOT NULL,
    depth_to REAL NOT NULL,
    rock_code INTEGER,
    description TEXT,
    FOREIGN KEY (hole_id) REFERENCES collars(hole_id),
    FOREIGN KEY (rock_code) REFERENCES rock_codes_lookup(rock_code),
    CHECK (depth_to > depth_from)
);

-- Sample Analyses Table
-- Contains laboratory analysis results for coal samples
CREATE TABLE sample_analyses (
    sample_id INTEGER PRIMARY KEY,
    hole_id VARCHAR(50) NOT NULL,
    depth_from REAL NOT NULL,
    depth_to REAL NOT NULL,
    sample_no VARCHAR(50) NOT NULL,
    
    -- Proximate Analysis
    im REAL,                    -- Inherent Moisture (%)
    tm REAL,                    -- Total Moisture (%)
    ash REAL,                   -- Ash Content (%)
    vm REAL,                   -- Volatile Matter (%)
    fc REAL,                   -- Fixed Carbon (%)
    
    -- Ultimate Analysis
    sulphur REAL,              -- Sulphur Content (%)
    
    -- Calorific Value
    gross_cv REAL,             -- Gross Calorific Value (kcal/kg)
    net_cv REAL,               -- Net Calorific Value (kcal/kg)
    
    -- Physical Properties
    sg REAL,                   -- Specific Gravity
    rd REAL,                   -- Relative Density
    hgi REAL,                 -- Hardgrove Grindability Index
    
    -- Seam Classification (Foreign Keys)
    seam_code_quality_original REAL,  -- Original quality seam code (for reference)
    seam_quality_id INTEGER,         -- Foreign key to seam_codes_lookup (Quality system)
    seam_73_id INTEGER,              -- Foreign key to seam_codes_lookup (73 system)
    
    -- Metadata
    analysis_date DATE,
    lab_name VARCHAR(100),
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    FOREIGN KEY (hole_id) REFERENCES collars(hole_id),
    FOREIGN KEY (seam_quality_id) REFERENCES seam_codes_lookup(seam_id),
    FOREIGN KEY (seam_73_id) REFERENCES seam_codes_lookup(seam_id),
    
    -- Data validation constraints
    CHECK (depth_to > depth_from),
    CHECK (ash >= 0 AND ash <= 100),
    CHECK (vm >= 0 AND vm <= 100),
    CHECK (fc >= 0 AND fc <= 100),
    CHECK (im >= 0 AND im <= 100),
    CHECK (tm >= 0 AND tm <= 100)
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
CREATE INDEX idx_rock_codes_code ON rock_codes_lookup(rock_code);
CREATE INDEX idx_rock_codes_lithology ON rock_codes_lookup(lithology);

-- =====================================================
-- 4. VIEWS FOR EASIER QUERYING
-- =====================================================

-- View: Complete Sample Analyses with Seam Information
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

-- View: Sample Analyses with Collar Information
CREATE VIEW sample_analyses_with_location AS
SELECT 
    sa.*,
    c.easting,
    c.northing,
    c.elevation,
    c.final_depth as hole_final_depth
FROM sample_analyses sa
LEFT JOIN collars c ON sa.hole_id = c.hole_id;

-- View: Complete Hole Information
CREATE VIEW holes_complete AS
SELECT 
    c.*,
    COUNT(DISTINCT sa.sample_id) as sample_count,
    COUNT(DISTINCT ll.log_id) as log_count,
    MIN(sa.depth_from) as min_sample_depth,
    MAX(sa.depth_to) as max_sample_depth
FROM collars c
LEFT JOIN sample_analyses sa ON c.hole_id = sa.hole_id
LEFT JOIN lithology_logs ll ON c.hole_id = ll.hole_id
GROUP BY c.collar_id;

-- View: Seam Summary by Hole
CREATE VIEW seam_summary_by_hole AS
SELECT 
    sa.hole_id,
    sqc.seam_label as quality_seam_label,
    COUNT(*) as sample_count,
    MIN(sa.depth_from) as seam_top_depth,
    MAX(sa.depth_to) as seam_bottom_depth,
    AVG(sa.ash) as avg_ash,
    AVG(sa.vm) as avg_vm,
    AVG(sa.gross_cv) as avg_gross_cv,
    AVG(sa.net_cv) as avg_net_cv
FROM sample_analyses sa
LEFT JOIN seam_codes_lookup sqc ON sa.seam_quality_id = sqc.seam_id
WHERE sa.seam_quality_id IS NOT NULL
GROUP BY sa.hole_id, sqc.seam_label;

-- =====================================================
-- 5. DOCUMENTATION AND COMMENTS
-- =====================================================

COMMENT ON TABLE collars IS 'Drilling hole collar locations and basic information';
COMMENT ON TABLE lithology_logs IS 'Detailed lithology logs for each depth interval';
COMMENT ON TABLE sample_analyses IS 'Laboratory analysis results for coal samples with normalized seam codes';
COMMENT ON TABLE seam_codes_lookup IS 'Complete lookup table for all seam codes from different classification systems (30, 46, 57, 58, Quality, 73)';
COMMENT ON TABLE rock_codes_lookup IS 'Complete lookup table for all rock/lithology codes';

COMMENT ON COLUMN sample_analyses.seam_quality_id IS 'Foreign key to seam_codes_lookup (Quality classification system)';
COMMENT ON COLUMN sample_analyses.seam_73_id IS 'Foreign key to seam_codes_lookup (73 classification system)';
COMMENT ON COLUMN sample_analyses.depth_from IS 'Starting depth of sample interval (meters)';
COMMENT ON COLUMN sample_analyses.depth_to IS 'Ending depth of sample interval (meters)';
COMMENT ON COLUMN sample_analyses.ash IS 'Ash content percentage (dry basis)';
COMMENT ON COLUMN sample_analyses.vm IS 'Volatile matter percentage (dry ash-free basis)';
COMMENT ON COLUMN sample_analyses.fc IS 'Fixed carbon percentage (dry ash-free basis)';
COMMENT ON COLUMN sample_analyses.gross_cv IS 'Gross Calorific Value in kcal/kg';
COMMENT ON COLUMN sample_analyses.net_cv IS 'Net Calorific Value in kcal/kg';
