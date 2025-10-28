#!/usr/bin/env python3
"""
Fix CSV issues for SQL Server import
"""

import polars as pl
from pathlib import Path


def fix_seam_codes_csv():
    """Fix SEAM_CODES CSV to include seam_code_id"""
    input_file = "data/processed/seam_codes.csv"
    output_file = "data/processed/seam_codes_fixed.csv"
    
    print(f"Fixing SEAM_CODES CSV...")
    
    try:
        # Read CSV
        df = pl.read_csv(input_file)
        print(f"Original shape: {df.shape}")
        
        # Add seam_code_id column (auto-increment starting from 1)
        df = df.with_row_index("seam_code_id", offset=1)
        
        # Reorder columns to match SQL table
        df = df.select(["seam_code_id", "seam_code", "seam_label", "seam_system"])
        
        # Save fixed CSV
        df.write_csv(output_file)
        print(f"Fixed SEAM_CODES CSV saved to {output_file}")
        print(f"Final shape: {df.shape}")
        
        # Show sample (avoid encoding issues)
        print("\nSample data: [Data loaded successfully]")
        
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()


def fix_sample_analyses_csv():
    """Fix SAMPLE_ANALYSES CSV to handle NULL values"""
    input_file = "data/processed/sample_analyses.csv"
    output_file = "data/processed/sample_analyses_fixed.csv"
    
    print(f"Fixing SAMPLE_ANALYSES CSV...")
    
    try:
        # Read CSV with proper settings
        df = pl.read_csv(input_file, infer_schema_length=0, ignore_errors=True)
        print(f"Original shape: {df.shape}")
        
        # Fix numeric columns - replace empty strings with NULL
        numeric_columns = [
            'im', 'tm', 'ash', 'vm', 'fc', 'sulphur', 'gross_cv', 'net_cv', 
            'sg', 'rd', 'hgi', 'seam_code_quality', 'seam_code_73'
        ]
        
        for col in numeric_columns:
            if col in df.columns:
                df = df.with_columns(
                    pl.col(col)
                    .str.replace_all(r'^$', 'NULL')  # Replace empty strings with NULL
                    .str.replace_all(r'^""$', 'NULL')  # Replace "" with NULL
                )
        
        # Save fixed CSV
        df.write_csv(output_file)
        print(f"Fixed SAMPLE_ANALYSES CSV saved to {output_file}")
        print(f"Final shape: {df.shape}")
        
        # Show sample (avoid encoding issues)
        print("\nSample data: [Data loaded successfully]")
        
        # Show NULL counts
        print("\nNULL counts in numeric columns:")
        for col in numeric_columns:
            if col in df.columns:
                null_count = df.filter(pl.col(col) == "NULL").height
                print(f"  {col}: {null_count} NULLs")
        
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()


def main():
    """Fix all CSV issues"""
    print("Fixing CSV issues for SQL Server import...")
    print("=" * 50)
    
    fix_seam_codes_csv()
    print()
    fix_sample_analyses_csv()
    
    print("\n" + "=" * 50)
    print("CSV fixes completed!")


if __name__ == "__main__":
    main()
