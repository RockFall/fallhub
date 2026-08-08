#Requires -Version 5.1
<#
.SYNOPSIS
  Re-extract Living Pawn / Habitat reference textures from a local RimWorld install.
.NOTES
  Output is gitignored. Do not redistribute. See docs/produto/06-LIFE_COLONY_OS_LIVING_PAWN_ASSET_CATALOG.md
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$cli = Join-Path $PSScriptRoot 'assetstudio\cli\AssetStudioModCLI_net8_portable\AssetStudioModCLI.exe'
$src = Join-Path ${env:ProgramFiles(x86)} 'Steam\steamapps\common\RimWorld\RimWorldWin64_Data\resources.assets'
$base = Join-Path $root 'docs\produto\assets\reference\living_pawn'

if (-not (Test-Path $cli)) { throw "AssetStudio CLI not found: $cli" }
if (-not (Test-Path $src)) { throw "RimWorld resources.assets not found: $src" }

$batches = [ordered]@{
  vanilla_pawn_body           = 'Naked_Male;Naked_Female;Naked_Thin;Naked_Fat;Naked_Hulk'
  vanilla_pawn_head           = 'Female_Average;Male_Average;Female_Narrow;Male_Narrow'
  vanilla_pawn_hair           = 'Afro;Mohawk;Spikes;Burgundy;Bob;Pigtails;Firestarter;Tuque;Shaved;Wavy;Straight;Curl;Senorita;Troubadour'
  vanilla_pawn_beard          = 'Beard;Moustache;Goatee;Stubble;Lincoln;Colonial'
  vanilla_apparel             = 'ShirtBasic;ShirtButton;Pants;Jacket;Parka;Duster;CowboyHat;Tuque;FlakJacket;FlakPants;SimpleHelmet;PlateArmor;Tribal;Robes;Veil;Psychic'
  vanilla_habitat_furniture   = 'Bed;Table;Chair;Stool;Armchair;Couch;Dresser;EndTable;Shelf;PlantPot;LampStanding;HospitalBed;Bedroll;OrbitalTradeBeacon'
  vanilla_habitat_leisure     = 'ChessTable;Billiards;Bookcase;Television;GameOfUr;Telescope;Piano;Harp;Harpsichord;Drum;Instrument'
  vanilla_habitat_work        = 'CraftingSpot;ToolCabinet;Hopper;ShipComputerCore;Smithy;Stonecutter;Tailor;Butchery;Brewery;DrugLab;Fabrication'
  vanilla_habitat_stations    = 'ResearchBench;CommsConsole;Stove;Heater;Cooler;Battery;TorchLamp;Telescope;NutrientPaste;DeepDrill;GroundPenetrating;HiTechResearch'
  vanilla_habitat_decor       = 'Sculpture;Column;Brazier;Grave;Sarcophagus;Urn;Stele;Relic;Banner;Torch;Campfire;Firefoam;PodLauncher'
  vanilla_habitat_plants      = 'Daylily;Rose;Bush;Tree;Grass;Moss;Flower;Plant;Potted;Bonsai;Healroot;Smokeleaf;Psychoid;Cotton;Devilstrand'
  vanilla_items               = 'Meal;Pemmican;Beer;Wort;Medicine;Component;Steel;Wood;Cloth;Jade;Gold;Silver;Plasteel;Chunk;ChunkSlag;Weapon;Knife;Gun;Pack'
  vanilla_structure           = 'Autodoor;Carpet;Tile;Concrete;WoodFloor;PavedTile;Wall;Door;Fence;Barrier;Sandbags;PowerConduit;Cooler;Vent'
}

New-Item -ItemType Directory -Force -Path $base | Out-Null
foreach ($name in $batches.Keys) {
  $out = Join-Path $base $name
  New-Item -ItemType Directory -Force -Path $out | Out-Null
  Write-Host "=== $name ==="
  & $cli $src -t tex2d -o $out -g none -r --image-format png --filter-by-name $batches[$name] --log-level warning
  $count = @(Get-ChildItem $out -File -Filter *.png -ErrorAction SilentlyContinue).Count
  Write-Host "PNGs: $count"
}

Write-Host "Done. Catalog: docs/produto/06-LIFE_COLONY_OS_LIVING_PAWN_ASSET_CATALOG.md"
