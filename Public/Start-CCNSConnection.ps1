<#
$baseURI = "https://portaluswest2.mycybercns.com"
$tenant = "wooden-spoon"
$clientID = "51000ae7-abea-4f79-8432-7da45af0363e"
$clientSecret = "oVpjpmOKo2IPVoC41VaLnbt9zxeoxFsQ"
$basicAuth = "Basic {0}" -f ([Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $clientID, $clientSecret))))

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("CustomerID", $tenant)
$headers.Add("Authorization", $basicAuth)

$response = Invoke-RestMethod -Uri "$($baseURI)/api/$($tenant)/login" -Method Get -Headers $headers
$response | ConvertTo-Json
#>

<#
.SYNOPSIS

Initiates a connection to the CyberCNS REST API

.DESCRIPTION

This function will connect to the CyberCNS API on your server.

If no parameter is provided it will try to read those parameters from the registry. If not, it will prompt you for initial URL and credentials, unless you provide them as parameters.

Returns $null if the connection was not successful.

.PARAMETER URL

The URL to your CyberCNS server API (https://api-na.myconnectwise.net/v4_6_release/apis/3.0 for US-based partners).

.PARAMETER ClientID

The ClientID assigned to your partner account when you signed up at https://developer.connectwise.com.

.PARAMETER PartnerID

Your Manage partner ID.

.PARAMETER PublicKey

The PublicKey to login to your installation, it is recommended to use an account dedicated to that function, with the minimal set of permissions required for the job.

.PARAMETER PrivateKey

The corresponding PrivateKey.

.PARAMETER Force

This will force a new connection to the API, regardless of the current state (gets a new API token).

.PARAMETER Clear

This will delete the current CWMSettings.xml stored in your PS profile path. If you also provide new credentials and URL it will save those to the new file, or prompt you for new values.

.PARAMETER NoSave

Do not save the current parameters to CWMSettings.xml.

.EXAMPLE

Start-CCNSConnection

Will (re)connect to the current Manage server. If no settings had been saved before, will prompt for those parameters.

.EXAMPLE

Start-CCNSConnection -URL https://api-na.myconnectwise.net/v4_6_release/apis/3.0 -ClientID MyPartnerClientID -PublicKey 1f83f4f8 -PrivateKey 1f83f4f8

Will initiate a connection to the standard hosted Manage server for North America partnerts using the user's public and private keys, and store the URL and credentials in the CWMSettings.xml file.

.EXAMPLE

Start-CCNSConnection -Clear

Will delete the existing CWMSettings.xml and prompt you to enter new parameters.

.EXAMPLE

Start-CCNSConnection -Clear -NoSave -Force

Will delete the existing CWMSettings.xml and prompt you to enter new parameters but will not save those parameters. Subsequent calls will prompt you again before initiating a new connection (even if this last one succedded).

#>
Function Start-CCNSConnection {
	[CmdletBinding()]
	param(
		[Parameter(ParameterSetName = 'Explicit')]
		[string]$URL,

		[Parameter(ParameterSetName = 'Explicit')]
		[string]$ClientID,

		[Parameter(ParameterSetName = 'Explicit')]
		[string]$PartnerID,

		[Parameter(ParameterSetName = 'Explicit')]
		[string]$PublicKey,

		[Parameter(ParameterSetName = 'Explicit')]
		[string]$PrivateKey,

		[switch]$Force = $false,

		[switch]$Clear = $false,

		[switch]$NoSave = $false
	)

	# If user specified URL, PublicKey and PrivateKey as parameters, save them for future calls
	if($PSCmdlet.ParameterSetName -eq 'Explicit') {

		Write-Verbose "CmdLet invoked with all parameters, evaluating.";

		$pw = $PrivateKey | ConvertTo-SecureString -asPlainText -Force;
		$Credentials = New-Object System.Management.Automation.PSCredential($PublicKey, $pw);

		$script:cwmURL = $URL;
		$script:cwmClientID = $ClientID;
		$script:cwmPartnerID = $PartnerID;

		$Settings = [Hashtable] @{
			Credentials = $Credentials;
			URL = $script:cwmURL;
			ClientID = $ClientID;
			PartnerID = $PartnerID;
		}

		if(-Not $NoSave) {

			Write-Verbose "Saving all new parameters.";
			$Settings | Set-WSTBlobData -Module ManageAPI -Name Settings

		}
		else {

			Write-Verbose "NoSave parameter specified, parameters will not be saved.";

		}

		$Force = $true;	# Force a connection with those settings, even if one already existed

	}
	else {


		# If no credentials were ever saved, prompt user and save credentials
		$Settings = Get-WSTBlobData -Module ManageAPI -Name Settings
		if ((-Not ($Settings)) -Or ($Clear)) {

			Write-Verbose 'No CWMSettings file found, asking for credentials.';
			
			Write-Host 'Enter the CyberCNS API URL for your Manage server (eg https://api-na.myconnectwise.net/v4_6_release/apis/3.0): ';
			$URL = Read-Host;
			Write-Host 'Enter your Connectwise partner developer ClientID: ';
			$ClientID = Read-Host;
			Write-Host 'Enter your Connectwise partner ID: ';
			$PartnerID = Read-Host;
			Write-Host 'Enter the credentials of a user authorized to connect to your Manage server: ';
			$Credentials = Get-Credential;

			$script:cwmURL = $URL;
			$script:cwmClientID = $ClientID;
			$script:cwmPartnerID = $PartnerID;

			$Settings = [Hashtable] @{
				Credentials = $Credentials;
				URL = $script:cwmURL;
				ClientID = $script:cwmClientID;
				PartnerID = $script:cwmPartnerID;
			}

			if(-Not $NoSave) {

				Write-Verbose "Saving new parameters.";
				$Settings | Set-WSTBlobData -Module ManageAPI -Name Settings

			}
			else {

				Write-Verbose "NoSave parameter specified, parameters will not be saved.";

			}

			$Force = $true;	# Force a connection with those settings, even if one already existed

		}

		$Settings = Get-WSTBlobData -Module ManageAPI -Name Settings

		if($Settings) {

			$Credentials = $Settings.Credentials;
			$script:cwmURL = $Settings.URL;
			$script:cwmClientID = $Settings.ClientID;
			$script:cwmPartnerID = $Settings.PartnerID;

		}
		if($Credentials) {

			$PublicKey = $Credentials.UserName;
			$PrivateKey = $Credentials.GetNetworkCredential().Password;

		}
		Write-Verbose ("Using URL '{0}' and PublicKey '{1}'." -f $script:cwmURL, $PublicKey);

	}

	if((-Not $PublicKey) -Or (-Not $PrivateKey) -Or (-Not $script:cwmURL) -Or (-Not $script:cwmClientID) -Or (-Not $script:cwmPartnerID)) {

		Write-Error "Some parameters are missing, please use -Clear to re-enter them";
		return $null;

	}

	if($force) {

		Write-Verbose "Force parameter specified or new connection required, clearing current connection.";
		$script:header = $null;

	}

	$Auth = $script:cwmPartnerID + '+' + $PublicKey + ':' + $PrivateKey;
	$Bytes = [System.Text.Encoding]::ASCII.GetBytes($Auth);
	$EncodedAuth =[Convert]::ToBase64String($Bytes);

	$script:header = [Hashtable] @{
		Authorization = 'Basic ' + $EncodedAuth;
		ClientID = $cwmClientID;
	}

	Write-Verbose "Settings appear to be correct.";

	return $true;

}
