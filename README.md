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
- Configure and save each company bus's vehicle model (starter truck, two semi-trucks, city bus or either luxury coach), route and preferred hired driver from the fleet-management panel; use AUTO ASSIGN to select the first available driver.
- A bus with a specifically assigned driver will not dispatch if that driver is busy; select another driver or AUTO ASSIGN.
- Choose immediate, 10-second or 30-second departure scheduling for each dispatch; scheduled buses and their assigned drivers are reserved until departure.
- Dispatch an available hired driver with an available company bus; the roster marks both ON ROUTE while the player continues driving.
- Return the assigned driver and bus to AVAILABLE when the timed trip completes; each completed trip reduces that bus's condition by 8 percentage points.
- Service the selected available bus back to 100% condition for OMR 1 per restored point; a bus at 15% condition or lower must be serviced before dispatch.
- Complete a timed background trip and receive a prototype net company return of OMR 50 after trip costs.
- Save the company name, funds, dispatch route, individual bus records, individual driver records and completed company trips locally.
- Show a fleet and staff roster with each bus and driver marked AVAILABLE or ON ROUTE.
- Dispatch reserves one available driver and one available bus; additional available driver/bus pairs can be dispatched while earlier company buses are still working. Each trip has its own bus instance, individually configured route, optional departure delay, route waypoints, passenger-stop dwell and completion event, and releases only its assigned driver and bus when it returns to the depot.

**Important prototype boundary:** company buses accelerate gradually, steer smoothly and follow five ordered road-centre waypoints on the same short straight test road before returning to the depot. Departure scheduling is a simple in-game countdown, not a clock-based timetable or persistent offline simulation. The company trip completes on depot arrival. At the destination, eight simple procedural low-poly passenger figures and a bus-stop label appear beside the company bus. They walk in a staggered sequence toward the bus entrance and shrink away as a visual boarding effect; the stop dwell is 6.5 seconds and the status label tracks the boarding count. This remains a visual placeholder: there is no individual pathfinding, functional door operation, interior seating, ticketing, or persistent passenger simulation. The bus still uses scripted waypoint navigation along one straight short test road, not a real road graph, junction navigation, traffic-aware AI, or a real Oman map.

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


### Driving model update
- The shared player vehicle controller now uses a simple speed-dependent torque curve, stronger low-speed acceleration, engine/rolling drag, and reduced steering authority at higher speeds.
- This remains an arcade-style CharacterBody3D controller; it is not yet a wheel-suspension or tire-physics simulation.

- Steering input now eases smoothly, and a lightweight lateral-grip approximation damps sideways momentum for more planted handling. This is still not full tire, suspension, or wheel-contact physics.


### Shared player vehicle controls
All six player-drivable vehicle models inherit a shared touch-control layer. The current shared cockpit/touch-control layer includes a procedural horn (including a wheel-area horn button), steering-wheel animation linked to steering input, left/right indicators, hazard flashers, animated wipers, a parking brake, an animated cab-door toggle, basic seat-height adjustment, low/high-beam (dipper) switching, parking-light switching, and a boot/cargo-payload visibility control. Brake input brightens the rear lamps. These are early prototype controls with simple procedural visuals; they still need in-game review and Android device testing. Vehicle-specific bus passenger-door/boarding systems, truck trailer coupling and towing physics, functional loading equipment, adjustable mirrors, a selectable P/R/N/D transmission with a low-speed gear-change interlock, and an engine ignition toggle that disables drive input and silences the procedural engine when switched off. These transmission/ignition controls are prototype logic, not a full automatic/manual gearbox or clutch simulation. A live instrument HUD now also displays vehicle speed, selected gear/engine state, estimated RPM, a simple warming engine-temperature value, and active parking-brake/light/indicator/trailer-leg warnings. These are prototype telemetry values, not calibrated real-vehicle gauges or a full engine thermal simulation. The starter truck also receives a modest acceleration and top-speed penalty while its mission cargo payload is loaded, and the HUD reports CARGO ONBOARD; this is a simple handling approximation, not a full weight-transfer or suspension-load model. All three bus/coach scene variants now expose an animated passenger-entry door. Passenger pickup missions require the player to stop the bus, open the passenger door, and enter the pickup checkpoint; reaching the gate with the door closed or while moving will not board passengers. This is a first functional boarding gate; individual passenger walking/boarding animations, interior aisle navigation, seating and ticketing remain planned. Both semi-truck variants now have a detachable trailer assembly and hinged rear trailer doors: stop, engage the parking brake, lower the landing legs, then uncouple. To reconnect, bring the tractor close to the detached trailer, stop and park, then use the trailer control. The rear trailer doors can be opened and closed with their own cockpit button. The trailer assembly follows the tractor while coupled and remains at its parked location when detached. Lowered landing legs prevent the tractor from driving until they are raised again. This is an early prototype coupling interaction; articulated fifth-wheel steering, independent trailer wheel physics, realistic reversing jack-knife behavior, air/electrical lines, and cargo transfer are still planned. A selectable rear-view camera is available from the REAR CAM touch control on the shared player-vehicle layer; it switches to a rear-facing camera and restores the previous view when switched off. This is a basic camera view, not yet a rendered mirror display or multi-camera mirror system. Functional loading equipment and adjustable mirrors also remain planned.


