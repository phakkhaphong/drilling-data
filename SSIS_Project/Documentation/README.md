# SSIS Drilling Data ETL Project

## Project Overview
This SSIS project is designed to extract, transform, and load drilling data from Excel files into a SQL Server database. The project is compatible with SSIS Extension 1.6.2 for Visual Studio 2022.

## Project Structure
```
SSIS_Project/
├── DrillingDataETL.sln              # Visual Studio Solution
├── DrillingDataETL/
│   ├── DrillingDataETL.dtproj       # SSIS Project File
│   ├── Connections/                  # Connection Managers
│   │   ├── Excel_Connection.conmgr
│   │   ├── SQL_Server_Connection.conmgr
│   │   └── CSV_Connection.conmgr
│   └── Packages/                     # SSIS Packages
│       ├── MainETL.dtsx             # Main orchestration package
│       ├── LoadCollars.dtsx         # Load collar data
│       └── LoadSampleAnalyses.dtsx  # Load sample analyses data
├── Documentation/                    # Project documentation
└── Scripts/                         # Deployment and execution scripts
```

## Prerequisites
- Visual Studio 2022 with SSIS Extension 1.6.2
- SQL Server 2019 or later
- Access to the drilling data Excel file (DH70.xlsx)

## Project Parameters
The project uses the following configurable parameters:
- **ExcelFilePath**: Path to the source Excel file (default: data/raw/DH70.xlsx)
- **SQLServerInstance**: SQL Server instance name (default: localhost)
- **DatabaseName**: Target database name (default: DrillingDatabase)
- **ProcessedDataPath**: Path to processed CSV files (default: data/processed)
- **LogLevel**: SSIS logging level (default: 4 - Diagnostic)
- **MaxConcurrentExecutables**: Maximum concurrent executables (default: 4)
- **ErrorOutputPath**: Path for error output files (default: data/error)
- **BatchSize**: Batch size for data loading (default: 1000)

## Packages Description

### MainETL.dtsx
The main orchestration package that:
- Executes LoadCollars package
- Executes LoadSampleAnalyses package
- Manages execution order and error handling

### LoadCollars.dtsx
Loads collar data from CSV files:
- Source: collars.csv from processed data path
- Target: Collars table in SQL Server
- Includes data validation and error handling

### LoadSampleAnalyses.dtsx
Loads sample analyses data from CSV files:
- Source: sample_analyses.csv from processed data path
- Target: SampleAnalyses table in SQL Server
- Includes data validation and error handling

## Connection Managers

### Excel_Connection
- Type: Microsoft Excel
- Purpose: Read data from Excel files
- Configuration: Uses project parameter for file path

### SQL_Server_Connection
- Type: Microsoft SQL Server
- Purpose: Write data to SQL Server database
- Configuration: Uses project parameters for server and database

### CSV_Connection
- Type: Microsoft Flat File
- Purpose: Read data from CSV files
- Configuration: Uses project parameter for file path

## Deployment
1. Open the solution in Visual Studio 2022
2. Build the project
3. Deploy to SSIS Catalog or execute directly

## Execution
The project can be executed:
- From Visual Studio (Debug/Release mode)
- From SQL Server Management Studio (SSIS Catalog)
- From command line using DTExec utility

## Troubleshooting
- Ensure all project parameters are correctly configured
- Verify connection strings and file paths
- Check SQL Server permissions
- Review SSIS logs for detailed error information