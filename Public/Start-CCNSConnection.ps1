<#
.SYNOPSIS

Initiates a connection to the CyberCNS API

.DESCRIPTION

This function will connect to the CyberCNS API on your dashboard.

The function will read the parameters from the WSTBlobData 'CyberCNSAPI/Settings', unless manual parameters are passed.

Returns $true if successful, $false if the connection was not successful.

.EXAMPLE

Start-CCNSConnection

#>
Function Start-CCNSConnection {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'Manual')]
        [switch]$VerifyLogin,
        [Parameter(Mandatory = $true, ParameterSetName = 'Manual')]
        [string]$ManualClientID,
        [Parameter(Mandatory = $true, ParameterSetName = 'Manual')]
        [string]$ManualClientSecret,
        [Parameter(Mandatory = $true, ParameterSetName = 'Manual')]
        [string]$ManualBaseURI,
        [Parameter(Mandatory = $true, ParameterSetName = 'Manual')]
        [string]$ManualTenantName
    )

    switch ($PsCmdlet.ParameterSetName) {
        "Manual" {
            Write-Verbose "Manual parameters passed, using those to make a connection."

            $ClientID = $ManualClientID
            $ClientSecret = $ManualClientSecret
            $BaseURI = $ManualBaseURI
            $TenantName = $ManualTenantName

            # Force a new connection with the manual parameters
            $VerifyLogin = $true
            break
        }

        default { 

            if ((-not $VerifyLogin) -and ($script:ccnsBaseURI) -and ($script:ccnsTenantName) -and ($script:ccnsBasicAuth)) {

                Write-Verbose "Module variables already set, skipping."
                return $true
        
            }
            
            # Clear the script variables so that no other cmdLet can use them until we have confirmed we have good values
            $script:ccnsBaseURI = $null
            $script:ccnsTenantName = $null
            $script:ccnsBasicAuth = $null
        
            # Read the settings from the blob
            $Settings = Get-CCNSSettings
            if (-Not ($Settings)) {
                Write-Error "Unable to read settings from WSTBlobData 'CyberCNSAPI/Settings', please use Set-CCNSConnection"
                return $false
            }
        
            $Credentials = $Settings.Credentials
            $BaseURI = $Settings.BaseURI
            $TenantName = $Settings.TenantName
        
            if ($Credentials) {
        
                $ClientID = $Credentials.UserName
                $ClientSecret = $Credentials.GetNetworkCredential().Password
        
            }
        
        }
    }

    if ((-Not $ClientID) -Or (-Not $ClientSecret) -Or (-Not $BaseURI) -Or (-Not $TenantName)) {

        Write-Error "Some parameters are missing, please use Set-CCNSConnection to enter them."
        return $false

    }

    $BasicAuth = "Basic {0}" -f ([Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $clientID, $clientSecret))))

    if ($VerifyLogin) {

        Write-Verbose "Verifying that the connection settings are valid"
        Add-Type -AssemblyName System.Web
        $URL = "https://{0}/api/{1}/login" -f $BaseURI, $TenantName
    
        $Request = [System.UriBuilder]($URL)
        $Parameters = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
        $Request.Query = $Parameters.ToString()

        $Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $Headers.Add("CustomerID", $TenantName)
        $Headers.Add("Authorization", $BasicAuth)
    
        $restCallResult = @{}
        try {
    
            Write-Verbose "Hitting URL '$($Request.Uri)'"
            $res = Invoke-RestMethod -Uri "$($Request.Uri)" -Method Get -Headers $Headers
    
        }
        catch {
    
            $restCallResult.exception = $_.Exception
            $restCallResult.error = 1
    
        }
    
        if ($restCallResult.error) {
    
            Write-Error ("Error connecting: Response was {0} - {1}" -f $restCallResult.exception.response.StatusCode, $restCallResult.exception.response.StatusDescription)
            return $false
    
        }

        Write-Verbose "Call returned the following result:"
        Write-Verbose ($res | ConvertTo-Json)
    }

    $script:ccnsBaseURI = $BaseURI
    $script:ccnsTenantName = $TenantName
    $script:ccnsBasicAuth = $BasicAuth

    Write-Verbose "Module variables set, all good to proceed."
    return $true

}