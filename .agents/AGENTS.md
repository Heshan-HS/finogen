# Finogen (Nova Finance) — Master Architecture & Engineering Specification

## 1. Executive System Overview & Product Identity
**Finogen** (also known as Nova Finance) is an enterprise-grade financial intelligence, multi-account ledger, Sri Lankan bank automation, and business orchestration ecosystem built with Flutter.

The system acts as the unified financial control center for both personal wealth management and **NovaGen SpeedNet** (VPN infrastructure and telecommunications business operations).

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       FINOGEN ARCHITECTURE TOPOGRAPHY                       │
└─────────────────────────────────────────────────────────────────────────────┘
                                  ▲
                                  │ Multi-Platform UI (Flutter)
                                  ▼
      ┌───────────────────────────────────────────────────────┐
      │ Client Tier (Cross-Platform)                          │
      │ • Android Native (Hardware SMS Receiver + Biometrics) │
      │ • Windows Desktop (High-Resolution Bento Grid Layout) │
      │ • Web / PWA (CanvasKit & HTML Responsive Engine)      │
      │ • iOS / macOS (Apple Silicon & CocoaPods Integration) │
      └───────────────────────────┬───────────────────────────┘
                                  │
                                  │ State & Data Management
                                  ▼
      ┌───────────────────────────────────────────────────────┐
      │ Core Engine (Riverpod 3 + Offline Sync)               │
      │ • Local Persistence: Hive & SharedPreferences         │
      │ • Cloud Persistence: Cloud Firestore (users/{uid}/...)│
      │ • Auth Engine: Firebase Auth (Google Sign-In + Guest) │
      │ • Hardware Bridge: MethodChannel ('sms')              │
      └───────────────────────────┬───────────────────────────┘
                                  │
                                  │ Cross-Project API Bridge
                                  │ (Encrypted x-finogen-api-key)
                                  ▼
      ┌───────────────────────────────────────────────────────┐
      │ NovaGen SpeedNet Infrastructure Integration           │
      │ • Telemetry Bridge: https://finance.novagen.software  │
      │ • Server NOC Health: CPU, RAM, Disk, Load, Uptime     │
      │ • X-UI Core Sync: Active Users, Total Bandwidth       │
      │ • MEXC Crypto Balance: Spot & Futures Live USDT       │
      │ • Dual-Node Sync: Germany (Netcup) & Singapore (Linode)│
      └───────────────────────────────────────────────────────┘
```

---

## 2. Core Technology Stack & Architecture

### A. Technologies & Packages
- **Framework**: Flutter 3.10+ / Dart 3.x
- **State Architecture**: `flutter_riverpod: ^3.3.2`
  - Pattern: `Notifier` / `AsyncNotifier` / `StreamProvider`
  - Decoupled unidirectional data flow across repositories and views.
- **Cloud Infrastructure**:
  - `firebase_core: ^4.13.0`
  - `firebase_auth: ^6.5.7` (Google Sign-In & Anonymous Guest mode)
  - `cloud_firestore: ^6.8.0` (Real-time reactive document streams)
- **Local Persistence & Caching**:
  - `hive: ^2.2.3` & `hive_flutter: ^1.1.0`: High-performance binary offline cache.
  - `shared_preferences: ^2.5.5`: Instant local session flags (`isGuest`, theme mode, biometrics).
- **Native Android Hardware Bridge**:
  - `MethodChannel('com.example.nova_finance/sms')`: Background SMS broadcast listener for automatic bank transaction ingestion.
- **Biometric Security & Privacy**:
  - `local_auth: ^3.0.2`: Fingerprint, Face ID, and biometric credentials.
  - Custom PIN keypad and balance obfuscation mode.
- **Charts & Financial Telemetry**:
  - `fl_chart: ^1.2.0`: Multi-bar cash flow, expense curves, and category donut breakdowns.
- **Notifications & Scheduling**:
  - `flutter_local_notifications: ^22.3.0` & `timezone: ^0.11.1`: Scheduled bill due date alerts and budget warnings.
- **Icons & Typography**:
  - `lucide_icons: ^0.257.0` & `google_fonts: ^8.2.1` (Inter, Outfit, JetBrains Mono).

---

## 3. Database Architecture & Firestore Schemas

Finogen isolates all user data under a root tenant structure: `users/{uid}/...`

```
users/
└── {uid}/
    ├── accounts/           # Financial accounts (Banks, Wallets, Crypto, Holding)
    ├── transactions/       # Transaction ledger (Income, Expense, Transfer, Business)
    ├── budgets/            # Monthly category budget limits
    ├── goals/              # Long-term savings goals & milestones
    ├── bills/              # Recurring bills & subscription reminders
    ├── crypto_trades/      # Futures & Spot day trading journal
    ├── categories/         # Custom user categories with icons & colors
    └── settings/           # User configuration, security PIN, base currency
