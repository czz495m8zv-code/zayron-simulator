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

### Movable depot forklift and crate handling prototype
- The depot forklift now responds to on-screen MOVE FORWARD, MOVE BACK, MOVE LEFT and MOVE RIGHT controls, with movement constrained to a small depot work area.
- The player can lower the forks, move close to a visible depot crate and use GRAB / RELEASE CRATE to attach one crate to the fork carriage or set it back down.
- Fork height remains player-controlled with FORKS UP and FORKS DOWN, and the selected height is shown on screen.
- This is a first interaction prototype using bounded position steps and node attachment. It does not yet use vehicle-grade steering/drive physics, wheel rotation, collision-based fork insertion, pallet pickup, fork tilt, load stability, or realistic forklift hydraulics. Crates are handled individually rather than as a full pallet.


### Forklift steering and safer load movement
- The depot forklift now has STEER LEFT and STEER RIGHT controls. Forward, reverse and side-step movement follow the forklift's current facing direction, so players can turn before positioning at a crate.
- The procedural wheel meshes rotate during forward/reverse movement as a visual cue. This is not yet a fully simulated steering axle or wheel-physics system.
- When carrying a crate above the low travel-height threshold, movement is blocked and the HUD asks the player to lower the load first. This is a simple stability safeguard, not a calculated load-centre or tip-over model.
- If a cargo mission starts while a crate is attached to the forklift, the crate is safely returned to its depot home position before the mission's loading animation begins.
- Forklift movement is still bounded, button-step movement without collision physics, articulated steering geometry, hydraulic tilt, or full pallet handling.


### Forklift grouped-pallet handling
- Depot crates are now arranged as child objects of three separate pallet assemblies. The forklift's GRAB / RELEASE control targets a complete pallet assembly, keeping its crates together while it is lifted and moved.
- The cargo status reports the number of crates on the carried pallet. Starting a cargo mission returns a carried pallet and its crates to their depot home positions before the truck-loading visual sequence begins.
- Crate loading/unloading animations now use world-space positions so the grouped crate objects can animate correctly while parented to a pallet assembly.
- This is still a scripted attachment interaction, not collision-accurate fork insertion, pallet-jack/forklift physics, load-centre calculations, or realistic hydraulic tilt.


### Forklift fork tilt controls
- Added TILT BACK and TILT FORWARD controls for the moving fork carriage. Tilt is clamped to a small ±0.18-radian range and shown on the depot control panel. A pallet attached to the carriage follows its tilt.
- This is a visual scripted tilt feature; it does not yet simulate hydraulic cylinders, load-centre stability, pallet slip, or real forklift safety physics.

### Forklift pallet alignment and placement
- Pallet pickup now checks the fork approach direction and side-to-side alignment as well as proximity; the player must line the forklift up with the pallet instead of grabbing it from any nearby angle.
- A carried pallet can only be set down after the forks are lowered. The pallet remains at the forklift's placement point, and the tilt returns to level.
- Pallet crate home positions are now stored relative to their pallet assemblies, so resetting or changing routes does not rely on stale world-space coordinates.
- These are scripted proximity/alignment checks and node attachments, not physical fork-pocket collision, hydraulic load sensing, pallet friction, or collision-aware warehouse navigation.

### Marked pallet staging bays
- The depot now has three numbered visual staging bays. When a carried pallet is released close to an unoccupied bay, it snaps into that bay and the forklift panel reports the bay number.
- Picking a staged pallet frees its bay; mission resets also clear bay occupancy so the depot can be used again.
- If the forklift releases a pallet outside the staging area, it is parked where released and the panel asks the player to align it with a bay.
- Bay snapping and occupancy are scripted gameplay rules, not physical pallet collision or an automated warehouse conveyor system.

