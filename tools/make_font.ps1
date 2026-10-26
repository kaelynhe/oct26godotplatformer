# Builds the blocky pixel fonts used by the HUD (pixel_font*.fnt + .png).
# Each glyph is drawn on a 7-row grid; X = filled pixel.
# Run from the project folder:  powershell -File tools\make_font.ps1
Add-Type -AssemblyName System.Drawing

$glyphs = [ordered]@{
  'A' = '.XXX.','X...X','X...X','XXXXX','X...X','X...X','X...X'
  'B' = 'XXXX.','X...X','X...X','XXXX.','X...X','X...X','XXXX.'
  'C' = '.XXX.','X...X','X....','X....','X....','X...X','.XXX.'
  'D' = 'XXXX.','X...X','X...X','X...X','X...X','X...X','XXXX.'
  'E' = 'XXXXX','X....','X....','XXXX.','X....','X....','XXXXX'
  'F' = 'XXXXX','X....','X....','XXXX.','X....','X....','X....'
  'G' = '.XXX.','X...X','X....','X.XXX','X...X','X...X','.XXXX'
  'H' = 'X...X','X...X','X...X','XXXXX','X...X','X...X','X...X'
  'I' = 'XXX','.X.','.X.','.X.','.X.','.X.','XXX'
  'J' = '..XXX','...X.','...X.','...X.','...X.','X..X.','.XX..'
  'K' = 'X...X','X..X.','X.X..','XX...','X.X..','X..X.','X...X'
  'L' = 'X....','X....','X....','X....','X....','X....','XXXXX'
  'M' = 'X...X','XX.XX','X.X.X','X.X.X','X...X','X...X','X...X'
  'N' = 'X...X','XX..X','X.X.X','X..XX','X...X','X...X','X...X'
  'O' = '.XXX.','X...X','X...X','X...X','X...X','X...X','.XXX.'
  'P' = 'XXXX.','X...X','X...X','XXXX.','X....','X....','X....'
  'Q' = '.XXX.','X...X','X...X','X...X','X.X.X','X..X.','.XX.X'
  'R' = 'XXXX.','X...X','X...X','XXXX.','X.X..','X..X.','X...X'
  'S' = '.XXXX','X....','X....','.XXX.','....X','....X','XXXX.'
  'T' = 'XXXXX','..X..','..X..','..X..','..X..','..X..','..X..'
  'U' = 'X...X','X...X','X...X','X...X','X...X','X...X','.XXX.'
  'V' = 'X...X','X...X','X...X','X...X','X...X','.X.X.','..X..'
  'W' = 'X...X','X...X','X...X','X.X.X','X.X.X','XX.XX','X...X'
  'X' = 'X...X','X...X','.X.X.','..X..','.X.X.','X...X','X...X'
  'Y' = 'X...X','X...X','.X.X.','..X..','..X..','..X..','..X..'
  'Z' = 'XXXXX','....X','...X.','..X..','.X...','X....','XXXXX'
  '0' = '.XXX.','X...X','X..XX','X.X.X','XX..X','X...X','.XXX.'
  '1' = '.X.','XX.','.X.','.X.','.X.','.X.','XXX'
  '2' = '.XXX.','X...X','....X','...X.','..X..','.X...','XXXXX'
  '3' = 'XXXX.','....X','....X','.XXX.','....X','....X','XXXX.'
  '4' = '...X.','..XX.','.X.X.','X..X.','XXXXX','...X.','...X.'
  '5' = 'XXXXX','X....','XXXX.','....X','....X','X...X','.XXX.'
  '6' = '.XXX.','X....','X....','XXXX.','X...X','X...X','.XXX.'
  '7' = 'XXXXX','....X','...X.','..X..','.X...','.X...','.X...'
  '8' = '.XXX.','X...X','X...X','.XXX.','X...X','X...X','.XXX.'
  '9' = '.XXX.','X...X','X...X','.XXXX','....X','....X','.XXX.'
  ':' = '.','X','X','.','X','X','.'
  '.' = '..','..','..','..','..','XX','XX'
  ',' = '..','..','..','..','XX','.X','X.'
  '/' = '....X','....X','...X.','..X..','.X...','X....','X....'
  '!' = 'X','X','X','X','X','.','X'
  '?' = '.XXX.','X...X','....X','...X.','..X..','.....','..X..'
  '-' = '....','....','....','XXXX','....','....','....'
  "'" = 'X','X','.','.','.','.','.'
  ' ' = '...','...','...','...','...','...','...'
}

$root = Split-Path $PSScriptRoot -Parent

# $bold widens every pixel by that many screen pixels so the strokes look thicker.
function Make-Font([string]$name, [int]$px, [int]$bold) {
  $cellW = 6 * $px + $bold; $cellH = 8 * $px + $bold; $cols = 16
  $count = $glyphs.Count
  $w = $cols * $cellW; $h = [math]::Ceiling($count / $cols) * $cellH
  $bmp = New-Object System.Drawing.Bitmap $w, $h
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear([System.Drawing.Color]::Transparent)
  $white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
  $chars = New-Object System.Collections.Generic.List[string]
  $i = 0
  foreach ($e in $glyphs.GetEnumerator()) {
    $rows = $e.Value
    $gw = $rows[0].Length
    $ox = ($i % $cols) * $cellW; $oy = [math]::Floor($i / $cols) * $cellH
    for ($y = 0; $y -lt 7; $y++) { for ($x = 0; $x -lt $gw; $x++) {
      if ($rows[$y][$x] -eq 'X') { $g.FillRectangle($white, $ox + $x * $px, $oy + $y * $px, $px + $bold, $px + $bold) }
    } }
    $ids = @([int][char]$e.Key)
    $lower = $e.Key.ToLower()
    if ($lower -cne $e.Key) { $ids += [int][char]$lower }
    foreach ($id in $ids) {
      $chars.Add("char id=$id x=$ox y=$oy width=$($gw * $px + $bold) height=$(7 * $px + $bold) xoffset=0 yoffset=0 xadvance=$(($gw + 1) * $px + $bold) page=0 chnl=15")
    }
    $i++
  }
  $g.Dispose()
  $ms = New-Object IO.MemoryStream
  $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  $out = Join-Path $root "$name.png"
  $bytes = $ms.ToArray()
  # Skip unchanged images (an open Godot editor can keep them locked).
  if (-not (Test-Path $out) -or [Convert]::ToBase64String([IO.File]::ReadAllBytes($out)) -ne [Convert]::ToBase64String($bytes)) {
    [IO.File]::WriteAllBytes($out, $bytes)
  }
  $fnt = @(
    "info face=""$name"" size=$(7 * $px + $bold) bold=0 italic=0 charset="""" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=0,0",
    "common lineHeight=$(10 * $px) base=$(7 * $px + $bold) scaleW=$w scaleH=$h pages=1 packed=0",
    "page id=0 file=""$name.png""",
    "chars count=$($chars.Count)"
  ) + $chars
  [IO.File]::WriteAllLines((Join-Path $root "$name.fnt"), $fnt)
  "$name.fnt: $($chars.Count) chars, $px px per pixel"
}

Make-Font 'pixel_font_bold' 4 2
Make-Font 'pixel_font_large_bold' 5 2
