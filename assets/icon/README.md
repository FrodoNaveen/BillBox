# App icon

`billbox_icon.svg` is the master artwork for the BillBox app icon: a bill
standing in an open box, on the deep-purple gradient the app's theme is seeded
from. It is design source, not a runtime asset, so it is deliberately not listed
under `flutter: assets:` in `pubspec.yaml`.

To change the icon, edit the SVG and regenerate every platform's icons:

```bash
./tool/icon/generate_icons.sh     # macOS only (uses swiftc + AppKit)
```

That rewrites:

| Platform | Files |
| --- | --- |
| Android | `mipmap-*/ic_launcher*.png` (legacy, round, adaptive foreground, themed monochrome) |
| iOS | `Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png` (flattened, no alpha) |
| macOS | `Runner/Assets.xcassets/AppIcon.appiconset/app_icon_*.png` |
| Web | `web/favicon.png`, `web/icons/Icon-*.png` (incl. maskable) |
| Windows | `windows/runner/resources/app_icon.ico` |

Two things are hand-maintained alongside it: the gradient in
`android/app/src/main/res/drawable/ic_launcher_background.xml` (the adaptive
icon's background layer) and the monochrome silhouette inside
`generate_icons.sh`, which repeats the artwork's paths so the bill's lines can be
punched out. Keep both in step with the master's colours and geometry.
