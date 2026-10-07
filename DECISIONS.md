# Decision Log

Raw material for the Required Document (Sections 2 and 4). Add an entry whenever you choose between options, hit a surprise, or change your mind. Keep entries short; the report keeps only the best 3–4.

**Entry template**

```
## YYYY-MM-DD — <decision in a few words>
Context:  what prompted it
Options:  what was considered
Chose:    what was decided
Why:      reasoning + evidence
Cost:     what we gave up
Report:   which section this feeds
```

---

## 2026-10-06 — Problem: international student work hours (visa condition 8105)
Context:  Needed a real, evidenced problem with a specific stakeholder.
Options:  Six candidates, each with an extension pairing:
          1. Visa-hours tracker for international students
          2. Rental move-in condition report
          3. Allergy-parent product checker
          4. Family carer medication tracker
          5. Graduate job application tracker
          6. Pantry expiry tracker
Chose:    1. Visa-hours tracker.
Why:      - A government-defined rule (48 hrs per fortnight) gives real business rules to enforce and test.
          - Strong published evidence.
          - Stakeholders I can actually interview (classmates).
          Rejected 6 as a very common student idea; 5 had mainly personal evidence.
Cost:     The domain involves visa law, so accuracy matters. The app must cite Home Affairs and say it isn't legal advice.
Report:   Section 4, Problem & justification

## 2026-10-06 — Doubted the widget as an extension
Context:  The first pairing for this idea was Widget + Share Extension.
Options:  Keep the widget showing "31 / 48 hrs" / look for extensions that fit the moments where things go wrong.
Chose:    Questioned the widget. Mapped the student's workflow to moments of risk:
          - A shift is offered.
          - A shift ends.
          - A payslip arrives.
          - Any time (general awareness).
Why:      Applying the brief's test, "would the stakeholder notice if it were removed?":
          - A number they could see by opening the app barely passes.
          - The decision to accept a shift happens inside a chat with the manager, not on the Home Screen.
Cost:     —
Report:   Section 4, Extension design decisions (would they notice if removed?)

## 2026-10-06 — Considered an Action Extension: "Can I take this shift?"
Context:  The moment of risk is accepting a shift offer inside a chat.
Options:  Select the offer text → Share → check it against the fortnight limit.
Chose:    Not in the core pair. Kept as an optional third extension.
Why:      - Strong fit to the moment.
          - But chat text like "Sat 5-11" is messy to parse.
          - Whether the share sheet is available inside Messages varies by app and iOS version, which puts end-to-end reliability at risk.
Cost:     No check at the exact moment of the offer. The roster screen warns when the shift is entered instead.
Report:   Section 2, Why these extensions (alternatives considered)

## 2026-10-06 — Considered a Share Extension for payslips with parsing; dropped parsing
Context:  Idea: share the payslip PDF from email → the app parses hours → compares with logged shifts.
Options:  1. No parsing (attach + manual entry)
          2. Assisted parsing (extract PDF text, pre-fill, confirm)
          3. Fully automatic (including OCR of photos)
Chose:    Dropped parsing and the payslip Share Extension entirely (see next entry).
Why:      - Payslip formats vary by payroll system.
          - Hours are split across penalty-rate lines.
          - Photos have no text layer.
          Later research reinforced the decision: underpaid migrant workers are more likely to get fraudulent payslips or none at all (Off the Books, 2026), so a payslip is an unreliable input.
Cost:     No automatic mismatch detection; the student compares hours themselves.
Report:   Section 4, Architecture under pressure / Extension design decisions

## 2026-10-06 — Final design: roster up front, clock-in/out prompts, widget as status and reminder (my proposal)
Context:  Rethought the app around the root cause: students forget to record, or record inaccurately.
Chose:    - The student enters rostered shifts up front (editable).
          - A notification at the rostered start asks them to clock in; another at the rostered finish asks them to clock out.
          - The widget keeps showing status ("Not clocked in", "On shift", "Still clocked in") until it's resolved.
          - The app totals fortnight hours across employers.
          - It warns on visa-limit breaches, both when a shift is planned and after it's worked.
          - The student compares their own record with their payslip.
          Extensions: **Notification Content Extension** + **Widget**.
