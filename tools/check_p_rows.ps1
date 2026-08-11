$files = Get-ChildItem scripts\rooms\*.gd
foreach ($f in $files) {
  $lines = Get-Content $f.FullName
  $inLayout = $false
  $rowIdx = 0
  foreach ($ln in $lines) {
    if ($ln -match "const LAYOUT") { $inLayout = $true; $rowIdx = 0; continue }
    if ($inLayout) {
      $t = $ln.Trim()
      if ($t.Length -eq 3 -and $t -eq '"""') { break }
      if ($t.Length -ge 40 -and $t.StartsWith('#')) {
        $rowIdx++
        $col = $t.IndexOf('P')
        if ($col -ge 0) { Write-Output ("{0}: P at row {1} col {2}" -f $f.Name, $rowIdx, $col) }
      }
    }
  }
}