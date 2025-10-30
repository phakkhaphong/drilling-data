# API Reference - Hongsa Drilling Database

## Overview

This document provides comprehensive API reference for the Hongsa Drilling Database system, which has been migrated from Polars to Pandas with full SQL Server support.

## Core Modules

### 1. Data Processing Core (`src.data_processing.core`)

#### `DataProcessor` Class

Main data processing class for drilling data operations.

```python
from src.data_processing.core import DataProcessor

# Initialize processor
processor = DataProcessor(config={'log_level': 'INFO'})
```

**Methods:**

##### `clean_data(df, replace_negative_with_null=True, clean_strings=True, handle_numeric_errors=True)`

Clean drilling data with comprehensive error handling.

**Parameters:**
- `df` (pd.DataFrame): Input DataFrame
- `replace_negative_with_null` (bool): Replace -1 values with NaN
- `clean_strings` (bool): Clean string columns
- `handle_numeric_errors` (bool): Handle numeric conversion errors

**Returns:**
- `pd.DataFrame`: Cleaned DataFrame

**Example:**
```python
df_cleaned = processor.clean_data(df)
```

##### `validate_data(df, required_columns=None, check_data_types=True)`

Validate data quality and completeness.

**Parameters:**
- `df` (pd.DataFrame): Input DataFrame
- `required_columns` (List[str]): List of required columns
- `check_data_types` (bool): Check for data type consistency

**Returns:**
- `Dict[str, Any]`: Validation results dictionary

**Example:**
```python
validation = processor.validate_data(df, required_columns=['hole_id', 'depth'])
if validation['is_valid']:
    print("Data is valid")
else:
    print(f"Errors: {validation['errors']}")
```

##### `process_excel_file(file_path, sheet_name=None)`

Process Excel file with error handling.

**Parameters:**
- `file_path` (Union[str, Path]): Path to Excel file
- `sheet_name` (Optional[Union[str, int]]): Sheet name or index to read

**Returns:**
- `pd.DataFrame`: Processed DataFrame

**Example:**
```python
df = processor.process_excel_file('data/raw/DH70.xlsx', sheet_name='DAT201')
```

##### `export_to_csv(df, output_path, index=False, encoding='utf-8')`

Export DataFrame to CSV with error handling.

**Parameters:**
- `df` (pd.DataFrame): DataFrame to export
- `output_path` (Union[str, Path]): Output file path
- `index` (bool): Include index in export
- `encoding` (str): File encoding

**Returns:**
- `bool`: Success status

**Example:**
```python
success = processor.export_to_csv(df, 'output/data.csv')
```

##### `get_data_summary(df)`

Get comprehensive data summary.

**Parameters:**
- `df` (pd.DataFrame): Input DataFrame

**Returns:**
- `Dict[str, Any]`: Summary dictionary

**Example:**
```python
summary = processor.get_data_summary(df)
print(f"Shape: {summary['shape']}")
print(f"Memory usage: {summary['memory_usage']} bytes")
```

### 2. Database Management (`src.data_processing.database_manager`)

#### `SQLiteManager` Class

SQLite database manager for local database operations.

```python
from src.data_processing.database_manager import SQLiteManager

# Initialize SQLite manager
sqlite_manager = SQLiteManager('drilling_database.db')
```

**Methods:**

##### `connect() -> bool`

Connect to SQLite database.

**Returns:**
- `bool`: Connection success status

##### `disconnect() -> None`

Disconnect from SQLite database.

##### `read_table(table_name, **kwargs) -> pd.DataFrame`

Read table from SQLite.

**Parameters:**
- `table_name` (str): Name of table to read
- `**kwargs`: Additional parameters (e.g., query)

**Returns:**
- `pd.DataFrame`: Table data

**Example:**
```python
df = sqlite_manager.read_table('collars')
# Or with custom query
df = sqlite_manager.read_table('collars', query='SELECT * FROM collars WHERE depth > 100')
```

##### `write_table(df, table_name, if_exists='replace', index=False, **kwargs) -> bool`

Write DataFrame to SQLite.

