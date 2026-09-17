# Gallipot — Build Specification

> Portfolio app 76, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Scan a grocery tin, set its best-before, and use the older pack first.

| Field | Value |
| --- | --- |
| Product name | Gallipot |
| Bundle identifier | `com.gallipot.bay` |
| Domain | https://gallipot-bay.pro |
| Contact URL | https://gallipot-bay.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Light |
| Asset prefix | `glp_` |
| User-Agent | `Gallipot/1.0 (iOS; +https://gallipot-bay.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
   Guideline 4.2 (Minimum Functionality): this is a native SwiftUI product, not
   a web browsing experience. WKWebView / SFSafariViewController as UI is a
   reject. Push notifications, Core Location, and sharing do not make a
   browser or a thin catalog into an App Store app.
5. **Guideline 5.1.1 (Privacy):** never direct the user to grant camera access.
   A pre-permission screen may exist; the proceed button is **Continue** or
   **Next**, never "Allow camera", "Enable camera", "Grant camera", or a bare
   Allow/Enable that triggers `requestAccess`. The system alert is the only Allow.
6. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
7. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
8. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Gallipot -destination 'generic/platform=iOS' build`.
9. **Nothing may echo another app in this batch** in naming, layout or visuals.
10. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

A housekeeper scans a tin onto the use-soon rail and pulls the facing pack so the older best-before is used first.

### 2.1 User flow

1. Pull the facing tin on the use-soon rail
2. Scan or search a product and set its best-before so a Lot lands behind that Bay's Face
3. Open Pantry to see stacked Lots behind each Face
4. Cull Spent lots whose best-before daykey is already past
5. Open Settings for the Open Food Facts credit, CSV export, and reset

### 2.2 Essential behaviour

- Use-soon rail of Faces ordered by days-left
- Scan or search Open Food Facts for identity, then set best-before in place
- FIFO Face: only the soonest live Lot of a Bay can be pulled
- Same barcode and same daykey stack qty on one Lot
- Local midnight folds past-date Lots to Spent; Cull clears them
- Undo peels the last PullMark or the last Lot
- Deep links and App Intents open UseSoon, Scan, a Bay, or Settings
- No kcal, no macros, no meal slots
- Empty or failed search falls back to a local shelf
- Simulator sample chips and a manual barcode field

---

## 3. Uniqueness assignment for Gallipot

| Axis | Assigned value |
| --- | --- |
| Architecture | **Lot-face encoding (a scan writes a Lot; the soonest live Lot of each Bay is the Face; Pull peels the Face and writes a PullMark; a later Lot never faces while an earlier Lot remains; past-date Lots fold to Spent)** |
| UI approach | **SwiftUI pure · take pantryexpiry** |
| Naming convention | **Stillroom / facing lexicon** |
| File organization | **By stillroom role (Bay, Lot, Face, PullMark, Spent)** |
| Dependency strategy | **None** |
| Design direction | **Aqua data clarity** |
| Typography | **SF Pro** |
| Navigation pattern | **Stillroom-tab chrome (UseSoon holds the facing rail; scan and best-before fuse on the rail; Pantry and Settings are sibling tabs)** |
| AI art style | **3D glass render glassmorphism · take pantryexpiry** |
| Functional twist | **Face-then-pull (Pull peels the soonest Lot of that Bay; a later pack never faces while an earlier one remains; qty stacks on the same daykey; midnight folds past-date Lots to Spent)** |
| Persistence | **UserDefaults+Codable** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — pantry_expiry

**Core** — A housekeeper scans a tin onto the use-soon rail and pulls the facing pack so the older best-before is used first.

**Audience** — Households that waste food because a newer pack sits in front of an older one.

**User flow**

1. Pull the facing tin on the use-soon rail
2. Scan or search a product and set its best-before so a Lot lands behind that Bay's Face
3. Open Pantry to see stacked Lots behind each Face
4. Cull Spent lots whose best-before daykey is already past
5. Open Settings for the Open Food Facts credit, CSV export, and reset

