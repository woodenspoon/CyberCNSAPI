Function Get-CCNSSettings {
    if (Get-Command Get-WSTBlobData -ErrorAction SilentlyContinue) {
        return Get-WSTBlobData -Module CyberCNSAPI -Name Settings -ErrorAction SilentlyContinue
    } else {
        return (Import-Clixml -Path "$ENV:USERPROFILE\cybercns.settings" -ErrorAction SilentlyContinue)
    }
}
