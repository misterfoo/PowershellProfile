# copies text to the clipboard
function Set-ClipboardText
{
	[CmdletBinding()]
	param
	(
		[Parameter( ValueFromPipeline = $true )] [string] $text
	)
	
	begin
	{
		$final = ""
	}
	
	process
	{
		$final += $text + "`r`n"
	}

	end
	{
		$final # echo the input
		Add-Type -AssemblyName system.windows.forms
		[System.Windows.Forms.Clipboard]::SetText( $final )
	}
}
