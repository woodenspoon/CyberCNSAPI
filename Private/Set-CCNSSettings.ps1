Function Set-CCNSSettings {
    param($Settings)
    if (Get-Command Get-WSTBlobData -ErrorAction SilentlyContinue) {
        $Settings | Set-WSTBlobData -Module CyberCNSAPI -Name Settings
    } else {
        $Settings | Export-Clixml -Path "$ENV:USERPROFILE\cybercns.settings"
    }
}
