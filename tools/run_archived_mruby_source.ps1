$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$archive=Join-Path $root '.omo/evidence/owned-compiler-source-archive-complete/current-source.zip'
$out=Join-Path $root '.omo/evidence/archived-mruby-source-rebuild-complete'
if(Test-Path $out){throw 'Preserve source-rebuild evidence.'}
New-Item -ItemType Directory "$out/checks" | Out-Null
Copy-Item "$root/tools/defined-compiler/build_config_linux.rb","$root/tools/defined-compiler/test_defined_semantics.rb","$root/tools/linux_shared_host_probe.c","$root/tools/test_archived_mruby_source.sh" "$out/checks/"
& 'C:/Program Files/Docker/Docker/resources/bin/docker.exe' run --rm --name rgss-archive-rebuild --mount "type=bind,source=$archive,target=/archive.zip,readonly" --mount "type=bind,source=$out/checks,target=/checks,readonly" --mount "type=bind,source=$out,target=/output" ubuntu:24.04 bash /checks/test_archived_mruby_source.sh
exit $LASTEXITCODE
