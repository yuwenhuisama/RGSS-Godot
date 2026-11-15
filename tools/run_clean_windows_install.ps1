param([string]$Name = 'windows-clean-install-explicit-exit', [string]$LogName = 'runtime.log', [string]$ExpectedMarker = '')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$work = Join-Path $root ('.omo/evidence/' + $Name)
$install = Join-Path $work 'install'
$start = New-Object System.Diagnostics.ProcessStartInfo
$start.FileName = Join-Path $install 'RGSS-Godot.exe'
$start.WorkingDirectory = Join-Path $work 'empty-working-directory'
$start.Arguments = '--windowed --rendering-method gl_compatibility --quit-after 180 --log-file "' + (Join-Path $work $LogName) + '"'
$start.UseShellExecute = $false
$start.RedirectStandardOutput = $true
$start.RedirectStandardError = $true
$start.EnvironmentVariables['PATH'] = "$env:SystemRoot\System32;$env:SystemRoot"
$start.EnvironmentVariables.Remove('RGSS_FFMPEG_PATH')
$start.EnvironmentVariables.Remove('MRUBY_DIR')
$process = [System.Diagnostics.Process]::Start($start)
$null = $process.Handle
$stdout = $process.StandardOutput.ReadToEndAsync()
$stderr = $process.StandardError.ReadToEndAsync()
if (-not $process.WaitForExit(90000)) {
    $process.Kill()
    throw 'Isolated exported runtime exceeded 90 seconds'
}
Write-Output "CLEAN_INSTALL_RUNTIME_EXIT:$($process.ExitCode)"
$console = $stdout.GetAwaiter().GetResult() + $stderr.GetAwaiter().GetResult()
[System.IO.File]::WriteAllText((Join-Path $work ($LogName + '.console.txt')), $console)
Write-Output $console
Get-Content (Join-Path $work $LogName) | Select-String 'CONFIG|RMPROJECT_PATH|SCRIPTS_LOADED|MAIN_LOADED|GEM_INIT_FAIL|Exception|ERROR'
if ($process.ExitCode -ne 0) { throw 'Isolated exported runtime failed' }
$log = [System.IO.File]::ReadAllText((Join-Path $work $LogName)) + $console
if ($log -match 'Exception:|GEM_INIT_FAIL|MAIN_LOADED:FAIL|SCRIPTS_LOADED:FAIL') { throw 'Isolated exported runtime reported a startup failure' }
if ($ExpectedMarker -and -not $log.Contains($ExpectedMarker)) { throw "Missing exported behavior marker: $ExpectedMarker" }
