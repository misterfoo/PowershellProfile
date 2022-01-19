# .synopsis
# Copies the specified path to the clipboard, after expanding it to be fully-qualified
function Copy-Path( [string] $path, [switch] $ModuleTester )
{
	if( $ModuleTester )
	{
		$path = "utilities\development\moduleTester\debug\moduleTester.exe"
	}
	
	if( !$path )
	{
		throw "Please specify a path or one of the well-known item switches"
	}
	
	(Resolve-Path $path).Path | clip.exe
}
