# Session handoff — Fortnightly (UTS iOS Assessment 3)

Read this first, then `ASSIGNMENT.md` (the brief; local only, gitignored), `PRODUCT.md`, `DECISIONS.md` and the relevant `PLAN.md` sections. Last updated 2026-10-07, `main` at `4125ba8`.

## What the project is

An iPhone app for international students on a subclass 500 visa working casual hospitality shifts. It keeps them within the visa work limit (48 hours in **any** 14 days starting on a Monday, so fortnights overlap) and gives them their own accurate record of hours worked across employers. The student rosters shifts up front; the app prompts at rostered start and finish to clock in and out; a widget keeps nagging until the shift is recorded.

- **Extensions:** Notification Content Extension (custom clock-in/out prompt) + WidgetKit widget (status, interactive clock-in/out buttons).
- **Database:** Core Data, store in the App Group `group.com.peter.fortnightly`.
- **Architecture:** SwiftUI Views → ViewModels → Use Cases (structs, typed errors) → Repository protocols → Core Data. All logic lives in the `FortnightlyKit` framework, shared by the app and both extensions.

## Working with the user (important)

- UTS student, writing in English as a second language. Explain plainly, in short sections. They make the product and design decisions; offer options with trade-offs and a recommendation, then follow their call.
- **TDD, tests chosen together.** Before any new logic, propose candidate tests (each naming the plausible bug it catches) with the `ask` tool, multi-select, recommended ones marked. They pick. Then red commit (`test(...)`), green commit (`feat(...)`), per group. If they "can't judge from text", draw a visual storyboard (see `prototype/test-storyboard.html`).
- **Design before code, shown not described.** They judge designs from HTML mocks opened in their browser, not text.
- They make good product calls. The donut redesign and dropping the research-degree setting were theirs; record such decisions in `DECISIONS.md` with "I" as the decider.
- Every significant decision, finding and AI interaction goes in `DECISIONS.md` (it feeds the reflective report and the AI section). Keep the AI-use table updated.

## Repo and git conventions

- `main` holds only stable, tested code. Work on `feature/...` (or `chore/`, `docs/`) branches, merge with `git merge --no-ff`. Conventional Commits (`feat:`, `fix:`, `test:`, `docs:`, `refactor:`, `chore:`).
- `ASSIGNMENT.md` must never be committed (UTS material); it's in `.gitignore`.
- Throwaway prototypes live only on branch `prototype/ui-variants` (`prototype/*.html`); never merge it into main. Bring main in with `git merge main` when needed.
- Commit author is `peter <peter.wanchai@shinko1.ai>`. The user hasn't decided whether to change it before the first push (open item).

## Key files

| File | What it is |
|---|---|
| `PRODUCT.md` | Product record from the impeccable `init` interview (users, purpose, positioning, constraints, principles). |
| `PLAN.md` | Full plan. §4 rules (R1–R11; R12 dropped), §8 use cases and error copy, §13 all 20 agreed tests with Given/When/Then, §14 project setup, §16 build order. Parts of §9–12 still describe the old tab layout; the screens are now the ones below. |
| `DECISIONS.md` | Dated decision log, AI-use table, open items checklist. |
| `.impeccable/surfaces/atures-fortnight-fortnightboardview-swift-7ebb1a81.md` | The **direction contract** for the home screen and its related surfaces (donut + day list). The build must match it. Read it with `~/.claude/skills/impeccable/scripts/impeccable surface-brief read Fortnightly/Fortnightly/Features/Fortnight/FortnightBoardView.swift`. |
| `prototype/board-v2.html` (prototype branch) | **Approved board design**: donut + 14-day list, scrolled state, other fortnight, over limit, roster sheet, Lock Screen, Home Screen widget, Dark Mode. |
| `prototype/screens.html` (prototype branch) | Remaining screens: roster sheet, day sheet, shift details (missed, upcoming, worked), Jobs, onboarding, large text. Drawn in the older timetable layout; **apply board-v2's donut/day-row language** when building (e.g. the roster preview uses a day row, not a timetable strip). The research-degree toggle on Jobs is dropped. |

## Code state (all 20 tests pass)