**Parameters:**
- `df` (pd.DataFrame): DataFrame to write
- `table_name` (str): Target table name
- `if_exists` (str): What to do if table exists ('replace', 'append', 'fail')
- `index` (bool): Include index in table
- `**kwargs`: Additional parameters

**Returns:**
- `bool`: Success status

**Example:**
```python
success = sqlite_manager.write_table(df, 'collars', if_exists='replace')
```

##### `execute_sql(query) -> bool`

Execute SQL query in SQLite.

**Parameters:**
- `query` (str): SQL query to execute

**Returns:**
- `bool`: Success status

##### `list_tables() -> List[str]`

List all tables in SQLite database.

**Returns:**
- `List[str]`: List of table names

#### `SQLServerManager` Class

SQL Server database manager for enterprise database operations.

```python
from src.data_processing.database_manager import SQLServerManager

# Initialize SQL Server manager
config = {
    'server': 'localhost',
    'database': 'drilling_database',
    'username': 'user',
    'password': 'pass',
    'trusted_connection': False
}
sql_server_manager = SQLServerManager(config)
```

**Methods:**

Same interface as `SQLiteManager` but for SQL Server operations.

#### `UnifiedDatabaseManager` Class

Unified database manager that can work with multiple database types.

```python
from src.data_processing.database_manager import UnifiedDatabaseManager

# Create unified manager
unified_manager = UnifiedDatabaseManager(primary_db, secondary_db)
```

**Methods:**

##### `sync_tables(table_names) -> bool`

Sync tables between primary and secondary databases.

**Parameters:**
- `table_names` (List[str]): List of table names to sync

**Returns:**
- `bool`: Success status

##### `backup_to_csv(table_names, output_dir) -> bool`

Backup tables to CSV files.

**Parameters:**
- `table_names` (List[str]): List of table names to backup
- `output_dir` (Union[str, Path]): Output directory for CSV files

**Returns:**
- `bool`: Success status

### 3. SQL Server Connection (`src.data_processing.sql_server_connection`)

#### `SQLServerConnection` Class

SQL Server connection utility with comprehensive database operations.

```python
from src.data_processing.sql_server_connection import SQLServerConnection

# Initialize connection
conn = SQLServerConnection(
    server='localhost',
    database='drilling_database',
    trusted_connection=True
)
```

**Methods:**

##### `connect() -> bool`

Establish connection to SQL Server.

**Returns:**
- `bool`: Connection success status

##### `disconnect() -> None`

Close connection.

##### `read_table(table_name, **kwargs) -> pd.DataFrame`

Read table from SQL Server.

**Parameters:**
- `table_name` (str): Name of table to read
- `**kwargs`: Additional parameters

**Returns:**
- `pd.DataFrame`: Table data

##### `write_table(df, table_name, if_exists='replace', index=False, chunksize=1000, **kwargs) -> bool`

Write DataFrame to SQL Server table.

**Parameters:**
- `df` (pd.DataFrame): DataFrame to write
- `table_name` (str): Target table name
- `if_exists` (str): What to do if table exists
- `index` (bool): Include index in table
- `chunksize` (int): Number of rows to write at a time
- `**kwargs`: Additional parameters

**Returns:**
- `bool`: Success status

##### `execute_sql(query) -> bool`

Execute SQL command.

**Parameters:**
- `query` (str): SQL query to execute

**Returns:**
- `bool`: Success status

##### `get_table_info(table_name) -> pd.DataFrame`

Get table schema information.

**Parameters:**
- `table_name` (str): Name of table

**Returns:**
- `pd.DataFrame`: Table schema information

##### `list_tables() -> pd.DataFrame`

List all tables in database.

**Returns:**
- `pd.DataFrame`: List of tables with metadata

## Convenience Functions

### Data Processing

```python
from src.data_processing.core import clean_data, validate_data, process_excel_file

# Clean data
df_cleaned = clean_data(df)

# Validate data
validation = validate_data(df, required_columns=['hole_id'])

# Process Excel file
df = process_excel_file('data/raw/DH70.xlsx')
```

### Database Management

```python
from src.data_processing.database_manager import (
    create_sqlite_manager, 
    create_sql_server_manager,
    create_unified_manager
)

# Create managers
sqlite_manager = create_sqlite_manager('drilling_database.db')
sql_server_manager = create_sql_server_manager(config)
unified_manager = create_unified_manager(sqlite_manager, sql_server_manager)
```