**Essential features**

- Use-soon rail of Faces ordered by days-left
- Scan or search Open Food Facts for identity, then set best-before in place
- FIFO Face: only the soonest live Lot of a Bay can be pulled
- Same barcode and same daykey stack qty on one Lot
- Local midnight folds past-date Lots to Spent; Cull clears them
- Undo peels the last PullMark or the last Lot
- Deep links and App Intents open UseSoon, Scan, a Bay, or Settings
- No kcal, no macros, no meal slots
- Empty or failed search falls back to a local shelf
- Simulator sample chips and a manual barcode field

**Twist** — Face-then-pull. Home is the use-soon rail. Scanning a product writes a Lot at the inline best-before. The soonest live Lot of that Bay is the Face — later dates stack behind it and do not get their own row. Pull writes a PullMark, decrements qty, and peels the Face when qty hits 0 so the next Lot steps forward. A later Lot never faces while an earlier one remains. Pull on an empty Bay is refused. At the next local midnight a Lot whose best-before daykey is past folds to Spent and ranks on Pantry until Cull. Undo peels the last PullMark or the last Lot. Home verb: pull-the-face, not log-a-calorie. Pantry lists Bays. Settings exports CSV. No macros and no meal slots.

**Why this is not a repeat** — Pantry_expiry is unused in the ledger. MacroDock is a calorie tracker whose pantry twist decrements grams when a meal is logged; this app has no slots, no macros, and no gram stock. Stallage scans belongings into stalls and hops a Tag between locations; this app never hops, never assigns a person, and ranks by best-before Face instead of by stall. OakLarder has an empty recovered idea and must not be reskinned as another pantry list. Home is the facing rail: one Face per Bay, Pull peels it, midnight spends past dates. That is a persisted verb on device, not a catalog browser.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: Use-soon rail is home. Not Today macros.
- Invariant: Best-before → days left. Use-soon ordered by date. Mark used. No kcal, no slots.
- Never: OFF is allowed for identity, not for macros.
- Desk `pack_balance`: fill=Σvol/cap; balanceXY=weight-avg of zones; readiness mixes clip(weight), clip(fill), balance.
- Taste DNA is section 7.6. Do not invent a second look.
- Scan: AVFoundation + Vision; symbologies include `.qr`; digit runs 8–14 from QR/URL; UPC-A pad; Simulator chips + manual; stop session. Pre-permission CTA is Continue or Next (Guideline 5.1.1 — never Allow/Enable camera).
- OFF: `GET /api/v2/product/<code>.json`; decoder without `convertFromSnakeCase`; tappable Open Food Facts link (1.4.1).
- Mini-ref `FoodFlow (identity only)`: steal OFF product-by-barcode and search for identity. Home is the use-soon rail. Never Do not copy Today macros or meal slots. No wrapper. New types and layout — do not reskin.

### 3.1 Architecture contract

A scan or search writes a Lot onto a Bay keyed by product identity, and the same barcode plus the same best-before daykey stack qty on one Lot. The Face of each Bay is the soonest live Lot by daykey, so later Lots stack behind it and never own a UseSoon row while an earlier Lot remains. Pull writes a PullMark, decrements Face qty, and peels the Face when qty hits 0 so the next Lot steps forward; Pull on an empty Bay is refused. At the next local midnight a Lot whose best-before daykey is past folds to Spent and ranks on Pantry until Cull. Undo peels the last PullMark or the last Lot through StillroomStore, which is the only mutation seam. Views never touch UserDefaults.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

100% SwiftUI. The only UIViewRepresentable is the AVCaptureVideoPreviewLayer for capture. Home is the UseSoon facing rail: one hero Face with a display-size days-left metric, then variance in thinner Face rows, never four equal stat cards. Scan and best-before fuse on that rail as a routed sheet; they are not a food-tracker tab. Pantry is stacked Lots behind each Face plus Spent until Cull. Settings is a Form. Native Button, Toggle, TextField; Pull uses a bordered-prominent ButtonStyle. Hairline plus fill only. take pantryexpiry means steal OFF identity lookup and use-soon density, not FoodFlow types, Today macros, meal slots, or layout. Axis values never appear as section titles. Empty UseSoon and empty Pantry are full-page cutouts with one headline, one line, and a bottom full-width CTA.

