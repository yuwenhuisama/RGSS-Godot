#!/usr/bin/env bash
set -euo pipefail
tar -C /output/install -cf /output/linux-headless-verified.tar .
sha256sum /output/linux-headless-verified.tar | tee /output/linux-headless-verified.sha256
