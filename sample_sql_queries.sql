-- =====================================================
-- SQL Query Examples for Drilling Database
-- Compatible with SQL Server 2022
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
,     geologist
FROM collars
ORDER BY hole_id;

-- Query 2: ค้นหาหลุมเจาะที่มีความลึกเกิน 200 เมตร (Find Holes Exceeding 200m Depth)
-- Purpose: ระบุหลุมเจาะที่ลึกที่สุดเพื่อการวิเคราะห์เชิงลึก (Identify deepest holes for in-depth analysis)
SELECT 
      hole_id
,     total_depth
,     elevation
,     geologist
,     year_drilled
FROM collars
WHERE total_depth > 200
ORDER BY total_depth DESC;

-- Query 3: ดูลำดับชั้นหินตามความลึกของหลุมเจาะ (View Lithological Sequence by Depth)
-- Purpose: วิเคราะห์โครงสร้างทางธรณีวิทยาของหลุมเจาะตามช่วงความลึก (Analyze geological structure by depth intervals)
SELECT 
      l.depth_from
,     l.depth_to
,     l.thickness
,     l.rock_code
,     r.rock_name
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
,     thickness
,     rock_code
FROM lithology_logs
WHERE rock_code IN ('LI', 'CLLI', 'LICL')
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
,     r.rock_name
,     COUNT(*) as intervals
,     SUM(l.thickness) as total_thickness
FROM lithology_logs l
LEFT JOIN rock_types r ON l.rock_code = r.rock_code
GROUP BY l.hole_id, l.rock_code, r.rock_name
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
    ,     thickness
    ,     rock_code
    FROM lithology_logs
    WHERE rock_code IN ('LI', 'CLLI')
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
    ,     SUM(thickness) as overburden_thickness
    FROM lithology_logs
    WHERE rock_code NOT IN ('LI', 'CLLI', 'LICL')
        AND depth_from < 50  -- กำหนดความลึกสูงสุดของดินเปิดหน้า 50 เมตร
    GROUP BY hole_id
),
coal AS (
    SELECT 
          hole_id
    ,     SUM(thickness) as coal_thickness
    FROM lithology_logs
    WHERE rock_code IN ('LI', 'CLLI')
        AND depth_from < 100  -- กำหนดความลึกเหมืองสูงสุด 100 เมตร
    GROUP BY hole_id
)
SELECT 
      o.hole_id
,     ROUND(o.overburden_thickness, 2) as overburden_m
,     ROUND(c.coal_thickness, 2) as coal_m
,     ROUND(o.overburden_thickness / c.coal_thickness, 2) as stripping_ratio
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
SELECT 
      CASE 
          WHEN depth_from < 20 THEN '0-20m'
          WHEN depth_from < 50 THEN '20-50m'
          WHEN depth_from < 100 THEN '50-100m'
          WHEN depth_from < 200 THEN '100-200m'
          ELSE '>200m'
      END as depth_range
,     COUNT(*) as sample_count
,     ROUND(AVG(ash), 2) as avg_ash
,     ROUND(AVG(gross_cv), 0) as avg_cv
,     ROUND(AVG(sulphur), 2) as avg_sulphur
FROM sample_analyses
WHERE ash IS NOT NULL
GROUP BY depth_range
ORDER BY 
    CASE depth_range
        WHEN '0-20m' THEN 1
        WHEN '20-50m' THEN 2
        WHEN '50-100m' THEN 3
        WHEN '100-200m' THEN 4
        ELSE 5
    END;

-- Query 15: สร้างมุมมองสำหรับรายงานคุณภาพถ่านหิน (Create Coal Quality Summary View)
-- Purpose: สร้างมุมมองรวมสำหรับการรายงานและการวิเคราะห์คุณภาพถ่านหินอย่างรวดเร็ว
--          (Create consolidated view for rapid quality reporting and analysis)
IF OBJECT_ID('coal_quality_summary', 'V') IS NOT NULL DROP VIEW coal_quality_summary;
GO