### Truck-side warehouse loading
- A marked truck loading bay has been added beside the depot, with a LOAD STAGED PALLET interaction that appears only when the player vehicle is nearby, stopped with its parking brake applied, and at least one pallet occupies a staging bay.
- Loading consumes one staged pallet, animates its crates toward the truck bay, updates the vehicle cargo payload and advances the cargo mission to its delivery destination.
- The original road checkpoint no longer grants cargo automatically; it directs the player to complete the warehouse loading process first.
- Starting a new vehicle/mission restores pallet visibility, original pallet positions, crate visibility and empty staging-bay occupancy.
- This remains a scripted transfer and payload visual/state update. It does not yet model a loading dock leveller, forklift-to-truck physical handoff, straps, weight distribution, or cargo physics.

### Cargo strap securing
- Loaded cargo now starts unsecured. A CARGO STRAPS / SECURE CARGO control appears on the vehicle touch panel while a payload is present.
- Securing the load reveals the strap and buckle visuals and updates the instrument status. Forward and reverse drive input remain blocked until the cargo is secured; braking and steering remain available.
- Clearing the cargo payload hides the strap control and resets the securing state. This is a gameplay safety interlock and visual representation, not a physics-based tensioning or load-shift simulation.
- Trailer rear doors now require the tractor to be stopped with the parking brake applied. Forward and reverse drive input are blocked while trailer doors are open; close them before moving.

### Passenger boarding and alighting
- Passenger jobs use eight visible low-poly waiting figures at the pickup stop. After the bus is stopped, parking brake applied and passenger doors opened, the figures animate toward the bus side and disappear as the onboard count is recorded.
- At the destination, the same figures reappear beside the stopped bus and animate toward a nearby waiting area. The passenger delivery reward is then credited.
- These are scripted exterior walk-up animations. There is not yet a true bus interior, seat assignment, collision-aware pathfinding, individual passenger AI, ticketing or realistic door-to-seat boarding.

### Passenger-door driving interlock
- Buses and coaches cannot receive forward or reverse drive input while their passenger entry door is open. Close the passenger door before moving away from a stop.
- The vehicle status display warns CLOSE PASSENGER DOORS while the door is open. Opening the door still requires the vehicle to be stopped with the parking brake applied.
- This is a control interlock; it does not yet simulate door pressure sensors, pneumatic mechanisms or emergency release hardware.

### Delivery-site cargo unloading
- Reaching the cargo destination no longer completes delivery automatically. The player must stop inside the delivery area, apply the parking brake and use the UNLOAD DELIVERED CARGO interaction.
- The unload interaction appears only within the delivery radius while the vehicle is stationary with the parking brake engaged. Successful unloading clears the vehicle payload, records the delivery and pays the selected cargo reward.
- This is a scripted unloading interaction; animated workers, dock equipment and physical pallet transfer at destination remain future work.

### Desktop driving safety parity
- Keyboard driving now uses the same engine, selected-drive-gear, passenger-door, trailer-door/landing-leg and unsecured-cargo interlocks as the Android touch controls.
- Braking and steering remain available so the player can safely stop or manoeuvre while a drive interlock is active.
- This keeps the desktop fallback from bypassing safety rules that already apply to mobile throttle and reverse inputs.


### Bus cabin window openings
- Replaced the single opaque bus body mesh with separate roof, bulkhead, lower/upper side panels and window pillars. The side windows are now open gaps rather than glass sitting over a solid wall, so the existing passenger seats, aisle and grab rails can be seen from outside.
- The main chassis collision shape remains unchanged. This is a visual body-shell improvement; it does not yet add glass physics, a fully modelled interior, or animated passenger seat assignment.


### Visible seated passengers
- Passenger-mode pickup now creates a visible seated passenger group inside the active bus/coach, up to the ten available seat positions. The group is cleared after passengers alight and whenever the active vehicle is reset.
- This is a visual seat-occupancy representation tied to the passenger mission count; individual walking paths through the door, seat reservations, passenger AI, and persistent passenger identities are not simulated yet.


