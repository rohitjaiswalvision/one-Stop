# 📱 One Stop VV — Project Context Document

> **Purpose:** This file is for any AI assistant (Antigravity, Gemini, Claude, Copilot, etc.) to quickly understand the full context of this Flutter project before making any changes.

---

## 🏢 Project Overview

| Field | Value |
|---|---|
| **App Name** | One Stop VV |
| **Flutter Package** | `sixam_mart` |
| **Version** | 1.0.0+1 |
| **Flutter SDK** | ^3.10.0 |
| **Base Template** | 6amMart (multi-vendor marketplace) by 6amtech |
| **Developer/Owner** | Rohit Jaiswal (Vision Vivante) |
| **GitHub Repo** | `rohitjaiswalvision/one-Stop` |
| **Android Package** | `com.visionvivante.onestop` |

---

## 🌐 Backend & APIs

| Field | Value |
|---|---|
| **Backend URL** | `https://onestop.visionvivante.in` |
| **Backend Panel** | 6amMart Admin Panel (Laravel-based) |
| **API Format** | `/api/v1/...` (REST JSON) |
| **API Timeout** | 60 seconds |

---

## 🔑 Third-Party Keys & Services

| Service | Key / ID |
|---|---|
| **Firebase Project** | `stackmart-500c7` |
| **Firebase Sender ID** | `491987943015` |
| **Android Maps API Key** | `AIzaSyD14lEm23LccLi4rwzz9K5GP-e3qVkr8jE` |
| **Google Server Client ID** | `491987943015-agln6biv84krpnngdphj87jkko7r9lb8.apps.googleusercontent.com` |
| **Facebook App ID** | `380903914182154` |
| **Android Firebase App ID** | `1:491987943015:android:a6fb4303cc4bf3d18f1ec2` |

> ⚠️ **IMPORTANT:** Never commit real API keys to version control. These are in native config files (`google-services.json`, `GoogleService-Info.plist`).

---

## 📂 Project Structure

```
lib/
├── api/                        # API client, local client, API checker
│   ├── api_client.dart         # Main HTTP client (uses GetX + dio-like requests)
│   └── local_client.dart       # Local cache client
├── common/                     # Shared/generic widgets and controllers
│   ├── controllers/
│   │   └── theme_controller.dart
│   └── widgets/
│       ├── card_design/
│       │   └── item_card.dart  # Product card used in horizontal lists
│       ├── custom_image.dart   # CachedNetworkImage wrapper
│       ├── item_bottom_sheet.dart
│       └── menu_drawer.dart
├── features/                   # Feature-first architecture (40 modules)
│   ├── address/
│   ├── auth/
│   │   └── screens/
│   │       └── sign_in_screen.dart  # ← MODIFIED: language switcher added to AppBar
│   ├── cart/
│   ├── checkout/
│   ├── dashboard/
│   │   └── screens/
│   │       └── dashboard_screen.dart
│   ├── home/
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   └── modules/
│   │   │       ├── food_home_screen.dart
│   │   │       ├── grocery_home_screen.dart
│   │   │       └── shop_home_screen.dart  # eCommerce home
│   │   └── widgets/
│   │       └── views/
│   │           ├── best_reviewed_item_view.dart  # NOT in ShopHomeScreen by default
│   │           ├── most_popular_item_view.dart
│   │           └── ...
│   ├── item/
│   │   └── widgets/
│   │       └── item_image_view_widget.dart  # ← MODIFIED: BoxFit.contain fix
│   ├── language/
│   │   ├── controllers/
│   │   │   └── language_controller.dart (LocalizationController)
│   │   └── widgets/
│   │       ├── language_bottom_sheet_widget.dart  # Bottom sheet for language selection
│   │       └── language_card_widget.dart          # ← MODIFIED: Expanded fix for overflow
│   ├── splash/
│   │   └── controllers/
│   │       └── splash_controller.dart   # Central routing logic & module management
│   ├── store/
│   │   └── widgets/
│   │       └── store_description_view_widget.dart  # ← MODIFIED: overflow fix
│   └── ...
├── helper/
│   ├── route_helper.dart        # All named routes defined here
│   ├── auth_helper.dart
│   ├── responsive_helper.dart   # isDesktop / isMobile / isWeb checks
│   └── ...
├── theme/
│   ├── light_theme.dart
│   └── dark_theme.dart
└── util/
    ├── app_constants.dart       # ← KEY FILE: API URLs, language list, module names
    ├── dimensions.dart          # Spacing and font size constants
    ├── images.dart              # ← MODIFIED: Images.french added
    ├── messages.dart            # GetX translations loader
    └── styles.dart              # Text styles (robotoBold, robotoRegular, etc.)

assets/
├── image/                      # All image assets (flags, icons, placeholders)
│   ├── english.png
│   ├── french.png              # ← ADDED (currently uses english flag as placeholder)
│   ├── arabic.png
│   ├── spanish.png
│   └── ...
├── language/                   # Translation JSON files
│   ├── en.json                 # English (source of truth)
│   ├── fr.json                 # ← ADDED (currently mirrors en.json, needs translation)
│   ├── ar.json
│   ├── bn.json
│   └── es.json
├── font/                       # Roboto font family
└── json/                       # Other JSON data files

android/
└── app/src/main/AndroidManifest.xml   # Google Maps API key declared here

ios/
└── GoogleService-Info.plist           # iOS Firebase config
```

