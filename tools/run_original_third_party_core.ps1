$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/test_paths.ps1"
$destination = Join-Path $PSScriptRoot '../.omo/compatibility-run-tmp/f07-yea-core-original'
New-Item -ItemType Directory -Path (Join-Path $destination 'Graphics/System') -Force | Out-Null
Copy-Item (Join-Path (Get-TestPath 'rtp') 'Graphics/System/Window.png') (Join-Path $destination 'Graphics/System/Window.png') -Force
Get-ChildItem (Join-Path (Get-TestPath 'game_project') 'Data/*.rvdata2') | Where-Object Name -ne 'Scripts.rvdata2' | Copy-Item -Destination (Join-Path $destination 'Data')
Set-Location $destination
$refresh = @'
require 'zlib'
require File.join(ENV.fetch('RGSS_TEST_REPO_ROOT'), 'tools/test_paths')
scripts=Marshal.load(File.binread(File.join(TestPathsConfig.path('game_project'), 'Data/Scripts.rvdata2'))).reject {|entry|entry[1]=='Main'}
plugin=File.read('../../../tests/fixtures/third_party/Ace_Core_Engine.rb')
fixture=File.read('../../../tests/fixtures/third_party_core_reference.rb')
body="begin\n"+plugin+"\n"+fixture+"\nrescue SystemExit\nraise\nrescue Exception => error\nFile.open('third_party_core_error.txt','w') {|f|f.puts error.class,error.message,error.backtrace}; exit\nend\n"
scripts << [1001,'YEA Core + Probe',Zlib::Deflate.deflate(TestPathsConfig.fixture_source(body))]
File.binwrite('Data/Scripts.rvdata2',Marshal.dump(scripts))
'@
$refresh | ruby
if ($LASTEXITCODE -ne 0) { throw 'Third-party fixture refresh failed' }
$process=Start-Process ./Game.exe -PassThru -Wait
Write-Output "ORIGINAL_EXIT:$($process.ExitCode)"
if ($process.ExitCode -ne 0) { exit 1 }
if (Test-Path './third_party_core_error.txt') { throw 'Third-party fixture error recorded' }
if (-not (Test-Path './third_party_core_reference.tsv')) { throw 'Third-party ledger missing' }
Write-Output 'ORIGINAL_THIRD_PARTY_CORE_READY'
