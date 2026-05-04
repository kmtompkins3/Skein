# Product Requirements Document: NFC Stitch Clip — iOS Native App

**Version:** 1.1  
**Date:** April 27, 2026  
**Status:** Planning Phase  
**Platform:** iOS (native Swift/SwiftUI)

---

## 1. Executive Summary

**NFC Stitch Clip** is an iOS app that enables crocheters to track project progress by writing and reading short notes to/from NFC-embedded stitch clips using native iOS NFC capabilities. The app expands beyond a simple read/write tool with local project management, multi-tag workflows, and full project history tracking.

**Core Premise:** Users create crochet projects, assign NFC clips to each project, and use those clips to log progress notes at any time. The app maintains a local history of all write events and provides a unified view of all projects and their timelines.

---

## 2. Goals

1. **Support iOS as the primary platform** with full NFC read/write capability
2. **Enable multi-clip workflows** where one project can have multiple tagged clips, each with specific notes
3. **Provide project-level history** so users can see how long they've been working on a project and when they made progress
4. **Deliver a native, polished iOS experience** with SwiftUI and platform conventions
5. **Maintain simplicity** — the core loop (create project → add clips → scan/write notes) should be intuitive

---

## 3. User Workflows

### 3.1 Create a New Project

**Actor:** Crocheter starting a new project

**Flow:**
1. User taps "New Project" on home page
2. Presented with form:
   - Project name (text field, required)
   - Pattern link (URL field, optional)
   - Project image (picker, optional — photo library or camera)
3. User taps "Create"
4. Project is saved locally; user is taken to project detail page
5. Project is marked as "Ongoing"

**Success Criteria:**
- Project name is required; form cannot submit without it
- Pattern link and image are optional
- Project appears in home page list immediately
- User can begin adding tags to the project

---

### 3.2 Add a Tag to a Project

**Actor:** User wanting to associate a physical NFC clip with a project and write initial notes

**Flow:**
1. User is on project detail page
2. User taps "Add Tag"
3. Presented with:
   - Text field for tag-specific notes (optional)
   - "Write to Tag" button
4. User taps "Write to Tag"
5. NFC prompt appears: "Hold iPhone near tag"
6. App writes to tag:
   - Project ID (reference)
   - Tag-specific notes
   - Timestamp (current date/time)
7. Success message: "✓ Tag written successfully"
8. Tag is added to project's tag list
9. A write event is recorded in the project history

**Success Criteria:**
- User can write to a blank NFC tag
- Tag stores project ID + notes in JSON NDEF format
- App records the write timestamp
- Tag appears in the project's Tags list after write
- History tab reflects the new write event
- On failure: displays "Write failed. Please try again."

---

### 3.3 Read a Tag (Home Page Scan)

**Actor:** User scanning an existing tag from the home page

**Flow:**
1. User is on home page
2. User taps "Scan Tag" button
3. NFC prompt: "Hold iPhone near tag"
4. App reads tag data (project ID + notes)
5. `projectId` is matched against local storage
6. Popup/modal appears showing:
   - Project name (looked up from local storage)
   - Pattern link (if available)
   - Project image (if available)
   - Current tag notes
7. User can:
   - Close the modal
   - Tap to open the full project view
   - Edit the tag notes (optional — see 3.4)

**Success Criteria:**
- Scan works from home page
- Correct project details are displayed
- User can navigate from scan result to project view
- On failure: displays "Read failed. Please try again."
- Unrecognized `projectId` triggers the orphaned tag flow (see 3.8)

---

### 3.4 Update Tag Notes

**Actor:** User wanting to update notes on an existing tag

**Flow:**
1. User has scanned a tag OR is viewing a tag in the project detail
2. User taps "Edit" on the tag notes
3. Presented with text field containing current notes
4. User edits notes and taps "Save"
5. App writes updated notes back to the tag
6. Tag in project list updates; a write event is recorded in the history

**Success Criteria:**
- User can edit notes on existing tags
- Updated notes persist on the physical tag
- Write event timestamp is recorded in history
- On failure: displays "Write failed. Please try again." — no partial state is saved

---

### 3.5 View Project History

**Actor:** User wanting to see project progress over time

