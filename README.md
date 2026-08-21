# Empire Legacy — Phase 1 Progression Build

An original offline-first Android business tycoon built with Godot and GDScript.

## Working features

- Responsive portrait mobile interface
- Active income through deal tapping
- Five original businesses
- Business purchase and upgrade progression
- Live passive income
- Net-worth calculation
- Automatic local save every 10 seconds
- Offline earnings with an 8-hour cap
- First-run guided tutorial
- Seven-day escalating daily reward streak
- Five persistent achievements
- Business milestones at levels 5, 10 and 25
- Dependency-free generated sound effects
- Optional haptic feedback with saved settings
- Original scalable app icon and splash screen
- Preconfigured Android debug export preset
- Automatic GitHub Actions APK build
- Local Windows and Linux/macOS build scripts
- Player statistics and protected reset flow

## Run in Godot

1. Install the current stable Godot 4 release.
2. Import `project.godot` from this folder.
3. Press **F6/F5** to run the project.

The project uses no external assets or plugins, so it should open without dependency installation.

## Android export

1. Install Godot Android export templates.
2. Configure OpenJDK 17 and the Android SDK in Godot Editor Settings.
3. Add an Android export preset.
4. Set a unique package ID, for example `com.yourstudio.empirelegacy`.
5. Export an APK for device testing or an AAB for Google Play.

For a 2026 Play Store release, configure the Android project to target the API level currently required by Google Play.

## Project structure

```text
empire-legacy/
├── project.godot
├── assets/
│   └── icon.svg
├── docs/
│   └── ANDROID_EXPORT.md
├── export_presets.cfg
├── .github/workflows/
│   └── android-debug.yml
├── scenes/
│   └── main.tscn
└── scripts/
    ├── game_state.gd
    ├── main.gd
    ├── build_android_debug.sh
    └── build_android_debug.ps1
```

## Phase 1 next work

- Balance the first 30–60 minutes of progression
- Export and test on multiple Android screen sizes
- Add richer achievement rewards and business detail views
- Add accessibility and localization foundations

The stock market, crypto, real estate, employees, banking, luxury assets and monetization belong to later phases and are intentionally not included in this foundation.
