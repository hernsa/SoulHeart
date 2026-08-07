param([string]$Godot = "tools\godot.exe")
if (-not (Test-Path $Godot)) { $Godot = "godot" }
$output = & $Godot --headless -s res://tests/run_all.gd 2>&1 | Out-String
$exit = $LASTEXITCODE
Write-Output $output.TrimEnd("`r`n")
if ($output -match "SCRIPT ERROR") {
    Write-Host "NOTE: SCRIPT ERROR detected in test run output"
    exit 1
}
exit $exit
