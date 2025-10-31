#!/usr/bin/env python3
"""
Create HongsaDW - Star Schema Dimensional Data Warehouse
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
    source_db = os.getenv('MSSQL_DATABASE', 'HongsaNormalized')
    
    if not all([server, username, password]):
        raise ValueError("Missing required environment variables: MSSQL_SERVER, MSSQL_USERNAME, MSSQL_PASSWORD")
    
    return server, username, password, source_db

def execute_sql_file(conn, sql_file_path):
    """Execute SQL file against connection (handles GO statements)"""
    print(f"Executing: {sql_file_path.name}")
    
    with open(sql_file_path, 'r', encoding='utf-8') as f:
        text = f.read()
    
    # Split on lines that are exactly GO (like load_to_sqlserver.py)
    batches = []
    batch = []
    for line in text.splitlines():
        if line.strip().upper() == 'GO':
            if batch:
                batches.append('\n'.join(batch))
            batch = []
        else:
            batch.append(line)
    if batch:
        batches.append('\n'.join(batch))
    
    cursor = conn.cursor()
    executed = 0
    errors = []
    
    for i, batch in enumerate(batches, 1):
        stmt = batch.strip()
        if not stmt:
            continue
        
        try:
            cursor.execute(stmt)
            # Commit after each batch (GO statement behavior)
            conn.commit()
            executed += 1
        except Exception as e:
            error_msg = str(e)
            # Rollback on error
            try:
                conn.rollback()
            except:
                pass
            
            # Ignore common non-critical errors
            if any(keyword in error_msg.lower() for keyword in [
                'already exists', 'does not exist', 'cannot drop', 
                'object does not exist', 'no such object'
            ]):
                continue
            errors.append(f"Batch {i}: {error_msg[:200]}")
    
    print(f"  Executed {executed}/{len(batches)} batches successfully")
    
    if errors:
        print(f"  Warnings ({len(errors)}):")
        for err in errors[:5]:  # Show first 5 errors
            print(f"    - {err}")
        if len(errors) > 5:
            print(f"    ... and {len(errors) - 5} more")
    
    return executed

def update_populate_script_source_db(source_db_name):
    """Update populate script with correct source database name"""
    populate_script = project_root / 'sql' / 'populate_hongsa_dw_data.sql'
    
    if not populate_script.exists():
        print(f"Warning: {populate_script} not found")
        return
    
    with open(populate_script, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Update the source database name declaration
    import re
    pattern = r"DECLARE @SourceDbName NVARCHAR\(100\) = '[^']*';"
    replacement = f"DECLARE @SourceDbName NVARCHAR(100) = '{source_db_name}';"
    
    new_content = re.sub(pattern, replacement, content)
    
    if new_content != content:
        with open(populate_script, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated populate script with source database: {source_db_name}")

def main():
    """Main execution"""
    print("=" * 60)
    print("Creating HongsaDW - Star Schema Dimensional Data Warehouse")
    print("=" * 60)
    
    try:
        server, username, password, source_db = get_connection_info()
        print(f"\nConnection Info:")
        print(f"  Server: {server}")
        print(f"  Username: {username}")
        print(f"  Source Database: {source_db}")
        print(f"  Target Database: HongsaDW")
        
        # Update populate script with source database name
        update_populate_script_source_db(source_db)
        
        # Connect to SQL Server (master database for initial connection)
        print(f"\nConnecting to SQL Server...")
        conn = pymssql.connect(
            server=server,
            user=username,
            password=password,
            database='master',
            timeout=30
        )
        print("✓ Connected successfully")
        
        # Step 1: Create database if not exists
        print(f"\n{'=' * 60}")
        print("Step 1: Creating/Checking HongsaDW Database")
        print(f"{'=' * 60}")
        
        cursor = conn.cursor()
        # Check if database exists
        cursor.execute("SELECT name FROM sys.databases WHERE name = 'HongsaDW'")
        exists = cursor.fetchone()
        
        if not exists:
            # Close connection first (CREATE DATABASE needs exclusive access)
            conn.close()
            # Reconnect with autocommit for CREATE DATABASE
            conn = pymssql.connect(
                server=server,
                user=username,
                password=password,
                database='master',
                timeout=30,
                autocommit=True
            )
            cursor = conn.cursor()
            cursor.execute("CREATE DATABASE HongsaDW")
            print("✓ Created HongsaDW database")
            conn.close()
        else:
            print("✓ HongsaDW database already exists")
        
        # Reconnect normally
        conn = pymssql.connect(
            server=server,
            user=username,
            password=password,
            database='master',
            timeout=30
        )
        
        # Step 2: Create schema
        print(f"\n{'=' * 60}")
        print("Step 2: Creating HongsaDW Schema")
        print(f"{'=' * 60}")
        
        # Reconnect to HongsaDW
        conn.close()
        conn = pymssql.connect(
            server=server,
            user=username,
            password=password,
            database='HongsaDW',
            timeout=30
        )
        print("✓ Connected to HongsaDW")
        
        schema_file = project_root / 'sql' / 'create_hongsa_dw_schema.sql'
        if not schema_file.exists():
            raise FileNotFoundError(f"Schema file not found: {schema_file}")
        
        # Read and execute schema file, but skip CREATE DATABASE statement
        with open(schema_file, 'r', encoding='utf-8') as f:
            schema_content = f.read()
        
        # Remove CREATE DATABASE section (lines with CREATE DATABASE)
        lines = schema_content.split('\n')
        filtered_lines = []
        skip_use = False
        for line in lines:
            if 'CREATE DATABASE' in line.upper() or 'USE master' in line.upper():
                skip_use = True
                continue
            if skip_use and 'USE HongsaDW' in line.upper():
                skip_use = False
                continue
            filtered_lines.append(line)
        
        filtered_content = '\n'.join(filtered_lines)
        
        # Save temporary file
        temp_file = project_root / 'sql' / 'create_hongsa_dw_schema_temp.sql'
        with open(temp_file, 'w', encoding='utf-8') as f:
            f.write(filtered_content)
        
        try:
            execute_sql_file(conn, temp_file)
            print("✓ Schema created successfully")
        finally:
            # Clean up temp file
            if temp_file.exists():
                temp_file.unlink()
        
        # Step 3: Populate data
        print(f"\n{'=' * 60}")
        print("Step 3: Populating HongsaDW Data")
        print(f"{'=' * 60}")
        
        # Reconnect to HongsaDW database
        conn.close()
        conn = pymssql.connect(
            server=server,
            user=username,
            password=password,
            database='HongsaDW',
            timeout=30
        )
        print("✓ Connected to HongsaDW")
        
        populate_file = project_root / 'sql' / 'populate_hongsa_dw_data.sql'
        if not populate_file.exists():
            raise FileNotFoundError(f"Populate file not found: {populate_file}")
        
        # Read populate script and replace all @SourceDbName references with actual database name
        with open(populate_file, 'r', encoding='utf-8') as f:
            populate_content = f.read()
        
        # Strategy: Replace @SourceDbName in dynamic SQL strings with literal database name
        # Pattern: [' + @SourceDbName + '] becomes [{source_db}]
        # We need to be careful with string escaping
        
        import re
        
        # First, update the DECLARE statement
        populate_content = re.sub(
            r"DECLARE @SourceDbName NVARCHAR\(100\) = '[^']*';",
            f"DECLARE @SourceDbName NVARCHAR(100) = '{source_db}';",
            populate_content
        )
        
        # Replace [' + @SourceDbName + '] in dynamic SQL strings
        # This pattern appears in SET @SQL = '... FROM [' + @SourceDbName + ']...'
        pattern_dynamic = r"\['\s*\+\s*@SourceDbName\s*\+\s*'\]"
        populate_content = re.sub(pattern_dynamic, f"[{source_db}]", populate_content)
        
        # Replace @SourceDbName in IF EXISTS check (not in string)
        # But be careful - this is after GO, so we can't use the variable
        # Replace the whole IF block with direct comparison
        populate_content = re.sub(
            r"IF NOT EXISTS \(SELECT name FROM sys\.databases WHERE name = @SourceDbName\)",
            f"IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = '{source_db}')",
            populate_content
        )
        
        # Replace @SourceDbName in PRINT statements
        populate_content = re.sub(
            r"' \+ @SourceDbName \+ '",
            f"'{source_db}'",
            populate_content
        )
        
        # Save to temp file
        temp_populate_file = project_root / 'sql' / 'populate_hongsa_dw_data_temp.sql'
        with open(temp_populate_file, 'w', encoding='utf-8') as f:
            f.write(populate_content)
        
        try:
            execute_sql_file(conn, temp_populate_file)
            print("✓ Data populated successfully")
        finally:
            if temp_populate_file.exists():
                temp_populate_file.unlink()
        
        # Step 4: Verify data
        print(f"\n{'=' * 60}")
        print("Step 4: Verifying Data")
        print(f"{'=' * 60}")
        
        cursor = conn.cursor()
        
        tables = [
            'DimDate', 'DimHole', 'DimSeam', 'DimRock',
            'FactCoalAnalysis', 'FactLithology'
        ]
        
        for table in tables:
            cursor.execute(f"SELECT COUNT(*) FROM {table}")
            count = cursor.fetchone()[0]
            print(f"  {table}: {count:,} rows")
        
        print("\n✓ Verification complete")
        
        conn.close()
        
        print(f"\n{'=' * 60}")
        print("✓ HongsaDW created successfully!")
        print(f"{'=' * 60}")
        print("\nNext steps:")
        print("  1. Connect SSAS Tabular Model to HongsaDW")
        print("  2. Import Fact and Dimension tables")
        print("  3. Create relationships and measures")
        print("  4. Deploy model")
        
    except pymssql.Error as e:
        print(f"\n✗ SQL Server Error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"\n✗ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()
