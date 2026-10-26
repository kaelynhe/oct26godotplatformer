# Draws the pixel clouds (cloud1.png, cloud2.png).
# O = soft blue edge, W = white, S = light shade.
# Run from the project folder:  powershell -File tools\make_clouds.ps1
Add-Type -AssemblyName System.Drawing

$clouds = [ordered]@{
  'cloud1' = @(
    '.........OOOO...........',
    '.......OOWWWWOO.........',
    '......OWWWWWWWWO..OOO...',
    '...OOOWWWWWWWWWWOOWWWO..',
    '..OWWWWWWWWWWWWWWWWWWWO.',
    '.OWWWWWWWWWWWWWWWWWWWWWO',
    'OWWWWWWWWWWWWWWWWWWWWWWO',
    'OSSWWWWWWWWWWWWWWWWWWSSO',
    '.OSSSSSWWWWWWWWWSSSSSSO.',
    '..OOOOOSSSSSSSSSSOOOOO..',
    '.......OOOOOOOOOO.......')
  'cloud2' = @(
    '.....OOOO.......',
    '...OOWWWWOOOO...',
    '..OWWWWWWWWWWO..',
    '.OWWWWWWWWWWWWO.',
    'OWWWWWWWWWWWWWWO',
    'OSSWWWWWWWWWSSSO',
    '.OOSSSSSSSSSSOO.',
    '...OOOOOOOOOO...')
}
$colors = @{
  'O' = [System.Drawing.Color]::FromArgb(255, 170, 205, 235)
  'W' = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
  'S' = [System.Drawing.Color]::FromArgb(255, 222, 236, 250)
}
$px = 5
$root = Split-Path $PSScriptRoot -Parent

foreach ($c in $clouds.GetEnumerator()) {
  $rows = $c.Value
  $bmp = New-Object System.Drawing.Bitmap ($rows[0].Length * $px), ($rows.Count * $px)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear([System.Drawing.Color]::Transparent)
  for ($y = 0; $y -lt $rows.Count; $y++) { for ($x = 0; $x -lt $rows[$y].Length; $x++) {
    $ch = [string]$rows[$y][$x]
    if ($colors.ContainsKey($ch)) {
      $b = New-Object System.Drawing.SolidBrush $colors[$ch]
      $g.FillRectangle($b, $x * $px, $y * $px, $px, $px)
      $b.Dispose()
    }
  } }
  $g.Dispose()
  $ms = New-Object IO.MemoryStream
  $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  [IO.File]::WriteAllBytes((Join-Path $root "$($c.Key).png"), $ms.ToArray())
  "$($c.Key).png"
}