CREATE VIEW coal_quality_summary AS
SELECT 
      c.hole_id
,     c.easting
,     c.northing
,     c.elevation
,     c.total_depth
,     c.year_drilled
,     c.geologist
,     COUNT(DISTINCT s.sample_id) as total_samples
,     ROUND(AVG(s.ash), 2) as avg_ash
,     ROUND(MIN(s.ash), 2) as min_ash
,     ROUND(MAX(s.ash), 2) as max_ash
,     ROUND(AVG(s.gross_cv), 0) as avg_cv
,     ROUND(MIN(s.gross_cv), 0) as min_cv
,     ROUND(MAX(s.gross_cv), 0) as max_cv
,     ROUND(AVG(s.sulphur), 2) as avg_sulphur
,     ROUND(
        (SELECT SUM(thickness) 
         FROM lithology_logs 
         WHERE hole_id = c.hole_id 
            AND rock_code IN ('LI', 'CLLI')), 2
    ) as total_coal_thickness
FROM collars c
LEFT JOIN sample_analyses s ON c.hole_id = s.hole_id
WHERE s.ash IS NOT NULL
GROUP BY c.hole_id, c.easting, c.northing, c.elevation, 
         c.total_depth, c.year_drilled, c.geologist;
GO

-- Example Usage: ใช้งานมุมมองสำหรับค้นหาถ่านหินคุณภาพดี
-- Query coal quality summary for holes with ash < 30% and CV > 2500 kcal/kg
SELECT * FROM coal_quality_summary
WHERE avg_ash < 30 AND avg_cv > 2500
ORDER BY total_coal_thickness DESC;

-- =====================================================
-- ADVANCED QUERIES: Using Table Valued Functions & CROSS APPLY
-- =====================================================

-- Query 16: สร้าง Table Valued Function สำหรับคำนวณคุณภาพถ่านหิน (Coal Quality Calculation TVF)
-- Purpose: สร้างฟังก์ชันที่คำนวณคุณภาพถ่านหินตามเกณฑ์ที่กำหนด
--          (Create function to calculate coal quality based on specified criteria)
IF OBJECT_ID('fn_GetCoalQualityMetrics', 'TF') IS NOT NULL DROP FUNCTION fn_GetCoalQualityMetrics;
GO

CREATE FUNCTION fn_GetCoalQualityMetrics(@hole_id NVARCHAR(50))
RETURNS TABLE
AS
RETURN
(
    SELECT 
          @hole_id as hole_id
    ,     COUNT(*) as sample_count
    ,     ROUND(AVG(ash), 2) as avg_ash
    ,     ROUND(AVG(gross_cv), 0) as avg_cv
    ,     ROUND(AVG(sulphur), 2) as avg_sulphur
    ,     ROUND(AVG(vm), 2) as avg_vm
    ,     ROUND(AVG(fc), 2) as avg_fc
    ,     ROUND(MIN(ash), 2) as min_ash
    ,     ROUND(MAX(ash), 2) as max_ash
    ,     ROUND(MIN(gross_cv), 0) as min_cv
    ,     ROUND(MAX(gross_cv), 0) as max_cv
    ,     CASE 
            WHEN AVG(ash) < 15 THEN 'Premium'
            WHEN AVG(ash) < 25 THEN 'High'
            WHEN AVG(ash) < 35 THEN 'Medium'
            ELSE 'Low'
          END as quality_grade
    FROM sample_analyses
    WHERE hole_id = @hole_id
        AND ash IS NOT NULL
        AND gross_cv IS NOT NULL
);
GO

-- Query 17: ใช้ CROSS APPLY กับ Table Valued Function (Using CROSS APPLY with TVF)
-- Purpose: ใช้ CROSS APPLY เพื่อเรียกใช้ TVF สำหรับแต่ละหลุมเจาะ
--          (Use CROSS APPLY to call TVF for each drilling hole)
SELECT 
      c.hole_id
