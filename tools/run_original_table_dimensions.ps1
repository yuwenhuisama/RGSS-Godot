$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '../.omo/compatibility-run-tmp/f01-table-dimensions-original')
$refresh = @'
require 'zlib'
fixture = File.read('../../../tests/fixtures/table_dimensions_reference.rb')
wrapper = "begin\n" + fixture + "\nrescue SystemExit\nraise\nrescue Exception => error\nFile.open('table_dimensions_error.txt','w') { |file| file.puts error.class,error.message,error.backtrace }; exit\nend\n"
File.binwrite('Data/Scripts.rvdata2', Marshal.dump([[1, 'Compatibility', Zlib::Deflate.deflate(wrapper)]]))
'@
$refresh | ruby
if ($LASTEXITCODE -ne 0) { throw 'Table dimensions refresh failed' }
Remove-Item './table_dimensions_error.txt' -ErrorAction SilentlyContinue
$process = Start-Process ./Game.exe -PassThru -Wait
Write-Output "ORIGINAL_EXIT:$($process.ExitCode)"
if ($process.ExitCode -ne 0) { exit 1 }
if (Test-Path './table_dimensions_error.txt') { throw 'Table dimensions exception recorded' }
if (-not (Test-Path './table_dimensions_reference.tsv')) { throw 'Table dimensions output missing' }
Write-Output 'ORIGINAL_TABLE_DIMENSIONS_READY'
