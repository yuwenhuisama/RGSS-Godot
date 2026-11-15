# WMA decoder distribution route

Current2026-11-15: the macOS arm64 leg now passes native LGPL build, all five
decoder checks, exact20558-byte WAV hash, actual exported bundled cache and
ten-file native/decoder/source/license byte audit. Measured files are installed
inPlugins/macos. Actual Release output to the built-in speaker process stream
has440Hz WMA signal and exact silence after stop; software MIDI C4 also plays
and stops. The40-second CoreAudio capture and normal game both exit0.
See macos-verification.md and .omo/evidence/macos-audio-signal/complete-measurement.md.
B09 and all three measured platform decoder packages are accepted within this
scope. Intel Mac execution and signing/notarization are not established.

## Current guest and notice audit (2026-11-14)

Final combined packages now have a complete native/audio payload audit:
33files across Windows/Linux match production byte-for-byte, including every
native library, decoder, corresponding source archive, license/notice/build
file and MIDI bank/source/license. The packages are
windows-midi-file-io-release-settled and linux-file-io-nine-release; individual
sizes and SHA256 values are in
`.omo/evidence/final-audio-native-package-audit.json`.
The Linux final package passes offline WMA decode. After the user restored the
Windows guest on 2026-11-15, the combined snapshot also passes its fresh-cache
follow-up: actual game exit 0, WINDOWS_COMBINED_WMA_PASS and MAIN_LOADED:OK,
system-only PATH, empty working directory and fresh APPDATA. Its 20,558-byte
decoded WAV matches the independent reference SHA256
58799fa81bf05ee654ba7e2d20ca9fc27391cd71cea79a820a24e7c1392fdc55.
Receipt and raw logs are in `.omo/evidence/windows-combined-wma-diagnostic`.
The initial collection failed on forward-slash VIX guest paths; collecting
with native Windows paths recovered all four files without replaying the game.
The earlier suspended attempt remains unverified. This Dummy-audio decode
owner does not establish real output or post-stop silence; earlier Windows
actual WMA signal evidence below keeps its own snapshot scope.

Latest current-source Linux audio-fix Release repeats actual decode/cache and
offline runtime-only relocation at exit0; its five audio payload files remain
byte-identical to production. Evidence `.omo/evidence/linux-current-audio-release`.
Current Windows audio-fix Release exports at exit0 and its measured decoder/
LICENSE/NOTICE/BUILD match production; this snapshot now passes restricted-path
clean-guest startup at actual game/harness exit0. A separate copy of the same
package also produces real WMA output through the guest WASAPI mixer with
system-only PATH and no external-decoder override. Existing tone.wma is added
as controlled media and only its Ruby test entry is replaced; the export's
managed/native/decoder payload is unchanged. Game and recorder exit0; stderr
is empty. Recorded steady RMS0.08538 and440Hz amplitude0.06635 distinguish the
test signal from silence/system tones. The9-second recorder began before the
cold game startup and ends during playback, so it does not prove post-stop
silence; that remains covered only by the earlier channel lifecycle owners.
Raw recording, callback clock, receipt and logs:
`.omo/evidence/b09-windows-package-wma-signal`.

Actual Windows export content is also checked, rather than inferred from the
project copy rules. In the existing `windows-relocated-install/install`
package, `data_RGSS-Godot_windows_x86_64/Plugins/windows/audio` contains the
decoder executable, matching source tarball, LICENSE.txt, NOTICE.txt and
BUILD.txt. All five are byte-identical to their production-directory inputs.
Their sizes are respectively 2,322,958 / 11,732,036 / 26,517 / 208 / 781 bytes.
This closes source/notice inclusion for that actual exported package; the
macOS export and future regenerated package contents remain unmeasured.

The existing Linux Release export's
`install/data_RGSS-Godot_linuxbsd_x86_64/Plugins/linux/audio` likewise contains
all five corresponding files, each byte-identical to Plugins/linux/audio.
Sizes are 2,238,816 / 11,732,036 / 26,517 / 208 / 715 bytes in the same order.
This verifies the actual Linux export's decoder/source/license/notice/build
inclusion without rebuilding or rerunning the settled runtime checks.

