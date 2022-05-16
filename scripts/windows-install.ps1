 Param(
    [Parameter(Mandatory=$True)]
    [string]$API,
    [Parameter(Mandatory=$True)]
    [string]$NAMESPACE,
    [Parameter(Mandatory=$True)]
    [string]$USERNAME,
    [Parameter(Mandatory=$True)]
    [string]$PASSWORD
)

$pair = "$($USERNAME):$($PASSWORD)"

$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))

$basicAuthValue = "Basic $encodedCreds"

$Body = @{
    username = $USERNAME
    password = $PASSWORD
}

$JsonBody = $Body | ConvertTo-Json

$Params = @{
     Method = "Post"
     Uri = "https://api.prismacloud.io/login"
     Body = $JsonBody
     ContentType = "application/json"
}
$Results = Invoke-RestMethod @Params

if ($?) {
    Write-Output "Pre-check: Prisma Cloud Token Acquisition Successful"
} else {
    throw "Failed acquiring PC Token"
}

$PCToken = $Results | select -ExpandProperty token

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile("https://download.aporeto.com/prismacloud/app/apoctl/windows/apoctl.exe", "$env:PROGRAMDATA\apoctl.exe");

$MToken = & $env:PROGRAMDATA\apoctl.exe -A $API auth pc-token --token $PCToken

if ($?) { 
    Write-Output "Pre-check: Microseg Token Acquisition Successful"
} else {
    throw "Microseg token acquisition error"
}

$NSexists = & $env:PROGRAMDATA\apoctl.exe -A $API -n $NAMESPACE -t $MToken api ls namespaces

if ($?) { 
    Write-Output "Pre-check: Namespace Validation Successful"
} else {
    throw "Namespace doesnt exist"
}
 
& $env:PROGRAMDATA\apoctl.exe enforcer install windows --auth-mode appcred -A $API -n $NAMESPACE -t $MToken --confirm
if ($?) { 
    del $env:PROGRAMDATA\apoctl.exe
} 
