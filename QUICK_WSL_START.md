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

# Create drilling database
python3 create_drilling_database.py

# Create SQLite database
sqlite3 drilling_database.db < sql/create_drilling_database_schema.sql

# Load data
sqlite3 drilling_database.db < sql/load_drilling_database_data.sql
```

## 6. Query the Database
```bash
# Open SQLite
sqlite3 drilling_database.db

# Run queries
SELECT COUNT(*) FROM sample_analyses;
SELECT * FROM sample_analyses_complete LIMIT 5;
.quit
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
pip install --upgrade polars openpyxl

# Or recreate virtual environment
rm -rf drilling_env
python3 -m venv drilling_env
source drilling_env/bin/activate
pip install polars openpyxl
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
