#Requires -Version 5.1
<#
.SYNOPSIS
  Copy curated Vanilla Expanded (and related) Workshop textures into living_pawn reference folders.
.NOTES
  Source: local Steam Workshop for RimWorld (app 294100). Output is gitignored.
  Do not redistribute. Mod authors retain copyright; local study / exercise only.
  See docs/produto/06-LIFE_COLONY_OS_LIVING_PAWN_ASSET_CATALOG.md
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$ws = Join-Path ${env:ProgramFiles(x86)} 'Steam\steamapps\workshop\content\294100'
$destRoot = Join-Path $root 'docs\produto\assets\reference\living_pawn\modder\vanilla_expanded'

if (-not (Test-Path $ws)) { throw "Steam Workshop RimWorld folder not found: $ws" }

# id → relative dest under vanilla_expanded; textures subpath inside mod
$packs = @(
  @{ Id = '2102143149'; Dest = 'props_decor';     Tex = 'Textures\Things\Building'; KeepTree = $true }
  @{ Id = '1718190143'; Dest = 'furniture_core';  Tex = 'Textures';                 KeepTree = $true }
  @{ Id = '1968134023'; Dest = 'art';             Tex = 'Textures';                 KeepTree = $true }
  @{ Id = '2608762624'; Dest = 'architect';       Tex = 'Textures';                 KeepTree = $true }
  @{ Id = '2028381079'; Dest = 'spacer';          Tex = 'Textures';                 KeepTree = $true }
  @{ Id = '1880253632'; Dest = 'production';      Tex = 'Textures';                 KeepTree = $true }
  @{ Id = '1957158779'; Dest = 'farming';         Tex = 'Textures';                 KeepTree = $true }
  @{ Id = '2062943477'; Dest = 'power';           Tex = 'Textures';                 KeepTree = $true }
  @{ Id = '1718191613'; Dest = 'medical';         Tex = 'Textures';                 KeepTree = $true }
  @{ Id = '1845154007'; Dest = 'security';        Tex = 'Textures';                 KeepTree = $true }
  @{ Id = '1814987817'; Dest = 'apparel';         Tex = 'Textures\Things';          KeepTree = $true }
  @{ Id = '2521176396'; Dest = 'apparel_accessories'; Tex = 'Textures';             KeepTree = $true }
  @{ Id = '1888705256'; Dest = 'hair';            Tex = 'Textures\Things';          KeepTree = $true }
  @{ Id = '2016436324'; Dest = 'terrain_textures'; Tex = 'Textures\Things';         KeepTree = $true }
  @{ Id = '2493234474'; Dest = 'terrain_variations'; Tex = 'Textures\Things';       KeepTree = $true }
  @{ Id = '2193152410'; Dest = 'books';           Tex = 'Textures';                 KeepTree = $true }
  @{ Id = '2134308519'; Dest = 'cooking';         Tex = 'Textures\Things';          KeepTree = $true }
  @{ Id = '2186560858'; Dest = 'brewing';         Tex = 'Textures\Things';          KeepTree = $true }
  @{ Id = '2275449762'; Dest = 'brewing_coffee';  Tex = 'Textures';                 KeepTree = $true }
  @{ Id = '2134308522'; Dest = 'plants';          Tex = 'Textures\Things';          KeepTree = $true }
  @{ Id = '2198652536'; Dest = 'plants_succulents'; Tex = 'Textures\Things';        KeepTree = $true }
  @{ Id = '2748889667'; Dest = 'plants_more';     Tex = 'Textures';                 KeepTree = $true }
  @{ Id = '3006389281'; Dest = 'plants_mushrooms'; Tex = 'Textures';                KeepTree = $true }
  @{ Id = '3049464611'; Dest = 'decorative_vending'; Tex = 'Textures';              KeepTree = $true }
  @{ Id = '3033901359'; Dest = 'adaptive_storage'; Tex = 'Textures';                KeepTree = $true }
)

New-Item -ItemType Directory -Force -Path $destRoot | Out-Null
$manifest = @()

foreach ($pack in $packs) {
  $srcMod = Join-Path $ws $pack.Id
  $srcTex = Join-Path $srcMod $pack.Tex
  $dest = Join-Path $destRoot $pack.Dest

  Write-Host "=== $($pack.Dest) (workshop $($pack.Id)) ==="
  if (-not (Test-Path $srcMod)) {
    Write-Host "SKIP: mod not subscribed/installed"
    $manifest += [pscustomobject]@{ Dest = $pack.Dest; WorkshopId = $pack.Id; Status = 'missing'; Pngs = 0 }
    continue
  }
  if (-not (Test-Path $srcTex)) {
    Write-Host "SKIP: textures path missing: $($pack.Tex)"
    $manifest += [pscustomobject]@{ Dest = $pack.Dest; WorkshopId = $pack.Id; Status = 'no_textures'; Pngs = 0 }
    continue
  }

  if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
  New-Item -ItemType Directory -Force -Path $dest | Out-Null

  # /E copy tree; /NFL /NDL /NJH /NJS quieter; /R:1 /W:1 fail fast
  $null = & robocopy $srcTex $dest '*.png' /E /NFL /NDL /NJH /NJS /NC /NS /R:1 /W:1
  $rc = $LASTEXITCODE
  if ($rc -ge 8) { throw "robocopy failed for $($pack.Dest) exit=$rc" }

  # About.xml name for credits (best-effort)
  $aboutName = $null
  $about = Join-Path $srcMod 'About\About.xml'
  if (Test-Path $about) {
    $m = Select-String -Path $about -Pattern '<name>(.*?)</name>' | Select-Object -First 1
    if ($m) { $aboutName = $m.Matches.Groups[1].Value }
  }

  $count = @(Get-ChildItem $dest -Recurse -Filter '*.png' -File -ErrorAction SilentlyContinue).Count
  Write-Host "PNGs: $count  ($aboutName)"
  $manifest += [pscustomobject]@{
    Dest       = $pack.Dest
    WorkshopId = $pack.Id
    ModName    = $aboutName
    Status     = 'ok'
    Pngs       = $count
  }
}

$manifestPath = Join-Path $destRoot 'MANIFEST.csv'
$manifest | Export-Csv -Path $manifestPath -NoTypeInformation -Encoding UTF8
Write-Host ""
Write-Host "Manifest: $manifestPath"
Write-Host ("Total PNGs: {0}" -f (($manifest | Measure-Object -Property Pngs -Sum).Sum))
Write-Host "Done. Local reference only - do not commit or redistribute."
