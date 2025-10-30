# Quick WSL Start Guide

## Prerequisites
- Windows 10/11 with WSL installed
- Project files copied to WSL

## 1. Install WSL (if not already installed)
```powershell
# In Windows PowerShell (as Administrator)
wsl --install
```

## 2. Copy Project to WSL
```powershell
# From Windows PowerShell
cp -r C:\mySources\Code\Hongsa ~/drilling_database
```

## 3. Open WSL and Setup
```bash
# Open WSL terminal
wsl

# Navigate to project
cd ~/drilling_database

# Make scripts executable
chmod +x wsl_setup.sh wsl_test.sh

# Run setup
./wsl_setup.sh
```

## 4. Test the Setup
```bash
# Test everything works
./wsl_test.sh
```

## 5. Run the Project
```bash
# Activate virtual environment
source drilling_env/bin/activate

# Create normalized database
python3 create_proper_normalized_database.py

# Create SQL Server database (if available)
sqlcmd -S your_server -d your_database -i sql/create_sql_server_schema.sql

# Load data to SQL Server (if available)
sqlcmd -S your_server -d your_database -i sql/load_sql_server_data.sql
```

## 6. Query the Database
```bash
# Query SQL Server (if available)
sqlcmd -S your_server -d your_database -Q "SELECT COUNT(*) FROM sample_analyses;"
sqlcmd -S your_server -d your_database -Q "SELECT TOP 5 * FROM sample_analyses;"

# Or check CSV files
ls -la data/normalized_sql_server/
```

## Troubleshooting

### If setup fails:
```bash
# Check WSL version
wsl --list --verbose

# Update WSL
wsl --update

# Restart WSL
wsl --shutdown
wsl
```

### If Python packages fail:
```bash
# Reinstall packages
pip install --upgrade pandas openpyxl

# Or recreate virtual environment
rm -rf drilling_env
python3 -m venv drilling_env
source drilling_env/bin/activate
pip install pandas openpyxl
```

### If database creation fails:
```bash
# Check data files
ls -la data/raw/
ls -la data/drilling_database/

# Check permissions
chmod 755 data/
chmod 644 data/raw/DH70.xlsx
```

## Benefits of WSL
- ✅ Better file I/O performance
- ✅ Native Linux tools
- ✅ Easier cloud deployment
- ✅ Better development environment
- ✅ Consistent across machines

---
*This guide gets you up and running quickly in WSL!*
