-- =====================================================
-- SQL Queries ตัวอย่างสำหรับ Drilling Database
-- =====================================================

-- 1. ดูข้อมูลหลุมเจาะทั้งหมด
SELECT 
    hole_id,
    easting,
    northing,
    elevation,
    total_depth,
    year_drilled,
    geologist
FROM collars
ORDER BY hole_id;

-- 2. หาหลุมเจาะที่มีความลึกมากกว่า 200 เมตร
SELECT 
    hole_id,
    total_depth,
    elevation,
    geologist,
    year_drilled
FROM collars
WHERE total_depth > 200
ORDER BY total_depth DESC;

-- 3. ดูลำดับชั้นหินของหลุมเจาะที่ระบุ
SELECT 
    l.depth_from,
    l.depth_to,
    l.thickness,
    l.rock_code,
    r.rock_name,
    l.description
FROM lithology_logs l
LEFT JOIN rock_types r ON l.rock_code = r.rock_code
WHERE l.hole_id = 'BC01C'
ORDER BY l.depth_from;

-- 4. หาช่วงความลึกที่พบถ่านหิน (Lignite)
SELECT 
    hole_id,
    depth_from,
    depth_to,
    thickness,
    rock_code
FROM lithology_logs
WHERE rock_code IN ('LI', 'CLLI', 'LICL')
ORDER BY hole_id, depth_from;

-- 5. ดูผลการวิเคราะห์คุณภาพถ่านหินของหลุมที่ระบุ
SELECT 
    sample_no,
    depth_from,
    depth_to,
    ash,
    gross_cv,
    sulphur,
    vm,
    fc
FROM sample_analyses
WHERE hole_id = 'BC01C'
    AND ash IS NOT NULL
ORDER BY depth_from;

-- 6. หาตัวอย่างถ่านหินคุณภาพดี (Ash < 25%, CV > 3000)
SELECT 
    hole_id,
    sample_no,
    depth_from,
    depth_to,
    ash,
    gross_cv,
    sulphur
FROM sample_analyses
WHERE ash < 25 
    AND gross_cv > 3000
    AND ash IS NOT NULL
ORDER BY gross_cv DESC;

-- 7. สรุปความหนาของแต่ละชนิดหินในแต่ละหลุม
SELECT 
    l.hole_id,
    l.rock_code,
    r.rock_name,
    COUNT(*) as intervals,
    SUM(l.thickness) as total_thickness
FROM lithology_logs l
LEFT JOIN rock_types r ON l.rock_code = r.rock_code
GROUP BY l.hole_id, l.rock_code, r.rock_name
ORDER BY l.hole_id, total_thickness DESC;

-- 8. สรุปคุณภาพถ่านหินเฉลี่ยของแต่ละหลุม
SELECT 
    hole_id,
    COUNT(*) as sample_count,
    ROUND(AVG(ash), 2) as avg_ash,
    ROUND(AVG(gross_cv), 0) as avg_cv,
    ROUND(AVG(sulphur), 2) as avg_sulphur,
    ROUND(AVG(vm), 2) as avg_vm,
    ROUND(AVG(fc), 2) as avg_fc
FROM sample_analyses
WHERE ash IS NOT NULL
GROUP BY hole_id
ORDER BY avg_cv DESC;

-- 9. หาชั้นถ่านหินที่หนาที่สุดในแต่ละหลุม
WITH coal_intervals AS (
    SELECT 
        hole_id,
        depth_from,
        depth_to,
        thickness,
        rock_code
    FROM lithology_logs
    WHERE rock_code IN ('LI', 'CLLI')
)
SELECT 
    hole_id,
    MAX(thickness) as max_coal_thickness,
    SUM(thickness) as total_coal_thickness,
    COUNT(*) as coal_intervals
FROM coal_intervals
GROUP BY hole_id
ORDER BY max_coal_thickness DESC;

-- 10. วิเคราะห์การกระจายตัวเชิงพื้นที่ของคุณภาพถ่านหิน
SELECT 
    c.hole_id,
    c.easting,
    c.northing,
    c.elevation,
    ROUND(AVG(s.ash), 2) as avg_ash,
    ROUND(AVG(s.gross_cv), 0) as avg_cv,
    COUNT(s.sample_id) as sample_count
FROM collars c
LEFT JOIN sample_analyses s ON c.hole_id = s.hole_id
WHERE s.ash IS NOT NULL
GROUP BY c.hole_id, c.easting, c.northing, c.elevation
ORDER BY c.hole_id;

