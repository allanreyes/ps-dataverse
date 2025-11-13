# Import-Module Az.Account
# Install-Module -Name Az.Account -Force

#Get Current Execution folder
$scriptPath = $PSScriptRoot
Set-Location -Path $scriptPath
# Connect using service principal
$config = Get-Content '.\local.settings.json' | ConvertFrom-Json
$clientSecret = $config.clientSecret | ConvertTo-SecureString -AsPlainText -Force
$connectCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $config.clientId, $clientSecret
Clear-AzConfig -Force
Connect-AzAccount -ServicePrincipal -Credential $connectCreds -Tenant $config.tenantId
$token = (Get-AzAccessToken -ResourceUrl $config.orgUrl -AsSecureString).Token `
         | ConvertFrom-SecureString -AsPlainText

$headers = @{
    'Authorization'    = "Bearer $token"
    'Accept'           = 'application/json'
    'OData-MaxVersion' = '4.0'
    'OData-Version'    = '4.0'
    'Content-Type'     = 'application/json; charset=utf-8'
}

Invoke-RestMethod -Uri "$($config.orgUrl)/api/data/v9.2/WhoAmI" -Headers $headers | fl

# =========================
# CREATE TEST PROJECT
# =========================
$testBody = @{
    dfo_name = "Test Project - $(Get-Date -Format 'yyyyMMdd-HHmmss')"
} | ConvertTo-Json

# Use the **plural entity set name**
$createUri = "$($config.orgUrl)/api/data/v9.2/dfo_projects"

try {
    $response = Invoke-RestMethod -Method Post -Uri $createUri -Headers $headers -Body $testBody
    Write-Host "Test project created successfully! ID: $($response.projectid)"
} catch {
    Write-Host "Error creating test project: $($_.Exception.Message)"
}