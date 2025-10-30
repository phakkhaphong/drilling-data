-- =====================================================
-- SQL Query Examples for Enhanced Drilling Database
-- Compatible with Normalized Schema (Deduplicated & Enhanced)
-- =====================================================

-- Query 1: ดึงข้อมูลหลุมเจาะทั้งหมด (Select All Drilling Holes)
-- Purpose: แสดงรายการหลุมเจาะทั้งหมดพร้อมข้อมูลพื้นฐาน (Display all drilling holes with basic information)
SELECT 
      hole_id
,     easting
,     northing
,     elevation
,     total_depth
,     year_drilled
,     contractor
FROM collars
ORDER BY hole_id;

-- Query 2: ค้นหาหลุมเจาะที่มีความลึกเกิน 200 เมตร (Find Holes Exceeding 200m Depth)
-- Purpose: ระบุหลุมเจาะที่ลึกที่สุดเพื่อการวิเคราะห์เชิงลึก (Identify deepest holes for in-depth analysis)
SELECT 
      hole_id
,     total_depth
,     elevation
,     contractor
,     year_drilled
FROM collars
WHERE total_depth > 200
ORDER BY total_depth DESC;

-- Query 3: ดูลำดับชั้นหินตามความลึกของหลุมเจาะ (View Lithological Sequence by Depth)
-- Purpose: วิเคราะห์โครงสร้างทางธรณีวิทยาของหลุมเจาะตามช่วงความลึก (Analyze geological structure by depth intervals)
SELECT 
      l.depth_from
,     l.depth_to
,     l.depth_to - l.depth_from as thickness
,     l.rock_code
,     r.lithology
,     r.detail
,     l.description
FROM lithology_logs l
LEFT JOIN rock_types r ON l.rock_code = r.rock_code
WHERE l.hole_id = 'BC01C'
ORDER BY l.depth_from;

-- Query 4: ระบุช่วงความลึกที่พบชั้นถ่านหิน (Identify Coal Seam Depth Intervals)
-- Purpose: ค้นหาและติดตามชั้นถ่านหินในหลุมเจาะต่างๆ (Locate and track coal seams across drill holes)
SELECT 
      hole_id
,     depth_from
,     depth_to
,     depth_to - depth_from as thickness
,     l.rock_code
,     r.lithology
FROM lithology_logs l
LEFT JOIN rock_types r ON l.rock_code = r.rock_code
WHERE r.lithology IN ('LI', 'CLLI', 'LICL')
ORDER BY hole_id, depth_from;

-- Query 5: ดูผลการวิเคราะห์คุณภาพถ่านหิน (View Coal Quality Analysis Results)
-- Purpose: แสดงพารามิเตอร์คุณภาพถ่านหินสำหรับการประเมินมาตรฐาน (Display coal quality parameters for standards assessment)
SELECT 
      sample_no
,     depth_from
,     depth_to
,     ash
,     gross_cv
,     sulphur
,     vm
,     fc
FROM sample_analyses
WHERE hole_id = 'BC01C'
    AND ash IS NOT NULL
ORDER BY depth_from;

-- Query 6: ค้นหาตัวอย่างถ่านหินคุณภาพพรีเมียม (Find Premium Quality Coal Samples)
-- Criteria: Ash < 25%, CV > 3000 kcal/kg
-- Purpose: ระบุถ่านหินคุณภาพสูงสำหรับการค้าและการวิจัย (Identify high-quality coal for commercial and research purposes)
SELECT 
      hole_id
,     sample_no
,     depth_from
,     depth_to
,     ash
,     gross_cv
,     sulphur
FROM sample_analyses
WHERE ash < 25 
    AND gross_cv > 3000
    AND ash IS NOT NULL
ORDER BY gross_cv DESC;

-- Query 7: สรุปความหนาสะสมของแต่ละชนิดหิน (Summarize Rock Type Thickness by Hole)
-- Purpose: ประเมินความหนาสะสมของแต่ละหน่วยหินสำหรับการสร้างแบบจำลองธรณีวิทยา
--          (Assess cumulative rock thickness for geological modeling)
SELECT 
      l.hole_id
,     l.rock_code
,     r.lithology
,     r.detail
,     COUNT(*) as intervals
,     SUM(l.depth_to - l.depth_from) as total_thickness
FROM lithology_logs l
LEFT JOIN rock_types r ON l.rock_code = r.rock_code
GROUP BY l.hole_id, l.rock_code, r.lithology, r.detail
ORDER BY l.hole_id, total_thickness DESC;

