# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

SwiftUI, iOS 17 and later, iPhone only. Extensions: a WidgetKit widget (Home Screen small, Lock Screen rectangular and circular) and a notification content extension for shift prompts.

## Users

International students on a Student visa (subclass 500), studying in Sydney, working 2–4 casual hospitality shifts a week for one or two employers. Rosters arrive weekly by text message or a rostering app, and extra shifts are offered at short notice. They check their phone in short moments around work: arriving, on a break, after a late close, often at unusual hours.

## Product Purpose

Keep the student within the visa work limit and give them their own accurate record of the hours they worked.

- **The limit:** at most 48 hours in any work fortnight while the course is in session. A work fortnight is any 14 days starting on a Monday (Migration Regulations 1994, Sch 8, condition 8105(3)), so fortnights overlap and every week belongs to two of them.
- **The record:** actual clock-in and clock-out times across all employers, which the student holds up against their payslip.

Success: the student knows before accepting a shift whether it would breach the limit, never forgets to record a shift, and has a record they trust more than their employer's.

## Positioning

Driven by the roster, not by location. The student enters shifts as they're given; Fortnightly prompts at the rostered start and finish and keeps asking (widget) until the shift is recorded. It plans against the visa rule before a shift is accepted, rather than reporting a breach after it happens. The Fair Work Ombudsman's Record My Hours app records hours by background location and doesn't apply the visa limit.

## Operating Context

- **Weekly:** the roster arrives; the student enters each shift and sees its effect on both fortnights it falls in.
- **Each shift:** a notification at the rostered start ("Started on time" / "Started just now" / "Not working this shift") and at the rostered finish ("Finished on time" / "Finished just now" / "Still working"). The expanded notification shows the shift's effect on the fortnight.
- **Between:** the widget shows the next shift, a missing clock-in or clock-out, or the live shift, with buttons to act without opening the app.
- **Payday:** the student compares hours per employer and pay period with their payslip.

## Capabilities and Constraints

- Data stays on the phone (Core Data in an App Group shared with the extensions). No account, no server, works offline.
- Fixed product rules: 48-hour limit; Monday-start overlapping fortnights; hours worked during course breaks don't count. Students without the limit (research masters and PhD) aren't users, so there's no setting to turn it off.
- **Warn, don't block:** a shift that would breach the limit can still be saved after the student acknowledges it, and a worked breach is always recorded. The record must match what happened.
- The time of a tap is not assumed to be the time work started or finished. Where the student can't be asked (notification and widget buttons), both options are offered: the widget has two clock-in buttons, "Started <rostered time>" and "Just now".
- Shifts can't overlap; touching end to start is allowed.
- Not legal advice: the app says so and points to VEVO for the student's actual visa conditions.
- Out of scope: payslip parsing, checking pay rates against awards, cloud sync.
- Terminology: employer, shift, roster/rostered, clock in/out, on shift, worked, not worked, work fortnight, work limit, course break, pay period.

## Brand Commitments

The product name is **Fortnightly**.

## Evidence on Hand

- Department of Home Affairs, "Work restrictions for student visa holders" (48 hrs per fortnight; the weeks 2–3 breach example).
- Migration Regulations 1994, Schedule 8, condition 8105(3): "fortnight means the period of 14 days commencing on a Monday".
- Farbenblum & Berg (2020), *International Students and Wage Theft in Australia*: under-payment and fear of visa consequences.
- Migrant Justice Institute (2026), *Off the Books*: 65% of migrant employees underpaid; missing or false payslips.
- Student interviews have **not** been done yet. Don't invent quotes, testimonials or usage numbers.

## Product Principles

1. **Before, not after.** Show the visa consequence when a decision is still open: when rostering, accepting or clocking in.
2. **An honest record beats a clean one.** Never hide, round away or refuse real hours worked.
3. **Meet the student in the moment.** Prompts, widgets and one-tap actions over screens they must remember to open.
4. **Ask, don't guess.** When the app can't know a time, it offers the choices.
5. **Private by default.** Work and visa data never leave the phone.
