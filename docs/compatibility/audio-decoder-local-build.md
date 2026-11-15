# WMA decoder local build (Windows workstation)

Historical Windows build report. Subsequent 2026-11-14 Linux source build,
Godot export/WMA load and offline relocated headless runtime evidence are in
audio-decoder-distribution.md and linux-current-host-verification.md. The
Windows-only limits in the original run notes below describe that earlier run.

Status: executed and verified on 2026-11-13 on this Windows workstation. The
minimal LGPL route in `audio-decoder-distribution.md` is build-verified for
Windows only; macOS and Linux remain unexecuted. The lead has deployed the
verified binary with its pristine source, license, build flags and notices into
`Plugins/windows/audio/`, preserving the prior GPL binary in owned evidence.
Managed-copy build and fresh-source runtime loading passed (exit 0,
`AUDIO_FORMATS_PASS`). The runtime test copies a fresh owned WMA source and
removes only its own cache before invoking the bundled decoder, avoiding an
old-cache false pass. Platform export checks remain open.

Evidence bundle: `.omo/evidence/audio-decoder/windows/` (binary, notices,
license banner, decoder list, configure/make logs, decode outputs, measurements).

## Host

| Item | Value |
|------|-------|
| OS | Windows 11, kernel 10.0.26300, x64 |
| Shell | Git for Windows Bash, `uname -s` = `MINGW64_NT-10.0-26300` |
| Compiler | portable winlibs GCC 16.2.0 (no system install) |
| make | MSYS2 `make` 4.4.1 package binary, unpacked beside the compiler |
| NASM | 2.16.03 (portable zip) |
| Docker | Docker Desktop installed; Linux engine not running, `docker-desktop` WSL distro stopped |
| Absent | system MSYS2/MinGW, clang, `make`, `gcc`; `C:\Program Files\Microsoft Visual Studio\2022` is empty |

A native Windows build was chosen over the Docker route because the Docker
daemon was down and the only registered WSL distro was stopped, while the
Windows target is the platform whose bundled decoder actually ships today.
A Linux container build would not have produced Windows evidence.

## Toolchain provisioning (reversible, no global install)

Everything lives under `.omo/compatibility-run-tmp/audio-decoder-toolchain/`
and can be deleted without affecting the machine.

| Component | Artifact | SHA256 |
|-----------|----------|--------|
| GCC 16.2.0 + binutils 2.47 | `winlibs-x86_64-posix-seh-gcc-16.2.0-llvm-23.1.3-mingw-w64ucrt-14.0.0-r3.zip` from https://github.com/brechtsanders/winlibs_mingw/releases | `1f04e482797dc5f71fe2875cf2b743bfb9f5fd1de0955fdd3118438c0432ba5f` (matches the release's published `.zip.sha256`) |
| GNU Make 4.4.1 | `make-4.4.1-2-x86_64.pkg.tar.zst` from https://repo.msys2.org/msys/x86_64/ | `2408af61717dae87b00c855b132769a125c708907fc94a46bb16dae076113e5c` |
| NASM 2.16.03 | `nasm-2.16.03-win64.zip` from https://www.nasm.us/pub/nasm/releasebuilds/2.16.03/win64/ | not pinned |

`gcc -dumpmachine` reports `x86_64-w64-mingw32`; the build uses the UCRT
runtime, so the binary needs only OS-provided `api-ms-win-crt-*` plus
`KERNEL32`, `SHELL32` and `bcrypt`.

## Source and license provenance

- Archive: `ffmpeg-8.1.3.tar.xz`, 11,732,036 bytes, from
  `https://ffmpeg.org/releases/ffmpeg-8.1.3.tar.xz`.
- SHA256 `7138d28c96d9d3e3af4ee3d8cad72741f8ffb40da90c1112235dea3ecd3178a3`,
  recomputed independently with `sha256sum` and `certutil` during this build.
- Detached signature re-verified in this run: Git's bundled GnuPG 2.4.7,
  isolated `GNUPGHOME`, `--no-autostart`, exit 0,
  `GOODSIG B4322F04D67658D8`,
  `VALIDSIG FCF986EA15E6E293A5644F10B4322F04D67658D8`,
  `TRUST_UNDEFINED` (no local owner-trust certification; provenance is the
  official HTTPS download). Transcript: `signature-verify.txt` beside the source.
- Decoder license: LGPL v2.1 or later, confirmed by reading the headers of
  `libavcodec/wmadec.c`, `wmaprodec.c`, `wmavoice.c`, `wma.c` and
  `wmalosslessdec.c` in this tarball, and by the build's own banner
  (`License: LGPL version 2.1 or later`, `configure.log`).
- IJG obligation is real in this build: `jfdctfst.o`, `jfdctint.o` and
  `jrevdct.o` are present in the linked `libavcodec.a` because `faan`/`faandct`/
  `faanidct` default on and select `fdctdsp`/`idctdsp`.

## Build

Executed with the shared script so the reviewed flag set is what actually ran:

```sh
bash tools/build_audio_decoder.sh \
  .omo/compatibility-run-tmp/audio-decoder-source/ffmpeg-8.1.3.tar.xz \
  windows \
  .omo/evidence/audio-decoder/windows
```

Configure succeeded on the first attempt with no missing components. Selected
configure output (`configure.log`):

