# F11 installation and sustained resource evidence

Final2026-11-15 Mac acceptance completes the measured three-platform scope.
Actual Apple Silicon Release original-game installation uses relative project/
RTP, fresh HOME, empty cwd and system PATH without developer/native overrides;
Metal windowed startup and normal600-frame exit pass0. The separate current
assembly36000-frame live-map resource owner passes0 in646705ms with exact96
event counters,358nodes and complete5/107/7->5/11/7restoration. GC memory
fluctuates without monotonic growth. FPS mostly55--58with34/30low samples;
Metal texture memory counter is invalid. This is bounded sustained resource
evidence, not unlimited soak or stable60FPS. Soak is not a Release-app owner.
Evidence/limits: macos-verification.md, macos-dense-soak/resource-profile and
macos-release-native-path under .omo/evidence. Earlier dated entries are history.

## Current installation scope (2026-11-14)

Latest rendered Linux owner completed in the installed VMware Ubuntu 24.04.5
x86-64 guest, using Xorg and the VMware DX12 host renderer. The unchanged
36,000-frame resource-profile test reports DENSE_MAP_RUNTIME_PASS and exits 0
after a 1,353,949 ms parallel phase. Every one of the 64 parallel events runs
exactly 1125 times; autorun, action, player-touch and event-touch groups each
run their eight events exactly once. Drawables stay 5/107/7, nodes 358, objects
2170 and texture bytes 15,294,779 throughout. Managed memory rises to
75,719,624 at frame 28,800, then collection lowers it to 31,746,080 at 32,400;
the final value is 39,884,744. Static memory falls correspondingly. Scene
recreation preserves 5/107/7 and teardown restores 5/11/7. Sampled dense-map
FPS is 24-29, distinct from the direct stock-map minute at about 59 FPS.
Independent inspection of the final 544x416 map capture found no missing
textures, corrupted tiles, frame-edge clipping or error overlay. Evidence:
`.omo/evidence/f11-linux-vmware-dx12-xorg`, archive SHA256
`6a3a71d607e0547ea7562c7094f770b92402dd52bc8fb99616c0881b05ee8b9d`.
This establishes that bounded Linux rendered resource owner, not unlimited
stability or other-platform acceptance.

The older llvmpipe container run described below was deliberately stopped at
the user's request (exit 137). It is retained as partial evidence and was not
resumed or accepted. Both Windows and Linux execution now belongs in VMware
guests. Windows 11 Pro x64 is installed from disk with Tools running, a GPT
100 GB virtual disk, TPM present/ready, Secure Boot enabled and VMware SVGA 3D;
its first package run is pending. No macOS host execution is established.

### Earlier software-renderer attempt

A current-source Linux rendered resource-profile run is active under Mesa
llvmpipe/Xvfb via tools/run_linux_dense_map.ps1. It is not a Release-package
run. The first 3,600 frames take 792,499 ms; counts remain 5/107/7, nodes 358,
objects 2166 and texture bytes 15,294,779. Sampled FPS falls from 15 to 4.
Thus this software-renderer run is progressing slowly, not proven hung, and
has not passed the 36,000-frame or final teardown requirements. Seven existing
C# warnings and missing optional libxkbcommon/libdbus diagnostics are retained
in its build/runtime logs. Evidence: f11-linux-rendered-resource-profile.
An independent persistent docker-log subscription mon_X63CSYNFQE1G9BSR watches
the existing container; it does not start another workload. The original CLI
watch has a one-hour deadline, so later CLI termination must be distinguished
from the daemon-managed container's actual completion. No long-run PASS yet.

Linux now has separate offline runtime-only installation evidence: Ubuntu24.04
plus fontconfig/ICU runtime prerequisites, no SDK/compiler/system decoder,
read-only direct installation and fresh user cache. A tar archive also passes
after extraction to /tmp/relocated-install with no network. The current Gzip
library assembled with the exported managed host passes14 original encoding
rows and WMA cache equality in another offline run. See
linux-current-host-verification.md for exact archive hashes and logs. These
headless results cover Linux dependency discovery and package relocation;
they do not cover a graphical desktop or actual output device.

Windows current Gzip library assembled with the existing exported host also
passes all14 original rows at exit0 from an isolated install and restricted
PATH. This remains a local-machine result. The completed36,000-frame workload
below predates later encoding-only changes; it is retained as measured workload
evidence rather than reattributed to a newer library. Clean Windows machine,
macOS and Linux rendered long-run acceptance remain open. No new soak is needed
to establish the encoding-only behavior already covered by native owners.

## Earlier execution records

The current compiler/Gzip host completes its36,000-frame resource owner with
DENSE_MAP_RUNTIME_PASS, exit0, on 2026-11-14. Eleven samples span630,494ms;
viewports/sprites/windows stay5/107/7, nodes358 and texture bytes15,294,779.
Managed bytes range21,081,040..38,423,328 and end25,129,848; sampled FPS57..59.
After event, touch and scene recreation checks, final drawable counts return
from5/107/7 to the baseline5/11/7. Measurements are in the current resource-profile
directory, with the older profile preserved separately. The subsequent nine-row
encoding candidate is a newer library and was not part of this completed soak.
Clean-machine and other-platform installation remain open.

