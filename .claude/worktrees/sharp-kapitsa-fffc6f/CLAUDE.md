# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Summary

**Stitch Clip NFC Note Tool** — a zero-dependency, single-file web app that lets crocheters write and read short progress notes on NFC-embedded stitch clips using the Web NFC API.

- Full requirements: [`docs/PRD.md`](docs/PRD.md)
- Active task list: [`docs/tasks.md`](docs/tasks.md)

---

## Architecture

The entire application lives in one file:

```
src/index.html   ← HTML structure + <style> + <script> all embedded
docs/PRD.md
docs/tasks.md
```

There is **no build step, no bundler, no npm, no dependencies**. `src/index.html` is a fully self-contained static file deployable directly to GitHub Pages.

### Key Design Constraints (from PRD)

- **Single file only** — all HTML, CSS, and JS must remain in `src/index.html`.
- **Vanilla JS (ES2020+)** — no libraries, no frameworks.
- **Web NFC API** — `NDEFReader` is the only browser API for NFC. It is available exclusively in Chrome 89+ on Android. Do not polyfill or wrap it unnecessarily.
- **`localStorage`** — used only for persisting the last-written note across sessions. No server, no database.
- **`AbortController`** — required for cancelling pending NFC operations when the user switches tabs.

### NFC Data Format

NDEF records are written as plain text (`recordType: "text"`, UTF-8). No metadata or timestamps are stored on the tag in MVP — the payload is the raw note string only.

---

## Development Workflow

### Run locally

Open `src/index.html` directly in Chrome for Android (or use a local HTTP server if testing over USB debugging):

```bash
# Simple local server (Python)
python -m http.server 8080
# Then open http://localhost:8080/src/index.html in Chrome on Android
```

Web NFC requires HTTPS or `localhost`. Testing on desktop Chrome will always show the unsupported-browser banner — that is correct behavior.

### Test on device

1. Enable USB debugging on Android.
2. Open `chrome://inspect` on desktop Chrome.
3. Forward port 8080 → localhost:8080 on the device.
4. Open `http://localhost:8080/src/index.html` in Android Chrome.
5. Use a physical NTAG216 NFC sticker tag to test write/read.

### Deploy

Push to GitHub and enable GitHub Pages pointing at the repo root or `src/`. No CI pipeline is needed.

---

## Status Messages (exact strings — do not alter)

These are user-facing and must match the PRD exactly:

| Event | Message |
|-------|---------|
| Write idle | `Ready to write` |
| Awaiting tag (write) | `Tap tag now...` |
| Write success | `✓ Note written successfully` |
| Write timeout | `✗ Write timed out. Hold tag steady and try again.` |
| Read-only tag | `✗ Tag is read-only and cannot be written to.` |
| Write failure | `✗ Write failed. Please try again.` |
| Awaiting tag (read) | `Tap tag to read...` |
| Read success | `✓ Note retrieved` |
| Blank tag | `✗ No note found on this tag. Write a note first.` |
| Read out of range | `✗ Read failed. Tag may be out of range.` |
| Damaged tag | `✗ Could not read tag. Tag may be damaged.` |
| Unsupported browser | `NFC is not supported in this browser. Please use Chrome on Android.` |

---

## Behavioural Invariants

- The unsupported-browser banner is shown on load whenever `"NDEFReader" not in window` and **cannot be dismissed**.
- All NFC buttons must be disabled while the banner is visible.
- Buttons are disabled for the full duration of an active NFC operation (no double-tap).
- Tab switching must always call `AbortController.abort()` before switching.
- `localStorage` is written only after a confirmed successful NFC write.
- The note display area on the Read tab is hidden until a successful scan.

---

## Out of Scope for MVP

Do not implement: PWA/service workers, timestamps on notes, project names, cloud sync, iOS support, user accounts, or analytics. See `docs/PRD.md §2` for the full exclusion list.
