# Five-hour segmented meter design

## Goal

Add a compact five-hour quota meter to the always-on-top capsule without
changing its size, text hierarchy, or hover behaviour.

## Layout

- Keep the existing blue continuous line as the lower weekly meter.
- Add a green meter directly above it in the collapsed portion of the capsule.
- The green meter contains exactly ten evenly spaced rounded segments.
- A filled segment represents roughly ten percent of the five-hour remaining
  quota; unfilled segments use the existing muted line colour.
- Keep the existing `W E E K`, weekly percentage, and hover-only weekly reset
  copy unchanged.

## Data mapping

- Use `QuotaSnapshot.FiveHour.RemainingPercent`, already supplied by the
  app-server quota parser.
- Convert the percentage to a segment count by rounding to the nearest tenth
  away from zero and clamping the result to 0 through 10.
- Before the first successful quota response, all ten segments remain muted.

## Verification

- Unit-test 0%, 38%, and 100% five-hour values map to 0, 4, and 10 filled
  segments.
- Run the full test suite.
- Launch the local app and inspect the WPF automation tree to confirm the
  weekly percentage remains visible after the new meter is added.
