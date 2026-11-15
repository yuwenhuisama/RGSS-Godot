param([string]$Name='windows-archived-mruby-rebuild',[switch]$Resume,[switch]$SharedOnly)
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$archive=Join-Path $PSScriptRoot 'source/mruby-current-source.zip'
$out=Join-Path $root ".omo/evidence/$Name"
if((Test-Path $out) -and -not $Resume){throw 'Preserve Windows archive build evidence.'}
$sha=[Security.Cryptography.SHA256]::Create()
try{$hash=([BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($archive)))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
if($hash -ne '354d38673ef8775a1f0bda4e2525cfd11321b0279e4d5a04565669cfd6a02783'){throw 'Source archive hash differs.'}
if(-not $Resume){
 Add-Type -AssemblyName System.IO.Compression.FileSystem
 [IO.Compression.ZipFile]::ExtractToDirectory($archive,$out)
}
Copy-Item "$PSScriptRoot/build_config_windows_archive.rb" $out
if(Test-Path "$out/build-test.log"){Move-Item "$out/build-test.log" "$out/build-test-$([DateTime]::UtcNow.Ticks).log"}
$info=New-Object Diagnostics.ProcessStartInfo
$info.FileName='cmd.exe'
$info.Arguments='/d /c ""'+$PSScriptRoot+'\build_windows_archive.cmd" "'+$out+'""'
if($SharedOnly){$info.Arguments='/d /c ""'+$PSScriptRoot+'\build_windows_archive.cmd" "'+$out+'" shared"'}
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
[IO.File]::WriteAllText("$out/build-test.log",$stdout.Result)
[IO.File]::WriteAllText("$out/build-stderr.log",$stderr.Result)
Write-Output $stdout.Result
Write-Output $stderr.Result
Write-Output "WINDOWS_ARCHIVE_BUILD_EXIT:$($process.ExitCode)"
if($process.ExitCode -ne 0){exit $process.ExitCode}
& "$out/mruby/build/host-dll/bin/mruby.exe" "$PSScriptRoot/test_defined_semantics.rb" 2>&1 | Tee-Object "$out/defined-semantics.log"
if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}
if(-not(Test-Path "$out/mruby-shared/build/windows/x64/release/libmruby_x64.dll")){throw 'Shared host missing.'}
Write-Output 'WINDOWS_ARCHIVED_SOURCE_REBUILD_PASS'