-- Query 8: สรุปสถิติคุณภาพถ่านหินเฉลี่ยตามหลุมเจาะ (Summarize Average Coal Quality by Hole)
-- Purpose: ประเมินคุณภาพถ่านหินรวมของแต่ละหลุมเพื่อการเปรียบเทียบ (Evaluate overall coal quality per hole for comparison)
SELECT 
      hole_id
,     COUNT(*) as sample_count
,     ROUND(AVG(ash), 2) as avg_ash
,     ROUND(AVG(gross_cv), 0) as avg_cv
,     ROUND(AVG(sulphur), 2) as avg_sulphur
,     ROUND(AVG(vm), 2) as avg_vm
,     ROUND(AVG(fc), 2) as avg_fc
FROM sample_analyses
WHERE ash IS NOT NULL
GROUP BY hole_id
ORDER BY avg_cv DESC;

-- Query 9: ระบุชั้นถ่านหินที่หนาที่สุดในแต่ละหลุม (Identify Thickest Coal Seams per Hole)
-- Purpose: ค้นหาชั้นถ่านหินที่มีศักยภาพทางการทำเหมืองมากที่สุด (Locate most economically viable coal seams)
WITH coal_intervals AS (
    SELECT 
          hole_id
    ,     depth_from
    ,     depth_to
    ,     depth_to - depth_from as thickness
    ,     l.rock_code
    FROM lithology_logs l
    LEFT JOIN rock_types r ON l.rock_code = r.rock_code
    WHERE r.lithology IN ('LI', 'CLLI')
)
SELECT 
      hole_id
,     MAX(thickness) as max_coal_thickness
,     SUM(thickness) as total_coal_thickness
,     COUNT(*) as coal_intervals
FROM coal_intervals
GROUP BY hole_id
ORDER BY max_coal_thickness DESC;

-- Query 10: วิเคราะห์การกระจายตัวเชิงพื้นที่ของคุณภาพถ่านหิน (Spatial Quality Distribution Analysis)
-- Purpose: ศึกษาการเปลี่ยนแปลงคุณภาพถ่านหินตามตำแหน่งทางภูมิศาสตร์
--          (Study coal quality variation across geographic locations)
SELECT 
      c.hole_id
,     c.easting
,     c.northing
,     c.elevation
,     ROUND(AVG(s.ash), 2) as avg_ash
,     ROUND(AVG(s.gross_cv), 0) as avg_cv
,     COUNT(s.sample_id) as sample_count
FROM collars c
LEFT JOIN sample_analyses s ON c.hole_id = s.hole_id
WHERE s.ash IS NOT NULL
GROUP BY c.hole_id, c.easting, c.northing, c.elevation
ORDER BY c.hole_id;

-- Query 11: ประเมินอัตราส่วนดินเปิดหน้าถ่านหิน (Stripping Ratio Analysis)
-- Purpose: คำนวณอัตราส่วนดินเปิดหน้าถ่านหินสำหรับประเมินความคุ้มค่าในการทำเหมืองแบบเปิด
--          (Calculate overburden-to-coal ratio for open-pit mining viability assessment)
WITH overburden AS (
    SELECT 
          hole_id
    ,     SUM(depth_to - depth_from) as overburden_thickness
    FROM lithology_logs l
    LEFT JOIN rock_types r ON l.rock_code = r.rock_code
    WHERE r.lithology NOT IN ('LI', 'CLLI', 'LICL')
        AND depth_from < 50  -- กำหนดความลึกสูงสุดของดินเปิดหน้า 50 เมตร
    GROUP BY hole_id
),
coal AS (
    SELECT 
          hole_id
    ,     SUM(depth_to - depth_from) as coal_thickness
    FROM lithology_logs l
    LEFT JOIN rock_types r ON l.rock_code = r.rock_code
    WHERE r.lithology IN ('LI', 'CLLI')
        AND depth_from < 100  -- กำหนดความลึกเหมืองสูงสุด 100 เมตร
    GROUP BY hole_id
)
SELECT 
      o.hole_id
,     ROUND(o.overburden_thickness, 2) as overburden_m
,     ROUND(c.coal_thickness, 2) as coal_m
,     ROUND(o.overburden_thickness / NULLIF(c.coal_thickness, 0), 2) as stripping_ratio
FROM overburden o
JOIN coal c ON o.hole_id = c.hole_id
WHERE c.coal_thickness > 0
ORDER BY stripping_ratio;

