# DrillingDataETL SSIS Project

## Overview
This SSIS project is designed to extract, transform, and load drilling data from Excel files and CSV files into a SQL Server database. The project is optimized for SQL Server 2022 and uses the Project Deployment Model.

## Project Structure
```
SSIS_Project/
├── DrillingDataETL/
│   ├── DrillingDataETL.dtproj          # Main project file
│   └── DrillingDataETL.sln             # Solution file
├── Packages/
│   ├── MainETL.dtsx                    # Main orchestration package
│   ├── LoadCollars.dtsx                # Load collars data
│   ├── LoadRockTypes.dtsx              # Load rock types data
│   ├── LoadSeamCodes.dtsx              # Load seam codes data
│   ├── LoadLithologyLogs.dtsx          # Load lithology logs data
│   └── LoadSampleAnalyses.dtsx         # Load sample analyses data
├── Connections/
│   ├── Excel_Connection.conmgr         # Excel connection manager
│   ├── SQL_Server_Connection.conmgr    # SQL Server connection manager
│   └── CSV_Connection.conmgr           # CSV connection manager
├── Scripts/
│   ├── Deploy_Project.ps1              # Deployment script
│   └── Execute_Package.ps1             # Execution script
└── Documentation/
    └── README.md                       # This file
```

## Prerequisites
- SQL Server 2022 with Integration Services
- SQL Server Data Tools (SSDT) 2022 or Visual Studio 2022 with SSIS extension
- PowerShell 5.1 or later
- SQL Server PowerShell module

## Project Parameters
| Parameter | Type | Default Value | Description |
|-----------|------|---------------|-------------|
| ExcelFilePath | String | data/raw/DH70.xlsx | Path to Excel file |
| SQLServerInstance | String | localhost | SQL Server instance |
| DatabaseName | String | DrillingDatabase | Target database |
| ProcessedDataPath | String | data/processed | Path to CSV files |
| LogLevel | Int32 | 4 | SSIS log level |
| MaxConcurrentExecutables | Int32 | 4 | Max concurrent tasks |
| ErrorOutputPath | String | data/error | Error output path |
| BatchSize | Int32 | 1000 | Batch size for loading |

## Deployment Instructions

### 1. Build the Project
```bash
# Open in Visual Studio/SSDT
# Build the solution (Ctrl+Shift+B)
# This creates the .ispac file
```

### 2. Deploy to SSIS Catalog
```powershell
# Run the deployment script
.\Scripts\Deploy_Project.ps1 -ServerInstance "localhost" -ProjectPath "DrillingDataETL.ispac"
```

### 3. Execute the Package
```powershell
# Execute the main package
.\Scripts\Execute_Package.ps1 -ServerInstance "localhost" -Synchronous
```

## Package Execution Flow
1. **LoadCollars** - Loads collar data from CSV
2. **LoadRockTypes** - Loads rock types data from CSV
3. **LoadSeamCodes** - Loads seam codes data from CSV
4. **LoadLithologyLogs** - Loads lithology logs data from CSV
5. **LoadSampleAnalyses** - Loads sample analyses data from CSV

## Data Sources
- **Excel File**: `data/raw/DH70.xlsx` (Original drilling data)
- **CSV Files**: `data/processed/` directory containing cleaned data
  - `collars.csv` - 71 rows
  - `rock_types.csv` - 20 rows
  - `seam_codes.csv` - 97 rows
  - `lithology_logs.csv` - 6,598 rows
  - `sample_analyses.csv` - 8,592 rows

## Error Handling
- All packages include comprehensive error handling
- Failed rows are redirected to error output files
- Detailed logging to SSIS Catalog
- Package execution status monitoring

## Monitoring and Logging
- SSIS Catalog reports for execution monitoring
- SQL Server logs for detailed execution history
- Performance counters for optimization
- Error logs in designated output path

## Troubleshooting
1. **Connection Issues**: Verify SQL Server instance and database connectivity
2. **File Path Issues**: Ensure all file paths are accessible and correct
3. **Permission Issues**: Verify SSIS service account has necessary permissions
4. **Memory Issues**: Adjust MaxConcurrentExecutables parameter if needed

## Performance Optimization
- Uses optimized data flow settings
- Implements batch processing for large datasets
- Configurable concurrent execution limits
- Memory-optimized buffer settings

## Security Considerations
- Uses Windows Authentication
- Sensitive data in Project Parameters
- Environment-specific configurations
- Secure connection strings

## Version History
- **v1.0** - Initial release with basic ETL functionality
- **v1.1** - Added error handling and logging
- **v1.2** - Optimized for SQL Server 2022

