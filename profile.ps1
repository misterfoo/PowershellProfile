
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

# Developer stuff
$env:path += ";" + (Get-Item "Env:ProgramFiles(x86)").Value + "\Git\bin"
set-alias build D:\code\EMS\proj\utilities\development\autoSolver\bin\autoSolver.exe

# Setup the GE-network proxy
# note: the http: scheme is required in order for uaac to work. not sure if
# it's required on the HTTPS_PROXY value.
Write-Host ""
Write-Host -ForegroundCOlor Cyan "Setting up GE proxies..."
Write-Host ""
$proxy = "PITC-Zscaler-Americas-Cincinnati3PR.proxy.corporate.ge.com:80"
$env:HTTP_PROXY = "http://$proxy"
$env:HTTPS_PROXY = "http://$proxy"

# Custom tab completion!
. $PSScriptRoot\TabCompletion.ps1
