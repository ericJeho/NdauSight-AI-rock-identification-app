# NdauSight AI

Photograph a rock in the field, get an AI read-out of the rock type, visible
minerals, and estimated precious-mineral potential — with GPS mapping, offline
support, and a community discovery feed.

This repository is a **working Flutter app foundation** (Android-first, also
builds for iOS and web) plus a **reference FastAPI backend**. The AI analysis
runs in one of two modes, switchable in **Settings**:

- **Demo mode (default):** realistic mock scans so the whole app works
  end-to-end with no server — great for demos and UI development.
- **Live mode:** photos are POSTed to your own vision backend. The app UI is
  complete; you supply the trained model behind the documented API contract.

> ⚠️ Mineral-potential percentages are **indicative only**. No phone photo can
> replace assay: the app itself always recommends confirming with XRF or a
> laboratory test.

---

## Quick start

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install)
(3.19+) installed.

```bash
cd ndausight

# 1. Generate the native platform shells (android/ios/web).
#    This creates the gradle/Xcode projects around the provided lib/ code.
flutter create . --platforms=android,ios,web --org com.ndausight

# 2. Re-apply the Android permissions (step 1 overwrites the manifest).
#    Copy the <uses-permission> block and <queries> block from
#    android/app/src/main/AndroidManifest.xml in this repo into the generated
#    manifest — or just keep this repo's version.

# 3. Install packages and run on a connected device / emulator.
flutter pub get
flutter run
```

Then use **Scan a Rock** to capture photos and see a result. To go live, open
**Settings → Use real vision backend** and point it at your server.

---

## Get an installable APK

The native Android shell (Gradle project) isn't checked in — it's generated —
so building the `.apk` happens in one of three ways. Pick whichever suits you.
All produce a **debug-signed release APK** you can sideload onto any Android
phone (fine for testing and sharing; re-sign with your own key for the Play
Store).

### Option A — GitHub Actions (no local setup) ✅ easiest

1. Create a new GitHub repo and push this project to it:
   ```bash
   cd ndausight
   git init && git add . && git commit -m "NdauSight AI"
   git branch -M main
   git remote add origin https://github.com/<you>/ndausight.git
   git push -u origin main
   ```
2. The included workflow (`.github/workflows/build-apk.yml`) runs automatically.
   Open the repo's **Actions** tab, wait for the build to finish (~5 min).
3. Download the **`ndausight-release-apk`** artifact — that's your APK.
   (A smaller per-device **`ndausight-split-apks`** set is attached too.)

You can also trigger it manually from Actions → *Build Android APK* → **Run
workflow**.

### Option B — Codemagic (no local setup, emails you the APK)