### 3.3 Naming contract

Convention: Stillroom / facing lexicon.

Examples to follow: `Bay`, `Lot`, `Face`, `pullFace(_:)`

### 3.4 Dependency contract

Zero SPM packages. `project.yml` has no `packages:` key. Foundation, SwiftUI, AVFoundation. URLSession talks only to `https://world.openfoodfacts.org` for `GET /cgi/search.pl` and `GET /api/v2/product/<barcode>.json` with User-Agent `Gallipot/1.0 (iOS; +https://gallipot-bay.pro)`. Dedicated JSONDecoder with `.useDefaultKeys`. Identity fields only on screen (name, brand, code, image). Local bundled shelf catches empty or failed search. CSV export is a local FileManager write. No CocoaPods, no Alamofire, no WebView.

### 3.5 Navigation contract

`TabView` with three sibling tabs, each owning a `NavigationStack`: UseSoon (facing rail, home), Pantry (Bays and stacked Lots), Settings (OFF credit, CSV, reset, contact). Scan and inline best-before fuse as a routed sheet on UseSoon, not a fourth tab. Deep links and App Intents open UseSoon, the Scan sheet, a Bay, or Settings. Read `-ReviewScreen` once after onboarding: today opens UseSoon, log opens Pantry, goals opens Settings. Tab bar sits on the home indicator. Lists use `contentMargins(.bottom)`.

### 3.6 Screen composition contract

Deep link routed screens. Physical screens: UseSoon, Pantry, Settings. Bay is a pushed detail from Pantry and from a deep link. Capture is a routed sheet from UseSoon (App Intent and deep link), not a sibling tab. Onboarding is a full-page stack with Continue at the bottom full width. Camera notDetermined may show a pre-screen whose proceed button is Continue; denied shows copy plus Open Settings. ReviewScreen is read once after onboarding: today=UseSoon, log=Pantry, goals=Settings. No Today, Search, or Goals screens.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

---

## 4. Target file organization

Scheme: **By stillroom role (Bay, Lot, Face, PullMark, Spent)**

