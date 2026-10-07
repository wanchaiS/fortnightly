# Session handoff — Fortnightly (UTS iOS Assessment 3)

Read this first, then `ASSIGNMENT.md` (the brief; local only, gitignored), `PRODUCT.md`, `DESIGN.md`, `DECISIONS.md` and the relevant `PLAN.md` sections. Last updated 2026-10-08 (submission day).

## What the project is

An iPhone app for international students on a subclass 500 visa working casual hospitality shifts. It keeps them within the visa work limit (48 hours in **any** 14 days starting on a Monday, so fortnights overlap) and gives them their own accurate record of hours worked across employers. The student rosters shifts up front; the app prompts at rostered start and finish to clock in and out; a widget keeps nagging until the shift is recorded.

- **Extensions:** Notification Content Extension (custom clock-in/out prompt) + WidgetKit widget (Home Screen small, Lock Screen rectangular and circular, interactive clock-in/out buttons).
- **Database:** Core Data, store in the App Group `group.com.peter.fortnightly`.
- **Architecture:** SwiftUI Views → ViewModels → Use Cases (structs, typed errors) → Repository protocols → Core Data. All logic lives in the `FortnightlyKit` framework, shared by the app and both extensions.

## Working with the user (important)

- UTS student, writing in English as a second language. Explain plainly, in short sections. They make the product and design decisions; offer options with trade-offs and a recommendation, then follow their call.
- **Simplicity first (their instruction, 2026-10-07).** No over-engineering; readability is the key. Comments only where the code isn't self-explanatory: a business rule or an outside factor (iOS limits, Core Data). Reuse an existing use case before adding a new one.
- **TDD, tests chosen together.** Before any new logic, propose candidate tests (each naming the plausible bug it catches) with the `ask` tool, multi-select, recommended ones marked. They pick. Then red commit (`test(...)`, with the API and a stub so it compiles and fails), green commit (`feat(...)`), per group. If they "can't judge from text", draw a visual storyboard (see `prototype/test-storyboard.html`).
- **Design before code, shown not described.** They judge designs from HTML mocks opened in their browser, not text.
- Record decisions in `DECISIONS.md` with "I" as the decider, and keep the AI-use table updated (it feeds the reflective report and the AI section).

## Repo and git conventions

- `main` holds only stable, tested code. Work on `feature/...` (or `chore/`, `docs/`) branches, merge with `git merge --no-ff`, then delete the branch. Conventional Commits (`feat:`, `fix:`, `test:`, `docs:`, `refactor:`, `chore:`).
- `ASSIGNMENT.md` must never be committed (UTS material); it's in `.gitignore`.
- Throwaway prototypes live only on branch `prototype/ui-variants` (`prototype/*.html`); never merge it into main. A worktree of it may exist at `../ios_ass3-prototype`.
- Commit author is `peter <peter.wanchai@shinko1.ai>`. The user hasn't decided whether to change it before the first push (open item).

## Key files

| File | What it is |
|---|---|
| `README.md` | For markers: overview, domain, architecture, extensions, database, App Group, setup, sample data, tests. |
| `PRODUCT.md` | Product record (users, purpose, positioning, constraints, principles). |
| `DESIGN.md` + `.impeccable/design.json` | The visual system as built ("The Honest Fortnight"): tokens, named rules, components. New screens follow it. |
| `PLAN.md` | Full plan. §4 rules, §8 use cases, §13 all 31 tests with Given/When/Then, §14 project setup. Parts of §9–12 still describe the old tab layout; §10's "before → after" in the notification was simplified (see DECISIONS). |
| `DECISIONS.md` | Dated decision log, AI-use table, open items checklist. |
| `.impeccable/surfaces/…fortnightboardview…md` | Direction contract for the board and related surfaces (now with the resolved items). |
| `.impeccable/review/` | Simulator captures (light, dark, large text, widget, Lock Screen, prompt) and `finish-review.md` (disposition: ship). Good material for the PDF. |
| `tools/make_app_icon.py` | Draws the app icon (donut on navy); needs Pillow. |
| `prototype/board-v2.html`, `screens.html`, `open-designs.html` (prototype branch) | Approved designs. |

## Code state (31 tests pass)

**FortnightlyKit**
- **Domain:** `Employer` (with `EmployerColour`, six colours), `Shift`, `CourseBreak`, `WorkFortnight`, `WorkLimitPolicy`, `FortnightWorkSummary` (now with `hoursByEmployer`), `ShiftReminder` (prompt plan per shift), `ShiftListing` (shift + employer name + colour), formats.
- **Use cases:** `ReviewFortnightHours`, `ReviewFortnightDays` (14 `WorkDay`s), `ReviewCurrentShift` (what the dock and widget show), `ReviewMissedShifts`, `ReviewShift`, `ReviewJobs`, `RosterShift` (also undoes "not working" for an upcoming shift), `ClockIntoShift`, `ClockOutOfShift`, `MarkShiftNotWorked`, `LogPastShift` (new past shift, missed shift's times, **correct a worked shift's times**, undo "not working" for a finished shift), `AddEmployer`, `ArchiveEmployer`, `RecordCourseBreak`, `RemoveCourseBreak`, `RefreshShiftReminders` (rolling window of the next 10 shifts plus the open shift).
- **Persistence:** Core Data repositories for shifts, employers, course breaks; every read refetches (other processes write too).
- **Platform:** `FortnightlyServices` (wires every use case to the App Group store, used by all three targets), `NotificationReminderScheduler`, `WidgetDisplayRefresher`, `ShiftPromptCategory`/`ShiftPromptAction`, `ShiftPromptResponder` (notification buttons → use cases), `SampleRoster` (debug sample data).
- **Display:** `Palette`, `FortnightDonut`, `DayBar`/`DayRow` — the shared look for app, widget and prompt.

