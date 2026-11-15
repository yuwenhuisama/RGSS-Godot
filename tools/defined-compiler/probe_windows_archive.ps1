$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$build=Join-Path $root '.omo/evidence/windows-archived-mruby-zipapi'
$out=Join-Path $root '.omo/evidence/windows-archived-mruby-abi'
if(Test-Path $out){throw 'Preserve archive ABI probe evidence.'}
New-Item -ItemType Directory $out | Out-Null
Copy-Item "$build/mruby-shared/build/windows/x64/release/libmruby_x64.dll" $out
Copy-Item "$root/Plugins/windows/*_ext_x64.dll" $out
$info=New-Object Diagnostics.ProcessStartInfo
$info.FileName='cmd.exe'
$info.Arguments='/d /c ""'+$PSScriptRoot+'\probe_windows_archive.cmd" "'+$build+'" "'+$out+'""'
$info.UseShellExecute=$false
$info.RedirectStandardOutput=$true
$info.RedirectStandardError=$true
$process=New-Object Diagnostics.Process
$process.StartInfo=$info
$null=$process.Start()
$stdout=$process.StandardOutput.ReadToEndAsync()
$stderr=$process.StandardError.ReadToEndAsync()
$process.WaitForExit()
$process.Refresh()
[IO.File]::WriteAllText("$out/compile.log",$stdout.Result+$stderr.Result)
if($process.ExitCode -ne 0){throw "ABI probe compile failed: $($process.ExitCode)"}
$info.FileName="$out/extended_host_probe.exe"
$info.WorkingDirectory=$out
$info.Arguments='"'+$root+'/RGSS" "'+$out+'"'
$process=New-Object Diagnostics.Process
$process.StartInfo=$info
$null=$process.Start()
$stdout=$process.StandardOutput.ReadToEndAsync()
$stderr=$process.StandardError.ReadToEndAsync()
$process.WaitForExit()
$process.Refresh()
[IO.File]::WriteAllText("$out/probe.log",$stdout.Result+$stderr.Result)
Write-Output $stdout.Result
Write-Output $stderr.Result
Write-Output "ARCHIVED_WINDOWS_ABI_EXIT:$($process.ExitCode)"
exit $process.ExitCode
