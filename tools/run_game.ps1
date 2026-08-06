param([string]$Godot = "tools\godot.exe")
if (-not (Test-Path $Godot)) { $Godot = "godot" }
& $Godot --path .
exit $LASTEXITCODE
