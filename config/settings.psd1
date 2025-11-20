# ========================================
# Application Settings
# Paramètres non-sensibles de l'application
# Les credentials doivent être dans .env
# ========================================

@{
    # Seuils d'inactivité
    InactiveDaysThreshold = 75

    # Formats de rapport disponibles
    ReportFormats = @('Text')

    # Format par défaut
    DefaultReportFormat = 'Text'

    # Chemin de sortie par défaut
    DefaultOutputPath = '.\reports'

    # Stratégie de matching AD <-> Entra ID
    # Options: 'SamAccountName', 'Mail', 'UPN'
    MatchingStrategy = 'SamAccountName'


    # Logging
    LogLevel = 'Info'  # Debug, Info, Warning, Error
    LogPath = '.\logs'

    # Connexion SQL
    SQLConnectionTimeout = 30
    SQLCommandTimeout = 300


    # Notifications mail (to do)


    # Connecteurs de désactivation (to do)
    DisableConnectors = @{
        Usercube = $false
    }

    # Politiques de rétention
    ReportRetentionDays = 90
    LogRetentionDays = 30
}
