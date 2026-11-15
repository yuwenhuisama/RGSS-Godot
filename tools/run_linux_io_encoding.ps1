param([string]$Name='file-binary-native')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$output=Join-Path $root ".omo/evidence/$Name"
if(Test-Path $output){throw 'Preserve existing native candidate.'}
New-Item -ItemType Directory $output | Out-Null
& 'C:/Program Files/Docker/Docker/resources/bin/docker.exe' run --rm --network none --mount "type=bind,source=$root,target=/repo,readonly" --mount "type=bind,source=$output,target=/output" rgss-linux-godot-verified:local bash /repo/tools/build_linux_io_encoding.sh
exit $LASTEXITCODE