**FortnightlyKit/Domain:**
- Models: `Employer`, `Shift` (status rostered/onShift/worked/notWorked; `timeTowardWorkLimit(asOf:)`; `firstClash(with:asOf:)` on collections), `CourseBreak`.
- Fortnight logic: `WorkFortnight` (Monday start, forced; `containing`, `overlapping`), `WorkLimitPolicy` (48; near from 40), `FortnightWorkSummary` (hoursWorked, hoursRostered, hoursTowardLimit, status).
- Results and formatting: `FortnightEffect` (before/after), `WorkedShiftOutcome`, `ShiftListing` (shift + employer name), `StudentFacingFormats`.

**FortnightlyKit/UseCases** (8 structs, each with a typed error enum and `LocalizedError` messages saying what went wrong and what to do next):

| Use case | What it does |
|---|---|
| `ReviewFortnightHours` | Both fortnights containing a day |
| `RosterShift` | `execute` (with `acknowledgingWorkLimitBreach`; `editing:` changes an existing rostered shift) and `preview` (effects without saving) |
| `ClockIntoShift` | `.asRostered` / `.now` / `.at` |
| `ClockOutOfShift` | Returns `WorkedShiftOutcome`; queries shifts over 16 hrs |
| `ReviewMissedShifts` | Rostered shifts that finished without a clock-in |
| `MarkShiftNotWorked` | Stops a rostered shift counting |
| `LogPastShift` | A new past shift, or a missed shift's real times |
| `ArchiveEmployer` | Refused while on shift or with upcoming shifts there |

**FortnightlyKit/Ports:**
- `ShiftRepository`: `shift(withID:)`, `openShift`, `upcomingShifts(after:)`, `rosteredShifts`, `shiftsCountingTowardWorkLimit(overlapping:)`, `save`.
- `EmployerRepository`, `CourseBreakRepository` (only `courseBreaks(overlapping:)`).
- `ShiftReminderScheduling`: schedule, cancelClockIn, cancelAll.
- `ShiftDisplayRefreshing`.

**FortnightlyKit/Persistence:**
- Core Data model: `EmployerEntity` ↔ `ShiftEntity`. No `CourseBreakEntity` yet.
- `ShiftStore.appGroup` and the Core Data repositories for shifts and employers.

**Tests:** `FortnightlyKitTests` uses Swift Testing with in-memory mocks (`Mocks/`), fixtures in `Support/Fixtures.swift`:
- `october(day, at:)` in Sydney time; the calendar deliberately starts weeks on Sunday.
- `recordStoryboardShifts()` holds the mock data: 40.75 h in the fortnight from Mon 12 Oct without tonight's 5–10:30pm Café Roma shift.

**Still spike code (to replace):** `Fortnightly/Spike/SpikePanel.swift` (`ContentView` shows it), the spike widget in `ShiftStatusWidget.swift`, the spike notification view in `ShiftPromptNotification/ShiftPromptView.swift`, `Platform/SpikeProbe.swift`.

## Next step: build the app in SwiftUI (to-do steps 2–4)

1. **Missing plumbing (no new tests agreed; ask the user if they want any):**
   - `AddEmployer` (name required, unique; pay cycle; a colour from a fixed set of six, stored on the employer → add a Core Data attribute; dev stores can be reinstalled, no migration needed).
   - Course breaks: `CourseBreakEntity`, Core Data repository, `RecordCourseBreak` (end after start, no overlap).
   - "Correct times" for a worked shift.
   - An "onboarding done" flag.
2. **Platform adapters:**
   - `ShiftReminderScheduling` with `UNUserNotificationCenter`: identifiers `shift.<uuid>.clockInDue/.clockInOverdue/.clockOutDue/.clockOutOverdue`, a rolling window of the next 10 shifts (iOS limit of 64 pending), PLAN §12.
   - `ShiftDisplayRefreshing` with `WidgetCenter.reloadTimelines(ofKind: "ShiftStatusWidget")`.
   - Notification actions handled in `AppDelegate` through the same use cases.
3. **Screens:**
   - Fortnight board: navy shell, segmented control with the two fortnights containing today, donut by employer, hours-left line, colour key, "Did you work it?" row, 14 day rows with 12-hour bars, the donut collapsing into the nav bar on scroll, and the dock (order: clock in/out → missed shift → next shift).
   - Sheets: roster a shift (form + day-row preview + before → after; "Add" becomes "Add anyway" on breach), day, shift details per state.
   - Jobs (push), onboarding (3 steps).
   - ViewModels call use cases only, never Core Data.
   - Remove the spike panel.
