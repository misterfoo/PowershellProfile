
# sends output to a temp file and then opens the file for editing. this would normally be the last
# command in the pipeline.
function Out-Temp
{
	[CmdletBinding()]
	param(
		[Parameter( Mandatory = $true, Position = 1 )] [string] $file,
		[Parameter( Mandatory = $true, ValueFromPipeline = $true )] $data,
		[Parameter()] [string] $directory = "d:\temp",
		[Parameter()] [switch] $PassThru
	)
	
	begin
	{
		if( [System.IO.Path]::GetExtension( $file ) -eq "" )
		{
			$file += ".txt"
		}
		$file = Join-Path $directory $file
		if( Test-Path $file )
		{
			Remove-Item $file
		}
		$gotData = $false
	}
	process
	{
		$gotData = $true
		Add-Content -LiteralPath $file -Value $data
		if( $PassThru )
		{
			$data
		}
	}
	end
	{
		if( $gotData )
		{
			Invoke-Item $file
		}
	}
}
