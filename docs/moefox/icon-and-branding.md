# Moefox Icon & Branding Implementation Guide

## Problem & Solution

### Original Problem
- **Symptom**: Packaged Moefox application still shows Firefox icons
- **Root Cause**: Artifact Build uses pre-compiled EXEs whose embedded icons cannot be changed
- **Solution**: Switch to Full Compilation

### Build Method Comparison

| Build Method | Pros | Cons |
|---------|------|------|
| Artifact Build | Fast build time | Cannot customize EXE embedded icons |
| **Full Compilation** | Fully customize all icons | Slow build time |

---

## Icon Generation Tool

Location: `tools/moefox/icon/`

### Quick Usage

```bash
# 1. Prepare source image (SVG or at least 1024×1024 PNG recommended)
#    Place in tools/moefox/icon/source/icon.svg or icon.png

# 2. Install dependencies
pip install Pillow

# 3. Interactively generate all icons
cd tools/moefox/icon
python generate_icons.py
```

### Generated Icon Types

- **Windows default icons**: `default16.png` ~ `default256.png`
- **Windows tiles**: `VisualElements_70.png`, `VisualElements_150.png`
- **Private browsing tiles**: `PrivateBrowsing_70.png`, `PrivateBrowsing_150.png`
- **ICO files**: `firefox.ico`, `firefox64.ico`, `document.ico`, etc.
- **MSIX assets**: Assets required for Windows Store packages

---

## Branding Asset File Structure

```
browser/branding/moefox/
├── content/
│   ├── about-logo.svg          # About page SVG logo
│   ├── about-logo.png          # About page PNG
│   ├── about-logo@2x.png       # About page 2x PNG
│   ├── firefox-wordmark.svg    # Wordmark
│   └── moefox-wordmark.svg     # Moefox wordmark
├── msix/Assets/                # Windows Store assets
├── locales/                    # Multi-language brand strings
│   ├── en-US/brand.ftl
│   ├── zh-CN/brand.ftl
│   └── ...
├── *.ico                       # Windows icon files
├── *.png                       # PNG icons in various sizes
├── configure.sh                # Brand build configuration
└── branding.nsi                # NSIS installer configuration
```

---

## Multi-language Brand Name

Configured languages:
- English (en-US)
- Simplified Chinese (zh-CN)
- Traditional Chinese (zh-TW)
- Japanese (ja)
- Korean (ko)
- German (de)
- French (fr)
- Spanish (es-ES)
- Russian (ru)

Brand string location: `browser/branding/moefox/locales/<locale>/brand.ftl`

---

## Recompiling After Icon Changes

Icons in the EXE are embedded at compile time. After modification, recompilation is required:

```powershell
# 1. Update icon files in the branding directory
# 2. Recompile
.\tools\moefox\build-moefox.ps1 -Clean
```

---

*For detailed icon generation instructions, see `tools/moefox/icon/README.md`*
