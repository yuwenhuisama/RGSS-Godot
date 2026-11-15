param([string]$Name = 'windows-clean-install-explicit-exit')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$work = Join-Path $root ('.omo/evidence/' + $Name)
$install = Join-Path $work 'install'
$decoder = Join-Path $install 'data_RGSS-Godot_windows_x86_64/Plugins/windows/audio/ffmpeg.exe'
$inputFile = Join-Path $install 'RMProject/Audio/BGM/clean-install-tone.wma'
if (Test-Path $inputFile) { throw 'Owned decoder input already exists' }
Copy-Item (Join-Path $root 'tests/fixtures/audio/tone.wma') $inputFile
$output = Join-Path $work 'decoded.wav'
$start = New-Object System.Diagnostics.ProcessStartInfo
$start.FileName = $decoder
$start.WorkingDirectory = Join-Path $work 'empty-working-directory'
$start.Arguments = '-hide_banner -loglevel error -y -i "' + $inputFile + '" -vn -acodec pcm_s16le "' + $output + '"'
$start.UseShellExecute = $false
$start.EnvironmentVariables['PATH'] = "$env:SystemRoot\System32;$env:SystemRoot"
$process = [System.Diagnostics.Process]::Start($start)
$null = $process.Handle
if (-not $process.WaitForExit(30000)) {
    $process.Kill()
    throw 'Bundled decoder exceeded 30 seconds'
}
if ($process.ExitCode -ne 0) { throw "Bundled decoder failed: $($process.ExitCode)" }
if (-not (Test-Path $output)) { throw 'Bundled decoder produced no WAV' }
Write-Output "CLEAN_INSTALL_DECODE_EXIT:$($process.ExitCode)"
