$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$source = Join-Path $root '.omo/compatibility-run-tmp/b01-sizeglyph-original/font_variants_reference.tsv'
$destination = Join-Path $root 'tests/fixtures/rgss300-font-variants.tsv'
if (-not (Test-Path $source)) { throw 'Original reference capture is missing' }
Copy-Item -LiteralPath $source -Destination $destination -ErrorAction Stop
Write-Output 'FONT_REFERENCE_CAPTURED'
