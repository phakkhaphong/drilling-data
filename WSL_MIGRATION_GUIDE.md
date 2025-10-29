# WSL Migration Guide - Coal Drilling Database

## Overview
This guide helps you migrate the Coal Drilling Database project from Windows to WSL (Windows Subsystem for Linux).

## Prerequisites

### 1. Install WSL
```bash
# In Windows PowerShell (as Administrator)
wsl --install
# or for specific distribution
wsl --install -d Ubuntu
```

### 2. Update WSL
```bash
wsl --update
```

## Migration Steps

### Step 1: Copy Project to WSL
```bash
# From Windows PowerShell
# Copy entire project to WSL home directory
cp -r C:\mySources\Code\Hongsa ~/drilling_database
```

### Step 2: Access WSL
```bash
# Open WSL terminal
wsl
# Navigate to project directory
cd ~/drilling_database
```

### Step 3: Install Dependencies in WSL

#### Install Python and pip
```bash
# Update package list
sudo apt update

# Install Python 3 and pip
sudo apt install python3 python3-pip python3-venv

# Install SQLite3
sudo apt install sqlite3
```

#### Install Python Packages
```bash
# Create virtual environment
python3 -m venv drilling_env

# Activate virtual environment
source drilling_env/bin/activate

# Install required packages
pip install polars openpyxl sqlite3
```

### Step 4: Verify Project Structure
```bash
# Check project structure
ls -la
ls -la data/
ls -la sql/
ls -la docs/

# Verify Python script
python3 create_drilling_database.py --help
```

### Step 5: Test Database Creation
```bash
# Create drilling database
python3 create_drilling_database.py

# Create SQLite database
sqlite3 drilling_database.db < sql/create_drilling_database_schema.sql

# Load data
sqlite3 drilling_database.db < sql/load_drilling_database_data.sql

# Test database
sqlite3 drilling_database.db "SELECT COUNT(*) FROM sample_analyses;"
```

## WSL-Specific Considerations

### 1. File Permissions
```bash
# Make scripts executable
chmod +x create_drilling_database.py

# Fix file permissions if needed
find . -type f -name "*.py" -exec chmod +x {} \;
```

### 2. Path Differences
- Windows: `C:\mySources\Code\Hongsa`
- WSL: `~/drilling_database` or `/home/username/drilling_database`

### 3. Line Endings
```bash
# Convert Windows line endings to Unix
dos2unix *.py
dos2unix sql/*.sql
dos2unix docs/*.md
```

### 4. Database File Location
- Database will be created in current directory: `./drilling_database.db`
- Use absolute paths for better portability

## Development Workflow in WSL

### 1. Using VS Code with WSL
```bash
# Install VS Code WSL extension
# Open project in WSL
code .
```

### 2. Running the Project
```bash
# Activate virtual environment
source drilling_env/bin/activate

# Run main script
python3 create_drilling_database.py

# Query database
sqlite3 drilling_database.db
```

### 3. File Monitoring
```bash
# Watch for file changes (if using auto-reload)
watch -n 1 'ls -la data/drilling_database/'
```

## Performance Considerations

### 1. File System Performance
- Store project in WSL file system (`~/drilling_database`) for better performance
- Avoid accessing Windows files from WSL for heavy I/O operations

### 2. Memory Usage
```bash
# Monitor memory usage
htop
# or
free -h
```

### 3. Database Performance
```bash
# Check database size
ls -lh drilling_database.db

# Analyze database performance
sqlite3 drilling_database.db "ANALYZE;"
```

## Troubleshooting

### Common Issues

#### 1. Permission Denied
```bash
# Fix permissions
chmod +x create_drilling_database.py
chmod 755 data/
chmod 755 sql/
```

#### 2. Python Module Not Found
```bash
# Ensure virtual environment is activated
source drilling_env/bin/activate

# Reinstall packages
pip install --upgrade polars openpyxl
```

#### 3. SQLite Database Locked
```bash
# Check for running processes
ps aux | grep sqlite

# Kill if necessary
pkill sqlite3
```

#### 4. File Not Found Errors
```bash
# Check current directory
pwd

# List files
ls -la

# Check if data directory exists
ls -la data/drilling_database/
```

### Debugging Commands
```bash
# Check Python version
python3 --version

# Check installed packages
pip list

# Check SQLite version
sqlite3 --version

# Test database connection
sqlite3 drilling_database.db ".tables"
```

## Backup and Sync

### 1. Backup from WSL to Windows
```bash
# Copy database back to Windows
cp drilling_database.db /mnt/c/mySources/Code/Hongsa/
```

### 2. Sync with Git
```bash
# Initialize git if not already done
git init

# Add all files
git add .

# Commit changes
git commit -m "WSL migration - updated file paths and permissions"

# Push to remote repository
git remote add origin <your-repo-url>
git push -u origin main
```

## Recommended WSL Setup

### 1. WSL Configuration
Create `~/.wslconfig` in Windows:
```ini
[wsl2]
memory=8GB
processors=4
swap=2GB
```

### 2. Shell Configuration
Add to `~/.bashrc`:
```bash
# Activate virtual environment automatically
if [ -f ~/drilling_database/drilling_env/bin/activate ]; then
    source ~/drilling_database/drilling_env/bin/activate
fi

# Add project to PATH
export PATH="$HOME/drilling_database:$PATH"
```

### 3. Aliases
Add to `~/.bashrc`:
```bash
# Project aliases
alias drilling="cd ~/drilling_database"
alias drilling-run="cd ~/drilling_database && python3 create_drilling_database.py"
alias drilling-db="cd ~/drilling_database && sqlite3 drilling_database.db"
```

## Next Steps

1. **Test the migration** by running the full workflow
2. **Set up development environment** with VS Code and WSL
3. **Configure Git** for version control
4. **Set up automated backups** if needed
5. **Document any WSL-specific changes** made to the project

## Benefits of WSL Migration

- **Better performance** for file I/O operations
- **Native Linux tools** and utilities
- **Consistent environment** across different machines
- **Better integration** with cloud deployment
- **Easier containerization** for Docker/Kubernetes

---

*This guide ensures a smooth transition from Windows to WSL while maintaining all project functionality.*
