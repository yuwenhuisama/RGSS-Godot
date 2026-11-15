$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/test_paths.ps1"
$destination = Join-Path $PSScriptRoot '../.omo/compatibility-run-tmp/e05-battle-animation-pixels-original'
Get-ChildItem (Join-Path (Get-TestPath 'game_project') 'Data/*.rvdata2') | Where-Object Name -ne 'Scripts.rvdata2' | Copy-Item -Destination (Join-Path $destination 'Data')
New-Item -ItemType Directory -Force (Join-Path $destination 'Graphics/System') | Out-Null
Copy-Item (Join-Path (Get-TestPath 'rtp') 'Graphics/System/Window.png') (Join-Path $destination 'Graphics/System/Window.png') -Force
Set-Location $destination
$refresh = @'
require 'zlib'
require File.join(ENV.fetch('RGSS_TEST_REPO_ROOT'), 'tools/test_paths')
fixture = File.read('../../../tests/fixtures/battle_animation_pixels_reference.rb')
wrapper = "begin\n" + fixture + "\nrescue SystemExit\nraise\nrescue Exception => error\nFile.open('battle_animation_pixels_error.txt','w') { |file| file.puts error.class,error.message,error.backtrace }; exit\nend\n"
scripts=Marshal.load(File.binread('Data/Scripts.rvdata2'))
scripts[-1][2]=Zlib::Deflate.deflate(TestPathsConfig.fixture_source(wrapper))
File.binwrite('Data/Scripts.rvdata2',Marshal.dump(scripts))
'@
$refresh | ruby
if ($LASTEXITCODE -ne 0) { throw 'Animation pixel fixture refresh failed' }
$process = Start-Process ./Game.exe -PassThru -Wait
Write-Output "ORIGINAL_EXIT:$($process.ExitCode)"
if ($process.ExitCode -ne 0) { exit 1 }
if (Test-Path './battle_animation_pixels_error.txt') { throw 'Animation pixel exception recorded' }
if (-not (Test-Path './battle_animation_pixels.rgba')) { throw 'Animation RGBA missing' }
Write-Output 'ORIGINAL_BATTLE_ANIMATION_PIXELS_READY'
