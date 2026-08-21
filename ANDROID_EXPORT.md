# Android build and export

## One-time setup

1. Install the current stable Godot 4 release and its matching export templates.
2. Install OpenJDK 17.
3. Install Android Studio and the Android SDK.
4. In Godot, open **Editor Settings → Export → Android** and set the Java SDK and Android SDK paths.
5. Import this project's `project.godot`.

## Test APK

1. Open **Project → Export**.
2. Add an **Android** preset.
3. Set a unique package name such as `com.yourstudio.empirelegacy`.
4. Confirm portrait orientation and ARM64 support.
5. Export a debug APK and install it on a physical phone.

The included `export_presets.cfg` already contains an Android debug preset using ARM64, minimum Android 7.0/API 24 and target API 36. Change `package/unique_name` before public release.

### Automatic cloud build

The project includes `.github/workflows/android-debug.yml`.

1. Create an empty GitHub repository.
2. Upload the **contents** of the `empire-legacy` folder to the repository root.
3. Open the repository's **Actions** tab.
4. Select **Build Android APK** and click **Run workflow**.
5. When the run finishes, download `empire-legacy-android-debug` from the Artifacts section.
6. Extract the artifact ZIP to obtain the installable APK.

The workflow also runs automatically after pushes to the `main` branch. It creates a debug APK for testing; it does not contain release signing credentials.

### Local command-line build

- Linux/macOS: run `bash scripts/build_android_debug.sh`.
- Windows PowerShell: run `powershell -ExecutionPolicy Bypass -File scripts/build_android_debug.ps1`.

Both scripts require Godot 4, matching export templates and Android SDK paths configured in Godot.

## Google Play AAB

1. Create a private release keystore and keep it outside the project.
2. Configure the release keystore in the Android export preset.
3. Use a unique application ID that you will never reuse for a different app.
4. Target Android API 36 or the newer level required by Google Play at submission time.
5. Export an Android App Bundle (`.aab`).
6. Test the AAB through Play Console internal testing before production release.

## Test checklist

- Fresh install starts at $2,500.
- Tutorial appears only once.
- Daily reward cannot be claimed twice on the same day.
- Cash and businesses return after closing and reopening the app.
- Offline earnings appear after leaving the app closed.
- Sound and vibration toggles remain saved.
- UI fits small, tall and tablet screens without horizontal scrolling.
- Reset requires confirmation and clears all local progress.

Do not commit a release keystore, passwords, Play credentials or signing secrets into this project.
