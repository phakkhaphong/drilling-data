#!/usr/bin/env python3
"""
Fix CSV issues for SQL Server import - Version 2
Replace NULL strings with empty values for proper SQL Server import
"""

import polars as pl
from pathlib import Path


def fix_sample_analyses_csv_v2():
    """Fix SAMPLE_ANALYSES CSV to handle NULL values properly for SQL Server"""
    input_file = "data/processed/sample_analyses.csv"
    output_file = "data/processed/sample_analyses_fixed_v2.csv"
    
    print(f"Fixing SAMPLE_ANALYSES CSV for SQL Server import...")
    
    try:
        # Read CSV with proper settings
        df = pl.read_csv(input_file, infer_schema_length=0, ignore_errors=True)
        print(f"Original shape: {df.shape}")
        
        # Fix numeric columns - replace empty strings and NULL strings with empty values
        numeric_columns = [
            'im', 'tm', 'ash', 'vm', 'fc', 'sulphur', 'gross_cv', 'net_cv', 
            'sg', 'rd', 'hgi', 'seam_code_quality', 'seam_code_73'
        ]
        
        for col in numeric_columns:
            if col in df.columns:
                df = df.with_columns(
                    pl.col(col)
                    .str.replace_all(r'^$', '')  # Replace empty strings with empty
                    .str.replace_all(r'^""$', '')  # Replace "" with empty
                    .str.replace_all(r'^NULL$', '')  # Replace NULL with empty
                )
        
        # Save fixed CSV
        df.write_csv(output_file)
        print(f"Fixed SAMPLE_ANALYSES CSV saved to {output_file}")
        print(f"Final shape: {df.shape}")
        
        # Show sample (avoid encoding issues)
        print("\nSample data: [Data loaded successfully]")
        
        # Show empty value counts
        print("\nEmpty value counts in numeric columns:")
        for col in numeric_columns:
            if col in df.columns:
                empty_count = df.filter(pl.col(col) == "").height
                print(f"  {col}: {empty_count} empty values")
        
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()


def main():
    """Fix SAMPLE_ANALYSES CSV for SQL Server import"""
    print("Fixing SAMPLE_ANALYSES CSV for SQL Server import...")
    print("=" * 60)
    
    fix_sample_analyses_csv_v2()
    
    print("\n" + "=" * 60)
    print("CSV fix completed!")
    print("\nUse 'sample_analyses_fixed_v2.csv' for SQL Server import")


if __name__ == "__main__":
    main()

