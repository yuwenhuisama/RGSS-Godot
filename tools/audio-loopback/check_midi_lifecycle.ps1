param([Parameter(Mandatory=$true)][string]$Prefix)
$ErrorActionPreference = 'Stop'
# Recorded callback clocks are required: WASAPI can omit silent PCM intervals.
$wave = [IO.File]::ReadAllBytes($Prefix + 'capture.wav')
$offset = 12
while ($offset + 8 -le $wave.Length) {
    $tag = [Text.Encoding]::ASCII.GetString($wave, $offset, 4)
    $size = [BitConverter]::ToUInt32($wave, $offset + 4)
    if ($tag -eq 'fmt ') {
        if ([BitConverter]::ToUInt16($wave,$offset+8) -ne 3 -or
            [BitConverter]::ToUInt16($wave,$offset+10) -ne 2 -or
            [BitConverter]::ToUInt32($wave,$offset+12) -ne 48000 -or
            [BitConverter]::ToUInt16($wave,$offset+22) -ne 32) {
            throw 'Expected float32 stereo 48000 Hz capture.'
        }
    }
    if ($tag -eq 'data') { $dataOffset = $offset + 8; break }
    $offset += 8 + $size + ($size % 2)
}
if (-not $dataOffset) { throw 'PCM data chunk missing.' }
$events = @{}
foreach ($line in [IO.File]::ReadAllLines($Prefix + 'midi_me_signal_events.tsv')) {
    $fields = $line.Split("`t")
    $events[$fields[0]] = [double]::Parse($fields[1], [Globalization.CultureInfo]::InvariantCulture)
}
$chunks = Import-Csv ($Prefix + 'capture.wav.chunks.tsv') -Delimiter "`t"
$passed = $true
foreach ($mode in @('stop','fade','stopped-bgm')) {
    $windows = @(
        @('baseline', ($events["$mode-midi"] + 0.3), ($events["$mode-me"] - 0.15), $true),
        @('during-me', ($events["$mode-me"] + 0.25), ($events["$mode-release"] - 0.1), $true)
    )
    $end = $events["$mode-end"]
    if ($mode -eq 'fade' -and $events.ContainsKey('fade-explicit-stop')) {
        $end = $events['fade-explicit-stop']
        $windows += ,@('explicit-stop-resumes', ($end + 0.4), ($events['fade-end'] - 0.15), $true)
    }
    $windows += ,@('released', ($events["$mode-release"] + 0.65), ($end - 0.15), ($mode -eq 'stop'))
    foreach ($window in $windows) {
        $sum = 0.0
        $count = 0
        foreach ($chunk in $chunks) {
            $time = [double]::Parse($chunk.callback_unix_seconds, [Globalization.CultureInfo]::InvariantCulture)
            if ($time -lt $window[1] -or $time -gt $window[2]) { continue }
            $start = $dataOffset + [int]$chunk.pcm_byte_offset
            for ($i = 0; $i -lt [int]$chunk.byte_count; $i += 8) {
                $sample = ([BitConverter]::ToSingle($wave,$start+$i) + [BitConverter]::ToSingle($wave,$start+$i+4)) / 2.0
                $sum += $sample * $sample
                $count++
            }
        }
        if ($count -eq 0) { throw "Missing measured samples: $mode/$($window[0])" }
        $rms = [Math]::Sqrt($sum / $count)
        $ok = if ($window[3]) { $rms -gt 0.001 } else { $rms -lt 0.0005 }
        Write-Output "MIDI_LIFECYCLE:$mode/$($window[0]):rms=$($rms):pass=$ok"
        $passed = $passed -and $ok
    }
}
if (-not $passed) { throw 'MIDI lifecycle signal differs from measured RGSS300 behavior.' }
Write-Output 'MIDI_LIFECYCLE_SIGNAL_PASS'
