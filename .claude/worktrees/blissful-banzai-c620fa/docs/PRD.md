# Product Requirements Document (PRD)

## Stitch Clip NFC Note Tool — MVP (Workflow 1)

**Last Updated:** 2026-04-27

---

## 1. Product Overview

### Vision

Enable crochet enthusiasts to quickly capture and retrieve stitch progress notes by writing to and reading from NFC-embedded stitch clips using a simple web interface.

### Purpose

When a crocheter pauses their project, they can jot down progress notes (e.g., "Row 12, started double crochet") and write it to an NFC tag embedded in a stitch clip. Later, they can scan the clip with their phone to instantly see where they left off.

### Target Users

- Crochet hobbyists and professionals
- Anyone using stitch clips who wants a quick note-taking system
- Users with Android devices (primary launch target)

---

## 2. Scope

### In Scope (MVP)

- Web-based interface accessible via mobile browser
- Write text notes to NFC tags
- Read/scan NFC tags to retrieve notes
- Offline-capable (static file, no server required)
- Support for NFC Type 4 / NTAG216 tags (NDEF-compliant, read/write)
- Simple, intuitive mobile-first UI
- Error handling for common scenarios (tag not detected, write failures, blank tags)
- "Edit Note" shortcut: pre-fills Write tab with scanned note text
- Last-written note persisted in `localStorage` for quick re-access

### Out of Scope (V2+)

- PWA / service workers / "Add to Home Screen"
- Project-based workflow (project names, pattern links, images)
- Project history and tracking
- Timestamps on notes
- Cloud sync or multi-device support
- Sharing/collaboration features
- iOS support (Web NFC API not available in Safari)
- User accounts or authentication
- Analytics or telemetry

---

## 3. User Stories & Workflows

### User Story 1: Writing a Note to a Tag

**As a** crocheter on a break
**I want to** quickly write a note to my stitch clip
**So that** I remember exactly where I left off

**Acceptance Criteria:**

- User can open the web app on their Android phone in Chrome
- User can type a text note (max 500 characters)
- Character counter updates live as the user types
- "Write to Tag" button is disabled until at least 1 character is entered
- Tapping "Write to Tag" shows "Tap tag now..." status
- Upon tapping the NFC tag to their phone, the note is written
- User sees "✓ Note written successfully" on success
- User sees a clear error message on failure
- The written note is saved to `localStorage` for next session

---

### User Story 2: Reading a Note from a Tag

**As a** crocheter returning to a project
**I want to** scan my stitch clip to see the note I left
**So that** I can quickly resume my progress

**Acceptance Criteria:**

- User can open the web app and tap the Read tab
- User taps "Scan Tag" to initiate reading
- Status shows "Tap tag to read..."
- Upon tapping the tag, the note is retrieved and displayed
- User sees "✓ Note retrieved" on success
- User sees a clear error message if the tag is blank or unreadable

---

### User Story 3: Overwrite an Existing Note

**As a** crocheter making progress
**I want to** update the note on my stitch clip
**So that** the note always reflects my current progress

**Acceptance Criteria:**

- User can scan an existing tag with a note
- User taps "Edit Note" — Write tab opens pre-filled with the scanned text
- User modifies the note and writes it to the same tag
- User sees confirmation of successful overwrite
- The previous note is fully replaced (no history kept in MVP)

---

### User Story 4: Unsupported Browser / Device

**As a** user on an unsupported browser or device
**I want to** understand why the app won't work
**So that** I know what I need to change

**Acceptance Criteria:**

- On load, app checks for `NDEFReader` in `window`
- If absent, a clear banner is shown: "NFC is not supported in this browser. Use Chrome on Android."
- Write and Read buttons are disabled
- Banner persists — it is not dismissible

---

## 4. Core Features

### 4.1 Write Interface

- **Text Input Field**
  - Placeholder: "Enter your stitch note (e.g., Row 12, started double crochet)"
  - Character limit: 500 characters (`maxlength` enforced in HTML)
  - Live character counter: `{n} / 500`
  - On load: pre-populated from `localStorage` last-written note (labeled "Last note")
  - Minimum 1 character required before write is allowed

- **Write Button**
  - Label: "Write to Tag"
  - Disabled until ≥1 character is entered
  - Shows "Tap tag now..." while waiting
  - Shows success or error message on completion

- **Status Messages**
  - "Ready to write"
  - "Tap tag now..."
  - "✓ Note written successfully"
  - "✗ Write failed. Please try again."
  - "✗ Tag is read-only."
  - "✗ Write timed out. Hold tag steady and try again."

### 4.2 Read Interface