```

### Detailed Document Schemas:

#### 1. `AccountModel` (`users/{uid}/accounts/{id}`)
Represents any financial repository (Bank, eZ Cash, Cash, Crypto, Custodial):
```dart
{
  "id": String,                // Unique Firestore document ID
  "userId": String,            // Owner UID
  "name": String,              // e.g., "Nations Trust Bank", "eZ Cash SIM 2", "Mexc Account"
  "type": String,              // "bank", "cash", "credit", "crypto", "investment"
  "balance": double,           // Real-time balance (LKR or converted equivalent)
  "creditLimit": double,       // Credit limit (for credit cards / overdrafts)
  "colorValue": int,           // Color ARGB integer for UI chips
  "isEnabled": bool,           // Active/Inactive toggle
  "excludeFromTotal": bool,    // TRUE for holding accounts (e.g. GF Holding) to not distort Net Worth
  "lastSyncedAt": Timestamp,   // Last automated API or SMS sync timestamp
}
```

#### 2. `TransactionModel` (`users/{uid}/transactions/{id}`)
The immutable financial ledger:
```dart
{
  "id": String,
  "userId": String,
  "accountId": String,         // Primary linked account ID
  "categoryId": String,        // Category ID or custom category
  "amount": double,            // Transaction value
  "type": String,              // "income", "expense", "transfer", "business"
  "date": Timestamp,           // Transaction date
  "note": String,              // User memo or bank transaction description
  "recipientAccountId": String?, // Destination account ID (for inter-account transfers)
  "isBusiness": bool,          // Flag for NovaGen SpeedNet business transactions
  "businessType": String?,     // "client_payment", "server_cost", "drawing"
  "uniqueHash": String,        // SHA-256 de-duplication hash for incoming bank SMS
}
```

#### 3. `CryptoTradeModel` (`users/{uid}/crypto_trades/{id}`)
Day trading journal:
```dart
{
  "id": String,
  "pair": String,              // e.g., "BTCUSDT", "ETHUSDT", "SOLUSDT"
  "isLong": bool,              // true = Long, false = Short
  "entryPrice": double,
  "exitPrice": double?,
  "leverage": int,             // e.g., 10x, 20x, 50x
  "margin": double,            // USDT invested
  "pnl": double,               // Realized or unrealized PnL in USDT
  "status": String,            // "open", "closed"
  "createdAt": Timestamp,
}
```

---

## 4. Sri Lankan Automated Banking & Real-Time SMS Sync Engine

Finogen contains a proprietary automated SMS processing pipeline tailored specifically for Sri Lankan banking institutions and mobile wallets.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     AUTOMATED BANK SMS INGESTION FLOW                       │
└─────────────────────────────────────────────────────────────────────────────┘
  Incoming SMS on Android ──► BroadcastReceiver ──► MethodChannel ('sms')
                                                           │
                                                           ▼
                                               SmsParserService.parse()
                                                           │
                               ┌───────────────────────────┴───────────────────────────┐
                               ▼                                                       ▼
                Nations Trust Bank (NTB) Parser                           eZ Cash Dialog Parser
        • Detects CR/DR & Account: 2005xxxx0951                   • Primary SIM & Secondary SIM (769169810)
        • Extracts Amount & Current Balance                       • Parses Sinhala & English variations
        • Generates NTB unique SHA hash                           • Handles "RN:20", "Sheshaya: LKR", "recharge"
                               │                                                       │
                               └───────────────────────────┬───────────────────────────┘
                                                           ▼
                                                De-Duplication Engine
                                         (Checks uniqueHash in Firestore)
                                                           │
                                                           ▼
                                               Firestore Ledger Posting
                                  • Updates account balance automatically
                                  • Creates verified TransactionModel record
                                  • Dispatches local notification to status bar
```