,     c.easting
,     c.northing
,     c.elevation
,     c.total_depth
,     c.year_drilled
,     c.geologist
,     q.sample_count
,     q.avg_ash
,     q.avg_cv
,     q.avg_sulphur
,     q.quality_grade
,     q.min_ash
,     q.max_ash
FROM collars c
CROSS APPLY fn_GetCoalQualityMetrics(c.hole_id) q
WHERE q.sample_count > 0
ORDER BY q.avg_cv DESC;

-- Query 18: สร้าง Table Valued Function สำหรับวิเคราะห์ความหนาชั้นหิน (Lithology Thickness Analysis TVF)
-- Purpose: สร้างฟังก์ชันที่วิเคราะห์ความหนาของแต่ละชนิดหินในหลุมเจาะ
--          (Create function to analyze rock type thickness in drilling holes)
IF OBJECT_ID('fn_GetLithologyThickness', 'TF') IS NOT NULL DROP FUNCTION fn_GetLithologyThickness;
GO

CREATE FUNCTION fn_GetLithologyThickness(@hole_id NVARCHAR(50))
RETURNS TABLE
AS
RETURN
(
    SELECT 
          @hole_id as hole_id
    ,     l.rock_code
    ,     r.rock_name
    ,     COUNT(*) as interval_count
    ,     ROUND(SUM(l.thickness), 2) as total_thickness
    ,     ROUND(AVG(l.thickness), 2) as avg_thickness
    ,     ROUND(MIN(l.thickness), 2) as min_thickness
    ,     ROUND(MAX(l.thickness), 2) as max_thickness
    ,     ROUND(SUM(CASE WHEN l.rock_code IN ('LI', 'CLLI') THEN l.thickness ELSE 0 END), 2) as coal_thickness
    ,     ROUND(SUM(CASE WHEN l.rock_code NOT IN ('LI', 'CLLI', 'LICL') THEN l.thickness ELSE 0 END), 2) as overburden_thickness
    FROM lithology_logs l
    LEFT JOIN rock_types r ON l.rock_code = r.rock_code
    WHERE l.hole_id = @hole_id
    GROUP BY l.rock_code, r.rock_name
);
GO

-- Query 19: ใช้ CROSS APPLY กับ Lithology TVF (Using CROSS APPLY with Lithology TVF)
-- Purpose: วิเคราะห์ความหนาชั้นหินสำหรับหลุมเจาะที่มีข้อมูลครบถ้วน
--          (Analyze rock thickness for holes with complete data)
SELECT 
      c.hole_id
,     c.easting
,     c.northing
,     c.total_depth
,     c.year_drilled
,     l.rock_code
,     l.rock_name
,     l.interval_count
,     l.total_thickness
,     l.avg_thickness
,     l.coal_thickness
,     l.overburden_thickness
,     CASE 
        WHEN l.overburden_thickness > 0 AND l.coal_thickness > 0 
        THEN ROUND(l.overburden_thickness / l.coal_thickness, 2)
        ELSE NULL
      END as stripping_ratio
FROM collars c
CROSS APPLY fn_GetLithologyThickness(c.hole_id) l
WHERE l.total_thickness > 0
ORDER BY c.hole_id, l.total_thickness DESC;

-- Query 20: สร้าง Table Valued Function สำหรับการวิเคราะห์เชิงพื้นที่ (Spatial Analysis TVF)
-- Purpose: สร้างฟังก์ชันที่วิเคราะห์คุณภาพถ่านหินในพื้นที่รอบๆ หลุมเจาะ
--          (Create function to analyze coal quality in surrounding area)
IF OBJECT_ID('fn_GetSpatialQualityAnalysis', 'TF') IS NOT NULL DROP FUNCTION fn_GetSpatialQualityAnalysis;
GO

