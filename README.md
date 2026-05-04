# Moefox Browser

<p align="center">
  <img src="tools/moefox/icon/source/icon.png" alt="Moefox Icon" width="256" height="256">
</p>

Moefox is a Firefox-based web browser that balances privacy with usability.

## 🌟 Core Features

### 🔒 Privacy & Security First

- **Most telemetry and data collection disabled**: Telemetry, health report, crash reporting, Pocket, Activity Stream, and other data collection features are turned off by default
- **HTTPS-Only Mode**: Forces HTTPS connections by default to ensure communication security
- **Pre-installed uBlock Origin**: Powerful ad blocking and anti-tracking extension, ready out of the box
- **Pre-installed Bitwarden**: Open-source password manager for secure storage and auto-fill
- **Pre-installed Firefox Multi-Account Containers**: Container tab isolation to prevent cross-site tracking
- **Default DuckDuckGo search**: Privacy-friendly search engine that doesn't track users

### 🎨 Modern Interface

- **Microsoft Edge-style layout**: Vertical tabs, detached sidebar, Edge-style top chrome
- **Flexible layout options**: Sidebar left/right switching, vertical tabs detach/merge, dual-row top chrome
<p align="center">
  <img src="docs\moefox\images\preview.png" alt="Moefox preview">
</p>

## 🚀 Quick Start

### Download & Install

Visit the [Releases](../../releases) page to download the latest installer or portable package.

### Development Build

See the following documentation:
- **Build Tools**: [`tools/moefox/README.md`](tools/moefox/README.md) — Build scripts and tool usage guide
- **Release Workflow**: [`tools/moefox/RELEASE.md`](tools/moefox/RELEASE.md) — Multi-locale packaging and release process

## 📚 Documentation

| Document | Description |
|------|------|
| [`docs/moefox/overview.md`](docs/moefox/overview.md) | Distribution tools and documentation overview |
| [`docs/moefox/icon-and-branding.md`](docs/moefox/icon-and-branding.md) | Icon generation and branding implementation guide |
| [`tools/moefox/README.md`](tools/moefox/README.md) | Detailed build tool usage guide |
| [`tools/moefox/RELEASE.md`](tools/moefox/RELEASE.md) | Packaging and release workflow documentation |
| [`tools/moefox/icon/README.md`](tools/moefox/icon/README.md) | Icon generation tool documentation |

## ⚠️ Notes

- **Update mechanism**: Moefox currently disables built-in auto-updates (settings page retains but grays out the option). Please manually download new versions. GitHub Releases checking and one-click updates will be gradually implemented
- **Extension compatibility**: Fully compatible with the Firefox extension ecosystem
- **Profile**: Moefox uses a separate profile directory and will not interfere with the original Firefox. You can import profiles from Firefox, but a fresh profile is recommended for the complete Moefox default experience
- **Default browser prompt**: Will not ask about setting as default browser on first run, to avoid interruption

## 📄 License

This project is licensed under the [Mozilla Public License 2.0](LICENSE).

## 🚫 Disclaimer

Moefox actively replaces Firefox default names and logos with its own. If any Firefox names or logos appear anywhere, it is typically due to an oversight or technical issue preventing replacement. Moefox is in no way intended to impersonate the original Firefox.

## 🔗 Related Links

- [Firefox Official Website](https://firefox.com/)
- [Firefox Source Code Documentation](https://firefox-source-docs.mozilla.org/)
- [Mozilla Organization](https://mozilla.org/)
- [uBlock Origin](https://github.com/gorhill/uBlock)
- [Bitwarden](https://bitwarden.com/)
- [Firefox Multi-Account Containers](https://github.com/mozilla/multi-account-containers)

---