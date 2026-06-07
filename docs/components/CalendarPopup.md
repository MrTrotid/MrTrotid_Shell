# CalendarPopup - Clock, Calendar & Weather Display

## Purpose
Three-panel popup showing a live clock with 3D orbital hourly forecast, a monthly calendar, and weather statistics with 5-day forecast.

## Architecture
```
Item (root)
└── Item (scale/opacity wrapper)
    └── Rectangle (main container, radius: 20)
        ├── Rectangle (ambient blob 1)
        ├── Rectangle (ambient blob 2)
        ├── Item (centralHub) - Clock + orbital forecast
        │   ├── Canvas (orbitCanvas) - Elliptical orbit ring
        │   ├── ColumnLayout (clock)
        │   │   ├── RowLayout (HH:mm + :ss)
        │   │   └── Text (date)
        │   └── Repeater (hourRepeater) - 3D orbital hourly cards
        ├── Rectangle (calendarRect) - Monthly calendar
        │   └── ColumnLayout
        │       ├── RowLayout (month nav)
        │       ├── RowLayout (day headers)
        │       └── GridLayout (calendar days)
        └── Item (weatherPanel) - Weather stats
            └── ColumnLayout
                ├── RowLayout (day nav)
                ├── ColumnLayout (temp + description)
                └── RowLayout (4 gauges: wind/humidity/rain/feels)
```

## Key Properties
| Property | Type | Default | Description |
|---|---|---|---|
| `currentTime` | Date | new Date() | Current time |
| `weatherData` | var | null | Parsed weather JSON |
| `weatherView` | int | 0 | Active forecast day (0-4) |
| `targetWeatherView` | int | 0 | Target for transitions |
| `monthOffset` | int | 0 | Calendar month offset from current |
| `targetMonthOffset` | int | 0 | Target month for transitions |
| `globalOrbitAngle` | real | 0 | Orbital animation angle (90s loop) |
| `secondPulse` | real | 1.0 | Clock second pulse effect |
| `activeWeatherHex` | color | computed | Weather-based accent color |

## Weather Data Structure
```javascript
{
    current_temp: "25.0",
    current_icon: "☀",
    current_hex: "#f9e2af",
    current_desc: "Sunny",
    forecast: [
        {
            day: "Mon", day_full: "Monday", date: "07 Jun",
            max: "28.0", min: "18.0", feels_like: "27.0",
            wind: "5", humidity: "65", pop: "10",
            icon: "☀", hex: "#f9e2af", desc: "Clear sky",
            hourly: [
                { time: "09:00", temp: "22.0", icon: "☀", hex: "#f9e2af" },
                ...
            ]
        },
        ... // 5 days total
    ]
}
```

## Weather Gauges
| Index | Icon | Label | Value Source | Fill Calculation |
|---|---|---|---|---|
| 0 | 󰁝 | WIND | `forecast.wind + "m/s"` | `wind / 25.0` |
| 1 | 󰖨 | HUMID | `forecast.humidity + "%"` | `humidity / 100.0` |
| 2 | 󰖝 | RAIN | `forecast.pop + "%"` | `pop / 100.0` |
| 3 | 󰖐 | FEELS | `forecast.feels_like + "°"` | `(feels_like + 15) / 55.0` |

## Calendar
- 7-column grid (Mo-Su)
- 5 rows (35 days)
- Previous/next month navigation with slide animation
- Today highlighted with accent color
- `setMonthOffset()` transitions with opacity+slide animation

## Clock
- Time format: `HH:mm:ss`
- Second pulse: `secondPulse` animates 1.0→1.06→1.0 every second
- Date format: `dddd, MMMM dd`
- Levitation animation: y oscillates ±15px over 8s
- 3D rotation: pitch ±3.5° (4.2s), yaw ±2.5° (5.1s), roll ±1.5° (5.8s)

## 3D Orbital Hourly Forecast
- 8 hourly cards orbit the clock on an elliptical path
- `rx: 320, ry: 140` (orbit radii)
- Today's hours: centered around active hour, 30° spacing
- Other days: evenly distributed around orbit
- Cards scale/opacity based on z-position (sin-based depth)

## Weather Transitions
`weatherTransitionAnim` sequence:
1. Fade out + offset + spin (250ms)
2. Swap `weatherView = targetWeatherView`
3. Fade in + offset reverse + spin reverse (450ms)

## Intro Animation
1. `introMain` (0→1, 800ms, OutQuart)
2. `introAmbient` (0→1, 1000ms, OutSine, +150ms)
3. `introClock` (0→1, 900ms, OutBack, +250ms)
4. `introCalendar` (0→1, 850ms, OutQuint, +350ms)
5. `introWeather` (0→1, 850ms, OutQuint, +400ms)

## Weather Polling
- `weatherPoller` Process runs `weather.sh --json`
- Timer polls every 150000ms (2.5 minutes) when visible
- `weather.sh` caches results for 900s (15 min)

## Modifying This File
- Change orbit parameters: Modify `rx`, `ry` in hourRepeater delegate
- Change calendar size: Modify `calendarRect` dimensions (280x360)
- Change weather poll: Modify Timer interval (150000ms)
- Add forecast days: Modify `forecast` array and repeater model