### Reverse lamps
- Two rear white reverse lamps illuminate automatically only while the engine is running and reverse gear is selected; they switch off when leaving reverse or turning the engine off.
- Rear brake-lamp intensity increases with service-brake input. These are functional visual signals in the current prototype, not certified vehicle lighting simulation.


### Brake and tail lamp behaviour
- Rear red tail lamps illuminate with parking lights and automatically while the service brake is pressed, even if parking lights are off.
- Brake application increases rear lamp emission intensity; releasing the brake returns them to the parking-light state.


### Seat-belt reminder
- The shared player vehicle controls now include a SEAT BELT toggle.
- The instrument status display shows a seat-belt warning while the vehicle is moving and the belt is unfastened.
- This is a gameplay reminder only; no crash restraint or occupant injury simulation is implemented yet.

- Left/right turn indicators now automatically cancel after five seconds; hazard lights remain active until manually switched off.


### Passenger pickup stop visuals
- Passenger jobs now show a group of eight simple procedural passenger figures waiting beside the pickup stop.
- The group follows the selected route's pickup location and disappears from the stop when the boarding checkpoint is accepted.
- These are visual placeholders; individual walking-to-door, boarding animations, seat assignment, passenger comfort and alighting sequences remain future work.


### City bus passenger cabin
- The Oman City Bus now includes ten procedural passenger seats arranged in paired rows, seat grab rails and a central aisle.
- Luxury and VIP coaches already have their own paired passenger-seat layouts.
- These are static cabin meshes; passengers are not yet individually assigned to seats and no seat-belt, walking or boarding animation is simulated.


### Passenger drop-off safety
- Passenger trips now require the bus to be stopped with its parking brake engaged and passenger doors open before the passengers are marked delivered and the fare is awarded.
- If the bus reaches the destination with doors closed, the mission waits; opening the doors while stopped at the terminal completes the drop-off without requiring the bus to leave and re-enter the checkpoint.
- Passenger figures remain visual pickup placeholders: this update does not yet animate individual passengers walking down the aisle, sitting, or alighting.


### Company bus boarding animation update
- Company-service passengers now form a staggered two-column queue, walk through a short approach path toward the bus entrance, and disappear as a visual boarding effect.
- A boarding manifest updates from 0/8 to 8/8 as each passenger's animation finishes.
- This remains a lightweight visual effect; it does not yet place passenger characters on interior seats or simulate individual door collision, navigation or alighting.


### Cargo loading and unloading safety
- Cargo pickup and delivery now require the player vehicle to be fully stopped and the parking brake engaged.
- If the vehicle enters a cargo checkpoint while moving or without the parking brake, the mission waits and displays an instruction; it can complete once the player stops and parks within the checkpoint area.
- This is a gameplay safety interlock. Physical forklift-to-truck transfer, pallet placement, cargo straps operated by the player, and loading animations remain planned.


### Depot cargo transfer animation
- The Oman depot now keeps its warehouse and forklift visible during a mission instead of hiding the entire depot after pickup.
- Crates animate from their pallet positions toward the loading bay and disappear as a simplified loading sequence; at delivery they reappear and animate back onto the depot pallets.
- Starting a new vehicle/mission resets the crate positions and visibility.
- This is a visual gameplay sequence, not yet physical forklift fork contact, pallet collision, cargo mass simulation, or player-operated loading machinery.

### Player-controlled depot forklift mast
- The depot forklift now has on-screen FORKS UP and FORKS DOWN controls. Each tap raises or lowers the fork carriage in bounded increments, with a short movement tween and a live height readout.
- The previous automatic up/down oscillation has been removed; the mast stays at the selected height until the player changes it.
- This controls mast height only. The forklift is still a stationary depot prop: driving, steering, fork tilt, pallet pickup/attachment, load stability and collision-based handling are not implemented yet.
