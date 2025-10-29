#!/bin/bash
# WSL Setup Script for Coal Drilling Database
# Run this script in WSL to set up the project

set -e  # Exit on any error

echo "=========================================="
echo "WSL Setup for Coal Drilling Database"
echo "=========================================="

# Check if running in WSL
if ! grep -q Microsoft /proc/version; then
    echo "Warning: This script is designed for WSL. Continuing anyway..."
fi

# Update package list
echo "Updating package list..."
sudo apt update

# Install required packages
echo "Installing Python and dependencies..."
sudo apt install -y python3 python3-pip python3-venv sqlite3 dos2unix

# Install Python packages
echo "Installing Python packages..."
pip3 install polars openpyxl

# Create virtual environment
echo "Creating virtual environment..."
python3 -m venv drilling_env

# Activate virtual environment
echo "Activating virtual environment..."
source drilling_env/bin/activate

# Install packages in virtual environment
echo "Installing packages in virtual environment..."
pip install polars openpyxl

# Fix line endings
echo "Converting line endings..."
if command -v dos2unix &> /dev/null; then
    find . -name "*.py" -exec dos2unix {} \;
    find . -name "*.sql" -exec dos2unix {} \;
    find . -name "*.md" -exec dos2unix {} \;
fi

# Make scripts executable
echo "Setting executable permissions..."
chmod +x create_drilling_database.py
find . -name "*.py" -exec chmod +x {} \;

# Create necessary directories
echo "Creating directories..."
mkdir -p data/drilling_database
mkdir -p sql
mkdir -p docs

# Test Python installation
echo "Testing Python installation..."
python3 --version
python3 -c "import polars; print('Polars version:', polars.__version__)"
python3 -c "import openpyxl; print('Openpyxl version:', openpyxl.__version__)"

# Test SQLite
echo "Testing SQLite..."
sqlite3 --version

echo "=========================================="
echo "Setup completed successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Activate virtual environment: source drilling_env/bin/activate"
echo "2. Run the project: python3 create_drilling_database.py"
echo "3. Create database: sqlite3 drilling_database.db < sql/create_drilling_database_schema.sql"
echo "4. Load data: sqlite3 drilling_database.db < sql/load_drilling_database_data.sql"
echo ""
echo "To activate virtual environment in future sessions:"
echo "  source drilling_env/bin/activate"
