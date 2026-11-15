# Windows WMA decoder

Built locally from the included pristine `ffmpeg-8.1.3.tar.xz` on 2026-11-13.
Source SHA256: `7138d28c96d9d3e3af4ee3d8cad72741f8ffb40da90c1112235dea3ecd3178a3`.
Executable SHA256: `956c8fabab53982e2562fcbb683afe37a21c757f6304f8127158a8616fd4df12`.
License: LGPL version 2.1 or later; see LICENSE.txt and NOTICE.txt.
BUILD.txt records configure flags and GCC 16.2.0. Linked decoder dependencies
are Windows system libraries only. The corresponding FFmpeg source and
FFmpeg/IJG attribution are included beside the executable.

The prior GPL candidate is preserved in owned evidence outside this bundle.
Local build, license, decoder list and production-argument decode passed;
packaged runtime loading and platform export checks remain separate gates.

Production loader finds it at `Plugins/windows/audio/ffmpeg.exe` without an
environment variable. Explicit `RGSS_FFMPEG_PATH` takes precedence.