**Flow:**
1. User is on project detail page
2. User taps "History" tab
3. Presented with:
   - Summary header at top: "Started [date] · [X] write events · Est. work time: [Y hrs]"
   - Chronological list of all write events across all tags in the project, sorted most recent first
   - Each entry shows: timestamp, which tag was written to, the note content at that write, and time elapsed since the previous write event
4. User can scroll to see full history

**Time Tracking Logic (Write-to-Write Method, 12-hour threshold):**
- Estimated work time is calculated from intervals between consecutive tag writes
- If the gap between two consecutive writes exceeds 12 hours, that gap is treated as a session break and **not** counted
- Example:
  - Tag 1 written Mar 15 at 6:00 PM
  - Tag 2 written Mar 15 at 7:30 PM → gap = 1.5 hrs ≤ 12 hrs → **counted**
  - Tag 3 written Mar 16 at 9:00 AM → gap = 13.5 hrs > 12 hrs → **not counted** (session break)
  - Tag 4 written Mar 16 at 9:45 AM → gap = 0.75 hrs ≤ 12 hrs → **counted**
  - **Total estimated work time: 2.25 hours**
- Time is labelled "Estimated work time" with a note: "Based on time between tag writes"

**Success Criteria:**
- History shows accurate write timestamps for all events
- Time calculation uses write-to-write intervals with 12-hour gap threshold
- Gaps > 12 hours are excluded from the total
- Time is clearly labelled as estimated
- Works with 100+ write events
- Brief help text explains the methodology inline

---

### 3.6 Mark Project as Completed

**Actor:** User finishing a crochet project

**Flow:**
1. User is on project detail page
2. User taps menu/options button
3. Option appears: "Mark as Complete"
4. User confirms
5. Project is moved to "Completed" state
6. Project still appears in home list but marked as "Completed"
7. Project still shows history and can be viewed/edited

**Success Criteria:**
- Completed projects are visually distinct on home page
- User can still view/edit completed projects
- Can unmark as complete if needed

---

### 3.7 Delete a Project

**Actor:** User removing a project they no longer need

**Flow:**
1. User is on home page
2. User swipes or long-presses a project
3. "Delete" option appears (or via menu)
4. User confirms deletion
5. Project and all associated tag history are removed from app
6. Physical tags are unaffected — they still contain the old project ID, but a future scan will trigger the orphaned tag flow (see 3.8)

**Success Criteria:**
- Deletion is destructive and confirmed before proceeding
- No orphaned data left in app storage
- Home page updates immediately

---

### 3.8 Scan a Tag Whose Project Was Deleted ("Orphaned Tag")

**Actor:** User scanning a tag whose `projectId` no longer exists in local storage

**Flow:**
1. User taps "Scan Tag" from home page
2. App reads tag successfully (valid NDEF JSON on the tag)
3. `projectId` from the tag does not match any project in local storage
4. Modal appears titled **"Tag not linked to a project"**
5. Modal displays:
   - The raw notes stored on the tag (if any), labelled "Notes on tag:"
   - The timestamp of the last write, labelled "Last written:"
   - Two action buttons: **"Link to a Project"** and **"Dismiss"**
6. **If user taps "Dismiss":** modal closes; no changes are made to the tag or app data
7. **If user taps "Link to a Project":**
   - User is presented with a picker listing all existing projects, plus a "Create New Project" option
   - User selects an existing project or creates a new one
   - App initiates an NFC write session: "Hold iPhone near tag"
   - App overwrites the tag with a new NDEF record containing the selected project's `projectId` and the original notes
   - On successful write: tag is registered in the selected project's Tags list; the original write timestamp from the tag is preserved as `firstWriteAt`
   - Success message: "✓ Tag linked to [project name]"
   - User is navigated to the project detail view

**Success Criteria:**
- App never crashes or shows an unhandled error on an unrecognized `projectId`
- Raw tag notes are displayed so the user understands what is on the tag before deciding
- User can re-link an orphaned tag to any existing project or a newly created one
- Original note content is preserved through the re-linking process
- If the NFC write fails during re-linking, no partial state is saved in the app (tag remains unlinked)
- If the tag is completely blank or malformed (not a valid NDEF record from this app), display "Read failed. Please try again." rather than the orphaned tag modal

