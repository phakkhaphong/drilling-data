#!/usr/bin/env python3
"""
Ultimate fix for CSV files for SQL Server import
Replace empty values with 0 for numeric columns to avoid conversion errors
"""

import polars as pl
from pathlib import Path


def fix_sample_analyses_ultimate():
    """Fix SAMPLE_ANALYSES CSV - Ultimate version with 0 instead of empty"""
    input_file = "data/processed/sample_analyses_final.csv"
    output_file = "data/processed/sample_analyses_ultimate.csv"
    
    print(f"Creating ultimate SAMPLE_ANALYSES CSV for SQL Server...")
    
    try:
        # Read CSV
        df = pl.read_csv(input_file, infer_schema_length=0, ignore_errors=True)
        print(f"Original shape: {df.shape}")
        
        # Define numeric columns that should be 0 when empty
        numeric_columns = [
            'im', 'tm', 'ash', 'vm', 'fc', 'sulphur', 'gross_cv', 'net_cv', 
            'sg', 'rd', 'hgi', 'seam_code_quality', 'seam_code_73'
        ]
        
        # For each numeric column, replace empty strings with 0
        for col in numeric_columns:
            if col in df.columns:
                df = df.with_columns(
                    pl.when(pl.col(col) == "").then(0.0)
                    .when(pl.col(col) == '""').then(0.0)
                    .when(pl.col(col).is_null()).then(0.0)
                    .otherwise(pl.col(col))
                    .alias(col)
                )
        
        # Save CSV
        df.write_csv(output_file)
        print(f"Ultimate SAMPLE_ANALYSES CSV saved to {output_file}")
        print(f"Final shape: {df.shape}")
        
        # Show statistics
        print("\nZero counts in numeric columns:")
        for col in numeric_columns:
            if col in df.columns:
                zero_count = df.filter(pl.col(col) == 0.0).height
                print(f"  {col}: {zero_count} zeros")
        
        # Show sample of net_cv column
        print("\nSample of net_cv column:")
        sample = df.select("net_cv").head(10)
        for i, row in enumerate(sample.iter_rows()):
            print(f"  Row {i+1}: {row[0]}")
        
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()


def main():
    """Create ultimate CSV files"""
    print("Creating ultimate CSV files for SQL Server import...")
    print("=" * 60)
    
    fix_sample_analyses_ultimate()
    
    print("\n" + "=" * 60)
    print("Ultimate CSV files created!")
    print("\nUse 'sample_analyses_ultimate.csv' for SQL Server import")


if __name__ == "__main__":
    main()
