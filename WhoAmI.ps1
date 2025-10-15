3# Import-Module Az.Account
# Install-Module -Name Az.Account -Force

#Get Current Execution folder
$scriptPath = $PSScriptRoot
Set-Location -Path $scriptPath
# Connect using service principal
$config = Get-Content '.\local.settings.json' | ConvertFrom-Json
$clientSecret = $config.clientSecret | ConvertTo-SecureString -AsPlainText -Force
$connectCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $config.clientId, $clientSecret
Connect-AzAccount -ServicePrincipal -Credential $connectCreds -Tenant $config.tenantId
$token = (Get-AzAccessToken -ResourceUrl $config.orgUrl -AsSecureString).Token `
         | ConvertFrom-SecureString -AsPlainText


# Or connect using user credentials
# Connect-AzAccount -Tenant $config.tenantId
# $token = (Get-AzAccessToken -ResourceUrl $config.orgUrl -AsSecureString).Token `
#          | ConvertFrom-SecureString -AsPlainText

$headers = @{
    'Authorization'    = "Bearer $token"
    'Accept'           = 'application/json'
    'OData-MaxVersion' = '4.0'
    'OData-Version'    = '4.0'
    'Content-Type'     = 'application/json; charset=utf-8'
}

Invoke-RestMethod -Uri "$($config.orgUrl)api/data/v9.2/WhoAmI" -Headers $headers | fl

$result = Invoke-RestMethod -Uri "$($config.orgUrl)api/data/v9.2/accounts?`$top=5" -Headers $headers 

$result.value| Select-Object -Property incidentid, title, statecode, statuscode, createdon, modifiedon | 
Export-Csv -Path ".\output\accounts.csv" -NoTypeInformation -Encoding UTF8 -Force -UseQuotes AsNeeded