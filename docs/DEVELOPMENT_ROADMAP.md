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
- [x] Add different baseline acceleration, braking, speed and steering profiles for buses and heavy trucks
- [ ] Tune mass, traction, suspension, braking and steering with real-device testing
- [x] Add a lightweight procedural engine sound layer
- [ ] Add recorded or licensed vehicle engine samples and transmission behaviour
- [x] Add an alternate close driving camera and on-screen view toggle
- [x] Add initial luxury coach passenger-cabin and premium truck dashboard details
- [ ] Test at multiple frame rates and device performance levels

### 3 — Oman vertical slice
- [x] Create an initial original desert-road environment
- [x] Add initial roadside destination signs and a moving visual traffic prototype (runtime verification pending)
- [ ] Add detailed road markings, terrain, buildings and landmarks
- [x] Add a first delivery checkpoint objective and HUD
- [x] Add a repeatable delivery restart control and a simple OMR reward counter (source implemented; runtime verification pending)
- [x] Save completed deliveries, in-game OMR wallet and selected vehicle locally on the device (runtime verification pending)
- [x] Add three selectable Oman-inspired delivery checkpoint routes with route selection and local route-progress saving (source implemented; runtime verification pending)
- [x] Add selectable general, construction and chilled-goods delivery jobs with different prototype rewards and local selection saving (source implemented; runtime verification pending)
- [x] Add a bus-only passenger trip mode, automatically select a bus, and award a separate prototype trip reward (source implemented; runtime verification pending)
- [ ] Add passenger pickup/drop-off stops, passenger animations and route-specific depot gameplay
- [ ] Add interactive traffic with collision avoidance, traffic signals and road rules
- [ ] Verify all third-party asset licenses

### 4 — First Android test release
- [ ] Add graphics, audio, sensitivity and control-layout settings
- [x] Add a GitHub Actions Godot 4 headless import and scene-launch validation workflow
- [ ] Configure a repeatable Android APK export
- [ ] Profile memory, frame time, loading and battery use
- [ ] Test on real Android devices
- [ ] Fix crashes and blocking gameplay issues

### 5 — Content expansion
- [x] Add a first bus prototype scene and model built from procedural meshes
- [x] Add luxury coach and VIP silver coach models
- [x] Add premium blue and royal red semi-truck models
- [x] Expand in-game fleet selector to six vehicles
- [ ] Replace procedural fleet models with optimized production-quality art assets
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