CREATE FUNCTION fn_GetSpatialQualityAnalysis(@hole_id NVARCHAR(50), @radius FLOAT)
RETURNS TABLE
AS
RETURN
(
    WITH nearby_holes AS (
        SELECT 
              c2.hole_id
        ,     c2.easting
        ,     c2.northing
        ,     SQRT(POWER(c1.easting - c2.easting, 2) + POWER(c1.northing - c2.northing, 2)) as distance
        FROM collars c1
        CROSS JOIN collars c2
        WHERE c1.hole_id = @hole_id
            AND c2.hole_id != @hole_id
            AND SQRT(POWER(c1.easting - c2.easting, 2) + POWER(c1.northing - c2.northing, 2)) <= @radius
    )
    SELECT 
          @hole_id as center_hole_id
    ,     @radius as search_radius
    ,     COUNT(DISTINCT nh.hole_id) as nearby_hole_count
    ,     ROUND(AVG(s.ash), 2) as avg_ash_in_area
    ,     ROUND(AVG(s.gross_cv), 0) as avg_cv_in_area
    ,     ROUND(AVG(s.sulphur), 2) as avg_sulphur_in_area
    ,     ROUND(MIN(nh.distance), 2) as nearest_hole_distance
    ,     ROUND(MAX(nh.distance), 2) as farthest_hole_distance
    FROM nearby_holes nh
    JOIN sample_analyses s ON nh.hole_id = s.hole_id
    WHERE s.ash IS NOT NULL
        AND s.gross_cv IS NOT NULL
);
GO

-- Query 21: ใช้ CROSS APPLY กับ Spatial Analysis TVF (Using CROSS APPLY with Spatial TVF)
-- Purpose: วิเคราะห์คุณภาพถ่านหินในพื้นที่รอบๆ แต่ละหลุมเจาะ
--          (Analyze coal quality in surrounding area for each hole)
SELECT 
      c.hole_id
,     c.easting
,     c.northing
,     c.elevation
,     c.total_depth
,     c.year_drilled
,     spa.search_radius
,     spa.nearby_hole_count
,     spa.avg_ash_in_area
,     spa.avg_cv_in_area
,     spa.avg_sulphur_in_area
,     spa.nearest_hole_distance
,     spa.farthest_hole_distance
FROM collars c
CROSS APPLY fn_GetSpatialQualityAnalysis(c.hole_id, 1000.0) spa  -- 1000m radius
WHERE spa.nearby_hole_count > 0
ORDER BY spa.avg_cv_in_area DESC;

-- Query 22: ใช้ OUTER APPLY สำหรับการวิเคราะห์แบบ Optional (Using OUTER APPLY for Optional Analysis)
-- Purpose: ใช้ OUTER APPLY เพื่อวิเคราะห์ข้อมูลที่อาจไม่มี (เช่น ข้อมูลคุณภาพ)
--          (Use OUTER APPLY for analysis that might not have data)
SELECT 
      c.hole_id
,     c.easting
,     c.northing
,     c.total_depth
,     c.year_drilled
,     c.geologist
,     COALESCE(q.sample_count, 0) as sample_count
,     COALESCE(q.avg_ash, 0) as avg_ash
,     COALESCE(q.avg_cv, 0) as avg_cv
,     COALESCE(q.quality_grade, 'No Data') as quality_grade
,     CASE 
        WHEN q.sample_count IS NULL THEN 'No Quality Data'
        WHEN q.sample_count = 0 THEN 'No Samples'
        ELSE 'Has Quality Data'
      END as data_status
FROM collars c
OUTER APPLY fn_GetCoalQualityMetrics(c.hole_id) q
ORDER BY c.hole_id;

