$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/test_paths.ps1"
Set-Location (Join-Path $PSScriptRoot '../.omo/compatibility-run-tmp/f01-rpg-defaults-original')
$refresh = @'
require 'zlib'
require File.join(ENV.fetch('RGSS_TEST_REPO_ROOT'), 'tools/test_paths')
fixture = File.read('../../../tests/fixtures/rpg_defaults_reference.rb')
wrapper = "begin\n" + fixture + "\nrescue SystemExit\nraise\nrescue Exception => error\nFile.open('rpg_defaults_error.txt','w') { |file| file.puts error.class,error.message,error.backtrace }; exit\nend\n"
File.binwrite('Data/Scripts.rvdata2', Marshal.dump([[1, 'Compatibility', Zlib::Deflate.deflate(TestPathsConfig.fixture_source(wrapper))]]))
'@
$refresh | ruby
if ($LASTEXITCODE -ne 0) { throw 'RPG defaults refresh failed' }
Remove-Item './rpg_defaults_error.txt' -ErrorAction SilentlyContinue
$process = Start-Process ./Game.exe -PassThru -Wait
Write-Output "ORIGINAL_EXIT:$($process.ExitCode)"
if ($process.ExitCode -ne 0) { exit 1 }
if (Test-Path './rpg_defaults_error.txt') { throw 'RPG defaults exception recorded' }
if (-not (Test-Path './rpg_defaults_reference.tsv')) { throw 'RPG defaults output missing' }
Write-Output 'ORIGINAL_RPG_DEFAULTS_READY'
