param([string]$Godot = "tools\godot.exe")
if (-not (Test-Path $Godot)) { $Godot = "godot" }
& $Godot --headless -s res://tests/run_all.gd
exit $LASTEXITCODE
