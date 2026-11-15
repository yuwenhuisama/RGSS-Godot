$ErrorActionPreference = 'Stop'
$process = Start-Process -FilePath 'cmd.exe' -ArgumentList @('/d', '/c', (Join-Path $PSScriptRoot 'build_marshal_encoding.cmd')) -NoNewWindow -PassThru -Wait
Write-Output "MARSHAL_BUILD_EXIT:$($process.ExitCode)"
exit $process.ExitCode
