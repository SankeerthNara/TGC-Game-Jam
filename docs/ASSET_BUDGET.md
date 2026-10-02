# Web Export Size Limits & Asset Budget

Technical asset budget for our Godot 4.7 web export (Compatibility renderer) hosted on itch.io for a 15-minute game loop.

---

## 1. Web Export Platform Constraints

| Constraint | Limit / Benchmark | Why It Matters |
|---|---|---|
| **itch.io Web Upload Limit** | 200 MB max zip | Hard ceiling set by itch.io. |
| **itch.io File Count Limit** | ~1,000 files soft limit | Must package everything into a single `.pck` file alongside `.wasm` and `.html`. |
| **Player Bounce Threshold** | > 40-50 MB uncompressed | Players abandon web jam games if the initial loading screen takes longer than 8-10 seconds. |
| **Engine Baseline Size** | ~25 MB uncompressed (~7 MB gzip) | Godot 4.7 Compatibility `.wasm` + `.js` runtime overhead. |
| **Target Total Build Size** | **< 35 MB uncompressed** | Engine (~25 MB) + Game `.pck` (< 10 MB). Fast loading on all connections. |
| **Network Transfer Size** | **< 15 MB compressed** | Estimated download size after itch.io server-side gzip/brotli compression. |

---

## 2. Asset Allocation Budget (Max 10 MB for Game `.pck`)

```
Total Game Asset Budget: 10.0 MB
├── Audio (Music & SFX):   5.0 MB (50%)
├── Textures & Sprites:    3.5 MB (35%)
├── Fonts (2 files max):   0.5 MB (5%)
└── Data, Levels & Code:   0.5 MB (5%)
    Buffer / Safety:       0.5 MB (5%)
```

### Detailed Asset Specifications

| Asset Category | Format | Max Resolution / Spec | File Count Target | Max Total Size |
|---|---|---|---|---|
| **Backgrounds & Panels** | Compressed WebP / PNG | Max 1024x1024 (lossy 85%) | 4-6 sheets | **2.0 MB** |
| **Sprites & Animations** | Compressed PNG / WebP | 256x256 max per frame (spritesheets) | 3-4 sheets | **1.0 MB** |
| **UI Icons & Light Masks**| WebP / PNG / SVG | 512x512 max (radial light cones) | 1 atlas + masks | **0.5 MB** |
| **Music Tracks** | `.ogg` (Ogg Vorbis) | 44.1 kHz, 96-112 kbps, mono or joint stereo | 3 tracks (1.5-2 min loops) | **3.5 MB** |
| **Sound Effects (SFX)** | `.ogg` (>1s) / `.wav` (<1s) | Mono, 22.05 kHz or 44.1 kHz 16-bit | 15-20 short sounds (<50 KB each)| **1.5 MB** |
| **Fonts** | `.ttf` or `.woff2` | Latin-1 character set only | 2 font families (Title + Body) | **0.5 MB** |
| **Level Data & Scripts** | `.json` / `.tres` | Text-based, minified JSON for 5 levels | 5 level files + dialogue data | **0.5 MB** |

---

## 3. Web Performance & Rendering Rules
- **Viewport Resolution:** Set project canvas to **1280x720** (or **960x540** with 2D scale stretch mode `canvas_items`). This keeps texture memory small while keeping comic text crisp.
- **Audio Decoding:** Use uncompressed `.wav` for micro-SFX (UI clicks, footfalls) to avoid browser audio thread decode lag, and `.ogg` for music loops to minimize file size.
- **Texture Compression:** Import textures with VRAM compression disabled for 2D pixel/comic art (use `Lossless` or `Lossy WebP` in Godot import settings) to avoid compression artifacts on sharp black ink lines.
- **Browser Memory Budget:** Keep total WebGL memory consumption **under 256 MB RAM** to prevent mobile browsers and low-spec laptops from encountering `Out of Memory` errors.
