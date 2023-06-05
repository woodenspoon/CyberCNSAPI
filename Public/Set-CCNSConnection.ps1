<#
.SYNOPSIS

Save the settings necessary to connect to the CyberCNS API

.DESCRIPTION

This function collect the URL, tenant name and user credentials required to connect to the CyberCNS API.

The settings are then saved in a WSTBlobData 'CyberCNSAPI/Settings'.

Returns $true if the settings were collected, $false otherwise.

.EXAMPLE

Set-CCNSConnection

Will record new settings.

#>
Function Set-CCNSConnection {
    [CmdletBinding()]
    param()

    Write-Host 'Enter the Base URI for your CyberCNS instance (eg portaluswest2.mycybercns.com): '
    $BaseURI = Read-Host

    Write-Host 'Enter the Tenant Name for your CyberCNS instance (eg wooden-spoon): '
    $TenantName = Read-Host

    Write-Host 'Enter the credentials of a user authorized to connect to your CyberCNS instance: '
    $Credentials = Get-Credential

    $Settings = [Hashtable] @{
        Credentials = $Credentials
        BaseURI = $BaseURI
        TenantName = $TenantName
    }

    Write-Verbose "Saving new parameters."
    $Settings | Set-WSTBlobData -Module CyberCNSAPI -Name Settings

}
