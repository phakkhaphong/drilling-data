# SSIS Project Deployment Script
# This script deploys the SSIS project to SQL Server Integration Services Catalog

param(
    [Parameter(Mandatory=$true)]
    [string]$ServerInstance,
    
    [Parameter(Mandatory=$true)]
    [string]$CatalogName = "SSISDB",
    
    [Parameter(Mandatory=$true)]
    [string]$FolderName = "DrillingDataETL",
    
    [Parameter(Mandatory=$true)]
    [string]$ProjectName = "DrillingDataETL",
    
    [Parameter(Mandatory=$true)]
    [string]$ProjectFilePath
)

Write-Host "Deploying SSIS Project: $ProjectName" -ForegroundColor Green
Write-Host "Server Instance: $ServerInstance" -ForegroundColor Yellow
Write-Host "Catalog: $CatalogName" -ForegroundColor Yellow
Write-Host "Folder: $FolderName" -ForegroundColor Yellow

try {
    # Load SQL Server Management Objects
    Add-Type -Path "C:\Program Files (x86)\Microsoft SQL Server Management Objects 19.0\Microsoft.SqlServer.Smo.dll"
    Add-Type -Path "C:\Program Files (x86)\Microsoft SQL Server Management Objects 19.0\Microsoft.SqlServer.ConnectionInfo.dll"
    Add-Type -Path "C:\Program Files (x86)\Microsoft SQL Server Management Objects 19.0\Microsoft.SqlServer.Management.IntegrationServices.dll"

    # Create connection to SQL Server
    $connectionString = "Data Source=$ServerInstance;Initial Catalog=master;Integrated Security=SSPI;"
    $connection = New-Object Microsoft.SqlServer.Management.Common.ServerConnection
    $connection.ServerInstance = $ServerInstance
    $connection.Connect()

    # Create Integration Services object
    $integrationServices = New-Object Microsoft.SqlServer.Management.IntegrationServices.IntegrationServices($connection)

    # Get or create catalog
    $catalog = $integrationServices.Catalogs[$CatalogName]
    if ($catalog -eq $null) {
        Write-Host "Creating catalog: $CatalogName" -ForegroundColor Yellow
        $catalog = New-Object Microsoft.SqlServer.Management.IntegrationServices.Catalog($integrationServices, $CatalogName, "SSISDB")
        $catalog.Create()
    }

    # Get or create folder
    $folder = $catalog.Folders[$FolderName]
    if ($folder -eq $null) {
        Write-Host "Creating folder: $FolderName" -ForegroundColor Yellow
        $folder = New-Object Microsoft.SqlServer.Management.IntegrationServices.CatalogFolder($catalog, $FolderName, "Drilling Data ETL Project")
        $folder.Create()
    }

    # Deploy project
    Write-Host "Deploying project from: $ProjectFilePath" -ForegroundColor Yellow
    $projectBytes = [System.IO.File]::ReadAllBytes($ProjectFilePath)
    $folder.DeployProject($ProjectName, $projectBytes)

    Write-Host "Project deployed successfully!" -ForegroundColor Green

} catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    exit 1
} finally {
    if ($connection -ne $null) {
        $connection.Disconnect()
    }
}

Write-Host "Deployment completed." -ForegroundColor Green