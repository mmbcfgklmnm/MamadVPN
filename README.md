# 🛡️ MamadVPN

<p align="center">
  <img src="https://raw.githubusercontent.com/mamadvpn/mamadvpn/main/assets/banner.png" alt="MamadVPN Banner" width="700" onerror="this.style.display='none'"/>
</p>

<p align="center">
  <b>A next-generation, high-performance, ultra-sleek VPN client for Windows & Android.</b><br>
  Built with Flutter for high fps animation, modern design system, and multi-protocol censorship circumvention.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20Android-00F2FE?style=for-the-badge&logo=android&logoColor=white" alt="Platforms" />
  <img src="https://img.shields.io/badge/Core-Sing--Box%20%2F%20Xray-7F00FF?style=for-the-badge" alt="Core" />
  <img src="https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2563EB?style=for-the-badge&logo=githubactions&logoColor=white" alt="GitHub Actions" />
  <img src="https://img.shields.io/badge/License-GPLv3-00E676?style=for-the-badge" alt="License" />
</p>

---

## ✨ Features

### 🎨 Super Sleek & Futuristic UI
- **OLED Dark Theme**: Deep obsidian background (`#0B0E14`), glowing cyber-cyan accents (`#00F2FE`), electric purple gradients, and glassmorphic cards.
- **Studio Light Theme**: Crisp alabaster surface with royal sapphire accents and high-contrast typography.
- **Glowing Power Button**: Animated pulsating breathing ring, connection status glow, and live connection timer.
- **Adaptive Layout**: Responsive Desktop Navigation Rail for **Windows** and modern Bottom Navigation Bar for **Android**.

### ⚡ Multi-Protocol Censorship Circumvention
Import, parse, and connect to all state-of-the-art protocols:
- **VLESS** (XTLS, Reality, Vision, WebSocket, gRPC)
- **VMess** (WebSocket, TCP, TLS, Base64 JSON links)
- **Trojan** (TLS, gRPC, WebSocket)
- **Hysteria 2 / Hy2** (QUIC-based high-speed protocol)
- **Shadowsocks** (SIP002 standard & AEAD ciphers)
- **WireGuard**

### 🛰️ Advanced Subscription Management
- Add subscriptions via HTTP/HTTPS URLs or multi-line base64 blobs.
- Automatic and one-click batch updates for all subscriptions.
- Live quota tracking: Displays used bandwidth vs total package quota and expiration dates via `subscription-userinfo` headers.

### 📊 Real-Time Traffic & Speed Monitoring
- Live download and upload speedometers (KB/s, MB/s) with dynamic bitrate calculations.
- Cumulative session data counters (total downloaded and uploaded MB/GB).
- Active session duration stopwatch.

### ⏱️ Concurrent Ping Latency Testing
- Multi-threaded TCP socket ping testing.
- Color-coded latency badges:
  - 🟢 **Fast**: `< 150 ms`
  - 🟡 **Medium**: `150 ms - 350 ms`
  - 🔴 **High**: `> 350 ms`
  - ⚪ **Timeout**: Unreachable / Blocked
- **One-Click "Auto-Select Fastest"**: Automatically switches to the node with the lowest latency.
- Sorting options: Lowest Ping, Alphabetical, or Protocol.

### 🛡️ Smart Routing & Engine Settings
- **TUN Virtual Network Adapter**: Captures all system, app, and game traffic at the L3 IP layer.
- **System Proxy Mode**: Configures system HTTP/SOCKS5 proxy.
- **Routing Rules**:
  - *Bypass LAN & Iran*: Direct routing for domestic Iranian websites and bank portals; tunnels international traffic.
  - *Global Proxy*: Tunnels 100% of network traffic.
- **DNS Leak Protection**: Secure upstream DNS options (Cloudflare 1.1.1.1, Google 8.8.8.8, AdGuard, Quad9, DoH).
- **Security**: Auto-connect on startup, Kill switch, IPv6 tunnel toggle.

---

## 🚀 GitHub Actions Automated Builds (CI/CD)

The repository includes a ready-to-run GitHub Actions workflow (`.github/workflows/build.yml`) that automatically compiles release packages for both platforms whenever code is pushed to `main` or a new tag (e.g. `v1.0.0`) is created:

