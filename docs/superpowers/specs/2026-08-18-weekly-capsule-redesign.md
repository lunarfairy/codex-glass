# Codex Glass Weekly Capsule Redesign

## Goal

Replace the current two-window quota bar with a smaller, more refined single-value capsule that displays only the weekly remaining quota. Keep all existing background behavior, privacy guarantees, and installation behavior unchanged.

## Collapsed appearance

- Use a 176×52 logical-pixel always-on-top capsule.
- Show one compact `WEEK` label and one weekly remaining percentage, such as `71%`.
- Do not show the five-hour percentage, reset countdown, status copy, icons, or controls while collapsed.
- Use a fixed dark acrylic surface with a 20 px corner radius, restrained translucent border, subtle inner highlight, and soft shadow.
- Give the percentage the strongest visual weight. Keep the label small, widely tracked, and muted.
- Add a 2 px low-luminance progress light along the bottom interior edge. Its filled width represents the weekly remaining percentage; it must remain secondary to the number.

## Hover appearance

- Expand vertically to 82 logical pixels over 150 ms with an ease-out curve.
- Preserve the collapsed row without shifting its contents.
- Reveal only the weekly reset countdown in the added area, formatted as `6天 19小时后重置`.
- Collapse to 52 px when the pointer leaves.

## Behavior and data

- Continue reading both quota windows from the official local Codex App Server response so parsing compatibility is unchanged.
- Bind the UI only to the weekly quota and weekly reset time.
- Preserve automatic show/hide with Codex, topmost behavior, dragging, saved position, single-instance enforcement, startup registration, and one-minute refreshes.
- Preserve the last known weekly value during transient refresh failures.

## Scope

- Change only presentation constants, weekly view-model presentation, XAML composition, and directly related tests.
- Do not change the App Server protocol, process watcher, settings format, installer contract, or privacy model.

## Verification

- Unit tests verify the 176×52 collapsed and 176×82 expanded dimensions.
- View-model tests verify weekly percentage, weekly reset copy, and progress fraction.
- Release tests remain fully passing.
- Live verification confirms one visible weekly percentage, hover expansion, topmost state, automatic startup registration, and no listening ports.
- Rebuild the self-contained package, run uninstall/reinstall verification, and leave the updated version installed.