### Passenger boarding sequence
- Passenger seat-occupancy visuals now appear after the exterior boarding animation finishes, rather than immediately when the mission checkpoint is activated.
- The passenger status changes from BOARDING PASSENGERS to PASSENGERS SEATED after the final boarding figure reaches the bus. This remains a timed visual sequence and does not simulate individual walking through the doorway or seat navigation.


### Passenger capacity and dashboard occupancy
- The shared vehicle script caps visible seated passengers at the ten modeled coach seat positions. The cockpit status line displays the seated passenger count for buses and coaches while occupied.
- This is a display/capacity guard for the visual passenger manifest; it is not a ticketing system or dynamic seat reservation simulation.


### Fuel gauge and refuelling
- Player vehicles consume fuel based on distance travelled and engine load, show a cockpit fuel percentage, and display LOW FUEL / OUT OF FUEL warnings.
- At zero fuel, throttle and reverse are inhibited. The REFUEL control restores the tank only while the vehicle is stopped and the parking brake is engaged.
- This is an initial vehicle-level fuel prototype: refuelling is currently free and available from the control anywhere while parked. Fuel stations, fuel prices, tank-size differences and persistent fuel storage remain future work.


### Oman depot fuel station
- Added a visible diesel/petrol dispenser and canopy beside the logistics depot.
- The vehicle REFUEL control is enabled only when the player vehicle is within 6 metres of the station, and refuelling still requires the vehicle to be stopped with the parking brake engaged.
- Fueling is currently free; economy integration, separate diesel/petrol compatibility, fuel quantities and station network expansion remain future work.


### Fuel economy transaction
- Fuel is purchased at the depot station using the player's saved career wallet.
- Refill cost is proportional to the missing fuel level at OMR 0.12 per percentage point (rounded up); the control shows the required amount and disables when the wallet cannot cover it.
- The game rechecks station proximity, parking state and wallet balance before deducting money, then saves the updated wallet.
- Fuel level itself is not yet persisted across vehicle resets, and fuel type/tank capacity are still simplified.


### Persistent vehicle fuel tanks
- Fuel level is saved independently for each of the six player vehicle types in the career save.
- Switching vehicles stores the outgoing vehicle's current fuel and restores the selected vehicle's saved fuel.
- The active vehicle's fuel is captured whenever career progress is saved, so wallet and mission saves also preserve its current tank level.

- Career progress, including each vehicle's fuel level, is also saved when the app is paused or closed.


### Roadside highway fuel station
- Added a second Oman Fuel forecourt along the highway route, with an access lane, canopy, two dispensers, and diesel/petrol signage.
- Player vehicles can refuel at either the cargo depot pump or the roadside station; both use the same stopped-and-parked wallet transaction and per-vehicle saved fuel level.
- The roadside station is a prototype landmark on the current test-road segment, not a real-world Oman fuel network or real fuel-price simulation.


### Highway traffic expansion
- Replaced the single looping traffic sedan with three independently moving traffic cars, each with its own color, starting gap, and speed.
- Traffic remains a visual prototype: vehicles do not yet use collision avoidance, lane-changing AI, traffic signals, or full road rules.


### Highway traffic following behaviour

The three prototype highway cars now use a lightweight same-lane following model. Each car measures the wrapped distance to the next car ahead and smoothly reduces its speed when the gap closes, then accelerates back toward its configured cruising speed as the gap opens. This avoids the previous purely independent movement and reduces visual overlap in the traffic loop. It remains a simplified visual simulation: traffic cars do not yet have collision bodies, lane changes, junction logic, or interaction with the player's vehicle.


### Oman highway speed signage and traffic loop correction
- Added three visible 80 km/h speed-limit boards along alternating sides of the Oman-inspired test road.
- Corrected traffic-car respawn positions so all vehicles return inside the same 142 m loop with consistent spacing and ordering. This prevents wrapped-distance calculations from treating off-loop respawns as overlapping traffic.
- Speed signs are visual environment props only; the player is not yet subject to a speed-limit enforcement or fine system.