---

## 4. Features

### 4.1 MVP Features

1. **Home Page**
   - List all projects (ongoing + completed)
   - Filter or separate by status
   - "New Project" button
   - "Scan Tag" button (global)
   - Delete project (swipe or menu)
   - Visual distinction between ongoing and completed

2. **Create Project**
   - Name (required)
   - Pattern link (optional URL)
   - Project image (optional, photo picker)

3. **Project Detail View**
   - Project name, link, image (displayed at top)
   - Two tabs: **Tags** and **History**

4. **Tags Tab (Project Detail)**
   - Lists the physical NFC clips registered to this project (one row per clip)
   - Each row shows: tag number/label, current note content, last write date
   - Actions: tap a tag to edit notes, delete to unlink from project
   - "Add Tag" button to write a new clip into the project

5. **History Tab (Project Detail)**
   - Chronological log of every write event across all tags in the project
   - Each entry: timestamp, which tag was written to, note content at that write, time elapsed since previous write
   - Summary header: "Started [date] · [X] write events · Est. work time: [Y hrs]"
   - Estimated work time calculated using write-to-write intervals ≤ 12 hours
   - Disclaimer: "Estimated based on time between tag writes"

6. **Add/Write Tags**
   - Text field for tag-specific notes
   - "Write to Tag" NFC action
   - Generic success/error feedback

7. **Scan (Read) Tags**
   - "Scan Tag" from home page
   - Display project info + tag notes in modal
   - Option to open full project
   - Orphaned tag handling (see 3.8)

8. **Local Persistence**
   - All project data stored in iOS device storage using SwiftData
   - Survives app restart
   - No user account required

---

### 4.2 Stretch Goals (Post-MVP)

- Export project history as PDF
- Statistics dashboard (total projects, total time, streak tracking)
- Photo upload improvements (crop, edit before saving)
- Offline-first sync (local-first, prepare for optional cloud later)
- Localization (Spanish, French, etc.)
- Siri Shortcuts integration (e.g., "Log my crochet session")
- Apple Watch companion app
- Notifications/reminders to work on a project
- Tag templates (reusable note snippets)
- Tag naming/labels (custom names per clip)

---

## 5. Data Model

### 5.1 Local Storage (iOS Device)

```
Project (@Model):
{
  id: UUID,
  name: String,                        // required
  patternLink: String?,                // optional URL
  imagePath: String?,                  // filename only — stored in <Documents>/images/<UUID>.jpg
  startDate: Date,
  endDate: Date?,                      // nil if ongoing
  isCompleted: Bool,
  tags: [Tag]                          // physical NFC clips registered to this project
}

Tag (@Model):
{
  id: UUID,
  notes: String,                       // current note content on the physical tag
  firstWriteAt: Date,                  // when this tag was first written to
  lastWriteAt: Date,                   // when this tag was last updated
  writeEvents: [WriteEvent]            // full audit log of every write to this tag
}

WriteEvent (@Model):
{
  id: UUID,
  timestamp: Date,                     // when this write occurred
  noteContent: String                  // note content at time of write
}
```

**Storage Method:**
- SwiftData `@Model` classes (iOS 17+)
- Images stored as separate JPEG files in `<Documents>/images/<UUID>.jpg`; only the filename is persisted in the model — this avoids loading multi-MB data on every project list fetch
- No UserDefaults for structured data; no Core Data; no FileManager JSON

**Time Tracking:**
- To calculate total estimated work time for a project, collect all `WriteEvent.timestamp` values across all tags, sort chronologically, then sum consecutive gaps ≤ 12 hours

---

### 5.2 NFC Tag Format

Each tag stores a single NDEF Text record (UTF-8):

```
NDEF Record (Text type, UTF-8):
{
  "projectId": "UUID-string",
  "notes": "User's tag-specific notes",
  "timestamp": 1234567890
}
```

**Notes:**
- This format is iOS-app-specific. Cross-platform compatibility is out of scope.
- Storage footprint: ~150–180 bytes on NTAG216 — well within the 888-byte capacity.
- `timestamp` is a Unix epoch integer (seconds).

---

## 5.3 Time Tracking Methodology: Write-to-Write (12-Hour Threshold)

