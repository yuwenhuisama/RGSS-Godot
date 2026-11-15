$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$source = Join-Path $root '.omo/evidence/audio-decoder/linux'
$destination = Join-Path $root 'Plugins/linux/audio'
New-Item -ItemType Directory -Path $destination -Force | Out-Null
foreach ($name in @('ffmpeg', 'ffmpeg-8.1.3.tar.xz', 'LICENSE.txt', 'NOTICE.txt', 'BUILD.txt')) {
    $target = Join-Path $destination $name
    if (-not (Test-Path $target)) { Copy-Item (Join-Path $source $name) $target }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $expected = [BitConverter]::ToString($sha.ComputeHash([System.IO.File]::ReadAllBytes((Join-Path $source $name))))
        $actual = [BitConverter]::ToString($sha.ComputeHash([System.IO.File]::ReadAllBytes($target)))
    } finally { $sha.Dispose() }
    if ($expected -ne $actual) {
        throw "Linux decoder deployment mismatch: $name"
    }
}
Write-Output 'LINUX_PRODUCTION_DECODER_DEPLOYED'
