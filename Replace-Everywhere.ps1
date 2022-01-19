function Replace-Everywhere
{
	[CmdletBinding( SupportsShouldProcess = $true )]
	param
	(
		[Parameter( Mandatory = $true )]
		[string] $Directory,

		[Parameter()]
		[string[]] $FileSpec,

		[Parameter( Mandatory = $true )]
		[string] $FindText,

		[Parameter( Mandatory = $true )]
		[string] $ReplaceText,

		[Parameter()]
		[string[]] $SkipPattern,

		[Parameter()]
		[switch] $AllowPartialMatch,

		[Parameter()]
		[switch] $Interactive
	)

	if( -not $AllowPartialMatch )
	{
		$FindText = "\b$FindText\b"
		Write-Warning "Changed FindText to $FindText; specify -AllowPartialMatch to skip this"
	}

	Get-ChildItem $Directory -Recurse -Include $FileSpec |
		% {
			$file = $_.FullName
			$lines = Get-Content -LiteralPath $file
			$changes = 0
			$n = 0
			$edited = foreach( $line in $lines )
			{
				++$n

				# Should we skip this line entirely?
				if( $SkipPattern | ? { $line -match $_ } )
				{
					$line
					continue
				}

				# Try the replacement on this line
				$fixed = $line -replace $FindText,$ReplaceText
				if( $line -eq $fixed )
				{
					$line
					continue
				}

				Write-Information "${file}:$n -- $line" -InformationAction Continue

				# Should we make this replacement?
				if( $Interactive )
				{
					$choice = Read-Host -Prompt "Replace? [y/n] (default n)"
					if( $choice -eq "y" )
					{
						$fixed
						++$changes
					}
					elseif( $choice -in "n","" )
					{
						$line
					}
					else
					{
						Write-Warning "Huh? Assuming you meant No"
						$line
					}
				}
				else
				{
					$line
				}
			}

			if( ($changes -gt 0) -and $PSCmdlet.ShouldProcess( "${file}: $changes changes" ) )
			{
				Set-Content -LiteralPath $file $edited
			}
		}
}
