#!/usr/bin/env bash
set -euo pipefail

# RebuiltKali ISO builder
# Uses Kali's official kali-live build scripts as the upstream framework.

REPO_URL="https://gitlab.com/kalilinux/build-scripts/kali-live.git"
UPSTREAM_DIR=".upstream/kali-live"

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Do not run this script as root. Run it from a normal user account with sudo access."
  exit 1
fi

command -v git >/dev/null || { echo "Missing dependency: git"; exit 1; }
command -v sudo >/dev/null || { echo "Missing dependency: sudo"; exit 1; }

sudo apt update

# Ubuntu's live-build is too old for current Kali build scripts. Install Kali's
# current live-build package directly from the official Kali package pool.
LIVE_BUILD_DEB="/tmp/live-build_1:20250814+kali3_all.deb"
curl -fsSL "https://http.kali.org/kali/pool/main/l/live-build/live-build_1%3A20250814%2Bkali3_all.deb" -o "$LIVE_BUILD_DEB"
sudo apt install -y "$LIVE_BUILD_DEB"
sudo apt install -y git cdebootstrap curl xorriso squashfs-tools

live-build --version

mkdir -p .upstream
if [[ ! -d "$UPSTREAM_DIR/.git" ]]; then
  git clone "$REPO_URL" "$UPSTREAM_DIR"
else
  git -C "$UPSTREAM_DIR" pull --ff-only
fi

# Copy our customization layer into the upstream build tree.
mkdir -p "$UPSTREAM_DIR/kali-config/common/includes.chroot/etc"
mkdir -p "$UPSTREAM_DIR/kali-config/common/hooks"
mkdir -p "$UPSTREAM_DIR/kali-config/variant-xfce/package-lists"

cp -f config/etc/os-release "$UPSTREAM_DIR/kali-config/common/includes.chroot/etc/os-release"
cp -f config/hooks/01-rebuiltkali.chroot "$UPSTREAM_DIR/kali-config/common/hooks/01-rebuiltkali.chroot"
cp -f config/package-lists/rebuiltkali.list.chroot "$UPSTREAM_DIR/kali-config/variant-xfce/package-lists/rebuiltkali.list.chroot"
chmod +x "$UPSTREAM_DIR/kali-config/common/hooks/01-rebuiltkali.chroot"

cd "$UPSTREAM_DIR"
./build.sh --variant xfce --arch amd64 --verbose
