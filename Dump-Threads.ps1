$SymbolPath = "D:\symbols"

# .synopsis
# Dumps the callstacks of every thread to the console
#
# .description
# Given a minidump file, dumps the call stacks for all the threads to a text file.
# Also generates a companion file with thread stacks grouped together, so you can easily
# see how many threads are doing ths same thing.
#
# .parameter dumpFile
# The minidump file to analyze.
#
# .parameter quiet
# Causes the script to not open the generated files. By default the generated files are
# opened for inspection after they have been created.
#
function Dump-Threads
{
	[CmdletBinding()]
	param(
		[parameter(mandatory=$true)] [string] $dumpFile,
		[parameter()] [switch] $quiet
	)

	process
	{
		$threads = $dumpFile + ".threads.txt"
		"Dumping threads to $threads..."
		cdb -y $SymbolPath -i $SymbolPath -c "~*k50; q" -z "$dumpFile" -y d:\symbols > $threads

		$grouped = $dumpFile + ".threads-grouped.txt"
		Group-Threads $threads > $grouped

		if( !$quiet )
		{
			ii $threads
			ii $grouped
		}
	}
}

# Groups threads by call stack - this expects to consume the output of Dump-Threads
function Group-Threads
{
	[CmdletBinding()]
	param(
		[Parameter( Mandatory=$true )]
		[string] $threadListFile,
		
		[Parameter()]
		[string] $filterString
	)

	$started = $false
	$stack = ""
	$tid = 0

	$stacks = `
		switch -regex -file $threadListFile
		{
			"Id: [\da-f]+\.([\da-f]+) Suspend:.*"
			{
				$started = $true
				if( ($stack -ne "") -and
					(!$filterString -or ($stack -match $filterString)) )
				{
					# dump the thread id followed by the stack
					"Thread ${tid}:`r`n" + ($stack -replace "`t","`r`n")
				}
				$stack = ""
				$tid = [int]( "0x" + $matches[1] )
			}
			
			"[0-9a-f]{8} [0-9a-f]{8} (.*)"
			{
				if( $started )
				{
					$stack += $matches[1] + "`t"
				}
			}
		}

	# Group the stacks according to everything except the TID, but print the full TID+stack in the
	# output. This makes it faster to locate threads of interest in the debugger.
	$stacks | Group-Object @{ Expression = { $_ -replace "^Thread \d+:","" } } |
	% {
		"Count: $($_.Count)"
		$_.Group[0]
	}
}