-- Query 23: ใช้ CROSS APPLY กับ Multiple TVFs (Using CROSS APPLY with Multiple TVFs)
-- Purpose: รวมข้อมูลจากหลาย TVFs เพื่อการวิเคราะห์ที่ครอบคลุม
--          (Combine data from multiple TVFs for comprehensive analysis)
SELECT 
      c.hole_id
,     c.easting
,     c.northing
,     c.total_depth
,     c.year_drilled
,     c.geologist
    -- Quality metrics
,     q.sample_count
,     q.avg_ash
,     q.avg_cv
,     q.quality_grade
    -- Lithology summary
,     l.total_thickness
,     l.coal_thickness
,     l.overburden_thickness
    -- Spatial analysis
,     spa.nearby_hole_count
,     spa.avg_cv_in_area
,     spa.nearest_hole_distance
    -- Combined metrics
,     CASE 
        WHEN l.coal_thickness > 0 AND l.overburden_thickness > 0 
        THEN ROUND(l.overburden_thickness / l.coal_thickness, 2)
        ELSE NULL
      END as stripping_ratio
,     CASE 
        WHEN q.avg_cv > spa.avg_cv_in_area THEN 'Above Average'
        WHEN q.avg_cv < spa.avg_cv_in_area THEN 'Below Average'
        ELSE 'Average'
      END as quality_vs_area
FROM collars c
CROSS APPLY fn_GetCoalQualityMetrics(c.hole_id) q
CROSS APPLY (
    SELECT 
          SUM(total_thickness) as total_thickness
    ,     SUM(coal_thickness) as coal_thickness
    ,     SUM(overburden_thickness) as overburden_thickness
    FROM fn_GetLithologyThickness(c.hole_id)
) l
CROSS APPLY fn_GetSpatialQualityAnalysis(c.hole_id, 1000.0) spa
WHERE q.sample_count > 0
ORDER BY q.avg_cv DESC;

-- =====================================================
-- ADVANCED QUERIES: Using Grouping Sets & Window Functions
-- =====================================================

-- Query 24: วิเคราะห์คุณภาพถ่านหินด้วย Window Functions (Coal Quality Analysis using Window Functions)
-- Purpose: ใช้ Window Functions เพื่อเปรียบเทียบคุณภาพถ่านหินกับค่าเฉลี่ยและค่ามากที่สุดในหลุมเดียวกัน
--          (Compare coal quality against average and maximum values within the same hole)
SELECT 
      hole_id
,     sample_no
,     depth_from
,     depth_to
,     ash
,     gross_cv
,     sulphur
    -- คำนวณค่าเฉลี่ยในหลุมเดียวกัน
,     AVG(ash) OVER (PARTITION BY hole_id) as avg_ash_per_hole
,     AVG(gross_cv) OVER (PARTITION BY hole_id) as avg_cv_per_hole
    -- หาค่าสูงสุดในหลุมเดียวกัน
,     MAX(gross_cv) OVER (PARTITION BY hole_id) as max_cv_per_hole
    -- เรียงลำดับคุณภาพในหลุมเดียวกัน (1 = ดีที่สุด)
,     ROW_NUMBER() OVER (PARTITION BY hole_id ORDER BY gross_cv DESC) as quality_rank
    -- เปรียบเทียบกับตัวอย่างก่อนหน้า
,     LAG(gross_cv) OVER (PARTITION BY hole_id ORDER BY depth_from) as prev_cv
,     LEAD(gross_cv) OVER (PARTITION BY hole_id ORDER BY depth_from) as next_cv
FROM sample_analyses
WHERE ash IS NOT NULL
    AND gross_cv IS NOT NULL
ORDER BY hole_id, depth_from;

-- Query 25: วิเคราะห์ความหนาแบบสะสมด้วย Window Functions (Cumulative Thickness Analysis)
-- Purpose: คำนวณความหนาสะสมของชั้นถ่านหินตามความลึกเพื่อประเมินทรัพยากร
--          (Calculate cumulative coal thickness by depth for resource estimation)
SELECT 
      hole_id
