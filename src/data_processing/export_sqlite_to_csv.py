#!/usr/bin/env python3
"""
Export SQLite database to CSV files for SQL Server import
"""

import polars as pl
import sqlite3
from pathlib import Path
from datetime import datetime


def export_sqlite_to_csv(db_path: str = "drilling_database.db", output_dir: str = "data/processed"):
    """
    Export SQLite database to CSV files
    
    Args:
        db_path: Path to SQLite database
        output_dir: Directory to save CSV files
    """
    # Create output directory if it doesn't exist
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    
    # Connect to SQLite database
    conn = sqlite3.connect(db_path)
    
    # Define table names and their corresponding CSV filenames
    tables = {
        'collars': 'collars.csv',
        'rock_types': 'rock_types.csv',
        'seam_codes': 'seam_codes.csv',
        'lithology_logs': 'lithology_logs.csv',
        'sample_analyses': 'sample_analyses.csv'
    }
    
    print(f"Exporting SQLite database to CSV files...")
    print(f"Database: {db_path}")
    print(f"Output directory: {output_dir}")
    print("-" * 50)
    
    for table_name, csv_filename in tables.items():
        try:
            # Read data from SQLite
            df = pl.read_database(f"SELECT * FROM {table_name}", conn)
            
            # Save to CSV
            output_path = Path(output_dir) / csv_filename
            df.write_csv(output_path)
            
            print(f"✓ {table_name} -> {csv_filename} ({len(df)} rows)")
            
        except Exception as e:
            print(f"✗ Error exporting {table_name}: {e}")
    
    conn.close()
    
    # Create export summary
    create_export_summary(output_dir)
    
    print("-" * 50)
    print("Export completed!")


def create_export_summary(output_dir: str):
    """Create export summary file"""
    summary_path = Path(output_dir) / "export_summary.txt"
    
    with open(summary_path, 'w', encoding='utf-8') as f:
        f.write("CSV Export Summary\n")
        f.write("=" * 50 + "\n")
        f.write(f"Export Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"Output Directory: {output_dir}\n\n")
        
        f.write("Files Created:\n")
        f.write("-" * 20 + "\n")
        
        for csv_file in Path(output_dir).glob("*.csv"):
            f.write(f"- {csv_file.name}\n")


if __name__ == "__main__":
    export_sqlite_to_csv()