-- Query 12: ตรวจสอบความสมบูรณ์และความครบถ้วนของข้อมูล (Data Completeness Audit)
-- Purpose: ประเมินปริมาณและความครอบคลุมของข้อมูลในแต่ละตาราง (Assess data volume and coverage across tables)
SELECT 
      'Total Holes' as category
,     COUNT(DISTINCT hole_id) as count
FROM collars
UNION ALL
SELECT 
      'Holes with Lithology'
,     COUNT(DISTINCT hole_id)
FROM lithology_logs
UNION ALL
SELECT 
      'Holes with Samples'
,     COUNT(DISTINCT hole_id)
FROM sample_analyses
UNION ALL
SELECT 
      'Total Samples'
,     COUNT(*)
FROM sample_analyses
WHERE ash IS NOT NULL;

-- Query 13: ระบุหลุมเจาะที่มีข้อมูลไม่ครบถ้วน (Identify Incomplete Data Holes)
-- Purpose: ค้นหาหลุมเจาะที่ขาดข้อมูลธรณีวิทยาและ/หรือการวิเคราะห์ตัวอย่าง (Locate holes missing geological or analytical data)
WITH lithology_counts AS (
    SELECT 
          hole_id
    ,     COUNT(*) as log_count
    FROM lithology_logs
    GROUP BY hole_id
),
sample_counts AS (
    SELECT 
          hole_id
    ,     COUNT(*) as sample_count
    FROM sample_analyses
    WHERE ash IS NOT NULL
    GROUP BY hole_id
)
SELECT 
      c.hole_id
,     c.total_depth
,     COALESCE(l.log_count, 0) as lithology_count
,     COALESCE(s.sample_count, 0) as sample_count
FROM collars c
LEFT JOIN lithology_counts l ON c.hole_id = l.hole_id
LEFT JOIN sample_counts s ON c.hole_id = s.hole_id
WHERE l.log_count IS NULL OR s.sample_count IS NULL
ORDER BY c.hole_id;

-- Query 14: วิเคราะห์แนวโน้มคุณภาพถ่านหินตามระดับความลึก (Depth-Based Quality Trend Analysis)
-- Purpose: ศึกษาการเปลี่ยนแปลงคุณภาพถ่านหินตามระดับความลึกสำหรับการวางแผนเหมือง (Study quality variation by depth for mine planning)
WITH q AS (
    SELECT 
        CASE 
            WHEN depth_from < 20 THEN '0-20m'
            WHEN depth_from < 50 THEN '20-50m'
            WHEN depth_from < 100 THEN '50-100m'
            WHEN depth_from < 200 THEN '100-200m'
            ELSE '>200m'
        END as depth_range
    ,   ash
    ,   gross_cv
    ,   sulphur
    FROM sample_analyses
    WHERE ash IS NOT NULL
)
SELECT 
      depth_range
,     COUNT(*) as sample_count
,     ROUND(AVG(ash), 2) as avg_ash
,     ROUND(AVG(gross_cv), 0) as avg_cv
,     ROUND(AVG(sulphur), 2) as avg_sulphur
FROM q
GROUP BY depth_range
ORDER BY 
    CASE depth_range
        WHEN '0-20m' THEN 1
        WHEN '20-50m' THEN 2
        WHEN '50-100m' THEN 3
        WHEN '100-200m' THEN 4
        ELSE 5
    END;

-- Query 15: วิเคราะห์ Seam Codes ตามระบบ (Seam Code System Analysis)
-- Purpose: วิเคราะห์การใช้งาน seam codes ในระบบต่างๆ เพื่อการประเมินความครบถ้วน
--          (Analyze seam code usage across different systems for completeness assessment)
SELECT 
      scl.system_id
,     scl.system_name
,     COUNT(*) as total_seam_codes
,     MIN(scl.seam_code) as min_code
,     MAX(scl.seam_code) as max_code
,     COUNT(DISTINCT sa.sample_id) as samples_with_seam_codes
FROM seam_codes_lookup scl
LEFT JOIN sample_analyses sa ON (
    sa.seam_quality_id = scl.seam_id OR 
    sa.seam_73_id = scl.seam_id
)
GROUP BY scl.system_id, scl.system_name, scl.priority
ORDER BY scl.priority;