```text
C compiler                gcc
C library                 mingw64
ARCH                      x86 (generic)
standalone assembly       no
x86 assembler             nasm
static                    yes
shared                    no
threading support         w32threads

Libraries:
avcodec  avformat  swresample
avfilter avutil

Programs:
ffmpeg

Enabled decoders:
pcm_s16le  wmapro  wmav2
wmalossless wmav1  wmavoice

Enabled demuxers: asf wav
Enabled muxers:  wav
Enabled protocols: file
License: LGPL version 2.1 or later
```

`make -j16` completed. One linker warning is expected and benign:

```text
ld.exe: .rsrc merge failure: multiple non-default manifests
```

GCC injects its own default manifest (`longPathAware`, `asInvoker`) and FFmpeg
adds `fftools/fftools.manifest` (DPI awareness). Both survive in `.rsrc`; the
FFmpeg manifest is the first resource leaf, so DPI awareness is retained. The
binary runs normally, including with a stripped environment.

Artifact: `ffmpeg.exe`, 2,322,958 bytes,
SHA256 `956c8fabab53982e2562fcbb683afe37a21c757f6304f8127158a8616fd4df12`.

## Script changes made by this build

Two defects in `tools/build_audio_decoder.sh` were found by actually running it
and are fixed there; both are proven necessary by a control build
(`.omo/compatibility-run-tmp/audio-decoder-control/`):

1. `--enable-decoder=pcm_s16le` was missing. The workflow's second step
   re-opens the decoded WAV, which needs the PCM decoder. Control build without
   it: `Decoding requested, but no decoder found for: pcm_s16le`,
   `REDECODE_EXIT=127`.
2. `--extra-ldflags=-static` was missing for Windows. Control build without it
   imports `libwinpthread-1.dll`; the shipped build does not.

Also fixed: `BUILD.txt` used bare `cc`, which does not exist on this host and
would abort the script under `set -e`; it now falls back to `gcc`. Configure and
make output are now teed to `configure.log`/`make.log` in the output directory
so a failed CI run is diagnosable.

## Verification

`-L` banner (`license-banner.txt`): contains `version 2.1 of the License`,
does not contain `version 3 of the License`.

`-decoders` contains exactly the intended audio decoders:

```text
 A....D pcm_s16le            PCM signed 16-bit little-endian
 A....D wmalossless          Windows Media Audio Lossless
 A....D wmapro               Windows Media Audio 9 Professional
 A....D wmav1                Windows Media Audio 1
 A....D wmav2                Windows Media Audio 2
 A....D wmavoice             Windows Media Audio Voice
```

Production decode, using the exact arguments from `GameAudioManager.ConvertWma`
and the CI workflow:

```sh
ffmpeg.exe -hide_banner -loglevel error -y -i tests/fixtures/audio/tone.wma \
  -vn -acodec pcm_s16le decoded.wav
```

- Input fixture: `tone.wma`, 3,744 bytes,
  SHA256 `cd44ca14143d4524afba4cfc6675a71ccbcd1c888b8068219da831b05c911da0`,
  ASF/WMAv2, 22050 Hz mono, 32 kb/s, 0.51 s container duration.
- Output: 20,558-byte WAV, 22050 Hz mono s16, 10,240 frames,
  0.4644 s, 20,480 PCM bytes.
- PCM SHA256 `d9ff990a5ba2603383ecec00b3c061aba00e93d3a343ee255faf06fdda5fd03e`.
- Re-decode of that WAV reproduces the identical PCM payload (round-trip
  equality), so the workflow's second step passes.
- Wall time for the decode: 0.036 s real, ~142-149x realtime.
- Determinism: three repeated decodes and `-cpuflags 0` / `-threads 1` runs all
  produce the same PCM hash.

### Difference against the old GPL binary

The existing gyan 2022-10-30 GPLv3 candidate decodes the same fixture to
10,240 frames at the same rate/channels, PCM SHA256
`ffd0c4fb7865aa2e6d1da6dff1e9362519de01cc225b533a83c474bbf99bada4`.
Sample-by-sample comparison: 10,239 of 10,240 samples are identical, one sample
differs by 1 LSB (index 129, 201 vs 202). The old 5.x build reproduces the new
binary's exact PCM hash `d9ff990a...` when run with `-cpuflags 0`, so the delta
is SIMD rounding in the older build's optimized path, not a flag or build defect
in this one. The 8.1.3 build is bit-stable across `-cpuflags 0` and
`-threads 1`. The difference is one LSB on one sample: inaudible and outside the
format contract (rate, channels, duration all match).

## Historical remaining gaps at the first Windows build

The list below preserves the first-build state. Current results supersede
items2,4and the bundle part of5: Windows/Linux LGPL decoders are deployed,
source/licenses/FFmpeg/IJG notices are included, both platforms have actual
guest signal, and Linux offline Release decoding is byte-exact. See
audio-decoder-distribution.md. macOS execution, workflow execution and any
future game-specific credits remain separate unverified requirements.

1. macOS is unbuilt and unverified; it needs a macOS host (no reputable minimal
   LGPL binary exists).
2. Linux is unbuilt and unverified. Docker Desktop's Linux engine was not
   running and the `docker-desktop` WSL distro was stopped; a container build
   would also not be Windows evidence.
3. The workflow itself (`.github/workflows/audio-decoder.yml`) has still never
   run. This document is local workstation evidence, not CI evidence.
4. `Plugins/windows/audio/ffmpeg.exe` still holds the GPLv3 gyan candidate; the
   LGPL build has not been promoted into the bundle, and no archive/evidence was
   modified.
5. IJG credit text is still absent from the game's credits/EULA.
6. The NASM download is not hash-pinned in this record (it only affects
   assembly speed, not licensing or decode output).
