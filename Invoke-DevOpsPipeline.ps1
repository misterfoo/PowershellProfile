$devopsPipelines = @{}

function Invoke-DevOpsPipeline
{
	[CmdletBinding()]
	param
	(
		[Parameter( Mandatory )]
		[string] $Name,

		[Parameter()]
		[string] $Project = "EMS",

		[Parameter( Mandatory )]
		[string] $Branch,

		[Parameter()]
		[hashtable] $Parameters
	)

	$header = @{ Authorization = (Get-DevopsApiAuth -AccessType Pipelines) }

	Write-Verbose "Finding the pipeline..."
	$p = Invoke-RestMethod -Headers $header -Method GET `
		-uri "https://dev.azure.com/geaviationdigital-dss/$Project/_apis/pipelines?api-version=6.0-preview.1" |
			% value |
			where Name -eq $Name
	if( !$p )
	{
		throw "Can't find a pipeline named $Name in the $Project project"
	}
	$pipelineId = $p.id
	
	# Build the JSON spec for the pipeline inputs
	$pipelineSpec = @{
		resources = @{ repositories = @{ self = @{ refName = "refs/heads/$Branch" } } }
	}
	if( $Parameters )
	{
		$pipelineSpec.templateParameters = $Parameters
	}
	$pipelineJson = $pipelineSpec | ConvertTo-Json -Depth 100
	Write-Verbose "Pipeline json:"
	Write-Verbose $pipelineJson

	# Basic information we need for calling the API
	$apiBase = "https://dev.azure.com/geaviationdigital-dss/$Project/_apis/pipelines/$pipelineId"
	$apiVersion = "api-version=6.0-preview.1"

	# Start the build
	$build = Invoke-RestMethod -Headers $header -Method POST `
		-Uri "$apiBase/runs?$apiVersion" `
		-ContentType "application/json" -Body $pipelineJson
	$buildId = $build.id

	Write-Host "Started build $buildid!"

	# Open the build progress
	$buildUrl = "https://dev.azure.com/geaviationdigital-dss/$Project/_build/results?buildId=$buildId&view=results"
	Start-Process $buildUrl
}
