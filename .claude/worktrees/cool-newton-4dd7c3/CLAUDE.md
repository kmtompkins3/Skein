# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Projects in This Repo

| Project | Status | Entry point | PRD | Tasks |
|---------|--------|-------------|-----|-------|
| Web app (Android Chrome) | MVP complete | `src/index.html` | `docs/PRD.md` | `docs/tasks.md` |
| iOS native app | **Active development** | `ios/` (to be created) | `docs/PRD_iOS_Native.md` | `docs/TASKS_iOS_Native.md` |

---

## iOS Native App

### Architecture

MVVM, single Xcode project targeting iOS 17+. Folder layout inside the Xcode project:

```
Models/       ← SwiftData @Model classes (Project, Tag, WriteEvent)
Views/        ← SwiftUI views
ViewModels/   ← ObservableObject / @Observable view models
Services/     ← NFCService, ImageStorageService
```

**SwiftData model graph:**

```
Project  1──▶  [Tag]  1──▶  [WriteEvent]
```

- `Project`: id, name, patternLink?, imagePath?, startDate, endDate?, isCompleted, tags
- `Tag`: id, notes, firstWriteAt, lastWriteAt, writeEvents
- `WriteEvent`: id, timestamp, noteContent

Images are stored as JPEG files at `<Documents>/images/<UUID>.jpg`; only the filename is persisted in the model.

### Build & Test

NFC is unavailable on the iOS Simulator — all NFC flows require a **physical iPhone running iOS 17+**.

```bash
# Build (Simulator, for UI testing only)
xcodebuild -scheme NFCStitchClip \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build

# Run unit tests (Simulator)
xcodebuild test -scheme NFCStitchClip \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Build for device (requires provisioning profile)
xcodebuild -scheme NFCStitchClip \
  -destination 'generic/platform=iOS' \
  build
```

### Required Xcode Configuration (do not skip)

Both of these must be in place before any NFC code will compile or run:

1. `NFCStitchClip.entitlements` — add key `com.apple.developer.nfc.readersession.formats` with value `NDEF`
2. `Info.plist` — add key `NFCReaderUsageDescription` with a user-facing string

Dark mode is enforced at the app level, not per-view: add `UIUserInterfaceStyle = Dark` to `Info.plist`.

### NFC Tag Format

Every tag stores one NDEF Text record (UTF-8), JSON payload:

```json
{"projectId":"<UUID-string>","notes":"<user text>","timestamp":<unix-epoch-seconds>}
```

Storage footprint is ~150–180 bytes. Tags are NTAG216 (888-byte capacity). This format is iOS-app-specific — cross-platform compatibility is out of scope.

### Exact User-Facing Strings (do not alter)

| Event | String |
|-------|--------|
| Write success | `✓ Tag written successfully` |
| Write failure | `Write failed. Please try again.` |
| Read failure | `Read failed. Please try again.` |
| Orphaned tag modal title | `Tag not linked to a project` |
| Re-link success | `✓ Tag linked to [project name]` |

### Behavioural Invariants

- **No partial state on NFC failure** — if an NFC write fails, roll back any in-progress SwiftData changes before surfacing the error.
- **No concurrent NFC sessions** — disable all NFC trigger buttons while a session is active.
- **`firstWriteAt` preservation** — when re-linking an orphaned tag, set `Tag.firstWriteAt` from the `timestamp` field read off the physical tag, not from the current time.
- **Orphaned tag modal requires valid NDEF JSON** — a completely blank or malformed tag never shows the modal; show "Read failed. Please try again." instead.

### Time Tracking Logic (History tab)

Estimated work time = sum of consecutive `WriteEvent.timestamp` gaps that are **≤ 12 hours**, across all tags in the project, sorted chronologically. Gaps > 12 hours are session breaks and are excluded. When there is only one write event, display "No time data yet".

See `docs/PRD_iOS_Native.md §5.3` for the worked example and edge cases.

### Out of Scope (iOS MVP)

Cloud sync, user accounts, Android support, iPad-optimised layouts, tag custom naming, tag templates, PDF export, in-app purchases, iCloud sync. See `docs/PRD_iOS_Native.md §7`.

---

## Web App (`src/index.html`)

Single self-contained file — HTML + CSS + JS with no build step. Targets Chrome 89+ on Android via the Web NFC API (`NDEFReader`). The web app's NFC tag format is **plain text only** (no JSON) — this differs from the iOS app.

Key invariants:
- `AbortController.abort()` must be called on every tab switch.
- `localStorage` is written only after a confirmed successful NFC write.
- The unsupported-browser banner (`"NDEFReader" not in window`) is permanent and cannot be dismissed; all NFC buttons are disabled while it is visible.

See `docs/PRD.md` and `docs/tasks.md` for full detail.