```
Gallipot/
  Bay/
Lot/
Face/
PullMark/
Spent/
Stillroom/
Catalog/
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Pantry
A first-class screen for **Pantry**. Must render empty, populated and error states.

### 5.3 UseSoon
A first-class screen for **UseSoon**. Must render empty, populated and error states.

### 5.4 Scan
Live camera capture via AVFoundation + Vision `VNDetectBarcodesRequest`. Symbologies include `.qr` plus EAN/UPC. Extract 8–14 digit runs from QR/URL. 12-digit UPC-A → prefix `0`. Try every candidate before miss. Permission: Continue/Next only before the system alert (5.1.1 — never Allow/Enable camera). Denied routes to Settings. Simulator: chips + manual field. Cooldown 1.5–2 s; ignore the same payload while loading. `stopRunning` on disappear and background.

### 5.5 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.6 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.
Tappable Open Food Facts link (https://world.openfoodfacts.org). A static OpenFoodFacts label fails 1.4.1.

### 5.7 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.


**Scan (camera families). Mechanics from the white book scanner — add `.qr`.**

Capture:
- AVFoundation session + Vision `VNDetectBarcodesRequest` (or `AVCaptureMetadataOutput` with the same set).
- Symbologies must include `.qr` plus `.ean13`, `.ean8`, `.upce` (Code 128/39/93 if the domain uses them). Linear-only misses QR packs and QR-encoded EANs.
- Permission: notDetermined → `requestAccess` (system alert is the first ask). A pre-screen is allowed only if the proceed button is **Continue** or **Next**.
- Guideline 5.1.1 reject: any CTA that directs the grant — `Allow camera`, `Enable camera`, `Grant camera`, `Allow camera access`, or a bare `Allow` / `Enable` / `Grant` on the button that calls `requestAccess`.
- Denied/restricted → copy + Open Settings (`UIApplication.openSettingsURLString`). Never a second Allow/Enable button.
- No capture device (Simulator): sample-code chips + mandatory manual field. Fully usable without a camera.
- Start the session on appear; `stopRunning` on disappear and on background.
- Cooldown 1.5–2.0 s after a decode. Skip frames (every 3rd is enough). Ignore the same payload while a lookup is in flight.
- Continuous autofocus / autoexposure when supported. `alwaysDiscardsLateVideoFrames`. Preview `resizeAspectFill`.

Payload (camera, typed, pasted URL):
- Keep digit runs of length 8–14. A QR/URL may be text — extract those runs; do not require the whole payload to be digits.
- 12-digit UPC-A → prefix `0`.
- Try every candidate before miss. EAN-8/13, UPC-A/E, QR carrying any of those.

**Open Food Facts. Mechanics from white food_reference.**

- Host: `https://world.openfoodfacts.org`
- Search: `GET /cgi/search.pl` with `search_terms`, `json=1`, `page`, `page_size`, `fields`.
- Product: `GET /api/v2/product/<barcode>.json` — dedicated lookup, not a search filter.
- Dedicated `JSONDecoder` with `.useDefaultKeys`. Never `convertFromSnakeCase` — keys like `energy-kcal_100g` break.
- Nutriments: accept Double / Int / String; read `energy-kcal_100g` (and `energy_kcal_100g`); kcal = kcal100 ?? (kJ / 4.184).
- Search: debounce ~500 ms, cancel the previous `Task`, paginate. Empty query does not hit the network.
- `status == 0` → not found → manual entry, not a crash.
- Settings/About: tappable Open Food Facts link (`https://world.openfoodfacts.org`). A dead "OpenFoodFacts" label fails 1.4.1.

---

## 6. Domain model

Minimum entities, named per this app's convention:

- **PantryItem** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **Aqua data clarity**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#FBF6F4` | Screen background |
| `surface` | `#FEFEFD` | Cards, rows, sheets |
| `ink` | `#392218` | Primary text and icons |
| `accent` | `#C15425` | Primary action, key figure, progress fill |
| `muted` | `#8B695B` | Secondary text, dividers, disabled |

Define these as named colours in `Assets.xcassets` and reach them through one
typed accessor. Never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **SF Pro**

SF Pro via Font.system. The type move is metric-grid: one hero days-left numeral at display size, about 2.5x body, with tracked-caps or monospaced labels for DAYS LEFT, QTY, and FACE. Body stays about 17pt. Secondary figures stay small: stacked lot counts and dates formatted through NumberFormatter or DateFormatter, never a raw interpolated Int. At most six steps behind one accessor: display, title, headline, body, caption, micro. Weights and step carry hierarchy. No Font.custom, no fixedSize, never below 12pt. Dynamic Type; names truncate, numbers win. Day edges use Calendar.current.startOfDay then fold to Int YYYYMMDD.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- Corner radius and elevation are fixed by section 7.4, not chosen per screen.
- Every interactive element is at least 44x44 pt.

### 7.4 Component contract

Corner radius: **12pt** for cards, sheets and primary surfaces; **8pt** for chips, badges and small controls. Reach both through one accessor. Never a bare literal number, and never zero — a hard edge is not this app's design direction.

Elevation: **hairline+fill** — a 1pt hairline border plus a flat fill tint, reused everywhere a surface sits above another.

Primary control: **bordered prominent** — primary actions use `.buttonStyle(.borderedProminent)` or an equivalent filled, bordered shape.

This is arithmetic, not a suggestion: every card, sheet, chip and button in this app uses these two radii and this elevation style. Do not introduce a second radius or a second elevation style.

