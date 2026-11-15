param([Parameter(Mandatory=$true)][string]$Source)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$destination=Join-Path $root 'Plugins/windows/audio'
if (-not (Test-Path -LiteralPath $Source)) { throw 'ffmpeg source does not exist' }
$Source=(Resolve-Path -LiteralPath $Source).Path
# FFmpeg writes its banner to stderr even when the command succeeds.
$license = & $Source -hide_banner -L 2>&1 | ForEach-Object { "$_" }
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$licenseText = $license -join "`n"
if ($licenseText -notmatch 'GNU Lesser General Public' -or
    $licenseText -notmatch 'version 2\.1 of the License' -or
    $licenseText -match 'version 3 of the License') {
    throw 'Decoder must use LGPL version 2.1 or later without GPL/version3 build options.'
}
$decoders = & $Source -hide_banner -decoders 2>&1 | ForEach-Object { "$_" }
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$decoderText = $decoders -join "`n"
foreach ($decoder in @('wmav1','wmav2','wmapro','wmalossless','wmavoice')) {
    if ($decoderText -notmatch "(?m)^\s*A\S*\s+$decoder\s+") {
        throw "Required decoder missing: $decoder"
    }
}
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Copy-Item -LiteralPath $Source -Destination (Join-Path $destination 'ffmpeg.exe')
$license
Write-Output 'BUNDLED_AUDIO_DECODER_READY'
