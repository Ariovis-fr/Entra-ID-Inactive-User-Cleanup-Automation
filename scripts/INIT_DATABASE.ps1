# ========================================
# DATABASE INITIALIZATION
# Run this ONCE at the beginning
# ========================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DATABASE INITIALIZATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Load environment variables from .env
$envFile = "$PSScriptRoot\.env"

if (-not (Test-Path $envFile)) {
    Write-Host "[ERROR] .env file not found: $envFile" -ForegroundColor Red
    exit 1
}

Get-Content $envFile | ForEach-Object {
    if ($_ -match '^([^=]+)=(.+)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        Set-Variable -Name $key -Value $value -Scope Script
    }
}

Write-Host ""
Write-Host "[1/2] Creating database..." -ForegroundColor Yellow

$connectionString = "Server=$SQL_SERVER;Database=master;User Id=$SQL_USERNAME;Password=$SQL_PASSWORD;TrustServerCertificate=True;"

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()

    $command = $connection.CreateCommand()
    $command.CommandText = "IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = '$SQL_DATABASE') BEGIN CREATE DATABASE [$SQL_DATABASE] END"
    $command.ExecuteNonQuery() | Out-Null

    Write-Host "  [OK] Database '$SQL_DATABASE' created/verified" -ForegroundColor Green

    $connection.Close()
} catch {
    Write-Host "  [ERROR] SQL: $_" -ForegroundColor Red
    Write-Host "  Check your SQL Server parameters in the .env file" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[2/2] Creating tables..." -ForegroundColor Yellow

# Connect to the new database
$connectionString = "Server=$SQL_SERVER;Database=$SQL_DATABASE;User Id=$SQL_USERNAME;Password=$SQL_PASSWORD;TrustServerCertificate=True;"

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()

    # Create ADUserLogon table
    $command = $connection.CreateCommand()
    $command.CommandText = @"
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ADUserLogon')
BEGIN
    CREATE TABLE ADUserLogon (
        Id INT PRIMARY KEY IDENTITY(1,1),
        SamAccountName VARCHAR(100) NOT NULL,
        Name VARCHAR(200) NOT NULL,
        Status VARCHAR(500),
        LastLogon DATETIME,
        Days INT,
        Mail VARCHAR(100),
        MailManager VARCHAR(100),
        Relance1 BIT,
        Relance2 BIT
    )
END
"@
    $command.ExecuteNonQuery() | Out-Null

    Write-Host "  [OK] Table ADUserLogon created" -ForegroundColor Green

    # Create EntraIDUserSignIn table
    $command.CommandText = @"
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'EntraIDUserSignIn')
BEGIN
    CREATE TABLE EntraIDUserSignIn (
        Id INT PRIMARY KEY IDENTITY(1,1),
        DisplayName NVARCHAR(255),
        UserPrincipalName NVARCHAR(255),
        LastSignIn DATETIME
    )
END
"@
    $command.ExecuteNonQuery() | Out-Null

    Write-Host "  [OK] Table EntraIDUserSignIn created" -ForegroundColor Green

    $connection.Close()

} catch {
    Write-Host "  [ERROR] Table creation: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "INITIALIZATION COMPLETED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Database: $SQL_DATABASE" -ForegroundColor White
Write-Host "SQL Server: $SQL_SERVER" -ForegroundColor White
Write-Host ""
Write-Host "You can now run the main script:" -ForegroundColor Cyan
Write-Host "  .\Invoke-InactiveUserScan.ps1" -ForegroundColor Gray
Write-Host ""
