<#
.SYNOPSIS

Performs a DELETE on an API endpoint, deleting an entire object.

.DESCRIPTION

This function will call the CyberCNS API at a specified end point with a unique ID and perform a DELETE operation.

The object to be deleted has to be passed as parameter by its ID.

.PARAMETER Endpoint

The API Endpoint to call, see LINK section in HELP.

.PARAMETER ID

The ID of the object to delete.

.LINK

https://cybercns.atlassian.net/wiki/spaces/Verison2/pages/1755676675/CyberCNS+API+Documentation

.EXAMPLE

Delete-CCNSObject -Endpoint 'assetcredentials' -ID 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'

#>
Function Remove-CCNSObject {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory)]
		[string]$Endpoint,

		[Parameter(Mandatory)]
        [object]$ID
	)

	# Initialize the connection if it has expired (or is not active yet)
	if(-Not (Start-CCNSConnection)) {
		return $null
	}

    # Run the EndPoint
	Write-Verbose "Executing DELETE on endpoint '$EndPoint'"
	Add-Type -AssemblyName System.Web
	$URL = "https://{0}/api/{1}/{2}" -f $script:ccnsBaseURI, $EndPoint, $ID

	$Request = [System.UriBuilder]($URL)
	$Parameters = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
    $Request.Query = $Parameters.ToString()

	$Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
	$Headers.Add("CustomerID", $script:ccnsTenantName)
	$Headers.Add("Authorization", $script:ccnsBasicAuth)

	$ReturnObject = @()

    $restCallResult = @{}
    try {

        Write-Verbose "Hitting URL '$($Request.Uri)'"
        Write-Verbose "Deleting following ID: '$ID'"
        $res = Invoke-RestMethod -Uri "$($Request.Uri)" -Method Delete -Headers $Headers -ContentType 'application/json'
    
    }
    catch {

        $restCallResult.exception = $_.Exception
        $restCallResult.error = 1

    }

    if ($restCallResult.error) {

        Write-Error ("Error connecting: Response was {0} - {1}" -f $restCallResult.exception.response.StatusCode, $restCallResult.exception.response.StatusDescription)
        return $false

    }

	$ReturnObject = $res

	return $ReturnObject
}
