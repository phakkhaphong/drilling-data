#!/usr/bin/env python3
"""
Verify and report on HongsaDW data warehouse
Reads SQL Server connection details from .env file
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import pymssql

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

# Load environment variables
load_dotenv(project_root / '.env')

def get_connection_info():
    """Get SQL Server connection info from .env"""
    server = os.getenv('MSSQL_SERVER')
    username = os.getenv('MSSQL_USERNAME')
    password = os.getenv('MSSQL_PASSWORD')
    
    if not all([server, username, password]):
        raise ValueError("Missing required environment variables: MSSQL_SERVER, MSSQL_USERNAME, MSSQL_PASSWORD")
    
    return server, username, password

def verify_tables(conn):
    """Verify all required tables exist"""
    print("=" * 60)
    print("Table Verification")
    print("=" * 60)
    
    cursor = conn.cursor()
    required_tables = [
        'DimDate', 'DimHole', 'DimSeam', 'DimRock',
        'FactCoalAnalysis', 'FactLithology'
    ]
    
    missing_tables = []
    for table in required_tables:
        cursor.execute(f"""
            SELECT COUNT(*) 
            FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = '{table}'
        """)
        exists = cursor.fetchone()[0] > 0
        status = "✓" if exists else "✗"
        print(f"  {status} {table}")
        if not exists:
            missing_tables.append(table)
    
    if missing_tables:
        print(f"\n✗ Missing tables: {', '.join(missing_tables)}")
        return False
    else:
        print("\n✓ All required tables exist")
        return True

def report_row_counts(conn):
    """Report row counts for all tables"""
    print("\n" + "=" * 60)
    print("Data Volume Report")
    print("=" * 60)
    
    cursor = conn.cursor()
    tables = [
        'DimDate', 'DimHole', 'DimSeam', 'DimRock',
        'FactCoalAnalysis', 'FactLithology'
    ]
    
    total_rows = 0
    for table in tables:
        cursor.execute(f"SELECT COUNT(*) FROM {table}")
        count = cursor.fetchone()[0]
        total_rows += count
        print(f"  {table:25s} {count:>10,} rows")
    
    print(f"\n  {'TOTAL':25s} {total_rows:>10,} rows")

def check_data_quality(conn):
    """Check data quality issues"""
    print("\n" + "=" * 60)
    print("Data Quality Checks")
    print("=" * 60)
    
    cursor = conn.cursor()
    issues = []
    
    # Check for orphaned records
    cursor.execute("""
        SELECT COUNT(*) 
        FROM FactCoalAnalysis f
        LEFT JOIN DimHole h ON f.HoleKey = h.HoleKey
        WHERE h.HoleKey IS NULL
    """)
    orphaned_hole = cursor.fetchone()[0]
    if orphaned_hole > 0:
        issues.append(f"FactCoalAnalysis with invalid HoleKey: {orphaned_hole}")
    
    cursor.execute("""
        SELECT COUNT(*) 
        FROM FactLithology f
        LEFT JOIN DimHole h ON f.HoleKey = h.HoleKey
        WHERE h.HoleKey IS NULL
    """)
    orphaned_lith_hole = cursor.fetchone()[0]
    if orphaned_lith_hole > 0:
        issues.append(f"FactLithology with invalid HoleKey: {orphaned_lith_hole}")
    
    # Check for null foreign keys where they shouldn't be
    cursor.execute("""
        SELECT COUNT(*) 
        FROM FactCoalAnalysis 
        WHERE HoleKey IS NULL
    """)
    null_hole = cursor.fetchone()[0]
    if null_hole > 0:
        issues.append(f"FactCoalAnalysis with NULL HoleKey: {null_hole}")
    
    # Check date coverage
    cursor.execute("""
        SELECT 
            MIN(FullDate) as min_date,
            MAX(FullDate) as max_date
        FROM DimDate
        WHERE DateKey IN (SELECT DISTINCT AnalysisDateKey FROM FactCoalAnalysis WHERE AnalysisDateKey IS NOT NULL)
    """)
    date_range = cursor.fetchone()
    if date_range and date_range[0]:
        print(f"  Date Range Coverage: {date_range[0]} to {date_range[1]}")
    
    if issues:
        print("\n  ⚠ Issues found:")
        for issue in issues:
            print(f"    - {issue}")
    else:
        print("  ✓ No data quality issues detected")

def report_sample_data(conn):
    """Report sample data from each fact table"""
    print("\n" + "=" * 60)
    print("Sample Data Report")
    print("=" * 60)
    
    cursor = conn.cursor()
    
    # Sample from FactCoalAnalysis
    print("\n  Top 5 FactCoalAnalysis records:")
    cursor.execute("""
        SELECT TOP 5
            f.HoleID,
            f.SampleNo,
            f.DepthFrom,
            f.DepthTo,
            f.Ash,
            f.GrossCV,
            h.FinalDepth as HoleDepth
        FROM FactCoalAnalysis f
        INNER JOIN DimHole h ON f.HoleKey = h.HoleKey
        ORDER BY f.DepthFrom
    """)
    
    rows = cursor.fetchall()
    if rows:
        print(f"    {'HoleID':<10} {'Sample':<10} {'Depth':<15} {'Ash%':<8} {'GrossCV':<10}")
        print("    " + "-" * 55)
        for row in rows:
            depth = f"{row[2]:.2f}-{row[3]:.2f}"
            ash = f"{row[4]:.2f}" if row[4] else "NULL"
            cv = f"{row[5]:.0f}" if row[5] else "NULL"
            print(f"    {row[0]:<10} {row[1]:<10} {depth:<15} {ash:<8} {cv:<10}")
    
    # Summary statistics
    print("\n  FactCoalAnalysis Summary Statistics:")
    cursor.execute("""
        SELECT 
            COUNT(*) as total_samples,
            AVG(Ash) as avg_ash,
            AVG(GrossCV) as avg_gross_cv,
            AVG(VM) as avg_vm,
            AVG(FC) as avg_fc
        FROM FactCoalAnalysis
        WHERE Ash IS NOT NULL AND GrossCV IS NOT NULL
    """)
    stats = cursor.fetchone()
    if stats and stats[0]:
        print(f"    Total Samples: {stats[0]:,}")
        print(f"    Avg Ash: {stats[1]:.2f}%")
        print(f"    Avg Gross CV: {stats[2]:.0f} kcal/kg")
        print(f"    Avg VM: {stats[3]:.2f}%")
        print(f"    Avg FC: {stats[4]:.2f}%")

def main():
    """Main execution"""
    print("=" * 60)
    print("HongsaDW Verification Report")
    print("=" * 60)
    
    try:
        server, username, password = get_connection_info()
        print(f"\nConnection Info:")
        print(f"  Server: {server}")
        print(f"  Database: HongsaDW")
        
        # Connect to HongsaDW
        conn = pymssql.connect(
            server=server,
            user=username,
            password=password,
            database='HongsaDW',
            timeout=30
        )
        print("✓ Connected to HongsaDW\n")
        
        # Run verification checks
        if verify_tables(conn):
            report_row_counts(conn)
            check_data_quality(conn)
            report_sample_data(conn)
        
        conn.close()
        
        print("\n" + "=" * 60)
        print("✓ Verification complete")
        print("=" * 60)
        
    except Exception as e:
        print(f"\n✗ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()

