$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$out=Join-Path $root '.omo/evidence/stable-linux-host-source'
if(Test-Path $out){throw 'Preserve stable-source verification.'}
New-Item -ItemType Directory $out | Out-Null
& 'C:/Program Files/Docker/Docker/resources/bin/docker.exe' run --rm --name rgss-stable-source-host --mount "type=bind,source=$root,target=/repo,readonly" --mount "type=bind,source=$out,target=/output" rgss-linux-godot-verified:local bash -c 'set -e; bash -n /repo/tools/build_linux_current_mruby.sh /repo/tools/build_linux_shared_host.sh; bash /repo/tools/build_linux_shared_host.sh'
exit $LASTEXITCODE
