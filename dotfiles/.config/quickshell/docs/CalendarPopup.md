# CalendarPopup.qml — Calendar / Weather / Time Popup

## Purpose
Three-panel popup showing calendar (left), clock + 3D orbital hourly forecast (center), and daily weather stats (right). Toggled by clicking the time capsule in the bar. Adapted from ilyamiro's CalendarPopup.qml with bar's monochrome teal color scheme.

## Architecture
```
Item (root: popup)
├── Colors (monochrome teal, matching bar)
├── Time-of-day color property
├── State (currentTime, weatherData, weatherView, visible_, etc.)
├── Intro/exit animations (staggered fade-in per panel)
├── Weather transition animations (spin + fade + slide)
├── Calendar grid logic (5-week grid, month navigation)
├── Weather polling (Process → weather.sh --json, 150s interval)
├── UI container (Item, scale/opacity tied to introMain)
│   ├── Background Rectangle (rounded, clipped)
│   │   ├── Ambient blobs (2 floating circles, weather/time colored)
│   │   ├── CENTRAL HUB (Item, centered)
│   │   │   ├── Orbit ring canvas (dashed ellipse, breathing)
│   │   │   ├── Core clock (ColumnLayout: HH:MM + :ss + date)
│   │   │   └── 3D orbital hourly forecast (Repeater, 8 cards)
│   │   ├── LEFT WING: Calendar (Rectangle)
│   │   │   ├── Month header (prev/next arrows + month name)
│   │   │   ├── Weekday labels (Mo Tu We Th Fr Sa Su)
│   │   │   └── GridLayout (7×5, 35 cells, day numbers)
│   │   └── RIGHT WING: Weather stats (Item)
│   │       ├── Day navigation (prev/next arrows)
│   │       ├── Big temperature display
│   │       └── 4 circular gauges (Wind, Humid, Rain, Feels)
```

## File Locations
- `widgets/CalendarPopup.qml` — main QML component
- `calendar/weather.sh` — OpenWeatherMap API script (standalone, no caching.sh dependency)
- `calendar/.env` — API key + city config

## Weather Data Flow
1. `weather.sh --json` called by `Process` on show + every 150s
2. Script fetches OpenWeatherMap 5-day forecast API
3. Parses into JSON: `{ current_temp, current_icon, current_hex, current_desc, forecast[0..4] }`
4. Each forecast day: `{ day, day_full, date, max, min, feels_like, wind, humidity, pop, icon, hex, desc, hourly[] }`
5. Hourly entries: `{ time, temp, icon, hex }`

## Weather Icons (Nerd Font)
Icons use `printf '\uXXXX'` / `printf '\UXXXXXXXX'` in shell script (NOT literal characters):
| Code | Icon | Weather |
|------|------|---------|
| `\uf185` | Sun | Sunny |
| `\uf186` | Moon | Clear night |
| `\uf0c2` | Cloud | Cloudy |
| `\U000F0597` | Rain drops | Rainy |
| `\uf0e7` | Lightning | Storm |
| `\uf1dc` | Snowflake | Snow |
| `\U000F0591` | Fog | Mist |

**Important**: `LC_ALL=C` breaks `printf` for codepoints above U+FFFF — only set it locally around `date` commands.

## 3D Orbital Hourly Forecast
- Ellipse: `rx=320`, `ry=140`, centered on `centralHub`
- Up to 8 hourly cards orbit with:
  - `pitchBreath` (±3.5°), `yawBreath` (±2.5°), `rollBreath` (±1.5°) — slow sinusoidal wobble
  - `levitation` (0 to -15px) — vertical bobbing
  - `orbitBreath` (1.0 to 1.035) — orbit ring scale pulse
- Active hour highlighted with `_accent` color, scaled 1.4×
- Cards: 56×95px rounded rectangles with time + icon + temp
- Today's view: cards at fixed angles relative to current hour
- Other days: cards orbit continuously via `globalOrbitAngle`

## Calendar Grid
- 5-week grid (35 cells), `GridLayout` with 7 columns
- Month navigation with slide transition (prev/next arrows)
- Today highlighted with `_accent` background
- `updateCalendarGrid()` populates `ListModel` with day numbers
- `LC_ALL=C` required for `date` commands (month name parsing)

## Weather Stats (Right Wing)
- Day navigation: prev/next arrows cycle through 5 forecast days
- Big temperature display (animated on day change)
- 4 circular gauges:
  - Wind (m/s)
  - Humidity (%)
  - Rain probability (%)
  - Feels Like (°C)
- Gauges use `Canvas` with arc drawing

## Toggle Mechanism
- `ctx.calendarPopupOpen` property in `ServiceContext.qml`
- `toggleCalendarPopup()` function in `ServiceContext.qml`
- Time capsule in `BarContent.qml` has hover effect + click handler
- `shell.qml`: `calPopup` Item wraps `CalendarPopup`, sized `parent.width * 0.70 + 20`

## Key Decisions
- CalendarPopup is a **floating Item** inside main PanelWindow (NOT a separate Window)
- Wings (calendar + weather) anchored `verticalCenter` for proper centering
- Weather script uses standalone cache at `~/.cache/quickshell/weather/` (no ilyamiro caching.sh)
- `Qt.resolvedUrl("../calendar/")` — relative path from widgets/ to calendar/
- `bc` not available — use `jq` for math (`jq '[.[].pop] | max * 100 | floor'`)
