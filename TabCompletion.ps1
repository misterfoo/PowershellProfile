

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
	if ($psCmdlet.ParameterSetName -ne 'ScriptInputSet')
    {
        return [System.Management.Automation.CommandCompletion]::CompleteInput(
            $ast, $tokens, $positionOfCursor, $options)
	}

	# run the default tab completion. we need this if for no other reason than the fact
	# that we can't construct a CommandCompletion instance ourselves.
	$result = [System.Management.Automation.CommandCompletion]::CompleteInput(
		$inputScript, $cursorColumn, $options)

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
	# File = the name of the file
	function Get-GitStatus
	{
		switch -regex ((git status -z) -split "\0")
		{
			"(..) (.*)"
			{
				[pscustomobject] @{ Stat = $matches[1].Trim(); File = $matches[2] }
			}
		}
	}

	# gets custom completion values that should come ahead of default completions
	function Get-CustomCompletionPre
	{
		$last = Get-LastPart $inputScript

	    # auto-complete git branches
	    if( $last -match "^\s*git\s+(checkout|branch)" )
	    {
	        Get-GitBranches | select -Expand Name
	        return
	    }

	    # auto-complete files for index operations
	    if( $last -match "^\s*git\s+(add|stage|restore)" )
	    {
	        Get-GitStatus | select -Expand File
	        return
	    }
	}

	# see if any of our custom completion handlers match
	$custom = @(Get-CustomCompletionPre | % { New-Object Management.Automation.CompletionResult $_ })
	if( $custom.Length -ne 0 )
	{
		$result.CompletionMatches.Clear()
		$custom | % { $result.CompletionMatches.Add( $_ ) }
	}

	$result
}

}
