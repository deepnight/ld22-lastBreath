# Last Breath — Haxe 4 / Heaps port

Port of [deepnight/ld22-lastBreath](https://github.com/deepnight/ld22-lastBreath),
revision `1c69e37c25df0e92457d4bc0874ff9481fbe849b`.
The unfinished Heaps conversion has been completed using current deepnightLibs.

## Build and run

Extract into a **fresh folder** when updating an earlier archive. The old
`res/sfx/theme.mp3` must not remain beside `theme.ogg`. Run Setup again to
install the new JS decoder dependency.

Install Haxe **4.3.7** and Neko, then run from the project root:

```sh
haxe --run tools.Setup
haxe js.hxml
python3 -m http.server 8000
```

Open http://localhost:8000 and click the game to enable input/audio.
The archive includes compiled `bin/client.js` and `bin/client.hl`.
All runtime assets are embedded; no Flash player or external asset SWF is needed.
`index.html` and `js.html` both launch the browser build.

For native:

```sh
haxe hl.hxml
hl bin/client.hl
```

Use the **complete [HashLink 1.16.0 distribution](https://github.com/HaxeFoundation/hashlink/releases/tag/1.16)**.
Keep `hl.exe`, `libhl.dll`, all `.hdll` files and their dependent DLLs together.
On Windows, `run-hl.bat "D:\path\to\hashlink-1.16.0-win\hl.exe"`
checks the runtime version before launching. It also accepts `hl` from PATH.
Updating only `hl.exe` leaves old native libraries and can cause missing-function
errors such as `sdl@gl_multi_draw_elements_indirect_count`.
The browser build also uses `stb_ogg_sound` to decode the Ogg music through
Heaps, independently of native browser MP3 support.
The SDL externs are pinned to the same stable 1.16 release, rather than master.

`tools.Setup` installs a project-local `.haxelib/` with these verified revisions:

| Library | Revision |
| --- | --- |
| deepnightLibs | `7e5b5208d4bbbec4417a8d17fb7d009bf135d8c1` |
| Heaps | `d88d43e3b83d8fb1065ee09553b9e03891af8fac` |
| stb_ogg_sound (JS only) | `310c825feae17d502182ef7657186f7503bff5a4`, `src` |
| format | `775a06f0a7aa64cbd060b5c3ba62f65d7fed684a` |
| hlsdl | HashLink 1.16, `c3f2a1563cf7aa9f4076b0808a7eaf40e18e8f14`, `libs/sdl` |

## What changed

- `dn.Process` runs the original simulation, particles and animation at 30 Hz.
- `SpriteLib` / `HSprite` retain the original 100-frame dog atlas. Animation
  sequences preserve absolute frame numbers, timing and shadow replay pivots.
- The world renders to a **256 × 192** nearest-filtered texture before centered
  integer scaling (up to 4×; downscaling below 1× on very small windows) and the original pixel mosaic overlay. Tips and
  credits use a sharp overlay clipped and anchored to the game rectangle.
- The darkness uses an isolated Flash-style LAYER with alpha-only ERASE lights. Glows,
  directional inner shadows, cave backgrounds, opening sunlight, particles,
  dialogs and both masked cinematics are restored.
- The original pixel font is regenerated from `gfx/04B_03.TTF`; the atlas and
  effects remain unchanged; music uses Ogg and its MP3 original is retained in
  `legacy/audio/`. The level map is the original atlas crop.
- Scene callbacks now use the process delayer, pause with the game and cancel
  when skipping or restarting. Audio resources initialize after `initEmbed()`.
- Flash configurations and reference sources are retained in `legacy/`.

Controls: 1/2 choose difficulty, arrows move, Up jumps/grabs ledges,
Space/Enter advances dialogs, S or C skips the opening cinematic.

## Validation and limits

Both `haxe js.hxml` and `haxe hl.hxml` compile with Haxe 4.3.7.
Run the CPU regression checks with:

```sh
npm ci
npm test
```

Eighteen checks exercise the real compiled game classes: startup, difficulty,
cinematic skip and landing, all nine rooms / ten shards, shard persistence,
story-preserving reset, finite animation completion, ending mask, WebGL 1
shader generation, render-context lifecycle, shielded respawn, game-over reset, relative filter offsets, viewport clipping
actual Ogg PCM decoding, timer-driven startup, full intro completion and
alpha-only destination-out light compositing. Texture uploads, audio and
window access are replaced in these CPU tests; they do not validate GPU output.

`tests/native-symbols.json` records 282 native declarations checked against the
Windows HashLink 1.16 libraries, with no missing exported function names.
`tools/check_native.py` reproduces that check from a generated HLC
`hl/natives.h` and a runtime folder (requires GNU objdump). This verifies imports,
not native execution or ABI signatures.

Windows execution and a rendered screenshot comparison have **not** been
verified in this environment: there is no Windows runtime runner and the
available browser cannot acquire a WebGL context. Flash filters have been
translated into Heaps shaders, whose blur kernels can differ slightly. The
provided reference screenshots informed the render pipeline; pixel-exact
matching is not claimed.

Optional font regeneration requires Python and Pillow:
`python3 tools/make_font.py`.
The original project license is retained in `LICENSE`.

## Rendering/audio correction

InnerShadow now returns a tile with a relative zero offset. Previously it
returned the input tile's absolute offset, which Heaps applied again when
composing the filter group. This displaced platform/light silhouettes.
The UI now uses 1024 × 768 reference coordinates within a mask that moves
and scales with the 256 × 192 game, so text no longer uses window coordinates.
The WebAudio context is initialized before the first input so its unlock hooks
receive that click/key even though music starts later.
The music was transcoded with `ffmpeg -i legacy/audio/theme.mp3 -c:a libvorbis
-q:a 5 res/sfx/theme.ogg`; the JS decoder is explicitly installed by Setup.

## Intro timer and light-mask correction

The natural intro ending invokes `startGame()` inside `dn.Delayer.update()`.
Clearing that active delayer and adding the music timer reused its array slot;
when the old callback returned, update removed the new timer. `cancelAsync()`
now disposes the old delayer and installs a new one. The old update detects
disposal and exits without touching the new music timer. Full intro completion
and timer-triggered startup are both covered by regression tests.

`render.LightErase` replaces the inverse-mask path. Darkness is drawn first
inside an isolated layer, followed by the combined light sprites, matching
Flash's LAYER / ERASE order. Heaps ERASE uses source color, so the light filter
writes sampled alpha into all four channels before the erase operation.
This makes each destination channel multiply by `1 - light alpha`, independent
of atlas RGB, without a second mask-coordinate transform. Original light
frames, positions, scales and darkness opacity remain unchanged. Tests check
the generated GLSL and overlapping-light alpha math at both intro and gameplay
opacity. GPU screenshot comparison remains unavailable here.

## Transparent map markers and intro grass

The original Flash loader drew the map into opaque black BitmapData.
PNG pixels can retain white RGB under zero alpha; ignoring alpha created
61 extra `lightRay` sprites in the starting room. The loader now changes
transparent pixels to opaque black before decoding room markers. The map
itself is unchanged. Tests use real `hxd.Pixels` RGBA reads and verify ray
counts against opaque white pixels in all nine playable rooms.
The garden intro grass shadow now uses 0.3 opacity with strength 1, so the
old strength 10 no longer amplifies the requested translucent outline.

The cinematic image uses an unfiltered rectangular mask. A separate black
rectangle at 40% alpha behind it reproduces the original hard drop shadow
(distance 4, angle 70 degrees, no blur). The shadow is outside the image clip.
The previous filtered parent broke Mask clipping in the offscreen scene and
has been removed. Intro and ending use the same frame setup and cleanup.
Tests verify that the mask has no filtered ancestor and check shadow bounds.

The intro white-flash transition hides both the cinematic content and its
outer frame, so the separate shadow disappears with the image. Full intro
completion checks both visibility values before the music starts.