The latest Gzip-enabled Windows export completes exit0. Its existing owned
bootstrap probe now also writes/reads a Gzip file through the exported native
extension and rejects GzipFile allocation; no production bootstrap is changed.
Four-library hash and syntax checks precede actual execution. The earlier
pre-Gzip runtime logs remain preserved, and this export run does not count as
Gzip delivery until EXPORTED_GZIP_PASS appears in actual process output.

The latest exported runtime now completes EXPORTED_GZIP_PASS,
EXPORTED_DEFINED_PASS:3 and EXPORTED_TITLE_WMA_PASS at exit0. Four exported
native libraries match their production hashes, including Zlib
4a97a818b78f9c1fd0a9ad8622fd5a99bfcb83f083c153f4c58de0a7079db8a4.
Evidence is preserved in exported-gzip-runtime.log.console.txt. Installation
relocation with the unchanged relative RTP configuration is the next uncovered
Windows packaging condition; it remains unverified until actual startup passes.

Relocation now passes at exit0 from
`.omo/evidence/windows-relocated-install/install` with unchanged project_path
"." and rtp_path "RTP", restricted PATH and an empty working directory.
RMPROJECT_PATH names the new installation and actual process output contains
all three EXPORTED_DEFINED/GZIP/TITLE_WMA success markers. The complete output
is in relocation-runtime.log.console.txt. This establishes local directory
relocation for the tested Windows bundle; it does not establish clean-machine
installation or another platform.

Relative RTP reproduction: the same isolated export with rtp_path="RTP"
and an empty working directory logs `Failed to load image data, file not found:
RTP/Graphics/Titles1/Plain.png`; the expected title/WMA marker never appears.
The process still exits0, proving that exit status alone is insufficient for
this installation check. GlobalConfig now resolves nonempty RTP paths at the
configuration boundary against the directory containing the selected config
file. Absolute paths retain their meaning; blank RTP stays blank. C# diagnostics
and the build pass before the relative-path export replay below.

The corrected relative-path export reaches EXPORTED_TITLE_WMA_PASS and exits0.
Its first verifier run reports a missing marker because native Ruby puts writes
to process stdout rather than the Godot --log-file channel. The installation
runner now drains stdout/stderr asynchronously, preserves them in a separate
console artifact and checks both channels for errors and the expected marker.
The first green console receipt and its
verifier failure are retained as distinct results.

Final combined-channel capture passes at exit0, preserving both
EXPORTED_DEFINED_PASS:3 and EXPORTED_TITLE_WMA_PASS in
`relative-rtp-verified.log.console.txt`. No startup failure is present. This
closes the reproduced relative RTP installation defect; clean-machine and
other-platform installation remain unverified.

A fresh latest-host Windows release export has completed in
`.omo/evidence/windows-defined-host-install/`, exit0. Its isolated startup
probe checks unevaluated defined? assignment, constant/missing-constant
results, active real title commands and Audio.bgm_play with an owned WMA file.
Only the copied installation bootstrap is instrumented. Native hash comparison
passes for the compiler host, Regexp and Marshal libraries. Actual exported
runtime returns EXPORTED_DEFINED_PASS:3 and EXPORTED_TITLE_WMA_PASS, then
exits0 with CONFIG and MAIN_LOADED markers, from the empty working directory
and restricted PATH. This earlier run predates Gzip integration; the newer
Gzip package result is recorded above. Neither is a clean-machine verdict.

F11 remains open. Local isolation does not prove a clean Windows machine or
another desktop platform.

The existing rendered dense-map resource profile reached 36,000 frames in
621,015 ms. Its eleven samples are preserved in
`.omo/evidence/rmva-compatibility/godot/dense-map/soak/resource-profile/resources.tsv`.
Every sample has 5 viewports, 107 sprites, 7 windows, 358 nodes and 15,294,779
texture bytes. Object count starts at 2,162 then remains 2,161. Managed memory
ranges from 21,075,864 to 38,425,024 bytes and ends at 25,149,296; static memory
ranges from 42,167,379 to 43,446,235 bytes. Sampled FPS ranges from 55 to 60.
The observed memory oscillates rather than rising monotonically. These samples
support bounded resources for this workload and duration; they do not prove
absence of all leaks or establish a longer soak result. The profile predates
the newly deployed defined? compiler host.

The isolated Windows export in
`.omo/evidence/windows-clean-install-explicit-exit/` starts from an empty
working directory with PATH restricted to Windows system directories and
RGSS_FFMPEG_PATH/MRUBY_DIR removed. Its log records CONFIG, SCRIPTS_LOADED and
MAIN_LOADED, with RMProject and RTP inside that owned installation. Independent
title inspection passed six checks. The bundled decoder produced a mono
22,050 Hz, 16-bit WAV containing 10,240 frames from the production WMA fixture.
This is local exported-runtime and decoder evidence. Installed system software
and fonts remain present, so the result is not a clean-machine verdict.

The preparation script writes an absolute RTP path. Moving the installation
directory is therefore not covered by this result. Exporting the latest native
host and extension set also remains separate from this older package evidence.
No prior fixture or measurement is overwritten to claim either result.
