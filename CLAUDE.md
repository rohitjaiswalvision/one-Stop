# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **One Stop VV** (package name `sixam_mart`) — a Flutter multi-vendor super-app that bundles several service **modules** into one client: Food, Grocery, eCommerce, Pharmacy, Parcel delivery, Rental/Taxi, and Ride-share. The active module is selected at runtime and heavily influences which screens, controllers, and API responses are used, so many features branch on the current module type.

- Backend API base URL: `AppConstants.baseUrl` in `lib/util/app_constants.dart` (currently `https://onestop.visionvivante.in`). All endpoint URIs are constants in that same file.
- Targets Android, iOS, and Web (the codebase branches on `GetPlatform.isWeb` / `ResponsiveHelper` frequently — web is a first-class target, not an afterthought).

## Commands

```bash
flutter pub get                 # install dependencies
flutter analyze                 # static analysis / lint (use this to find compile errors)
flutter run                     # run on a connected device/emulator
flutter run -d chrome           # run the web build
flutter build apk               # Android release build
flutter build web               # web build
flutter test                    # run all tests
flutter test test/path_test.dart -n "test name"   # run a single test by name
```

### Code generation (Drift)

Local caching uses **Drift** (`lib/local/cache_response.dart`). The generated `*.g.dart` files are required to compile and are produced by `drift_dev` + `build_runner`:

```bash
dart run build_runner build         # regenerate generated code
dart run build_runner watch         # regenerate on change
```

If you see errors about undefined `CacheResponseCompanion` / `CacheResponseData`, the generated `lib/local/cache_response.g.dart` is missing — regenerate it. `drift_dev` must be present in `dev_dependencies` for generation to produce any output.

## Architecture

### Feature-first + layered (clean-ish) architecture

Almost all product code lives under `lib/features/<feature>/`, and each feature repeats the same layered structure:

```
features/<feature>/
  controllers/    # GetX controllers — UI state + orchestration
  domain/
    models/         # data models with manual fromJson/toJson (see below)
    repositories/   # <name>_repository.dart + <name>_repository_interface.dart — raw API/data access
    services/       # <name>_service.dart + <name>_service_interface.dart — business logic over repositories
  screens/        # full-page widgets
  widgets/        # feature-scoped reusable widgets
```

The dependency flow is **Controller → Service (interface) → Repository (interface) → ApiClient**. Repositories and services are always coded against their `*_interface.dart` abstraction, and the concrete implementation is bound in DI. When adding a feature, follow this exact shape and register all four (repo, repo interface impl, service, controller) in DI.

### Dependency injection — `lib/helper/get_di.dart`

There is **no build-time DI framework**; everything is wired manually with GetX in `init()` inside `lib/helper/get_di.dart`, called from `main()` before `runApp`. `ApiClient` and `SharedPreferences` are registered first, then each feature registers its repository → service → controller via `Get.lazyPut`/`Get.put`. Any new controller/service/repo must be added here or `Get.find()` will throw at runtime.

### State management & navigation — GetX everywhere

- State: `GetxController` + `Obx`/`GetBuilder`. There are ~50 controllers, one or more per feature.
- Navigation: centralized in `lib/helper/route_helper.dart` (named routes). Add new routes there rather than pushing `MaterialPageRoute` inline.
- Localization: strings use GetX `.tr` extension; translation maps live under `lib/util/messages.dart` and the language feature.

### Networking — `lib/api/`

- `api_client.dart` — `ApiClient extends GetxService`, wraps GetConnect HTTP. Injects auth token, language, module ID, zone, and location headers automatically on every request. Use its `getData/postData/putData/deleteData/postMultipartData` methods rather than raw `http`.
- `api_checker.dart` — centralized response/error handling (auth expiry, error snackbars).
- `local_client.dart` — read-through/write cache layer: on web it caches to `SharedPreferences`; on mobile it caches API responses into the Drift DB (`DbHelper` / `AppDatabase`). Controlled by `DataSourceEnum` (`client` = network, `local` = cache).

### Models — manual JSON, not code-generated

Data models use **hand-written `fromJson(Map<String,dynamic>)` constructors and `toJson()` methods**. Do **not** introduce `@JsonSerializable` / `json_serializable` — that generator is not a dependency, and mixing it in breaks the build. Match the existing manual pattern (see `lib/features/splash/domain/models/landing_model.dart` for the canonical style).

### Cross-cutting locations

- `lib/util/` — `app_constants.dart` (all API URIs + feature flags), `dimensions.dart`, `styles.dart`, `images.dart`, `messages.dart`.
- `lib/helper/` — stateless utility helpers (address, auth, date, notification, responsive, route, etc.).
- `lib/common/` — shared widgets, models, controllers, and enums used across features.
- `lib/theme/` — light/dark themes, toggled via `ThemeController`.

### Platform integrations

Firebase (Core, Messaging, Auth), Google Maps + Geolocator (used by location, order tracking, and the ride/taxi modules for polylines and live tracking), and social/payment SDKs are initialized in `main.dart`. Firebase web options are inlined in `main()`; mobile uses platform config files.
do the changes in the androidmanifetsfile = true 
