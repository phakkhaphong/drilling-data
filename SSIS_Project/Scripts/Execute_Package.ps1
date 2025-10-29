# SSIS Package Execution Script
# This script executes the MainETL package from SSIS Catalog

param(
    [Parameter(Mandatory=$true)]
    [string]$ServerInstance,
    
    [Parameter(Mandatory=$false)]
    [string]$FolderName = "DrillingDataETL",
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "DrillingDataETL",
    
    [Parameter(Mandatory=$false)]
    [string]$PackageName = "MainETL",
    
    [Parameter(Mandatory=$false)]
    [string]$EnvironmentName = "Production",
    
    [Parameter(Mandatory=$false)]
    [switch]$Synchronous
)

# Import SQL Server module
Import-Module SqlServer -ErrorAction SilentlyContinue

try {
    Write-Host "Starting SSIS Package Execution..." -ForegroundColor Green
    
    # Create execution
    $execution = New-Object Microsoft.SqlServer.Management.IntegrationServices.ExecutionInfo($server, $FolderName, $ProjectName, $PackageName, $EnvironmentName)
    
    # Set execution parameters
    $execution.Execute()
    
    if ($Synchronous) {
        Write-Host "Waiting for execution to complete..." -ForegroundColor Yellow
        $execution.WaitForCompletion()
        
        if ($execution.Status -eq "Succeeded") {
            Write-Host "Package execution completed successfully!" -ForegroundColor Green
        } else {
            Write-Host "Package execution failed with status: $($execution.Status)" -ForegroundColor Red
        }
    } else {
        Write-Host "Package execution started asynchronously. Execution ID: $($execution.ExecutionId)" -ForegroundColor Green
    }
    
} catch {
    Write-Error "Package execution failed: $($_.Exception.Message)"
    throw
}

