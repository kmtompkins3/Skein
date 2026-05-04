# Tasks — Stitch Clip NFC Note Tool MVP

> Derived from [PRD.md](PRD.md) · Last updated: 2026-04-27

---

## Phase 1: Project Setup

- [x] Create `src/index.html` as the single application file (HTML + CSS + JS embedded)
- [x] Verify `/docs/` directory exists for documentation files
- [x] Confirm no build tool is needed — static file served directly

---

## Phase 2: Core UI & Navigation

- [x] Implement mobile-first layout optimized for 320px–480px viewport width
- [x] Add app title: "Stitch Clip Note Writer"
- [x] Implement two-tab navigation: **Write** tab and **Read** tab
- [x] Highlight active tab with underline or color indicator
- [x] Ensure tab switching cancels any pending NFC operation via `AbortController`
- [x] Set minimum font size of 16px for inputs and body text
- [x] Set minimum tap target height of 48px for all buttons
- [x] Implement unsupported browser banner
  - Detect `NDEFReader` in `window` on load
  - Display: "NFC is not supported in this browser. Please use Chrome on Android."
  - Banner is persistent (not dismissible)
  - Disable all NFC buttons while banner is visible

---

## Phase 3: Write Feature

- [x] Add textarea with placeholder: "Enter your stitch note (e.g., Row 12, started double crochet)"
- [x] Enforce 500-character limit via `maxlength` HTML attribute
- [x] Implement live character counter displaying `{n} / 500`
- [x] Show counter in warning color when note reaches 500 / 500
- [x] Disable "Write to Tag" button until at least 1 character is entered
- [x] On "Write to Tag" tap, show status: "Tap tag now..."
- [x] Disable button while write operation is in progress (prevent double-tap)
- [x] On successful write, show status: "✓ Note written successfully"
- [x] Save written note to `localStorage` on success
- [x] Pre-populate textarea from `localStorage` on app load (label as "Last note" if present)
- [x] Show no "Last note" label when `localStorage` is empty (textarea shows placeholder only)
- [x] Implement User Story 3 — overwrite flow:
  - User scans tag on Read tab
  - Taps "Edit Note" → Write tab opens pre-filled with scanned text
  - User modifies and writes; previous note is fully replaced

---

## Phase 4: Read Feature

- [x] Add "Scan Tag" button to Read tab
- [x] On tap, show status: "Tap tag to read..."
- [x] Disable button while read operation is in progress
- [x] On successful read, display retrieved note in a readable block
- [x] Show status: "✓ Note retrieved" on success
- [x] Hide note display area until a successful scan occurs
- [x] Add "Edit Note" button below displayed note
  - Copies note text into Write textarea
  - Switches active tab to Write

---

## Phase 5: Error Handling & Edge Cases

### Write Errors

- [x] Tag not present / timeout → "✗ Write timed out. Hold tag steady and try again."
- [x] Tag is read-only → "✗ Tag is read-only and cannot be written to."
- [x] Generic write failure → "✗ Write failed. Please try again."

### Read Errors

- [x] Tag not present / timeout → "✗ Read failed. Tag may be out of range."
- [x] Tag is blank / no NDEF record → "✗ No note found on this tag. Write a note first."
- [x] Corrupted / unreadable data → "✗ Could not read tag. Tag may be damaged."

### General Edge Cases

- [x] Tab switch during active NFC operation: call `AbortController.abort()`, reset status to idle
- [x] Rapid button taps: button remains disabled for the duration of the operation
- [x] Note at exactly 500 characters: allowed, counter shows "500 / 500" in warning color
- [ ] Zero unhandled JS exceptions in normal and error flows

---

## Phase 6: NFC Integration

- [x] Use `NDEFReader` Web NFC API — no third-party library
- [x] Write NDEF record with `recordType: "text"`, UTF-8 encoding, plain text payload
- [x] Read NDEF record and extract text payload from first matching record
- [x] Use `AbortController` to cancel pending NFC operations on tab switch or user cancel
- [x] Confirm compatibility: Chrome 89+ on Android only

---

## Phase 7: Testing

- [ ] Test write flow with a physical NTAG216 NFC sticker tag
  - Verify note is written and readable by third-party NFC reader app
  - Verify success rate >95% across multiple attempts
- [ ] Test read flow with a written NTAG216 tag
  - Verify note is displayed correctly
  - Verify success rate >95% across multiple attempts
- [ ] Test average write time is <3 seconds
- [ ] Test average read time is <2 seconds
- [ ] Test overwrite flow: scan existing tag → edit note → write → confirm old note replaced
- [ ] Test unsupported browser banner on non-Chrome or non-NFC device
- [ ] Test all write error states (timeout, read-only tag, generic failure)
- [ ] Test all read error states (timeout, blank tag, corrupted tag)
- [ ] Test tab switch mid-operation cancels NFC without JS exceptions
- [ ] Test rapid button taps — confirm no duplicate operations
- [ ] Test 500-character note: write, read back, confirm full note retrieved
- [ ] Test empty `localStorage` state: textarea shows placeholder, no "Last note" label
- [ ] Confirm first-time user can write and read without external instructions

---

## Phase 8: Hardware Prototyping (Parallel Track)

- [ ] Source off-the-shelf NTAG216 NFC sticker tags for app validation
- [ ] Validate write/read reliability with sticker tags before custom hardware
- [ ] Define stitch clip form factor (clips onto crochet project)
- [ ] Determine NFC tag embedding method (post-print assembly or during print)
- [ ] Design 3D-printable clip housing sized for NTAG216 tag
- [ ] Print prototype clip and verify NFC read/write through clip material
- [ ] Iterate clip design based on usability feedback
- [ ] Verify clip durability under repeated handling

---

## Phase 9: Deployment

- [ ] Create GitHub repository for the project
- [ ] Push `src/index.html` and `docs/` to the repository
- [ ] Enable GitHub Pages from the repository settings
- [ ] Verify the live URL loads the app correctly on Android Chrome
- [ ] Test write and read on the deployed GitHub Pages URL (not local file)
- [ ] Confirm app works offline after initial page load (no network requests after load)
- [ ] Document the live URL for sharing with testers

---

## Success Criteria Checklist (MVP Sign-off)

- [ ] Web app successfully writes to NTAG216 NFC tags
- [ ] Web app successfully reads from NTAG216 NFC tags
- [ ] First-time users accomplish write/read without instructions
- [ ] Write success rate >95% in real-device testing
- [ ] Read success rate >95% in real-device testing
- [ ] Users always understand app state via status messages
- [ ] Validated with real NTAG216 tags on Android Chrome
- [ ] Live on GitHub Pages
