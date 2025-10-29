# Coal Drilling Database - Normalized Best Practice

## Overview
This is a normalized coal drilling database following best practices for mining data management. The database contains drilling hole data, sample analyses, seam classifications, and lithology information.

## Quick Start

### 1. Create Normalized Data
```bash
python create_drilling_database.py
```

### 2. Create Database
```bash
sqlite3 drilling_database.db < sql/create_drilling_database_schema.sql
```

### 3. Load Data
```bash
sqlite3 drilling_database.db < sql/load_drilling_database_data.sql
```

## Project Structure

```
data/
├── drilling_database/        # ✅ FINAL DATABASE DATA
│   ├── sample_analyses.csv            (8,592 records)
│   ├── seam_codes_lookup.csv          (399 records)
│   ├── rock_codes_lookup.csv           (28 records)
│   ├── collars.csv                     (70 records)
│   ├── lithology_logs.csv              (6,598 records)
│   └── rock_types.csv                  (19 records)
└── raw/                          # ✅ SOURCE DATA
    └── DH70.xlsx

sql/
├── create_drilling_database_schema.sql    # ✅ FINAL SCHEMA
└── load_drilling_database_data.sql      # ✅ DATA LOADER

docs/
└── BEST_PRACTICES.md                  # ✅ COMPLETE DOCUMENTATION

create_drilling_database.py  # ✅ MAIN SCRIPT
```

## Key Features

- **Data Normalization (3NF)**: All lookup data in separate tables
- **Foreign Key Relationships**: Proper referential integrity
- **Data Validation**: Constraints for depth and percentages
- **Performance Optimization**: Indexes on frequently queried columns
- **Mining Industry Standards**: Multiple seam classification systems

## Database Schema

### Core Tables
- `collars` - Drilling hole locations and basic information
- `lithology_logs` - Detailed lithology for each depth interval
- `sample_analyses` - Laboratory analysis results with foreign key relationships

### Lookup Tables
- `seam_codes_lookup` - All seam codes from 6 classification systems (30, 46, 57, 58, Quality, 73)
- `rock_codes_lookup` - Standard rock/lithology codes
- `rock_types` - Rock type classifications

### Views
- `sample_analyses_complete` - Samples with seam information
- `sample_analyses_with_location` - Samples with collar coordinates
- `holes_complete` - Complete hole information with statistics
- `seam_summary_by_hole` - Seam summaries grouped by hole

## Data Statistics

- **Total samples**: 8,592
- **Samples with Quality seam codes**: 3,812
- **Samples with 73 seam codes**: 5,443
- **Drilling holes**: 70
- **Lithology log entries**: 6,598
- **Seam codes**: 399 (from 6 systems)
- **Rock codes**: 28

## Usage Examples

### Query samples by seam code
```sql
SELECT * FROM sample_analyses_complete
WHERE quality_seam_label = 'H3c';
```

### Query samples by hole with location
```sql
SELECT * FROM sample_analyses_with_location
WHERE hole_id = 'BC01C';
```

### Get seam summary
```sql
SELECT * FROM seam_summary_by_hole
WHERE hole_id = 'BC01C';
```

## Best Practices Applied

✅ **Data Normalization (3NF)**
✅ **Foreign Key Relationships**
✅ **Data Validation Constraints**
✅ **Performance Indexes**
✅ **Mining Industry Standards**
✅ **Referential Integrity**

## Files to Use

**For Creating Normalized Data:**
- `create_drilling_database.py` - Run this first

**For Database Creation:**
- `sql/create_drilling_database_schema.sql`
- `sql/load_drilling_database_data.sql`

**For Data Access:**
- `data/drilling_database/` (all CSV files)

**For Documentation:**
- `docs/BEST_PRACTICES.md`
- `FINAL_DATABASE_SUMMARY.md`

## Dependencies

- Python 3.8+
- Polars
- SQLite3
- openpyxl (for Excel processing)

## WSL Migration

This project can be run in WSL (Windows Subsystem for Linux) for better performance and Linux compatibility.

### Quick WSL Setup
```bash
# 1. Copy project to WSL
cp -r C:\mySources\Code\Hongsa ~/drilling_database

# 2. Open WSL terminal
wsl
cd ~/drilling_database

# 3. Run setup script
chmod +x wsl_setup.sh
./wsl_setup.sh

# 4. Test the setup
./wsl_test.sh
```

### Manual WSL Setup
```bash
# Install dependencies
sudo apt update
sudo apt install python3 python3-pip python3-venv sqlite3

# Create virtual environment
python3 -m venv drilling_env
source drilling_env/bin/activate

# Install packages
pip install polars openpyxl

# Run project
python3 create_drilling_database.py
```

See `WSL_MIGRATION_GUIDE.md` for detailed instructions.

## Status
✅ **FINAL VERSION - Ready for Production Use**

---
*This database follows best practices for coal drilling data management with proper normalization and referential integrity.*