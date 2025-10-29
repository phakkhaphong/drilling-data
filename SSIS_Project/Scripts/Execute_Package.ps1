# SSIS Package Execution Script
# This script executes SSIS packages from the SSIS Catalog

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
    [string]$PackageName,
    
    [Parameter(Mandatory=$false)]
    [hashtable]$Parameters = @{}
)

Write-Host "Executing SSIS Package: $PackageName" -ForegroundColor Green
Write-Host "Server Instance: $ServerInstance" -ForegroundColor Yellow
Write-Host "Project: $ProjectName" -ForegroundColor Yellow

try {
    # Load SQL Server Management Objects
    Add-Type -Path "C:\Program Files (x86)\Microsoft SQL Server Management Objects 19.0\Microsoft.SqlServer.Smo.dll"
    Add-Type -Path "C:\Program Files (x86)\Microsoft SQL Server Management Objects 19.0\Microsoft.SqlServer.ConnectionInfo.dll"
    Add-Type -Path "C:\Program Files (x86)\Microsoft SQL Server Management Objects 19.0\Microsoft.SqlServer.Management.IntegrationServices.dll"

    # Create connection to SQL Server
    $connection = New-Object Microsoft.SqlServer.Management.Common.ServerConnection
    $connection.ServerInstance = $ServerInstance
    $connection.Connect()

    # Create Integration Services object
    $integrationServices = New-Object Microsoft.SqlServer.Management.IntegrationServices.IntegrationServices($connection)

    # Get catalog and folder
    $catalog = $integrationServices.Catalogs[$CatalogName]
    $folder = $catalog.Folders[$FolderName]
    $project = $folder.Projects[$ProjectName]

    if ($project -eq $null) {
        throw "Project '$ProjectName' not found in folder '$FolderName'"
    }

    # Get package
    $package = $project.Packages[$PackageName]
    if ($package -eq $null) {
        throw "Package '$PackageName' not found in project '$ProjectName'"
    }

    # Create execution
    $execution = $catalog.Executions.Create($project.Name, $folder.Name, $PackageName)
    
    # Set parameters
    foreach ($param in $Parameters.GetEnumerator()) {
        $execution.SetParameterValue($param.Key, $param.Value)
    }

    # Start execution
    Write-Host "Starting package execution..." -ForegroundColor Yellow
    $execution.Start()

    # Monitor execution
    $executionId = $execution.ExecutionId
    Write-Host "Execution ID: $executionId" -ForegroundColor Cyan

    do {
        Start-Sleep -Seconds 5
        $execution.Refresh()
        $status = $execution.Status
        
        switch ($status) {
            "Running" { Write-Host "Status: Running..." -ForegroundColor Yellow }
            "Succeeded" { Write-Host "Status: Succeeded!" -ForegroundColor Green }
            "Failed" { Write-Host "Status: Failed!" -ForegroundColor Red }
            "Cancelled" { Write-Host "Status: Cancelled!" -ForegroundColor Yellow }
            default { Write-Host "Status: $status" -ForegroundColor Cyan }
        }
    } while ($status -eq "Running")

    # Display final status
    if ($status -eq "Succeeded") {
        Write-Host "Package execution completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "Package execution failed or was cancelled." -ForegroundColor Red
        Write-Host "Check SSIS Catalog logs for details." -ForegroundColor Yellow
    }

} catch {
    Write-Error "Execution failed: $($_.Exception.Message)"
    exit 1
} finally {
    if ($connection -ne $null) {
        $connection.Disconnect()
    }
}

Write-Host "Execution script completed." -ForegroundColor Green