Windows decoder installation now validates the candidate before overwriting
the shipped executable. A real isolated regression using the preserved prior
GPL binary reproduced the old failure: exit 0 and replacement of the verified
LGPL binary. The corrected script rejects that same candidate at exit 1 and
preserves the installed bytes, then accepts the measured LGPL candidate with
all five WMA decoders. The combined check exits 0 with
DECODER_INSTALL_LICENSE_PASS. Reproduction script:
`D:/VMs/check-decoder-install.ps1`; isolated red/green installations:
`D:/VMs/decoder-install-red` and `D:/VMs/decoder-install-green`.
No production binary was replaced by the regression check. PowerShell LSP
is unavailable; actual PowerShell parsing and both executable branches ran.

The installed Ubuntu guest now supplies the earlier missing rendered/audio
evidence: exported WMA decode matches reference PCM and a guest-only PipeWire
sink captures the real output signal. The installed Windows guest runs the
existing relocated package at exit 0 with EXPORTED_TITLE_WMA_PASS; its title
capture passes independent visual inspection. Windows real-device WMA signal
is now measured in the separate current package copy above. See clean-install-verification.md and the VMware
entries in `.omo/notepads/rmva-compatibility-ultrawork.md` for scope and paths.

Both production audio directories contain the FFmpeg attribution and the exact
IJG credit sentence in NOTICE.txt. Their identical 208-byte notices have SHA256
88a9c827f147159ea9d3ffe0605eb5c6280921f3f2f941406f736a5b5e324410.
Both include the pristine 11,732,036-byte source archive with SHA256
7138d28c96d9d3e3af4ee3d8cad72741f8ffb40da90c1112235dea3ecd3178a3,
the 26,517-byte LGPL LICENSE.txt and platform-specific BUILD.txt.
Current binary SHA256 values are Windows
956c8fabab53982e2562fcbb683afe37a21c757f6304f8127158a8616fd4df12
and Linux b517ac10d4b15e2731bcdb0ab6c9eadc06a0f64aa5db10cd62c62de6a275844a.
Thus missing bundled IJG credit is no longer an open item for these two
directories. Inclusion in any future game-specific credits/EULA and macOS
build/runtime verification remain distinct requirements.

## Earlier deployment and build records

The verified Linux decoder, corresponding source, LICENSE, NOTICE and BUILD
files are now deployed to the standard Plugins/linux/audio directory; all five
files match their measured evidence copies by SHA256. The export recipe reads
that production path instead of reaching into evidence. A direct production-
path offline decoder run passes LINUX_CLEAN_DECODER_EXIT:0. Its20,558-byte WAV
matches the reference exactly, SHA256
58799fa81bf05ee654ba7e2d20ca9fc27391cd71cea79a820a24e7c1392fdc55.
The first deployment stopped because this
PowerShell lacks Get-FileHash; the resumed script uses .NET SHA256 and refuses
to overwrite differing existing files. No Linux decoder rebuild was required.

Linux actual-host format/path owner also passes AUDIO_FORMATS_PASS and
LINUX_AUDIO_FORMATS_NO_SKIP_PASS, exit 0. Real RTP is mounted read-only and an
isolated project directory provides the missing-project-file precondition.
This covers encoded WAV/OGG/MP3/WMA loading, extension resolution, project-first
exact matching and actual RTP fallback without skips. Log:
`.omo/evidence/f10-linux-godot-base-suite/linux-audio-formats.log`.
The Linux SE mixer owner also passes simultaneous440/660Hz, RTP effect PCM,
stop, finite ending and manager reinitialization, exit0. Loop/fade and full ME
owners pass separately; these are mixer evidence, not original signal parity.

Status: Windows minimal LGPL decoder was built and deployed on 2026-11-13.
Its production-argument decode and fresh-source runtime loading passed, with
source, license, build flags and notices included. See
`audio-decoder-local-build.md`. Linux source build, production decode and an
offline fresh-container decoder run also pass. Linux Godot Debug and Release
exports and offline relocated headless package verification pass. The current
Release evidence is in `.omo/evidence/f10-linux-release-export`, with
LINUX_RELEASE_CLEAN_EXIT:0 and byte-exact WMA cache comparison. Linux graphical/audible
output and macOS build/runtime remain open; the three-platform workflow has not run.

## Why this route

