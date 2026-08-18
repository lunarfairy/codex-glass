# Codex Glass Light Apple Capsule Design

## Goal

Turn the weekly quota overlay into a light, transparent, fully rounded capsule with the calm visual language of an Apple floating surface.

## Chosen visual direction

Use light acrylic glass rather than an opaque white card or a dark translucent surface. This choice keeps the requested transparency while retaining enough contrast for the weekly percentage on varied desktop backgrounds.

## Appearance

- Use a 184×56 logical-pixel collapsed capsule with a 28 px corner radius; it is visually a full pill rather than a rounded rectangle.
- Expand to 184×88 on hover and reveal the unchanged weekly reset copy.
- Use a low-opacity white and pale blue-grey acrylic surface, a thin semi-transparent white rim, and a top inner highlight.
- Render `W E E K` in muted slate grey and the percentage in deep blue-grey; remove the former high-contrast white-on-black treatment.
- Use one restrained blue progress line along the lower interior edge. It remains secondary to the percentage.
- Keep the existing typography hierarchy, drag behavior, topmost behavior, saved position, automatic Codex visibility, local App Server data source, and startup registration.

## Technical scope

- Update only `GlassLayout`, `MainWindow.xaml`, the acrylic color in `GlassBackdrop`, the matching layout test, and user-facing usage text if it describes the dark appearance.
- Preserve the weekly-only view model and all quota, process, installer, and privacy code unchanged.

## Verification

- Tests prove the 184×56 collapsed and 184×88 expanded layout contract.
- Release tests remain fully passing.
- The installed app visibly renders one weekly percentage in a light capsule, expands on hover, remains topmost, and uses no listening ports.
- Rebuild and install the self-contained package so the displayed desktop version is the new light design.
