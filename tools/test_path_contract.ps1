param([switch]$Missing)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/test_paths.ps1"
if ($Missing) { Get-TestPath 'game_project'; exit 1 }
$expected = Join-Path $TestRepoRoot 'tests/fixtures/audio/tone.ogg'
if ((Get-TestRepoPath 'tests/fixtures/audio/tone.ogg') -ne $expected) { throw 'Repository path was not derived' }
if (!(Test-Path (Join-Path (Get-TestPath 'game_project') 'Data/Map001.rvdata2'))) { throw 'Configured game input missing' }
Write-Output 'POWERSHELL_TEST_PATH_CONFIG_PASS'
