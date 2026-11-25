<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:0F172A,50:1E293B,100:0EA5E9&height=180&section=header&text=Finogen%20(Nova%20Finance)&fontSize=44&fontColor=F8FAFC&fontAlignY=38&desc=Enterprise%20Financial%20Intelligence%20and%20Multi-Platform%20Ledger&descSize=16&descAlignY=64" width="100%" alt="Finogen Header" />

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Riverpod-3.x-38BDF8?style=for-the-badge" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Firebase-Auth%20%26%20Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/Platforms-Android%20%7C%20Windows%20%7C%20Web%20%7C%20iOS-0F172A?style=for-the-badge" alt="Platforms" />
</p>

</div>

---

## Overview

**Finogen (Nova Finance)** is a cross-platform financial intelligence, multi-account ledger, Sri Lankan bank SMS automation, and business telemetry application built with **Flutter** and **Riverpod 3**. It serves as a unified financial control center for personal wealth management and **NovaGen** infrastructure operations.

## Key Features

- **Multi-Account & Workspace Ledger:** Separate personal and business (`workspace`) financial tracking with instant transfers and real-time balance calculation.
- **Sri Lankan Bank SMS Automation (Android):** Native `MethodChannel` background SMS listener (`com.example.nova_finance/sms`) for automatic transaction ingestion and parsing.
- **Crypto & Exchange Telemetry:** Live MEXC Spot & Futures USDT portfolio tracking (`crypto` module).
- **Budgets, Bills & Savings Goals:** Scheduled local notifications (`flutter_local_notifications`), recurring bill tracking, and goal progress analytics.
- **Interactive Analytics & Reports:** Multi-bar cash flow, expense curves, and category breakdowns powered by `fl_chart`, plus CSV export and sharing.
- **Biometric & PIN Security:** Fingerprint / Face ID (`local_auth`), custom PIN lock, and balance privacy obfuscation mode.
- **Offline-First Sync:** Binary local caching via **Hive** + `SharedPreferences` paired with real-time **Cloud Firestore** synchronization (`users/{uid}/...`).
- **NovaGen NOC Integration:** Real-time server health, X-UI bandwidth/client telemetry, and revenue monitoring.

---

## Architecture & Project Structure

```text
lib/
├── core/                      # Theme, routing, localization, security & shared services
└── features/
    ├── accounts/              # Bank, cash & wallet account management
    ├── auth/                  # Firebase Auth (Google Sign-In & Guest mode)
    ├── bills/                 # Recurring bills & due-date reminders
    ├── budget/                # Monthly category budgets
    ├── crypto/                # MEXC & crypto portfolio tracking
    ├── goals/                 # Savings goals & milestones
    ├── home/                  # High-density Bento dashboard
    ├── main/                  # Adaptive shell (Mobile bottom nav / Desktop sidebar)
    ├── novagen/               # NovaGen SpeedNet NOC & business telemetry
    ├── reports/               # Financial statements & CSV exports
    ├── settings/              # Theme, biometrics, PIN & backup preferences
    ├── spending/              # Expense categorization & insights
    ├── statistics/            # Cash-flow charts & trends
    ├── transactions/          # Unified ledger & SMS auto-parsed entries
    ├── transfer/              # Inter-account transfers
    └── workspace/             # Personal / Business workspace switching
```

---

## Tech Stack

| Layer | Technology |
| :--- | :--- |
| **Framework** | Flutter (`^3.10.0`) & Dart 3 |
| **State Management** | `flutter_riverpod` (`^3.3.2`) |
| **Cloud Backend** | Firebase Core, Firebase Auth, Cloud Firestore |
| **Local Persistence** | Hive (`^2.2.3`), `hive_flutter`, `shared_preferences` |
| **Charts & UI** | `fl_chart`, `lucide_icons`, `google_fonts`, `table_calendar` |
| **Security & Native** | `local_auth`, `flutter_local_notifications`, Android SMS `MethodChannel` |

---

## Getting Started

```bash
# 1. Install dependencies
flutter pub get

# 2. Run on Android / Windows / Web
flutter run
```

See [`AGENTS.md`](./AGENTS.md) for the full system architecture and Firestore schema specification.
