
# sends output to a temp file and then opens the file for editing. this would normally be the last
# command in the pipeline.
function Out-Temp
{
	[CmdletBinding()]
	param(
		[Parameter( Mandatory = $true, Position = 1 )]
		[string] $file,

		[Parameter( Mandatory = $true, ValueFromPipeline = $true )]
		$data,

		[Parameter()]
		[string] $directory = "d:\temp",

		[Parameter()]
		[switch] $Csv,

		[Parameter()]
		[switch] $PassThru
	)
	
	begin
	{
		if( [System.IO.Path]::GetExtension( $file ) -eq "" )
		{
			if( $Csv.IsPresent )
			{
				$file += ".csv"
			}
			else
			{
				$file += ".txt"
			}
		}

		$file = Join-Path $directory $file
		if( Test-Path $file )
		{
			Remove-Item $file
		}

		$gotData = $false
		$buffer = New-Object System.Collections.ArrayList
	}
	process
	{
		$gotData = $true
		if( $Csv.IsPresent )
		{
			[void] $buffer.Add( $data )
		}
		else
		{
			Add-Content -LiteralPath $file -Value $data
		}

		if( $PassThru )
		{
			$data
		}
	}
	end
	{
		if( $gotData )
		{
			if( $Csv.IsPresent )
			{
				$buffer | Export-Csv -LiteralPath $file -NoTypeInformation
			}

			Invoke-Item $file
		}
	}
}
