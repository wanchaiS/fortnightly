---
version: 1
slug: "atures-fortnight-fortnightboardview-swift-7ebb1a81"
primary_target: "Fortnightly/Fortnightly/Features/Fortnight/FortnightBoardView.swift"
related_targets: ["Fortnightly/ShiftStatusWidget/ShiftStatusWidget.swift","Fortnightly/ShiftPromptNotification/ShiftPromptView.swift"]
---

# Fortnight board (home screen)

Scope: the app's home screen, plus the surfaces that reuse its language: the roster-a-shift sheet, the day sheet, shift details, the shift status widget, and the expanded shift prompt notification. Visitor mode: **Operate**.

- **Task:** in two seconds, answer "how close am I to 48 hours in each fortnight containing today?" and "what do I do right now?". Then tap a day to see or add shifts.
- **Content:** two work fortnights (worked and rostered hours per employer), the 14 days of the selected fortnight, the current shift state (next / clock-in due / on shift / clock-out due), missed shifts.
- **Constraints:** native iOS controls and navigation, the use cases' wording; nothing alarming, gamified, finance-dashboard or template-like (confirmed 2026-10-07). Two jobs on one day must stay readable. No calendar grid: too much information on a phone (the student's redesign, 2026-10-07).
- **Decided:** the dock shows one thing, in this order: clock in or out, then a missed shift, then the next shift. A shift that would breach the limit is saved with "Add anyway" (the inline warning is the acknowledgement). Screens drawn in `prototype/board-v2.html` and `prototype/screens.html` (branch `prototype/ui-variants`).
- **Memorable moment:** the donut and the day bars are one colour system; a shift's bar is the same colour as its slice of the donut.
- **Unresolved:** onboarding's illustration (was the timetable; redo with day rows showing one week in two fortnights); how employer colours are assigned (a fixed set of six, given in order of adding); Lock Screen accessory widgets render in one colour, so state there is carried by words and the plain donut.

## Direction contract

THESIS: The fortnight as one honest number and its days: a donut of the 48 hours coloured by employer, and the fortnight's 14 days as rows in the same colours. It refuses the calendar grid and the dashboard of cards.

OWN-WORLD: Deep navy shell (#16204A) for the navigation bar and dock, cool grey ground (#EEF0F6), white list cards. Employers have their own colours (violet #6F45E8, teal #0F8FA8, then four more), used identically in the donut slices and the day bars. Line form carries state: solid = worked, light hatched = rostered, dashed = being added, struck = not worked, an orange "?" on a missed shift until answered. Signal yellow (#FFC21A, navy text) means "act now" and nothing else. Green, orange and red appear only on the hours-left line and the 48 tick. SF Pro with tabular figures for every hour and time; today's label sits in a navy pill.

STORY: The student sees whether the fortnight around today is safe, sees what to do now, and trusts that the record is theirs and honest. They clock in or out from the dock, tap a day to see its shifts, and add a shift with its effect previewed before saving.

FIRST VIEWPORT: Navy shell: large title "Fortnight", toolbar "Jobs" and a plus symbol, a segmented control with the two fortnights containing today ("From Mon 12 Oct", "From Mon 19 Oct"). On the ground: a 200 pt donut, worked slices then rostered slices by employer, a tick at 48, "46.25" and "of 48 hours" in the centre; under it the hours-left line in its state colour and the employer key with each employer's hours. Then a "Did you work it?" row when a shift is missed. Then a white card of 14 day rows in two week groups: day label, a 12-hour bar holding up to two jobs, the day's total. Scrolling collapses the donut into a small one in the navigation bar. The dock is pinned at the bottom, navy with rounded top corners: the current shift's sentence, its detail, the yellow primary action ("Started 5:00pm") beside the secondary ("Just now").

FORM: Donut and day list, the student's redesign of the semester timetable (candidate 5 of 7 on the ordered list; seed key 052dfc4a, assigned). The timetable's world survives (palette, line-form states, reserved yellow, tabular figures); its grid and the one-week slide were dropped as too dense for a phone. Overlap stays visible through the fortnight switcher and the before → after rows for both fortnights. Raises kept: state by line form, not just colour; a missed clock-in stays marked until acknowledged; the head names the span in view; one numeral style across board, dock, widget and notification; one reserved colour for "act now".

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