### Supported Financial Institutions & Regex Rules:
1. **Nations Trust Bank (NTB)**:
   - Identifiers: Sender contains `NATIONS`, `NTB`, or body contains `Account No. 2005`.
   - Amount Regex: `r'for\s+LKR\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*(CR|DR)\.?'`
   - Balance Regex: `r'Current\s+Bal(?:ance)?\s+LKR\s*([0-9,]+(?:\.[0-9]{1,2})?)'`
   - De-duplication: Hashes account number, amount, type, balance, and minute-level timestamp into `uniqueHash`.
2. **eZ Cash Mobile Money (Dialog Axiata)**:
   - Primary SIM and Secondary SIM (`769169810` / `9010`):
   - Supports both Sinhala notifications (`"recharge kara etha"`, `"Sheshaya: LKR"`) and English transaction alerts (`"Current Balance:"`, `"RN:20"`).
   - Accurately deducts merchant and transfer commission fees.

---

## 5. NovaGen SpeedNet Dual-Node Integration Bridge

Finogen connects natively to the **NovaGen SpeedNet** VPN backend to give the owner total visibility and control over VPS servers, client payments, and MEXC balances.

### A. Real-Time NOC Telemetry (`novagen_api_service.dart`)
- **Base Endpoint**: `https://finance.novagen.software`
- **Security**: Authenticated with the header `x-finogen-api-key: finogen-secure-2024`.
- **System Health Telemetry (`NovaGenServerHealth`)**:
  - CPU percentage and 1-minute load average.
  - RAM utilization (Used GB / Total GB).
  - Disk storage utilization percentage.
  - Process uptime formatted as `Xd Xh Xm`.
- **X-UI Core Bandwidth Telemetry (`NovaGenXuiStats`)**:
  - Total registered VPN clients, Active users, Expiring soon (within 24h), and Expired counts.
  - Monthly bandwidth consumed vs total historical server traffic.
- **Dual-Node Status (`NovaGenDualNodeStatus`)**:
  - Real-time online ping status for **Germany (Netcup)** and **Singapore (Akamai/Linode)**.

### B. MEXC Exchange Live USDT Balance Sync (`mexc_sync_service.dart`)
- Finogen invokes `GET /api/crypto/mexc/balance` on the NovaGen server.
- The backend signs the HMAC-SHA256 request to MEXC API and returns Spot + Futures USDT totals.
- Finogen queries live USD ➔ LKR exchange rates via `https://api.exchangerate-api.com/v4/latest/USD` (with a safe fallback of `330.0 LKR`).
- If the balance differs by more than 1.0 LKR, Finogen automatically synchronizes the new value into the user's `Mexc Account` document in Firestore.

### C. NovaGen Business Financial Model (`novagen_business_provider.dart`)
Finogen contains a dedicated accounting engine specifically for the NovaGen SpeedNet business:
- **Base Net Profit**: Calibrated baseline profit of `Rs. 64,611.12`.
- **Netcup VPS Renewal**: Automatically calculates days remaining until server renewal on the **22nd of every month**.
- **The Strict Profit Isolation Rule**:
  - Real Net Profit = `baseNetProfit + dynamicRevenue - dynamicServerCost`.
  - **CRITICAL**: Strictly only Netcup server VPS expenses are counted as business expenses for NovaGen. All owner drawings, personal expenses, and general living costs deduct **ONLY** from personal Total Balance and **NEVER** from NovaGen Business Net Profit!

### D. NovaGen Hub Quick-Add (`novagen_hub_screen.dart`)
- Fast client subscription entry screen with preset package chips:
  `[100, 150, 200, 250, 350, 400, 450, 500, 600, 1000]`.
- Default account priority hierarchy:
  1. eZ Cash SIM 2 (`769169810`)
  2. Dialog New
  3. Nations Trust Bank

---

## 6. GF Holding Sub-Ledger System (`gf_holding_modal.dart`)

