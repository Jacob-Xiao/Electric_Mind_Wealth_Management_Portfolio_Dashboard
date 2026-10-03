---
title: " Probe Flutter Module"
summary: "The `_probe_flutter/` module is a stock Flutter `probe_app` project scaffold (package `probe_app`, application ID `com.electricmind.probe_app`). It contains only Dart/build configuration and Android platform host files — no Dart business logic, iOS, or other platform folders are present in the evidence. This page documents its surface, Android embedder flow, and change guidance."
generated_by: ax-wiki
symbols:
  - "LaunchTheme"
  - "MainActivity"
  - "NormalTheme"
  - "com.android.application"
  - "com.electricmind.probe_app"
  - "cupertino_icons"
  - "dev.flutter.flutter-gradle-plugin"
  - "dev.flutter.flutter-plugin-loader"
  - "evaluationDependsOn"
  - "flutter.sdk"
  - "flutterEmbedding"
  - "flutter_lints"
  - "flutter_test"
  - "includeBuild"
  - "io.flutter.embedding.android.NormalTheme"
  - "launch_background"
  - "org.jetbrains.kotlin.android"
  - "package com.electricmind.probe_app"
  - "package:flutter_lints/flutter.yaml"
  - "probe_app"
  - "uses-material-design"
symbol_summaries: [{"name":"probe_app","summary":"The Flutter package name declared in `_probe_flutter/pubspec.yaml` and the Android app label; the project is marked `publish_to: 'none'`."},{"name":"MainActivity","summary":"Empty `FlutterActivity` subclass in `_probe_flutter/android/app/src/main/kotlin/com/electricmind/probe_app/MainActivity.kt`; the Android entrypoint with no added channels."},{"name":"com.electricmind.probe_app","summary":"Android namespace and applicationId for the probe app, declared in `_probe_flutter/android/app/build.gradle.kts`."},{"name":"com.android.application","summary":"Android Gradle Plugin pinned to 9.0.1 in `_probe_flutter/android/settings.gradle.kts` and applied in `app/build.gradle.kts`."},{"name":"dev.flutter.flutter-gradle-plugin","summary":"Flutter's Gradle plugin applied in `_probe_flutter/android/app/build.gradle.kts`, supplying SDK/NDK/version defaults."},{"name":"dev.flutter.flutter-plugin-loader","summary":"Flutter plugin loader applied at version 1.0.0 in `_probe_flutter/android/settings.gradle.kts`."},{"name":"org.jetbrains.kotlin.android","summary":"Kotlin Android Gradle plugin pinned to 2.3.20 (`apply false`) in `android/settings.gradle.kts`."},{"name":"LaunchTheme","summary":"Android splash theme in `res/values/styles.xml` and `values-night/styles.xml` that sets `windowBackground` to the launch drawable until the Flutter engine draws."},{"name":"NormalTheme","summary":"Theme applied after process start (V2 embedding) that colors the window behind the Flutter UI in both light and night variants."},{"name":"launch_background","summary":"Layer-list drawable used as the launch splash background; white for light, `?android:colorBackground` for drawable-v21."},{"name":"flutterEmbedding","summary":"Manifest meta-data set to value 2, selecting Flutter's V2 Android embedding and enabling generated plugin registration."},{"name":"flutter.sdk","summary":"Property read from `local.properties` by `settings.gradle.kts`; a missing value fails the build with 'flutter.sdk not set in local.properties'."},{"name":"uses-material-design","summary":"Flutter flag enabled in `pubspec.yaml` so the Material Icons font is bundled with the app."},{"name":"cupertino_icons","summary":"Sole third-party runtime dependency (`^1.0.8`) declared in `_probe_flutter/pubspec.yaml` for iOS-style icons."},{"name":"flutter_lints","summary":"Dev dependency (`^6.0.0`) pulled in via `analysis_options.yaml`'s include of `package:flutter_lints/flutter.yaml` with no rule overrides."},{"name":"flutter_test","summary":"SDK dev dependency declared in `pubspec.yaml`; no test files appear in the supplied evidence."},{"name":"package:flutter_lints/flutter.yaml","summary":"The included lint ruleset in `_probe_flutter/analysis_options.yaml`; run `flutter analyze` to surface its findings."},{"name":"includeBuild","summary":"Gradle directive in `settings.gradle.kts` that composes the Flutter tool's `packages/flutter_tools/gradle` build from the SDK path."},{"name":"evaluationDependsOn","summary":"Gradle configuration in `_probe_flutter/android/build.gradle.kts` making each subproject depend on `:app` evaluation for consistent build directories."}]
sources:
  - "_probe_flutter/README.md"
  - "_probe_flutter/analysis_options.yaml"
  - "_probe_flutter/android/app/build.gradle.kts"
  - "_probe_flutter/android/app/src/debug/AndroidManifest.xml"
  - "_probe_flutter/android/app/src/main/AndroidManifest.xml"
  - "_probe_flutter/android/app/src/main/kotlin/com/electricmind/probe_app/MainActivity.kt"
  - "_probe_flutter/android/app/src/main/res/drawable-v21/launch_background.xml"
  - "_probe_flutter/android/app/src/main/res/drawable/launch_background.xml"
  - "_probe_flutter/android/app/src/main/res/values-night/styles.xml"
  - "_probe_flutter/android/app/src/main/res/values/styles.xml"
  - "_probe_flutter/android/app/src/profile/AndroidManifest.xml"
  - "_probe_flutter/android/build.gradle.kts"
  - "_probe_flutter/android/settings.gradle.kts"
  - "_probe_flutter/pubspec.yaml"
