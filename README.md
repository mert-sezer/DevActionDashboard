# Dev Action Dashboard

Native macOS app for day-to-day developer workflows: system metrics, processes, network, local ports, Docker, environment, utilities, and system actions.

## Requirements

- macOS 14.0+
- Xcode 16+

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
./Scripts/generate-xcodeproj.sh
```

## Install from DMG

Download the latest `.dmg` from [Releases](https://github.com/mert-sezer/DevActionDashboard/releases). Open it and drag **Dev Action Dashboard** into **Applications**.

Ad-hoc signed builds (the default for this open-source project) are blocked by Gatekeeper until you open the app once with **right-click → Open**. After that, it launches normally.

To verify a download:

```bash
shasum -a 256 -c DevActionDashboard-*.sha256
```

A Developer ID signature and Apple notarization remove the Gatekeeper warning. That requires a paid Apple Developer Program membership. Set `CODESIGN_IDENTITY` (and optional notarization secrets) when running `./Scripts/package-dmg.sh`. GitHub Actions uses the same values if they are stored as repository secrets.

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