4. **Extensions in the new design:**
   - Widget: `.systemSmall` with the donut, and Lock Screen `.accessoryRectangular` + `.accessoryCircular` (one colour). Interactive App Intents: **two clock-in buttons "Started <rostered time>" / "Just now"** (user decision), plus clock out, all through the shared use cases.
   - Notification: categories `SHIFT_START` / `SHIFT_FINISH`, a small donut + tonight's day row + before → after. Actions: Started on time / Started just now / Not working this shift; Finished on time / Finished just now / Still working (snooze 30 min). Size the view to its content (the spike's last line was cut off at a fixed 150 pt).
5. **Verify in the Simulator:** screenshots light and dark plus a large text size (`xcrun simctl ui <udid> appearance dark`), compared against `board-v2.html`. Seed demo data for markers. Then show the user.

## The impeccable design skill (installed at `~/.claude/skills/impeccable`)

- Done: `init` (PRODUCT.md), new-work direction round (assigned candidate 5, seed `052dfc4a`, telemetry sent), direction contract written and updated for the redesign.
- Before any UI code, read `~/.claude/skills/impeccable/reference/craft-floor.md`. Key bans: no small-caps "eyebrow" label above a heading; no coloured left/right border over 1px on cards; no emoji/Unicode as icons (use SF Symbols); semantic colours plus Dark Mode; Dynamic Type.
- Platform rules: `reference/ios.md`. Build is **code-led** (no image generation available). Its browser decision page can't run here; use the `ask` tool instead.
- Still owed after the build (the contract's FINISH line):
  - At most two inspection rounds on Simulator screenshots.
  - A finish review. The `impeccable-finish-reviewer` agent doesn't exist in this harness, so check `reference/degraded/` for the in-thread version.
  - The documenter writes `DESIGN.md` **and** `.impeccable/design.json` (`reference/degraded/documenter.md` + `reference/document.md`).

## Environment gotchas

- **Xcode 27.** New projects start as untitled drafts. The Simulator app is **DeviceHub** (`/Applications/Xcode.app/Contents/Applications/DeviceHub.app`). In DeviceHub a long-press on a notification counts as a tap: open the custom view with **swipe left → View**. Push a test prompt with `xcrun simctl push <udid> com.peter.fortnightly payload.apns`.
- **Simulator:** iPhone 17, iOS 26.5, UDID `302AF005-18F9-42AA-B575-DA17506C6F5F`. No Team needed; the App Group is delivered as simulated entitlements. The App Group container on disk: `xcrun simctl get_app_container <udid> com.peter.fortnightly group.com.peter.fortnightly`.
- **Build and test:**
  ```
  xcodebuild -project Fortnightly/Fortnightly.xcodeproj -scheme Fortnightly -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -derivedDataPath /tmp/fortnightly-dd test 2>&1 | grep -E '(error:|warning: [^M]|Test case|Expectation failed|TEST (SUCCEEDED|FAILED))' | sed -E 's/ on .Clone.*\(/ (/' | sort -u
  ```
  About 25–40 s in the foreground. If it gets backgrounded, the job can take about 10 minutes to report.
- **Targets:**
  - `Fortnightly`: app, default actor isolation MainActor.
  - `FortnightlyKit`: nonisolated, `APPLICATION_EXTENSION_API_ONLY`; anything used outside it needs `public`, including inits.
  - `FortnightlyKitTests`.
  - `ShiftStatusWidgetExtension`: folder `ShiftStatusWidget/`.
  - `ShiftPromptNotification`: code-based principal class, no storyboard.
- **Core Data:** uniqueness constraints are refused on an entity with a required to-one relationship (repositories find-or-create by `id` instead). The model isn't versioned yet.
- **No Swift language server; renames by hand.** `ast_edit` only matched one of four uses of a type name, so don't rely on it for renames.
- **The edit tool has twice mis-placed multi-range edits around function signatures.** Read the region back after editing.
- **Prototype pages:** serve with `hub start` → `python3 -m http.server 8765` in `prototype/`, check in the managed browser, then `open prototype/<file>.html` for the user.

## Open items needing the user (`DECISIONS.md`)

- Interview 3–5 international students (questions in PLAN §1).
- Quote the Home Affairs work-restrictions page from a browser; it blocks automated fetch.
- Install Record My Hours to confirm the comparison.
- Decide the commit email before pushing; create a private GitHub repo and give the tutor access.
- Later: README (the brief's required sections), the PDF (Sections 1–4, a draw.io diagram), zip + submit.