---

# Probe Flutter Module

`_probe_flutter/` is a nearly-untouched Flutter application scaffold generated by `flutter create`. The only declared package is `probe_app` (`_probe_flutter/pubspec.yaml`), a version `1.0.0+1` app that is explicitly not published (`publish_to: 'none'`). Its stated description is the default "A new Flutter project." (`_probe_flutter/README.md`, `_probe_flutter/pubspec.yaml`).

The underscore prefix suggests this is a probe/experimental harness rather than a production app, but nothing in the evidence confirms that intent — verify against the wider repo. No `lib/` Dart source, `integration_test/`, or `test/` files appear in the supplied evidence, so the Dart UI layer is unknown.

Related modules: the production Flutter client is described in [Mobile Module](mobile.md); the overall layout is in [Architecture Overview](../architecture/overview.md).

## Public Surface

There is no Dart-level public API in evidence (no `lib/` files provided). The externally visible surface is entirely build/config:

- **Package metadata** — `name: probe_app`, `publish_to: 'none'`, `version: 1.0.0+1`, SDK constraint `^3.12.0` (`_probe_flutter/pubspec.yaml`).
- **Runtime dependencies** — `flutter` (SDK) and `cupertino_icons: ^1.0.8`.
- **Dev dependencies** — `flutter_test` (SDK) and `flutter_lints: ^6.0.0`.
- **Flutter section** — `uses-material-design: true`; assets and fonts are commented out.
- **Android application ID / namespace** — `com.electricmind.probe_app` (`_probe_flutter/android/app/build.gradle.kts`).

## Internal Flow (Android embedder)

```
Android OS
  └─ MainActivity : FlutterActivity        (MainActivity.kt)
       └─ Flutter engine draws first frame
            └─ LaunchTheme (splash)  ->  NormalTheme (window bg)
```

- `_probe_flutter/android/app/src/main/kotlin/com/electricmind/probe_app/MainActivity.kt` is an empty `FlutterActivity` subclass — it adds no channels or plugins, so the Dart entrypoint is the default `main()` (not visible in evidence).
- The activity is `.MainActivity`, exported, `singleTop`, `taskAffinity=""`, `hardwareAccelerated="true"`, `windowSoftInputMode="adjustResize"`, and declares `android:configChanges` covering orientation/keyboard/screen-size/density/locale/direction/fontScale/uiMode (`_probe_flutter/android/app/src/main/AndroidManifest.xml`).
- Two themes drive launch: `LaunchTheme` sets `android:windowBackground` to `@drawable/launch_background` while the engine boots; `NormalTheme` continues behind the Flutter UI (`.../res/values/styles.xml`, `.../res/values-night/styles.xml`). `launch_background.xml` is a plain `layer-list` with white (light) / `?android:colorBackground` (v21) fill and a commented bitmap slot.
- `android:label` is `probe_app`; `flutterEmbedding` meta-data is `2` (V2 embedding), which the manifest comment ties to `GeneratedPluginRegistrant.java`.
- Debug and profile manifests add only `android.permission.INTERNET`, needed for breakpoints and hot reload (`.../src/debug/AndroidManifest.xml`, `.../src/profile/AndroidManifest.xml`).

