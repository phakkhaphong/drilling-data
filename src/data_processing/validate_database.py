#!/usr/bin/env python3
"""
Validate database integrity and data quality
"""

import polars as pl
import sqlite3
from pathlib import Path


def validate_database(db_path: str = "drilling_database.db"):
    """
    Validate database integrity and data quality
    
    Args:
        db_path: Path to SQLite database
    """
    print(f"Validating database: {db_path}")
    
    conn = sqlite3.connect(db_path)
    
    # Check table existence
    tables = ['collars', 'rock_types', 'seam_codes', 'lithology_logs', 'sample_analyses']
    
    for table in tables:
        try:
            df = pl.read_database(f"SELECT COUNT(*) as count FROM {table}", conn)
            count = df['count'][0]
            print(f"✓ {table}: {count} rows")
        except Exception as e:
            print(f"✗ {table}: Error - {e}")
    
    conn.close()


if __name__ == "__main__":
    validate_database()