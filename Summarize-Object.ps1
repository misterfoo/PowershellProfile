<#
.synopsis
Groups and summarizes data in a manner similar to an Excel Pivot table.

.description
This cmdlet performs a two-stage operation to group and then aggregate
data, similar to an Excel pivot table or the Kusto "summarize" operator.
First it groups according to one or more properties or computed expressions
(using Group-Object) and then performs an aggregation on one or more data
fields (using Measure-Object).

.parameter InputObject
The set of objects to summarize.

.parameter GroupBy
The parameter(s) or expression(s) to group by. This should be a property
on the InputObject and is passed directly to Group-Object. Common values
for this would be something like a date, a computer name, or a resource
name.

.parameter SummarizeBy
The data properties to summarize, such as a count or a size. This should 
take the form of "Property:Aggregation", where Aggregation can be
"Count", "Sum", "Average", "Maximum", or "Minimum" (the same operations
supported by Measure-Object). The property should be a property on the 
InputObject and is passed directly to Measure-Object.

.parameter NumericPrecision
The number of decimal places to report when aggregating values, especially with
operators like Average.

#>
function Summarize-Object
{
	[CmdletBinding()]
	param
	(
		[Parameter( Mandatory = $true, ValueFromPipeline = $true )]
		[PSObject] $InputObject,

		[Parameter( Mandatory = $true )]
		[Object[]] $GroupBy,

		[Parameter( Mandatory = $true )]
		[string[]] $SummarizeBy,

		[Parameter()]
		[int] $NumericPrecision = 2
	)
	
	begin
	{
		$ErrorActionPreference = "Stop"
		$all = new-object System.Collections.ArrayList

		# Parse the SummarizeBy arguments into property names and aggregations
		$groupings = $SummarizeBy |
		% {
			if( $_ -notmatch "(.*):(\w+)" )
			{
				throw "Invalid format for SummarizeBy input: $_ (expected 'Property:Aggregation')"
			}

			$prop = $matches[1]
			$agg = $matches[2]

			[pscustomobject] @{ Property = $prop; Aggregate = $agg }
		}
	}

	process
	{
		if( $InputObject -is [Array] )
		{
			$all.AddRange( $InputObject ) > $null
		}
		else
		{
			$all.Add( $InputObject ) > $null
		}
	}
	
	end
	{
		$all | Group-Object $GroupBy |
		% {
			$g = $_
			$result = [pscustomobject] @{ Group = $g.Name }
			foreach( $item in $groupings )
			{
				# Create the arguments to Measure-Object, which is complicated because some
				# are parameter values and some are parameters themselves
				$measureArgs = @{}
				$measureArgs.Property = $item.Property
				if( $item.Aggregate -ne "Count" )
				{
					$measureArgs.($item.Aggregate) = $true
				}

				# Perform the aggregation
				$value = $g.Group | Measure-Object @measureArgs | Select-Object -expand $item.Aggregate
				Add-Member -InputObject $result -MemberType NoteProperty `
					-Name $item.Property -Value ([Math]::Round( $value, $NumericPrecision ))
			}
			$result
		}
	}
}
