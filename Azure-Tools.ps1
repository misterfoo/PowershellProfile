
$global:AzureSubscription = (Get-AzContext).Subscription.Name

function Get-AzureSubscription( $nameFragment )
{
	$sub = Get-AzContext -ListAvailable | ? Name -match $nameFragment
	if( !$sub )
	{
		throw "Can't find a subscription named $nameFragment"
	}
	$sub
}

function Set-AzureSubscription( $nameFragment )
{
	$sub = Get-AzContext -ListAvailable | where Name -match $nameFragment
	if( -not $sub )
	{
		throw "Can't find a subscription with '$nameFragment' in the name"
	}

	$chr = switch -regex ( $sub.Name )
		{
			"^134-" { "*" }
			"^114-" { "-" }
			"^003-" { "!" }
		}

	Select-AzContext $sub.Name
	$global:AzureSubscription = "$chr$chr $($sub.Subscription.Name) $chr$chr"
}

function azprod
{
	Get-AzureSubscription "134-GAV-EMS-PROD"
}

function azdevqa
{
	Get-AzureSubscription "114-GAV-EMS-DEVQA"
}

function azchina
{
	Get-AzureSubscription "003-GAVCN-EMS-PROD"
}
