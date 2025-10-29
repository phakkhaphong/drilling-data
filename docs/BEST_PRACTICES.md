# Coal Drilling Database - Best Practices Documentation

## Overview
This database follows best practices for coal drilling data management, ensuring data integrity, normalization, and efficient querying.

## Database Structure

### 1. Lookup Tables
- **seam_codes_lookup**: All seam classification codes from different systems (30, 46, 57, 58, Quality, 73)
- **rock_codes_lookup**: Standard rock/lithology codes
- **rock_types**: Rock type classifications

### 2. Core Tables
- **collars**: Drilling hole collar locations and basic information
- **lithology_logs**: Detailed lithology information for each depth interval
- **sample_analyses_normalized**: Laboratory analysis results with normalized foreign keys

## Key Features

### Normalization
- All seam codes are stored in lookup tables
- Foreign keys ensure referential integrity
- No data duplication
- Easy to maintain and update

### Data Validation
- Depth constraints (depth_to > depth_from)
- Percentage constraints (0-100 for ash, vm, fc, etc.)
- Foreign key constraints ensure data consistency

### Performance Optimization
- Indexes on commonly queried columns:
  - hole_id (primary identifier)
  - depth ranges (for interval queries)
  - seam codes (for filtering)
  - Location coordinates (for spatial queries)

### Views
- `sample_analyses_complete`: Samples with seam information
- `sample_analyses_with_location`: Samples with collar coordinates
- `holes_complete`: Complete hole information with statistics
- `seam_summary_by_hole`: Seam summaries grouped by hole

## Best Practices Applied

### 1. Data Normalization
- ✅ All lookup data in separate tables
- ✅ Foreign keys instead of duplicate data
- ✅ Normalized to 3NF (Third Normal Form)

### 2. Data Integrity
- ✅ Foreign key constraints
- ✅ Check constraints for data validation
- ✅ Unique constraints where appropriate
- ✅ NOT NULL constraints for required fields

### 3. Performance
- ✅ Indexes on foreign keys
- ✅ Indexes on frequently queried columns
- ✅ Composite indexes for common query patterns

### 4. Maintainability
- ✅ Clear table and column names
- ✅ Documentation comments
- ✅ Consistent naming conventions
- ✅ Views for complex queries

### 5. Mining Industry Standards
- ✅ Depth intervals properly tracked
- ✅ Multiple seam classification systems supported
- ✅ Laboratory analysis parameters stored correctly
- ✅ Collar location data included
- ✅ Lithology information linked

## Usage Examples

### Query samples by seam code:
```sql
SELECT * FROM sample_analyses_complete
WHERE quality_seam_label = 'H3c';
```

### Query samples by hole with location:
```sql
SELECT * FROM sample_analyses_with_location
WHERE hole_id = 'BC01C';
```

### Get seam summary:
```sql
SELECT * FROM seam_summary_by_hole
WHERE hole_id = 'BC01C';
```

### Query samples within depth range:
```sql
SELECT * FROM sample_analyses_normalized
WHERE hole_id = 'BC01C'
  AND depth_from >= 4.0
  AND depth_to <= 10.0;
```

## Data Flow

1. **Raw Data**: DH70.xlsx (Excel file)
2. **Lookup Extraction**: Seam codes and rock codes extracted from worksheets
3. **Normalization**: Sample analyses linked to lookup tables via foreign keys
4. **Storage**: Normalized CSV files ready for database import
5. **Database**: SQLite database with proper schema and constraints

## Maintenance

- Update lookup tables when new seam codes or rock codes are added
- Maintain referential integrity when updating sample analyses
- Use transactions for batch updates
- Regular backups of normalized data

## References

- Coal Quality Standards (ASTM, ISO)
- Mining Data Management Best Practices
- Database Normalization Principles
- Spatial Data Management for Mining