,     depth_from
,     depth_to
,     thickness
,     rock_code
    -- คำนวณความหนาสะสม
,     SUM(thickness) OVER (
        PARTITION BY hole_id 
        ORDER BY depth_from 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as cumulative_thickness
    -- คำนวณความหนาสะสมแยกตามชนิดหิน
,     SUM(CASE WHEN rock_code IN ('LI', 'CLLI') THEN thickness ELSE 0 END) OVER (
        PARTITION BY hole_id 
        ORDER BY depth_from 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as cumulative_coal_thickness
FROM lithology_logs
WHERE hole_id IN (SELECT DISTINCT hole_id FROM sample_analyses)
ORDER BY hole_id, depth_from;

-- Query 26: วิเคราะห์แนวโน้มคุณภาพถ่านหินตามความลึกด้วย Window Functions (Quality Trend Analysis)
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

-- Query 27: เปรียบเทียบคุณภาพระหว่างหลุมเจาะด้วย Window Functions (Inter-hole Quality Comparison)
-- Purpose: เปรียบเทียบคุณภาพถ่านหินของหลุมเจาะแต่ละหลุมกับค่าเฉลี่ยและค่ามัธยฐานทั้งโครงการ
--          (Compare individual hole quality against project average and median)
SELECT 
      c.hole_id
,     c.year_drilled
,     c.geologist
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
GROUP BY c.hole_id, c.year_drilled, c.geologist
ORDER BY quality_rank;

-- Query 28: ใช้ Grouping Sets เพื่อวิเคราะห์หลายมิติ (Multi-dimensional Analysis with Grouping Sets)
-- Purpose: วิเคราะห์คุณภาพถ่านหินในหลายมิติพร้อมกัน (หลุม, ปี, นักธรณีวิทยา, รวม)
--          (Multi-dimensional analysis: by hole, year, geologist, and overall)
SELECT 
      COALESCE(hole_id, 'ALL HOLES') as hole_id
,     COALESCE(year_drilled, 'ALL YEARS') as year_drilled
,     COALESCE(geologist, 'ALL GEOLOGISTS') as geologist
,     COUNT(*) as sample_count
,     ROUND(AVG(ash), 2) as avg_ash
,     ROUND(AVG(gross_cv), 0) as avg_cv
,     ROUND(AVG(sulphur), 2) as avg_sulphur
    -- ระบุระดับของ GROUPING SET
,     GROUPING_ID(hole_id, year_drilled, geologist) as grouping_level
FROM sample_analyses s
JOIN collars c ON s.hole_id = c.hole_id
WHERE s.ash IS NOT NULL AND s.gross_cv IS NOT NULL
GROUP BY GROUPING SETS (
    (hole_id, year_drilled, geologist),  -- ระดับ Detail
    (hole_id, year_drilled),             -- ตามหลุมและปี
    (hole_id),                           -- ตามหลุม
    (year_drilled),                      -- ตามปี
    (geologist),                         -- ตามนักธรณีวิทยา
    ()                                   -- Grand Total
)
ORDER BY grouping_level, hole_id, year_drilled, geologist;

-- Query 29: วิเคราะห์การกระจายตัวของข้อมูลด้วย Window Functions (Data Distribution Analysis)
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

-- Query 30: วิเคราะห์ความต่อเนื่องของชั้นถ่านหินด้วย Window Functions (Coal Seam Continuity Analysis)
-- Purpose: ตรวจสอบความต่อเนื่องและความสม่ำเสมอของชั้นถ่านหินในหลายหลุม
--          (Analyze coal seam continuity and consistency across multiple holes)
WITH depth_intervals AS (
    SELECT 
          hole_id
    ,     depth_from
    ,     depth_to
    ,     thickness
    ,     rock_code
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
    FROM lithology_logs
    WHERE rock_code IN ('LI', 'CLLI')
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
