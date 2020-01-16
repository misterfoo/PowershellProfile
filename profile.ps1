
Import-Module PSReadLine
Set-PSReadLineOption -Colors @{ "String" = "#00cc00" }

# Set a custom fancy prompt
function prompt
{
	$id = (Get-History -Count 1).Id + 1
	write-host ""
	write-host -BackgroundColor Gray -ForegroundColor Black "-- $pwd --"
	return "#$id >> "
}

# Sets the title of the window
function title( $text )
{
	$host.UI.RawUI.WindowTitle = $text
}

# Developer stuff
$env:path += ";" + (Get-Item "Env:ProgramFiles(x86)").Value + "\Git\bin"
set-alias build D:\code\EMS\proj\utilities\development\autoSolver\bin\autoSolver.exe

# Additional script files
. $PSScriptRoot\GeCompany.ps1
. $PSScriptRoot\Copy-Path.ps1
. $PSScriptRoot\Out-Temp.ps1
. $PSScriptRoot\Set-ClipboardText.ps1
. $PSScriptRoot\TabCompletion.ps1

# Fancy copy-helper, to replace simple clip.exe
function clip
{
	[CmdletBinding()]
	param(
		[Parameter( ValueFromPipeline = $true )]
		[object[]] $thing
	)

	begin { $things = @() }
	process { $things += $thing }
	end
	{
		Write-Host -ForegroundColor Cyan "Invoking smart clip function (from Profile)"

		$t = $things[0].GetType()
		if( $t.Name -eq "HistoryInfo" )
		{
			# Copy the CommandLine only
			$things | select -expand CommandLine | clip.exe
		}
		else
		{
			# Dunno what this is, just copy it
			$things | clip.exe
		}
	}
}
