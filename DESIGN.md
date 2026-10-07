---
name: Fortnightly
description: The visa work fortnight as one honest number and its days.
colors:
  shell: "#16204A"
  shell-dark: "#0B1030"
  ground: "#EEF0F6"
  ground-dark: "#0D1120"
  card: "#FFFFFF"
  card-dark: "#161B2E"
  ink: "#16204A"
  ink-dark: "#E8EBF5"
  muted: "#5B6275"
  muted-dark: "#9AA2B8"
  track: "#E3E6EF"
  track-dark: "#252D47"
  tint-dark: "#A5B4FC"
  act-now: "#FFC21A"
  within-limit: "#237A35"
  within-limit-dark: "#51CF66"
  near-limit: "#B8400E"
  near-limit-dark: "#FF922B"
  over-limit: "#C92A2A"
  over-limit-dark: "#FF6B6B"
  employer-violet: "#6F45E8"
  employer-violet-dark: "#9775FA"
  employer-teal: "#0F8FA8"
  employer-teal-dark: "#3BC9DB"
  employer-magenta: "#C2378A"
  employer-magenta-dark: "#F06BB6"
  employer-cobalt: "#2F66D0"
  employer-cobalt-dark: "#74A0FF"
  employer-bronze: "#9A5B2B"
  employer-bronze-dark: "#D9A066"
  employer-moss: "#5F7A1F"
  employer-moss-dark: "#A9C25A"
typography:
  display:
    fontFamily: "SF Pro (system), Dynamic Type Large Title"
    fontSize: "34pt"
    fontWeight: 700
    fontFeature: "tnum"
  headline:
    fontFamily: "SF Pro (system), Dynamic Type Headline"
    fontSize: "17pt"
    fontWeight: 600
  body:
    fontFamily: "SF Pro (system), Dynamic Type Body"
    fontSize: "17pt"
    fontWeight: 400
  title:
    fontFamily: "SF Pro (system), Dynamic Type Subheadline"
    fontSize: "15pt"
    fontWeight: 400
    fontFeature: "tnum"
  label:
    fontFamily: "SF Pro (system), Dynamic Type Caption and Footnote"
    fontSize: "12pt"
    fontWeight: 600
    fontFeature: "tnum"
rounded:
  segment: "4pt"
  bar: "5pt"
  pill: "7pt"
  widget-button: "9pt"
  control: "12pt"
  card: "14pt"
  dock: "18pt"
spacing:
  tight: "8pt"
  inner: "14pt"
  margin: "16pt"
  row: "44pt"
components:
  button-act-now:
    backgroundColor: "{colors.act-now}"
    textColor: "{colors.shell}"
    typography: "{typography.headline}"
    rounded: "{rounded.control}"
    height: "48pt"
  button-dock-plain:
    backgroundColor: "{colors.card}"
    textColor: "{colors.shell}"
    typography: "{typography.headline}"
    rounded: "{rounded.control}"
    height: "48pt"
  days-card:
    backgroundColor: "{colors.card}"
    rounded: "{rounded.card}"
    padding: "0 14pt"
  day-row:
    typography: "{typography.title}"
    height: "{spacing.row}"
  day-bar-track:
    backgroundColor: "{colors.track}"
    rounded: "{rounded.bar}"
    height: "16pt"
  today-pill:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.card}"
    rounded: "{rounded.pill}"
  answer-row:
    backgroundColor: "{colors.card}"
    textColor: "{colors.ink}"
    rounded: "{rounded.control}"
    padding: "12pt"
  dock:
    backgroundColor: "{colors.shell}"
    textColor: "{colors.card}"
    rounded: "{rounded.dock}"
    padding: "14pt 16pt 8pt"
---

# Design System: Fortnightly

## Overview

**Creative North Star: "The Honest Fortnight"**

The whole system serves one reading: how close the student is to 48 hours in each work fortnight around today, and what to do right now. The fortnight is drawn as one honest number, a donut of the 48 hours coloured by employer, and as its 14 days, each a 12-hour bar in the same colours. Nothing is rounded away, nothing is hidden: a missed clock-in stays marked until answered, and a shift that wasn't worked stays on its day, struck through.

The look comes from the semester timetable the student already lives by: a deep navy shell for the navigation bar and the dock, a cool grey ground, white cards, and employers as timetable subject colours. It is an Operate surface on iOS: native navigation, native sheets, grouped lists and system controls carry the structure; the world speaks through palette, line form, the donut and the day bars. The density is a working tool's, not a dashboard's: one number, one line of status, one action.

