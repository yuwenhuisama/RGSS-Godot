# Current owned compiler source

mruby-current-source.zip contains756source/license/config files for the owned
mruby4compiler and shared native binding. SHA256:
354d38673ef8775a1f0bda4e2525cfd11321b0279e4d5a04565669cfd6a02783

Pinned upstream base and compatibility changes are described in the parent
README. Upstream license and generated parser sources are included. Root build
outputs, Git metadata and caches are excluded; nested lib/mruby/build sources
are retained. The archive is byte-identical to the independently rebuilt copy
in .omo/evidence/owned-compiler-source-archive-complete.

That isolated rebuild passed1696upstream cases with0failures/0crashes/9skips,
65defined semantics cases and the shared-host callback/error-recovery probe.
It did not mount the original source tree. No bit-identical binary claim follows.
Linux build recipes read this fixed source input rather than temporary trees.
Other historical experiment scripts may still refer to their original inputs.

Windows reconstruction from this same archive also succeeds: 1661 upstream
cases pass, 0 fail, 0 crash, 28 skip; all 65 defined semantics cases pass and
the Windows/x64 shared DLL builds. See ../run_windows_archive.ps1 and
.omo/evidence/windows-archived-mruby-zipapi. The reconstructed Windows DLL is
not deployed. Its subsequent extension ABI probe passes at exit 0: class
layout, all four production extension initializers and their combined smoke
check pass in `.omo/evidence/windows-archived-mruby-abi/probe.log`.
Godot guest checks against this reconstructed DLL remain unrun.
