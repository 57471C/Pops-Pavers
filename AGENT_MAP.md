# Pop's Pavers – Agent Map

Last updated: 20 August 2026

## Project Overview
- **Name**: Pop's Pavers
- **Type**: Native SwiftUI iOS/iPadOS tile-matching game (3-of-a-kind)
- **Inspiration**: 3 Tiles / Triple Match style + garden/plumbing theme
- **Target player**: Older player ("Pop") + family
- **Repo**: https://github.com/57471C/Pops-Pavers
- **Bundle ID**: studio.lean.pops-pavers (or current one in Xcode)
- **Distribution**: TestFlight (Internal)

## Core Game Loop
- Layered board of paver tiles with icons
- Only free (uncovered) tiles can be selected
- Selected tiles go into a 7-slot tray
- Match 3 of the same icon → they clear (+10 points)
- Tray full with no match → lose a life
- Board cleared → level complete
- 3 lives per run
- Persistent Life Bank (earn 1 per 10 levels completed)

## Key Systems

### Scoring & Progression
- +10 points per match of 3
- Level counter increases on each win
- Every 5 levels: unlock one additional icon (starts at 5 icons, up to 20)
- Every 10 levels:
  - Change background image (`game-background` → `game-background-1` … `4`)
  - Advance to next music track in a pre-shuffled playlist
  - Award +1 reshuffle
  - Award +1 life to the Life Bank (persistent)

### Reshuffles & Undos
- Start with **1 reshuffle** per run
- Earn +1 reshuffle every 10 levels
- Reshuffle now re-deals the **remaining board tiles** (not the tray)
- Undo: 2 per run (planned / in progress) – reverses last board→tray move

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

### Audio
- Title music + multiple gameplay tracks
- On PLAY: create a random order of gameplay tracks and cycle every 10 levels
- SFX: paver-good, paver-bad, paver-match, level-win, level-lose, button, etc.
- Mute toggles background music only

## UI / Screens
- **TitleView**: animated title, Pop / Nan / Lilly characters, High Score, Banked Lives, PLAY button, secret cottage tap → bonus level
- **GameView**: board, tray, lives, score, level, shuffle, mute, win/lose overlays with pop-4 / pop-5
- **BonusLevelView**: placeholder for future Flow Free–style plumbing mini-game

## Important Asset Names
- Pavers: `paver-1` … `paver-6` (lowercase)
- Icons: `icon-1` … `icon-20`
- Backgrounds: `game-background`, `game-background-1` … `4`
- Characters: `pop-1`, `pop-4`, `pop-5`, `nan-4`, `lilly-1`
- UI: `tray`, `mute`, `unmute`, `level-complete`, `level-failed`, `tap`

## Technical Notes
- SwiftUI + `@Observable` GameState
- AVFoundation via AudioManager.shared
- UserDefaults for highScore + lifeBank
- Responsive layout needed for both iPhone and iPad (GeometryReader / size checks)
- App Icon must be opaque 1024×1024 (JPG preferred to avoid alpha issues)

## Near-term Ideas / Backlog
- [ ] Finish Undo button (2 per run)
- [ ] Implement real Flow Free–style plumbing bonus levels (secret cottage tap already wired)
- [ ] More board shapes and awkward higher-level layouts
- [ ] Possible Android port later (Flutter recommended if needed)
- [ ] Polish iPhone spacing further if anything still feels tight

## Agent Instructions
When continuing work on this project:
1. Read this file first for context.
2. Prefer full-file replacements over tiny scattered patches when the user is frustrated with merge conflicts / syntax errors.
3. Always keep iPhone + iPad layouts working.
4. Paver image names are **lowercase** (`paver-1` etc.).
5. Preserve the existing scoring, lives, bank, and progression rules unless explicitly asked to change them.