-- 11. หาช่วงความลึกที่มีศักยภาพในการทำเหมือง (Stripping Ratio)
WITH overburden AS (
    SELECT 
        hole_id,
        SUM(thickness) as overburden_thickness
    FROM lithology_logs
    WHERE rock_code NOT IN ('LI', 'CLLI', 'LICL')
        AND depth_from < 50  -- ความลึก overburden สูงสุด 50 ม.
    GROUP BY hole_id
),
coal AS (
    SELECT 
        hole_id,
        SUM(thickness) as coal_thickness
    FROM lithology_logs
    WHERE rock_code IN ('LI', 'CLLI')
        AND depth_from < 100  -- ความลึกสูงสุดที่จะทำเหมือง
    GROUP BY hole_id
)
SELECT 
    o.hole_id,
    ROUND(o.overburden_thickness, 2) as overburden_m,
    ROUND(c.coal_thickness, 2) as coal_m,
    ROUND(o.overburden_thickness / c.coal_thickness, 2) as stripping_ratio
FROM overburden o
JOIN coal c ON o.hole_id = c.hole_id
WHERE c.coal_thickness > 0
ORDER BY stripping_ratio;

-- 12. ตรวจสอบความสมบูรณ์ของข้อมูล
SELECT 
    'Total Holes' as category,
    COUNT(DISTINCT hole_id) as count
FROM collars
UNION ALL
SELECT 
    'Holes with Lithology',
    COUNT(DISTINCT hole_id)
FROM lithology_logs
UNION ALL
SELECT 
    'Holes with Samples',
    COUNT(DISTINCT hole_id)
FROM sample_analyses
UNION ALL
SELECT 
    'Total Samples',
    COUNT(*)
FROM sample_analyses
WHERE ash IS NOT NULL;

-- 13. หาหลุมเจาะที่มีข้อมูลไม่สมบูรณ์
SELECT 
    c.hole_id,
    c.total_depth,
    COALESCE(l.log_count, 0) as lithology_count,
    COALESCE(s.sample_count, 0) as sample_count
FROM collars c
LEFT JOIN (
    SELECT hole_id, COUNT(*) as log_count
    FROM lithology_logs
    GROUP BY hole_id
) l ON c.hole_id = l.hole_id
LEFT JOIN (
    SELECT hole_id, COUNT(*) as sample_count
    FROM sample_analyses
    WHERE ash IS NOT NULL
    GROUP BY hole_id
) s ON c.hole_id = s.hole_id
WHERE l.log_count IS NULL OR s.sample_count IS NULL
ORDER BY c.hole_id;

-- 14. วิเคราะห์แนวโน้มคุณภาพถ่านหินตามความลึก
SELECT 
    CASE 
        WHEN depth_from < 20 THEN '0-20m'
        WHEN depth_from < 50 THEN '20-50m'
        WHEN depth_from < 100 THEN '50-100m'
        WHEN depth_from < 200 THEN '100-200m'
        ELSE '>200m'
    END as depth_range,
    COUNT(*) as sample_count,
    ROUND(AVG(ash), 2) as avg_ash,
    ROUND(AVG(gross_cv), 0) as avg_cv,
    ROUND(AVG(sulphur), 2) as avg_sulphur
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

-- 15. สร้าง View สำหรับการรายงานคุณภาพถ่านหิน
CREATE VIEW IF NOT EXISTS coal_quality_summary AS
SELECT 
    c.hole_id,
    c.easting,
    c.northing,
    c.elevation,
    c.total_depth,
    c.year_drilled,
    c.geologist,
    COUNT(DISTINCT s.sample_id) as total_samples,
    ROUND(AVG(s.ash), 2) as avg_ash,
    ROUND(MIN(s.ash), 2) as min_ash,
    ROUND(MAX(s.ash), 2) as max_ash,
    ROUND(AVG(s.gross_cv), 0) as avg_cv,
    ROUND(MIN(s.gross_cv), 0) as min_cv,
    ROUND(MAX(s.gross_cv), 0) as max_cv,
    ROUND(AVG(s.sulphur), 2) as avg_sulphur,
    ROUND(
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

-- การใช้ View
SELECT * FROM coal_quality_summary
WHERE avg_ash < 30 AND avg_cv > 2500
ORDER BY total_coal_thickness DESC;
