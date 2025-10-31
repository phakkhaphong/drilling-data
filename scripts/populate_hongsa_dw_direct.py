#!/usr/bin/env python3
"""
Direct population of HongsaDW using Python instead of SQL script
This avoids issues with GO statements and variable scoping
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import pymssql
from datetime import date, timedelta

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
    source_db = os.getenv('MSSQL_DATABASE', 'HongsaNormalized')
    
    if not all([server, username, password]):
        raise ValueError("Missing required environment variables: MSSQL_SERVER, MSSQL_USERNAME, MSSQL_PASSWORD")
    
    return server, username, password, source_db

def populate_dimdate(conn):
    """Populate DimDate dimension"""
    print("Populating DimDate...")
    
    cursor = conn.cursor()
    
    # Check if already populated
    cursor.execute("SELECT COUNT(*) FROM DimDate")
    existing_count = cursor.fetchone()[0]
    if existing_count > 0:
        print(f"  DimDate already has {existing_count:,} rows, skipping...")
        return
    
    # Get date range from source
    source_db = os.getenv('MSSQL_DATABASE', 'HongsaNormalized')
    
    # Get min/max dates from source database
    # Get date range from sample_analyses (collars doesn't have drilling_date)
    cursor.execute(f"""
        SELECT 
            MIN(COALESCE(analysis_date, CAST('2000-01-01' AS DATE))) as min_date,
            MAX(COALESCE(analysis_date, CAST('2100-12-31' AS DATE))) as max_date
        FROM [{source_db}].[dbo].[sample_analyses]
        WHERE analysis_date IS NOT NULL
    """)
    result = cursor.fetchone()
    min_date = result[0] if result and result[0] else date(2000, 1, 1)
    max_date = result[1] if result and result[1] else date(2100, 12, 31)
    
    print(f"  Date range: {min_date} to {max_date}")
    
    # Generate dates
    current_date = min_date
    rows = []
    batch_size = 1000
    total_inserted = 0
    
    while current_date <= max_date:
        date_key = int(current_date.strftime('%Y%m%d'))
        day = current_date.day
        month = current_date.month
        month_name = current_date.strftime('%B')
        month_short = current_date.strftime('%b')
        quarter = (month - 1) // 3 + 1
        quarter_name = f'Q{quarter} {current_date.year}'
        year = current_date.year
        year_quarter = int(f"{year}{quarter}")
        
        week_of_year = current_date.isocalendar()[1]
        day_of_week = current_date.isoweekday()  # 1=Monday, 7=Sunday
        day_name = current_date.strftime('%A')
        day_short = current_date.strftime('%a')
        is_weekend = 1 if day_of_week >= 6 else 0
        
        rows.append((
            date_key, current_date, day, month, month_name, month_short,
            quarter, quarter_name, year, year_quarter,
            week_of_year, day_of_week, day_name, day_short,
            is_weekend, 0  # is_holiday
        ))
        
        current_date += timedelta(days=1)
        
        # Insert in batches using MERGE or INSERT with check
        if len(rows) >= batch_size:
            for row in rows:
                try:
                    cursor.execute("""
                        INSERT INTO DimDate (
                            DateKey, FullDate, Day, Month, MonthName, MonthShortName,
                            Quarter, QuarterName, Year, YearQuarter,
                            WeekOfYear, DayOfWeek, DayName, DayShortName,
                            IsWeekend, IsHoliday
                        ) VALUES (%d, %s, %d, %d, %s, %s, %d, %s, %d, %d, %d, %d, %s, %s, %d, %d)
                    """, row)
                    total_inserted += 1
                except pymssql.IntegrityError:
                    # Skip if duplicate
                    pass
            conn.commit()
            print(f"  Inserted {total_inserted:,} dates...")
            rows = []
    
    # Insert remaining
    for row in rows:
        try:
            cursor.execute("""
                INSERT INTO DimDate (
                    DateKey, FullDate, Day, Month, MonthName, MonthShortName,
                    Quarter, QuarterName, Year, YearQuarter,
                    WeekOfYear, DayOfWeek, DayName, DayShortName,
                    IsWeekend, IsHoliday
                ) VALUES (%d, %s, %d, %d, %s, %s, %d, %s, %d, %d, %d, %d, %s, %s, %d, %d)
            """, row)
            total_inserted += 1
        except pymssql.IntegrityError:
            pass
    conn.commit()
    
    cursor.execute("SELECT COUNT(*) FROM DimDate")
    count = cursor.fetchone()[0]
    print(f"✓ DimDate populated: {count:,} rows (inserted {total_inserted:,} new)")

def populate_dimseam(conn):
    """Populate DimSeam dimension"""
    print("Populating DimSeam...")
    
    source_db = os.getenv('MSSQL_DATABASE', 'HongsaNormalized')
    cursor = conn.cursor()
    
    # Delete existing if any
    cursor.execute("DELETE FROM DimSeam")
    
    cursor.execute(f"""
        INSERT INTO DimSeam (
            SeamID, SystemID, SystemName, SeamLabel, SeamCode, Priority, Description, SystemHierarchy
        )
        SELECT 
            seam_id AS SeamID,
            system_id AS SystemID,
            system_name AS SystemName,
            seam_label AS SeamLabel,
            seam_code AS SeamCode,
            ISNULL(priority, 0) AS Priority,
            description AS Description,
            system_name + ' > ' + seam_label AS SystemHierarchy
        FROM [{source_db}].[dbo].[seam_codes_lookup]
    """)
    conn.commit()
    
    cursor.execute("SELECT COUNT(*) FROM DimSeam")
    count = cursor.fetchone()[0]
    print(f"✓ DimSeam populated: {count:,} rows")

def populate_dimrock(conn):
    """Populate DimRock dimension"""
    print("Populating DimRock...")
    
    source_db = os.getenv('MSSQL_DATABASE', 'HongsaNormalized')
    cursor = conn.cursor()
    
    # Delete existing if any
    cursor.execute("DELETE FROM DimRock")
    
    cursor.execute(f"""
        INSERT INTO DimRock (
            RockCode, Lithology, Detail, RockCategory
        )
        SELECT 
            rock_code AS RockCode,
            lithology AS Lithology,
            detail AS Detail,
            CASE 
                WHEN lithology LIKE '%CLAY%' OR lithology LIKE '%CL%' THEN 'Clay'
                WHEN lithology LIKE '%SAND%' OR lithology LIKE '%SD%' THEN 'Sandstone'
                WHEN lithology LIKE '%COAL%' OR lithology LIKE '%CBCL%' THEN 'Coal'
                WHEN lithology LIKE '%SHALE%' OR lithology LIKE '%SH%' THEN 'Shale'
                ELSE 'Other'
            END AS RockCategory
        FROM [{source_db}].[dbo].[rock_types]
    """)
    conn.commit()
    
    cursor.execute("SELECT COUNT(*) FROM DimRock")
    count = cursor.fetchone()[0]
    print(f"✓ DimRock populated: {count:,} rows")

def populate_dimhole(conn):
    """Populate DimHole dimension"""
    print("Populating DimHole...")
    
    source_db = os.getenv('MSSQL_DATABASE', 'HongsaNormalized')
    cursor = conn.cursor()
    
    # Delete existing if any
    cursor.execute("DELETE FROM DimHole")
    
    cursor.execute(f"""
        INSERT INTO DimHole (
            HoleID, Easting, Northing, Elevation, Azimuth, Dip, FinalDepth, 
            Contractor, DrillingDateKey, DrillingYear, DrillingMonth, DrillingQuarter, Remarks
        )
        SELECT 
            c.hole_id AS HoleID,
            c.easting AS Easting,
            c.northing AS Northing,
            c.elevation AS Elevation,
            c.azimuth AS Azimuth,
            c.dip AS Dip,
            c.total_depth AS FinalDepth,
            c.contractor AS Contractor,
            NULL AS DrillingDateKey,  -- collars doesn't have drilling_date
            c.year_drilled AS DrillingYear,
            NULL AS DrillingMonth,  -- year_drilled is year only
            NULL AS DrillingQuarter,
            c.remarks AS Remarks
        FROM [{source_db}].[dbo].[collars] c
    """)
    conn.commit()
    
    cursor.execute("SELECT COUNT(*) FROM DimHole")
    count = cursor.fetchone()[0]
    print(f"✓ DimHole populated: {count:,} rows")

def populate_factcoalanysis(conn):
    """Populate FactCoalAnalysis fact table"""
    print("Populating FactCoalAnalysis...")
    
    source_db = os.getenv('MSSQL_DATABASE', 'HongsaNormalized')
    cursor = conn.cursor()
    
    # Delete existing if any
    cursor.execute("DELETE FROM FactCoalAnalysis")
    
    cursor.execute(f"""
        INSERT INTO FactCoalAnalysis (
            HoleKey, SeamQualityKey, Seam73Key, AnalysisDateKey,
            SampleID, HoleID, SampleNo,
            DepthFrom, DepthTo,
            IM, TM, Ash, VM, FC, Sulphur,
            GrossCV, NetCV, SG, RD, HGI,
            LabName, Remarks
        )
        SELECT 
            h.HoleKey,
            sq.SeamKey AS SeamQualityKey,
            s73.SeamKey AS Seam73Key,
            CASE 
                WHEN sa.analysis_date IS NOT NULL 
                THEN CAST(CONVERT(VARCHAR(8), sa.analysis_date, 112) AS INT)
                ELSE h.DrillingDateKey
            END AS AnalysisDateKey,
            sa.sample_id AS SampleID,
            sa.hole_id AS HoleID,
            sa.sample_no AS SampleNo,
            sa.depth_from AS DepthFrom,
            sa.depth_to AS DepthTo,
            sa.im AS IM,
            sa.tm AS TM,
            sa.ash AS Ash,
            sa.vm AS VM,
            sa.fc AS FC,
            sa.sulphur AS Sulphur,
            sa.gross_cv AS GrossCV,
            sa.net_cv AS NetCV,
            sa.sg AS SG,
            sa.rd AS RD,
            sa.hgi AS HGI,
            sa.lab_name AS LabName,
            sa.remarks AS Remarks
        FROM [{source_db}].[dbo].[sample_analyses] sa
        INNER JOIN DimHole h ON sa.hole_id = h.HoleID
        LEFT JOIN DimSeam sq ON sa.seam_quality_id = sq.SeamID
        LEFT JOIN DimSeam s73 ON sa.seam_73_id = s73.SeamID
    """)
    conn.commit()
    
    cursor.execute("SELECT COUNT(*) FROM FactCoalAnalysis")
    count = cursor.fetchone()[0]
    print(f"✓ FactCoalAnalysis populated: {count:,} rows")

def populate_factlithology(conn):
    """Populate FactLithology fact table"""
    print("Populating FactLithology...")
    
    source_db = os.getenv('MSSQL_DATABASE', 'HongsaNormalized')
    cursor = conn.cursor()
    
    # Delete existing if any
    cursor.execute("DELETE FROM FactLithology")
    
    cursor.execute(f"""
        INSERT INTO FactLithology (
            HoleKey, RockKey, LogDateKey,
            LogID, HoleID,
            DepthFrom, DepthTo,
            Description
        )
        SELECT 
            h.HoleKey,
            r.RockKey,
            h.DrillingDateKey AS LogDateKey,
            ll.log_id AS LogID,
            ll.hole_id AS HoleID,
            ll.depth_from AS DepthFrom,
            ll.depth_to AS DepthTo,
            ll.description AS Description
        FROM [{source_db}].[dbo].[lithology_logs] ll
        INNER JOIN DimHole h ON ll.hole_id = h.HoleID
        LEFT JOIN DimRock r ON ll.rock_code = r.RockCode
    """)
    conn.commit()
    
    cursor.execute("SELECT COUNT(*) FROM FactLithology")
    count = cursor.fetchone()[0]
    print(f"✓ FactLithology populated: {count:,} rows")

def main():
    """Main execution"""
    print("=" * 60)
    print("Populating HongsaDW - Direct Python Method")
    print("=" * 60)
    
    try:
        server, username, password, source_db = get_connection_info()
        print(f"\nConnection Info:")
        print(f"  Server: {server}")
        print(f"  Source Database: {source_db}")
        print(f"  Target Database: HongsaDW")
        
        # Connect to HongsaDW
        conn = pymssql.connect(
            server=server,
            user=username,
            password=password,
            database='HongsaDW',
            timeout=60
        )
        print("✓ Connected to HongsaDW")
        
        # Populate dimensions first
        populate_dimdate(conn)
        populate_dimseam(conn)
        populate_dimrock(conn)
        populate_dimhole(conn)
        
        # Then populate facts
        populate_factcoalanysis(conn)
        populate_factlithology(conn)
        
        # Verify
        print(f"\n{'=' * 60}")
        print("Verification")
        print(f"{'=' * 60}")
        cursor = conn.cursor()
        tables = ['DimDate', 'DimHole', 'DimSeam', 'DimRock', 'FactCoalAnalysis', 'FactLithology']
        for table in tables:
            cursor.execute(f"SELECT COUNT(*) FROM {table}")
            count = cursor.fetchone()[0]
            print(f"  {table}: {count:,} rows")
        
        conn.close()
        
        print(f"\n{'=' * 60}")
        print("✓ HongsaDW populated successfully!")
        print(f"{'=' * 60}")
        
    except Exception as e:
        print(f"\n✗ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()
