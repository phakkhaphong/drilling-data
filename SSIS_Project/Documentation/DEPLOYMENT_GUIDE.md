# SSIS Project Deployment Guide

## SQL Server 2022 Integration Services Catalog Deployment

### Prerequisites
1. **SQL Server 2022** with Integration Services installed
2. **SQL Server Data Tools (SSDT) 2022** or **Visual Studio 2022** with SSIS extension
3. **PowerShell 5.1+** with SQL Server module
4. **Administrative privileges** on SQL Server instance

### Step 1: Prepare the Environment

#### 1.1 Enable Integration Services
```sql
-- Check if SSIS is installed
SELECT SERVERPROPERTY('IsIntegratedSecurityOnly') as IsIntegratedSecurityOnly;

-- Enable SSIS if not already enabled
-- (This is typically done during SQL Server installation)
```

#### 1.2 Create SSIS Catalog (if not exists)
```sql
-- Create SSIS Catalog
CREATE CATALOG SSISDB;
```

#### 1.3 Set up Database
```sql
-- Create target database
CREATE DATABASE DrillingDatabase;
GO

-- Create tables (use existing SQL scripts)
-- Reference: sql/create_tables.sql
```

### Step 2: Build the Project

#### 2.1 Open in Visual Studio/SSDT
1. Open `DrillingDataETL.sln` in Visual Studio 2022
2. Ensure all packages compile without errors
3. Build the solution (Ctrl+Shift+B)

#### 2.2 Verify Build Output
- Check for `.ispac` file in `bin\Release\` or `bin\Debug\`
- Ensure all dependencies are included

### Step 3: Deploy to SSIS Catalog

#### 3.1 Using PowerShell Script
```powershell
# Navigate to project directory
cd C:\mySources\Code\Hongsa\SSIS_Project

# Run deployment script
.\Scripts\Deploy_Project.ps1 -ServerInstance "localhost" -ProjectPath "DrillingDataETL.ispac"
```

#### 3.2 Manual Deployment via SSMS
1. Open SQL Server Management Studio
2. Connect to SQL Server instance
3. Navigate to Integration Services Catalogs
4. Right-click on SSISDB → Create Folder
5. Right-click on folder → Deploy Project
6. Select the `.ispac` file
7. Configure project parameters

### Step 4: Configure Environment

#### 4.1 Create Environment
```sql
-- Create environment
DECLARE @environment_id BIGINT
EXEC [SSISDB].[catalog].[create_environment]
    @environment_name = N'Production',
    @environment_id = @environment_id OUTPUT
```

#### 4.2 Set Environment Variables
```sql
-- Set environment variables
EXEC [SSISDB].[catalog].[create_environment_variable]
    @variable_name = N'ExcelFilePath',
    @variable_value = N'data/raw/DH70.xlsx',
    @environment_name = N'Production'

EXEC [SSISDB].[catalog].[create_environment_variable]
    @variable_name = N'SQLServerInstance',
    @variable_value = N'localhost',
    @environment_name = N'Production'

-- Add other variables as needed
```

#### 4.3 Create Environment Reference
```sql
-- Create environment reference
EXEC [SSISDB].[catalog].[create_environment_reference]
    @environment_name = N'Production',
    @project_name = N'DrillingDataETL',
    @folder_name = N'DrillingDataETL'
```

### Step 5: Test Execution

#### 5.1 Execute Package
```powershell
# Execute main package
.\Scripts\Execute_Package.ps1 -ServerInstance "localhost" -Synchronous
```

#### 5.2 Monitor Execution
```sql
-- Check execution status
SELECT 
    execution_id,
    package_name,
    status,
    start_time,
    end_time,
    duration
FROM [SSISDB].[catalog].[executions]
WHERE package_name = 'MainETL'
ORDER BY start_time DESC;
```

### Step 6: Schedule Execution

#### 6.1 Create SQL Server Agent Job
```sql
-- Create job
EXEC dbo.sp_add_job
    @job_name = N'DrillingDataETL_Job';

-- Add job step
EXEC dbo.sp_add_jobstep
    @job_name = N'DrillingDataETL_Job',
    @step_name = N'Execute MainETL Package',
    @command = N'EXEC [SSISDB].[catalog].[start_execution] @execution_id = ?',
    @database_name = N'msdb';

-- Schedule job
EXEC dbo.sp_add_schedule
    @schedule_name = N'Daily_Execution',
    @freq_type = 4, -- Daily
    @freq_interval = 1,
    @active_start_time = 020000; -- 2:00 AM

EXEC dbo.sp_attach_schedule
    @job_name = N'DrillingDataETL_Job',
    @schedule_name = N'Daily_Execution';
```

### Troubleshooting

#### Common Issues

1. **Permission Denied**
   - Ensure SSIS service account has necessary permissions
   - Check SQL Server service account permissions

2. **Connection Failed**
   - Verify SQL Server instance is running
   - Check firewall settings
   - Validate connection strings

3. **Package Execution Failed**
   - Check SSIS Catalog logs
   - Verify file paths exist
   - Check data source accessibility

4. **Memory Issues**
   - Adjust MaxConcurrentExecutables parameter
   - Increase SQL Server memory allocation
   - Optimize data flow settings

#### Log Analysis
```sql
-- View execution logs
SELECT 
    e.execution_id,
    e.package_name,
    e.status,
    e.start_time,
    e.end_time,
    m.message_time,
    m.message
FROM [SSISDB].[catalog].[executions] e
LEFT JOIN [SSISDB].[catalog].[operation_messages] m 
    ON e.execution_id = m.operation_id
WHERE e.package_name = 'MainETL'
ORDER BY m.message_time DESC;
```

### Performance Optimization

#### 1. Buffer Settings
- Adjust `DefaultBufferMaxRows` and `DefaultBufferSize`
- Use `RunInOptimizedMode = True`

#### 2. Parallel Execution
- Configure `MaxConcurrentExecutables`
- Use parallel data flows where possible

#### 3. Memory Management
- Monitor memory usage during execution
- Adjust batch sizes for large datasets

### Security Best Practices

1. **Use Windows Authentication**
2. **Encrypt sensitive data**
3. **Limit service account permissions**
4. **Regular security audits**
5. **Use environment-specific configurations**

### Maintenance

#### Regular Tasks
1. **Monitor execution logs**
2. **Clean up old execution history**
3. **Update project parameters as needed**
4. **Backup SSIS Catalog**
5. **Performance tuning**

#### Backup SSIS Catalog
```sql
-- Backup SSIS Catalog
BACKUP DATABASE [SSISDB] 
TO DISK = 'C:\Backup\SSISDB.bak'
WITH FORMAT, INIT, COMPRESSION;
```

