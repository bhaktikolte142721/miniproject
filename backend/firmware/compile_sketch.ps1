param(
    [string]$SketchFile,
    [string]$Fqbn,
    [string]$SketchName
)

$ErrorActionPreference = "Continue"

$resolvedSketchFile = (Resolve-Path $SketchFile).Path

$targetDir = Join-Path $env:TEMP "sentinel_build\$SketchName"
if (Test-Path $targetDir) {
    Remove-Item -Recurse -Force $targetDir
}
New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

$targetIno = Join-Path $targetDir "$SketchName.ino"
Copy-Item $resolvedSketchFile $targetIno

Write-Host "============================================================"
Write-Host "Compiling: $SketchName"
Write-Host "Source:    $resolvedSketchFile"
Write-Host "FQBN:      $Fqbn"
Write-Host "============================================================"

$cli = "C:\Program Files\Arduino CLI\arduino-cli.exe"
$output = & $cli compile --fqbn $Fqbn $targetDir 2>&1
$exitCode = $LASTEXITCODE

$output | ForEach-Object { Write-Host $_ }

Write-Host "============================================================"
Write-Host "RESULT EXIT CODE: $exitCode"
if ($exitCode -eq 0) {
    Write-Host "STATUS: BUILD SUCCESS"
} else {
    Write-Host "STATUS: BUILD FAILED"
}
Write-Host "============================================================"

exit $exitCode
