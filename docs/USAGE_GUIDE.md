# Usage Guide - Coal Drilling Database

## Quick Start

### 1. Prerequisites
- Python 3.8+
- SQLite3
- Required Python packages: `polars`, `openpyxl`

### 2. Create Normalized Data
```bash
python create_best_practice_normalization.py
```
This creates all normalized CSV files in `data/normalized_best_practice/`

### 3. Create Database
```bash
sqlite3 drilling_database.db < sql/create_best_practice_schema.sql
```

### 4. Load Data
```bash
sqlite3 drilling_database.db < sql/load_best_practice_data.sql
```

## Common Queries

### 1. View All Samples with Seam Information
```sql
SELECT * FROM sample_analyses_complete LIMIT 10;
```

### 2. Query Samples by Hole
```sql
SELECT * FROM sample_analyses_with_location
WHERE hole_id = 'BC01C';
```

### 3. Get Seam Summary by Hole
```sql
SELECT * FROM seam_summary_by_hole
WHERE hole_id = 'BC01C';
```

### 4. Query Samples by Seam Code
```sql
SELECT * FROM sample_analyses_complete
WHERE quality_seam_label = 'H3c';
```

### 5. Query Samples by Depth Range
```sql
SELECT * FROM sample_analyses_normalized
WHERE hole_id = 'BC01C'
  AND depth_from >= 4.0
  AND depth_to <= 10.0;
```

### 6. Get Hole Statistics
```sql
SELECT * FROM holes_complete
WHERE hole_id = 'BC01C';
```

### 7. Query by Rock Type
```sql
SELECT ll.*, rcl.lithology, rcl.detail
FROM lithology_logs ll
JOIN rock_codes_lookup rcl ON ll.rock_code = rcl.rock_code
WHERE rcl.lithology = 'CL';
```

### 8. Get Seam Codes by System
```sql
SELECT system_id, COUNT(*) as count
FROM seam_codes_lookup
GROUP BY system_id
ORDER BY count DESC;
```

### 9. Query Samples with High Ash Content
```sql
SELECT * FROM sample_analyses_complete
WHERE ash > 50
ORDER BY ash DESC;
```

### 10. Get Average Quality by Seam
```sql
SELECT 
    quality_seam_label,
    COUNT(*) as sample_count,
    AVG(ash) as avg_ash,
    AVG(vm) as avg_vm,
    AVG(gross_cv) as avg_gross_cv
FROM sample_analyses_complete
WHERE quality_seam_label IS NOT NULL
GROUP BY quality_seam_label
ORDER BY avg_gross_cv DESC;
```

## Data Analysis Examples

### 1. Coal Quality Analysis
```sql
-- Analyze coal quality by seam
SELECT 
    quality_seam_label,
    COUNT(*) as samples,
    AVG(ash) as avg_ash,
    AVG(vm) as avg_vm,
    AVG(fc) as avg_fc,
    AVG(gross_cv) as avg_gross_cv,
    MIN(gross_cv) as min_gross_cv,
    MAX(gross_cv) as max_gross_cv
FROM sample_analyses_complete
WHERE quality_seam_label IS NOT NULL
GROUP BY quality_seam_label
ORDER BY avg_gross_cv DESC;
```

### 2. Depth Analysis
```sql
-- Analyze samples by depth intervals
SELECT 
    CASE 
        WHEN depth_from < 10 THEN '0-10m'
        WHEN depth_from < 20 THEN '10-20m'
        WHEN depth_from < 30 THEN '20-30m'
        ELSE '30m+'
    END as depth_interval,
    COUNT(*) as samples,
    AVG(ash) as avg_ash,
    AVG(gross_cv) as avg_gross_cv
FROM sample_analyses_normalized
GROUP BY depth_interval
ORDER BY depth_interval;
```

### 3. Hole Analysis
```sql
-- Analyze drilling holes
SELECT 
    c.hole_id,
    c.elevation,
    c.final_depth,
    COUNT(sa.sample_id) as sample_count,
    COUNT(ll.log_id) as log_count,
    MIN(sa.depth_from) as min_sample_depth,
    MAX(sa.depth_to) as max_sample_depth
FROM collars c
LEFT JOIN sample_analyses_normalized sa ON c.hole_id = sa.hole_id
LEFT JOIN lithology_logs ll ON c.hole_id = ll.hole_id
GROUP BY c.hole_id, c.elevation, c.final_depth
ORDER BY c.final_depth DESC;
```

## Data Export

### 1. Export Samples to CSV
```sql
.mode csv
.headers on
.output samples_export.csv
SELECT * FROM sample_analyses_complete;
```

### 2. Export Seam Summary
```sql
.mode csv
.headers on
.output seam_summary.csv
SELECT * FROM seam_summary_by_hole;
```

## Maintenance

### 1. Check Data Integrity
```sql
-- Check for invalid depth intervals
SELECT * FROM sample_analyses_normalized
WHERE depth_to <= depth_from;

-- Check for missing foreign keys
SELECT * FROM sample_analyses_normalized
WHERE seam_quality_id IS NOT NULL 
  AND seam_quality_id NOT IN (SELECT seam_id FROM seam_codes_lookup);
```

### 2. Update Statistics
```sql
-- Update table statistics
ANALYZE;
```

### 3. Backup Database
```bash
# Create backup
cp drilling_database.db drilling_database_backup.db

# Or export to SQL
sqlite3 drilling_database.db .dump > backup.sql
```

## Performance Tips

1. **Use Indexes**: Queries on indexed columns are much faster
2. **Use Views**: Use the provided views for complex queries
3. **Limit Results**: Use LIMIT for large result sets
4. **Filter Early**: Use WHERE clauses to reduce data early
5. **Use EXPLAIN**: Use EXPLAIN QUERY PLAN to analyze query performance

## Troubleshooting

### Common Issues

1. **Foreign Key Errors**: Check that referenced data exists
2. **Data Type Errors**: Ensure data types match schema
3. **Performance Issues**: Check if indexes are being used
4. **Memory Issues**: Use LIMIT for large queries

### Debug Queries

```sql
-- Check query plan
EXPLAIN QUERY PLAN SELECT * FROM sample_analyses_complete WHERE hole_id = 'BC01C';

-- Check table sizes
SELECT name, COUNT(*) as rows FROM sqlite_master WHERE type='table';
```

## Best Practices

1. **Always use transactions** for bulk operations
2. **Use prepared statements** for repeated queries
3. **Regular backups** of the database
4. **Monitor performance** with EXPLAIN QUERY PLAN
5. **Use views** for complex queries
6. **Validate data** before insertion
