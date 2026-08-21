$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

function Clear-NativeAssetsWindows {
  $nativeAssetsWindows = Join-Path $Root "build\native_assets\windows"
  if (Test-Path $nativeAssetsWindows) {
    try {
      Remove-Item -Recurse -Force $nativeAssetsWindows -ErrorAction Stop
    } catch {
      $bak = "$nativeAssetsWindows.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
      Rename-Item $nativeAssetsWindows $bak -ErrorAction SilentlyContinue
    }
  }
}

Write-Host "==> flutter analyze"
flutter analyze --no-fatal-infos --no-fatal-warnings --no-fatal-infos --no-fatal-warnings
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Work around Flutter native_assets copy race on Windows (errno 183).
Clear-NativeAssetsWindows

Write-Host "==> flutter test (app)"
flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Clear-NativeAssetsWindows

Write-Host "==> flutter test packages/colony_design_system"
flutter test packages/colony_design_system
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Clear-NativeAssetsWindows

Write-Host "==> flutter test packages/colony_domain"
flutter test packages/colony_domain
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Clear-NativeAssetsWindows

Write-Host "==> flutter test packages/colony_database"
flutter test packages/colony_database
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "==> test:all passed"