-- Query 16: วิเคราะห์คุณภาพถ่านหินตาม Seam Classification (Coal Quality by Seam Classification)
-- Purpose: เปรียบเทียบคุณภาพถ่านหินตามระบบ seam classification ต่างๆ
--          (Compare coal quality across different seam classification systems)
SELECT 
      scl.system_name
,     scl.seam_label
,     COUNT(*) as sample_count
,     ROUND(AVG(sa.ash), 2) as avg_ash
,     ROUND(AVG(sa.gross_cv), 0) as avg_cv
,     ROUND(AVG(sa.sulphur), 2) as avg_sulphur
FROM sample_analyses sa
JOIN seam_codes_lookup scl ON sa.seam_quality_id = scl.seam_id
WHERE sa.ash IS NOT NULL AND sa.gross_cv IS NOT NULL
GROUP BY scl.system_name, scl.seam_label
ORDER BY scl.system_name, avg_cv DESC;

-- Query 17: วิเคราะห์ความหนาแบบสะสมด้วย Window Functions (Cumulative Thickness Analysis)
-- Purpose: คำนวณความหนาสะสมของชั้นถ่านหินตามความลึกเพื่อประเมินทรัพยากร
--          (Calculate cumulative coal thickness by depth for resource estimation)
SELECT 
      hole_id
,     depth_from
,     depth_to
,     depth_to - depth_from as thickness
,     l.rock_code
,     r.lithology
    -- คำนวณความหนาสะสม
,     SUM(depth_to - depth_from) OVER (
        PARTITION BY hole_id 
        ORDER BY depth_from 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as cumulative_thickness
    -- คำนวณความหนาสะสมแยกตามชนิดหิน
,     SUM(CASE WHEN r.lithology IN ('LI', 'CLLI') THEN depth_to - depth_from ELSE 0 END) OVER (
        PARTITION BY hole_id 
        ORDER BY depth_from 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as cumulative_coal_thickness
FROM lithology_logs l
LEFT JOIN rock_types r ON l.rock_code = r.rock_code
WHERE hole_id IN (SELECT DISTINCT hole_id FROM sample_analyses)
ORDER BY hole_id, depth_from;

-- Query 18: วิเคราะห์แนวโน้มคุณภาพถ่านหินตามความลึกด้วย Window Functions (Quality Trend Analysis)
-- Purpose: ใช้ Moving Average เพื่อวิเคราะห์แนวโน้มคุณภาพถ่านหินตามระดับความลึก
--          (Use moving average to analyze coal quality trends by depth)
SELECT 
      hole_id
,     depth_from
,     depth_to
,     ash
,     gross_cv
,     sulphur
    -- Moving Average (3 samples)
,     AVG(ash) OVER (
        PARTITION BY hole_id 
        ORDER BY depth_from 
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) as moving_avg_ash
,     AVG(gross_cv) OVER (
        PARTITION BY hole_id 
        ORDER BY depth_from 
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) as moving_avg_cv
    -- Standard Deviation
,     STDEV(gross_cv) OVER (
        PARTITION BY hole_id 
        ORDER BY depth_from 
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) as cv_std_dev
FROM sample_analyses
WHERE ash IS NOT NULL AND gross_cv IS NOT NULL
ORDER BY hole_id, depth_from;

-- Query 19: เปรียบเทียบคุณภาพระหว่างหลุมเจาะด้วย Window Functions (Inter-hole Quality Comparison)
-- Purpose: เปรียบเทียบคุณภาพถ่านหินของหลุมเจาะแต่ละหลุมกับค่าเฉลี่ยและค่ามัธยฐานทั้งโครงการ
--          (Compare individual hole quality against project average and median)
SELECT 
      c.hole_id
,     c.year_drilled
,     c.contractor
,     COUNT(s.sample_id) as sample_count
,     AVG(s.ash) as hole_avg_ash
,     AVG(s.gross_cv) as hole_avg_cv
    -- ค่าเฉลี่ยทั้งโครงการ
,     AVG(AVG(s.ash)) OVER () as project_avg_ash
,     AVG(AVG(s.gross_cv)) OVER () as project_avg_cv
    -- ค่ามัธยฐานทั้งโครงการ
,     PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY AVG(s.ash)) OVER () as project_median_ash
,     PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY AVG(s.gross_cv)) OVER () as project_median_cv
    -- ค่าเบี่ยงเบนจากค่าเฉลี่ย
