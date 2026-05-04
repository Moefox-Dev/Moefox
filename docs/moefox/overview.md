# Moefox Distribution Tools & Documentation Overview

This directory centralizes Moefox distribution-specific documentation for easy reference and maintenance.

> **Core Principle**: Moefox is a privacy-focused and security-enhanced Firefox customization with a Microsoft Edge-like interface experience.

---

## 📁 Directory Structure

```
repository/
├── docs/moefox/                # [This directory] Distribution docs
│   ├── overview.md             # Overview document (you are reading)
│   └── icon-and-branding.md    # Icon and branding implementation guide
├── tools/moefox/               # Distribution tool scripts
│   ├── build-moefox.ps1           # Unified build entry point (interactive)
│   ├── package-multi-locale.ps1   # Multi-locale packaging main script
│   ├── l10n_overlay.py            # Localization overlay tool
│   ├── stage-extension.ps1        # Unified extension staging script (supports ublock/bitwarden/multi-account-containers)
│   ├── clean-user-data.ps1        # User data cleanup
│   ├── reset-dev-profile.ps1      # Dev profile reset
│   ├── debug-locale.js            # Locale debugging script
│   ├── icon/                       # Icon generation tools
│   │   ├── generate_icons.py      # Icon generation script
│   │   ├── source/                # Source icon files
│   │   └── README.md              # Icon tool documentation
│   ├── README.md                  # Tool usage guide
│   └── RELEASE.md                 # Release workflow details
├── browser/branding/moefox/    # Moefox branding assets
└── browser/locales/*/browser/preferences/moefox.ftl  # Moefox-specific translations
```

---

## 🛠 Tool Scripts Quick Reference

### Build & Package

| Script | Purpose | Common Command |
|------|---------|---------|
| `build-moefox.ps1` | Unified build entry point (interactive) | `.\tools\moefox\build-moefox.ps1` |
| `package-multi-locale.ps1` | Multi-locale packaging (low-level) | Called by build-moefox.ps1 |
| `l10n_overlay.py` | Merge Moefox localization strings | Automatically invoked by packaging script |

**Recommended build methods:**
```powershell
# Interactive launch (recommended) - guides build mode selection
.\tools\moefox\build-moefox.ps1

# Quick dev iteration
.\tools\moefox\build-moefox.ps1 -Dev -Quick

# Release build (clean build)
.\tools\moefox\build-moefox.ps1 -Release -Clobber
```

### Extension Pre-installation

| Script | Purpose | Notes |
|------|------|------|
| `stage-extension.ps1` | Unified extension deployment | Supports ublock / bitwarden / multi-account-containers |

```powershell
# Deploy extensions individually (usually auto-called by packaging script)
.\tools\moefox\stage-extension.ps1 -Extension ublock -StageToObjDir
.\tools\moefox\stage-extension.ps1 -Extension bitwarden -StageToObjDir
.\tools\moefox\stage-extension.ps1 -Extension multi-account-containers -StageToObjDir
```

### Development & Debugging

| Script | Purpose | Common Command |
|------|---------|---------|
| `reset-dev-profile.ps1` | Reset dev profile | `.\tools\moefox\reset-dev-profile.ps1` |
| `clean-user-data.ps1` | Thorough user data cleanup | `.\tools\moefox\clean-user-data.ps1` |
| `debug-locale.js` | Diagnose locale issues | Run in browser console |

### Icon Generation (`tools/moefox/icon/`)

| Script | Purpose |
|------|------|
| `generate_icons.py` | Interactive generation of all brand icons |

```bash
# 1. Prepare source image (SVG or 1024×1024 PNG recommended)
#    Place in tools/moefox/icon/source/icon.svg or icon.png
# 2. Install dependencies
pip install Pillow
# 3. Generate icons
cd tools/moefox/icon
python generate_icons.py
```

---

## 📄 Key Document Index

| Document | Location | Description |
|------|------|------|
| **Release Workflow** | `tools/moefox/RELEASE.md` | Detailed packaging and release steps |
| **Tool Usage Guide** | `tools/moefox/README.md` | How to use all tools |
| **Icons & Branding** | `docs/moefox/icon-and-branding.md` | Icon generation and branding configuration |
| **Icon Generation Tool** | `tools/moefox/icon/README.md` | Icon processing script details |

---

## 🔧 Moefox-Specific Configuration

### Default Privacy Settings (`browser/app/profile/firefox.js`)

- ✅ HTTPS-Only Mode
- ✅ Telemetry and data collection disabled
- ✅ Crash reporting disabled
- ✅ Default search engine: DuckDuckGo
- ✅ Baidu search engine disabled

### UI Layout Defaults

- ✅ Sidebar displayed on the right by default
- ✅ Vertical tabs enabled and detached from sidebar by default
- ✅ Edge-style two-row top chrome layout

### Pre-installed Extensions

- ✅ uBlock Origin (ad blocking)
- ✅ Bitwarden (password management)

---

## 🚀 Quick Start

### Interactive Build (Recommended)

```powershell
# Launches interactive menu to guide build mode selection
.\tools\moefox\build-moefox.ps1
```

### Command Line Build

```powershell
# Quick dev iteration (skip configure)
.\tools\moefox\build-moefox.ps1 -Dev -Quick

# Full dev build
.\tools\moefox\build-moefox.ps1 -Dev

# Clean dev build (first time or after major changes)
.\tools\moefox\build-moefox.ps1 -Dev -Clean

# Release build (recommend using -Clobber)
.\tools\moefox\build-moefox.ps1 -Release -Clobber
```

### Development Testing

```powershell
# Run compiled build
./mach run

# Reset dev profile (test new default settings)
.\tools\moefox\reset-dev-profile.ps1
```

### Clean Reinstall Testing

```powershell
# Thoroughly clean user data before testing installer
.\tools\moefox\clean-user-data.ps1 -Force
```

---

## 📋 Multi-language Support

### Supported Languages

| Language | Code | Brand Translation | Settings Page Translation |
|------|------|----------|-----------|
| English | `en-US` | ✅ | ✅ |
| Simplified Chinese | `zh-CN` | ✅ | ✅ |
| Traditional Chinese | `zh-TW` | ✅ | ✅ |
| Japanese | `ja` | ✅ | ✅ |
| Korean | `ko` | ✅ | ✅ |
| German | `de` | ✅ | ✅ |
| French | `fr` | ✅ | ✅ |
| Spanish | `es-ES` | ✅ | ✅ |
| Russian | `ru` | ✅ | ✅ |

### Localization File Locations

- **Brand name**: `browser/branding/moefox/locales/<locale>/brand.ftl`
- **Settings page strings**: `browser/locales/<locale>/browser/preferences/moefox.ftl`

---

## ⚠️ Notes

1. **Disk space**: At least 30-50 GB required
2. **Artifact Build disabled**: To support custom EXE icons, use a full build

---