**App (`Fortnightly/Fortnightly`)**: `Features/Fortnight` (board, dock, model), `Roster`, `Day`, `Shift` (details, times sheet), `Jobs`, `Onboarding`; `Shared/` (problem alerts, navy bar, shift actions). `AppDelegate` handles prompt buttons from banners.

**Widget (`ShiftStatusWidget/`)**: timeline from `ReviewCurrentShift` + `ReviewFortnightHours`; App Intents `ClockInIntent` (rostered time / just now) and `ClockOutIntent`.

**Notification (`ShiftPromptNotification/`)**: donut, hours, the shift's day row; buttons with real times set per shift; sizes to its content; stale prompts say what already happened.

## Next steps

Done 2026-10-08: public repo https://github.com/wanchaiS/fortnightly (all branches pushed); `README.md`; the Required Document `report/Fortnightly-Report.pdf` (8 pages: Sections 1–4 and references; source `report/report.html`, diagram `report/architecture.excalidraw` → `architecture.png`); submission copies in `~/Desktop/Fortnightly submission/`.

1. The user submits on Canvas: the PDF, the project zip and the repo link.
2. Still open: student interviews (the report says honestly that none were done); install Record My Hours (the report relies on the Fair Work Ombudsman's own pages).
3. To change the PDF: edit `report/report.html`, open it through a local server from the repo root (images use `../.impeccable/review/`), print to PDF (A4, background graphics on). Section 3 uses a landscape named page. To change the diagram: edit `report/architecture.excalidraw` (excalidraw.com, or the generator in this session), open `report/render-excalidraw.html` through the same server, and save the rendered SVG as `architecture.png` at 2x.
4. Optional polish noticed in review (not material): animate the donut when switching fortnights; the native segmented control on navy uses its dark style rather than the mock's white selected segment.

## Environment gotchas

- **Xcode 27, iOS 26.5 Simulator** (iPhone 17, UDID `302AF005-18F9-42AA-B575-DA17506C6F5F`). The Simulator app is DeviceHub. No Team needed; the App Group is delivered as simulated entitlements.
- **Build and test:**
  ```
  xcodebuild -project Fortnightly/Fortnightly.xcodeproj -scheme Fortnightly -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -derivedDataPath /tmp/fortnightly-dd test 2>&1 | grep -E '(error:|warning: [^M]|Test case.*failed|TEST (SUCCEEDED|FAILED))' | sort -u
  ```
  About 25–40 s.
- **Core Data model changes need a reinstall** (`xcrun simctl uninstall <udid> com.peter.fortnightly`): the model isn't versioned.
- **Sample data:** launch with `xcrun simctl launch <udid> com.peter.fortnightly -sampleRoster` on a fresh install (skips onboarding; only loads when there are no employers). A fresh install with shifts shows the notification permission alert first.
- **AXe** (installed with Homebrew) taps the Simulator: `axe tap --label "Jobs" --udid <udid>`, `axe tap -x 106 -y 808 …`, `axe swipe …`, `axe type …`, `axe describe-ui …`, `axe screenshot --output <file> …`. Labels with times contain a narrow no-break space before "pm"; tap those by coordinates. `xcrun simctl terminate` the app to reach the Home Screen; `axe button lock` twice reaches the Lock Screen.
- **Test a prompt:** find a shift id with `sqlite3 "$(xcrun simctl get_app_container <udid> com.peter.fortnightly group.com.peter.fortnightly)/Fortnightly.sqlite" "select hex(ZID), ZSTATUS from ZSHIFTENTITY"`, put it (dashed UUID) in an APNs payload with `"category":"SHIFT_START"` and `"shiftID"`, `xcrun simctl push`. Then swipe down from the top-left for the list, swipe the prompt left a little (330 → 220), tap View.
- **iOS 26 navigation bars:** the system title stays dark on the navy bar, so `navyNavigationBar(title:)` draws a white principal title; a conditional toolbar item didn't update, so the title's visibility uses opacity. Use `Palette.shell(for:)` under a forced-dark bar.
- **Targets:** `FortnightlyKit` is nonisolated and `APPLICATION_EXTENSION_API_ONLY` (anything used outside needs `public`, including inits); the app defaults to MainActor; new files are picked up automatically (synchronized folders).
- **No Swift language server; renames by hand.** The edit tool can mis-place multi-range edits; read the region back after editing.
