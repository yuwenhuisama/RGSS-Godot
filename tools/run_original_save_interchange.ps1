$ErrorActionPreference = 'Stop'
$destination = Join-Path $PSScriptRoot '../.omo/compatibility-run-tmp/f02-save-interchange-original'
Get-ChildItem 'E:/Projects/RMProject/Data/*.rvdata2' | Where-Object Name -ne 'Scripts.rvdata2' | Copy-Item -Destination (Join-Path $destination 'Data')
Set-Location $destination
$refresh = @'
require 'zlib'
fixture = "$save_interchange_peer='E:/Projects/RGSS-Godot/.omo/evidence/rmva-compatibility/godot/save-interchange/Save1.rvdata2'\n" + File.read('../../../tests/fixtures/save_interchange_reference.rb')
wrapper = "begin\n" + fixture + "\nrescue SystemExit\nraise\nrescue Exception => error\nFile.open('save_interchange_error.txt','w') { |file| file.puts error.class,error.message,error.backtrace }; exit\nend\n"
scripts = Marshal.load(File.binread('Data/Scripts.rvdata2'))
scripts[-1][2] = Zlib::Deflate.deflate(wrapper)
File.binwrite('Data/Scripts.rvdata2', Marshal.dump(scripts))
'@
$refresh | ruby
if ($LASTEXITCODE -ne 0) { throw 'Save fixture refresh failed' }
Remove-Item './save_interchange_error.txt' -ErrorAction SilentlyContinue
$process = Start-Process ./Game.exe -PassThru -Wait
Write-Output "ORIGINAL_EXIT:$($process.ExitCode)"
if ($process.ExitCode -ne 0) { exit 1 }
if (Test-Path './save_interchange_error.txt') { throw 'Save interchange exception recorded' }
if (-not (Test-Path './save_interchange_reference.tsv')) { throw 'Save interchange ledger missing' }
Write-Output 'ORIGINAL_SAVE_INTERCHANGE_READY'
