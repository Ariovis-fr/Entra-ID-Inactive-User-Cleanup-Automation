# ========================================
# Active Directory Provider
# Handles Active Directory queries
# ========================================

function Get-InactiveADUsers {
    <#
    .SYNOPSIS
    Retrieves inactive AD users

    .DESCRIPTION
    Queries Active Directory to get users inactive for X days

    .PARAMETER InactiveDays
    Number of days of inactivity (default: 75)

    .PARAMETER Server
    AD server to query

    .PARAMETER Credential
    Credentials for AD connection

    .EXAMPLE
    $users = Get-InactiveADUsers -InactiveDays 90 -Server "dc.example.com" -Credential $cred
    #>

    [CmdletBinding()]
    param(
        [int]$InactiveDays = 75,

        [Parameter(Mandatory)]
        [string]$Server,

        [Parameter(Mandatory)]
        [PSCredential]$Credential
    )

    try {
        Import-Module ActiveDirectory -ErrorAction Stop

        # Build the filter
        $filter = { Enabled -eq $true }

        # Retrieve all users with necessary properties
        $allUsers = Get-ADUser -Filter $filter -Server $Server -Credential $Credential -Properties LastLogon, LastLogonDate, mail, Manager, Enabled, WhenCreated

        # Calculate cutoff date
        $cutoffDate = (Get-Date).AddDays(-$InactiveDays)

        # Filter inactive users
        $inactiveUsers = $allUsers | Where-Object {
            $lastLogonDate = Get-ADUserLastLogonDate -User $_

            if ($lastLogonDate) {
                $lastLogonDate -lt $cutoffDate
            } else {
                # Include never-logged users if created more than InactiveDays ago
                if ($_.WhenCreated) {
                    $_.WhenCreated -lt $cutoffDate
                } else {
                    $false # Exclude users with neither last logon nor when created
                }
            }
        }

        # Map to standardized format
        $results = $inactiveUsers | ForEach-Object {
            $lastLogonDate = Get-ADUserLastLogonDate -User $_
            $daysSinceLogon = if ($lastLogonDate) {
                (New-TimeSpan -Start $lastLogonDate -End (Get-Date)).Days
            } else {
                $null
            }

            [PSCustomObject]@{
                SamAccountName   = $_.SamAccountName
                Name             = $_.Name
                Enabled          = $_.Enabled
                LastLogon        = $lastLogonDate
                DaysSinceLogon   = $daysSinceLogon
                Mail             = $_.mail
                Manager          = $_.Manager
                WhenCreated      = $_.WhenCreated
                DistinguishedName = $_.DistinguishedName
            }
        }

        return $results

    } catch {
        throw "Error retrieving AD users: $_"
    }
}

function Get-ADUserLastLogonDate {
    <#
    .SYNOPSIS
    Calculates AD user's last logon date

    .DESCRIPTION
    Uses LastLogonDate if available, otherwise converts LastLogon from FileTime

    .PARAMETER User
    AD user object

    .EXAMPLE
    $date = Get-ADUserLastLogonDate -User $adUser
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$User
    )

    # LastLogonDate is more reliable (replicated)
    if ($User.LastLogonDate) {
        return $User.LastLogonDate
    }

    # Fallback to LastLogon (local to DC)
    if ($User.LastLogon -and $User.LastLogon -gt 0) {
        try {
            return [DateTime]::FromFileTime($User.LastLogon)
        } catch {
            return $null
        }
    }

    return $null
}

function Get-ADCredentialFromConfig {
    <#
    .SYNOPSIS
    Creates a PSCredential object from configuration

    .PARAMETER Username
    AD username

    .PARAMETER Password
    Plain text password

    .EXAMPLE
    $cred = Get-ADCredentialFromConfig -Username "domain\admin" -Password "secret"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Username,

        [Parameter(Mandatory)]
        [string]$Password
    )

    $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    return New-Object System.Management.Automation.PSCredential($Username, $securePassword)
}

Export-ModuleMember -Function Get-InactiveADUsers, Get-ADUserLastLogonDate, Get-ADCredentialFromConfig
