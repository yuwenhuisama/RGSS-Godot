param([string]$Name = 'windows-clean-install')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$work = Join-Path $root ('.omo/evidence/' + $Name)
if (Test-Path $work) { throw 'Clean-install evidence already exists' }
New-Item -ItemType Directory -Path $work | Out-Null
$install = Join-Path $work 'install'
New-Item -ItemType Directory -Path $install | Out-Null
$exe = Join-Path $install 'RGSS-Godot.exe'
& 'E:/Godot/Godot_v4.6.1-stable_mono_win64_console.exe' --headless --path $root --export-release 'Windows Desktop' $exe --max-fps 60 --quit-after 120 --log-file (Join-Path $work 'export.log')
if ($LASTEXITCODE -ne 0) { throw "Export failed: $LASTEXITCODE" }
Copy-Item (Join-Path $root 'RGSS') (Join-Path $install 'RGSS') -Recurse
$project = Join-Path $install 'RMProject'
New-Item -ItemType Directory -Path $project | Out-Null
foreach ($folder in @('Data', 'Graphics', 'Audio', 'Movies')) {
    Copy-Item (Join-Path 'E:/Projects/RMProject' $folder) (Join-Path $project $folder) -Recurse
}
# Installed licensed assets are copied only into this local acceptance fixture.
$rtp = Join-Path $install 'RTP'
New-Item -ItemType Directory -Path $rtp | Out-Null
foreach ($folder in @('Graphics', 'Audio')) {
    Copy-Item (Join-Path 'F:/Softwares/RPG Maker VX Ace/RTP' $folder) (Join-Path $rtp $folder) -Recurse
}
$config = @{
    project_path = '.'
    rtp_path = $rtp
    legacy_mode = $true
    legacy_mode_width = 544
    legacy_mode_height = 416
    cn_ver_rmva = $true
}
$config | ConvertTo-Json | Set-Content (Join-Path $install 'rm_conf.json') -Encoding UTF8
New-Item -ItemType Directory -Path (Join-Path $work 'empty-working-directory') | Out-Null
Write-Output "CLEAN_WINDOWS_INSTALL_READY:$install"
