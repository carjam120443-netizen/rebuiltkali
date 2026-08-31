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

# Ubuntu's live-build is too old for current Kali build scripts. Kali's current
# package pool exposes the version needed by the build scripts. Resolve the
# current .deb from the official package index instead of hard-coding a version.
LIVE_BUILD_URL="$(python3 - <<'PY'
import re
import urllib.request

index = urllib.request.urlopen(
    "https://http.kali.org/kali/pool/main/l/live-build/",
    timeout=30,
).read().decode("utf-8", "replace")

matches = re.findall(r'href="(live-build_[^"]+_all\.deb)"', index)
if not matches:
    raise SystemExit("Could not find a Kali live-build package in the package pool.")

# Prefer the current Kali package whose filename contains a Kali revision.
kali = [m for m in matches if "+kali" in m]
if not kali:
    raise SystemExit("Could not find a Kali live-build package with a Kali revision.")

# The package index is ordered newest-first on the current mirror; use the
# first matching package rather than assuming a particular date/revision.
print("https://http.kali.org/kali/pool/main/l/live-build/" + kali[0])
PY
)"

LIVE_BUILD_DEB="/tmp/live-build.deb"
echo "Downloading: $LIVE_BUILD_URL"
curl -fL --retry 3 --retry-delay 2 "$LIVE_BUILD_URL" -o "$LIVE_BUILD_DEB"
sudo apt install -y "$LIVE_BUILD_DEB"
sudo apt install -y git cdebootstrap curl xorriso squashfs-tools python3

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
