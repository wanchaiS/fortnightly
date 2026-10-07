# Finish review: Fortnight board and related surfaces (round 1)

Run inline: this harness has no finish-reviewer agent, so `reference/degraded/finish-reviewer.md` was followed in the build thread.
Not read: a QUALITY BAR card (none exists for this code-led build) and comp-diff reports (code-led, no comp round). Critique reference: `prototype/board-v2.html` (prototype branch), not binding.

disposition: fix

## persistence

Pass. PRODUCT.md present. Code-led build, so no `.impeccable/build/state.json` or comp round is expected. FORM carries seed key 052dfc4a. DESIGN.md is absent because this is a new world; the documenter writes it after this review. Captures in `.impeccable/review/`: `phone.png` plus scrolled, other fortnight, roster, missed shift, Jobs, dark, large text (two), Home Screen widget, Lock Screen, expanded prompt. All valid iPhone 17 captures (1206 × 2622).

## fidelity

| Element | Verdict |
|---|---|
| Navy shell, large title "Fortnight", Jobs and plus | Adaptation: iOS 26 draws the toolbar buttons as one glass capsule; the large title is drawn in the shell header because the system title stays dark on a coloured bar |
| Fortnight switcher | Adaptation: native segmented control in its dark style (grey selected segment, not white with navy text); the region adds a comma ("From Mon, 28 Sep") |
| Donut: worked solid, rostered light, tick at 48, centre number | Match |
| Hours-left line in its state colour | Match in placement and wording; contrast below the floor (fix 1) |
| Employer key with hours | Match |
| "Did you work it?" row | Match |
| 14 day rows in two week groups, 12-hour bars, hatched rostered, yellow ring when due, today pill | Match |
| Orange "?" on a missed shift | Match on the board; missing on the expanded prompt's day row (fix 2) |
| Donut collapsing into the bar on scroll | Match |
| Dock: sentence, detail, yellow primary, secondary | Match; at accessibility sizes the detail line is dropped to leave room for the board |
| Roster sheet: day-row preview (dashed), before → after for both fortnights, "Add anyway" | Match |
| Shift details | Adaptation: grouped-list rows instead of the mock's filled buttons (HIG grouped lists) |
| Home Screen small widget, Lock Screen rectangular and circular | Match |
| Expanded prompt: small donut, day row, actions with real times | Adaptation: "40.75 → 46.25" became "46.25 of 48 h this fortnight" |
| TYPE | Match: SF Pro, tabular figures for hours and times |
| MATERIAL | Match: flat vector, as the reference |
| GROUND | Match: #EEF0F6 light, #0D1120 dark |

## ceiling

Unused: switching fortnights cuts instead of moving the donut between values; the collapse crossfade is the only motion. Not material for an Operate surface.

## material_fixes

1. Floor, contrast: the hours-left line's orange (#D9480F, 3.77:1) and green (#2B8A3E, 3.83:1) on the cool grey ground fail 4.5:1 for 15 pt semibold text. Darken the light-mode variants to at least 4.5:1; red (4.79:1) passes.
2. Contract (OWN-WORLD, "a missed clock-in stays marked until acknowledged"): the expanded prompt's day row shows a missed shift without its orange "?". Mark it there as on the board, from one shared rule.

## keep

One colour system: a shift's bar is the same colour as its slice of the donut on the board, the widget and the prompt.

# Verdict pass (round 2)

Recaptured over the same files: `phone.png`, `phone-prompt.png`.

## verdict

1. Contrast of the hours-left line: resolved. `phone.png` shows "1.75 h left before the limit" in the darker orange (#B8400E, 4.88:1 on the ground); green is now #237A35 (4.72:1).
2. Missed shift unmarked on the prompt: resolved. `phone-prompt.png` shows the orange "?" beside Wed 7, where the Thai Express shift finished without a clock-in.

Regressions from the fix batch: none visible.

## remaining

clear

disposition: ship
