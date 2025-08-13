# SAR SHARE — Lossless Photo/Video Transfer (iOS & Android)

SAR SHARE is a simple, privacy-friendly app that lets you send original photos and videos between iPhone and Android with zero quality loss. It runs a local HTTP server on the sender device and the receiver downloads the original files over the same Wi‑Fi network. Pairing is done via a QR code or by pasting a link.

## Highlights
- Original files only — no compression, no re-encoding
- Works offline on local Wi‑Fi (no internet required)
- Cross‑platform: iOS and Android using Flutter
- Simple QR pairing and progress indicators
- Streams files efficiently to handle large videos

## How it works
- Sender selects photos/videos in the app
- App starts a local HTTP server and shows a QR code containing a one‑time session URL (with a secret token)
- Receiver scans the QR code (or pastes the URL) and downloads the files directly from the sender device over the LAN

This approach avoids any quality loss because the receiver gets the exact original bytes.

## Requirements
- Both devices must be on the same Wi‑Fi network (or personal hotspot)
- iOS 14+ and Android 8.0+

## Project structure
```
xshare/
  lib/
    main.dart
    ui/
      send_page.dart
      receive_page.dart
    transfer/
      local_http_server.dart
      remote_client.dart
  pubspec.yaml
  PLATFORM_SETUP.md
```

## Getting started
1) Install Flutter (3.22+ recommended). See Flutter install docs.
2) Create a Flutter project (if you want to use this folder directly, you can run inside `xshare`):
   - Option A (use this as a project folder):
     - Open this `xshare` directory in your IDE.
     - Run `flutter pub get`.
   - Option B (create fresh, then copy):
     - `flutter create xshare`
     - Copy the `lib/`, `pubspec.yaml`, and `PLATFORM_SETUP.md` from this workspace into your new project.
3) Follow `PLATFORM_SETUP.md` to configure iOS and Android permissions (camera, local network, cleartext HTTP for local IPs).
4) Run on device:
   - iOS: `flutter run -d <ios_device>`
   - Android: `flutter run -d <android_device>`

## Usage
- Sender tab:
  - Tap “Select files” and choose photos/videos
  - Tap “Start session”
  - A QR code and link appear; share the link or have the receiver scan the QR
- Receiver tab:
  - Tap “Scan QR” or paste the link
  - Select files to download. Downloads save into the app’s documents folder; you can open them from the app

Notes:
- On iOS, the first time you start a session, the OS will ask for Local Network access.
- For very large files, keep the app in the foreground and the screen awake for best performance.

## Security & privacy
- The session link contains a random token that must match or the server won’t respond.
- Transfers happen only over your local network. No internet server is involved.

## Limitations / roadmap
- Currently optimized for same‑network transfers. Internet relay is not included.
- Optional ZIP “download all” is not enabled to avoid memory usage; individual files download as-is.

## License
MIT