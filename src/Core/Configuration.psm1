# ========================================
# Configuration Manager
# Loads and validates configuration from .env and settings.psd1
# ========================================

function Get-AppConfiguration {

    # Loads parameters from .env and settings.psd1

    [CmdletBinding()]
    param(
        [string]$ConfigPath = "$PSScriptRoot\..\..\..env"
    )

    if (-not (Test-Path $ConfigPath)) {
        throw "Configuration file not found: $ConfigPath"
    }

    $config = @{}

    Get-Content $ConfigPath | ForEach-Object {
        $line = $_.Trim()

        # Ignore comments and empty lines
        if ($line -and -not $line.StartsWith('#')) {
            if ($line -match '^([^=]+)=(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()

                # Remove quotes if present
                if ($value -match '^"(.*)"$' -or $value -match "^'(.*)'$") {
                    $value = $matches[1]
                }

                $config[$key] = $value
            }
        }
    }

    # Load settings.psd1 if exists
    $settingsPath = "$PSScriptRoot\..\..\config\settings.psd1"
    if (Test-Path $settingsPath) {
        $settings = Import-PowerShellDataFile -Path $settingsPath
        foreach ($key in $settings.Keys) {
            if (-not $config.ContainsKey($key)) {
                $config[$key] = $settings[$key]
            }
        }
    }

    # Validate minimal configuration
    $requiredKeys = @('SQL_SERVER', 'SQL_DATABASE', 'SQL_USERNAME', 'SQL_PASSWORD')
    foreach ($key in $requiredKeys) {
        if (-not $config.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($config[$key])) {
            throw "Missing configuration: $key"
        }
    }

    return [PSCustomObject]$config
}

function Test-AppConfiguration {

    # Tests connectivity to configured services

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config
    )

    $errors = @()

    # Test SQL connection
    try {
        $connectionString = "Server=$($Config.SQL_SERVER);Database=$($Config.SQL_DATABASE);User Id=$($Config.SQL_USERNAME);Password=$($Config.SQL_PASSWORD);TrustServerCertificate=True;Connection Timeout=5;"
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $connectionString
        $connection.Open()
        $connection.Close()
    } catch {
        $errors += "SQL connection failed: $_"
    }

    # Test AD configuration
    if ($Config.AD_SERVER) {
        if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
            $errors += "ActiveDirectory module not available"
        }
    }

    # Test Entra ID configuration
    if ($Config.TENANT_ID) {
        if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
            $errors += "Microsoft.Graph module not available"
        }

        if (-not $Config.CLIENT_ID -or -not $Config.CLIENT_SECRET) {
            $errors += "CLIENT_ID or CLIENT_SECRET missing for Entra ID"
        }
    }

    if ($errors.Count -gt 0) {
        throw "Configuration errors:`n$($errors -join "`n")"
    }

    return $true
}

Export-ModuleMember -Function Get-AppConfiguration, Test-AppConfiguration