,     AVG(s.ash) - AVG(AVG(s.ash)) OVER () as ash_deviation
,     AVG(s.gross_cv) - AVG(AVG(s.gross_cv)) OVER () as cv_deviation
    -- Ranking
,     RANK() OVER (ORDER BY AVG(s.gross_cv) DESC) as quality_rank
FROM collars c
JOIN sample_analyses s ON c.hole_id = s.hole_id
WHERE s.ash IS NOT NULL AND s.gross_cv IS NOT NULL
GROUP BY c.hole_id, c.year_drilled, c.contractor
ORDER BY quality_rank;

-- Query 20: วิเคราะห์การกระจายตัวของข้อมูลด้วย Window Functions (Data Distribution Analysis)
-- Purpose: ใช้ Percentile และ Quartile เพื่อวิเคราะห์การกระจายตัวของคุณภาพถ่านหิน
--          (Use percentiles and quartiles to analyze coal quality distribution)
SELECT 
      hole_id
,     depth_from
,     depth_to
,     ash
,     gross_cv
,     sulphur
    -- Quartiles
,     PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY gross_cv) 
        OVER (PARTITION BY hole_id) as q1_cv
,     PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gross_cv) 
        OVER (PARTITION BY hole_id) as median_cv
,     PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY gross_cv) 
        OVER (PARTITION BY hole_id) as q3_cv
    -- Percentile Rank
,     PERCENT_RANK() OVER (PARTITION BY hole_id ORDER BY gross_cv) as cv_percent_rank
    -- CUME_DIST
,     CUME_DIST() OVER (PARTITION BY hole_id ORDER BY gross_cv) as cv_cumulative_dist
FROM sample_analyses
WHERE ash IS NOT NULL AND gross_cv IS NOT NULL
ORDER BY hole_id, depth_from;

-- Query 21: สร้างมุมมองสำหรับรายงานคุณภาพถ่านหิน (Create Coal Quality Summary View)
-- Purpose: สร้างมุมมองรวมสำหรับการรายงานและการวิเคราะห์คุณภาพถ่านหินอย่างรวดเร็ว
--          (Create consolidated view for rapid quality reporting and analysis)
DROP VIEW IF EXISTS coal_quality_summary;
GO

CREATE VIEW coal_quality_summary AS
SELECT 
      c.hole_id
,     c.easting
,     c.northing
,     c.elevation
,     c.total_depth
,     c.year_drilled
,     c.contractor
,     COUNT(DISTINCT s.sample_id) as total_samples
,     ROUND(AVG(s.ash), 2) as avg_ash
,     ROUND(MIN(s.ash), 2) as min_ash
,     ROUND(MAX(s.ash), 2) as max_ash
,     ROUND(AVG(s.gross_cv), 0) as avg_cv
,     ROUND(MIN(s.gross_cv), 0) as min_cv
,     ROUND(MAX(s.gross_cv), 0) as max_cv
,     ROUND(AVG(s.sulphur), 2) as avg_sulphur
,     ROUND(
        (SELECT SUM(depth_to - depth_from) 
         FROM lithology_logs l
         LEFT JOIN rock_types r ON l.rock_code = r.rock_code
         WHERE l.hole_id = c.hole_id 
            AND r.lithology IN ('LI', 'CLLI')), 2
    ) as total_coal_thickness
FROM collars c
LEFT JOIN sample_analyses s ON c.hole_id = s.hole_id
WHERE s.ash IS NOT NULL
GROUP BY c.hole_id, c.easting, c.northing, c.elevation, 
         c.total_depth, c.year_drilled, c.contractor;
GO

-- Example Usage: ใช้งานมุมมองสำหรับค้นหาถ่านหินคุณภาพดี
-- Query coal quality summary for holes with ash < 30% and CV > 2500 kcal/kg
SELECT * FROM coal_quality_summary
WHERE avg_ash < 30 AND avg_cv > 2500
ORDER BY total_coal_thickness DESC;

