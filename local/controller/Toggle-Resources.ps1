param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("Lite", "Full")]
    [string]$Mode
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$projectDir = (Get-Item $scriptDir).Parent.Parent.FullName
$configFile = Join-Path $scriptDir "config.json"

if (-Not (Test-Path $configFile)) {
    Write-Error "Cannot find config.json: $configFile"
    exit 1
}

$config = Get-Content $configFile -Raw | ConvertFrom-Json

Write-Host "================================================="
Write-Host "Starting resource toggle to $Mode mode..."
Write-Host "================================================="

if ($Mode -eq "Lite") {
    $replicasTarget = "replicas: 1"
    $replicasReplacement = "replicas: 0"
    $suspendTarget = "suspend: false"
    $suspendReplacement = "suspend: true"
} else {
    $replicasTarget = "replicas: 0"
    $replicasReplacement = "replicas: 1"
    $suspendTarget = "suspend: true"
    $suspendReplacement = "suspend: false"
}

foreach ($file in $config.targetFiles) {
    $filePath = Join-Path $projectDir $file
    if (Test-Path $filePath) {
        $content = Get-Content $filePath -Raw
        if ($content -match $replicasTarget) {
            $newContent = $content -replace $replicasTarget, $replicasReplacement
            Set-Content -Path $filePath -Value $newContent -NoNewline
            Write-Host "[SUCCESS] Updated file (Deployments): $file"
        } else {
            Write-Host "[SKIP] No changes needed: $file"
        }
    } else {
        Write-Warning "File not found: $file"
    }
}

foreach ($file in $config.cronjobFiles) {
    $filePath = Join-Path $projectDir $file
    if (Test-Path $filePath) {
        $content = Get-Content $filePath -Raw
        if ($content -match $suspendTarget) {
            $newContent = $content -replace $suspendTarget, $suspendReplacement
            Set-Content -Path $filePath -Value $newContent -NoNewline
            Write-Host "[SUCCESS] Updated file (CronJobs): $file"
        } else {
            Write-Host "[SKIP] No changes needed: $file"
        }
    } else {
        Write-Warning "File not found: $file"
    }
}

Write-Host "-------------------------------------------------"
Write-Host "Committing and pushing to Git..."

Set-Location $projectDir

$gitStatus = git status --porcelain
if ([string]::IsNullOrWhiteSpace($gitStatus)) {
    Write-Host "No changes detected. Already in $Mode mode."
    exit 0
}

git add .
git commit -m "chore(controller): toggle resources to $Mode mode"
git push origin main

Write-Host "================================================="
Write-Host "Resources toggled to $Mode mode successfully."
Write-Host "ArgoCD will sync these changes shortly!"
Write-Host "================================================="

