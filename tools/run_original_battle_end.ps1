$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/test_paths.ps1"
$destination = Join-Path $PSScriptRoot '../.omo/compatibility-run-tmp/e01-battle-end-original'
Get-ChildItem (Join-Path (Get-TestPath 'game_project') 'Data/*.rvdata2') | Where-Object Name -ne 'Scripts.rvdata2' | Copy-Item -Destination (Join-Path $destination 'Data')
New-Item -ItemType Directory -Force (Join-Path $destination 'Audio/SE') | Out-Null
Copy-Item (Join-Path (Get-TestPath 'rtp') 'Audio/SE/*') (Join-Path $destination 'Audio/SE')
Set-Location $destination
if (Test-Path './battle_end_error.txt') { Move-Item './battle_end_error.txt' './battle_end_missing_audio.txt' }
$ruby = @'
require 'zlib'
require File.join(ENV.fetch('RGSS_TEST_REPO_ROOT'), 'tools/test_paths')
fixture = File.read('../../../tests/fixtures/battle_end_reference.rb')
wrapper = "begin\n" + fixture + "\nrescue SystemExit\nraise\nrescue Exception => error\nFile.open('battle_end_error.txt','w') { |f| f.puts error.class,error.message,error.backtrace }; exit\nend\n"
scripts = Marshal.load(File.binread('Data/Scripts.rvdata2'))
scripts[-1][2] = Zlib::Deflate.deflate(TestPathsConfig.fixture_source(wrapper))
File.binwrite('Data/Scripts.rvdata2', Marshal.dump(scripts))
'@
$ruby | ruby
if ($LASTEXITCODE -ne 0) { throw 'Fixture refresh failed' }
$process = Start-Process ./Game.exe -PassThru -Wait
Write-Output "ORIGINAL_EXIT:$($process.ExitCode)"
if ($process.ExitCode -ne 0 -or (Test-Path './battle_end_error.txt')) { exit 1 }
if (-not (Test-Path './battle_end_reference.tsv')) { throw 'Original battle-end output missing' }
Write-Output 'ORIGINAL_BATTLE_END_READY'
