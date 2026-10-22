# PBMS customer app: design notes

Visual language: **"Cuống vé xe & biển báo bãi xe"** (parking stub and lot signage), on the
`main` branch base (teal, white surfaces on slate-50). Refined with the repo-local `taste-skill`
and `impeccable` rules. Shared primitives live in `lib/core/widgets/pbms_ui.dart`; parking-specific
components in `lib/core/widgets/parking/` (exported from `pbms_ui.dart`).

- **Accent:** one only, teal `#087B8C` (`AppColors.brand` / `AppColors.primary`), tint `#EFFBFC`,
  line `#97DFEB`. No other hues in `AppColors` (royal blue, sky, indigo, Material 3 set removed).
- **Status colors** (>= 4.5:1 on white): ok `#047857`, warn `#B45309`, danger `#DC2626`
  (`AppColors.success/warning/error` now use these values).
- **Type:** Be Vietnam Pro everywhere (full Vietnamese diacritics), set once in the theme.
  Scale in `PbmsText`; nothing below 12sp. Body is w400, w600 for labels/emphasis.
  Headline numbers (time parked, fee, balance, exit code) use `PbmsText.display` (40-52sp, w800,
  tabular). Lists use `PbmsText.figure`.
  **Buttons:** never set `textStyle` inside `styleFrom` (it drops the theme font); style the
  `Text` child instead.
- **Domain components:**
  - `PbmsPlate`: Vietnamese plate, white with ink outer and silver inner border; motorbikes on
    two lines ("59-X2" / "123.45").
  - `PbmsTicketStub`: paper `#F9F9F6` stub with notch cut-outs and a dashed tear line, soft
    shadow (no border). For the active session, upcoming reservation and exit pass.
  - `PbmsLedCounter`: dark panel with large tabular counts like the lot entrance board; "HẾT" when full.
  - `PbmsSlotTag`: slot code painted like floor signage (white on ink).
  - `PbmsPaidStamp`: "Đã thanh toán" stamp outline.
  - `ExitQrScreen` (via `PbmsQrDialog.show`): full-screen white, QR >= 300px, max brightness and
    wake-lock, single "Xong" button at the bottom, swipe down to close.
- **Surfaces:** cards are border-only (`PbmsCard`, radius 16; list rows 14); only the ticket stub
  carries a shadow. Glass only on the bottom bar; gradients only for the lot photo fade.
- **Lists/settings:** `PbmsSettingsGroup` + `PbmsSettingsRow`: flat grouped rows, plain icon, no
  subtitles, at most 4 rows per group.
- **States:** every async block goes through `PbmsAsync` (skeleton, error with retry, short empty state).
- **Copy:** short and factual, no teaching paragraphs. No em/en dashes, no uppercase eyebrows,
  no fake data (illustrations are labelled "Ví dụ"). Labels above inputs.
- **Motion:** carousels never auto-advance. The bottom bar keeps the original frosted bar with the
  raised, bouncing wallet button (owner's choice).
- **Home:** promo carousel first, then the active ticket / quick actions, then lots. Lot rows have
  no border or own background: the location photo on the left fades into the page background
  (`#F8FAFC`), text is right-aligned on the clean side.
- **Notifications:** flat full-width rows, no borders/radius; unread rows get a full-row teal tint.
- **Touch targets:** 48dp minimum; primary gate actions sit in the lower half of the screen.
