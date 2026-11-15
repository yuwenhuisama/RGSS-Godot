$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$source = Join-Path $root '.omo/compatibility-run-tmp/b03-lowgray-original'
$destination = Join-Path $root 'tests/fixtures/rgss300-font-styles'
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Get-ChildItem -LiteralPath $source -Filter 'font_style_*.rgba' | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $destination $_.Name) -ErrorAction Stop
}
Write-Output 'FONT_STYLES_CAPTURED'