Finogen features an isolated custodial ledger for tracking partner or held funds without distorting the user's personal financial health.
- **Account Binding**: `GF BOC (Holding)`.
- **The Exclusion Rule**: Marked with `excludeFromTotal = true`. The balance is excluded from Total Net Worth, Total Income, and Total Expense charts.
- **Independent Sub-Ledger**: Features its own Deposit, Withdrawal, and Transfer tabs with dedicated month-by-month filtering and transaction histories.

---

## 7. Productivity Workspace Engine (`workspace_screen.dart`)

Finogen integrates productivity and time-management tools directly inside the financial application:
- **Interactive Calendar**: `table_calendar: ^3.2.1` with day/week/month selection.
- **Timetable Scheduler (`timetable_view.dart`)**: Hourly block organizer for study, server maintenance, trading sessions, and dev tasks.
- **Daily Notes (`notes_card.dart`)**: Quick notepad with auto-save for financial notes, reminders, and daily logs.
- **Task List (`tasks_list.dart`)**: Interactive checklist with completion toggles and priority badges.

---

## 8. Design System & Anti-AI-Slop Visual Craft

Finogen enforces a luxury visual standard across both Dark and Light modes:

### A. Dark Mode — Deep Obsidian Mint
- **Scaffold Background**: `#020706` (Deep obsidian teal)
- **Card Surfaces**: `#061210` (Base) and `#0A1512` (Elevated interactive cards)
- **Primary Accent**: `#00D9A8` (Electric mint green) with ambient glow `#2E00D9A8`
- **Progress Gradients**: `#C8F73A` ➔ `#86F278` ➔ `#4EDBA4`
- **Typography**: `#F2FAF6` (High contrast primary) and `#A5B4AD` (Muted secondary)
- **Borders**: 1px subtle hairline `Color(0x17F0FDF5)`

### B. Light Mode — Deep Luxury Emerald & Slate
- **Scaffold Background**: `#F8FAFC` (Clean slate off-white)
- **Card Surfaces**: `#FFFFFF` (Crisp pure white) and `#F1F5F9` (Elevated slate tiles)
- **Primary Accent**: `#005A36` (Prestigious deep luxury dark emerald)
- **Accent Tint**: `#E8F5ED` (Soft emerald badge fill)
- **Typography**: `#0F172A` (Slate-900 sharp dark text) and `#64748B` (Slate-500 secondary)
- **Borders**: Clean emerald border `Color(0x40005A36)`

### C. Responsive Bento Grids
- **Desktop (Width > 680px)**: Multi-column responsive Bento grid layout (`desktop_home_screen.dart`, `desktop_main_layout.dart`) featuring sidebar navigation, live server telemetry chips, and side-by-side charts.
- **Mobile**: Ergonomic single-column scrollable feed with sticky bottom navigation and touch-friendly sheets.

---

## 9. Operational Runbooks & Developer Rules

### A. Local Execution & Build Runbooks
- **Run Windows Desktop**:
  ```bash
  flutter run -d windows
  ```
- **Run Web (Local Dev)**:
  ```bash
  flutter run -d chrome
  ```
- **Build Android Release**:
  ```bash
  flutter build apk --release
  ```
- **Firebase Configuration**:
  ```bash
  flutterfire configure
  ```

### B. Strict Financial Integrity Rules (NEVER BREAK)
1. **Preserve SMS De-Duplication Hashes**:
   Never alter or bypass `uniqueHash` in `SmsParserService`. Changing hash algorithms without migration will re-import historical SMS messages and duplicate account balances.
2. **Never Mix Personal Expenses with Business Profit**:
   NovaGen SpeedNet business expenses must only include VPS server hosting fees. Personal withdrawals and living expenses must only deduct from the user's personal cash/bank balance.
3. **Always Respect `excludeFromTotal`**:
   Any new account type or custom ledger marked with `excludeFromTotal` must be excluded from total net worth sums across all analytics providers (`analytics_providers.dart`).
4. **Offline Resilience First**:
   Always handle Firebase initialization failures gracefully (especially on Windows Desktop without `flutterfire configure`) by offering Hive-cached local operation or a clear configuration prompt instead of crashing on the first frame.
