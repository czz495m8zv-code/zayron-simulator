# Zayron Simulator

**An Android-first, 3D bus and truck driving simulator built with free and open-source tools.**

The first playable region will be Oman. The long-term roadmap is to expand across the GCC and then worldwide.

## Project goals

- Android as the first target platform
- Bus and truck driving with believable vehicle handling
- Oman-inspired roads, terrain, towns, and driving environments
- Mobile-friendly visuals, performance, and controls
- Modular architecture so buses, trucks, maps, missions, and features can grow independently
- Free/open-source development tools wherever practical

## Technology

- **Godot Engine 4.x** — game engine and Android export
- **GDScript** — gameplay and simulation logic
- **Blender** — original 3D models and environment assets
- **Git + GitHub** — version control and project planning

## Development approach

We will build and test in small milestones: project foundation, a drivable prototype, vehicle physics, mobile controls, a small Oman test map, optimization, and Android testing. Realistic visuals will be balanced against performance on actual Android devices.

## Current status

**Current status: early gameplay prototype — source features are not yet verified in a clean Android run.**

Touch steering now tracks left and right buttons independently so releasing one held direction does not cancel the other still-held direction. The vehicle prototypes now have three selectable views (chase, close-follow and cockpit), with a basic steering-wheel model added to the starter truck, both semi-truck variants, city bus and luxury coaches. Cockpit camera positions are adjusted by vehicle type. Both enclosed semi-truck prototypes now share a more complete procedural trailer: reinforced underframe rails and axle cross-members, tandem wheel hubs, protective mudguards, rear mudflaps, landing legs and coupling plate, rear double doors with hinges and locking bars, rear tail/reverse lamps, a bumper and amber side marker lights. These remain lightweight block-mesh prototype details, not final production vehicle art. The Oman-inspired test road now includes a small procedural date-palm and desert-shrub roadside pass to make the route feel less empty; these are lightweight placeholder meshes, not a finished Oman map. The project now contains a first roadside Oman cargo depot with a warehouse, loading canopy, loading bay, pallets, staged crates, a procedural forklift prop with gently animated lifting forks and a pulsing amber safety beacon and visible cargo crates on the starter truck after pickup; staged depot props disappear when cargo is collected, plus a procedural Oman-inspired driving test scene, six selectable vehicle prototypes, touch controls, a delivery checkpoint, a basic OMR reward counter, a route-restart control, local career saving for deliveries/wallet/selected vehicle/route choice, three selectable checkpoint routes, three selectable delivery cargo types with different prototype rewards, a bus-only passenger trip mode with a pickup stop and separate destination drop-off checkpoint, initial roadside destination signs, and one moving visual traffic car. These are early source-level features; the project now has a GitHub Actions Godot headless import/launch check, but still needs Android device testing.

## Documentation

- [Development roadmap](docs/DEVELOPMENT_ROADMAP.md)
- [Technical architecture](docs/TECHNICAL_ARCHITECTURE.md)

## Important scope

This is an original game project. It will not copy proprietary game assets, maps, code, or branding. Third-party assets and map data must be checked for license and attribution requirements before use.


## Current vehicle fleet

The current source includes six selectable vehicle prototypes:
- Starter truck
- Premium blue semi-truck with enclosed trailer
- Royal red semi-truck with enclosed trailer
- Oman city bus
- Luxury coach with panoramic passenger windows and metallic trim
- VIP silver coach

Use the in-game **NEXT** button to cycle through the fleet and the **ROUTE** button to switch between three short Oman-inspired checkpoint routes and the **CARGO** button to choose general goods, construction supplies or chilled goods, and **JOB** to switch between cargo work and bus passenger trips. Cargo jobs now require reaching a loading checkpoint first, loading the selected goods, then driving to the route destination for delivery; the starter flatbed truck displays a matching crate payload after pickup; passenger trips require reaching the pickup gate first, boarding a displayed group of eight passengers, then driving to the destination drop-off gate. Both mission types use two stages, and their status resets when a route is restarted. Reach the green delivery gate to complete a run and earn a prototype reward of OMR 25; use **RESTART ROUTE** to drive again. The wallet is a gameplay placeholder, not real money. These original procedural Godot models are early prototypes, not final photorealistic assets, and still require on-device testing and visual refinement.
