#!/usr/bin/env python3
"""
Final fix for CSV files for SQL Server import
Remove empty values completely for numeric columns
"""

import polars as pl
from pathlib import Path


def fix_sample_analyses_final():
    """Fix SAMPLE_ANALYSES CSV - Final version"""
    input_file = "data/processed/sample_analyses.csv"
    output_file = "data/processed/sample_analyses_final.csv"
    
    print(f"Creating final SAMPLE_ANALYSES CSV for SQL Server...")
    
    try:
        # Read CSV
        df = pl.read_csv(input_file, infer_schema_length=0, ignore_errors=True)
        print(f"Original shape: {df.shape}")
        
        # Define numeric columns that should be NULL when empty
        numeric_columns = [
            'im', 'tm', 'ash', 'vm', 'fc', 'sulphur', 'gross_cv', 'net_cv', 
            'sg', 'rd', 'hgi', 'seam_code_quality', 'seam_code_73'
        ]
        
        # For each numeric column, replace empty strings with None (which becomes NULL in CSV)
        for col in numeric_columns:
            if col in df.columns:
                df = df.with_columns(
                    pl.when(pl.col(col) == "").then(None)
                    .when(pl.col(col) == '""').then(None)
                    .otherwise(pl.col(col))
                    .alias(col)
                )
        
        # Save CSV with proper NULL handling
        df.write_csv(output_file, null_value="")
        print(f"Final SAMPLE_ANALYSES CSV saved to {output_file}")
        print(f"Final shape: {df.shape}")
        
        # Show statistics
        print("\nNULL counts in numeric columns:")
        for col in numeric_columns:
            if col in df.columns:
                null_count = df.filter(pl.col(col).is_null()).height
                print(f"  {col}: {null_count} NULLs")
        
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
    """Create final CSV files"""
    print("Creating final CSV files for SQL Server import...")
    print("=" * 60)
    
    fix_sample_analyses_final()
    
    print("\n" + "=" * 60)
    print("Final CSV files created!")
    print("\nUse 'sample_analyses_final.csv' for SQL Server import")


if __name__ == "__main__":
    main()