It refuses the calendar grid (too much on a phone), the dashboard of cards, gamified progress, and anything alarming. An over-limit fortnight turns one line red and moves the tick; nothing flashes.

**Key Characteristics:**
- One colour system: an employer's colour is identical in the donut slice, the day bar, the widget and the prompt.
- State carried by line form, never by colour alone.
- A single reserved "act now" yellow.
- Tabular figures for every hour and time.
- Navy shell top and bottom, grey ground, white cards, in light and dark.

## Colors

A navy-and-grey timetable with six subject colours and exactly two kinds of signal: a yellow that asks for action and a three-step hours line.

### Primary
- **Timetable Navy** (shell; shell-dark in Dark Mode): the navigation bar, the shell header with the fortnight switcher, and the dock. It frames every board screen top and bottom and is the app icon's ground.

### Secondary
- **Subject Violet** (employer-violet): the first employer added.
- **Subject Teal** (employer-teal): the second.
- **Subject Magenta, Cobalt, Bronze, Moss** (employer-magenta, employer-cobalt, employer-bronze, employer-moss): the third to sixth. A new employer takes the first colour no current employer uses; a seventh current job starts again from violet. Each has a lifted Dark Mode variant (the `-dark` keys).

### Tertiary
- **Act-Now Yellow** (act-now, with navy text): the primary button when a clock-in or clock-out is due, the ring around a shift that has started without a clock-in, and the widget's due buttons.
- **Within, Near and Over** (within-limit, near-limit, over-limit, with `-dark` variants): the hours-left line ("19.25 h left", "1.75 h left before the limit", "2.25 h over the limit"), the dot beside each fortnight in the roster sheet's before → after rows, and over-limit text. Light variants are at least 4.5:1 on the ground.

### Neutral
- **Cool Paper** (ground; ground-dark): the screen field under every board, sheet and list.
- **Card White** (card; card-dark): the day card, the "Did you work it?" row, grouped list rows, the widget background.
- **Navy Ink** (ink; ink-dark): primary text, the 48 tick, the today pill.
- **Slate** (muted; muted-dark): secondary text, empty days, the employer key's names.
- **Track Grey** (track; track-dark): the empty part of every day bar and the donut's unfilled ring.
- **Lifted Periwinkle** (tint-dark): links and sheet buttons in Dark Mode; in light mode the tint is Navy Ink.

### Named Rules
**The One Colour System Rule.** A shift's bar and its slice of the donut are the same employer colour, everywhere the shift appears. Never recolour a job for emphasis.

**The Act-Now Rule.** Yellow appears only where the student should act now: a due clock-in or clock-out. It is never decoration and never an employer.

**The Hours-Line Rule.** Green, orange and red belong to the hours left against 48 and nothing else: not jobs, not bars, not buttons.

## Typography

**Display Font:** SF Pro (system, Dynamic Type)
**Body Font:** SF Pro (system, Dynamic Type)

**Character:** The platform face, set heavy for the one number that matters and plain everywhere else; every hour and time in tabular figures so columns of hours line up.

### Hierarchy
- **Display** (700, Large Title 34 pt): the "Fortnight" title in the shell header, the hours in the donut's centre, onboarding headings.
- **Headline** (600, Headline 17 pt): the dock's sentence, the compact summary when the donut collapses, button labels.
- **Body** (400, Body 17 pt): list rows, form fields.
- **Title** (400, Subheadline 15 pt; 600 for emphasis): day rows, the hours-left line (semibold), the "Did you work it?" row.
- **Label** (600, Caption 12 pt / Footnote 13 pt): week headers with their totals, the employer key, widget captions.

### Named Rules
**The Tabular Figures Rule.** Hours and times always use tabular figures (`monospacedDigit`), on the board, the dock, the widget and the prompt.

**The Dynamic Type Rule.** Every size is a system text style. At accessibility sizes the day bars give way to a plain list of the days with shifts, and the dock keeps only its sentence and buttons.

## Layout

One column with 16 pt margins. The board stacks, top to bottom: the navy shell (large title, the switcher for the two fortnights containing today), the 200 pt donut with the hours-left line and employer key, the "Did you work it?" row when a shift is missed, then one white card of 14 day rows in two week groups, each group headed by its dates and total. Blocks are 12 pt apart; rows are at least 44 pt tall; inside the card rows have 14 pt side padding.

The dock is pinned to the bottom safe area and shows one thing, in this order: clock out or in, then a missed shift, then the next shift. Scrolling collapses the donut into a 44 pt donut and "46.25 of 48 h" line inside the shell, with an inline title in the bar. Sheets (roster, day, shift details, times) and Jobs use native grouped lists on the grey ground.

