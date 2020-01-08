
function TabExpansion2
{

[CmdletBinding(DefaultParameterSetName = 'ScriptInputSet')]
Param(
    [Parameter(ParameterSetName = 'ScriptInputSet', Mandatory = $true, Position = 0)]
    [string] $inputScript,
    
    [Parameter(ParameterSetName = 'ScriptInputSet', Mandatory = $true, Position = 1)]
    [int] $cursorColumn,

    [Parameter(ParameterSetName = 'AstInputSet', Mandatory = $true, Position = 0)]
    [System.Management.Automation.Language.Ast] $ast,

    [Parameter(ParameterSetName = 'AstInputSet', Mandatory = $true, Position = 1)]
    [System.Management.Automation.Language.Token[]] $tokens,

    [Parameter(ParameterSetName = 'AstInputSet', Mandatory = $true, Position = 2)]
    [System.Management.Automation.Language.IScriptPosition] $positionOfCursor,
    
    [Parameter(ParameterSetName = 'ScriptInputSet', Position = 2)]
    [Parameter(ParameterSetName = 'AstInputSet', Position = 3)]
    [Hashtable] $options = $null
)

End
{
	Set-StrictMode -Version Latest

   	function log( $thing )
   	{
		$thing >> d:\temp\log.txt
   	}

	trap
	{
		log $_.ToString()
		log $_.ScriptStackTrace
   	}

	log "--------------------------------------"
	log ""
   	
	# parse input
	if ($PSCmdlet.ParameterSetName -eq 'ScriptInputSet') {
		$_ = [System.Management.Automation.CommandCompletion]::MapStringInputToParsedInput($inputScript, $cursorColumn)
		$ast = $_.Item1
		$tokens = $_.Item2
		$positionOfCursor = $_.Item3
	}

	# gets the last command on the line (using ; as the separator)
	function Get-LastPart( [string] $line )
	{
		$chars = ';', '|'
		$lastBreak = $line.LastIndexOfAny( $chars );
		if( $lastBreak -ge 0 )
		{ $line.Substring( $lastBreak + 1 ).TrimStart() }
		else
		{ $line }
	}

	# finds the root directory of a git repository, assuming we are currently in a subdirectory
	function Find-GitRoot
	{
		$dir = (Get-Location).Path
		for(;;)
		{
			if( Test-Path (Join-Path $dir ".git") )
			{
				return $dir
			}

			$parent = Split-Path -Parent $dir
			if( $parent -eq "" )
			{
				return $null
			}

			$dir = $parent
		}
	}

	# Gets the list of local branches, as a set of objects looking like:
	# Name = the name of the branch
	# Remote = the remote tracking branch, if any
	# LastHash = the hash of the last commit on the branch
	# LastMsg = the first bit of the last commit message
	function Get-GitBranches
	{
		switch -regex (git branch -vv)
		{
			# *     name    hash            remote     message
			"\*?\s+(\S+)\s+([0-9a-f]+) (?:\[(.*?)\] )?(.*)"
			{
				[pscustomobject] @{
					Name = $matches[1]
					Remote = $matches[3]
					LastHash = $matches[2]
					LastMsg = $matches[4]
				}
			}
		}
	}

	# Gets the status of the local git repository, as a set of objects looking like:
	# Stat = the status of the file (M, A, or ??)
	# File = the path and name of the file (note that paths are relative to repository root)
	function Get-GitStatus
	{
		switch -regex (git status --porcelain=v1)
		{
			"(..) (.*)"
			{
				[pscustomobject] @{ Stat = $matches[1].Trim(); File = $matches[2] }
			}
		}
	}

	# Filters the $results array to entries beginning with $prefix
	function FilterResults( $results, $prefix )
	{
		if( $prefix -ne "" )
		{
			$pattern = "^" + [system.Text.RegularExpressions.Regex]::Escape( $prefix )
			$results = $results | where { $_ -match $pattern }
		}
		$results
	}

	# gets custom completion values that should come ahead of default completions
	function Get-CustomCompletionPre
	{
		$last = Get-LastPart $inputScript

	    # auto-complete git branches
	    #
	    #					   git   command               -args     prefix-of-thing
	    if( $last -match "^\s*git\s+(checkout|branch)\s+(?:-\w+\s+)*(.*)" )
	    {
	        $names = Get-GitBranches | select -Expand Name
	        return FilterResults $names $matches[2]
	    }

	    # auto-complete files for index operations
		#
	    #					   git    command                -args     prefix-of-thing
	    if( $last -match "^\s*git\s+(add|stage|restore)\s+(?:-\w+\s+)*(.*)" )
	    {
			# Have they already typed some of the file they want? If so, skip tab
			# completion if they started with .\ or ..\ or a drive letter
			$prefix = $matches[2]
			if( ($prefix -match "^\.") -or ($prefix -match "^\w:\\") )
			{
				return @()
			}
	    
	        $files = Get-GitStatus | select -Expand File

			# The output of Get-GitStatus is relative to the root of the repo, but we want
			# tab completion to function relative to the current directory
			$root = Find-GitRoot
			if( $root -ne $null )
			{
				$pwd = (Get-Location).Path
				$relative = $pwd.Substring( $root.Length + 1 )
				log "adjusting files relative to $relative"
				$files = $files | % {
						if( $_.StartsWith( $relative ) )
						{
							log "relative: $_"
							$_.Substring( $relative.Length + 1 ) # +1 is for final path separator
						}
						else
						{
							log "absolute: $_"
							$root + $_
						}	
					}
			}

	        return FilterResults $files $matches[2]
	    }
	}
	
	# see if any of our custom completion handlers match
	$custom = @(Get-CustomCompletionPre)
	if( $custom.Length -gt 0 )
	{
		# make a fake local version of TabExpansion which only returns the matches we want
		# see this repo for helpful guidance: https://github.com/nightroman/FarNet/blob/master/PowerShellFar/TabExpansion2.ps1
		function TabExpansion { $custom }

		# run "regular" tab expansion with our custom results
		return [System.Management.Automation.CommandCompletion]::CompleteInput(
				$ast, $tokens, $positionOfCursor, $null)
	}


	# run the default tab completion
	[System.Management.Automation.CommandCompletion]::CompleteInput(
		$inputScript, $cursorColumn, $options)
}

}
