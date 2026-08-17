# Architecture

Dev Action Dashboard is a native SwiftUI macOS app with a layered, feature-based layout.

## Layers

| Layer | Responsibility |
|-------|----------------|
| `App/` | Scene, composition root, navigation, menu bar |
| `Features/` | One domain per module: views and view models |
| `Services/` | Use-case facades shared by features |
| `Infrastructure/` | Darwin, Network, Docker CLI, and other adapters |
| `Core/` | Protocols, models, errors, logging, input policy |
| `Shared/` | Design tokens and reusable UI |

Features never import other features. Cross-feature navigation goes through `AppNavigationStore` and `FeatureRegistry`.

View models do not talk to OS APIs directly. They depend on services; services depend on Core protocols implemented in Infrastructure.

## Source layout

```text
DevActionDashboard/
  App/             Scene, DI, navigation, menu bar
  Features/        One folder per feature (views + view models)
  Services/        Shared use-case facades
  Infrastructure/  Darwin, Docker CLI, network, process adapters
  Core/            Protocols, models, errors, logging, input policy
  Shared/          Design tokens and reusable UI
  Resources/       Asset catalog
Tests/
Scripts/
Documentation/
```

## Safety constraints

- Subprocesses are launched by absolute executable path and argument arrays, never a shell string.
- Docker CLI path must resolve to a binary named `docker`; container IDs must be hexadecimal-length alphanumeric values.
- Port fingerprinting and “Open in Browser” stay on loopback `http(s)` and do not follow redirects off localhost.
- DerivedData cleanup skips symbolic links.
- Public IP lookup accepts only a well-formed IPv4 or IPv6 address.

## Features

| Feature | Role |
|---------|------|
| Dashboard | Overview metrics, local/public IP, DNS |
| System | Host identity, thermal, hardware summary |
| Processes | Process list, terminate, Activity Monitor |
| Network | Path, addresses, throughput, latency, DNS |
| Ports | Listening TCP ports and stack fingerprints |
| Docker | Container list, logs, start/stop via Docker CLI |
| Environment | Installed developer toolchains |
| Env Vars | Process environment browse and compare |
| Utilities | JSON, JWT, Base64, hash, QR, color, and related tools |
| Actions | DNS flush, Finder/Dock restart, DerivedData, Trash, shortcuts |
| Settings | Theme, accent, refresh interval, notifications, menu bar, Docker path |
| About | Version and license |

## UI state vs live data

- SwiftUI `@Observable` view models hold screen state.
- Live collectors (metrics, network, Docker, ports, processes) are shared services with start/stop monitoring.

## Destructive actions

Actions that restart system UI, empty Trash, or delete DerivedData require an in-app confirmation before they run.
