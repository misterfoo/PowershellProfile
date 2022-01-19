[CmdletBinding( SupportsShouldProcess )]
param
(
	[Parameter( Mandatory )]
	[string] $TimeularExportCsv,

	[Parameter()]
	[int] $StartingRecord
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

$workspace = 5790557

# Figure out the authentication to use for Toggl
$apiKeySecret = Get-Secret "TogglApiKey"
$apiKey = $apiKeySecret | ConvertFrom-SecureString -AsPlainText
$authString = ConvertTo-Base64String "${apiKey}:api_token"
$apiHeader = @{ Authorization = "Basic $authString" }

# Read the raw data from timeular
$rows = Import-CSV $TimeularExportCsv
$hours = $rows | Measure-Object -Sum { ([timespan]$_.Duration).TotalHours } | % Sum -WhatIf:$false
if( $hours -lt 35 )
{
	throw "Less than 35 hours recorded! ($hours)"
}

$map = @{
	"Email/overhead" = @{ P = "AVN_171"; T = "100 | Admin & All other unapplied" }
	"TogglFusion" = @{ P = "AVN_ASDS-729"; T = "F03 | Engineering" }
	"EMS platform development" = @{ P = "AVN_28-B"; T = "R03 | Engineering" }
	"PTO" = @{ P = "AVN_171"; T = "260 | PTO - Permissive Time Off" }
	"EMS operations" = @{ P = "AVN_FAS76"; T = "F03 | Engineering" }
	"Lufthansa support" = @{ P = "AVN_74"; T = "S02 | L3/L4" }
	"American Airlines support" = @{ P = "AVN_65"; T = "S02 | L3/L4" }
	"Customer Support (other)" = @{ P = "AVN_FAS76"; T = "F03 | Engineering" }
	"CEOD stuff" = @{ P = "AVN_FAS76"; T = "F03 | Engineering" }
}

$togglProjects = Invoke-RestMethod -Headers $apiHeader -Method Get `
	-Uri "https://api.track.toggl.com/api/v8/workspaces/$workspace/projects"

$taskLookup = @{}
function GetTogglProjectTasks( $projectId )
{
	if( !$taskLookup.ContainsKey( $projectId ) )
	{
		$tasks = Invoke-RestMethod -Method Get -Headers $apiHeader `
			-Uri "https://api.track.toggl.com/api/v8/projects/$projectId/tasks"
		$taskLookup[$projectId] = $tasks
	}
	$taskLookup[$projectId]
}

function ImportRows
{
	[CmdletBinding( SupportsShouldProcess )]
	param()

	foreach( $entry in ($rows | Select-Object -Skip $StartingRecord) )
	{
		$localName = $entry.Activity
		if( !$map.COntainsKey( $localName ) )
		{
			throw "Not sure what Toggl project+task to use for '$localName'"
		}

		$projectPrefix = $map[$localName].P
		$taskPrefix = $map[$localName].T

		$projectInfo = $togglProjects | Where-Object name -match "^$projectPrefix"
		if( @($projectInfo).Length -ne 1 )
		{
			throw "Error finding project for $localName; can't find a unique Toggl project starting with $projectPrefix"
		}

		$togglTasks = GetTogglProjectTasks $projectInfo.id
		$taskInfo = $togglTasks | Where-Object name -match "^$taskPrefix"
		if( @($taskInfo).Length -ne 1 )
		{
			throw "Error finding task for $localName; can't find a task under $($projectInfo.name) starting with $taskPrefix"
		}

		$startDate = [datetime]"$($entry.StartDate)T$($entry.StartTime)$($entry.StartTimeOffset)"
		$startDate = $startDate.ToUniversalTime()

		if( $PSCmdlet.ShouldProcess( "Import data for $localName" ) )
		{
			Write-Information "Adding entry for $($entry.Activity) at $startDate"
			$entry = @{ time_entry = @{
				description = $entry.Activity
				start = $startDate.ToString( "yyyy-MM-ddTHH:mm:ss.000Z" )
				duration = ([TimeSpan]$entry.Duration).TotalSeconds
				pid = $projectInfo.id
				tid = $taskInfo.id
				created_with = "TimeularImporter"
			} }
			Invoke-WebRequest -Method Post -Headers $apiHeader `
				-Uri "https://api.track.toggl.com/api/v8/time_entries" `
				-Body (ConvertTo-Json $entry) -ContentType "application/json" |
			Out-Null
		}
	}
}

# Do a dry run to see if there are any issues
ImportRows -WhatIf
if( $WhatIfPreference -eq $true )
{
	return
}

# Import for real
ImportRows
