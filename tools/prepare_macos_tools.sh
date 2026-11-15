#!/usr/bin/env bash
set -euo pipefail
cd "$HOME/RGSS-Godot-Verification"
mkdir -p downloads dotnet godot
curl -fL https://builds.dotnet.microsoft.com/dotnet/Sdk/8.0.428/dotnet-sdk-8.0.428-osx-arm64.tar.gz -o downloads/dotnet-sdk.tar.gz
printf '%s  %s\n' c2930ce6363417165142e5610992df1430b1cf93f4b5ac31027da611a6bc089a73e7062eed0200be3e4a32db893a92c86fc27816a53521e5b041aafba0aa1215 downloads/dotnet-sdk.tar.gz | shasum -a 512 -c -
tar -xf downloads/dotnet-sdk.tar.gz -C dotnet
curl -fL https://github.com/godotengine/godot-builds/releases/download/4.6.1-stable/Godot_v4.6.1-stable_mono_macos.universal.zip -o downloads/Godot_v4.6.1-stable_mono_macos.universal.zip
curl -fL https://github.com/godotengine/godot-builds/releases/download/4.6.1-stable/SHA512-SUMS.txt -o downloads/SHA512-SUMS.txt
checksum=$(grep 'Godot_v4.6.1-stable_mono_macos.universal.zip$' downloads/SHA512-SUMS.txt)
test -n "$checksum"
(cd downloads; printf '%s\n' "$checksum" | shasum -a 512 -c -)
unzip -q downloads/Godot_v4.6.1-stable_mono_macos.universal.zip -d godot
dotnet/dotnet --info
godot/Godot_mono.app/Contents/MacOS/Godot --version
printf 'MACOS_TOOLS_READY\n'
