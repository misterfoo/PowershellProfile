
Set-StrictMode -Version Latest
Import-Module PSReadLine

# Fancy coloring!
Set-PSReadLineOption -Colors @{ "Variable" = "#00aaff"; "String" = "#ff920d" }

# I'd rather use SaveIncrementally, but it doesn't interact well with Digital Guardian
#Set-PSReadLineOption -HistorySaveStyle SaveAtExit

# Are we Admin?
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$global:ConsoleIsAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Additional script files
. $PSScriptRoot\DevopsAuthHelper.ps1
. $PSScriptRoot\GeCompany.ps1
. $PSScriptRoot\Azure-Tools.ps1
. $PSScriptRoot\Copy-Path.ps1
. $PSScriptRoot\Out-Temp.ps1
. $PSScriptRoot\Set-ClipboardText.ps1
. $PSScriptRoot\Summarize-Object.ps1
. $PSScriptRoot\TabCompletion.ps1
. $PSScriptRoot\Dump-Threads.ps1
. $PSScriptRoot\Base64.ps1
. $PSScriptRoot\Window-Tools.ps1
. $PSScriptRoot\Git.ps1
. $PSScriptRoot\ModuleDevelopment.ps1
. $PSScriptRoot\Invoke-DevOpsPipeline.ps1

# Don't use the paged 'help' function
$badHelp = "function:\help"
if( Test-Path $badHelp )
{
	Remove-Item $badHelp
}
Set-Alias help Get-Help

if( $PSVersionTable.PSVersion.Major -lt 7 )
{
	Write-Warning "Skipping various other profile bits; Powershell is too old"
	return
}

# Modules we like
Import-Module D:\code\EmsOperations\EmsAzureOps\bin\EmsAzureOps\
$env:EmsAzUserName = "charles.nevill"
$env:EmsRealmDataRoot = "D:\code\EmsDeployment\EmsDeploymentData\bin\"

# Gets the ID of the last command in the history, with some interesting side effects
function GetHistoryIdForPrompt
{
	$h = Get-History -Count 1

	# If the last command took a while, flash the window so I know it's done
	if( $h.Duration.TotalSeconds -gt 1 )
	{
		$id = $PID

		# If this is Windows Terminal, we have to flash the Terminal window,
		# because the Powershell process won't have a window of its own.
		$parent = (Get-Process -Id $PID).Parent
		if( $parent.ProcessName -match "WindowsTerminal" )
		{
			$id = $parent.Id
		}

		flash $id
	}

	$h.Id + 1
}

# Customize the posh-git prompt
Import-Module posh-git
$GitPromptSettings.DefaultPromptPrefix.Text = "`n$([char]0xE0B0) "
$GitPromptSettings.DefaultPromptPath.Text = '$([char]0xE0B0) $(Get-PromptPath) $([char]0xE0B2)'
$GitPromptSettings.DefaultPromptPath.BackgroundColor = 0x0077c2
$GitPromptSettings.DefaultPromptPath.ForegroundColor = "White"
$GitPromptSettings.PathStatusSeparator.Text = " $([char]0xE0B2)`n"
$GitPromptSettings.BranchColor.ForegroundColor = "Black"
$GitPromptSettings.BranchColor.BackgroundColor = 0x60ff99
$GitPromptSettings.DefaultPromptSuffix.Text = '`n$global:AzureSubscription`n#$(GetHistoryIdForPrompt) >> '
$GitPromptSettings.RepositoriesInWhichToDisableFileStatus += "d:\code\EMS\EMS\"

# Customize other posh-git stuff
$GitPromptSettings.IndexColor.ForegroundColor = "Green"
$GitPromptSettings.WorkingColor.ForegroundColor = "Red"
$GitPromptSettings.LocalWorkingStatusSymbol.ForegroundColor = "Red"

# Sets the title of the window
function title( $text )
{
	if( $global:ConsoleIsAdmin )
	{
		$text = "ADMIN - $text"
	}
	$host.UI.RawUI.WindowTitle = $text
}

# Developer stuff
$env:path += ";" + (Get-Item "Env:ProgramFiles(x86)").Value + "\Git\bin"
$env:path += ";d:\tools"
set-alias build "D:\code\EMS\EMS\proj\utilities\development\autoSolver\bin\autoSolver.exe"
set-alias symstore "C:\Program Files (x86)\Windows Kits\10\Debuggers\x86\symstore.exe"
set-alias cdb "C:\Program Files (x86)\Windows Kits\10\Debuggers\x86\cdb.exe"
set-alias nuget "D:\code\tools\nuget.exe"
set-alias openssl 'C:\Program Files\Git\usr\bin\openssl.exe'

# Helper for converting times
function ctime( [int] $secondsSince1970 )
{
	([datetime]"1970/1/1").AddSeconds( $secondsSince1970 )
}

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
