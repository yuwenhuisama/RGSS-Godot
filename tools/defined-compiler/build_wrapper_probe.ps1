$ErrorActionPreference = 'Stop'
$process = Start-Process cmd.exe -ArgumentList @('/d','/c',(Join-Path $PSScriptRoot 'build_wrapper_probe.cmd')) -NoNewWindow -PassThru
$null = $process.Handle
$process.WaitForExit()
Write-Output "WRAPPER_PROBE_BUILD_EXIT:$($process.ExitCode)"
exit $process.ExitCode
