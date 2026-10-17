# PBMS customer app: design notes

Base: the `main` branch UI (teal, white cards on slate-50). Refined with the repo-local
`taste-skill` and `impeccable` rules. Shared primitives live in `lib/core/widgets/pbms_ui.dart`.

- **Accent:** one only, teal `#087B8C` (`AppColors.brand`), tint `#EFFBFC`, line `#97DFEB`.
- **Status text colors** (>= 4.5:1 on white): ok `#047857`, warn `#B45309`, danger `#DC2626`.
  Do not use `AppColors.success/error/warning` for text.
- **Type:** Be Vietnam Pro everywhere (full Vietnamese diacritics). Scale in `PbmsText`;
  nothing below 12sp. Figures use tabular numerals (`PbmsText.figure`).
- **Surfaces:** cards are border-only (`PbmsCard`, radius 16), no border + shadow.
- **States:** every async block goes through `PbmsAsync` (skeleton, error with retry, empty that teaches).
- **Copy:** no em/en dashes, no uppercase eyebrows, no fake data. Labels above inputs.
- **Touch targets:** 48dp minimum.