**Why this approach?**
- NFC tags only record when the user writes (creates or updates notes), not passive work time
- Time between writes represents active project sessions
- Simple to implement with no arbitrary inactivity timers or manual start/stop
- Transparent to users — methodology is disclosed in the UI

**How it works:**

1. **Every write to any tag in the project creates a `WriteEvent`** with a timestamp and the note content.

2. **To calculate total estimated work time:**
   - Collect all `WriteEvent.timestamp` values across all tags in the project
   - Sort chronologically
   - For each consecutive pair, if the gap ≤ 12 hours: add to work time. If gap > 12 hours: skip (session break).
   ```
   Write 1: Mar 15, 6:00 PM
   Write 2: Mar 15, 7:30 PM  → gap = 1.5 hrs  ≤ 12 hrs → counted
   Write 3: Mar 16, 9:00 AM  → gap = 13.5 hrs > 12 hrs → NOT counted (session break)
   Write 4: Mar 16, 9:45 AM  → gap = 0.75 hrs ≤ 12 hrs → counted
   Total estimated work time: 2.25 hours
   ```

3. **Display in History tab:**
   - "Est. work time: 2.25 hrs"
   - Disclaimer: "Estimated based on time between tag writes"

4. **Edge cases:**
   - Only one write event in project → No time to calculate; show "No time data yet"
   - Gap exactly 12 hours → Counted (threshold is strictly greater than 12 hours to exclude)
   - Updates to the same tag → Each update creates a new `WriteEvent` and participates in time calculation

**Limitations (disclosed to user):**
- Does not account for work done without writing a tag
- Does not filter out short breaks within a session
- Labelled "estimated" throughout the UI

---

## 6. Technical Requirements

### 6.1 Platform & Language
- **Platform:** iOS 17.0+ (required for SwiftData)
- **Language:** Swift
- **UI Framework:** SwiftUI
- **Architecture:** MVVM or similar

### 6.2 NFC
- **API:** Core NFC framework (`NFCNDEFReaderSession`, `NFCNDEFMessage`)
- **Tag Type:** NTAG216 or compatible (NFC Forum Type 2)
- **Data Format:** NDEF records (text type, JSON payload)
- **Permissions:** Add the `com.apple.developer.nfc.readersession.formats` entitlement to the Xcode project's `.entitlements` file (compile-time configuration). Add an `NFCReaderUsageDescription` key to `Info.plist`. The system NFC scanning sheet appears automatically when `NFCNDEFReaderSession.begin()` is called — no runtime permission request is required beyond these build-time settings.

### 6.3 Storage
- **Local Storage:** SwiftData (iOS 17+). Project, Tag, and WriteEvent data modelled as `@Model` classes.
- No Core Data, no FileManager JSON, no UserDefaults for structured data.
- No cloud required for MVP. Keep models `Codable`-compatible to allow optional future sync.

### 6.4 UI/UX
- Native iOS design language (HIG compliance)
- **Appearance:** Dark mode only. The app ignores the system appearance setting and always renders in dark theme. No light mode variant is required.
- Accessibility (VoiceOver, Dynamic Type)
- iPhone-optimized layouts (iPad support is an open question — see §10)

### 6.5 Performance
- App should launch in <2 seconds
- NFC operations should complete in <5 seconds
- Smooth scrolling on large project and history lists (100+ entries)

---

## 7. Out of Scope (MVP)

**Do NOT implement for initial release:**
- Cloud sync / user accounts
- Android support (separate native app if needed later)
- Web version
- PWA
- Video tutorials or in-app help beyond inline disclaimer text
- Advanced analytics
- Social features (sharing projects, etc.)
- Payments / in-app purchases
- Multiple devices sync
- Bluetooth (NFC only)
- Tag templates (noted as stretch goal)
- Tag custom naming/labels (noted as stretch goal)

---

## 8. Success Metrics

- [ ] App launches on iOS 17+
- [ ] User can create a project in <30 seconds
- [ ] User can write a tag in <15 seconds
- [ ] User can scan and view a tag in <10 seconds
- [ ] All project data persists across app restarts
- [ ] No crashes on edge cases (empty fields, malformed tags, orphaned tag IDs, etc.)
- [ ] NFC read/write success rate >95%
- [ ] App is intuitive without in-app tutorials

