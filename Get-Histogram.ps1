
function Get-Histogram
{
	[CmdletBinding()]
	param(
		[Parameter(ValueFromPipeline=$true)] [int[]] $Values,
		[Parameter()] [int] $BinCount,
		[Parameter()] [int] $MinValue,
		[Parameter()] [int] $MaxValue,
		[Parameter()] [int] $Width = 40
	)

	begin
	{
		$all = @()
	}

	process
	{
		$all += $Values
	}

	end
	{
		$all = $all | Sort-Object
		Write-Debug "Got $($all.Length) objects"
		
		# Compute the rough parameters for the graph
		$msmts = $all | Measure-Object -Min -Max
		if( !$MinValue )
		{
			$MinValue = $msmts.Minimum
			Write-Debug "Defaulted min to $MinValue"
		}
		if( !$MaxValue )
		{
			$MaxValue = $msmts.Maximum
			Write-Debug "Defaulted max to $MaxValue"
		}
		if( !$BinCount )
		{
			$BinCount = 15
			Write-Debug "Defaulted bin count to $BinCount"
		}

		# How big are the bins?
		[int] $binSize = [Math]::Max( [Math]::Round( ($MaxValue - $MinValue) / $BinCount ), 1 )
		$MaxValue = $MinValue + ($BinCount * $binSize)

		Write-Debug "Min: $MinValue"
		Write-Debug "Max: $MaxValue"
		Write-Debug "Bins: $BinCount"
		Write-Debug "Size: $binSize"

		# Create the bins
		$bins = for( $i = $MinValue; $i -lt $MaxValue; $i += $BinSize )
			{ [pscustomobject] @{Name="$i-$($i+$BinSize-1)"; Min=$i; Max=$i + $BinSize; Count=0; Graph=""} }
		$bins = @([pscustomobject] @{Name="Underflow"; `
			Min=[int]::MinValue; Max=$bins[0].Min; Count=0; Graph=""}) + $bins
		$bins = $bins + @([pscustomobject] @{Name="Overflow"; `
			Min=$bins[$bins.Length-1].Min; Max=[int]::MaxValue; Count=0; Graph=""})

		# Add the values to the bins
		foreach( $v in $all )
		{
			$found = $false
			for( $i = 0; $i -lt $bins.Length; ++$i )
			{
				$b = $bins[$i]
				if( $v -ge $b.Min -and $v -lt $b.Max )
				{
					$found = $true
					$b.Count++
					break
				}
			}
			if( -not $found )
			{
				Write-Warning "Can't find a bin for $v"
			}
		}

		# Create the actual graph
		$binMsmts = $bins | Measure-Object -Max Count
		$maxCount = $binMsmts.Maximum
		
		$scaleFactor = $width / $maxCount
		$bins | % { [int] $cols = ($_.Count * $scaleFactor); $_.Graph = "*" * $cols }
		$bins[0].Min = "--"
		$bins[$bins.Length-1].Max = "--"
		$bins
	}
}
