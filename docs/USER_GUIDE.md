# Hongsa Drilling Database - User Guide

## 📖 Table of Contents

1. [Introduction](#introduction)
2. [Quick Start](#quick-start)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Basic Usage](#basic-usage)
6. [Data Processing](#data-processing)
7. [Database Operations](#database-operations)
8. [Troubleshooting](#troubleshooting)
9. [FAQ](#faq)

## Introduction

The Hongsa Drilling Database is a comprehensive system for managing coal drilling data. It uses Pandas for data processing and supports both SQLite and Microsoft SQL Server databases.

### Key Features

- ✅ **Dual Database Support**: SQLite (local) and SQL Server (enterprise)
- ✅ **Data Processing**: Clean and validate drilling data
- ✅ **Excel Integration**: Read from Excel files directly
- ✅ **Flexible Export**: CSV, Excel, and direct database export
- ✅ **Configuration Management**: Easy setup via `.env` file
- ✅ **Comprehensive Logging**: Track all operations

## Quick Start

### 1. Setup (One-time)

```bash
# Clone or download the project
cd Hongsa

# Run setup script
./setup.sh

# Activate virtual environment
source .venv/bin/activate
```

### 2. Basic Usage

```bash
# Process Excel file to SQLite
python src/data_processing/clean_and_create_db.py

# Export to SQL Server (if configured)
python src/data_processing/export_sqlite_to_csv.py
```

### 3. Verify Installation

```bash
# Test the installation
python create_proper_normalized_database.py
```

## Installation

### Prerequisites

- Python 3.8 or higher
- Windows, Linux, or macOS
- For SQL Server: ODBC Driver 17 for SQL Server

### Step-by-Step Installation

#### 1. Download Project

```bash
# If using git
git clone <repository-url>
cd Hongsa

# Or download and extract ZIP file
```

#### 2. Create Virtual Environment

```bash
# Create virtual environment
python3 -m venv .venv

# Activate (Linux/macOS)
source .venv/bin/activate

# Activate (Windows)
.venv\Scripts\activate
```

#### 3. Install Dependencies

```bash
# Install required packages
pip install -r requirements.txt
```

#### 4. Configure Environment

```bash
# Copy configuration template
cp .env.example .env

# Edit configuration
nano .env  # or use your preferred editor
```

#### 5. Test Installation

```bash
# Run the main script
python create_proper_normalized_database.py

# Expected output: Database normalization completed successfully
```

## Configuration

### Environment Variables (.env)

The system uses `.env` file for configuration. Here are the key settings:

#### Database Configuration

```bash
# SQLite (Local Development)
SQLITE_DB_PATH=data/drilling_database.db

# SQL Server (Enterprise)
SQL_SERVER_ENABLED=false
SQL_SERVER_HOST=localhost
SQL_SERVER_DATABASE=drilling_database
SQL_SERVER_TRUSTED_CONNECTION=true
```

#### Data Paths

```bash
DATA_RAW_DIR=data/raw
DATA_PROCESSED_DIR=data/processed
EXCEL_FILE_PATH=data/raw/DH70.xlsx
```

#### Logging

```bash
LOG_LEVEL=INFO
LOG_FILE=logs/hongsa_drilling.log
```

### SQL Server Setup (Optional)

If you want to use SQL Server:

1. **Install ODBC Driver**:
   - Download from Microsoft
   - Install "ODBC Driver 17 for SQL Server"

2. **Configure Connection**:
   ```bash
   # Edit .env file
   SQL_SERVER_ENABLED=true
   SQL_SERVER_HOST=your-server
   SQL_SERVER_DATABASE=drilling_database
   SQL_SERVER_TRUSTED_CONNECTION=true
   ```

3. **Test Connection**:
   ```bash
   python sql_server_setup.py
   ```

## Basic Usage

### 1. Process Excel Data

```python
from src.data_processing.clean_and_create_db import clean_and_create_db

# Process Excel file to SQLite
clean_and_create_db(
    excel_path="data/raw/DH70.xlsx",
    db_path="data/drilling_database.db"
)
```

### 2. Export to SQL Server

```python
from src.data_processing.export_sqlite_to_csv import export_to_sql_server

# Export SQLite to SQL Server
export_to_sql_server(
    db_path="data/drilling_database.db",
    sql_server_config={
        "server": "localhost",
        "database": "drilling_database",
        "trusted_connection": True
    }
)
```

### 3. Direct Excel to SQL Server

```python
from src.data_processing.export_sqlite_to_csv import direct_sql_server_export

# Direct Excel to SQL Server
direct_sql_server_export(
    excel_path="data/raw/DH70.xlsx",
    sql_server_config={
        "server": "localhost",
        "database": "drilling_database",
        "trusted_connection": True
    }
)
```

## Data Processing

### Data Cleaning

The system automatically cleans data during processing:

- **Negative Values**: Converts -1 to NULL (common in drilling data)
- **String Cleaning**: Removes extra spaces and invalid characters
- **Type Conversion**: Ensures proper data types
- **Null Handling**: Standardizes null values

### Data Validation

```python
from src.data_processing.core import DataProcessor

processor = DataProcessor()

# Load and clean data
df = processor.process_excel_file("data/raw/DH70.xlsx")
df_cleaned = processor.clean_data(df)

# Validate data
validation = processor.validate_data(df_cleaned)
if validation['is_valid']:
    print("Data is valid")
else:
    print(f"Errors: {validation['errors']}")
```

### Data Summary

```python
# Get comprehensive data summary
summary = processor.get_data_summary(df_cleaned)
print(f"Shape: {summary['shape']}")
print(f"Memory usage: {summary['memory_usage']} bytes")
print(f"Null counts: {summary['null_counts']}")
```

## Database Operations

### SQLite Operations

```python
from src.data_processing.database_manager import create_sqlite_manager

# Create SQLite manager
sqlite_manager = create_sqlite_manager("data/drilling_database.db")

# Connect
if sqlite_manager.connect():
    # Read data
    df = sqlite_manager.read_table("collars")
    
    # Write data
    sqlite_manager.write_table(df, "new_table")
    
    # Execute SQL
    sqlite_manager.execute_sql("CREATE INDEX idx_hole_id ON collars(hole_id)")
    
    # Disconnect
    sqlite_manager.disconnect()
```

### SQL Server Operations

```python
from src.data_processing.database_manager import create_sql_server_manager

# Create SQL Server manager
config = {
    "server": "localhost",
    "database": "drilling_database",
    "trusted_connection": True
}
sql_server_manager = create_sql_server_manager(config)

# Connect and use (same interface as SQLite)
if sql_server_manager.connect():
    df = sql_server_manager.read_table("collars")
    sql_server_manager.write_table(df, "new_table")
    sql_server_manager.disconnect()
```

### Unified Database Management

```python
from src.data_processing.database_manager import create_unified_manager

# Create unified manager
unified_manager = create_unified_manager(sqlite_manager, sql_server_manager)

# Connect to both databases
if unified_manager.connect():
    # Sync tables between databases
    unified_manager.sync_tables(["collars", "lithology_logs"])
    
    # Backup to CSV
    unified_manager.backup_to_csv(["collars"], "backup/")
    
    unified_manager.disconnect()
```

## Command Line Usage

### Process Data

```bash
# Process Excel to SQLite
python src/data_processing/clean_and_create_db.py

# Export to CSV
python src/data_processing/export_sqlite_to_csv.py

# Setup SQL Server
# Run the SQL Server schema script
sqlcmd -S your_server -d your_database -i sql/create_sql_server_schema.sql

# Test installation
python create_proper_normalized_database.py
```

### Using Configuration

```bash
# Set environment variables
export SQL_SERVER_ENABLED=true
export SQL_SERVER_HOST=your-server

# Run with environment variables
python your_script.py
```

## Data Export Options

### 1. CSV Export

```python
from src.data_processing.core import DataProcessor

processor = DataProcessor()
df = processor.process_excel_file("data/raw/DH70.xlsx")

# Export to CSV
processor.export_to_csv(df, "output/data.csv")
```

### 2. Excel Export

```python
# Export to Excel
df.to_excel("output/data.xlsx", index=False)
```

### 3. Database Export

```python
# Export to SQLite
sqlite_manager.write_table(df, "table_name")

# Export to SQL Server
sql_server_manager.write_table(df, "table_name")
```

## Monitoring and Logging

### Log Files

Logs are automatically created in `logs/hongsa_drilling.log`:

```
2024-01-15 10:30:15 - INFO - Processing Excel file: data/raw/DH70.xlsx
2024-01-15 10:30:16 - INFO - Data cleaning completed: (15400, 34)
2024-01-15 10:30:17 - INFO - Connected to SQLite: data/drilling_database.db
2024-01-15 10:30:18 - INFO - Data written to table: drilling_data (15400 rows)
```

### Log Levels

- **DEBUG**: Detailed information for debugging
- **INFO**: General information about operations
- **WARNING**: Something unexpected happened
- **ERROR**: An error occurred

### Configure Logging

```python
import logging

# Set log level
logging.basicConfig(level=logging.DEBUG)

# Or in .env file
LOG_LEVEL=DEBUG
```

## Troubleshooting

### Common Issues

#### 1. Import Errors

**Problem**: `ModuleNotFoundError: No module named 'pandas'`

**Solution**:
```bash
# Activate virtual environment
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

#### 2. SQL Server Connection Failed

**Problem**: `Connection failed: [ODBC Driver 17 for SQL Server]`

**Solutions**:
- Install ODBC Driver 17 for SQL Server
- Check SQL Server is running
- Verify connection parameters in `.env`
- Test connection: `python sql_server_setup.py`

#### 3. Excel File Not Found

**Problem**: `FileNotFoundError: Excel file not found`

**Solutions**:
- Check file path in `.env`: `EXCEL_FILE_PATH`
- Ensure file exists: `ls data/raw/DH70.xlsx`
- Check file permissions

#### 4. Memory Issues

**Problem**: `MemoryError` with large datasets

**Solutions**:
- Use chunking: Set `CHUNK_SIZE=1000` in `.env`
- Process data in smaller batches
- Increase system memory
- Use SQL Server instead of SQLite for large datasets

#### 5. Permission Denied

**Problem**: `PermissionError: [Errno 13] Permission denied`

**Solutions**:
- Check file/directory permissions
- Run with appropriate user privileges
- Ensure write access to output directories

### Debug Mode

Enable debug mode for detailed troubleshooting:

```bash
# Set in .env
DEBUG_MODE=true
LOG_LEVEL=DEBUG

# Or in code
import logging
logging.basicConfig(level=logging.DEBUG)
```

### Getting Help

1. **Check Logs**: Look at console output
2. **Run Script**: `python create_proper_normalized_database.py`
3. **Check Configuration**: Verify data files exist
4. **Review Documentation**: Check `docs/` folder

## FAQ

### Q: Can I use this without SQL Server?

**A**: Yes! The system works perfectly with SQLite only. Set `SQL_SERVER_ENABLED=false` in `.env`.

### Q: How do I process multiple Excel files?

**A**: Use a loop or batch processing:

```python
import glob
from src.data_processing.core import DataProcessor

processor = DataProcessor()

for excel_file in glob.glob("data/raw/*.xlsx"):
    df = processor.process_excel_file(excel_file)
    # Process each file
```

### Q: Can I customize data cleaning?

**A**: Yes! Modify the `clean_data` function in `src/data_processing/core.py` or create your own cleaning logic.

### Q: How do I backup my data?

**A**: Use the built-in backup functionality:

```python
from src.data_processing.database_manager import create_unified_manager

unified_manager = create_unified_manager(primary_db, secondary_db)
unified_manager.backup_to_csv(["collars", "lithology_logs"], "backup/")
```

### Q: What's the difference between SQLite and SQL Server?

**A**: 
- **SQLite**: Local file database, good for development and small datasets
- **SQL Server**: Enterprise database, good for production and large datasets

### Q: How do I update the system?

**A**: 
1. Backup your data
2. Pull latest changes
3. Update dependencies: `pip install -r requirements.txt`
4. Test: `python create_proper_normalized_database.py`

### Q: Can I use this on Windows?

**A**: Yes! The system works on Windows, Linux, and macOS. Use `.venv\Scripts\activate` on Windows.

---

## Support

For additional help:

1. Check the documentation in `docs/` folder
2. Review the API reference: `docs/API_REFERENCE.md`
3. Check configuration guide: `docs/ENVIRONMENT_CONFIG.md`
4. Run the main script: `python create_proper_normalized_database.py`

---

**Last Updated**: January 2024  
**Version**: 2.0.0