- **Scan Button**
  - Label: "Scan Tag"
  - Triggers NFC read mode

- **Note Display**
  - Hidden until a successful scan
  - Shows retrieved note in a readable block
  - "Edit Note" button below note → copies note to Write textarea, switches to Write tab

- **Status Messages**
  - "Tap tag to read..."
  - "✓ Note retrieved"
  - "✗ No note found on this tag. Write a note first."
  - "✗ Read failed. Tag may be out of range."
  - "✗ Could not read tag. Tag may be damaged."

### 4.3 Navigation

- Two tabs: **Write** and **Read**
- Active tab clearly indicated (underline or highlight)
- Switching tabs cancels any pending NFC operation via `AbortController`

### 4.4 Unsupported Browser Banner

- Shown on load if `"NDEFReader" not in window`
- Message: "NFC is not supported in this browser. Please use Chrome on Android."
- All NFC buttons disabled while banner is shown

---

## 5. Technical Requirements

### 5.1 Platform & Compatibility

- **Target Devices:** Android phones with NFC capability
- **Browsers:** Chrome 89+ (Android) — Web NFC API required
- **iOS:** Not supported in MVP (Web NFC API not available in Safari)
- **Offline Support:** Yes — static HTML file, no network requests after initial load

### 5.2 NFC Specifications

- **Tag Type:** NFC Forum Type 4 — NTAG216
- **Read/Write:** Both supported
- **Data Format:** NDEF (NFC Data Exchange Format)
- **User Data Capacity:** 888 bytes (supports 500-character UTF-8 notes)
- **Rewritable:** Yes

### 5.3 Data Format on Tag

- **Format:** Plain text NDEF record (`recordType: "text"`)
- **Structure:** Simple text payload — no metadata, no timestamp
- **Encoding:** UTF-8
- **Max characters:** 500

### 5.4 Technology Stack

- **Frontend:** HTML5, CSS3, Vanilla JavaScript (ES2020+)
- **NFC:** Web NFC API (`NDEFReader`) — no third-party library
- **Storage:** `localStorage` for last-written note only (no server, no database)
- **Build Tool:** None — single static `src/index.html` file
- **Hosting:** GitHub Pages

### 5.5 File Structure

```
/src/
  index.html    ← entire application (HTML + CSS + JS embedded)
/docs/
  PRD.md        ← this document
```

### 5.6 Browser APIs Used

- `NDEFReader` (Web NFC API) — write and scan NFC tags
- `AbortController` — cancel pending NFC operations
- `localStorage` — persist last-written note across sessions

---

## 6. User Interface Design

### 6.1 Layout (Mobile-First)

- Single-page application
- Tab navigation between Write and Read
- Optimized for 320px–480px viewport width
- Minimum 16px font size for inputs and body text
- Minimum 48px tap target height for all buttons

### 6.2 Design Principles

- **Simplicity:** Minimal UI, focus on core actions
- **Clarity:** Status messages are always specific and actionable
- **Feedback:** User always knows what state the app is in
- **Accessibility:** High contrast, readable fonts, large tap targets

### 6.3 Key Screens

**Screen 1: Write Tab**
```
┌─────────────────────────────────────┐
│     Stitch Clip Note Writer         │
├─────────────────────────────────────┤
│  [Write ▸]  [Read]                  │
├─────────────────────────────────────┤
│                                     │
│  Enter your note:                   │
│  ┌─────────────────────────────────┐│
│  │ Row 12, started double crochet  ││
│  │                                 ││
│  └─────────────────────────────────┘│
│  38 / 500                           │
│                                     │
│  ┌─────────────────────────────────┐│
│  │         Write to Tag            ││
│  └─────────────────────────────────┘│
│                                     │
│  Status: Ready to write             │
│                                     │
└─────────────────────────────────────┘
```

**Screen 2: Read Tab**
```
┌─────────────────────────────────────┐
│     Stitch Clip Note Writer         │
├─────────────────────────────────────┤
│  [Write]  [Read ▸]                  │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────────┐│
│  │           Scan Tag              ││
│  └─────────────────────────────────┘│
│                                     │
│  Status: ✓ Note retrieved           │
│                                     │
│  ─────────────────────────────────  │
│  Current Note:                      │
│  Row 12, started double crochet     │
│  ─────────────────────────────────  │
│                                     │
│  ┌─────────────────────────────────┐│
│  │           Edit Note             ││
│  └─────────────────────────────────┘│
│                                     │
└─────────────────────────────────────┘
```

