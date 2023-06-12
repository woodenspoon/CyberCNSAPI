<#
.SYNOPSIS

Add a new object on an API endpoint.

.DESCRIPTION

This function will call the CyberCNS API at a specified end point and perform a POST operation to create a new object.

The object can be passed as either an object or in JSON format.

.PARAMETER Endpoint

The API Endpoint to call, see LINK section in HELP.

.PARAMETER Object

The object properties to create, either as an object or a string in JSON format.

.PARAMETER JSON

Interpret the object as a JSON string.

.LINK

https://cybercns.atlassian.net/wiki/spaces/Verison2/pages/1755676675/CyberCNS+API+Documentation

.EXAMPLE

Add-CCNSObject -Endpoint 'company' -Object $json

#>
Function Add-CCNSObject {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory)]
		[string]$Endpoint,

        [Parameter(ValueFromPipeline,Mandatory)]
        [object]$Object,

        [switch]$JSON
	)

	# Initialize the connection if it has expired (or is not active yet)
	if(-Not (Start-CCNSConnection)) {
		return $null
	}

    # Determine if the object needs to be converted to a JSON string
    if ($JSON) {
        $obj = $Object
    } else {
        $obj = $Object | ConvertTo-Json
    }

    # Run the EndPoint
	Write-Verbose "Executing POST on endpoint '$EndPoint'"
	Add-Type -AssemblyName System.Web
	$URL = "https://{0}/api/{1}/" -f $script:ccnsBaseURI, $EndPoint

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
        Write-Verbose "Making following changes:"
        Write-Verbose "$obj"
        $res = Invoke-RestMethod -Uri "$($Request.Uri)" -Method Post -Headers $Headers -ContentType 'application/json' -Body $obj
    
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