Sign in at [codemagic.io](https://codemagic.io) with your Git provider, add the
repo, and start a build. `codemagic.yaml` is already configured to build the APK
and email it to you on success.

### Option C — Build locally

With the Flutter SDK, a Java 17 JDK, and the Android SDK installed (all bundled
with Android Studio), just run the helper script from the project root:

```bash
./build_apk.sh
```

It writes the APK to `build/app/outputs/flutter-apk/app-release.apk`. Copy that
to your phone and open it to install (enable "Install unknown apps" for your
file manager first).

> **Installing on a phone:** transfer the `.apk` via USB, email, or cloud drive,
> tap it, and allow installation from unknown sources when prompted.

> **Why `flutter create .`?** The platform folders (gradle files, Xcode
> project, `web/index.html`) are large, machine-generated, and version-specific,
> so they aren't checked in. `flutter create .` regenerates them around the
> app code without touching `lib/`. The one file to preserve afterwards is the
> Android manifest (permissions).

---

## Feature map

Every core feature from the product brief is wired into the app:

| Brief feature | Where it lives |
|---|---|
| 1. Take a photo (multi-angle guidance) | `screens/capture_screen.dart` |
| 2. AI rock & mineral identification | `services/ai_service.dart` → results |
| 3. Precious-mineral probability (Au, Ag, Cu, Li, REE, gems) | `models/scan_result.dart`, results screen |
| 4. Confidence score | `ConfidenceRing`, `ProbabilityBar` widgets |
| 5. GPS geological mapping + belts + nearby pins | `screens/map_screen.dart` |
| 6. AI recommendations | `ai_service.dart` profiles → results screen |
| 7. Offline mode + sync | `services/storage_service.dart`, `sync_service.dart` |
| 8. Community discoveries (share + rate) | `screens/community_screen.dart` |

Future hardware (Bluetooth XRF, spectrometers, metal detectors, drones) plugs in
as additional `services/` with the same repository pattern used by `AiService`.

---

## Branding — launcher icon & splash

The app ships with an original icon and splash: a faceted gold quartz-point
crystal on a slate background, framed by a subtle scan reticle (mineral +
AI detection).

- **Source art** is generated by [`tool/generate_brand_assets.py`](tool/generate_brand_assets.py),
  which writes editable SVGs and the PNGs into `assets/icon/` and
  `assets/splash/`. Regenerate anytime with:
  ```bash
  pip install cairosvg
  python3 tool/generate_brand_assets.py
  ```
- **Applied to the app** by `flutter_launcher_icons` and
  `flutter_native_splash`, configured in `pubspec.yaml`. All three build paths
  (GitHub Actions, Codemagic, `build_apk.sh`) run these generators automatically
  before the APK is built, so the finished app has a proper adaptive launcher
  icon and a branded launch screen. To apply them by hand:
  ```bash
  dart run flutter_native_splash:create
  dart run flutter_launcher_icons
  ```

The launcher icon uses an **adaptive** foreground/background on Android so it
looks correct under any launcher mask (circle, squircle, rounded square).

---

## Architecture

```
lib/
├── main.dart                 App bootstrap + Provider wiring
├── models/                   Plain Dart models with JSON (no codegen needed)
│   ├── scan_result.dart      Detection, MineralPotential, ScanResult
│   └── discovery.dart        Community discovery + ratings
├── services/
│   ├── app_settings.dart     Persisted settings (backend toggle, identity)
│   ├── ai_service.dart       Mock + real-backend analysis (swap point)
│   ├── location_service.dart GPS via geolocator (graceful permission flow)
│   ├── storage_service.dart  Offline-first Hive storage (scans + discoveries)
│   ├── sync_service.dart     Connectivity-aware sync queue
│   └── scan_repository.dart  Central ChangeNotifier state holder
├── screens/                  Scan home, capture, results, map, community, settings
├── widgets/                  ProbabilityBar, ConfidenceRing, badges, empty states
└── theme/app_theme.dart      Earthy geological palette + Material 3 theme
```

State is managed with **Provider**. `ScanRepository` is the single source of
truth; screens `watch` it and call methods like `analyzePhotos`, `shareScan`,
`syncNow`. Persistence is **offline-first** — every scan is saved locally
immediately, and syncing is a separate, connectivity-gated step.

---

## Backend contract

When live mode is on, the app calls:

**`POST {backendUrl}/analyze`** — `multipart/form-data`
- `images`: one or more image files
- `latitude`, `longitude`: form fields (optional)

Expected `200` JSON response:

```json
{
  "rockType": "Quartz Vein",
  "rockConfidence": 96,
  "detectedMinerals": [
    { "name": "Quartz", "confidence": 98 },
    { "name": "Iron Oxides", "confidence": 87 }
  ],
  "potentials": [
    { "mineral": "Gold", "probability": 71 },
    { "mineral": "Copper", "probability": 24 }
  ],
  "recommendations": ["High-priority sample — collect fresh rock chips."]
}
```

**`POST {backendUrl}/scans`** — JSON body (a full scan) for cloud sync.

A runnable reference implementation with this exact schema is in
[`backend/main.py`](backend/main.py):

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```

Replace the placeholder in `/analyze` with your real inference (YOLO mineral
detection + ViT rock classifier, fused with GPS and geological layers).

---

## iOS notes

Live camera/location on iOS need these keys in `ios/Runner/Info.plist` after
`flutter create`:

```xml
<key>NSCameraUsageDescription</key>
<string>Photograph rock samples for AI mineral identification.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Select existing rock photos to analyse.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Record where each sample was collected for geological mapping.</string>
```

---

## Tests

```bash
flutter test
```

`test/models_test.dart` covers the scan model: top-potential selection,
priority thresholds, and JSON round-tripping.

---

## Roadmap

- Real trained vision models (rock ViT + mineral YOLO) behind the existing API.
- Verified-sample feedback loop: user assay results → model improvement.
- Offline map tile caching for truly remote areas.
- Hardware integrations: Bluetooth XRF, portable spectrometers, drone imagery.
- Auth + real community backend (currently local + seed data).
- Premium/enterprise tiers: exportable PDF reports, geological map overlays.