---

## 🧩 Module System (Business Modules)

The app supports multiple business modules. Users are shown a **module selection screen** only when **more than one module is active** in a zone.

| Module Key | Description |
|---|---|
| `food` | Food delivery |
| `grocery` | Grocery delivery |
| `ecommerce` | General e-commerce / shop |
| `pharmacy` | Pharmacy / medicine |
| `parcel` | Parcel/courier service |
| `rental` | Car rental (taxi) |
| `ride-share` | Ride sharing |
| `service` | Service booking |

**Module routing logic:** `SplashController.route()` → `SplashRouteHelper.dart`

If only one module exists in the zone, the app **skips module selection** and goes directly to that module's home screen.

---

## 🌍 Languages Supported

| Language | Code | File |
|---|---|---|
| English | `en` (US) | `assets/language/en.json` |
| French | `fr` (FR) | `assets/language/fr.json` ← added, needs translation |
| Arabic | `ar` (SA) | `assets/language/ar.json` |
| Spanish | `es` (ES) | `assets/language/es.json` |
| Bengali | `bn` (BN) | `assets/language/bn.json` |

**Language switching:** Available from the **Login Screen AppBar** (globe icon) and **Profile > Settings**. Uses `LanguageBottomSheetWidget`.

---

## 🏗️ Architecture & Key Patterns

| Pattern | Detail |
|---|---|
| **State Management** | GetX (`Get.find<XController>()`) |
| **Navigation** | GetX named routes via `RouteHelper` |
| **Dependency Injection** | GetX (`Get.put`, `Get.lazyPut`) initialized in `helper/get_di.dart` |
| **API Calls** | `ApiClient` (wraps HTTP with auth headers, zone ID, module ID) |
| **Image Loading** | `CachedNetworkImage` via `CustomImage` widget |
| **Theming** | Light/Dark via `ThemeController`, toggled from profile settings |
| **Responsive** | `ResponsiveHelper.isDesktop/isMobile/isWeb()` |
| **Font** | Roboto (weights 400, 500, 700, 900) |

---

## ✅ Modifications Made So Far (Changelog)

| File | Change |
|---|---|
| `lib/api/api_client.dart` | API timeout increased from 40s → 60s |
| `lib/features/home/screens/home_screen.dart` | Minor whitespace fix |
| `lib/features/auth/screens/sign_in_screen.dart` | Added language globe icon button to AppBar (opens `LanguageBottomSheetWidget`) |
| `lib/features/store/widgets/store_description_view_widget.dart` | Fixed UI overflow with `Expanded` |
| `lib/features/item/widgets/item_image_view_widget.dart` | Applied `BoxFit.contain` to fix image rendering |
| `lib/features/language/widgets/language_card_widget.dart` | Wrapped language name `Text` in `Expanded` to fix RenderFlex overflow |
| `lib/util/app_constants.dart` | Added French (`fr`, FR) to `AppConstants.languages` list |
| `lib/util/images.dart` | Added `Images.french` constant pointing to `assets/image/french.png` |
| `assets/image/french.png` | Added (currently a copy of english.png — needs real French flag) |
| `assets/language/fr.json` | Added (currently mirrors `en.json` — needs French translation) |

---

## 🚧 Known Issues / TODO

- [ ] `assets/image/french.png` — Replace with actual French flag PNG image
- [ ] `assets/language/fr.json` — Translate all string values to French
- [ ] Google Maps not showing — Check Google Cloud Console: enable "Maps SDK for Android", link a billing account, verify SHA-1 fingerprint for API key
- [ ] App jumps directly to eCommerce module — This is correct behavior when only one module is configured in the zone. Add a second module from the Admin Panel to see module selection screen
- [ ] Performance warning: `Skipped 52 frames` / `performTraversals: cancelAndRedraw` — Investigate `DashboardScreen` and `RunningOrderViewWidget` for layout constraint conflicts

---

## 📱 Test Device

| Field | Value |
|---|---|
| **Device** | RMX3782 (Realme) |
| **Platform** | Android |
| **Renderer** | Impeller (Vulkan) |

---

## 🔗 Useful Entry Points for AI

| Task | Start Here |
|---|---|
| Change API base URL | `lib/util/app_constants.dart` → `baseUrl` |
| Add a new language | `app_constants.dart` (languages list) + `images.dart` + add `assets/language/xx.json` |
| Add a new screen/route | `lib/helper/route_helper.dart` |
| Modify home layout for eCommerce | `lib/features/home/screens/modules/shop_home_screen.dart` |
| Modify home layout for Food | `lib/features/home/screens/modules/food_home_screen.dart` |
| Change app theme colors | `lib/theme/light_theme.dart` or `dark_theme.dart` |
| Add a new API endpoint | `lib/util/app_constants.dart` (add URI) + relevant repository file |
| Change splash/onboarding flow | `lib/features/splash/controllers/splash_controller.dart` |