### Prototype Oman T-junction and animated traffic signals
- Added a short asphalt access spur to form a visible T-junction beside the test highway.
- Added paired three-aspect traffic signal heads with red, amber, and green emissive lamps.
- Signal phase cycles automatically: green for 8 seconds, amber for 2 seconds, and red for 4 seconds.
- This is currently an environmental prototype only. Traffic cars and the player vehicle do not yet stop at the signal, and the spur is not yet a fully navigable route with junction AI.


### Signal-aware highway traffic
- Added a visible stop bar on the approach to the prototype T-junction.
- The three looping highway traffic cars now calculate a safe approach speed and stop before the bar while the signal is red or amber.
- Traffic resumes after the green phase begins; acceleration and braking are smoothed.
- This is a first-pass single-lane traffic rule. It does not yet implement turning vehicles, cross traffic, pedestrian signals, collision-aware queues, or player enforcement.


### Player vehicle traffic-signal braking
- The player's active truck or bus now receives a smooth braking assist while approaching the prototype junction on red or amber.
- Braking is based on distance to the stop line and a simple deceleration estimate, while the driver's normal brake input remains effective.
- The dashboard status indicates TRAFFIC SIGNAL while the assist is active.
- This is a prototype single approach rule; it does not yet cover the opposite direction, turning lanes, cross traffic, or real-world traffic-law edge cases.


### Junction signal timing and stop-line correction
- Corrected the signal phase order to green (8 s), amber (2 s), red (4 s), matching the documented cycle.
- Corrected the player's approach-distance calculation for travel toward decreasing Z coordinates. The earlier sign was reversed, so player-side braking could fail to engage.
- Added a firm low-speed stop hold within 1 m of the stop line during red/amber.
- Highway traffic uses the same green phase as the visible signal.


### Junction stop-line refinement
- Extended the stop bar across the full highway carriageway so it is visible from both the centre player lane and the traffic lane.
- Added a low-speed stop hold for AI traffic at the line during red/amber.
- Player braking assist now continues holding the vehicle if it reaches or slightly passes the stop-line coordinate while the signal remains red/amber, rather than releasing immediately after crossing the coordinate.


### Side-road give-way markings and signage
- Added a dashed centre marking along the side access road.
- Added a give-way bar and painted triangular yield markings at the junction mouth.
- Added a roadside GIVE WAY sign for vehicles approaching from the side access road.
- These markings are visual guidance only; side-road cross-traffic and yield enforcement are not simulated yet.


### Signal-coordinated side-road traffic
- Added an independently animated vehicle on the T-junction access road.
- It approaches and waits at the give-way line while the main road has green.
- It crosses the highway during the main road's red/amber phase, then loops back for another approach.
- This is a scripted traffic demonstration, not yet collision-aware gap acceptance or a full junction AI system.


### Side-road junction gap checks
- Side-road traffic now checks the physical conflict zone before entering during its permitted phase.
- It waits if a highway traffic vehicle or the player is passing through the junction.
- A vehicle already committed to crossing is allowed to clear the junction instead of stopping in the carriageway.
- This remains a simplified position-based check without collision shapes, predictive time-to-collision, or lane-aware turning paths.

### Junction all-red clearance and crossing protection
- Extended the signal cycle to 16 seconds: green 8 s, amber 2 s, red 6 s.
- Side-road traffic remains held through green, amber, and the first 2 seconds of red; it may enter only during the final 4 seconds of the red phase.
- The final 2 seconds of red provide an all-red clearance interval before the main road returns to green.
- Side-road traffic now crosses faster to target clearing the junction before the next green phase.
- Main-road AI traffic is held outside the conflict area while the side-road vehicle occupies the crossing.
- Player braking assistance also holds before the stop line while the side-road vehicle is crossing.
- This remains a single scripted vehicle and position-based conflict zone; it is not a complete multi-lane junction controller or collision-physics system.


### Full side-road crossing
- Extended the Oman T-junction access road beyond the opposite side of the highway, with a matching asphalt surface and centre dashes.
- Side-road traffic now traverses the full crossing and west exit before recycling to its approach position; it no longer respawns as soon as it clears the main carriageway.
- This remains a scripted single-vehicle traffic prototype, not a complete multi-lane road network or collision-physics traffic simulation.


