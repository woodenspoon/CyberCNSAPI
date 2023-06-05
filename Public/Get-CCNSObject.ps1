<#
.SYNOPSIS

Performs a GET on an API endpoint, passing optional query parameters, and returns the result as an object.

.DESCRIPTION

This function will call the CyberCNS API at a specified end point and perform a GET operation.

You can pass additional query parameters to refine the query.

The object returned is usually a list of properties, depending on the query.

.PARAMETER Endpoint

The API Endpoint to call, see LINK section in HELP.

.PARAMETER Conditions

Any condition to restrict the records returned, see LINK section in HELP.

.PARAMETER Fields

List of fields to return, see LINK section in HELP.

.PARAMETER PageSize

Number of records to return per page (default 100)

.PARAMETER ShowProgress

Show a progress indicator for long running queries

.LINK

https://portaluswest2.mycybercns.com/docs#/

.EXAMPLE

Get-CCNSObject -Endpoint 'company/'

.EXAMPLE

Get-CWMObject -Endpoint 'company/' -Conditions 'name LIKE "ABC%"'

#>
Function Get-CCNSObject {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory)]
		[string]$Endpoint,

		[string]$Conditions,

		[string]$Fields,

		[int]$PageSize,

		[switch]$ShowProgress
	)

	# Initialize the connection if it has expired (or is not active yet)
	if(-Not (Start-CCNSConnection)) {
		return $null
	}
		
	# Run the EndPoint paged calls and collect the results
	Write-Verbose "Executing endpoint '$EndPoint'"
	Add-Type -AssemblyName System.Web
	$URL = "https://{0}/api/{1}" -f $script:ccnsBaseURI, $EndPoint

	$Request = [System.UriBuilder]($URL)
	$Parameters = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
	if($Fields) {
		$Parameters['fields'] = $Fields
	}

	if($Conditions) {
		$Parameters['q'] = $Conditions
	}

	if($PageSize) {
		$Parameters['limit'] = $PageSize
	}

	$Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
	$Headers.Add("CustomerID", $script:ccnsTenantName)
	$Headers.Add("Authorization", $script:ccnsBasicAuth)

	$ReturnObject = @()
	$page = 0
	$lastPage = 0

	do {
		# Paginate
		$Parameters['skip'] = $page++
		$Request.Query = $Parameters.ToString()

		if ($lastPage) {
			if ($ShowProgress) { Write-Progress -Activity ("Endpoint: {0}, Page(s): {1}/{2}, Page Size: {3}" -f $Endpoint, $page, $lastPage, $PageSize) -PercentComplete ([math]::Min((($page / $lastPage) * 100), 100)) }
		}
		
		$restCallResult = @{}
		try {

			Write-Verbose "Hitting URL '$($Request.Uri)'"
			$res = Invoke-RestMethod -Uri "$($Request.Uri)" -Method Get -Headers $Headers -ContentType 'application/json'
		
		}
		catch {

			$restCallResult.exception = $_.Exception
			$restCallResult.error = 1

		}

		if ($restCallResult.error) {

			Write-Error ("Error connecting: Response was {0} - {1}" -f $restCallResult.exception.response.StatusCode, $restCallResult.exception.response.StatusDescription)
			return $false

		}

		# Either we received a collection of objects, and therefore we have the data collection, the count of objects returned and the total number in the collection ...
		if ((($res | Get-Member -Name 'data','count','total' -Type NoteProperty).count) -eq 3) {
			$content = $res.data
			if($content) {
				$ReturnObject += $content
			}
			$cnt = $res.Count
			$lastPage = [int]($res.Total / $PageSize)
		} else {
			# ... or we have a single object and there is nothing more to return
			$ReturnObject = $res
			$cnt = 0
		}

	} while ($cnt -gt 0)

	return $ReturnObject
}
