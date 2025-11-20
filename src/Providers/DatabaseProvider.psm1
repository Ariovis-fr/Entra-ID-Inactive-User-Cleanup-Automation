# ========================================
# Database Provider
# ========================================

function Save-ADUsersToDatabase {
    <#
    .SYNOPSIS
    Saves AD users to SQL Server

    .PARAMETER Users
    Collection of AD users to save

    .PARAMETER ConnectionString
    SQL connection string

    .PARAMETER TruncateFirst
    Clear table before insertion (default: true)

    .EXAMPLE
    Save-ADUsersToDatabase -Users $users -ConnectionString $connStr
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Users,

        [Parameter(Mandatory)]
        [string]$ConnectionString,

        [bool]$TruncateFirst = $true
    )

    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $ConnectionString
        $connection.Open()

        if ($TruncateFirst) {
            $command = $connection.CreateCommand()
            $command.CommandText = "TRUNCATE TABLE ADUserLogon"
            $command.ExecuteNonQuery() | Out-Null
        }

        $inserted = 0

        foreach ($user in $Users) {
            $command = $connection.CreateCommand()
            $command.CommandText = @"
INSERT INTO ADUserLogon (SamAccountName, Name, Status, LastLogon, Days, Mail)
VALUES (@SamAccountName, @Name, @Status, @LastLogon, @Days, @Mail)
"@
            $command.Parameters.AddWithValue("@SamAccountName", $user.SamAccountName) | Out-Null
            $command.Parameters.AddWithValue("@Name", $user.Name) | Out-Null
            $command.Parameters.AddWithValue("@Status", $(if ($user.Enabled) { "Enabled" } else { "Disabled" })) | Out-Null
            $command.Parameters.AddWithValue("@LastLogon", $(if ($user.LastLogon) { $user.LastLogon } else { [DBNull]::Value })) | Out-Null
            $command.Parameters.AddWithValue("@Days", $(if ($user.DaysSinceLogon) { $user.DaysSinceLogon } else { [DBNull]::Value })) | Out-Null
            $command.Parameters.AddWithValue("@Mail", $(if ($user.Mail) { $user.Mail } else { [DBNull]::Value })) | Out-Null

            try {
                $command.ExecuteNonQuery() | Out-Null
                $inserted++
            } catch {
                Write-Warning "Error inserting user $($user.SamAccountName): $_"
            }
        }

        $connection.Close()

        return $inserted

    } catch {
        throw "Error saving AD to SQL: $_"
    }
}

function Save-EntraIdUsersToDatabase {
    <#
    .SYNOPSIS
    Saves Entra ID users to SQL Server

    .PARAMETER Users
    Collection of Entra ID users to save

    .PARAMETER ConnectionString
    SQL connection string

    .PARAMETER TruncateFirst
    Clear table before insertion (default: true)

    .EXAMPLE
    Save-EntraIdUsersToDatabase -Users $users -ConnectionString $connStr
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Users,

        [Parameter(Mandatory)]
        [string]$ConnectionString,

        [bool]$TruncateFirst = $true
    )

    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $ConnectionString
        $connection.Open()

        if ($TruncateFirst) {
            $command = $connection.CreateCommand()
            $command.CommandText = "TRUNCATE TABLE EntraIDUserSignIn"
            $command.ExecuteNonQuery() | Out-Null
        }

        $inserted = 0

        foreach ($user in $Users) {
            $command = $connection.CreateCommand()
            $command.CommandText = @"
INSERT INTO EntraIDUserSignIn (DisplayName, UserPrincipalName, LastSignIn)
VALUES (@DisplayName, @UserPrincipalName, @LastSignIn)
"@
            $command.Parameters.AddWithValue("@DisplayName", $user.DisplayName) | Out-Null
            $command.Parameters.AddWithValue("@UserPrincipalName", $user.UserPrincipalName) | Out-Null
            $command.Parameters.AddWithValue("@LastSignIn", $(if ($user.LastSignIn) { $user.LastSignIn } else { [DBNull]::Value })) | Out-Null

            try {
                $command.ExecuteNonQuery() | Out-Null
                $inserted++
            } catch {
                Write-Warning "Error inserting user $($user.UserPrincipalName): $_"
            }
        }

        $connection.Close()

        return $inserted

    } catch {
        throw "Error saving Entra ID to SQL: $_"
    }
}

function Get-DatabaseStatistics {
    <#
    .SYNOPSIS
    Retrieves database statistics

    .PARAMETER ConnectionString
    SQL connection string

    .EXAMPLE
    $stats = Get-DatabaseStatistics -ConnectionString $connStr
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConnectionString
    )

    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $ConnectionString
        $connection.Open()

        $command = $connection.CreateCommand()
        $command.CommandText = "SELECT COUNT(*) FROM EntraIDUserSignIn"
        $countEntra = $command.ExecuteScalar()

        $command = $connection.CreateCommand()
        $command.CommandText = "SELECT COUNT(*) FROM ADUserLogon"
        $countAD = $command.ExecuteScalar()

        $connection.Close()

        return [PSCustomObject]@{
            EntraIdUserCount = $countEntra
            ADUserCount      = $countAD
            Timestamp        = Get-Date
        }

    } catch {
        throw "Error retrieving statistics: $_"
    }
}

function Test-DatabaseConnection {
    <#
    .SYNOPSIS
    Tests database connection

    .PARAMETER ConnectionString
    SQL connection string

    .EXAMPLE
    Test-DatabaseConnection -ConnectionString $connStr
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConnectionString
    )

    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $ConnectionString
        $connection.Open()
        $connection.Close()
        return $true
    } catch {
        return $false
    }
}

Export-ModuleMember -Function Save-ADUsersToDatabase, Save-EntraIdUsersToDatabase, Get-DatabaseStatistics, Test-DatabaseConnection
