# ========================================
# Non-sensitive application settings
# ========================================

@{
    # Inactivity thresholds
    InactiveDaysThreshold = 75

    # Available report formats
    ReportFormats = @('Text')

    # Default format
    DefaultReportFormat = 'Text'

    # Default output path
    DefaultOutputPath = '.\reports'

    # AD <-> Entra ID matching strategy
    # Options: 'SamAccountName', 'Mail', 'UPN'
    MatchingStrategy = 'SamAccountName'

    # SQL Connection
    SQLConnectionTimeout = 30
    SQLCommandTimeout = 300


    # Mail notifications (to do)


    # Disable connectors
    DisableConnectors = @{
        Usercube = $false
    }
}
