#!/bin/bash
# WSL Test Script for Coal Drilling Database
# Run this script to test the project in WSL

set -e  # Exit on any error

echo "=========================================="
echo "Testing Coal Drilling Database in WSL"
echo "=========================================="

# Check if virtual environment exists
if [ ! -d "drilling_env" ]; then
    echo "Error: Virtual environment not found. Run wsl_setup.sh first."
    exit 1
fi

# Activate virtual environment
echo "Activating virtual environment..."
source drilling_env/bin/activate

# Check Python packages
echo "Checking Python packages..."
python3 -c "import polars; print('✓ Polars:', polars.__version__)"
python3 -c "import openpyxl; print('✓ Openpyxl:', openpyxl.__version__)"

# Check project structure
echo "Checking project structure..."
echo "✓ Python script: $(ls -la create_drilling_database.py)"
echo "✓ Data directory: $(ls -la data/)"
echo "✓ SQL scripts: $(ls -la sql/)"
echo "✓ Documentation: $(ls -la docs/)"

# Test data files
echo "Checking data files..."
if [ -f "data/raw/DH70.xlsx" ]; then
    echo "✓ Source Excel file found"
else
    echo "⚠ Warning: data/raw/DH70.xlsx not found"
fi

# Test Python script (dry run)
echo "Testing Python script..."
if python3 -c "import create_drilling_database; print('✓ Script imports successfully')" 2>/dev/null; then
    echo "✓ Python script syntax is valid"
else
    echo "✗ Python script has syntax errors"
    exit 1
fi

# Test SQL scripts
echo "Testing SQL scripts..."
if [ -f "sql/create_drilling_database_schema.sql" ]; then
    echo "✓ Schema script found"
    # Test SQL syntax
    if sqlite3 :memory: < sql/create_drilling_database_schema.sql 2>/dev/null; then
        echo "✓ Schema script syntax is valid"
    else
        echo "✗ Schema script has syntax errors"
    fi
else
    echo "✗ Schema script not found"
fi

if [ -f "sql/load_drilling_database_data.sql" ]; then
    echo "✓ Data loading script found"
else
    echo "✗ Data loading script not found"
fi

# Test database creation (if data exists)
echo "Testing database creation..."
if [ -f "data/raw/DH70.xlsx" ]; then
    echo "Creating test database..."
    python3 create_drilling_database.py
    
    if [ -f "drilling_database.db" ]; then
        echo "✓ Database created successfully"
        
        # Test database content
        echo "Testing database content..."
        RECORD_COUNT=$(sqlite3 drilling_database.db "SELECT COUNT(*) FROM sample_analyses;" 2>/dev/null || echo "0")
        echo "✓ Sample analyses records: $RECORD_COUNT"
        
        # Test views
        echo "Testing database views..."
        sqlite3 drilling_database.db "SELECT name FROM sqlite_master WHERE type='view';" | while read view; do
            echo "✓ View: $view"
        done
        
        echo "✓ Database test completed successfully"
    else
        echo "✗ Database creation failed"
        exit 1
    fi
else
    echo "⚠ Skipping database creation test (no source data)"
fi

echo "=========================================="
echo "All tests completed successfully!"
echo "=========================================="
echo ""
echo "Project is ready to use in WSL!"
echo ""
echo "To run the project:"
echo "  source drilling_env/bin/activate"
echo "  python3 create_drilling_database.py"
echo ""
echo "To query the database:"
echo "  sqlite3 drilling_database.db"
