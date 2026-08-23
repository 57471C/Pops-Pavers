# Pop's Pavers – Agent Map

Last updated: 23 August 2026

## Project Overview
- **Name**: Pop's Pavers
- **Type**: Native SwiftUI iOS/iPadOS tile-matching game (3-of-a-kind)
- **Inspiration**: 3 Tiles / Triple Match style + garden/plumbing theme
- **Target player**: Older player ("Pop") + family — keep copy and HUD readable
- **Repo**: https://github.com/57471C/Pops-Pavers
- **Bundle ID**: studio.lean.pops-pavers (or current one in Xcode)
- **Distribution**: TestFlight (Internal)

## Core Game Loop
- Layered board of paver tiles with icons
- Only free (uncovered) tiles can be selected
- Selected tiles go into a 7-slot tray (plus overflow slots from level 21)
- Match 3 of the same icon → they clear (+10 points), matching across both trays
- Both trays full with no match → lose a life
- Board cleared → level complete
- 3 lives per run
- Persistent Life Bank (earn 1 per 10 levels completed)

## Key Systems

### Scoring & Progression
- +10 points per match of 3
- +10 match popup: float `score-10` up from the **board cell of the 3rd paver** that completed the match. Size = `trayTileSize * 2.15`. Uses the existing match SFX — no extra sound.
- +5 tray-clear bonus: after the first paver is placed in a level, whenever a match empties the tray (`justClearedTray`) award **+5**, play `tray-cleared.mp3`, and float a smaller `score-5` (`trayTileSize * 1.15`) up from the first tray slot. Delay the +5 popup and SFX **0.24s** after the +10 so it feels extra. Do **not** award this on the level’s final match (board also empty). Do **not** award on undo or on a fresh empty tray at level start.
- Bonus plumbing does **not** award +10/+5. Clear `matchBurst` / `trayClearBurst` when leaving a finished board so those popups don’t replay on the next main level.
- Plumbing time bonus (`FlowDifficulty.score(elapsed:)`): under 10s → 50, then −5 per 5 seconds down to under 55s → 5; 55s+ → 0. Timer starts when the grid appears, is shown on the bonus HUD, points are added to the main score on complete (`addBonusPoints`), and “+N” is shown on the chest screen.
- Level counter increases on each win
- Every 5 levels: unlock one additional icon (starts at 5 icons, up to 20)
- Every 10 levels:
  - Change background image (`game-background` → `game-background-1` … `4`)
  - Advance to next music track in a pre-shuffled playlist
  - Award +1 reshuffle
  - Award +1 life to the Life Bank (persistent)

### Reshuffles & Undos
- Start with **1 reshuffle** per run
- Earn +1 reshuffle every 10 levels (`shufflesForCurrentLevel`)
- Reshuffle re-deals the **remaining board tiles** (not the tray)
- Undo is live: starts at **2 per level** (`undosForCurrentLevel`), reverses last board→tray move
- Each new main-game level **resets** undos to the current max — unused undos do **not** carry over
- Extra Undo after completing **5, 15, 25…** raises that max (level 6–15: 3, 16–25: 4, …)
- Do **not** increment `undosRemaining` in `applyBonusRewards` — that double-grants on top of the per-level reset
- Do **not** double-grant shuffle or banked life in `applyBonusRewards` — those already come from `startNewLevel()` / `recordLevelCompleted()`

### Lives & Bank
- 3 hearts per run
- Lose a life when tray fills
- At 0 lives → Game Over screen
- Life Bank is persistent (UserDefaults)
- At Game Over player can spend 1 banked life to continue

### Board Generation
- Early levels (1–10): simple rectangular layouts
- Higher levels: shaped layouts (H, Plus, Circle/Ring, Diamond, Hollow Frame, etc.)
- Multiple layers with covering logic (a higher tile can block multiple below)
- Icon counts always multiples of 3

### Plumbing Bonus (Flow-style hose puzzle)
Triggered after completing main levels **5, 10, 15, 20…** (`FlowDifficulty.triggered`).

