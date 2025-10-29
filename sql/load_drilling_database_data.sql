-- =====================================================
-- Load Coal Drilling Database Data
-- Following Best Practices for Mining Data Management
-- =====================================================

-- Load seam codes lookup
.mode csv
.import data/drilling_database/seam_codes_lookup.csv seam_codes_temp

INSERT INTO seam_codes_lookup (seam_id, system_id, system_name, seam_label, seam_code)
SELECT seam_id, system_id, system_name, seam_label, seam_code
FROM seam_codes_temp
WHERE seam_id != 'seam_id';

DROP TABLE seam_codes_temp;

-- Load rock codes lookup
.import data/drilling_database/rock_codes_lookup.csv rock_codes_temp

INSERT INTO rock_codes_lookup (rock_id, rock_code, lithology, detail)
SELECT rock_id, rock_code, lithology, detail
FROM rock_codes_temp
WHERE rock_id != 'rock_id';

DROP TABLE rock_codes_temp;

-- Load rock types
.import data/drilling_database/rock_types.csv rock_types_temp

INSERT INTO rock_types (rock_type_id, rock_code, rock_type)
SELECT rock_type_id, rock_code, rock_type
FROM rock_types_temp
WHERE rock_type_id != 'rock_type_id';

DROP TABLE rock_types_temp;

-- Load collars
.import data/drilling_database/collars.csv collars_temp

INSERT INTO collars (
    collar_id, hole_id, easting, northing, elevation, 
    azimuth, dip, final_depth, drilling_date, contractor, remarks
)
SELECT 
    collar_id, hole_id, easting, northing, elevation,
    azimuth, dip, final_depth, drilling_date, contractor, remarks
FROM collars_temp
WHERE collar_id != 'collar_id';

DROP TABLE collars_temp;

-- Load lithology logs
.import data/drilling_database/lithology_logs.csv lithology_temp

INSERT INTO lithology_logs (log_id, hole_id, depth_from, depth_to, rock_code, description)
SELECT log_id, hole_id, depth_from, depth_to, rock_code, description
FROM lithology_temp
WHERE log_id != 'log_id';

DROP TABLE lithology_temp;

-- Load normalized sample analyses
.import data/drilling_database/sample_analyses.csv sample_analyses_temp

INSERT INTO sample_analyses (
    sample_id, hole_id, depth_from, depth_to, sample_no,
    im, tm, ash, vm, fc, sulphur, gross_cv, net_cv, sg, rd, hgi,
    seam_code_quality_original, seam_quality_id, seam_73_id,
    analysis_date, lab_name, remarks
)
SELECT 
    sample_id, hole_id, depth_from, depth_to, sample_no,
    im, tm, ash, vm, fc, sulphur, gross_cv, net_cv, sg, rd, hgi,
    seam_code_quality_original,
    CASE WHEN seam_quality_id = '' THEN NULL ELSE seam_quality_id END,
    CASE WHEN seam_73_id = '' THEN NULL ELSE seam_73_id END,
    NULL, NULL, NULL
FROM sample_analyses_temp
WHERE sample_id != 'sample_id';

DROP TABLE sample_analyses_temp;

-- Verify data loading
SELECT 'Seam Codes Count:' as info, COUNT(*) as count FROM seam_codes_lookup
UNION ALL
SELECT 'Rock Codes Count:', COUNT(*) FROM rock_codes_lookup
UNION ALL
SELECT 'Rock Types Count:', COUNT(*) FROM rock_types
UNION ALL
SELECT 'Collars Count:', COUNT(*) FROM collars
UNION ALL
SELECT 'Lithology Logs Count:', COUNT(*) FROM lithology_logs
UNION ALL
SELECT 'Sample Analyses Count:', COUNT(*) FROM sample_analyses;

-- Show sample statistics
SELECT 'Seam Codes by System:' as info;
SELECT system_id, COUNT(*) as count FROM seam_codes_lookup GROUP BY system_id;

SELECT 'Sample Analyses with Seam Codes:' as info;
SELECT COUNT(*) as samples_with_quality FROM sample_analyses WHERE seam_quality_id IS NOT NULL;
SELECT COUNT(*) as samples_with_73 FROM sample_analyses WHERE seam_73_id IS NOT NULL;