Why:      - Captures accurate hours at the only moment they're known, at unusual hours, without relying on memory.
          - The widget's role changed from showing a number to showing clock status, with clock in/out buttons (iOS 17+ interactive widgets).
          - Rostered times let the widget schedule its own state changes.
Cost:     It depends on the student entering shifts. Reminder limits need careful scheduling (iOS allows 64 pending local notifications).
Report:   Section 2 (both extension scenarios) and Section 4 (how the design evolved)

## 2026-10-06 — Core Data, not CloudKit
Options:  Core Data (local, private) / CloudKit (sync, sharing)
Chose:    Core Data, with the store in the App Group container so both extensions can read and write it.
Why:      - Visa and work data is sensitive. Students fear information reaching immigration authorities (Farbenblum & Berg, 2020).
          - It must work offline at work.
          - The widget and notification need fast local reads.
          - No sharing or sync is needed.
Cost:     Losing the phone means losing the record. Mitigation: CSV export (stretch).
Report:   Section 2, Why this database / Section 4, Database decisions

## 2026-10-06 — Research changed my understanding of the problem
Findings:
- **The fortnight overlaps.** Home Affairs defines a fortnight as 14 days starting on a Monday, with an example of a breach in "weeks 2 and 3". Every week belongs to two fortnights, so tracking hours mentally or by pay cycle is unreliable. This became a core rule and a unit test.
- **Visa fear and wage theft are linked.** Almost two-thirds of international students didn't seek help with workplace problems, often because of visa concerns. The labour regulator can share information with immigration authorities about students who exceed their hours (Farbenblum & Berg, 2020). Staying within the limit *and* keeping one's own record is what makes it safe to question pay.
- **Employer records can't be trusted.** In the 2026 survey of 9,963 migrant workers, 65% were paid below entitlements, and deeper underpayment correlates with fraudulent or missing payslips (Off the Books, 2026).
- **An existing tool exists.** The FWO's Record My Hours app records hours by background location or manually. FWO notes automatic recording can fail on iPhone when the app has been in the background a long time. Its help page doesn't mention visa limits. Differentiation: driven by the roster (no location permission) and plans against the 48-hr rule before a shift is accepted.
Report:   Section 1 (evidence), Section 2 (why not an existing tool), Section 4 (has my understanding changed?)

## 2026-10-06 — Planned design decisions (to confirm during the build)
- **Warn, don't block,** when a rostered shift would breach the limit. An honest record beats a false clean one; the student decides after being warned.
- **Offer "Started on time" and "Started just now"** instead of guessing. The time of the tap isn't necessarily the time work started.
- **Widget buttons can't show errors,** so only buttons valid for the current state are shown.
- **Shared `FortnightlyKit` framework,** so the widget and notification extension run the same use cases as the app. No duplicated business rules.
- **Hours worked on course-break days are excluded** from the limit. Partial-overlap handling is my interpretation of "not in session"; state it in the document.
- **Scope ranked Must / Should / Could.** Payslip comparison (manual hours paid) is a "Could".

## 2026-10-06 — Spike: shared store proven across app, widget and notification extension
Context:  Extensions that crash or show "No data" score zero, so the riskiest integration was tested before any features.
Built:    - FortnightlyKit: `Employer` and `Shift` types, Core Data model (EmployerEntity → ShiftEntity), store in the App Group container, repositories.
          - A temporary test panel in the app.
Result (verified in the iPhone 17 / iOS 26.5 Simulator):
          - The app saved a shift to the App Group store; the row was confirmed on disk.
          - The widget (separate process) read it: "Next shift · Café Roma · Tue 11:34 pm".
          - The notification content extension (separate process) loaded the shift from the ID in the notification, and its custom view replaced the default one.
          - The widget extension saw the app's 2 pending reminders and cancelled one; iOS's pending list for the app was empty afterwards. So a Clock in tap on the widget can cancel the "not clocked in" reminders directly; the planned fallback isn't needed.
          - No Team is needed in the Simulator: the App Group is delivered as simulated entitlements.