| After main level | Difficulty | Grid |
| --- | --- | --- |
| 5 | Easy | 5×5 |
| 10, 15 | Medium | 6×6 |
| 20+ (every 5) | Hard | 7×7 |

- Shown as an **in-place overlay** in `GameView` (not `fullScreenCover` — that slid up over the board)
- Flow: `BonusTitleView` → `FlowGridView` (timer + time score) → `BonusChestRevealView` (shows “+N”)
- Map selection: keep Easy → Medium → Hard by main-game level. Each tier has a **shuffled bag** (`bonusFlowQueue-{easy|medium|hard}`): every layout in the tier is dealt once before any repeat, and a new shuffle does not start with the map just played. HUD shows e.g. `Easy 2/3`. Back from the grid to the bonus title keeps the same map for that visit; a new bonus session (new main level) always draws the next map in the bag.
- Lilly tap on the **title screen is disabled** (decorative only). Bonus is reached only via the main-game milestone
- 7 hose colours: red, blue, green, yellow, orange, cyan, purple
- Each colour uses 3 assets: straight (`hose-*-h`), inside corner, outside corner, plus matching `tap-*`
- Hose lighting: highlight on **top** for horizontals, **left** for verticals
- Vertical straight: up→down = 270° + mirrored; down→up = 270° not mirrored
- Hose stubs at taps (half-cell toward enter/leave)
- `hose.mp3` plays **once per newly filled cell**, not looping while dragging
- `bonus-start` plays **once** (do not loop); then `bonus-background-1` loops
- Mute must **not** break bonus music — it only sets volume to 0

#### Chest rewards
Tap-paced reveal. Do **not** auto-close the chest. Don’t rush.

Sequence: wait 3.2s → zoom chest → per reward: open / bling / wait tap / close → Continue.

Chest sprite sheet: **6 frames**, each **333×348**. Crop then scale, `interpolation(.none)`, `drawingGroup()`.

Displayed rewards after completing main level N:

- Next unlocked paver icon when the next level adds one (`icon-6` after 5, `icon-7` after 10, …)
- Levels 20 / 25 / 30 / 35: **Paver slot added** (blank `paver-1`) when overflow free slots increase for the next main level
- Levels 5 / 15 / 25…: Extra Undo (raises `undosForCurrentLevel` for the next main level; chest still **shows** it)
- Levels 10 / 20 / 30…: Extra Shuffle + Banked Life (already granted by main progression; chest still **shows** them)

Keep existing main-game win sounds. Bonus success uses `bonus-success`.

### Audio
- Title music + multiple gameplay tracks
- On PLAY: create a random order of gameplay tracks and cycle every 10 levels
- SFX: paver-good, paver-bad, paver-match, level-win, level-lose, button, play-button, win-applause, tray-cleared
- Bonus SFX: hose, flow-connect, bonus-success, chest-open, chest-close, reward-bling
- Mute toggles background music only (volume 0, players still run)
- `AudioManager.stopAll()` on `UIApplication.willResignActive` in `PopsPaversApp`

## UI / Screens
- **TitleView**: animated `title-text`, Pop / Nan / Lilly, High Score, Banked Lives, PLAY. Lilly is **not** tappable. Nan warp is behind `TitleView.nanWarpsToLevel21` (currently **false**); set `true` to jump to level 21. iPhone `titleTop` is **88** so the wordmark (including the leaf) sits under the Dynamic Island. Full-bleed `GeometryReader` + `ignoresSafeArea()` — do not add safe-area padding on the whole view or the background will show a white border / shift
- **GameView**: board, tray, lives, score, level, shuffle, undo, mute, win/lose/game-over overlays. Bonus replaces the main board in the same ZStack
- **Game HUD (iPhone)**: two-row chrome (Back/Mute, then Easy/Flows on bonus). Keep original full-bleed background. Do not “fix” Dynamic Island by wrapping the whole game in safe-area padding
- **Board**: iPad shifted left one tile (`-tileSize`). iPhone shifted left half a tile (`-tileSize * 0.5`) so it sits on the path.
- **Tray (iPad)**: overlay 7 equal slots on the tray graphic using `tray.png` pocket insets so tiles sit in the recesses. Shuffle / Undo sit beside the tray.
- **Tray (iPhone)**: same pocket overlay as iPad. Shuffle / Undo sit **below** the tray (not beside it — they would clip off-screen). Do not change tray width/tile sizing to make room.
- **Overflow tray** (level 21+): second full `tray.png` (same size as the main tray) sitting above it. Six extra slots; the 7th pocket stays locked so the art lines up. Locked slots are a darkened paver + lock icon. Free slots: 21–25 → 1, 26–30 → 2, 31–35 → 3, 36+ → 4. Tiles fill the main tray first, then overflow; match-3 and undo use both. Hidden before 21. Cleared in `startNewLevel()`.
- **Win / fail / game-over overlays**: Nan + Pop at the bottom. iPhone characters sit lower (`overlayCharacterBottom` **-44**) so they cover the tray. Per-pose iPhone insets:
  - Nan leading: win **16**, fail/game-over **40** (`overlayNanLeading` takes `isCompact` — `layout` is not in GameView scope)
  - Pop trailing: game-over **24**, otherwise **0**
  - iPad Nan leading / Pop trailing: **-8**
