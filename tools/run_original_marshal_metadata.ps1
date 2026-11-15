$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/test_paths.ps1"
Set-Location (Join-Path $PSScriptRoot '../.omo/compatibility-run-tmp/f04-marshal-metadata-original')
$refresh = @'
require 'zlib'
require File.join(ENV.fetch('RGSS_TEST_REPO_ROOT'), 'tools/test_paths')
fixture = "$marshal_encoding_peer=#{TestPathsConfig.repo('.omo/evidence/rmva-compatibility/godot/marshal-metadata').inspect}\n" + File.read('../../../tests/fixtures/marshal_metadata_reference.rb')
wrapper = "begin\n" + fixture + "\nrescue SystemExit\nraise\nrescue Exception => error\nFile.open('marshal_metadata_error.txt','w') { |file| file.puts error.class,error.message,error.backtrace }; exit\nend\n"
File.binwrite('Data/Scripts.rvdata2', Marshal.dump([[1, 'Compatibility', Zlib::Deflate.deflate(TestPathsConfig.fixture_source(wrapper))]]))
'@
$refresh | ruby
if ($LASTEXITCODE -ne 0) { throw 'Marshal metadata refresh failed' }
Remove-Item './marshal_metadata_error.txt' -ErrorAction SilentlyContinue
$process = Start-Process ./Game.exe -PassThru -Wait
Write-Output "ORIGINAL_EXIT:$($process.ExitCode)"
if ($process.ExitCode -ne 0) { exit 1 }
if (Test-Path './marshal_metadata_error.txt') { throw 'Marshal metadata exception recorded' }
if (-not (Test-Path './marshal_metadata_reference.tsv')) { throw 'Marshal metadata ledger missing' }
Write-Output 'ORIGINAL_MARSHAL_METADATA_READY'