Surprises:
          - Core Data rejects a uniqueness constraint on an entity with a required to-one relationship. Removed the constraints; repositories find-or-create by `id` instead.
          - Xcode 27 starts new projects as untitled drafts with multiplatform and iOS 27 defaults, and replaces the Simulator app with DeviceHub.
          - In DeviceHub a long-press on a notification registers as a tap, so the custom view only opens via swipe left → View. The README must tell markers this.
          - The custom view's last line was cut off at a fixed 150 pt height. The real notification feature should size it to its content.
          - Tapping "Save test shift" 4 times created 4 overlapping shifts. A live example of why `RosterShift` must reject overlaps (rule R7).
Report:   Section 4: extension design; architecture under pressure (de-risk the integration first)

## 2026-10-07 — Core rules built test-first (12 tests, 4 red/green rounds)
Context:  I chose the 12 tests myself from a longer list, keeping only those that guard a mistake that could plausibly be made (PLAN §13). Each round committed failing tests first, then the code.
Built:    `ReviewFortnightHours`, `RosterShift`, `ClockIntoShift`, `ClockOutOfShift`, each with a typed error enum whose messages say what went wrong and what to do next.
Findings:
          - **A test claim that wasn't true.** I assumed the Sunday-first test calendar made every test prove fortnights start on Monday. A mutation check (deleting the Monday rule) failed only the Sunday-midnight test; weekday-only scenarios can't tell the difference. One guarding test is enough, but the claim was corrected. Lesson: check what a test actually catches instead of assuming.
          - **Touching isn't overlapping.** Back-to-back shifts (5pm finish, 5pm start) must be allowed, so the overlap check uses strict comparisons. `DateInterval.intersects` would count touching shifts as overlapping, which is exactly what test 7 guards against.
          - **Clock-out reads before it saves.** If reading the fortnight data failed after saving, the student would be told the clock-out "couldn't be saved" when it had been. Reading first avoids that.
Decision: Simple guard rules I chose not to test are still enforced: finish after start, 14-hr rostering limit, already-finished shifts, archived employers, clock-in window, finish before clock-in. The tests target the rules where a mistake costs the student most (visa limit, overlaps, honest records).
Report:   Section 4: architecture under pressure (warn vs block, honest record); AI tools (how output was checked)

## 2026-10-07 — Screen structure: the fortnight board (prototype variant C)
Context:  Before building screens, a throwaway HTML prototype (branch `prototype/ui-variants`, `prototype/fortnightly-ui.html`) showed three structurally different versions of the whole app on the same fake data: A tabs, B timeline, C fortnight board.
Chose:    **C: the fortnight board.** A gauge for one work fortnight, a 14-day grid, and the current shift docked at the bottom.
Why:      The home screen is built around the visa rule itself (two overlapping fortnights, either of which can be breached). The grid makes "every week belongs to two fortnights" visible.
Prototype findings the use cases must now support:
          1. Worked and rostered hours separately (`FortnightWorkSummary` only has a total).
          2. A "before → after" preview of one shift without saving it (roster form and notification).
          3. Missed shifts (finished, never clocked in) still count as rostered hours; they need their own query and a "Did you work it?" prompt.
          4. Lists show each shift with its employer name.
Report:   Section 2 (design decisions before code); Section 4 (how the design changed)

## 2026-10-07 — Widget clock-in: two buttons
Context:  A widget button can't ask "on time or just now?". Recording the tap time would under-record a student who taps late (a 5:00pm start tapped at 5:40 loses 40 minutes).
Options:  Tap time (fast, can be wrong) / two buttons (never wrong, tight on the small widget) / open the app to choose (accurate, one extra step).
Chose:    **Two buttons on the widget:** "Started <rostered time>" and "Just now".
Why:      Product principle "ask, don't guess" (PRODUCT.md). Accuracy is the point of the record, and the widget is the fallback for students who missed the notification, so they're the likeliest to tap late.
Cost:     Short labels on the small widget.
Report:   Section 2 (widget scenario); Section 4 (architecture under pressure)

## 2026-10-07 — Product record and the impeccable design skill
Context:  I installed the impeccable design skill to guide the visual design. Its first step is a product interview, which produced `PRODUCT.md` (users, purpose, positioning, constraints, evidence, principles). I confirmed the summary, kept the name Fortnightly, and chose the widget's two buttons.
Source:   The legal definition of a fortnight is Migration Regulations 1994, Sch 8, condition 8105(3): "the period of 14 days commencing on a Monday". It's a better primary source than the Home Affairs page.
Report:   Section 1 (evidence); AI tools (how the design skill was used)

