# RebuiltKali 🐉

**RebuiltKali** is an independent, community-built Kali Linux derivative focused on a clean, lightweight XFCE desktop and a reproducible ISO build process.

> RebuiltKali is **not an official Kali Linux project**. Kali Linux and its trademarks belong to their respective owners.

## ✨ Features

- 🐧 Kali Linux rolling base
- 🖥️ XFCE desktop
- 📦 APT package management
- ⚡ Lightweight desktop-focused setup
- 🔧 Custom OS identity and configuration
- 💿 Reproducible AMD64 live ISO builds
- 🤖 Ready for GitHub Actions automation

## 🏗️ Building the ISO

The project uses Kali's official `kali-live` build framework as its upstream build system. Kali documents this framework for customized Kali images. citeturn0search1turn0search0

Build from a Kali Linux or supported Debian-based environment:

```bash
git clone https://github.com/carjam120443-netizen/rebuiltkali.git
cd rebuiltkali
chmod +x build.sh
./build.sh
```

The script installs the required build dependencies, downloads or updates Kali's live-build framework, applies the RebuiltKali configuration, and starts an XFCE AMD64 build.

### Requirements

- Debian/Kali-based build environment
- `sudo` access
- Internet connection
- Git
- Enough disk space for the Kali build environment and generated ISO

## 📁 Project Layout

```text
rebuiltkali/
├── config/
│   ├── etc/
│   │   └── os-release
│   ├── hooks/
│   │   └── 01-rebuiltkali.chroot
│   └── package-lists/
│       └── rebuiltkali.list.chroot
├── build.sh
└── README.md
```

## 🧪 Current Status

🚧 **Early development** — the initial ISO build system and XFCE configuration are being assembled now.

Future plans include custom artwork, wallpapers, branding, additional package selections, and automated ISO builds.

## ⚖️ Credits & Licensing

RebuiltKali builds on Kali Linux's publicly documented ISO-building framework. See Kali's documentation and upstream project for the applicable licenses and attribution requirements.

- Kali Linux: https://www.kali.org/
- Kali live build scripts: https://gitlab.com/kalilinux/build-scripts/kali-live

RebuiltKali's own files are provided under the license included in this repository, when applicable.
