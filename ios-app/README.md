# CoreBank iOS App

Mobile banking app built with Swift and UIKit (programmatic — no Storyboard).
Connects to the Spring Boot Gateway for all banking operations.

![Swift](https://img.shields.io/badge/Swift-5.x-orange)
![UIKit](https://img.shields.io/badge/UIKit-Programmatic-blue)
![iOS](https://img.shields.io/badge/iOS-15+-lightgrey)
![Architecture](https://img.shields.io/badge/Architecture-MVVM-purple)

---

## Screenshots

```
Splash → Onboarding → Register → Login → Dashboard
```

---

## Features

### Completed
- Splash screen with animated gradient
- 3-slide onboarding with page dots
- Customer registration (full form validation)
- Login with JWT token storage
- Dashboard with live account balance
- Quick action buttons (Deposit, Withdraw, Transfer, History)
- Recent transactions list with credit/debit indicators
- Custom bottom tab bar (Home, Accounts, Transfer, History, Settings)
- Full API request/response logging with password masking

### In Progress
- Transfer screen
- Full transaction history
- Account detail screen
- Settings and logout

### Planned
- Blockchain mode toggle
- Face ID / Touch ID
- Push notifications

---

## Project Structure

```
CoreBankingApp/
├── Constants/
│   ├── AppColors.swift         ← blue design system colors
│   └── Constants.swift         ← API URL, keychain keys, UI constants
├── Network/
│   ├── APIService.swift        ← URLSession with full logging
│   └── Models/
│       ├── AuthModels.swift    ← login/register request+response
│       └── AccountModels.swift ← account and transaction models
├── Storage/
│   └── DeviceStorage.swift     ← UserDefaults wrapper
├── Utils/
│   └── Components/
│       ├── CBButton.swift      ← blue gradient button
│       └── CBTextField.swift   ← custom text field with icon
├── ViewModels/
│   ├── AuthViewModel.swift     ← register/login logic
│   └── DashboardViewModel.swift ← accounts/transactions logic
└── Views/
    ├── Splash/
    │   └── SplashViewController.swift
    ├── Onboarding/
    │   └── OnboardingViewController.swift
    ├── Auth/
    │   ├── LoginViewController.swift
    │   └── RegisterViewController.swift
    └── Dashboard/
        ├── MainTabBarController.swift
        └── Home/
            └── HomeViewController.swift
```

---

## Architecture — MVVM

```
View (UIViewController)
  │  user taps "Sign In"
  ▼
ViewModel (AuthViewModel)
  │  validates input
  │  calls APIService
  ▼
APIService (singleton)
  │  URLSession POST to Spring Boot
  ▼
Spring Boot Gateway (port 8080)
  │  validates, forwards, responds
  ▼
ViewModel receives result
  │  fires onSuccess or onError closure
  ▼
View updates UI on main thread
```

---

## Navigation Flow

```
App Launch
    │
    ▼
SplashViewController (2 seconds)
    │
    ├── First time → OnboardingViewController
    │       └── Get Started → RegisterViewController
    │               └── Success → MainTabBarController
    │
    ├── Returning user → LoginViewController
    │       └── Success → MainTabBarController
    │
    └── Already logged in → MainTabBarController
```

---

## Setup

### Requirements
- Xcode 16+
- iOS 15+ simulator or device
- Backend running (Docker or manual)

### Configuration

Open `Constants/Constants.swift` and update the API URL:

```swift
struct API {
    // Use your Mac's IP address (not localhost — simulator won't reach it)
    static let baseURL = "http://YOUR_MAC_IP:8080/api/v1"
}
```

Find your Mac IP:
```bash
ipconfig getifaddr en0
```

### Info.plist — Required for Local Network

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>    <true/>
    <key>NSAllowsLocalNetworking</key>   <true/>
</dict>
<key>NSLocalNetworkUsageDescription</key>
<string>CoreBank needs local network access to connect to the banking server.</string>
```

### Run

```bash
open ios-app/CoreBankingApp.xcodeproj
# Press Cmd+R in Xcode
```

---

## Design System

Based on the AllPay design — blue gradient theme.

```swift
UIColor.primaryBlue   = #2E61FA  ← main blue
UIColor.primaryDark   = #1F47D9  ← dark blue (gradients)
UIColor.primaryLight  = #598AFF  ← light blue (gradients)
UIColor.appBackground = #F7F7FC  ← page background
UIColor.textPrimary   = #1A1A26  ← main text
UIColor.textSecondary = #8C91A1  ← secondary text
UIColor.successGreen  = #33C85A  ← positive amounts
UIColor.errorRed      = #F24040  ← negative amounts
```

---

## API Connection

The app connects ONLY to the Spring Boot Gateway.
It never talks to Node.js or the blockchain directly.

```
iOS App → Spring Boot (8080) → Node.js (3000) → PostgreSQL
                             → Blockchain (3001) → Ethereum
```

All requests include:
```
Authorization: Bearer {spring-boot-jwt-token}
Content-Type: application/json
```
