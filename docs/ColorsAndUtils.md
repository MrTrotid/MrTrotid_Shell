# Colors.qml & ColorUtils.qml - Color System

## Colors.qml

### Purpose
Centralized color palette for the entire shell. All widgets reference these colors for consistent theming.

### Color Palette (Monochrome Teal)

| Property | Color | Hex | Usage |
|----------|-------|-----|-------|
| `base` | Dark green-black | `#1a2120` | Main background |
| `mantle` | Dark green-black | `#1a2120` | Same as base |
| `crust` | Dark gray-green | `#303635` | Borders, secondary surfaces |
| `surface0` | Dark gray-green | `#303635` | Same as crust |
| `surface1` | Dark gray-green | `#303635` | Same as crust |
| `surface2` | Dark gray-green | `#303635` | Same as crust |
| `text` | Light gray | `#dde4e2` | Primary text |
| `subtext0` | Light blue-gray | `#aec9e6` | Secondary text, volume icon |
| `overlay0` | Muted green | `#578466` | Tertiary elements |
| `overlay1` | Muted green | `#578466` | Same as overlay0 |
| `blue` | Light blue | `#96ccf8` | (Reserved) |
| `mauve` | Teal | `#81d5ca` | Primary accent |
| `pink` | Light red | `#ffb4ab` | Error/danger |
| `green` | Light green | `#92d5ab` | Success/connected |
| `red` | Light red | `#ffb4ab` | Same as pink |
| `peach` | Yellow-green | `#bccf81` | Battery medium |
| `sapphire` | Light blue-gray | `#aec9e6` | Same as subtext0 |
| `teal` | Teal | `#81d5ca` | Same as mauve |
| `accent` | Teal | `#81d5ca` | Main accent color |
| `accentText` | Dark green-black | `#1a2120` | Text on accent background |

### Design Notes
- This is a **monochrome teal** palette — most colors are variations of green/teal
- `base`/`mantle` are identical (dark background)
- `crust`/`surface0-2` are identical (secondary surfaces)
- `mauve`/`teal`/`accent` are identical (primary accent)
- `pink`/`red` are identical (error states)
- `subtext0`/`sapphire` are identical (secondary text)

### Usage
```qml
import "widgets"

Rectangle {
    color: Colors.base
    border.color: Colors.crust
}

Text {
    color: Colors.text
    font.family: "JetBrainsMono Nerd Font"
}
```

---

## ColorUtils.qml

### Purpose
Utility functions for color manipulation. Used by ServiceContext and available to all widgets.

### Functions

#### `colorWithHueOf(color1, color2)`
Returns `color1` with the hue of `color2`.
```javascript
colorWithHueOf("#81d5ca", "#ffb4ab")  // teal with red hue → reddish teal
```

#### `colorWithSaturationOf(color1, color2)`
Returns `color1` with the saturation of `color2`.
```javascript
colorWithSaturationOf("#81d5ca", "#dde4e2")  // teal with gray saturation → desaturated teal
```

#### `colorWithLightness(color, lightness)`
Returns `color` with specified lightness (0-1).
```javascript
colorWithLightness("#81d5ca", 0.3)  // darker teal
```

#### `colorWithLightnessOf(color1, color2)`
Returns `color1` with the lightness of `color2`.
```javascript
colorWithLightnessOf("#81d5ca", "#dde4e2")  // teal with gray lightness
```

#### `adaptToAccent(color1, color2)`
Returns `color1` with the hue and saturation of `color2`, keeping original lightness.
```javascript
adaptToAccent("#1a2120", "#81d5ca")  // dark background tinted to teal
```

#### `mix(color1, color2, percentage)`
Linear interpolation between two colors. `percentage` (0-1) determines the blend. Default: 0.5.
```javascript
mix("#81d5ca", "#ffb4ab", 0.3)  // 30% teal + 70% red
```

#### `transparentize(color, percentage)`
Reduces alpha by percentage. `percentage` (0-1) where 1 = fully transparent.
```javascript
transparentize("#81d5ca", 0.5)  // 50% transparent teal
```

#### `applyAlpha(color, alpha)`
Sets exact alpha value (0-1).
```javascript
applyAlpha("#81d5ca", 0.3)  // teal at 30% opacity
```

#### `isDark(color)`
Returns `true` if color lightness < 0.5.
```javascript
isDark("#1a2120")  // true
isDark("#dde4e2")  // false
```

#### `clamp01(x)`
Clamps value between 0 and 1.

#### `solveOverlayColor(baseColor, targetColor, overlayOpacity)`
Solves for the overlay color needed to achieve `targetColor` when placed over `baseColor` at `overlayOpacity`. Used for dynamic theming.

### Usage
```qml
ServiceContext {
    property var colorUtils: ColorUtils {}
}

// In other files:
serviceContext.colorUtils.mix(color1, color2, 0.5)
```

---

## Changing the Theme

To change the entire shell theme:

1. **Edit Colors.qml**: Update all color properties
2. **Edit widget color schemes**: Each widget has its own color properties at the top
3. **Update Matugen templates**: If using matugen, update `~/.config/matugen/templates/`
4. **Regenerate**: Run `wallset-backend` to apply new wallpaper-based colors

### Widget Color Properties
Each widget defines its own color properties (not importing Colors.qml directly):
```qml
readonly property color _base:    "#1a2120"
readonly property color _crust:   "#303635"
readonly property color _accent:  "#81d5ca"
// ... etc
```
This is intentional — each widget can have its own color overrides without affecting others.
