# Setup

Notes for developers and AI coding agents working on this repo or a fork of it.

## Dependencies

The PublicOS packages come from the PublicOS-dev repos on GitHub as git
dependencies (see `pubspec.yaml`): `publicos_core`, `publicos_web3_bridge`,
`zero_webview_windows`, `zero_video_windows`, `zero_mentions`, and the
`zero_cached_video` / `zero_cached_thumbnail` overrides. `xmtp_plugin` and
`zero_cached_image` come from pub.dev. To work against local checkouts, put
path overrides in a `pubspec_overrides.yaml` (do not commit it).

## Developer gate

`lib/screens/settings_pane.dart`, `_devAddress`. It is the zero address in
this repo. Set it to your own session address to unlock the developer options
(redeploy profile, register DAO) in your build.

## Identifiers a fork must change

- Windows: `windows/runner/Runner.rc` (`CompanyName`, `LegalCopyright`,
  `ProductName`).
- Android: `android/app/build.gradle.kts` (`namespace`, `applicationId`) and
  the package path `android/app/src/main/kotlin/com/example/publicos_desktop/`.
- iOS: `ios/Runner.xcodeproj/project.pbxproj` (`PRODUCT_BUNDLE_IDENTIFIER`).
- macOS: `macos/Runner/Configs/AppInfo.xcconfig` (`PRODUCT_BUNDLE_IDENTIFIER`,
  `PRODUCT_COPYRIGHT`) and `macos/Runner.xcodeproj/project.pbxproj`.
- Linux: `linux/CMakeLists.txt` (`APPLICATION_ID`).

The non-Windows targets still carry the Flutter template `com.example`
identifiers. Windows is the platform this app is built for.

## Messaging DLL

`xmtp_plugin_native.dll` is not produced by `flutter build`. Build it from
the xmtp_plugin repo:

    cd <xmtp_plugin>\rust
    cargo build --release

Use a release DLL with a release app build; do not mix with debug.

## Package a Windows kit

From the repo root:

    powershell -File scripts/package_windows.ps1

It builds the Release app, copies the DLL from
`<xmtp_plugin>\rust\target\release\` beside the exe, adds the VC++ runtime
DLLs app-local, and writes a zip under `dist\`. Options:

- `-XmtpPluginRepo <path>` the xmtp_plugin checkout (default: `..\xmtp_plugin`,
  a sibling of this repo)
- `-SkipBuild` reuse the existing Release folder
- `-AllowStaleDll` package even if the plugin source is newer than the DLL

It needs Visual Studio's VC++ redistributable folder on the machine.

## Windows package identity (optional)

`windows/packaging/` registers the local build as an unsigned sparse package
so Windows hands it `https://publicos.dev/...` and `publicos://` links
(`Register-Identity.ps1`, `Unregister-Identity.ps1`, `AppxManifest.xml`). It
needs Developer Mode and is not required to build or run the app. A fork
should change the `Identity` and `Publisher` values in `AppxManifest.xml`.
