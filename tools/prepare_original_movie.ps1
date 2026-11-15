$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root = Split-Path -Parent $PSScriptRoot
$destination = Join-Path $root '.omo/compatibility-run-tmp/b07-movie-original'
& ruby (Join-Path $root 'tools/prepare_original_fixture.rb') (Get-TestPath 'game_project') $destination (Join-Path $root 'tests/fixtures/movie_playback_reference.rb')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Copy-Item -LiteralPath (Join-Path $root 'tests/fixtures/movie-reference.ogv') -Destination (Join-Path $destination 'movie-reference.ogv')
Write-Output 'ORIGINAL_MOVIE_READY'