### Build toolchain

- `_probe_flutter/android/settings.gradle.kts` reads `local.properties` for `flutter.sdk`, fails with "flutter.sdk not set in local.properties" if missing, includes the Flutter Gradle tooling via `includeBuild`, and pins `com.android.application` 9.0.1 plus `org.jetbrains.kotlin.android` 2.3.20 (both `apply false`).
- `_probe_flutter/android/app/build.gradle.kts` applies `com.android.application` and `dev.flutter.flutter-gradle-plugin`, sets Java/Kotlin targets to 17, and derives `compileSdk`, `ndkVersion`, `minSdk`, `targetSdk`, `versionCode`, `versionName` from the Flutter plugin. Release builds use the debug signing key (a TODO in-file).
- `_probe_flutter/android/build.gradle.kts` relocates all build output to `<repo>/build` via a `../../build` reference relative to `rootProject.layout.buildDirectory`, then wires subprojects to `newBuildDir.dir(project.name)`.

### Static analysis

`_probe_flutter/analysis_options.yaml` includes `package:flutter_lints/flutter.yaml` with no rule overrides; run `flutter analyze` to apply it.

## Dependencies and Boundaries

- **Inbound (external):** the Flutter SDK (pinned via `flutter.sdk` in `local.properties`), the Android Gradle Plugin, Kotlin, and pub.dev packages `cupertino_icons` and `flutter_lints`.
- **No cross-module imports appear in evidence** — this module does not reference `mobile/`, `backend/`, `support/`, or `frontend/`.
- **Boundary with the `frontend/` web app and `mobile/`:** nothing in `_probe_flutter/` shares code with them; treat it as an isolated scaffold.

## Change Guidance

- **Renaming the app:** update `name`/`description` in `_probe_flutter/pubspec.yaml`, `android:label` in `_probe_flutter/android/app/src/main/AndroidManifest.xml`, and the namespace/applicationId pair in `_probe_flutter/android/app/build.gradle.kts`. Note the applicationId carries the generator TODO comment, so renaming is expected.
- **Below Flutter defaults:** minSdk/targetSdk/compileSdk/ndkVersion are intentionally delegated to `flutter.*`; override only when a plugin requires it.
- **Adding dependencies:** edit `pubspec.yaml` and refresh with `flutter pub get` (`flutter pub upgrade --major-versions` and `flutter pub outdated` are referenced inline in that file).
- **Release signing:** replace the debug-key `signingConfig` before shipping; it currently exists only so `flutter run --release` works.
- **Platform support:** only Android host files are in the evidence. If iOS, web, or desktop targets exist they were not supplied — inspect the directory directly before assuming parity.
- **Dart layer unknown:** because `lib/` is absent from the evidence, do not assume entrypoint or widget structure. Run `find _probe_flutter -name '*.dart'` to confirm the actual app code before editing.

See [Development Workflows](../development/workflows.md) for general build/test conventions and [Repository Quickstart](../quickstart.md) for setup.

## Sources

- `_probe_flutter/README.md`
- `_probe_flutter/analysis_options.yaml`
- `_probe_flutter/android/app/build.gradle.kts`
- `_probe_flutter/android/app/src/debug/AndroidManifest.xml`
- `_probe_flutter/android/app/src/main/AndroidManifest.xml`
- `_probe_flutter/android/app/src/main/kotlin/com/electricmind/probe_app/MainActivity.kt`
- `_probe_flutter/android/app/src/main/res/drawable-v21/launch_background.xml`
- `_probe_flutter/android/app/src/main/res/drawable/launch_background.xml`
- `_probe_flutter/android/app/src/main/res/values-night/styles.xml`
- `_probe_flutter/android/app/src/main/res/values/styles.xml`
- `_probe_flutter/android/app/src/profile/AndroidManifest.xml`
- `_probe_flutter/android/build.gradle.kts`
- `_probe_flutter/android/settings.gradle.kts`
- `_probe_flutter/pubspec.yaml`