### Junction pedestrian crossing markings
- Added a six-stripe zebra crossing across the side-road mouth, with raised kerb-edge guides.
- The crossing is currently visual road infrastructure only; pedestrian AI, crossing signals and vehicle yielding to pedestrians are not implemented yet.


### Junction pedestrian crossing behaviour
- Added a simple procedural pedestrian who waits at the kerb, walks across the marked zebra crossing, and repeats after a short interval.
- Side-road AI traffic yields while the pedestrian occupies the crossing zone; main-road AI traffic pauses near the junction during the crossing.
- This is a single scripted pedestrian prototype with position-based yielding, not pedestrian pathfinding, collision physics, pedestrian signals, or a crowd system.


### Pedestrian walking animation
- Replaced static pedestrian legs with pivoted leg nodes and alternating swing while crossing the zebra crossing.
- Leg motion settles back to a standing pose while the pedestrian waits at either kerb.
- Animation is procedural and lightweight; it does not use a skeletal character rig or motion-capture animation.


### Coordinated pedestrian signal
- Added a two-aspect pedestrian signal beside the zebra crossing with red WAIT and green WALK lamps.
- The pedestrian waits at the kerb until the main-road vehicle signal enters its red phase, then crosses at a faster walking pace designed to clear before the next cycle.
- Side-road traffic continues to yield while the pedestrian occupies the crossing.
- This is a timed prototype signal, not a standards-certified pedestrian crossing controller.


### Pedestrian signal text indicators
- Added illuminated 3D WAIT and WALK text labels beside the two-aspect pedestrian signal.
- The labels switch with the same timed crossing phase as the signal lamps and pedestrian movement.


### Pedestrian signal countdown and cycle safety
- Added a numeric countdown on the pedestrian signal showing seconds until the next WAIT/WALK phase.
- Fixed the crossing state so the pedestrian crosses only once per red phase and does not restart at the far kerb before the signal changes.
- The crossing cycle resets after the main-road signal returns to green/amber.


### Vehicle traffic-signal countdown displays
- Both roadside three-aspect traffic signals now display a numeric countdown to the end of the active green, amber, or red phase.
- The countdown is driven by the same 16-second junction signal clock used by traffic and player stop-line logic.


### Pedestrian WALK clearance warning
- During the final two seconds of the pedestrian signal's red-traffic interval, the green WALK lamp and WALK text flash at a steady 0.8-second cycle.
- The numeric countdown remains visible so pedestrians receive a clear indication that the phase is ending.

### Road-position awareness
- The driving HUD reports normal road position, lane-departure warning, and road-edge warning based on the player's lateral position on the current prototype highway.
- The warning is visual only; it does not steer the vehicle, apply braking, or represent a full lane-marking/collision detection system.

### Junction approach guidance
- The driving HUD now shows approximate distance to the prototype junction stop line while approaching, with guidance for green, stop/prepare-to-stop phases, and crossing side-road traffic.
- This is limited to the single test intersection and uses prototype world coordinates; it is not a complete traffic-law system or a guarantee that the junction is safe to enter.

### Pedestrian proximity awareness
- The driving HUD warns when the animated junction pedestrian is crossing close to the player's vehicle and returns to a clear status when the hazard is no longer nearby.
- This is a proximity warning for the current prototype crossing only; it is not certified collision avoidance and does not guarantee that a collision will be prevented.

### Highway speed awareness
- The driving HUD shows the prototype highway limit of 80 km/h and changes to a caution/overspeed warning above the limit.
- This is a visual driver-awareness warning only; it does not yet issue fines, enforce speed, or model location-specific speed-limit zones.

### Engine and fuel behaviour
- The vehicle dashboard shows an approximate remaining driving range alongside fuel percentage. It is calculated from the prototype's distance-based fuel rate; idling, payload, terrain and driving style can reduce actual range.

