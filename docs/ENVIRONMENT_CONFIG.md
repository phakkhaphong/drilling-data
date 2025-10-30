# Environment Configuration Guide

## Overview

The Hongsa Drilling Database uses environment variables stored in `.env` file for configuration. This allows easy customization without modifying code.

## Quick Start

1. **Copy the example file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` file** with your settings (see below)

3. **Configuration is automatically loaded** when you import:
   ```python
   from src.config import config
   ```

## Configuration Variables

### Virtual Environment Settings

```bash
VENV_NAME=.venv          # Virtual environment directory name
VENV_PATH=.venv          # Virtual environment path
```

### Database Configuration

#### SQLite (Local Development)
```bash
SQLITE_DB_PATH=data/drilling_database.db
```

#### SQL Server Configuration
```bash
SQL_SERVER_ENABLED=false                    # Enable SQL Server (true/false)
SQL_SERVER_HOST=localhost                   # SQL Server hostname/IP
SQL_SERVER_PORT=1433                        # SQL Server port
SQL_SERVER_DATABASE=drilling_database        # Database name
SQL_SERVER_DRIVER=ODBC Driver 17 for SQL Server  # ODBC driver name

# Authentication - Choose one:
SQL_SERVER_TRUSTED_CONNECTION=true          # Windows Authentication
# OR
SQL_SERVER_TRUSTED_CONNECTION=false         # SQL Server Authentication
SQL_SERVER_USERNAME=your_username
SQL_SERVER_PASSWORD=your_password
```

### Data Paths

```bash
DATA_RAW_DIR=data/raw                       # Raw data directory
DATA_PROCESSED_DIR=data/processed           # Processed data directory
DATA_EXPORT_DIR=data/export                 # Export directory
```

### Excel File Configuration

```bash
EXCEL_FILE_PATH=data/raw/DH70.xlsx          # Excel file path
EXCEL_SHEET_NAME=DAT201                     # Sheet name to read
```

### Logging Configuration

```bash
LOG_LEVEL=INFO                              # DEBUG, INFO, WARNING, ERROR
LOG_FILE=logs/hongsa_drilling.log          # Log file path
LOG_FORMAT=%(asctime)s - %(name)s - %(levelname)s - %(message)s
```

### Application Settings

```bash
APP_NAME=Hongsa Drilling Database           # Application name
APP_VERSION=2.0.0                           # Application version
DEBUG_MODE=false                            # Enable debug mode (true/false)
```

### Data Processing Settings

```bash
CHUNK_SIZE=1000                             # Data chunk size for processing
MAX_WORKERS=4                               # Maximum worker threads
ENABLE_VALIDATION=true                      # Enable data validation (true/false)
```

### Backup Configuration

```bash
BACKUP_ENABLED=true                         # Enable backups (true/false)
BACKUP_DIR=backup                           # Backup directory
BACKUP_RETENTION_DAYS=30                    # Days to keep backups
```

### Export Configuration

```bash
EXPORT_FORMAT=csv                           # Export format (csv, excel, json)
EXPORT_ENCODING=utf-8                       # File encoding
EXPORT_INCLUDE_INDEX=false                  # Include index in export (true/false)
```

### Development Settings

```bash
DEVELOPMENT_MODE=false                      # Development mode (true/false)
TEST_DATABASE_PATH=test_drilling_database.db  # Test database path
```

## Usage Examples

### Using Configuration in Code

```python
from src.config import config

# Access configuration values
print(f"SQLite DB: {config.SQLITE_DB_PATH}")
print(f"Excel File: {config.EXCEL_FILE_PATH}")

# Get SQL Server config
if config.SQL_SERVER_ENABLED:
    sql_config = config.get_sql_server_config()
    print(f"SQL Server: {sql_config['server']}/{sql_config['database']}")
```

### Environment-Specific Configuration

Create different `.env` files for different environments:

1. **Development:** `.env.development`
2. **Production:** `.env.production`
3. **Testing:** `.env.test`

Load specific environment:
```python
from src.config import Config

# Load development config
dev_config = Config(env_file=Path('.env.development'))

# Load production config
prod_config = Config(env_file=Path('.env.production'))
```

### Updating Configuration

1. **Edit `.env` file** directly
2. **Reload configuration:**
   ```python
   from src.config import get_config
   config = get_config(reload=True)
   ```

## Security Best Practices

⚠️ **Important Security Notes:**

1. **Never commit `.env` file** to version control
   - `.env` is already in `.gitignore`
   - Use `.env.example` for documentation

2. **Use `.env.example`** as template
   - Remove sensitive values
   - Add comments for documentation

3. **Keep passwords secure**
   - Use environment variables in production
   - Consider using secrets management tools

4. **Different environments**
   - Use different `.env` files for dev/test/prod
   - Never share production credentials

## Configuration Validation

The configuration loader automatically:
- ✅ Creates necessary directories
- ✅ Validates file paths
- ✅ Provides default values
- ✅ Handles missing variables gracefully

## Troubleshooting

### Configuration not loading

1. Check `.env` file exists
2. Verify file is in project root
3. Check file permissions
4. Verify `python-dotenv` is installed:
   ```bash
   pip install python-dotenv
   ```

### Wrong values being used

1. Check `.env` file syntax (no spaces around `=`)
2. Verify variable names match exactly
3. Restart Python process
4. Use `reload=True` when getting config

### SQL Server connection issues

1. Verify ODBC driver is installed
2. Check connection parameters in `.env`
3. Test connection manually:
   ```bash
   python sql_server_setup.py
   ```

## Environment Variables Priority

Configuration is loaded in this order (highest priority first):

1. Environment variables (system-level)
2. `.env` file
3. Default values in code

This allows overriding `.env` values with system environment variables for production deployments.

## Example Production Setup

```bash
# Set environment variables
export SQL_SERVER_ENABLED=true
export SQL_SERVER_HOST=prod-server.example.com
export SQL_SERVER_PASSWORD=$(cat /secure/password.txt)

# Run application
python your_script.py
```

The application will use these environment variables instead of `.env` file values.

