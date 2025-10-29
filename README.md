# Hongsa Drilling Data Processing

A Python package for processing drilling data from Excel files and exporting to various formats including CSV and SQL Server.

## Project Structure

```
hongsa/
├── src/                          # Source code
│   └── data_processing/          # Data processing modules
│       ├── __init__.py
│       ├── clean_and_create_db.py
│       ├── export_sqlite_to_csv.py
│       ├── fix_import_wizard.py
│       ├── fix_csv_final.py
│       ├── fix_csv_issues.py
│       ├── fix_csv_issues_v2.py
│       ├── fix_csv_ultimate.py
│       └── validate_database.py
├── data/                         # Data directory
│   ├── raw/                      # Raw data files
│   │   └── DH70.xlsx
│   ├── processed/                # Processed data files
│   │   ├── collars.csv
│   │   ├── rock_types.csv
│   │   ├── seam_codes.csv
│   │   ├── lithology_logs.csv
│   │   ├── sample_analyses.csv
│   │   └── README.md
│   └── export/                   # Export files (legacy)
├── sql/                          # SQL scripts
│   ├── create_tables.sql
│   ├── add_foreign_keys.sql
│   └── check_data.sql
├── docs/                         # Documentation
│   ├── README.md
│   ├── SQL_SERVER_IMPORT_GUIDE.md
│   ├── PROJECT_STRUCTURE.md
│   └── Data_Cleaning_Steps.md
├── Data_Cleaning_Tutorial_Polars.ipynb  # Jupyter Notebook tutorial
├── tests/                        # Test files
├── setup.py                      # Package setup
├── requirements.txt              # Dependencies
├── pyproject.toml               # Modern Python packaging
└── README.md                    # This file
```

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd hongsa
```

2. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Install the package in development mode:
```bash
pip install -e .
```

## Usage

### Command Line Interface

```bash
# Clean data and create database
python src/data_processing/clean_and_create_db.py

# Export SQLite database to CSV
python src/data_processing/export_sqlite_to_csv.py

# Validate database
python src/data_processing/validate_database.py
```

### Python API

```python
from src.data_processing.clean_and_create_db import clean_data
from src.data_processing.export_sqlite_to_csv import export_sqlite_to_csv

# Clean data and create database
clean_data()

# Export SQLite to CSV
export_sqlite_to_csv()
```

## Data Processing Workflow

1. **Raw Data**: Excel file (`data/raw/DH70.xlsx`)
2. **Processing**: Clean and transform data using Polars
3. **Database**: Create SQLite database
4. **Export**: Export to CSV files for SQL Server import
5. **Import**: Use SQL scripts to import to SQL Server

## SQL Server Import

1. Run `sql/create_tables.sql` to create tables
2. Use SQL Server Import Wizard with files from `data/processed/`:
   - `collars.csv` → collars table
   - `rock_types.csv` → rock_types table
   - `seam_codes.csv` → seam_codes table
   - `lithology_logs.csv` → lithology_logs table
   - `sample_analyses.csv` → sample_analyses table
3. Run `sql/add_foreign_keys.sql` to add relationships
4. Run `sql/check_data.sql` to validate import

For detailed import instructions, see `docs/SQL_SERVER_IMPORT_GUIDE.md`.

## Development

### Running Tests

```bash
pytest
```

### Code Formatting

```bash
black src/
```

### Type Checking

```bash
mypy src/
```

## Dependencies

- **polars**: Fast data processing
- **openpyxl**: Excel file reading
- **sqlite3**: Database operations (built-in)

## License

MIT License

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request