-- Query 22: วิเคราะห์ความต่อเนื่องของชั้นถ่านหินด้วย Window Functions (Coal Seam Continuity Analysis)
-- Purpose: ตรวจสอบความต่อเนื่องและความสม่ำเสมอของชั้นถ่านหินในหลายหลุม
--          (Analyze coal seam continuity and consistency across multiple holes)
WITH depth_intervals AS (
    SELECT 
          hole_id
    ,     depth_from
    ,     depth_to
    ,     depth_to - depth_from as thickness
    ,     l.rock_code
    ,     r.lithology
        -- หาความลึกเริ่มต้นของชั้นถ่านหิน
    ,     FIRST_VALUE(depth_from) OVER (
            PARTITION BY hole_id 
            ORDER BY depth_from 
            ROWS UNBOUNDED PRECEDING
        ) as first_depth
        -- หาความลึกสิ้นสุดของชั้นถ่านหิน
    ,     LAST_VALUE(depth_to) OVER (
            PARTITION BY hole_id 
            ORDER BY depth_from 
            ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
        ) as last_depth
    FROM lithology_logs l
    LEFT JOIN rock_types r ON l.rock_code = r.rock_code
    WHERE r.lithology IN ('LI', 'CLLI')
)
SELECT 
      hole_id
,     depth_from
,     depth_to
,     thickness
,     first_depth
,     last_depth
,     last_depth - first_depth as total_interval
,     SUM(thickness) OVER (
        PARTITION BY hole_id 
        ORDER BY depth_from 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as cumulative_coal_thickness
FROM depth_intervals
ORDER BY hole_id, depth_from;

-- Query 23: วิเคราะห์ Seam Code Mapping ระหว่างระบบ (Cross-System Seam Code Mapping)
-- Purpose: วิเคราะห์การแมป seam codes ระหว่างระบบต่างๆ เพื่อการตรวจสอบความสอดคล้อง
--          (Analyze seam code mapping between different systems for consistency checking)
SELECT 
      scl1.system_name as system_1
,     scl1.seam_label as seam_1
,     scl1.seam_code as code_1
,     scl2.system_name as system_2
,     scl2.seam_label as seam_2
,     scl2.seam_code as code_2
,     COUNT(DISTINCT sa.sample_id) as sample_count
FROM sample_analyses sa
JOIN seam_codes_lookup scl1 ON sa.seam_quality_id = scl1.seam_id
JOIN seam_codes_lookup scl2 ON sa.seam_73_id = scl2.seam_id
WHERE sa.seam_quality_id IS NOT NULL AND sa.seam_73_id IS NOT NULL
GROUP BY scl1.system_name, scl1.seam_label, scl1.seam_code,
         scl2.system_name, scl2.seam_label, scl2.seam_code
ORDER BY sample_count DESC;

-- Query 24: สรุปข้อมูลตามระบบ Seam Classification (Summary by Seam Classification System)
-- Purpose: สรุปข้อมูลคุณภาพถ่านหินตามระบบ seam classification ต่างๆ
--          (Summarize coal quality data by different seam classification systems)
SELECT 
      scl.system_name
,     COUNT(DISTINCT sa.hole_id) as holes_count
,     COUNT(sa.sample_id) as samples_count
,     ROUND(AVG(sa.ash), 2) as avg_ash
,     ROUND(AVG(sa.gross_cv), 0) as avg_cv
,     ROUND(AVG(sa.sulphur), 2) as avg_sulphur
,     ROUND(MIN(sa.ash), 2) as min_ash
,     ROUND(MAX(sa.ash), 2) as max_ash
,     ROUND(MIN(sa.gross_cv), 0) as min_cv
,     ROUND(MAX(sa.gross_cv), 0) as max_cv
FROM sample_analyses sa
JOIN seam_codes_lookup scl ON (
    sa.seam_quality_id = scl.seam_id OR 
    sa.seam_73_id = scl.seam_id
)
WHERE sa.ash IS NOT NULL AND sa.gross_cv IS NOT NULL
GROUP BY scl.system_name, scl.priority
ORDER BY scl.priority;

-- Query 25: ตรวจสอบความสมบูรณ์ของ Seam Code Data (Seam Code Data Completeness Check)
-- Purpose: ตรวจสอบความครบถ้วนของข้อมูล seam codes ใน sample analyses
--          (Check completeness of seam code data in sample analyses)
SELECT 
      'Total Samples' as category
,     COUNT(*) as count
FROM sample_analyses
UNION ALL
SELECT 
      'Samples with Quality Seam'
,     COUNT(*)
FROM sample_analyses
WHERE seam_quality_id IS NOT NULL
UNION ALL
SELECT 
      'Samples with 73 Seam'
,     COUNT(*)
FROM sample_analyses
WHERE seam_73_id IS NOT NULL
UNION ALL
SELECT 
      'Samples with Any Seam'
,     COUNT(*)
FROM sample_analyses
WHERE seam_quality_id IS NOT NULL OR seam_73_id IS NOT NULL;

