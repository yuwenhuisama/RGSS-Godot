# Installed VMware test environments

Both guests boot from installed disks under `D:/VMs/`. The environment setup
task is accepted for Tools, graphics and bounded audio/rendered tests. This is
not blanket acceptance of Windows/Linux compatibility or macOS support.

Windows 11 Pro x64 verification records a 100 GiB GPT disk, running VMTools
(service state 4), TPM present/ready, Secure Boot and VMware SVGA 3D driver
9.17.11.4. The actual windowed message owner renders through SVGA3D/OpenGL 4.3
and reports D05_MESSAGE_PASS. Its four stock message captures separately pass
the exact pixel and independent visual checks in message-window-verification.
The installed Release's private WASAPI capture and game both exit zero; actual
440 Hz WMA signal is documented in audio-decoder-distribution.md.

Ubuntu 24.04.5 is installed on ext4 with Tools 13.0.10, Xorg, SVGA3D and guest
PipeWire. Selecting the VMware host DX12 renderer resolves the earlier Vulkan
stall. The real stock-map minute exits zero at measured cumulative averages
58.45-59.36 FPS; independent inspection confirms the actual map without missing
textures or error overlays. Guest-only WMA and MIDI captures contain the known
test signals. The denser 36,000-frame owner measures 24-29 FPS, so the minute
result is not a dense-map performance claim.

Core raw receipts are archived in `.omo/evidence/guest-environment-acceptance`.
The Linux long-run archive and independent visual findings are in
`.omo/evidence/f11-linux-vmware-dx12-xorg`; the Windows actual WMA capture is
in `.omo/evidence/b09-windows-package-wma-signal`. Dedicated fullscreen tests
remain separate, with watermark and alternate-refresh limitations preserved.
