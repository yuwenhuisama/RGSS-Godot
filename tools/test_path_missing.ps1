$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/test_paths.ps1"
$godot = Get-TestPath 'godot'
$env:RGSS_TEST_PATHS_FILE = Join-Path $TestRepoRoot '.omo/evidence/test-path-contract/empty.json'
New-Item -ItemType Directory -Force (Split-Path $env:RGSS_TEST_PATHS_FILE -Parent) | Out-Null
Set-Content -LiteralPath $env:RGSS_TEST_PATHS_FILE -Value '{}' -Encoding UTF8
& $godot --headless --path $TestRepoRoot -s tools/test_path_contract.gd -- --missing
if ($LASTEXITCODE -ne 1) { throw "Missing configuration must exit 1, got $LASTEXITCODE" }
Write-Output 'MISSING_TEST_PATH_CONFIG_PASS'
. "$PSScriptRoot/test_paths.ps1"
try {
    Get-TestPath 'game_project'
    throw 'PowerShell accepted a missing game_project'
} catch {
    if ($_.Exception.Message -notlike "Missing test setting 'game_project'*") { throw }
}
Write-Output 'POWERSHELL_MISSING_TEST_PATH_CONFIG_PASS'
