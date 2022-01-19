function ConvertTo-Base64String
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory,Position=0,ValueFromPipeline)]
		[AllowEmptyString()]
		[string]$NormalString
	)

	Process
	{
		# short circuit on empty strings
		if ($NormalString -eq [string]::Empty)
		{
			return [string]::Empty
		}

		return [Convert]::ToBase64String( [Text.Encoding]::UTF8.GetBytes( $NormalString ) )
	}  
}

function ConvertFrom-Base64String
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory,Position=0,ValueFromPipeline)]
		[AllowEmptyString()]
		[string]$Base64String
	)

	Process
	{
		# short circuit on empty strings
		if ($Base64String -eq [string]::Empty)
		{
			return [string]::Empty
		}

		return [Text.Encoding]::UTF8.GetString( [Convert]::FromBase64String( $Base64String ) )
	}  
}

function ConvertFrom-Base64Url
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory,Position=0,ValueFromPipeline)]
		[AllowEmptyString()]
		[string]$Base64Url,
		[switch]$AsByteArray
	)

	Process
	{
		# short circuit on empty strings
		if ($Base64Url -eq [string]::Empty)
		{
			return [string]::Empty
		}

		# put the standard unsafe characters back
		$s = $Base64Url.Replace('-', '+').Replace('_', '/')

		# put the padding back
		switch ($s.Length % 4)
		{
			0 { break; }             # no padding needed
			2 { $s += '=='; break; } # two pad chars
			3 { $s += '='; break; }  # one pad char
			default { throw "Invalid Base64Url string" }
		}

		# convert it using standard base64 stuff
		if ($AsByteArray) {
			return [Convert]::FromBase64String($s)
		} else {
			return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($s))
		}
		
	}  
}
