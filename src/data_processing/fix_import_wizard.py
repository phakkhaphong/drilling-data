#!/usr/bin/env python3
"""
Create a completely clean CSV file for SQL Server Import Wizard
Removes all problematic characters and ensures proper encoding
"""

import polars as pl
import os
from pathlib import Path


def create_ultra_clean_csv(input_file: str = None, output_file: str = None):
    """
    Create ultra-clean CSV for SQL Server Import Wizard
    
    Args:
        input_file: Path to input CSV file
        output_file: Path to output CSV file
    """
    if input_file is None:
        input_file = "data/processed/lithology_logs.csv"
    if output_file is None:
        output_file = "data/processed/lithology_logs_ultra_clean.csv"
    
    print(f"Creating ultra-clean CSV from {input_file}...")
    
    try:
        # Read CSV file
        df = pl.read_csv(input_file, infer_schema_length=0, ignore_errors=True)
        
        print(f"Original shape: {df.shape}")
        
        # Ultra-clean all text columns
        text_columns = ['description', 'clay_color', 'remark']
        
        for col in text_columns:
            if col in df.columns:
                print(f"Ultra-cleaning column: {col}")
                
                # Get statistics
                max_length = df[col].str.len_chars().max()
                print(f"  Original max length: {max_length}")
                
                # Ultra-clean the column
                df = df.with_columns(
                    pl.col(col)
                    .cast(pl.Utf8)
                    .fill_null("")
                    .str.replace_all(r'[^\x20-\x7E]', '')  # Remove ALL non-printable ASCII
                    .str.replace_all(r'["""]', '"')  # Replace smart quotes
                    .str.replace_all(r"[''']", "'")  # Replace smart apostrophes
                    .str.replace_all(r'[–—]', '-')  # Replace dashes
                    .str.replace_all(r'[^\x20-\x7E]', '')  # Final cleanup
                    .str.strip_chars()
                    .str.slice(0, 50)  # Truncate to 50 characters (very safe)
                )
                
                # Check final length
                final_max = df[col].str.len_chars().max()
                print(f"  Final max length: {final_max}")
        
        # Ensure all columns are properly typed
        df = df.with_columns([
            pl.col('log_id').cast(pl.Int64),
            pl.col('hole_id').cast(pl.Utf8),
            pl.col('depth_from').cast(pl.Float64),
            pl.col('depth_to').cast(pl.Float64),
            pl.col('thickness').cast(pl.Float64),
            pl.col('rock_code').cast(pl.Utf8),
            pl.col('description').cast(pl.Utf8),
            pl.col('clay_color').cast(pl.Utf8),
            pl.col('remark').cast(pl.Utf8)
        ])
        
        # Save ultra-clean CSV
        df.write_csv(output_file)
        print(f"Ultra-clean CSV saved to {output_file}")
        print(f"Final shape: {df.shape}")
        
        # Show final statistics
        print("\nFinal column statistics:")
        for col in text_columns:
            if col in df.columns:
                max_len = df[col].str.len_chars().max()
                avg_len = df[col].str.len_chars().mean()
                print(f"  {col}: max={max_len}, avg={avg_len:.1f}")
        
        # Show sample of ultra-clean data
        print("\nSample of ultra-clean remark column:")
        sample = df.filter(pl.col('remark').str.len_chars() > 5).select('remark').head(5)
        for row in sample.iter_rows():
            print(f"  '{row[0]}'")
            
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    create_ultra_clean_csv()