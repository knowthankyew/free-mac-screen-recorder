# Legal, Privacy, and Third-Party Attribution Notice

**Free Mac Screen Recorder**  
Copyright © 2026 penguinpecker and contributors  
Repository: [https://github.com/penguinpecker/free-mac-screen-recorder](https://github.com/penguinpecker/free-mac-screen-recorder)  
Portfolio Reference: [https://github.com/knowthankyew/free-mac-screen-recorder](https://github.com/knowthankyew/free-mac-screen-recorder)  

---

## 1. Functional Scope Notice
Free Mac Screen Recorder is a native macOS utility application designed to capture display, window, application, and region video alongside microphone and system audio streams. All captured media is encoded via Apple VideoToolbox and saved directly to the user's local filesystem.

## 2. Consumer Privacy Defaults & Air-Gap Invariant
This application conforms to the `knowthankyew` Consumer-Safe Zero-Egress specification:
- **Zero Network Egress (`deny`):** The application does not bundle networking frameworks, establish remote socket connections, or perform outbound HTTP/HTTPS requests.
- **Zero Cloud Persistence:** Media is never uploaded to remote servers, cloud buckets, or third-party hosting services.
- **Zero Remote Telemetry:** The application does not bundle analytics SDKs, trackers, or remote error reporting pipelines. Diagnostics are handled exclusively through Apple's local unified logging subsystem (`os.Logger`).
- **Programmatic Claims Verification:** User-facing privacy assertions are derived directly at runtime from `PrivacyClaimsProvider`.

## 3. Sensitive Input & Password Protection
When the optional keystroke overlay is active:
- Keystrokes are inspected transiently in memory solely to render the floating visual indicator (`KeystrokeOverlayController`) and are never written to disk or logged.
- The overlay actively monitors `IsSecureEventInputEnabled()`. When the active application indicates secure event input (such as entering passwords, PINs, or master credentials in browsers, password managers, or terminal prompts), the keystroke overlay is immediately suppressed and faded out to prevent credential exposure in captured frames.

## 4. Software Bill of Materials (SBOM) & Supply Chain
- **Zero Third-Party Dependencies:** Free Mac Screen Recorder contains zero external Swift Package Manager dependencies. The dependency attack surface is limited strictly to Apple platform SDKs.
- **CycloneDX SBOM:** A standardized CycloneDX JSON Software Bill of Materials (`bom.json`) is generated during the application build pipeline (`Scripts/build-app.sh`) and packaged into `Contents/Resources/bom.json`.

## 5. Third-Party & Framework Attribution
- **Aperture by Sindre Sorhus (MIT License):** Referenced as an architectural design pattern for integrating ScreenCaptureKit with AVAssetWriter.
- **Apple macOS SDKs:** ScreenCaptureKit, AVFoundation, VideoToolbox, AppKit, SwiftUI, and Carbon HIToolbox.

See [LICENSE](./LICENSE) for the root MIT license terms.
