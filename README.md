# Gallipot

Scan a grocery tin, set its best before, and pull the older pack first.

Gallipot is for households that waste food because a newer pack sits in front of an older one. There are no meal slots, no macros, and no calorie log.

## Architecture

Lot-face encoding fits this product because the job is a facing rail, not a pantry spreadsheet.

- A scan or search writes a **Lot** onto a **Bay** keyed by tin identity.
- Same barcode and same best-before daykey stack quantity on one Lot.
- The **Face** of each Bay is the soonest live Lot. Later Lots stack behind it and never own a Use Soon row while an earlier Lot remains.
- **Pull** writes a **PullMark**, decrements Face quantity, and peels the Face at 0 so the next Lot steps forward.
- Pull on an empty Bay is refused.
- At the next local midnight, a Lot whose daykey is past folds to **Spent** until Cull.
- Undo peels the last PullMark or the last Lot.

`StillroomStore` is the only mutation seam. Views never touch UserDefaults. Face, days-left, and live-versus-Spent are derived at display.

Use Soon, Pantry, and Settings sit on a stillroom dock, not a three-item tab bar. Scan and best-before fuse as a sheet on Use Soon.

## Face then pull

This is why someone picks Gallipot. Home is Use Soon: one hero Face with a days-left metric, then thinner Face rows. Pull peels that Face. A later pack never faces while an earlier one remains. Qty stacks on the same barcode and daykey. Midnight folds past dates to Spent until Cull.

Pantry shows stacked Lots behind each Face. Settings exports CSV and credits Open Food Facts with a tappable link.

## Look

Aqua data clarity on SF Pro. Hairline plus fill. 12pt cards, 8pt chips. Tokens live in `StillroomPaint`, `StillroomType`, and `StillroomMeasure`. Home is a metric grid: one display-size days-left figure, tracked caps for DAYS LEFT, QTY, and FACE.

Art style (generated later): 3D glass render, glassmorphism, frosted gallipot jars on a facing rail.

Base prompt:

```
3D glass render, glassmorphism, frosted translucent gallipot jars and grocery tins on a shallow facing rail, soft studio light, refractive edges, hairline depth, quiet centre band, isolated subjects with real transparency for in-app cutouts, full-bleed field for icon splash and backdrop. Mood: stillroom precision, not a calorie ring or a catalog browser. Technique: studio glass, one hero tin in front, later packs stacked behind, no text in the frame.
```

## Why it is not a clone

Home is the facing rail, not Today macros. Identity lookup uses Open Food Facts. Nutrition is never shown. A later pack never faces while an earlier one remains.

## Build

```bash
cd Gallipot
xcodegen generate
xcodebuild -scheme Gallipot -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```
