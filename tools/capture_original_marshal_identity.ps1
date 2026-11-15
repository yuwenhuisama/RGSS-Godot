$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root = Split-Path $PSScriptRoot -Parent
$work = Join-Path $root '.omo/compatibility-run-tmp/f09-marshal-identity-original'
& ruby (Join-Path $PSScriptRoot 'prepare_original_fixture.rb') (Get-TestPath 'game_project') $work (Join-Path $root 'tests/fixtures/marshal_identity_reference.rb')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$game = Start-Process (Join-Path $work 'Game.exe') -WorkingDirectory $work -PassThru -Wait
if ($game.ExitCode -ne 0) { throw "Original exit $($game.ExitCode)" }
Get-Content (Join-Path $work 'marshal_identity_reference.tsv')
Write-Output 'ORIGINAL_MARSHAL_IDENTITY_CAPTURED'