**Screen 3: Unsupported Browser**
```
┌─────────────────────────────────────┐
│     Stitch Clip Note Writer         │
├─────────────────────────────────────┤
│  ┌─────────────────────────────────┐│
│  │ ⚠ NFC is not supported in this  ││
│  │ browser. Use Chrome on Android. ││
│  └─────────────────────────────────┘│
│                                     │
│  [Write ▸]  [Read]                  │
│  ...                                │
└─────────────────────────────────────┘
```

---

## 7. Error Handling & Edge Cases

### 7.1 Write Errors

| Scenario | Status Message | Guidance |
|----------|---------------|----------|
| NFC not supported | Banner on load | Use Chrome on Android |
| Tag not present / timeout | "✗ Write timed out. Hold tag steady and try again." | Hold tag closer, try again |
| Tag is read-only | "✗ Tag is read-only and cannot be written to." | Use a writable NTAG216 tag |
| Write failed (generic) | "✗ Write failed. Please try again." | Retry |

### 7.2 Read Errors

| Scenario | Status Message | Guidance |
|----------|---------------|----------|
| NFC not supported | Banner on load | Use Chrome on Android |
| Tag not present / timeout | "✗ Read failed. Tag may be out of range." | Hold tag closer, try again |
| Tag is blank | "✗ No note found on this tag. Write a note first." | Switch to Write tab |
| Corrupted data | "✗ Could not read tag. Tag may be damaged." | Check physical tag |

### 7.3 General Edge Cases

- **Tab switch during active operation:** `AbortController.abort()` cancels the pending NFC operation; status resets to idle
- **Rapid button taps:** Button disabled while operation is in progress
- **Note exactly 500 chars:** Allowed; character counter shows "500 / 500" in warning color
- **Empty `localStorage`:** Write textarea starts empty with placeholder text; no "Last note" label shown
- **Browser doesn't support Web NFC:** Unsupported banner shown; all NFC buttons disabled

---

## 8. Success Metrics (MVP)

### Technical

- Write success rate: >95%
- Read success rate: >95%
- Average write time: <3 seconds
- Average read time: <2 seconds
- Zero unhandled JS exceptions

### User Experience

- First-time user can write and read without external instructions
- Error messages resolve user issues without external help
- App state is always clear to the user

---

## 9. Hardware Specifications

### NFC Tag Requirements

- **Model:** NTAG216
- **Type:** NFC Forum Type 4 (NDEF-compliant)
- **Rewritable:** Yes
- **User data capacity:** 888 bytes
- **Character capacity at UTF-8:** ~880 characters (500-char limit is well within bounds)

### Stitch Clip Design

- Form factor: clips onto crochet project
- Embedding method: TBD (post-printing assembly or during print)
- Durability: withstands repeated handling

### Prototyping Phase

- Test app with off-the-shelf NTAG216 NFC sticker tags first
- Validate write/read reliability before custom 3D printing
- Iterate clip design based on user feedback

---

## 10. Assumptions & Dependencies

### Assumptions

- Users have Android phones with NFC capability and Chrome 89+
- Physical NTAG216 tags available for testing
- ~500 character notes are sufficient for MVP
- Users have connectivity for first load; app works offline after that

### Dependencies

- Chrome for Android with Web NFC API support
- Physical NTAG216 NFC tags for testing and embedding
- GitHub account for GitHub Pages hosting

---

## 11. Future Enhancements (V2+)

- PWA: `manifest.json` + service worker for "Add to Home Screen" and full offline support
- Timestamps prepended to note payload (e.g., `[2026-04-27] Row 12...`)
- Project-based organization (project name, pattern link, images)
- Project history and activity tracking
- Multi-tag support per project
- Cloud sync for multi-device access
- Sharing and collaboration features
- iOS support (native app or alternative tech)

---

## 12. Timeline & Milestones (Estimate)

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| Design & Planning | Complete | PRD, plan |
| Development | 1–2 weeks | `src/index.html` — full write/read/error handling |
| Testing (with NTAG216 stickers) | 1 week | Validated with real tags, all error states covered |
| Iteration & Refinement | 1 week | UX polish, bug fixes |
| Hardware Prototyping | Parallel | 3D clip design, embedding process |
| GitHub Pages Deploy | 1 day | Live URL, deployment verified |

---

## 13. Success Criteria for MVP

- **Functional:** Web app successfully writes to and reads from NTAG216 NFC tags
- **Usable:** First-time users accomplish write/read without instructions
- **Reliable:** >95% success rate on write and read operations
- **Clear:** Users always understand app state via status messages
- **Tested:** Validated with real NTAG216 tags
- **Deployed:** Live on GitHub Pages

---

**End of PRD**
