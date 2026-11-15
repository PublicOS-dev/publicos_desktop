# PublicOS Desktop

The PublicOS app for Windows, built with Flutter.

Public source under the Business Source License 1.1. Free to use for anything built on the PublicOS network. Each version becomes AGPL-3.0-or-later four years after its release. See [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md).

## Build

- Flutter with a Dart SDK matching `^3.8.1` (the `environment` constraint in `pubspec.yaml`).
- Visual Studio with the C++ desktop workload. The embedded webview (`zero_webview_windows`) builds as C++23.
- The messaging library `xmtp_plugin_native.dll` is not produced by the Flutter build. Build it from the Rust code in the xmtp_plugin repo with `cargo build --release`. The packaging script `scripts/package_windows.ps1` copies it beside the exe.

Step by step, and what a fork must change: [SETUP.md](SETUP.md).

## Name

The name "PublicOS" is used only by the official apps. If you publish a fork, give it its own name. The rules: https://publicos.dev/library/name-and-phrases/

## Docs

https://publicos.dev/library/