## Configuration

### SQL Server Configuration

Create `sql_server_config.json`:

```json
{
  "server": "localhost",
  "database": "drilling_database",
  "username": "your_username",
  "password": "your_password",
  "driver": "ODBC Driver 17 for SQL Server",
  "trusted_connection": false
}
```

### Logging Configuration

The system uses Python's built-in logging module. Configure logging level:

```python
import logging
logging.basicConfig(level=logging.INFO)
```

## Error Handling

All methods include comprehensive error handling with logging. Common exceptions:

- `FileNotFoundError`: When Excel files are not found
- `ConnectionError`: When database connections fail
- `ValueError`: When invalid parameters are provided
- `Exception`: General errors with detailed logging

## Examples

### Complete Data Processing Workflow

```python
from src.data_processing.core import DataProcessor
from src.data_processing.database_manager import create_sql_server_manager

# Initialize components
processor = DataProcessor()
config = {
    'server': 'localhost',
    'database': 'drilling_database',
    'trusted_connection': True
}
db_manager = create_sql_server_manager(config)

# Process Excel file
df = processor.process_excel_file('data/raw/DH70.xlsx')

# Clean data
df_cleaned = processor.clean_data(df)

# Validate data
validation = processor.validate_data(df_cleaned)
if not validation['is_valid']:
    print(f"Data validation failed: {validation['errors']}")
    return

# Connect to database
if db_manager.connect():
    # Write to database
    success = db_manager.write_table(df_cleaned, 'drilling_data')
    if success:
        print("Data successfully written to database")
    
    db_manager.disconnect()
```

### Data Validation and Quality Check

```python
from src.data_processing.core import DataProcessor

processor = DataProcessor()

# Load and clean data
df = processor.process_excel_file('data/raw/DH70.xlsx')
df_cleaned = processor.clean_data(df)

# Validate data
validation = processor.validate_data(
    df_cleaned, 
    required_columns=['hole_id', 'depth', 'easting', 'northing']
)

# Print validation results
print(f"Data is valid: {validation['is_valid']}")
print(f"Total rows: {validation['stats']['total_rows']}")
print(f"Null counts: {validation['stats']['null_counts']}")

if validation['warnings']:
    print("Warnings:")
    for warning in validation['warnings']:
        print(f"  - {warning}")
```

### Database Synchronization

```python
from src.data_processing.database_manager import (
    create_sqlite_manager, 
    create_sql_server_manager,
    create_unified_manager
)

# Create managers
sqlite_manager = create_sqlite_manager('drilling_database.db')
sql_server_manager = create_sql_server_manager(sql_server_config)

# Create unified manager
unified_manager = create_unified_manager(sqlite_manager, sql_server_manager)

# Connect to both databases
if unified_manager.connect():
    # Sync tables
    tables_to_sync = ['collars', 'lithology_logs', 'sample_analyses']
    success = unified_manager.sync_tables(tables_to_sync)
    
    if success:
        print("Tables synchronized successfully")
    
    # Backup to CSV
    unified_manager.backup_to_csv(tables_to_sync, 'backup/')
    
    unified_manager.disconnect()
```

## Performance Considerations

1. **Chunking**: Use `chunksize` parameter for large datasets
2. **Connection Pooling**: Reuse database connections when possible
3. **Memory Management**: Monitor memory usage with `get_data_summary()`
4. **Indexing**: Ensure proper database indexes for query performance

## Troubleshooting

### Common Issues

1. **SQL Server Connection Failed**
   - Check ODBC driver installation
   - Verify connection parameters
   - Ensure SQL Server is running

2. **Memory Issues with Large Datasets**
   - Use chunking for data processing
   - Consider data sampling for testing
   - Monitor memory usage

3. **Data Type Conversion Errors**
   - Check data quality before processing
   - Use `validate_data()` to identify issues
   - Handle missing values appropriately

### Debug Mode

Enable debug logging for detailed troubleshooting:

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

This will provide detailed information about data processing steps and database operations.

