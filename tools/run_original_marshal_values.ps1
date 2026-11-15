$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/test_paths.ps1"
Set-Location (Join-Path $PSScriptRoot '../.omo/compatibility-run-tmp/f04-marshal-values-int64-original')
$refresh = @'
require 'zlib'
require File.join(ENV.fetch('RGSS_TEST_REPO_ROOT'), 'tools/test_paths')
fixture = "$marshal_values_peer=#{TestPathsConfig.repo('.omo/evidence/rmva-compatibility/godot/marshal-values/marshal_values_payload.bin').inspect}\n" + File.read('../../../tests/fixtures/marshal_values_reference.rb')
wrapper = "begin\n" + fixture + "\nrescue SystemExit\nraise\nrescue Exception => error\nFile.open('marshal_values_peer_error.txt','w') { |file| file.puts error.class,error.message,error.backtrace }; exit\nend\n"
File.binwrite('Data/Scripts.rvdata2', Marshal.dump([[1, 'Compatibility', Zlib::Deflate.deflate(TestPathsConfig.fixture_source(wrapper))]]))
'@
$refresh | ruby
if ($LASTEXITCODE -ne 0) { throw 'Marshal value fixture refresh failed' }
$process = Start-Process ./Game.exe -PassThru -Wait
Write-Output "ORIGINAL_EXIT:$($process.ExitCode)"
if ($process.ExitCode -ne 0) { exit 1 }
if (Test-Path './marshal_values_peer_error.txt') { throw 'Marshal value peer exception recorded' }
if (-not (Test-Path './marshal_values_reference.tsv')) { throw 'Marshal values ledger missing' }
Write-Output 'ORIGINAL_MARSHAL_VALUES_READY'
