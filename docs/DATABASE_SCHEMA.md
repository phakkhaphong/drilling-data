# Database Schema Documentation

## Overview
This document describes the normalized database schema for the coal drilling system.

## Database Type
- **SQLite** (not SQL Server)
- **Normalized to 3NF** (Third Normal Form)
- **Foreign Key Relationships** for data integrity

## Table Structure

### 1. Lookup Tables

#### `seam_codes_lookup`
- **Purpose**: All seam codes from different classification systems
- **Records**: 399
- **Systems**: 30, 46, 57, 58, Quality, 73

| Column | Type | Description |
|--------|------|-------------|
| seam_id | INTEGER PRIMARY KEY | Unique identifier |
| system_id | VARCHAR(20) | System identifier (30, 46, 57, 58, Quality, 73) |
| system_name | VARCHAR(50) | System name |
| seam_label | VARCHAR(50) | Seam label (e.g., H3c, I2a) |
| seam_code | INTEGER | Seam code number |
| description | TEXT | Optional description |
| created_at | TIMESTAMP | Creation timestamp |

#### `rock_codes_lookup`
- **Purpose**: Standard rock/lithology codes
- **Records**: 28

| Column | Type | Description |
|--------|------|-------------|
| rock_id | INTEGER PRIMARY KEY | Unique identifier |
| rock_code | INTEGER UNIQUE | Rock code number |
| lithology | VARCHAR(20) | Lithology code (e.g., CBCL, CL) |
| detail | VARCHAR(100) | Detailed description |
| created_at | TIMESTAMP | Creation timestamp |

#### `rock_types`
- **Purpose**: Rock type classifications
- **Records**: 19

| Column | Type | Description |
|--------|------|-------------|
| rock_type_id | INTEGER PRIMARY KEY | Unique identifier |
| rock_code | INTEGER | Foreign key to rock_codes_lookup |
| rock_type | VARCHAR(50) | Rock type name |

### 2. Core Tables

#### `collars`
- **Purpose**: Drilling hole collar information
- **Records**: 70

| Column | Type | Description |
|--------|------|-------------|
| collar_id | INTEGER PRIMARY KEY | Unique identifier |
| hole_id | VARCHAR(50) UNIQUE | Hole identifier (e.g., BC01C) |
| easting | REAL | Easting coordinate |
| northing | REAL | Northing coordinate |
| elevation | REAL | Elevation above sea level |
| azimuth | REAL | Drilling azimuth |
| dip | REAL | Drilling dip |
| final_depth | REAL | Final hole depth |
| drilling_date | DATE | Date drilled |
| contractor | VARCHAR(100) | Drilling contractor |
| remarks | TEXT | Additional remarks |
| created_at | TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | Last update timestamp |

#### `lithology_logs`
- **Purpose**: Detailed lithology information for each depth interval
- **Records**: 6,598

| Column | Type | Description |
|--------|------|-------------|
| log_id | INTEGER PRIMARY KEY | Unique identifier |
| hole_id | VARCHAR(50) | Foreign key to collars |
| depth_from | REAL | Starting depth (meters) |
| depth_to | REAL | Ending depth (meters) |
| rock_code | INTEGER | Foreign key to rock_codes_lookup |
| description | TEXT | Lithology description |

**Constraints:**
- `depth_to > depth_from`
- Foreign key to `collars(hole_id)`
- Foreign key to `rock_codes_lookup(rock_code)`

#### `sample_analyses_normalized`
- **Purpose**: Laboratory analysis results for coal samples
- **Records**: 8,592

| Column | Type | Description |
|--------|------|-------------|
| sample_id | INTEGER PRIMARY KEY | Unique identifier |
| hole_id | VARCHAR(50) | Foreign key to collars |
| depth_from | REAL | Starting depth (meters) |
| depth_to | REAL | Ending depth (meters) |
| sample_no | VARCHAR(50) | Sample number |
| im | REAL | Inherent Moisture (%) |
| tm | REAL | Total Moisture (%) |
| ash | REAL | Ash Content (%) |
| vm | REAL | Volatile Matter (%) |
| fc | REAL | Fixed Carbon (%) |
| sulphur | REAL | Sulphur Content (%) |
| gross_cv | REAL | Gross Calorific Value (kcal/kg) |
| net_cv | REAL | Net Calorific Value (kcal/kg) |
| sg | REAL | Specific Gravity |
| rd | REAL | Relative Density |
| hgi | REAL | Hardgrove Grindability Index |
| seam_code_quality_original | REAL | Original quality seam code |
| seam_quality_id | INTEGER | Foreign key to seam_codes_lookup (Quality) |
| seam_73_id | INTEGER | Foreign key to seam_codes_lookup (73) |
| analysis_date | DATE | Analysis date |
| lab_name | VARCHAR(100) | Laboratory name |
| remarks | TEXT | Additional remarks |
| created_at | TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | Last update timestamp |

**Constraints:**
- `depth_to > depth_from`
- `ash >= 0 AND ash <= 100`
- `vm >= 0 AND vm <= 100`
- `fc >= 0 AND fc <= 100`
- `im >= 0 AND im <= 100`
- `tm >= 0 AND tm <= 100`
- Foreign key to `collars(hole_id)`
- Foreign key to `seam_codes_lookup(seam_id)` (Quality)
- Foreign key to `seam_codes_lookup(seam_id)` (73)

## Indexes

### Performance Indexes
- `idx_collars_hole_id` ON collars(hole_id)
- `idx_collars_location` ON collars(easting, northing)
- `idx_lithology_hole_id` ON lithology_logs(hole_id)
- `idx_lithology_depth` ON lithology_logs(hole_id, depth_from, depth_to)
- `idx_lithology_rock_code` ON lithology_logs(rock_code)
- `idx_sample_analyses_hole_id` ON sample_analyses_normalized(hole_id)
- `idx_sample_analyses_depth` ON sample_analyses_normalized(hole_id, depth_from, depth_to)
- `idx_sample_analyses_seam_quality` ON sample_analyses_normalized(seam_quality_id)
- `idx_sample_analyses_seam_73` ON sample_analyses_normalized(seam_73_id)
- `idx_sample_analyses_sample_no` ON sample_analyses_normalized(hole_id, sample_no)

### Lookup Indexes
- `idx_seam_codes_system` ON seam_codes_lookup(system_id)
- `idx_seam_codes_code` ON seam_codes_lookup(seam_code)
- `idx_seam_codes_label` ON seam_codes_lookup(seam_label)
- `idx_rock_codes_code` ON rock_codes_lookup(rock_code)
- `idx_rock_codes_lithology` ON rock_codes_lookup(lithology)

## Views

### `sample_analyses_complete`
Joins sample analyses with seam information from both systems.

### `sample_analyses_with_location`
Joins sample analyses with collar location data.

### `holes_complete`
Complete hole information with sample and log counts.

### `seam_summary_by_hole`
Seam summaries grouped by hole with statistics.

## Data Relationships

```
collars (1) -----> (many) lithology_logs
collars (1) -----> (many) sample_analyses_normalized
rock_codes_lookup (1) -----> (many) lithology_logs
rock_codes_lookup (1) -----> (many) rock_types
seam_codes_lookup (1) -----> (many) sample_analyses_normalized (Quality)
seam_codes_lookup (1) -----> (many) sample_analyses_normalized (73)
```

## Best Practices Applied

1. **Normalization**: All lookup data in separate tables
2. **Foreign Keys**: Proper referential integrity
3. **Constraints**: Data validation rules
4. **Indexes**: Performance optimization
5. **Views**: Complex query simplification
6. **Documentation**: Complete table and column descriptions
