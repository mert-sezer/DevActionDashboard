<p align="center">
  <img src="docs/images/icon.svg" width="88" alt="Dev Action Dashboard">
</p>

<h1 align="center">Dev Action Dashboard</h1>

<p align="center">
  <strong>Native macOS control center for day-to-day developer work.</strong><br>
  System metrics, processes, network, ports, Docker, toolchains, and utilities — one window, no account.
</p>

<p align="center">
  <a href="https://github.com/mert-sezer/DevActionDashboard/releases"><img alt="Release" src="https://img.shields.io/github/v/release/mert-sezer/DevActionDashboard?include_prereleases&style=flat-square&color=26ADAD"></a>
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-black?style=flat-square">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-5.9-F05138?style=flat-square">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-blue?style=flat-square">
</p>

<p align="center">
  <img src="docs/images/hero.gif" alt="Live tour of Dashboard, Processes, Network, Ports, Utilities, and the command palette" width="920">
</p>

<p align="center">
  <a href="https://github.com/mert-sezer/DevActionDashboard/releases"><strong>Download DMG</strong></a>
  ·
  <a href="#install-from-dmg">Install notes</a>
  ·
  <a href="#getting-started">Build from source</a>
</p>

---

## What it does

A local-only SwiftUI app for the things you keep bouncing between Activity Monitor, Terminal, Docker Desktop, and a pile of browser tabs.

<p align="center">
  <img src="docs/images/welcome.png" alt="Welcome screen" width="720">
</p>

| Area | What you get |
| --- | --- |
| **Monitor** | Live CPU, memory, storage, battery, thermal state, and network pressure |
| **Develop** | Listening ports, Docker containers, installed toolchains |
| **Tools** | UUID, JWT, Base64, JSON, regex, cron, hashes, QR, color picker |
| **Actions** | Flush DNS, open common folders, jump to Terminal |
| **Palette** | ⌘K to jump anywhere without leaving the keyboard |

Addresses stay hidden until you choose **Show addresses**.

## Screenshots

<p align="center">
  <img src="docs/images/dashboard.png" alt="Dashboard with live CPU, memory, storage, and masked network addresses" width="48%">
  &nbsp;
  <img src="docs/images/processes.png" alt="Process list sorted by CPU" width="48%">
</p>

<p align="center">
  <img src="docs/images/network.png" alt="Network throughput, latency, and masked IPs" width="48%">
  &nbsp;
  <img src="docs/images/ports.png" alt="Local listening ports" width="48%">
</p>

<p align="center">
  <img src="docs/images/utilities.png" alt="Utilities with UUID generator selected" width="48%">
  &nbsp;
  <img src="docs/images/palette.png" alt="Command palette over Actions" width="48%">
</p>

<p align="center">
  <img src="docs/images/environment.png" alt="Installed toolchains on this Mac" width="48%">
  &nbsp;
  <img src="docs/images/docker.png" alt="Docker engine status" width="48%">
</p>

## Requirements

- macOS 14.0+
- Xcode 16+ to build from source

## Install from DMG

Download the latest `.dmg` from [Releases](https://github.com/mert-sezer/DevActionDashboard/releases). Open it and drag **Dev Action Dashboard** into **Applications**.

Ad-hoc signed builds (the default for this open-source project) are blocked by Gatekeeper until you open the app once with **right-click → Open**. After that, it launches normally.

```bash
shasum -a 256 -c DevActionDashboard-*.sha256
```

A Developer ID signature and Apple notarization remove the Gatekeeper warning. That requires a paid Apple Developer Program membership. Set `CODESIGN_IDENTITY` (and optional notarization secrets) when running `./.github/scripts/package-dmg.sh`. GitHub Actions uses the same values if they are stored as repository secrets.

## Getting started

```bash
git clone https://github.com/mert-sezer/DevActionDashboard.git
cd DevActionDashboard
open DevActionDashboard.xcodeproj
```

Select the **DevActionDashboard** scheme and press ⌘R.

The Xcode project is generated from [`project.yml`](project.yml) with [XcodeGen](https://github.com/yonaskolb/XcodeGen). After changing the source layout:

```bash
brew install xcodegen   # once
./.github/scripts/generate-xcodeproj.sh
```

## Architecture

```text
App/             Composition root and dependency injection
Features/        Isolated feature modules (SwiftUI + ViewModels)
Services/        Use-case facades
Infrastructure/  System, Docker, network, and process adapters
Core/            Protocols, models, errors, logging
Shared/          Design tokens and reusable UI
```

Features do not import other features. The sidebar is assembled from `FeatureRegistry`.

See [Documentation/Architecture.md](Documentation/Architecture.md) for details.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md).

## Security

See [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE) © 2026 Mert Sezer
