# Retrieves a DevOps PAT from the local secret store and converts it to a value
# suitable for an Authorization header in an API call.
function Get-DevopsApiAuth
{
	[CmdletBinding()]
	param
	(
		[Parameter( Mandatory )]
		[string] $AccessType
	)

	$ErrorActionPreference = "Stop"
	Set-StrictMode -Version Latest

	$secretName = "DevopsPatFor$AccessType"
	$secret = Get-Secret $secretName
	$decoded = $secret | ConvertFrom-SecureString -AsPlainText

	$base64 = ConvertTo-Base64String ":$decoded"
	"Basic $base64"
}

# Stores a PAT for future retrieval through Get-DevopsApiAuth
function Store-DevopsApiAuth
{
	[CmdletBinding()]
	param
	(
		[Parameter( Mandatory )]
		[string] $AccessType
	)

	$ErrorActionPreference = "Stop"
	Set-StrictMode -Version Latest

	$pat = Read-Host -AsSecureString -Prompt "Please enter the PAT for $AccessType"
	$secretName = "DevopsPatFor$AccessType"
	Set-Secret -Name $secretName -Secret $pat
	"Saved $secretName!"
}