- Overlay art: win `nan-1` / `pop-4`; fail `nan-2` / `pop-2`; game over `nan-3` / `pop-5`
- **BonusTitleView** + **FlowGridView** + **BonusChestRevealView**: plumbing intro, hose board, chest reward sequence

## Important Asset Names
- Pavers: `paver-1` … `paver-6` (lowercase)
- Icons: `icon-1` … `icon-20`
- Backgrounds: `game-background`, `game-background-1` … `4`, `title-background`
- Title: `title-text`, `title-bonus`, `title-3stars`
- Characters: `pop-1` … `pop-5`, `nan-1` … `nan-4`, `lilly-1` … `lilly-4`
- UI: `tray`, `mute`, `unmute`, `level-complete`, `level-failed`, `game-over`, `chest`, `score-5`, `score-10`
- Bonus hoses / taps: `hose-{color}-h`, `hose-{color}-inside`, `hose-{color}-outside`, `tap-{color}` (seven colours)

## Technical Notes
- SwiftUI + `@Observable` GameState
- AVFoundation via AudioManager.shared
- UserDefaults for highScore + lifeBank
- Responsive layout needed for both iPhone and iPad (GeometryReader / size checks)
- `GeometryReader` + `.ignoresSafeArea()` makes `geo.safeAreaInsets` **0**. Compact layouts use hardcoded top/bottom insets instead of relying on that GeometryReader
- App Icon must be opaque 1024×1024 (JPG preferred to avoid alpha issues)
- Do not commit Xcode user state: `xcuserdata/`, `*.xcuserstate`, `.DS_Store` (see `.gitignore`)
- Key files: `GameView.swift`, `GameState.swift`, `TitleView.swift`, `FlowModels.swift`, `HosePiece.swift`, `FlowGridView.swift`, `PlumbingBonusView.swift`, `BonusTitleView.swift`, `BonusChestRevealView.swift`, `AudioManager.swift`

## Constraints (do not regress)
- Keep existing main-game win sounds
- Older-player readability
- Do not loop `bonus-start`
- Do not auto-close the chest
- Don’t rush the chest sequence
- Mute must not break bonus music
- Do not double-grant shuffle / life
- Do not restore Lilly as a title-screen bonus cheat unless asked

## Near-term Ideas / Backlog
- [ ] More board shapes and awkward higher-level layouts
- [ ] Possible Android port later (Flutter recommended if needed)
- [ ] Polish iPhone spacing further if anything still feels tight

## Agent Instructions
When continuing work on this project:
1. Read this file first for context.
2. Prefer full-file replacements over tiny scattered patches when the user is frustrated with merge conflicts / syntax errors.
3. Always keep iPhone + iPad layouts working.
4. Paver image names are **lowercase** (`paver-1` etc.).
5. Preserve the existing scoring, lives, bank, bonus rewards, and progression rules unless explicitly asked to change them.
6. When moving overlay characters, change only the requested screen / device (iPhone vs iPad, win vs fail vs game over).
