---
version: 1
slug: "atures-fortnight-fortnightboardview-swift-7ebb1a81"
primary_target: "Fortnightly/Fortnightly/Features/Fortnight/FortnightBoardView.swift"
related_targets: ["Fortnightly/ShiftStatusWidget/ShiftStatusWidget.swift","Fortnightly/ShiftPromptNotification/ShiftPromptView.swift"]
---

# Fortnight board (home screen)

Scope: the app's home screen, plus the surfaces that reuse its language: the roster-a-shift sheet, the day sheet, the shift status widget, and the expanded shift prompt notification. Visitor mode: **Operate**.

- **Task:** in two seconds, answer "how close am I to 48 hours in each fortnight containing today?" and "what do I do right now?". Then tap a day to see or add shifts.
- **Content:** two work fortnights (worked and rostered hours), 21 days of shifts per employer, the current shift state (next / clock-in due / on shift / clock-out due), missed shifts.
- **Constraints:** variant C structure, native iOS controls and navigation, the use cases' wording; nothing alarming, gamified, finance-dashboard or template-like (confirmed 2026-10-07). Two jobs on one day must stay readable.
- **Memorable moment:** the one-week slide.
- **Unresolved:** how employer colours are assigned (a fixed set of six, given in order of adding); the list-per-day layout at accessibility text sizes; Dark Mode values (tuned in the build); Lock Screen accessory widgets render monochrome, so state there is carried by line form only.

## Direction contract

THESIS: The home screen is the work fortnight itself, drawn as a semester timetable over which a 14-day frame slides one week at a time. It refuses the month-calendar grid and the fitness-ring dashboard.

OWN-WORLD: Deep navy shell (#16204A) for the navigation bar and dock, cool grey ground (#EEF0F6), white timetable card. Employers are timetable subjects with their own colours (violet #6F45E8, teal #0F8FA8, then four more). Line form carries state: solid block = worked, outlined and hatched = rostered, struck = not worked, an orange "?" badge on a missed shift until it's answered. Signal yellow (#FFC21A, navy text) means "act now" and nothing else. Green, orange and red appear only on the hours-left line and the 48 tick. SF Pro with tabular figures for every hour and time; today's date sits in a navy disc.

STORY: The student sees whether each fortnight around today is safe, sees what to do now, and trusts that the record is theirs and honest. They clock in or out from the dock, tap a day to see that day's shifts, and add a shift with its effect previewed on the timetable.

FIRST VIEWPORT: Navy shell: large title "Fortnight", toolbar "Jobs" and a plus symbol, then a segmented control with the two fortnights containing today ("From Mon 12 Oct", "From Mon 19 Oct"). On the ground: a 96 pt ring (worked solid, rostered at 35%, a tick at 48) beside "46.25 h" in title weight, "of 48 · 29.75 worked, 16.5 rostered", and the hours-left line in its state colour. Then the span, "Mon 12 – Sun 25 Oct". Then the timetable card: an M–S header, three week rows (last, this, next), with the two-week frame drawn as a 2 pt navy outline. Each day stacks one block per shift, sized by hours, with the day total underneath. Then the employer legend. The dock is pinned at the bottom, navy with rounded top corners: the current shift's sentence, its detail line, and the yellow primary action ("Started 5:00pm") beside the secondary one ("Just now").

FORM: Semester timetable. Candidate 5 of 7 on the ordered list (roster sheet, Opal tap on/off, swim between the flags, café docket rail, semester timetable, student planner, order-number board). Seed key 052dfc4a, assigned. Raises from the declined challengers: state by line form, not just colour (spectrogram rail); a missed clock-in stays marked until acknowledged (gate board); hours numerals sized from the grid module (Crouwel); the head names the span in view (lexicon); one numeral style across board, dock, widget and notification (bitmap specimen); one reserved colour for "act now" (airport signage).

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
