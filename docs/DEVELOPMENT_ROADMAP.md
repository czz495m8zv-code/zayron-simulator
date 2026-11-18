# Zayron Simulator — Development Roadmap

## Product decisions

- Platform: Android first
- Genre: 3D bus and truck simulator
- Visual target: high-detail / realistic presentation, with scalable quality settings for mobile hardware
- First region: Oman
- Expansion: GCC, then worldwide
- Budget: free and open-source tools first

## Milestones

### 0 — Foundation
- [x] Create GitHub repository
- [x] Define project identity and initial technical direction
- [ ] Install a current stable Godot 4.x release
- [ ] Create and commit the starter Godot project
- [ ] Add a repeatable Android export setup

### 1 — First drivable prototype
- [ ] Create a simple test scene and road
- [ ] Add one placeholder truck
- [ ] Implement acceleration, braking, steering, reverse, and a follow camera
- [ ] Add keyboard controls for desktop testing
- [ ] Add touch controls for Android

### 2 — Vehicle simulation
- [ ] Tune mass, traction, suspension, braking, and steering
- [ ] Add transmission / gears and engine audio
- [ ] Add basic damage only after the core handling is stable
- [ ] Test at multiple frame rates and device performance levels

### 3 — Oman vertical slice
- [ ] Build a small, original Oman-inspired test area
- [ ] Add road markings, signs, terrain, buildings, and landmarks
- [ ] Add a simple delivery / passenger mission loop
- [ ] Verify all third-party map data and asset licenses

### 4 — First Android test release
- [ ] Add settings for graphics, sensitivity, and control layout
- [ ] Profile memory, frame time, loading, and battery use
- [ ] Test on real Android devices
- [ ] Fix crashes and blocking gameplay issues

### 5 — Content expansion
- [ ] Add more buses and trucks
- [ ] Add depots, routes, cargo, passengers, and progression
- [ ] Expand the Oman map in manageable regions
- [ ] Add GCC regions only after the Oman foundation is stable

## Definition of done for each milestone

A milestone is complete only when its acceptance checks pass, the project opens from a clean checkout, and the relevant tests have been run. A successful GitHub commit alone does not mean the game is playable or fully tested.

## Cost and licensing rules

- Prefer free/open-source software and original assets.
- Do not assume every free asset is free for commercial use.
- Record asset source, license, and required attribution.
- Do not scrape or redistribute proprietary game assets or map data.