## 2026-10-07 — Visual direction: semester timetable
Context:  The design skill rolled one direction from my own list of seven (candidate 5, the uni semester timetable) and weighed six catalog challengers against it; all six lost on recognisability and clarity but each donated one discipline. I compared three directions as mocks of the same home screen (branch `prototype/ui-variants`, `prototype/directions.html`).
Options:  Semester timetable / roster sheet with highlighter / standard iOS.
Chose:    **Semester timetable.** Navy shell, employers as timetable subject colours, solid blocks for worked and outlined for rostered, yellow reserved for "act now", and the fortnight frame sliding one week at a time over three weeks.
Why:      The other two break down when a student works **two jobs in one day**, which is the common case: the roster sheet squeezes two highlights into one table row, and the standard list hides which day is heavy. The timetable stacks one block per shift inside the day; a mock with Café Roma 9am–3:15pm and Thai Express 5–11pm on the same Saturday stayed readable. The roster sheet's highlighter colours also looked odd. The one-week slide makes overlapping fortnights visible.
Recorded: direction contract in `.impeccable/surfaces/atures-fortnight-fortnightboardview-swift-7ebb1a81.md`.
Report:   Section 2 (design before code); Section 4 (how I evaluated design options)

---

## AI use log

| Date | What I asked | What the AI produced | What I kept / changed | How I checked it |
|---|---|---|---|---|
| 2026-10-06 | Transcribe the brief; explain it in plain terms | `ASSIGNMENT.md`, plain-language summary | Kept | Compared against the original brief |
| 2026-10-06 | Explain Core Data, CloudKit, extensions, App Group | Plain explanations with examples | Kept as learning | — |
| 2026-10-06 | App ideas | 6 ideas, each with stakeholder, extensions, entities, use cases | Chose idea 1 | Judged against which evidence I could get and who I could interview |
| 2026-10-06 | Whether the widget was justified | Agreed it was weak; suggested Action + Notification Content | Rejected the Action Extension as core; then proposed my own payslip and roster designs | Applied the brief's "would they notice if removed?" test |
| 2026-10-06 | Whether payslip parsing is hard | Difficulty levels and risks | Dropped parsing; **proposed the roster + clock-prompt design myself** | — |
| 2026-10-06 | Full plan | Web research + `PLAN.md` | (review pending) | Must verify: open the Home Affairs page in a browser (it blocked automated fetch); install Record My Hours to confirm its features |
| 2026-10-06 | Set up the Xcode project and test the extension integration (the spike) | Target settings, App Group entitlements, data layer, spike code; ran builds and checked the store on disk | I created the targets in Xcode myself; I did the visual checks (widget, notification) | Saw the widget and custom notification in DeviceHub; AI confirmed the shared store and pending reminders from files on disk |
| 2026-10-07 | Pick the core tests (TDD) | A longer list of candidate tests with the plausible bug each catches | **I chose 12** and declined the rest as low-risk | Mutation check on the Monday rule; the AI's claim about it was wrong and corrected |
| 2026-10-07 | Show what the screens could look like | Throwaway HTML prototype with 3 layouts, checked in a browser | **I chose C**, and two widget clock-in buttons | Walked through a shift in the prototype; it surfaced 4 missing use-case outputs |
| 2026-10-07 | Use the impeccable design skill | Product interview → `PRODUCT.md` | I confirmed the record and the name | Checked the product record against PLAN.md and my own answers |

**Lessons so far:**
- The AI's first extension suggestion (widget) had a weak justification. Questioning it led to a better design.
- Factual claims from AI research need checking against primary sources before they go in the PDF.

---

## Open questions / to verify

- [ ] Quote the Home Affairs work-restrictions page directly (opened in a browser)
- [ ] Install Record My Hours; confirm the location-based recording, the manual option, and that there's no visa-limit feature
- [ ] Interview 3–5 international students (questions in PLAN.md §1); record anonymised quotes here
- [x] Spike: does the App Group work in the Simulator? Yes, no Team needed
- [x] Spike: can the widget extension cancel the app's pending reminders? Yes
