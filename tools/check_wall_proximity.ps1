$files = Get-ChildItem scripts\rooms\*.gd
foreach ($f in $files) {
  $lines = Get-Content $f.FullName
  foreach ($ln in $lines) {
    if ($ln -match "target_spawn") {
      if ($ln -match "Vector2\((\d+),\s*(\d+)\)") {
        $x = [int]$Matches[1]; $y = [int]$Matches[2]
        $tileRow = [Math]::Floor($y / 16)
        $tileCol = [Math]::Floor($x / 16)
        $flag = ""
        if ($tileRow -le 1 -or $tileRow -ge 28) { $flag += "ROW-WALL! " }
        if ($tileCol -le 1 -or $tileCol -ge 38) { $flag += "COL-WALL! " }
        if ($flag -ne "") { Write-Output ("{0}: {1} at ({2},{3}) tile({4},{5}) {6}" -f $f.Name, $ln.Trim(), $x, $y, $tileCol, $tileRow, $flag) }
      }
    }
  }
  $inLayout = $false; $rowIdx = 0
  foreach ($ln in $lines) {
    if ($ln -match "const LAYOUT") { $inLayout = $true; $rowIdx = 0; continue }
    if ($inLayout) {
      $t = $ln.Trim()
      if ($t.Length -eq 3 -and $t -eq '"""') { break }
      if ($t.Length -ge 40 -and $t.StartsWith('#')) {
        $rowIdx++
        $c = $t.IndexOf('S')
        if ($c -ge 0 -and ($rowIdx -le 2 -or $rowIdx -ge 29 -or $c -le 2 -or $c -ge 38)) {
          Write-Output ("{0}: SAVE at row {1} col {2} TOO CLOSE TO WALL" -f $f.Name, $rowIdx, $c)
        }
      }
    }
  }
}