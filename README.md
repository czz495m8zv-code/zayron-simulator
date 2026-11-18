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

A shared vehicle-light pass adds a LIGHTS toggle, directional headlight spotlights, front/rear lamp meshes and brake-responsive rear-lamp brightness; light placement and visual impact still need in-game review. A pause/settings overlay provides resume, route restart, a master-volume slider and adjustable locally saved steering sensitivity. These additions are source-implemented but still need Android runtime verification. Touch steering now tracks left and right buttons independently so releasing one held direction does not cancel the other still-held direction. The vehicle prototypes now have three selectable views (chase, close-follow and cockpit), with a basic steering-wheel model added to the starter truck, both semi-truck variants, city bus and luxury coaches. Cockpit camera positions are adjusted by vehicle type. Both enclosed semi-truck prototypes now share a more complete procedural trailer: reinforced underframe rails and axle cross-members, tandem wheel hubs, protective mudguards, rear mudflaps, landing legs and coupling plate, rear double doors with hinges and locking bars, rear tail/reverse lamps, a bumper and amber side marker lights. These remain lightweight block-mesh prototype details, not final production vehicle art. The Oman-inspired test road now includes a small procedural date-palm and desert-shrub roadside pass to make the route feel less empty; these are lightweight placeholder meshes, not a finished Oman map. The project now contains a first roadside Oman cargo depot with a warehouse, loading canopy, loading bay, pallets, staged crates, a procedural forklift prop with gently animated lifting forks and a pulsing amber safety beacon and visible cargo crates on the starter truck after pickup; staged depot props disappear when cargo is collected, plus a procedural Oman-inspired driving test scene, six selectable vehicle prototypes, touch controls, a delivery checkpoint, a basic OMR reward counter, a route-restart control, local career saving for deliveries/wallet/selected vehicle/route choice, three selectable checkpoint routes, three selectable delivery cargo types with different prototype rewards, a bus-only passenger trip mode with a pickup stop and separate destination drop-off checkpoint, initial roadside destination signs, and one moving visual traffic car. These are early source-level features; the project now has a GitHub Actions Godot headless import/launch check, but still needs Android device testing.


## Transport company management — first playable foundation

The first company-management layer is now implemented in the gameplay scene:
- Rename the player's transport company.
- Start with a separate company account of OMR 500, one company bus and no hired drivers.
- Hire a driver for the prototype cost of OMR 80.
- Purchase an additional company bus for the prototype cost of OMR 450.
- Select a company dispatch route independently of the player's personal driving route.
- Dispatch an available hired driver with an available company bus; the roster marks both ON ROUTE while the player continues driving.
- Return the assigned driver and bus to AVAILABLE when the timed trip completes.
- Complete a timed background trip and receive a prototype net company return of OMR 50 after trip costs.
- Save the company name, funds, dispatch route, individual bus records, individual driver records and completed company trips locally.
- Show a fleet and staff roster with each bus and driver marked AVAILABLE or ON ROUTE.
- Dispatch reserves one available driver and one available bus; both return to AVAILABLE after the simulated trip completes.

**Important prototype boundary:** the visible company bus accelerates gradually, steers smoothly, follows five ordered road-centre waypoints to the selected test-road endpoint, pauses for three seconds, then follows those waypoints in reverse to return to the depot. The company trip completes on depot arrival. At the destination, eight simple procedural low-poly passenger figures and a bus-stop label appear beside the company bus. They walk in a staggered sequence toward the bus entrance and shrink away as a visual boarding effect; the stop dwell is 6.5 seconds and the status label tracks the boarding count. This remains a visual placeholder: there is no individual pathfinding, functional door operation, interior seating, ticketing, or persistent passenger simulation. The bus still uses scripted waypoint navigation along one straight short test road, not a real road graph, junction navigation, traffic-aware AI, or a real Oman map.

## Android build

A GitHub Actions workflow attempts to export an arm64 Android debug APK on pushes to `main` and manual workflow runs. When the workflow succeeds, download the `ZayronSimulator-Android-debug` artifact from the repository's Actions run page. This is a debug build for installation/testing, not a Play Store release. The project has not yet been verified on a physical Android device.

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
