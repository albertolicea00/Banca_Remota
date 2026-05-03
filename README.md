# Banca Remota — Cuba

Native iPhone app that simplifies Cuban banking operations via USSD codes. No internet required — everything works over the phone network.

Created to revive the original BancaRemota app after it disappeared, with credit to **Henry Cruz** as the creator of the original version.

Compatible with:
- **BPA** — Banco Popular de Ahorro
- **BANDEC** — Banco de Crédito y Comercio
- **BM** — Banco Metropolitano

---

## Features

### Banking Operations
Access any USSD operation for your bank (login, balance check, transfers, limits, etc.) organized by category. Tap an operation and the system dialer opens with the code ready to call.

### Favorites
Pin frequent operations to the home screen for quick access. Drag to reorder. Color customizable from Settings.

### Bank Accounts
Store card data (number, cardholder name, associated mobile, custom color). Numbers are masked by default and can be copied to clipboard.

### Nauta Accounts
Store Nauta usernames (Nacional and Internacional) organized by groups.

### Service Bills
Store contract numbers for electricity, water, gas, and telephone — copy them quickly when making USSD payments.

### Keys
Local PIN and password manager by category. **Only accessible when biometric authentication is enabled.**

### Settings
- Light / dark / system theme
- Face ID / Touch ID with configurable session expiration
- Toggle menu shortcuts on home screen
- Custom color for favorite cards
- Reset favorites to defaults

---

## Privacy

- No internet connection required
- No servers, no user accounts, no analytics
- All data stored locally on device only (UserDefaults)
- Keys section requires biometric authentication (Face ID / Touch ID)
- Data never leaves the device

---

## Requirements

- iOS 16.0+
- Xcode 15.0+

## Installation

1. Clone the repository.
2. Open `Banca_Remota.xcodeproj` in Xcode.
3. Configure your developer account in _Signing & Capabilities_.
4. Build and run on a physical device with **Cmd+R**.

---

## Project Structure

| File | Description |
|---|---|
| `codes.json` | Banks, categories and USSD codes. Edit this file to add or modify operations without touching code. |
| `Models.swift` | `Codable` models for `codes.json` and user data structures (`BankAccount`, `NautaAccount`, `Bill`, `UserKey`). |
| `Services.swift` | Configuration loading, USSD dialer, favorites management and user data persistence. |
| `Views.swift` | All screens: navigation, lists, edit forms and info views. |
| `UIComponents.swift` | Reusable components: `TopNavBar`, `OperationCard`, `WalletCard`, `DataCard`, `MenuShortcutCard`, etc. |
| `BancaRemotaApp.swift` | App entry point, authentication management and theme preferences. |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). **Issues, PR descriptions and commit messages must be written in English.**

> Note: The app UI is intentionally in Spanish — it targets Cuban users. Code contributions should still follow English conventions for all technical communication.

---

*Developed by [Alberto Licea](https://www.linkedin.com/in/albertolicea00). Inspired by the original app by [Henry Cruz](https://www.linkedin.com/in/henrycruzmederos).*