| Platform | Output Artifact | Details |
|---|---|---|
| **Android** | `MamadVPN-Universal.apk` | Compatible with all Android devices (Android 7.0+) |
| **Android** | `MamadVPN-arm64-v8a.apk` | Optimized for modern 64-bit phones (smaller size) |
| **Android** | `MamadVPN-armeabi-v7a.apk` | Optimized for older 32-bit devices |
| **Android** | `MamadVPN-x86_64.apk` | For Android emulators & Chromebooks |
| **Windows** | `MamadVPN-Windows-x64.zip` | Standalone portable executable with all runtime dependencies |

Whenever you push a Git release tag (e.g. `git tag v1.0.0 && git push origin v1.0.0`), GitHub Actions will automatically draft a **GitHub Release** and attach all APKs and the Windows ZIP!

---

## 🛠️ Local Development & Build

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.24.0`)
- [Java JDK 17](https://adoptium.net/) (for Android builds)
- Visual Studio 2022 with "Desktop development with C++" (for Windows builds)

### 1. Clone & Install
```bash
git clone https://github.com/mamadvpn/mamadvpn.git
cd mamadvpn
flutter pub get
```

### 2. Run Tests
```bash
flutter test
```

### 3. Build Android APK
```bash
# Universal Release APK
flutter build apk --release

# Split APKs per architecture (smaller size)
flutter build apk --split-per-abi --release
```
*Outputs will be in: `build/app/outputs/flutter-apk/`*

### 4. Build Windows Desktop
```bash
flutter config --enable-windows-desktop
flutter build windows --release
```
*Outputs will be in: `build/windows/x64/runner/Release/`*

---

## 📂 Project Structure

```
MamadVPN/
├── .github/
│   └── workflows/
│       └── build.yml               # Automated CI/CD pipeline for Android & Windows
├── android/                        # Android native app & VpnService implementation
├── windows/                        # Windows native desktop runner & CMake build files
├── lib/
│   ├── main.dart                   # Application entry point & theme initialization
│   ├── core/
│   │   ├── constants/              # App constants, defaults, and keys
│   │   ├── theme/                  # OLED dark theme, light theme, cyber neon colors
│   │   └── utils/                  # Formatters for bytes, speed, ping, and flags
│   ├── models/
│   │   ├── server_node.dart        # Node model supporting VLESS, VMess, Trojan, etc.
│   │   ├── subscription.dart       # Subscription profile with quota tracking
│   │   ├── traffic_stats.dart      # Real-time speed and data counters
│   │   └── app_settings.dart       # Routing, DNS, TUN/Proxy, and theme settings
│   ├── services/
│   │   ├── config_parser.dart      # Protocol URI parser & Sing-Box config builder
│   │   ├── subscription_service.dart # Remote subscription fetcher & base64 decoder
│   │   ├── ping_service.dart       # TCP socket & HTTP ping testing engine
│   │   ├── traffic_service.dart    # Live telemetry and bandwidth stream
│   │   ├── vpn_core_service.dart   # Core lifecycle orchestrator
│   │   └── storage_service.dart    # SharedPreferences local persistence
│   ├── providers/                  # State management controllers
│   │   ├── vpn_controller.dart     # Connect / Disconnect state machine
│   │   ├── server_controller.dart  # Servers list, search, batch ping, active node
│   │   ├── subscription_controller.dart # Subscriptions manager
│   │   └── settings_controller.dart # Theme, routing, and DNS preferences
│   └── views/
│       ├── home/                   # Dashboard: Glowing power button, speed cards
│       ├── servers/                # Server list: Search, protocol chips, batch ping
│       ├── subscriptions/          # Subscriptions: Quota progress, auto-updates
│       ├── settings/               # Settings: Routing rules, DNS, TUN mode, Theme
│       └── widgets/                # GlassCard, PulseButton, SpeedCard, PingBadge
├── test/                           # Unit tests for parsers and utilities
└── pubspec.yaml                    # Flutter project specification
```

---

## 📜 License
This project is open-source under the **GNU General Public License v3.0**.
