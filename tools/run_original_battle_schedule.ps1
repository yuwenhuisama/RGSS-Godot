$ErrorActionPreference='Stop'
$destination=Join-Path $PSScriptRoot '../.omo/compatibility-run-tmp/e04-battle-schedule-original'
Get-ChildItem 'E:/Projects/RMProject/Data/*.rvdata2' | Where-Object Name -ne 'Scripts.rvdata2' | Copy-Item -Destination (Join-Path $destination 'Data')
Set-Location $destination
$ruby=@'
require 'zlib'
fixture=File.read('../../../tests/fixtures/battle_schedule_reference.rb')
wrapper="begin\n"+fixture+"\nrescue SystemExit\nraise\nrescue Exception => error\nFile.open('battle_schedule_error.txt','w') { |f| f.puts error.class,error.message,error.backtrace }; exit\nend\n"
scripts=Marshal.load(File.binread('Data/Scripts.rvdata2'))
scripts[-1][2]=Zlib::Deflate.deflate(wrapper)
File.binwrite('Data/Scripts.rvdata2',Marshal.dump(scripts))
'@
$ruby | ruby
if ($LASTEXITCODE -ne 0) { throw 'Schedule fixture refresh failed' }
$process=Start-Process ./Game.exe -PassThru -Wait
Write-Output "ORIGINAL_EXIT:$($process.ExitCode)"
if ($process.ExitCode -ne 0 -or (Test-Path './battle_schedule_error.txt')) { exit 1 }
if (-not (Test-Path './battle_schedule_reference.tsv')) { throw 'Schedule output missing' }
Write-Output 'ORIGINAL_BATTLE_SCHEDULE_READY'
