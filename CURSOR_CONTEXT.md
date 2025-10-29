# Cursor Context - Coal Drilling Database

## Project Overview
This is a **normalized coal drilling database** following best practices for mining data management. The project has been **fully completed** and is ready for production use.

## Key Information for Cursor

### 🎯 **Main Purpose**
- Store and manage coal drilling data with proper normalization
- Support multiple seam classification systems (30, 46, 57, 58, Quality, 73)
- Provide efficient querying with proper foreign key relationships

### 📁 **File Structure (FINAL)**
```
data/
├── normalized_best_practice/     # ✅ FINAL NORMALIZED DATA
│   ├── sample_analyses_normalized.csv    (8,592 records)
│   ├── seam_codes_lookup.csv             (399 records)
│   ├── rock_codes_lookup.csv             (28 records)
│   ├── collars.csv                       (70 records)
│   ├── lithology_logs.csv                (6,598 records)
│   └── rock_types.csv                    (19 records)
└── raw/                          # ✅ SOURCE DATA
    └── DH70.xlsx

sql/
├── create_best_practice_schema.sql    # ✅ FINAL SCHEMA
└── load_best_practice_data.sql        # ✅ DATA LOADER

docs/
└── BEST_PRACTICES.md                  # ✅ COMPLETE DOCUMENTATION

create_best_practice_normalization.py  # ✅ MAIN SCRIPT
```

### 🔧 **Main Script**
- **`create_best_practice_normalization.py`** - The ONLY Python script you need
- This script creates all normalized CSV files from the Excel source
- Run this first before creating the database

### 🗄️ **Database Schema**
- **SQLite database** (not SQL Server)
- **Normalized to 3NF** with proper foreign keys
- **6 lookup systems** for seam codes
- **Performance indexes** on frequently queried columns

### 📊 **Data Flow**
1. **Source**: `data/raw/DH70.xlsx` (Excel file with worksheets)
2. **Processing**: `create_best_practice_normalization.py` extracts and normalizes data
3. **Output**: `data/normalized_best_practice/` (normalized CSV files)
4. **Database**: SQLite database with proper schema

### 🎯 **Key Tables**
- `sample_analyses_normalized` - Main table with lab results
- `seam_codes_lookup` - All seam codes from 6 systems
- `rock_codes_lookup` - Rock/lithology codes
- `collars` - Drilling hole locations
- `lithology_logs` - Detailed lithology information

### 🔍 **Important Notes**
- **DO NOT** create new normalization scripts - use the existing one
- **DO NOT** modify the schema - it's already optimized
- **DO NOT** create duplicate data - everything is normalized
- **USE** the existing views for complex queries

### 📈 **Data Statistics**
- **Total samples**: 8,592
- **Samples with Quality seam codes**: 3,812
- **Samples with 73 seam codes**: 5,443
- **Drilling holes**: 70
- **Seam codes**: 399 (from 6 systems)

### 🚀 **Quick Commands**
```bash
# Create normalized data
python create_best_practice_normalization.py

# Create database
sqlite3 drilling_database.db < sql/create_best_practice_schema.sql

# Load data
sqlite3 drilling_database.db < sql/load_best_practice_data.sql
```

### ⚠️ **What NOT to Do**
- Don't create new Python scripts for normalization
- Don't modify the existing schema
- Don't create duplicate data structures
- Don't use SQL Server - this is SQLite
- Don't create new lookup tables - they already exist

### ✅ **What TO Do**
- Use the existing normalized data
- Query using the provided views
- Follow the best practices documentation
- Use the existing Python script for data updates

### 🔗 **Related Files**
- `README.md` - Project overview
- `FINAL_DATABASE_SUMMARY.md` - Complete summary
- `docs/BEST_PRACTICES.md` - Detailed best practices
- `sql/create_best_practice_schema.sql` - Database schema
- `sql/load_best_practice_data.sql` - Data loader

### 🎯 **Project Status**
✅ **COMPLETED** - Ready for production use
✅ **NORMALIZED** - Following best practices
✅ **OPTIMIZED** - Performance indexes included
✅ **DOCUMENTED** - Complete documentation available

---
*This context file helps Cursor understand the project structure and avoid recreating existing functionality.*