---

## 9. Timeline (Estimate)

| Phase | Tasks | Duration |
|-------|-------|----------|
| **Phase 1: Core** | Project CRUD, SwiftData models, SwiftUI layout | 1-2 weeks |
| **Phase 2: NFC** | Read/write integration, JSON tag format, error handling, orphaned tag flow | 1-2 weeks |
| **Phase 3: History & Polish** | WriteEvent log, history tab, time calculation, UI refinement | 1 week |
| **Phase 4: Testing & Release** | QA, App Store submission, documentation | 1-2 weeks |

**Total Estimate:** 4–7 weeks (assuming full-time developer)

---

## 10. Open Questions / Decisions

**Resolved:**
- ~~Core Data vs. FileManager?~~ → **SwiftData** (iOS 17+)
- ~~iCloud backup?~~ → **Not explicitly configured for MVP.** SwiftData stores are included in the standard iOS device backup automatically — no additional code required.
- ~~Notification permissions?~~ → **Not requested.** Notifications are out of scope for MVP.

**Still Open:**
1. **iPad support?** — iPhone-only is recommended for MVP; NFC availability on iPad is inconsistent.
2. **Tag naming?** — Should users assign custom labels to individual tags, or use auto-numbered defaults ("Tag 1", "Tag 2")? Noted as a stretch goal.
3. **Images — resize/compress?** — What max resolution/quality should be enforced when saving project images to Documents?
4. **Time tracking help text?** — How prominently should the write-to-write methodology be explained? Inline tooltip, first-launch callout, or always-visible disclaimer?

---

## 11. Appendix: UI Wireframe Sketch

```
┌─ HOME PAGE ─────────────────┐
│ [+] New Project [Scan Tag]  │
├─────────────────────────────┤
│ Projects:                   │
│ ┌─ My Blanket (Ongoing) ─┐ │
│ │ Started Mar 15          │ │
│ │ 5 write events, ~2 hrs  │ │
│ │ [Menu] > Delete         │ │
│ └────────────────────────┘ │
│ ┌─ Baby Booties (Done) ──┐ │
│ │ Completed Apr 10        │ │
│ │ 3 write events          │ │
│ └────────────────────────┘ │
└─────────────────────────────┘

┌─ PROJECT DETAIL ────────────┐
│ [Image] My Blanket           │
│ Pattern: etsy.com/... [🔗]  │
├─────────────────────────────┤
│ [Tags] [History]            │
│                             │
│ — TAGS TAB —                │
│ Tag 1: "Row 15, color..."   │
│   Last write: Mar 15, 6pm   │
│ Tag 2: "Starting border"    │
│   Last write: Apr 8, 7pm    │
│ Tag 3: "Final stitches"     │
│   Last write: Apr 10, 2pm   │
│ [+ Add Tag]                 │
└─────────────────────────────┘

┌─ HISTORY TAB ───────────────┐
│ Started: Mar 15, 2026        │
│ 5 write events               │
│ Est. work time: ~2.25 hrs   │
│ Estimated based on tag writes│
├─────────────────────────────┤
│ Apr 10, 2:30pm              │
│   Tag 3 — "Final stitches"  │
│   +45 min since last write  │
│                             │
│ Apr 8, 7:15pm               │
│   Tag 2 — "Starting border" │
│   +2.5 hrs since last write │
│                             │
│ Mar 15, 7:30pm              │
│   Tag 2 — "Row 20, cont."   │
│   +1.5 hrs since last write │
│                             │
│ Mar 15, 6:00pm              │
│   Tag 1 — "Row 15, color.." │
│   (first write)             │
└─────────────────────────────┘

┌─ ORPHANED TAG MODAL ────────┐
│ Tag not linked to a project │
├─────────────────────────────┤
│ Notes on tag:               │
│ "Row 15, ready for change"  │
│                             │
│ Last written: Mar 15, 6pm   │
│                             │
│ [Link to a Project] [Dismiss]│
└─────────────────────────────┘
```

---

## End of PRD

**Next Step:** Approve this PRD, then move to architecture/design phase.