### 7.5 Custom rendering scope

This app's `ui` axis is **SwiftUI pure · take pantryexpiry**.

If that approach uses anything beyond stock SwiftUI/UIKit controls — `Canvas`, `CALayer`, Metal, SceneKit, SpriteKit, RealityKit, a hand-drawn `UIViewRepresentable`, or any other pixel-level custom rendering — confine it to exactly one hero surface on one screen (the mechanic's home view, or the one screen this axis exists to showcase). Every other screen — every list, every settings screen, every sheet, every secondary surface — is built from stock components: `List`, `Form`, `NavigationStack`, `TabView`, `Button`, `.sheet`, native `Text`/`Image`. A second custom-rendered surface elsewhere in the app is a defect, not a stylistic choice.

If **SwiftUI pure · take pantryexpiry** is already fully native (no custom drawing layer), this section is satisfied automatically — there is nothing to confine.

The `ui` axis value is an implementation choice. It must never appear as a user-visible section title or label.

This assignment restates a catalog technique another app already holds. Write a new composition: new types, new layout, new motion. Do not copy source, file trees, or type names from the holder.

### 7.6 Taste DNA

Aesthetic: **agency** (High-end agency: huge type, air, one accent, hairline depth.)

Reference system: **vercel** — steal rhythm and restraint, not their colours or logos.

Mood: **clear**.

Home rhythm (`metric-grid`, dense): Tight grid, one hero metric, mono labels. No four equal stat cards.

Black-and-ink precision on this palette. Hairline only. The hero number is 2.5x the body. Secondary figures stay small.

Type move: One hero metric at display size, labels mono or tracked caps.

Motion (`snap`): Press scale 0.97, 140-180ms ease-out. Sheets scale 0.96 to 1 plus fade. Reduce Motion: opacity only.

Voice (`dry`): Short verbs. No warmth padding. 'Saved.' not 'Your changes were saved successfully.'

Anti-slop from KNOWLEDGE.md applies. Taste never overrides contrast, 44pt hits, VoiceOver labels, or Reduce Motion.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


Every item here is a defect if it is missing. Section 7.4 fixed the numbers —
this is where they have to show up on screen.

**Hierarchy and density**

- Every screen has exactly one dominant element (a hero number, a canvas, a
  primary card) that the eye lands on first. A screen where every element has
  equal weight reads as a spreadsheet, not a product.
- Related content is grouped into a card or a section with the elevation
  style from 7.4, not left floating on the bare background.
- Unused flat background is not "minimal" — see the density rule in
  `KNOWLEDGE.md`. If a screen has room left after the mechanic and the
  content, add a secondary surface (a stat strip, a recent-activity card, a
  related-item row), not a `Spacer`.

**Components**

- Every card, sheet, chip, row and button in the app uses the corner radius
  and elevation from section 7.4. No screen introduces its own radius or its
  own shadow value "just for this one card".
- Buttons have a pressed state (`ButtonStyle` with a scale or opacity change
  on `isPressed`) and a disabled state that is visibly different, not just
  non-interactive.
- Chips and badges are pill or rounded-rect shaped per 7.4, never a bare
  `Text` with no background sitting where a control is expected.
- A functional control (add, filter, sort, close, more, share, delete) is an
  SF Symbol inside a properly hit-targeted `Button`. SF Symbols are fine and
  expected here — section 16 only bans them as the app's primary brand
  iconography (app icon, empty-state hero, onboarding art), which is what the
  generated assets in section 13 are for.

**Depth and material**

- At least one surface in the app (a sheet, a modal, a floating toolbar) uses
  the elevation style from 7.4 to visibly sit above the content behind it.
  A flat app with no depth anywhere reads as a wireframe.
- Icons and generated art sit on the surface colour from 7.1, never directly
  on a colour that makes their edges disappear.

**Motion as feedback, not decoration**

- The one dominant element in a screen (7.4's primary control, the mechanic's
  hero) responds visibly to touch: a scale, a colour shift, a haptic — pick
  at least one. A control that looks identical pressed and unpressed reads as
  broken, not calm.

**Taste DNA (section 7.6)**

- Home uses the assigned layout family and density. Three identical equal-weight
  cards, a leftover bento hole, or a second column structure copied down the
  page is a defect.
- Copy follows the assigned voice. No em-dash, no elevate/unlock/seamless, no
  emoji, no SECTION 01 labels.
- Motion follows the assigned personality and honours Reduce Motion with a fade.
  One signature motion per view. No glow stacked on glass stacked on spring.
- Tokens by intent: the live verb wears accent; delete does not wear primary.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **UserDefaults+Codable**

One Codable Stillroom document (schemaVersion from 1, Bays, Lots, PullMarks, Spent, daykeys as Int YYYYMMDD) encoded to JSON Data in UserDefaults under glp.stillroom.v1. Face, days-left, and live-vs-Spent are derived at display and never stored as a parallel truth. In-memory StillroomStore is the source of truth; UserDefaults is the projection. Debounce writes; flush when scenePhase becomes inactive or background; encode after every Lot, Pull, Cull, and Undo. Decoding failure falls back to an empty stillroom, never a crash. resetAllData() is reachable from Settings. Simulator seed only once behind glp.demo.v1 writes several Bays with mixed live Lots, at least one stacked later date, at least one Spent, leaves Pull enabled on a Face, marks onboarding complete, and never seeds an empty rail as the first frame. Never seed on a device. Views never touch UserDefaults. CSV export reads the same document.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Dedicated `JSONDecoder` with `.useDefaultKeys`. Never `convertFromSnakeCase` —
  Open Food Facts keys like `energy-kcal_100g` break snake_case conversion.
- Resolve a scanned code with `GET /api/v2/product/<barcode>.json`, not a search.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Gallipot/1.0 (iOS; +https://gallipot-bay.pro)` on every request. Never reuse another app's string.
Use the **cgi search pl** search endpoint for this app.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- Guideline 5.1.1 (Privacy): do not encourage or direct the user to grant camera
  access. A pre-permission screen may exist, but the proceed button must be
  **Continue** or **Next** — never "Allow camera", "Enable camera",
  "Grant camera", or a bare Allow/Enable that calls `requestAccess`. The
  system dialog is the only Allow. Denied/restricted offers Open Settings.
- The app must not present itself as a clinician or as medical advice.
- Guideline 4.2 (Design — Minimum Functionality): the binary must be a native
  product, not a web browsing experience. No WKWebView / SFSafariViewController
  / UIWebView as home, a tab, or the primary UX. A content catalog, article
  reader, or site wrapper that could be a website is a reject. Push
  notifications, Core Location, and sharing do not make that acceptable.
- Guideline 1.4.1 (Safety — Physical Harm): if the binary shows health or
  medical recommendations, body-based targets, dosages, "you should" guidance,
  or product health claims (food, drink, supplement, remedy), put citations
  in the app. Tappable links to the sources, easy to find: same screen as the
  claim, or a Sources row one tap from Settings. Name the source (Open Food
  Facts, USDA FoodData Central, WHO, NIH MedlinePlus, …) and link it. A
  "not medical advice" footer without sources is a reject. A personal log
  that never advises does not invent claims to cite.
- Nutrition catalog data is credited to the database this app actually uses
  (Open Food Facts unless the spec names another). Credit is a tappable link,
  not a dead "OpenFoodFacts" label.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.food-and-drink`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Light
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UIRequiresFullScreen: YES
INFOPLIST_KEY_NSCameraUsageDescription: Gallipot uses the camera to read a grocery barcode so a tin can be identified and given a best-before date.
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.food-and-drink
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Face-then-pull (Pull peels the soonest Lot of that Bay; a later pack never faces while an earlier one remains; qty stacks on the same daykey; midnight folds past-date Lots to Spent)

Home is the UseSoon rail of Faces ordered by days left. Scanning a product writes a Lot at the inline best-before, and the soonest live Lot of that Bay is the Face. Pull peels that Face, writes a PullMark, and decrements qty; a later pack never faces while an earlier one remains. Qty stacks on the same barcode and daykey; at the next local midnight a past-date Lot folds to Spent and ranks on Pantry until Cull. Undo peels the last PullMark or the last Lot. The home verb is pull the face, not log a calorie.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **3D glass render glassmorphism · take pantryexpiry**


This assignment restates a catalog technique another app already holds. Write a new composition: new types, new layout, new motion. Do not copy source, file trees, or type names from the holder.

Base prompt, reused and extended for every asset:

```
3D glass render, glassmorphism, frosted translucent gallipot jars and grocery tins on a shallow facing rail, soft studio light, refractive edges, hairline depth, quiet centre band, isolated subjects with real transparency for in-app cutouts, full-bleed field for icon splash and backdrop. Mood: stillroom precision, not a calorie ring or a catalog browser. Technique: studio glass, one hero tin in front, later packs stacked behind, no text in the frame.
```

All 13 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `glp_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `glp_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `glp_Splash` | 1290x2796 | fill | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `glp_Onboarding1` | 1024x1536 | **required cutout** | Onboarding page 1 illustration: what the app is for. |
| 4 | `glp_Onboarding2` | 1024x1536 | **required cutout** | Onboarding page 2 illustration: the main verb. |
| 5 | `glp_Onboarding3` | 1024x1536 | **required cutout** | Onboarding page 3 illustration: why they stay. |
| 6 | `glp_EmptyHome` | 1024x1024 | **required cutout** | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `glp_EmptyList` | 1024x1024 | **required cutout** | Empty state: a secondary list has no rows. |
| 8 | `glp_CardBackdrop` | 1200x800 | fill | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `glp_ControlFace` | 512x512 | **required cutout** | Custom control artwork used for the primary interactive element. |
| 10 | `glp_TwistHero` | 1024x1024 | **required cutout** | Hero art for the 'Face-then-pull (Pull peels the soonest Lot of that Bay; a later pack never faces while an earlier one remains; qty stacks on the same daykey; midnight folds past-date Lots to Spent)' feature screen. |
| 11 | `glp_SuccessMark` | 512x512 | **required cutout** | Shown briefly when the primary action succeeds. |
| 12 | `glp_HeaderDecor` | 1200x600 | **required cutout** | Decorative header accent on the main screen. |
| 13 | `glp_ProductPlaceholder` | 1024x1024 | **required cutout** | Cutout of a generic unbranded grocery tin with no readable label. Isolated, transparent corners. Fallback thumbnail when identity has no image. |

### Prompt per asset

**`glp_AppIcon`** — 1024x1024

```
Single frosted glass gallipot tin filling the canvas edge to edge, lid facing the viewer, studio glass render, no text, no rounded corners, no drop shadow outside the canvas, no alpha.
```

**`glp_Splash`** — 1290x2796

```
Vertical glass facing rail of gallipot tins receding in depth, quiet uncluttered middle third, frosted glassmorphism, studio light, full-bleed.
```

**`glp_Onboarding1`** — 1024x1536

```
Cutout of one glass tin on an empty facing rail. Isolated subject, transparent corners. The product in one glance: a stillroom waiting for the first pack.

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`glp_Onboarding2`** — 1024x1536

```
Cutout of a hand peeling the facing tin forward off the rail while a later pack stays stacked behind. Isolated, transparent corners. The main verb: pull the face.

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`glp_Onboarding3`** — 1024x1536

```
Cutout of stacked lots behind one facing tin, a spent jar set aside. Isolated, transparent corners. Why they stay: older dates get used first.

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`glp_EmptyHome`** — 1024x1024

```
Cutout of an empty glass facing rail with one vacant gallipot outline. Isolated subject, all four corners transparent. Calm, not sad.

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`glp_EmptyList`** — 1024x1024

```
Cutout of empty stillroom bays, shelves with no tins. Isolated, transparent corners.

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`glp_CardBackdrop`** — 1200x800

```
Abstract frosted glass shelves as a low-contrast full-bleed field behind a Face card, hairline depth, no readable labels.
```

**`glp_ControlFace`** — 512x512

```
Cutout of a single glass tin lid used as the Pull control. Isolated, transparent corners, one physical handle.

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`glp_TwistHero`** — 1024x1024

```
Cutout emblem of one facing tin in front and later packs stacked behind it, glass render. Isolated, transparent corners. Face-then-pull.

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`glp_SuccessMark`** — 512x512

```
Cutout of a peeled glass lid confirming a Pull. Isolated, transparent corners. No emoji, no check-plate.

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`glp_HeaderDecor`** — 1200x600

```
Wide frosted glass rail band, hairline only, quiet ornament for the UseSoon header, not a second kit.

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`glp_ProductPlaceholder`** — 1024x1024

```
Cutout of a generic unbranded grocery tin with no readable label. Isolated, transparent corners. Fallback thumbnail when identity has no image.

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```


### 13.3 Asset rules

- Cut-outs (everything except AppIcon, Splash, CardBackdrop): isolated subject,
  real PNG alpha, all four corners transparent. No square plate.
- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, and seamless tiles are drawn in SwiftUI via `Path` or `Shape`. GenerateImage is not used for those. Every other in-app graphic (except AppIcon, Splash, CardBackdrop) is a **cutout**: isolated subject, real PNG alpha, all four corners transparent. An opaque square plate inside a circle or pentagon is a fail.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. The same seed must mark onboarding complete and
fill the primary surface — otherwise `-ReviewScreen` never fires. Never seed
on a physical device. Guard with `#if targetEnvironment(simulator)` and
`glp.demo.v1`.

Seed the happy path: the home primary verb is enabled. The blocked / gated /
error state is a unit-test fixture, not Simulator home. Home chrome names the
job and the next tap in words a stranger knows. Axis values (`ui`, `naming`,
`architecture`) never become user-visible titles. A card that looks tappable
is a `Button`. A readout does not use button chrome.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as the app's brand iconography — the app icon, the
  empty-state hero, or onboarding art. Those come from section 13. SF Symbols
  are the right choice for every functional control (add, filter, sort,
  close, share, delete) — leaving those as bare text instead of a symbol is
  also a defect.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.


---

## 17. Tests

Add a unit test target `GallipotTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. Parse `ProcessInfo.processInfo.arguments` once after onboarding. 
   `-ReviewScreen today|log|goals` switches the running app's live navigation.
   Cover that parser with a unit test. Do not host a `View` in the test.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Gallipot -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.
- [ ] Seeded home names the job and next tap; primary verb enabled.
- [ ] App reads `-ReviewScreen today|log|goals` after onboarding.

**Uniqueness**
- [ ] Architecture matches **Lot-face encoding (a scan writes a Lot; the soonest live Lot of each Bay is the Face; Pull peels the Face and writes a PullMark; a later Lot never faces while an earlier Lot remains; past-date Lots fold to Spent)** with no leakage across layers.
- [ ] UI approach matches **SwiftUI pure · take pantryexpiry**.
- [ ] Custom rendering, if any, is confined to one hero surface (section 7.5).
- [ ] Navigation matches **Stillroom-tab chrome (UseSoon holds the facing rail; scan and best-before fuse on the rail; Pantry and Settings are sibling tabs)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **SF Pro** and nothing else.
- [ ] Palette matches section 7.1 exactly.
- [ ] Home rhythm and motion match section 7.6. No second look.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Gallipot
xcodegen generate
xcodebuild -scheme Gallipot -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcrun simctl list devices available
xcodebuild -scheme Gallipot -destination 'platform=iOS Simulator,id=<UDID>' test
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY or DEVELOPMENT_TEAM in project.yml — CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
