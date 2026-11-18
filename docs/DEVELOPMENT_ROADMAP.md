# Zayron Simulator — Development Roadmap

## Product decisions

- Platform: Android first
- Genre: 3D bus and truck simulator
- Visual target: realistic presentation with scalable quality settings for mobile hardware
- First region: Oman
- Expansion: GCC, then worldwide
- Budget: free and open-source tools first

## Milestones

### 0 — Foundation
- [x] Create GitHub repository
- [x] Define project identity and initial technical direction
- [x] Install Godot 4 on the Android development phone (user-confirmed)
- [x] Create and commit the starter Godot project
- [ ] Add a repeatable Android export setup

### 1 — First drivable prototype
- [x] Create a simple test scene and Oman-inspired desert road
- [x] Add a placeholder truck
- [x] Add initial acceleration, braking, steering and reverse logic
- [x] Add a follow camera
- [x] Add keyboard fallback controls
- [x] Add Android touch-control UI in source
- [ ] Verify touch controls, vehicle switching, mission trigger and handling in a fresh Android run

### 2 — Vehicle simulation
- [x] Separate service brake and reverse inputs in the current truck controller
- [x] Add basic speed and gear-state display
- [x] Add simple wheel and cab details to the placeholder truck
- [ ] Tune mass, traction, suspension, braking and steering
- [ ] Add transmission behaviour and engine audio
- [ ] Test at multiple frame rates and device performance levels

### 3 — Oman vertical slice
- [x] Create an initial original desert-road environment
- [ ] Add detailed road markings, signs, terrain, buildings and landmarks
- [x] Add a first delivery checkpoint objective and HUD\n- [ ] Add a full delivery / passenger mission loop with rewards and route selection
- [ ] Add traffic and road rules
- [ ] Verify all third-party asset licenses

### 4 — First Android test release
- [ ] Add graphics, audio, sensitivity and control-layout settings
- [ ] Configure a repeatable Android APK export
- [ ] Profile memory, frame time, loading and battery use
- [ ] Test on real Android devices
- [ ] Fix crashes and blocking gameplay issues

### 5 — Content expansion
- [x] Add a first bus prototype scene and model built from procedural meshes\n- [ ] Add more detailed production-quality bus and truck models
- [ ] Add depots, routes, cargo, passengers and progression
- [ ] Expand the Oman map in manageable regions
- [ ] Add GCC regions only after the Oman foundation is stable

## Definition of done

A milestone is complete only when the project opens from a clean checkout and its acceptance checks pass. A successful GitHub commit alone does not mean the game is playable or fully tested. Features marked as implemented in source remain unverified until run in Godot.

## Cost and licensing rules

- Prefer free/open-source software and original assets.
- Check commercial-use terms before adding free assets.
- Record asset source, license and required attribution.
- Do not copy proprietary game assets, maps, code or branding.
