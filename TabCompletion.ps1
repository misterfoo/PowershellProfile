

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

	# writes git branch names to the output
	function Get-Branches
	{
		switch -regex ( git branch )
		{
			"\s+(\w.*)" { $matches[1] }
		}
	}

	# gets custom completion values that should come ahead of default completions
	function Get-CustomCompletionPre
	{
		$last = Get-LastPart $inputScript

	    # auto-complete git branches
	    if( $last -match "^\s*git\s+(checkout|branch)" )
	    {
	        Get-Branches
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
