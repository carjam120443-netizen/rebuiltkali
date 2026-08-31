#!/usr/bin/env bash
set -euo pipefail

# RebuiltKali ISO builder
# Uses Kali's official kali-live build scripts as the upstream framework.

REPO_URL="https://gitlab.com/kalilinux/build-scripts/kali-live.git"
UPSTREAM_DIR=".upstream/kali-live"
KALI_POOL="https://http.kali.org/kali/pool/main/l/live-build/"
KALI_KEYRING_POOL="https://http.kali.org/kali/pool/main/k/kali-archive-keyring/"

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Do not run this script as root. Run it from a normal user account with sudo access."
  exit 1
fi

command -v git >/dev/null || { echo "Missing dependency: git"; exit 1; }
command -v sudo >/dev/null || { echo "Missing dependency: sudo"; exit 1; }
command -v curl >/dev/null || { echo "Missing dependency: curl"; exit 1; }

sudo apt update
sudo apt install -y git curl cdebootstrap xorriso squashfs-tools

# Ubuntu's live-build is too old for current Kali build scripts. Discover the
# current Kali live-build package from Kali's official package index instead
# of hard-coding a versioned filename.
INDEX=$(curl -fsSL --retry 5 --retry-delay 2 "$KALI_POOL")
LIVE_BUILD_FILE=$(printf '%s\n' "$INDEX" | grep -oE 'live-build_[^" <]+_all\.deb' | grep -E '\+kali[0-9]+_all\.deb$' | sort -V | tail -n1 || true)

if [[ -z "$LIVE_BUILD_FILE" ]]; then
  echo "Could not find a Kali live-build package with a Kali revision."
  echo "Kali package index: $KALI_POOL"
  exit 1
fi

echo "Using Kali live-build package: $LIVE_BUILD_FILE"
curl -fsSL --retry 5 --retry-delay 2 "${KALI_POOL}${LIVE_BUILD_FILE}" -o "/tmp/$LIVE_BUILD_FILE"
sudo dpkg -i "/tmp/$LIVE_BUILD_FILE" || sudo apt-get install -f -y

# The Kali live-build configuration explicitly asks debootstrap to use
# /usr/share/keyrings/kali-archive-keyring.gpg. Ubuntu runners do not ship
# that Kali keyring, so install the current official keyring before building.
KEYRING_INDEX=$(curl -fsSL --retry 5 --retry-delay 2 "$KALI_KEYRING_POOL")
KEYRING_FILE=$(printf '%s\n' "$KEYRING_INDEX" | grep -oE 'kali-archive-keyring_[^" <]+_all\.deb' | sort -V | tail -n1 || true)

if [[ -z "$KEYRING_FILE" ]]; then
  echo "Could not find the Kali archive keyring package."
  echo "Kali keyring index: $KALI_KEYRING_POOL"
  exit 1
fi

echo "Using Kali archive keyring: $KEYRING_FILE"
curl -fsSL --retry 5 --retry-delay 2 "${KALI_KEYRING_POOL}${KEYRING_FILE}" -o "/tmp/$KEYRING_FILE"
sudo dpkg -i "/tmp/$KEYRING_FILE" || sudo apt-get install -f -y

if [[ ! -f /usr/share/keyrings/kali-archive-keyring.gpg ]]; then
  echo "Kali archive keyring was not installed correctly."
  exit 1
fi

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