## Elevation & Depth

Flat, layered by tone: grey ground, white cards above it, navy shell framing both. There are no card shadows. Depth beyond that comes from the system: sheets, the iOS 26 glass toolbar capsule, the notification and widget chrome. The one authored shadow is the notification preview on onboarding (soft, 6 pt down, 12 pt blur, 12% black), standing in for a real banner.

### Named Rules
**The Flat Card Rule.** Cards are separated by tone and spacing, never by shadow or coloured edges.

## Shapes

Softly rounded rectangles throughout: bar segments 4 pt inside a 5 pt track, the today pill 7 pt, widget buttons 9 pt, buttons and single-row cards 12 pt, the day card 14 pt, the dock's top corners 18 pt. The donut is a ring with butt ends, a 2 pt gap between slices, and a round-capped tick at 48; past 48 the ring rescales so the tick moves back and the overflow shows beyond it.

### Named Rules
**The Line-Form Rule.** State is carried by form: solid for worked, light hatched with a 1.5 pt edge for rostered, a yellow edge for started without a clock-in, outlined and struck through for not worked, dashed for the shift being added, and an orange "?" on the day of a missed clock-in.

## Components

### Buttons
- **Shape:** gently rounded (12 pt), at least 48 pt tall in the dock.
- **Act now:** yellow fill, navy bold label ("Started 5:00 pm", "Finished 10:30 pm").
- **Plain:** white fill, navy label, for actions that aren't urgent ("Roster a shift", "Clock out now", "Yes, enter my times").
- **Secondary:** white at 14% on navy, white label ("Just now", "No, I didn't").
- Pairs sit side by side and stack when large text doesn't fit. Pressed state dims to 75%.

### Cards / Containers
- **Corner Style:** 14 pt for the day card, 12 pt for single rows.
- **Background:** Card White on Cool Paper.
- **Shadow Strategy:** none (see Elevation & Depth).
- **Internal Padding:** 14 pt sides in the day card, 12 pt in single rows.

### Inputs / Fields
- **Style:** native grouped Form rows; dates and times are compact system date pickers; the employer choice is a segmented control for up to three jobs and a menu beyond.
- **Error:** the use case's own message and recovery appear in a tinted row under the form as the student types (over-limit red at 12%), and the confirm button becomes "Add anyway" in red when the only problem is the limit.

### Navigation
- **Style:** native navigation stack with a navy bar and a white title; board-level actions (Jobs, plus) in the trailing toolbar. Sheets for self-contained tasks, with Cancel and a confirming action. The switcher is the native segmented control on the shell.

### Fortnight Donut
The signature. Worked slices first, then rostered slices at 42% opacity, each in employer colour order, over a track-grey ring, with a navy tick at 48. 200 pt with a 22 pt ring on the board, 44 pt in the collapsed header and the widget, 60 pt in the prompt. The centre carries the hours in Display and "of 48 hours" in Slate.

### Day Row
Weekday (bold) and date, a 12-hour bar holding up to two shifts side by side (a longer day stretches the scale), and the day's total right-aligned in tabular figures. Today's weekday sits in a navy pill. A missed clock-in adds an orange "?". Empty days show the label and an en dash in Slate.

### Dock
Navy, rounded top corners, pinned to the bottom: one sentence ("Café Roma started at 5:00 pm"), one detail line, and the buttons for the current state.

### Shift Status Widget
Small: the donut with the hours (or the employer and "Not clocked in" when due) and the state's buttons. Lock Screen: one-colour rectangular text and a circular capacity gauge, with words carrying the state.

## Do's and Don'ts

### Do:
- **Do** give every new employer one of the six subject colours and use it identically in the donut and the bars.
- **Do** keep yellow for the action that is due now, with navy text.
- **Do** show worked and rostered hours in the same slice colour, worked solid and rostered at 42%.
- **Do** keep a missed or not-worked shift visible on its day, marked by its form.
- **Do** set every hour and time in tabular figures and every size as a Dynamic Type style.
- **Do** use native sheets, grouped lists and system controls; express the world through palette, line form, the donut and the day bars.

### Don't:
- **Don't** draw a calendar grid of the fortnight.
- **Don't** build the board from dashboard cards, progress badges or anything gamified.
- **Don't** make an over-limit fortnight alarming: one red line and the moved tick are enough.
- **Don't** use green, orange or red for jobs, bars or buttons.
- **Don't** add shadows or coloured edges to cards.
