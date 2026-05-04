# Tasks — NFC Stitch Clip iOS Native App

> Derived from [PRD_iOS_Native.md](PRD_iOS_Native.md) · Last updated: 2026-04-27

---

## Phase 1: Xcode Project Setup

- [ ] Create Xcode project: SwiftUI app target, iOS 17.0+ deployment target, set bundle ID
- [ ] Add `com.apple.developer.nfc.readersession.formats` entitlement to the app's `.entitlements` file
- [ ] Add `NFCReaderUsageDescription` key to `Info.plist`
- [ ] Set `UIUserInterfaceStyle = Dark` in `Info.plist` (dark mode only — ignores system setting)
- [ ] Set up MVVM folder structure: `Models/`, `Views/`, `ViewModels/`, `Services/`
- [ ] Configure `ModelContainer` in `@main` app entry point with all three SwiftData models

---

## Phase 2: Data Models (SwiftData)

- [ ] Implement `Project` `@Model`: `id: UUID`, `name: String`, `patternLink: String?`, `imagePath: String?`, `startDate: Date`, `endDate: Date?`, `isCompleted: Bool`, `tags: [Tag]`
- [ ] Implement `Tag` `@Model`: `id: UUID`, `notes: String`, `firstWriteAt: Date`, `lastWriteAt: Date`, `writeEvents: [WriteEvent]`
- [ ] Implement `WriteEvent` `@Model`: `id: UUID`, `timestamp: Date`, `noteContent: String`
- [ ] Make all three models `Codable`-compatible (for optional future sync)
- [ ] Verify `ModelContainer` migration strategy: no-op for MVP, but confirm schema version is set

---

## Phase 3: Home Page

- [ ] Implement project list view showing all projects (ongoing + completed)
- [ ] Visual distinction between ongoing and completed project rows
- [ ] Each row displays: project name, start date, write-event count, estimated work time
- [ ] "New Project" button → navigates to Create Project sheet
- [ ] "Scan Tag" button (global) → triggers NFC read session (see Phase 8)
- [ ] Swipe-to-delete on project rows with destructive confirmation alert
- [ ] Tap project row → navigates to Project Detail view
- [ ] Home page updates immediately after create or delete

---

## Phase 4: Create Project

- [ ] Form view: project name text field (required), pattern link URL field (optional), image picker (optional)
- [ ] Disable "Create" button until name field is non-empty
- [ ] Photo picker: support both photo library and camera capture
- [ ] On image selected: resize/compress to JPEG, save to `<Documents>/images/<UUID>.jpg`, store only the filename in the model
- [ ] On "Create": save `Project` to SwiftData, dismiss sheet, navigate to project detail
- [ ] Pattern link: accept any string; validate URL format before saving (warn if invalid)

---

## Phase 5: Project Detail View

- [ ] Header: project image (if set), project name, pattern link (tappable → opens in Safari/browser)
- [ ] Two-tab layout: **Tags** tab and **History** tab
- [ ] Options/menu button: "Mark as Complete" (if ongoing) or "Mark as Ongoing" (if completed), with confirmation
- [ ] Completed state reflected in header (badge or label) and in the home page row

---

## Phase 6: Tags Tab

- [ ] List all `Tag` records for the project; auto-numbered labels ("Tag 1", "Tag 2", …)
- [ ] Each row: tag label, current note content (truncated), last write date
- [ ] Tap tag row → opens Update Tag Notes flow (see Phase 7)
- [ ] Swipe-to-delete: unlinks tag from project (deletes `Tag` + `WriteEvent` records; does not affect physical tag)
- [ ] "Add Tag" button → opens Add Tag flow (see Phase 7)

---

## Phase 7: NFC Write (Add Tag & Update Notes)

- [ ] Implement `NFCNDEFReaderSession` write mode using `NFCNDEFWriterDelegate`
- [ ] Encode tag payload as NDEF Text record (UTF-8), JSON body: `{"projectId":"<UUID>","notes":"<string>","timestamp":<unix-epoch>}`
- [ ] Confirm storage footprint ~150–180 bytes — well within NTAG216's 888-byte capacity
- [ ] **Add Tag flow**: present notes text field (optional) + "Write to Tag" button → NFC write → on success: create `Tag`, create `WriteEvent`, append both to project in SwiftData
- [ ] **Update Tag flow**: text field pre-filled with current `tag.notes` → "Write to Tag" → NFC write → on success: update `tag.notes` + `tag.lastWriteAt`, append new `WriteEvent`
- [ ] Success feedback: "✓ Tag written successfully"
- [ ] Failure feedback: "Write failed. Please try again."
- [ ] On failure: no partial state saved — abort SwiftData changes

---

## Phase 8: NFC Read (Scan Tag)

- [ ] Implement `NFCNDEFReaderSession` in read-only mode
- [ ] Decode JSON payload from the first NDEF Text record on the tag
- [ ] Look up `projectId` in SwiftData
- [ ] **Known project**: display scan result modal — project name, pattern link, image, tag notes — with "Open Project" and "Edit Notes" actions
- [ ] "Open Project" → navigate to project detail, dismiss modal
- [ ] "Edit Notes" → pre-fill Update Tag Notes flow with scanned notes, dismiss modal
- [ ] **Unknown `projectId`**: trigger Orphaned Tag flow (see Phase 9)
- [ ] **Blank or malformed tag** (no valid NDEF JSON from this app): dismiss NFC sheet, show "Read failed. Please try again."
- [ ] NFC session failure (tag not detected): show "Read failed. Please try again."

