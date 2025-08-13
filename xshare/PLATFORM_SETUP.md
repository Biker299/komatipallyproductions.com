# Platform setup

Follow these steps after `flutter create` and adding the `pubspec.yaml` and `lib/` code.

## iOS
Edit `ios/Runner/Info.plist` and add the following keys:

- NSCameraUsageDescription: "Scan QR codes to connect to sender"
- NSLocalNetworkUsageDescription: "Allow local network connections to transfer files to and from nearby devices."
- NSAppTransportSecurity:
  - NSAllowsArbitraryLoadsInLocalNetworking: true

Example snippet to insert inside the `<dict>`:
```
<key>NSCameraUsageDescription</key>
<string>Scan QR codes to connect to sender</string>
<key>NSLocalNetworkUsageDescription</key>
<string>Allow local network connections to transfer files to and from nearby devices.</string>
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoadsInLocalNetworking</key>
    <true/>
</dict>
```

Notes:
- You do NOT need Bonjour keys unless you add mDNS discovery. QR pairing uses direct IP.
- First time starting a session, iOS may prompt for Local Network access.

## Android
Edit `android/app/src/main/AndroidManifest.xml`:

1) Add permissions inside the `<manifest>` tag:
```
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

2) Allow cleartext traffic for local IPs by setting on the `<application>` element:
```
<application
    android:usesCleartextTraffic="true"
    ...>
```

This is needed because the receiver downloads over `http://<local-ip>`.

## Build and run
- Run on device: `flutter run -d <device_id>`
- Ensure both devices are on the same Wi‑Fi network (or one shares a hotspot and the other connects)

## Troubleshooting
- If the receiver cannot connect: verify both devices are on the same subnet (e.g., 192.168.1.x)
- Some guest networks block peer to peer traffic; use a regular Wi‑Fi or a shared hotspot
- Keep the app in the foreground during large transfers to avoid OS throttling