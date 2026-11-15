param([string]$Name = 'test-path-relocation')
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/test_paths.ps1"
$godot = Get-TestPath 'godot'
$work = Get-TestRepoPath ('.omo/evidence/' + $Name)
if (Test-Path $work) { throw 'Relocation evidence already exists' }
$project = Join-Path $work 'checkout with spaces'
New-Item -ItemType Directory -Path $project | Out-Null
foreach ($directory in @('Scripts', 'RGSS', 'Shaders', 'Plugins', 'Scenes', 'tests')) {
    Copy-Item (Join-Path $TestRepoRoot $directory) $project -Recurse
}
Copy-Item (Join-Path $TestRepoRoot 'project.godot') $project
New-Item -ItemType Directory -Path (Join-Path $project 'tools') | Out-Null
foreach ($file in @('test_paths.gd', 'test_path_contract.gd', 'test_paths.rb', 'test_paths.ps1', 'test_paths.py')) {
    Copy-Item (Join-Path $PSScriptRoot $file) (Join-Path $project 'tools')
}
New-Item -ItemType Directory -Path (Join-Path $project '.godot/mono/temp') -Force | Out-Null
Copy-Item (Join-Path $TestRepoRoot '.godot/mono/temp/bin') (Join-Path $project '.godot/mono/temp') -Recurse
$env:RGSS_TEST_PATHS_FILE = Join-Path $work 'local-inputs.json'
@{game_project = Get-TestPath 'game_project'; rtp = Get-TestPath 'rtp'} | ConvertTo-Json |
    Set-Content -LiteralPath $env:RGSS_TEST_PATHS_FILE -Encoding UTF8
& $godot --headless --path $project -s tools/test_path_contract.gd
if ($LASTEXITCODE -ne 0) { throw 'Relocated path contract failed' }
& $godot --headless --path $project -s tests/test_cursor_cache.gd
if ($LASTEXITCODE -ne 0) { throw 'Relocated actual fixture contract failed' }
Write-Output 'RELOCATED_TEST_PATH_CONFIG_PASS'