---

## Phase 9: Orphaned Tag Flow

- [ ] On scan of unrecognized `projectId`: present modal titled "Tag not linked to a project"
- [ ] Modal displays: raw notes from tag (labelled "Notes on tag:"), last-written timestamp (labelled "Last written:")
- [ ] "Dismiss" button: close modal, no state changes, tag unchanged
- [ ] "Link to a Project" button: present project picker listing all existing projects + "Create New Project" option
- [ ] On project selected / new project created: start NFC write session — overwrite tag with new `projectId` + original notes + current timestamp
- [ ] On write success: create `Tag` in the selected project, set `firstWriteAt` from the tag's original `timestamp`, append `WriteEvent`, navigate to project detail, show "✓ Tag linked to [project name]"
- [ ] On write failure during re-linking: no partial state saved; tag remains unlinked; show "Write failed. Please try again."

---

## Phase 10: History Tab

- [ ] Collect all `WriteEvent` records across all tags in the project
- [ ] Sort events chronologically, display most recent first
- [ ] Summary header: "Started [date] · [X] write events · Est. work time: [Y hrs]"
- [ ] **Time calculation** — write-to-write method with 12-hour threshold:
  - Sort all `WriteEvent.timestamp` values across all tags chronologically
  - For each consecutive pair: if gap ≤ 12 hours, add to total; if gap > 12 hours, skip (session break)
  - Gap exactly 12 hours → counted (threshold is strictly greater than to exclude)
- [ ] Edge case: single write event → show "No time data yet" instead of a time figure
- [ ] Each history row: timestamp, tag label ("Tag 1", etc.), note content at time of write, elapsed time since previous write (or "(first write)" for the earliest)
- [ ] Inline disclaimer beneath summary header: "Estimated based on time between tag writes"
- [ ] Lazy list (no full load) to handle 100+ entries without freezing

---

## Phase 11: Error Handling & Edge Cases

- [ ] No crash when scanning a blank NFC tag
- [ ] No crash when NDEF record contains unexpected JSON structure (missing keys, wrong types)
- [ ] No crash on NFC session timeout
- [ ] Prevent starting a second NFC session while one is already active (disable scan/write buttons)
- [ ] No orphaned `Tag` or `WriteEvent` records in SwiftData after project deletion
- [ ] Handle SwiftData save errors gracefully (show alert, do not leave partial state)

---

## Phase 12: UI Polish & Accessibility

- [ ] Verify dark mode is always applied regardless of system appearance setting
- [ ] HIG-compliant navigation: `NavigationStack`, modal sheets, destructive confirmation alerts
- [ ] VoiceOver accessibility labels on all buttons, list rows, and modal actions
- [ ] Dynamic Type: all text scales correctly at all system sizes
- [ ] App launch time <2 seconds (measure with Instruments on a minimum-spec device)
- [ ] Smooth scrolling with 100+ history entries (verify with Time Profiler)
- [ ] NFC scanning: system NFC sheet provides built-in visual feedback; no custom overlay needed

---

## Phase 13: Testing

- [ ] Happy path: create project → add tag (NFC write) → scan tag (NFC read) → update notes → view history
- [ ] NFC write success rate >95% across multiple attempts with NTAG216 tags
- [ ] NFC read success rate >95% across multiple attempts with NTAG216 tags
- [ ] Orphaned tag flow: delete project → scan old tag → verify modal → link to new project → verify tag updated
- [ ] Time calculation: run the PRD §5.3 example data (Mar 15 6pm, 7:30pm; Mar 16 9am, 9:45am → expected 2.25 hrs)
- [ ] Mark project complete → verify visual distinction → mark ongoing → verify restored
- [ ] Delete project: confirm no orphaned `Tag`/`WriteEvent` records remain in SwiftData
- [ ] Edge cases: single write event (no time data), blank tag, malformed NDEF, NFC timeout
- [ ] Performance: 100+ write events — confirm smooth scroll and correct time total
- [ ] Accessibility: VoiceOver navigation through all major flows
- [ ] App launch <2 seconds on a device running iOS 17

---

## Phase 14: App Store Submission

- [ ] App Store Connect: create app record with bundle ID and Core NFC capability
- [ ] Generate required iPhone screenshots (6.7", 6.1", 5.5" minimum)
- [ ] Write app description, subtitle, and keyword list
- [ ] Create or link privacy policy URL (disclose: data stored locally only, no external transmission)
- [ ] Submit build for App Review

---

## Success Criteria Checklist (MVP Sign-off)

- [ ] App launches on iOS 17+
- [ ] User can create a project in <30 seconds
- [ ] User can write a tag in <15 seconds
- [ ] User can scan and view a tag in <10 seconds
- [ ] All project data persists across app restarts
- [ ] No crashes on edge cases (empty fields, malformed tags, orphaned tag IDs)
- [ ] NFC read/write success rate >95%
- [ ] App is intuitive without in-app tutorials