- FFmpeg publishes source only, no binaries for any platform
  (https://ffmpeg.org/download.html).
- The WMA decoders are LGPL-2.1-or-later in upstream source: `libavcodec/wmadec.c`,
  `wmaprodec.c`, `wmavoice.c` and `wma.c` were read and carry the LGPL v2.1-or-later
  header. The downloaded `wmalosslessdec.c` also confirms LGPL v2.1-or-later.
  `configure` reports `LGPL version 2.1 or later` when
  neither `--enable-gpl`, `--enable-version3` nor `--enable-nonfree` is used.
- A `--disable-everything` build with only WMA decode, ASF/WAV demux, WAV mux,
  PCM s16le encode and the CLI's audio filters links **no external libraries**.
  There is no third-party source set to collect, unlike the gyan essentials
  build.
- `--disable-everything` unsets the per-component enable variables for
  decoders, encoders, filters, demuxers, muxers, protocols, bsfs, parsers,
  hwaccels, indevs and outdevs. The name lists survive, so
  `--enable-decoder=...` still resolves; libraries and programs stay enabled.
  `aresample` pulls in `swresample` via `aresample_filter_deps="swresample"`.

## Source

- `https://ffmpeg.org/releases/ffmpeg-8.1.3.tar.xz` (11,732,036 bytes)
- `https://ffmpeg.org/releases/ffmpeg-8.1.3.tar.xz.asc` (520 bytes)
- Release key `FCF986EA15E6E293A5644F10B4322F04D67658D8` from
  `https://ffmpeg.org/ffmpeg-devel.asc`
- Verify: `gpg --verify ffmpeg-8.1.3.tar.xz.asc ffmpeg-8.1.3.tar.xz`
- Downloaded and unpacked locally; measured SHA256:
  `7138d28c96d9d3e3af4ee3d8cad72741f8ffb40da90c1112235dea3ecd3178a3`.
  Detached signature verified on 2026-11-13 using Git's bundled GnuPG 2.4.7,
  an isolated homedir and the key fetched from the official URL above:
  exit 0, GOODSIG B4322F04D67658D8 and VALIDSIG matching the full fingerprint.
  The key has no local owner-trust certification; its provenance is the official
  HTTPS download. Import returned 2 after importing the key because gpg-agent
  could not start; public verification used --no-autostart and passed.
- ffmpeg.org publishes no `.sha256`/`.md5` files (both 404); the detached
  signature is the only upstream integrity artifact. Pin one exact release.

## Build (once per platform, from the unpacked tarball)

```sh
./configure --prefix=/opt/ffmpeg-wma \
  --disable-everything --disable-autodetect --disable-network --disable-doc \
  --disable-ffplay --disable-ffprobe --disable-avdevice --disable-swscale \
  --disable-debug --disable-iconv \
  --enable-ffmpeg \
  --enable-decoder=wmav1,wmav2,wmapro,wmalossless,wmavoice \
  --enable-demuxer=asf,wav --enable-muxer=wav \
  --enable-encoder=pcm_s16le --enable-protocol=file \
  --enable-filter=aresample,aformat,anull,atrim
make -j"$(nproc)"
make install
```

- `aresample` is required: the CLI auto-inserts it to convert WMA `fltp` to
  `pcm_s16le` (`libavfilter/formats.c` audio converter, inserted by
  `avfiltergraph.c`).
- `aformat`, `anull`, `atrim` are in `ffmpeg_select`. Because
  `--disable-everything` unsets rather than sets `no`, configure's
  `enable_deep_weak` auto-enables them anyway; listing them explicitly only
  documents the dependency.
- `--disable-ffplay/--disable-ffprobe/--disable-swscale` are valid options:
  programs and libraries are reachable through `CMDLINE_SELECT` via
  `$CONFIG_LIST`. `ffmpeg_deps` excludes swscale and its remaining uses are
  `#if CONFIG_SWSCALE`-guarded.
- `--disable-x86asm` may be added when nasm is unavailable (speed cost only).
- Hosts: Windows MSYS2 MINGW64, macOS Xcode Command Line Tools, Linux gcc.
  Record compiler and version in `BUILD.txt`.

## Release bundle, per platform

```text
Plugins/<platform>/audio/ffmpeg[.exe]
Plugins/<platform>/audio/LICENSE.txt          # COPYING.LGPLv2.1, verbatim
Plugins/<platform>/audio/BUILD.txt            # exact configure line + toolchain
Plugins/<platform>/audio/ffmpeg-8.1.3.tar.xz  # pristine upstream tarball
```

Shipping the unmodified tarball beside the binary satisfies the FFmpeg LGPL
checklist for source distribution, exact correspondence and build instructions
without a separate download server. Add the FFmpeg attribution sentence to the
game's about/credits and EULA.

IJG obligation is real even in this minimal build: `libavcodec/Makefile` links
`jfdctfst.o jfdctint.o` under `CONFIG_FDCTDSP` and `jrevdct.o` under
`CONFIG_IDCTDSP`. `--disable-everything` does not touch `faan`, and configure
defaults to `enable faan faandct faanidct`, whose `_select` pulls in `fdctdsp`
and `idctdsp`. `LICENSE.md` requires crediting the IJG in documentation when
distributing executables only, plus noting any changes to those three files.

## Verification per platform

1. `ffmpeg -L` prints the GNU Lesser General Public License banner containing
   `version 2.1 of the License` and not `version 3` (the `#else` branch of
   `show_license` in `fftools/opt_common.c`; the GPL, LGPLv3 and nonfree
   branches print different text). `tools/prepare_audio_decoder.ps1` checks
   this text and all five required decoders before copying the candidate.
2. `ffmpeg -decoders` lists `wmav1`, `wmav2`, `wmapro`, `wmalossless`,
   `wmavoice`.
3. Decode a fixture with the production arguments
   (`-hide_banner -loglevel error -y -i in.wma -vn -acodec pcm_s16le out.wav`)
   and compare duration/sample rate/channels against the original runtime.

## Rejected fallback

BtbN `FFmpeg-Builds` publishes static/shared artifacts for win64, winarm64,
linux64 and linuxarm64 only - **no macOS** - and its `lgpl` variant passes
`--enable-version3`, i.e. it is LGPLv3, not LGPLv2.1. It also bundles many
external libraries, recreating the source-collection burden. Usable at most as
a Windows/Linux stopgap, never as the macOS answer.

## Exact remaining gaps

Linux local execution started on 2026-11-14 after the existing Docker Desktop
engine became available. An owned disposable Ubuntu24.04 container installs
build tools, verifies the previously signature-verified source SHA256, runs
the production minimal build script and decodes the production WMA fixture.
The repository is mounted read-only; only the owned Linux evidence directory
is writable. Build and production decode now pass at exit0 with
AUDIO_DECODER_BUILD_PASS:linux and LINUX_PRODUCTION_DECODE_PASS. Actual decoded
WAV is PCM16 mono22,050Hz with20,480 data bytes (10,240 frames), matching the
Windows format and duration measurement. BUILD.txt records Ubuntu GCC13.3.0;
ldd lists only glibc, libm and the dynamic loader. Source, LGPL text, IJG/FFmpeg
notices, configure and build logs are in `.omo/evidence/audio-decoder/linux/`.
Fresh offline base-image runtime verification completes
LINUX_CLEAN_DECODER_EXIT:0 without installing any compiler or decoder
dependency. Its20,558-byte WAV is byte-exact with the build-container output.
This container run cannot establish macOS execution or a full Linux Godot export.

The Linux exported Ruby Audio.bgm_play entry now passes with a new source file
and empty user cache, with its failure callback unset. The generated cache WAV
is byte-exact with the independent reference, exit 0. Godot's .NET content export
had changed the decoder from mode 0755 to 0644; the Linux package assembly step
now restores its executable mode. This proves discovery/conversion/loading,
not audible output. A plain Ubuntu container separately fails on missing
fontconfig and .NET ICU. A runtime-only image with those prerequisites now
passes offline execution with a read-only installation and fresh user cache:
LINUX_CLEAN_EXPORTED_WMA_PASS, exit 0. No SDK, compiler or system decoder is
available; the cache WAV again matches the independent reference exactly.

Execution entries: `tools/build_audio_decoder.sh` and
`.github/workflows/audio-decoder.yml`. The workflow verifies the upstream
signature, builds each platform, checks license/decoders, decodes the production
fixture and uploads binary plus matching source and notices. It is not execution
evidence until the workflow actually runs. A portable GCC toolchain was used
for the verified local Windows build; the old GPL candidate is retained only
in owned evidence outside the production bundle.

1. Windows configure/build, decoder list, LGPL banner and fresh-source runtime
   loading passed. The local Windows release export also executed successfully
   and its actual Ruby audio entry returned EXPORTED_WMA_PASS.
2. No reputable minimal-LGPL macOS binary exists; macOS must be built on a
   macOS host.
3. Linux decoder-only build/decode, Godot debug export and offline runtime-only
   container execution pass. Linux graphical/audible playback and macOS
   decode/export verification remain pending.
   Windows local export boot and fresh-source WMA loading passed; clean
   installation remains separate.
4. FFmpeg/IJG credit text is included in the decoder bundle's NOTICE.txt.
   Integrating credits into a consuming game's interface remains its packaging
   responsibility; no external game was modified.
5. The Windows bundle now contains the LGPL binary and corresponding source.
   Linux has separate headless export evidence above; macOS and graphical
   release package parity remain unverified.
