
if( $PSVersionTable.PSVersion.Major -lt 7 )
{
	Write-Warning "Skipping GIT code, Powershell is too old"
	return
}

$packages = "C:\Program Files\PackageManagement\NuGet\Packages"
$env:Path += ";$packages\LibGit2Sharp.NativeBinaries.2.0.306\runtimes\win-x64\native"
Add-Type -AssemblyName "$packages\LibGit2Sharp.0.26.2\lib\netstandard2.0\LibGit2Sharp.dll"

function Find-RepoRoot
{
	$root = $null
	$location = (Get-Location).Path
	while( $location -notmatch '^\w:\\$' )
	{
		if( Test-Path (Join-Path $location ".git") )
		{
			$root = $location
			break
		}

		$location = Split-Path -Parent $location
	}
	if( !$root )
	{
		throw "Can't find any git repo at or above $(Get-Location)"
	}

	$root
}

# Gets a LibGit2Sharp object representation of the current git repository (if any)
$global:gitRepos = @{}
function Get-GitRepo
{
	[CmdletBinding()]
	param
	(
		[Parameter()]
		[string] $RepoRoot
	)

	# Find a repository in the current directory or one of its parents
	if( !$RepoRoot )
	{
		$RepoRoot = Find-RepoRoot
	}

	# Do we have this repo loaded yet?
	if( !$gitRepos.ContainsKey( $RepoRoot ) )
	{
		Write-Warning "Initializing LibGit2Sharp repo for $RepoRoot"
		$repo = New-Object LibGit2Sharp.Repository -ArgumentList $RepoRoot
		$gitRepos[$RepoRoot] = $repo
	}

	$gitRepos[$RepoRoot]
}

# Pushes to git, with smarts for setting up a tracking branch if it doesn't exist
function Git-Push
{
	$repo = Get-GitRepo
	$current = $repo.Branches | Where-Object IsCurrentRepositoryHead -eq $true
	if( ! $current.TrackedBranch )
	{
		Write-Warning "Note: Establishing a remote tracking branch for $($current.FriendlyName)"
		git push --set-upstream origin $current.FriendlyName

		$pr = Read-Host -Prompt "Would you like to open a PR for this branch? yes/y/[n]"
		if( $pr -in "yes","y" )
		{
			New-PullRequest
		}
	}
	else
	{
		git push
	}
}

function New-PullRequest
{
	[CmdletBinding()]
	param
	(
		[Parameter()]
		[string] $FromBranch,

		[Parameter()]
		[string] $ToBranch
	)

	$root = Find-RepoRoot
	$repo = Split-Path -Leaf $root
	$project = Split-Path -Leaf (Split-Path -Parent $root)

	$devopsBase = "https://dev.azure.com/geaviationdigital-dss"

	# Find the repository info
	$header = @{ Authorization = (Get-DevopsApiAuth -AccessType PullRequests) }
	$repoInfo = Invoke-RestMethod -Uri "$devopsBase/$project/_apis/git/repositories/${repo}?api-version=6.0" -Method Get -Headers $header
	$repoId = $repoInfo.id
	$defaultBranch = $repoInfo.defaultBranch -replace "refs/heads/",""

	# Which branches are we targeting?
	if( !$FromBranch )
	{
		$repoObj = Get-GitRepo
		$current = $repoObj.Branches | Where-Object IsCurrentRepositoryHead -eq $true
		$FromBranch = $current | % FriendlyName
	}
	if( !$ToBranch )
	{
		$ToBranch = $defaultBranch
	}

	# Open the browser to start a new PR for this change
	$url = "$devopsBase/$project/_git/$repo/pullrequestcreate?" +
		"sourceRef=$FromBranch&targetRef=$ToBranch&sourceRepositoryId=$repoId&targetRepositoryId=$repoId"
	Start-Process $url
}

# Diffs changes, commits, and pushes, all based on a set of input directories
function DiffAndCommit
{
	[CmdletBinding()]
	param
	(
		[Parameter( Mandatory = $true )]
		[string[]] $BaseDirectory,

		[Parameter()]
		[switch] $Gui,

		[Parameter()]
		[switch] $Push = $true
	)
	
	Set-StrictMode -Version Latest
	$InformationPreference = "Continue"
	$ErrorActionPreference = "Stop"

	Write-Information "Diffing changes..."
	if( $Gui.IsPresent )
	{
		git difftool @BaseDirectory
	}
	else
	{
		git diff @BaseDirectory
	}

	Write-Information "Staging for commit..."
	git stage @BaseDirectory
	git status

	Write-Warning "Please review the status shown above and verify it for correctness."
	Write-Information "Enter a commit message below, or press Ctrl+C to abort"
	$msg = Read-Host "Commit message"
	git commit -m $msg

	if( !$Push.IsPresent )
	{
		Write-Information "Do you want to push to remote?"
		Read-Host "Press Enter to push, or press Ctrl+C to abort"
	}
	Git-Push
}
