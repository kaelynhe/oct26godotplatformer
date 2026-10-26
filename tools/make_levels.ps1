# Builds level2.tscn .. level10.tscn from the text maps below.
#   #  = block (grass/dirt edges are picked automatically)
#   D  = the white dog (sits on the block under it)
# Each row is 16 columns: tile x = -1 .. 14. Rows are tile y = 0 .. 7.
# Run from the project folder:  powershell -File tools\make_levels.ps1

$levels = [ordered]@{
  # 2: a small pit and some steps
  2 = @(
    '................',
    '................',
    '................',
    '................',
    '...........D....',
    '.......#..####..',
    '#####..#########',
    '#####..#########')
  # 3: floating platforms over a big pit
  3 = @(
    '................',
    '................',
    '................',
    '..........D.....',
    '......##.###....',
    '....#...........',
    '###.#......#####',
    '###.#......#####')
  # 4: one-tile pillars, climbing up
  4 = @(
    '................',
    '................',
    '................',
    '...........D....',
    '.........###....',
    '......#..#......',
    '##.#..#..#......',
    '##.#..#..#......')
  # 5: low tunnel - you can only do short hops in here
  5 = @(
    '................',
    '................',
    '................',
    '...########.....',
    '...########.....',
    '............D...',
    '#####..##..#####',
    '#####..##..#####')
  # 6: floating staircase, nothing below
  6 = @(
    '................',
    '................',
    '............D...',
    '..........###...',
    '.......#........',
    '....#...........',
    '###.............',
    '###.............')
  # 7: long gaps between pillars, with a ceiling in the way
  7 = @(
    '................',
    '................',
    '................',
    '.....####.......',
    '............D...',
    '.........#..##..',
    '##...#...#..##..',
    '##...#...#..##..')
  # 8: tunnel with a one-tile landing, then a climb
  8 = @(
    '................',
    '................',
    '................',
    '...######...D...',
    '...######..##...',
    '..........#.....',
    '####..#..#......',
    '####..#..#......')
  # 9: tiny floating blocks under a ceiling
  9 = @(
    '................',
    '................',
    '....#######.....',
    '............D...',
    '...........###..',
    '....#...#.......',
    '###.............',
    '###.............')
  # 10: everything at once
  10 = @(
    '................',
    '................',
    '................',
    '..####......D...',
    '..####......#...',
    '..........#.....',
    '##..#..#........',
    '##..#..#........')
}

# Tileset source ids (see tiles.tres)
$GRASS = @{ none = 4; left = 7; right = 10; both = 5 }
$DIRT  = @{ none = 3; left = 8; right = 9;  both = 6 }

$root = Split-Path $PSScriptRoot -Parent

foreach ($entry in $levels.GetEnumerator()) {
  $n = $entry.Key
  $rows = $entry.Value
  if ($rows.Count -ne 8) { throw "level $n needs 8 rows" }
  $solid = @{}
  $dog = $null
  for ($y = 0; $y -lt 8; $y++) {
    if ($rows[$y].Length -ne 16) { throw "level $n row $y is $($rows[$y].Length) wide, needs 16" }
    for ($i = 0; $i -lt 16; $i++) {
      $c = $rows[$y][$i]
      if ($c -eq '#') { $solid["$($i - 1),$y"] = $true }
      elseif ($c -eq 'D') { $dog = @(($i - 1), $y) }
    }
  }
  if (-not $dog) { throw "level $n has no D" }

  $ms = New-Object IO.MemoryStream
  $bw = New-Object IO.BinaryWriter $ms
  $bw.Write([UInt16]0)
  foreach ($key in $solid.Keys) {
    $x, $y = $key.Split(',') | ForEach-Object { [int]$_ }
    $left = -not $solid.ContainsKey("$($x - 1),$y")
    $right = -not $solid.ContainsKey("$($x + 1),$y")
    $side = if ($left -and $right) { 'both' } elseif ($left) { 'left' } elseif ($right) { 'right' } else { 'none' }
    $src = if ($solid.ContainsKey("$x,$($y - 1)")) { $DIRT[$side] } else { $GRASS[$side] }
    $bw.Write([Int16]$x); $bw.Write([Int16]$y); $bw.Write([UInt16]$src)
    $bw.Write([UInt16]0); $bw.Write([UInt16]0); $bw.Write([UInt16]0)
  }
  $data = [Convert]::ToBase64String($ms.ToArray())

  # Tile layer sits at (34, -36) with 90px tiles; the dog's feet go on the block top.
  $dogX = 34 + 90 * $dog[0] + 45
  $dogY = -36 + 90 * ($dog[1] + 1) - 14

  $scene = @"
[gd_scene format=3]

[ext_resource type="PackedScene" path="res://player.tscn" id="1_player"]
[ext_resource type="TileSet" path="res://tiles.tres" id="2_tiles"]
[ext_resource type="PackedScene" path="res://mini_dog.tscn" id="3_minidog"]

[node name="Level$n" type="Node"]

[node name="Player" parent="." instance=ExtResource("1_player")]

[node name="TileMapLayer" type="TileMapLayer" parent="."]
position = Vector2(34, -36)
scale = Vector2(0.075, 0.075)
tile_map_data = PackedByteArray("$data")
tile_set = ExtResource("2_tiles")

[node name="MiniDog" parent="." instance=ExtResource("3_minidog")]
position = Vector2($dogX, $dogY)

"@
  [IO.File]::WriteAllText((Join-Path $root "level$n.tscn"), $scene, (New-Object Text.UTF8Encoding $false))
  "level$n.tscn: $($solid.Count) tiles, dog at tile $($dog[0]),$($dog[1])"
}