- Fuel consumption now runs only while the engine is switched on, combining distance travelled with a small idle and throttle-load allowance.
- A vehicle with an empty tank cannot restart its engine; the ignition control displays a no-fuel reminder until the vehicle is refuelled.

### Refuelling safety interlock
- Refuelling is available only at the depot or roadside fuel station, while fully stopped with the parking brake engaged.
- The engine must also be switched off. The refuel control stays disabled while the engine is running and displays an engine-off reminder.
- Fuel level and wallet balance remain part of the saved career state.

### Junction stop-line clearance safety
- Main-road AI traffic and the player driving-assist brake only apply a red/amber stop when the vehicle is still before the stop line.
- A vehicle that legally entered the junction on green is no longer commanded to stop merely because the signal changes while it is clearing the conflict area.
- Side-road and pedestrian conflict yielding remain active independently.

### Live junction phase status on the driving HUD
- Added a compact status line below the mission objective showing the active junction phase and seconds remaining.
- The HUD distinguishes main-road green/amber, pedestrian WALK while main-road traffic is red, all-red clearance, and the protected side-road crossing window.
- The status is derived from the same 26-second signal clock that controls the roadside lamps, pedestrian signal, AI traffic and player braking assist.
- This gives the driver an at-a-glance phase cue without relying only on distant roadside countdown boards.

### Protected multi-phase T-junction signal cycle
- Extended the junction cycle to 26 seconds: main-road green 8 s, amber 2 s, and red 16 s.
- Pedestrian WALK runs from second 10 to second 16, followed by an all-red clearance interval.
- Side-road traffic receives a dedicated protected crossing window from second 18 to second 24, followed by a 2-second all-red clearance before main-road green returns.
- Side-road vehicles wait behind the give-way line until their phase, enter only when the junction is clear, and are allowed to finish crossing once committed.
- The main-road traffic countdown and player braking assist use the same 26-second cycle; the pedestrian countdown includes the wait until the next WALK phase.
- This remains a single-lane scripted junction prototype, not a certified signal controller or collision-physics traffic system.

### Physical highway traffic obstacles

- The three moving highway sedans and the crossing side-road sedan now have `AnimatableBody3D` collision bodies with compact box shapes.
- The player vehicle can physically contact these traffic vehicles instead of passing through visual-only meshes.
- The collision response and damage model are lightweight gameplay approximations, not a complete road-user physics simulation.

### Traffic impact response

- Hitting a highway traffic collision body at driving speed sharply reduces the player's speed, activates hazard lights, and displays a temporary `COLLISION - CHECK VEHICLE` dashboard warning.
- The impact response is a simple gameplay approximation; it does not yet model vehicle deformation, repair costs, injury, insurance, or detailed crash physics.


### Vehicle collision damage and depot repair

- Highway traffic impacts now add persistent damage to the currently selected player vehicle. Damage is capped at 100% and reduces available acceleration and top speed as condition worsens.
- The dashboard reports the vehicle's damage percentage and a reduced-power warning at higher damage levels. Damage is stored separately for each of the six player vehicle choices and survives game restarts.
- A service control is available at the depot/roadside service area. Repairs cost OMR 1 per damage point and require the vehicle to be stopped, parking brake engaged, and engine switched off. Repair cost is deducted from the player's wallet and the vehicle returns to 0% damage. The main-game payment handler independently rechecks the stopped, parking-brake, and engine-off conditions before charging, rather than relying only on the button's disabled state.
- This is a simple condition-and-repair loop: it does not include component-specific faults, visible deformation, towing, insurance, or a full damage physics model.


### Collision damage persistence and repeat-impact protection

- Sustained contact with a traffic collision body is now rate-limited: the vehicle receives one damage event per 1.5-second impact cooldown instead of accumulating damage every physics frame while touching the same obstacle.
- Each new damage event triggers an immediate career save, preserving the selected vehicle's condition if the app is paused or interrupted shortly after a crash.
