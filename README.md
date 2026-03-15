# Remote Banking - Cuba

Remote Banking is a native iOS application written in SwiftUI to automate USSD (Telebanca) calls and codes for the main banks in Cuba:

- **BPA** (Banco Popular de Ahorro)
- **BANDEC** (Banco de Crédito y Comercio)
- **BM** (Banco Metropolitano)

## Features

- **Native & Fast Interface:** Built 100% with SwiftUI, featuring fluid transitions and reusable components.
- **JSON-Driven Configuration:** All operations, menus, and USSD codes are defined in the `codes.json` file. To add or modify a code, simply edit the JSON without having to reprogram the interface logic.
- **Automatic Dialing:** Executes phone commands and USSD codes automatically by correctly parsing `#` symbols.

## Requirements

- iOS 16.0+
- Xcode 14.0+

## Installation

1. Clone the repository.
2. Open the `Banca_Remota.xcodeproj` file using Xcode.
3. Configure your developer account in _Signing & Capabilities_ to compile on a physical device.
4. Press **Build and Run (Cmd+R)**.

## Core Files

- `codes.json` - Configured banking operation data.
- `BancaRemotaApp.swift` - App entry point.
- `Views.swift` - Main views and side menu navigation.
- `Services.swift` - Data loading and phone dialer utility services.
- `Models.swift` - `Codable` data models for parsing `codes.json`.

## Contributing

Any improvements to the codes or interface design are welcome.
