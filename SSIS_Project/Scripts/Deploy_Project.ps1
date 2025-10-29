# SSIS Project Deployment Script for SQL Server 2022
# This script deploys the DrillingDataETL project to SSIS Catalog

param(
    [Parameter(Mandatory=$true)]
    [string]$ServerInstance,
    
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,
    
    [Parameter(Mandatory=$false)]
    [string]$FolderName = "DrillingDataETL",
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "DrillingDataETL",
    
    [Parameter(Mandatory=$false)]
    [string]$EnvironmentName = "Production"
)

# Import SQL Server module
Import-Module SqlServer -ErrorAction SilentlyContinue

try {
    Write-Host "Starting SSIS Project Deployment..." -ForegroundColor Green
    
    # Check if SSIS Catalog exists
    $catalogExists = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query "SELECT COUNT(*) as CatalogCount FROM sys.databases WHERE name = 'SSISDB'" -Database "master"
    
    if ($catalogExists.CatalogCount -eq 0) {
        Write-Host "Creating SSIS Catalog..." -ForegroundColor Yellow
        New-SqlCatalog -ServerInstance $ServerInstance
    }
    
    # Create folder if it doesn't exist
    Write-Host "Creating folder: $FolderName" -ForegroundColor Yellow
    $folder = New-Object Microsoft.SqlServer.Management.IntegrationServices.CatalogFolder($server, $FolderName, $null)
    $folder.Create()
    
    # Deploy project
    Write-Host "Deploying project: $ProjectName" -ForegroundColor Yellow
    $project = $folder.DeployProject($ProjectName, $ProjectPath)
    
    # Create environment
    Write-Host "Creating environment: $EnvironmentName" -ForegroundColor Yellow
    $environment = New-Object Microsoft.SqlServer.Management.IntegrationServices.EnvironmentInfo($folder, $EnvironmentName, $null)
    $environment.Create()
    
    # Set environment variables
    Write-Host "Setting environment variables..." -ForegroundColor Yellow
    $environment.Variables.Add("ExcelFilePath", [Microsoft.SqlServer.Management.IntegrationServices.DataType]::String, "data/raw/DH70.xlsx", $false, $null)
    $environment.Variables.Add("SQLServerInstance", [Microsoft.SqlServer.Management.IntegrationServices.DataType]::String, $ServerInstance, $false, $null)
    $environment.Variables.Add("DatabaseName", [Microsoft.SqlServer.Management.IntegrationServices.DataType]::String, "DrillingDatabase", $false, $null)
    $environment.Variables.Add("ProcessedDataPath", [Microsoft.SqlServer.Management.IntegrationServices.DataType]::String, "data/processed", $false, $null)
    $environment.Variables.Add("LogLevel", [Microsoft.SqlServer.Management.IntegrationServices.DataType]::Int32, 4, $false, $null)
    $environment.Variables.Add("MaxConcurrentExecutables", [Microsoft.SqlServer.Management.IntegrationServices.DataType]::Int32, 4, $false, $null)
    $environment.Variables.Add("ErrorOutputPath", [Microsoft.SqlServer.Management.IntegrationServices.DataType]::String, "data/error", $false, $null)
    $environment.Variables.Add("BatchSize", [Microsoft.SqlServer.Management.IntegrationServices.DataType]::Int32, 1000, $false, $null)
    
    $environment.Alter()
    
    # Create environment reference
    Write-Host "Creating environment reference..." -ForegroundColor Yellow
    $project.CreateEnvironmentReference($EnvironmentName, $FolderName, $false)
    
    Write-Host "Deployment completed successfully!" -ForegroundColor Green
    Write-Host "Project: $ProjectName" -ForegroundColor Cyan
    Write-Host "Folder: $FolderName" -ForegroundColor Cyan
    Write-Host "Environment: $EnvironmentName" -ForegroundColor Cyan
    
} catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    throw
}

