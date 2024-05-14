# Date 05/14/2004
# Author Mark Moore
# Stop all Microsoft Fabric Capacities in a subscription
# Thanks Sergei for the API calls https://github.com/sergeig888/ps-fskumgmt-fabric


# Login using a Service Principal and pull a token to run in Azure Automation as a batch job each night
#---------------------------------------------------------------------------------------
$azureAplicationId ="<Your Service Principal App ID"
$azureTenantId= "<Your Tenant ID>"
$azurePassword = ConvertTo-SecureString "<Your SP Secret>" -AsPlainText -Force
$psCred = New-Object System.Management.Automation.PSCredential($azureAplicationId , $azurePassword)
$account = Connect-AzAccount -Credential $psCred -TenantId $azureTenantId -ServicePrincipal -SubscriptionID "<Your Subscription ID"
$context = get-azcontext
$sub = $context.Subscription.Id
#$resources = Get-AzResource
$capacityhash =  @{}
$i=1

$token=(Get-AzAccessToken).Token

$headers = @{
    "Authorization"="Bearer $token";
    "Content-Type"="application/json"
    }
#---------------------------------------------------------------------------------------
# Get Microsoft Fabric Instances in subscription and list their current state
#---------------------------------------------------------------------------------------

$status = (Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$sub/providers/Microsoft.Fabric/capacities?api-version=2022-07-01-preview" -Headers $headers -Method Get).value

write-host "_________________________________________________________________"
write-host "|  Resource Group   |   Instance Name   |   Status   |   SKU    |"
write-host "|___________________|___________________|____________|__________|"

foreach($bstat in $status)
{
    $textline ="|                                                                                                                       "
    $respath = $bstat.id -split "/"
    $RG = $respath[4]
    $bout = $before -f ($RG, $bstat.name, $bstat.properties.state)

    #$textline = $textline.insert(5,'|')
    $textline = $textline.insert(3,$($RG))
    $textline = $textline.insert(20,'|')
    $textline = $textline.insert(24,$($bstat.name))
    $textline = $textline.insert(40,'|')
    $textline = $textline.insert(44,$($bstat.properties.state))
    $textline = $textline.insert(53,'|')
    $textline = $textline.insert(57,$($bstat.sku.name))
    $textline = $textline.insert(64,'|')
    write-host $textline.substring(0,102) 
}
write-host "|___________________|___________________|____________|__________|"

#---------------------------------------------------------------------------------------
# If an instance of Microsoft Fabric is in the Active state, than pause it.
#---------------------------------------------------------------------------------------
Foreach($stat in $status)
{
    if($stat.properties.state -eq "Active")
    {
        $stat
        $respath = $stat.id -split "/"
        $RG = $respath[4]
        $fresult = Invoke-AzResourceAction -ResourceGroupName $RG -ResourceType Microsoft.Fabric/capacities -ResourceName $stat.name -Action suspend -ApiVersion 2023-11-01 -Force
    }
}

#---------------------------------------------------------------------------------------
# Get all Fabric instances in subscription and list them out, should all be paused
#---------------------------------------------------------------------------------------
$status = (Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$sub/providers/Microsoft.Fabric/capacities?api-version=2022-07-01-preview" -Headers $headers -Method Get).value

write-host "_________________________________________________________________"
write-host "|  Resource Group   |   Instance Name   |   Status   |   SKU    |"
write-host "|___________________|___________________|____________|__________|"

foreach($astat in $status)
{
    $textline ="|                                                                                                                       "
    $respath = $bstat.id -split "/"
    $RG = $respath[4]
    $aout = $before -f ($RG, $bstat.name, $bstat.properties.state)

    #$textline = $textline.insert(5,'|')
    $textline = $textline.insert(3,$($RG))
    $textline = $textline.insert(20,'|')
    $textline = $textline.insert(24,$($astat.name))
    $textline = $textline.insert(40,'|')
    $textline = $textline.insert(44,$($astat.properties.state))
    $textline = $textline.insert(53,'|')
    $textline = $textline.insert(57,$($astat.sku.name))
    $textline = $textline.insert(64,'|')
    write-host $textline.substring(0,102)
}
write-host "|___________________|___________________|____________|__________|"
