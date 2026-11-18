extends Node3D

const FLEET_SCENES: Array[PackedScene] = [
	preload("res://scenes/vehicles/prototype_truck.tscn"),
	preload("res://scenes/vehicles/premium_semi.tscn"),
	preload("res://scenes/vehicles/royal_red_semi.tscn"),
	preload("res://scenes/vehicles/prototype_bus.tscn"),
	preload("res://scenes/vehicles/luxury_coach.tscn"),
	preload("res://scenes/vehicles/vip_silver_coach.tscn")
]
const FLEET_NAMES: Array[String] = [
	"STARTER TRUCK",
	"PREMIUM BLUE SEMI",
	"ROYAL RED SEMI",
	"OMAN CITY BUS",
	"LUXURY COACH",
	"VIP SILVER COACH"
]

var _active_vehicle: Node3D
var _selected_vehicle: int = 0
var _vehicle_button: Button
var _mission_label: Label
var _mission_complete: bool = false
var _mission_target := Vector3(0.0, 0.0, -82.0)
var _delivery_count: int = 0
var _cash_balance: int = 0
var _cash_label: Label
var _restart_button: Button
var _traffic_car: Node3D
var _traffic_speed: float = 7.5
const SAVE_PATH := "user://zayron_progress.cfg"
const ROUTE_NAMES: Array[String] = ["MUSCAT -> NIZWA", "NIZWA -> SUR", "SUR -> MUSCAT"]
const ROUTE_TARGETS: Array[Vector3] = [Vector3(0.0, 0.0, -82.0), Vector3(0.0, 0.0, -48.0), Vector3(0.0, 0.0, -112.0)]
const CARGO_NAMES: Array[String] = ["GENERAL GOODS", "CONSTRUCTION SUPPLIES", "CHILLED GOODS"]
const CARGO_REWARDS: Array[int] = [25, 40, 35]
const PASSENGER_TRIP_REWARD: int = 30
const PASSENGER_GROUP_SIZE: int = 8

var _selected_route: int = 0
var _route_button: Button
var _checkpoint_area: Area3D
var _checkpoint_gate_parts: Array[MeshInstance3D] = []
var _selected_cargo: int = 0
var _cargo_button: Button
var _passenger_mode: bool = false
var _mission_type_button: Button
var _passenger_pickup_done: bool = false
var _passenger_pickup_target := Vector3(0.0, 0.0, -37.0)
var _checkpoint_label: Label3D
var _passenger_status_label: Label
var _cargo_status_label: Label
var _cargo_pickup_done: bool = false
var _cargo_depot: Node3D
var _forklift_carriage: Node3D
var _forklift_beacon: OmniLight3D
var _forklift_animation_time: float = 0.0
var _pause_button: Button
var _pause_overlay: Control
var _audio_slider: HSlider
var _steering_slider: HSlider
var _steering_sensitivity: float = 1.0
var _master_volume: float = 1.0

# First playable transport-company management layer.
var _company_name: String = "ZAYRON TRANSPORT"
var _company_funds: int = 500
var _company_bus_count: int = 1
var _company_driver_count: int = 0
var _company_completed_trips: int = 0
var _company_trip_active: bool = false
var _company_trip_timer: Timer
var _company_panel: Control
var _company_summary_label: Label
var _company_status_label: Label
var _company_name_edit: LineEdit
var _company_dispatch_button: Button

func _ready() -> void:
	_load_progress()
	_mission_target = ROUTE_TARGETS[_selected_route]
	_passenger_pickup_target = Vector3(0.0, 0.0, (8.0 + _mission_target.z) * 0.5)
	_mission_target = _passenger_pickup_target
	_build_environment()
	_build_oman_test_road()
	_build_oman_roadside_vegetation()
	_build_roadside_signs()
	_build_traffic_vehicle()
	_build_mission()
	_build_cargo_depot()
	_spawn_vehicle()
	_build_vehicle_selector()
	_build_mission_hud()
	_build_pause_menu()
	_build_company_management()

func _process(delta: float) -> void:
	if is_instance_valid(_traffic_car):
		_traffic_car.position.z += _traffic_speed * delta
		if _traffic_car.position.z > 24.0:
			_traffic_car.position.z = -118.0
	if is_instance_valid(_forklift_carriage):
		_forklift_animation_time += delta
		_forklift_carriage.position.y = 0.48 + (sin(_forklift_animation_time * 1.35) + 1.0) * 0.22
	if is_instance_valid(_forklift_beacon):
		_forklift_beacon.light_energy = 0.15 + (0.85 if sin(_forklift_animation_time * 4.0) > 0.15 else 0.0)
	if _company_trip_active and is_instance_valid(_company_status_label) and is_instance_valid(_company_trip_timer):
		_company_status_label.text = "DRIVER EN ROUTE  |  ARRIVAL IN %d SEC" % ceili(_company_trip_timer.time_left)
	if not is_instance_valid(_mission_label) or _mission_complete or not is_instance_valid(_active_vehicle):
		return
	var distance := Vector2(_active_vehicle.global_position.x - _mission_target.x, _active_vehicle.global_position.z - _mission_target.z).length()
	var stage_name := "LOAD CARGO" if not _cargo_pickup_done else "DELIVER CARGO"
	if _passenger_mode:
		stage_name = "PICKUP STOP" if not _passenger_pickup_done else "PASSENGER DROP-OFF"
	_mission_label.text = "%s  |  %s: %d m" % [ROUTE_NAMES[_selected_route], stage_name, int(distance)]

func _spawn_vehicle() -> void:
	_mission_complete = false
	_passenger_pickup_done = false
	_cargo_pickup_done = false
	if is_instance_valid(_cargo_status_label):
		_cargo_status_label.text = "CARGO STATUS: WAITING FOR LOAD"
	if is_instance_valid(_cargo_depot):
		_cargo_depot.visible = not _passenger_mode
		_cargo_depot.position.z = (8.0 + ROUTE_TARGETS[_selected_route].z) * 0.5
	if is_instance_valid(_passenger_status_label):
		_passenger_status_label.text = "PASSENGERS ON BOARD: 0"
	if _passenger_mode or not _cargo_pickup_done:
		_mission_target = Vector3(0.0, 0.0, (8.0 + ROUTE_TARGETS[_selected_route].z) * 0.5)
	else:
		_mission_target = ROUTE_TARGETS[_selected_route]
	if is_instance_valid(_checkpoint_area):
		_checkpoint_area.position = _mission_target
	_move_checkpoint_gate()
	if is_instance_valid(_active_vehicle):
		_active_vehicle.queue_free()
	_active_vehicle = FLEET_SCENES[_selected_vehicle].instantiate() as Node3D
	_active_vehicle.position = Vector3(0.0, 0.15, 8.0)
	add_child(_active_vehicle)
	_sync_vehicle_cargo_payload()
	_apply_vehicle_settings()
	if is_instance_valid(_vehicle_button):
		_vehicle_button.text = "NEXT: " + FLEET_NAMES[(_selected_vehicle + 1) % FLEET_NAMES.size()]
	if is_instance_valid(_mission_label):
		_mission_label.text = "%s  |  CHECKPOINT: 000 m" % ROUTE_NAMES[_selected_route]


func _apply_vehicle_settings() -> void:
	if is_instance_valid(_active_vehicle) and _active_vehicle.has_method("set_steering_sensitivity"):
		_active_vehicle.set_steering_sensitivity(_steering_sensitivity)

func _sync_vehicle_cargo_payload() -> void:
	if not is_instance_valid(_active_vehicle) or not _active_vehicle.has_method("set_cargo_payload"):
		return
	var show_payload := _selected_vehicle == 0 and not _passenger_mode and _cargo_pickup_done
	_active_vehicle.set_cargo_payload(_selected_cargo, show_payload)


func _build_vehicle_selector() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var button := Button.new()
	button.name = "VehicleSelector"
	button.text = "NEXT: PREMIUM BLUE SEMI"
	button.custom_minimum_size = Vector2(180.0, 54.0)
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.anchor_top = 0.0
	button.anchor_bottom = 0.0
	button.offset_left = -204.0
	button.offset_right = -20.0
	button.offset_top = 22.0
	button.offset_bottom = 76.0
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color.WHITE)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.16, 0.25, 0.92)
	style.border_color = Color(0.2, 0.72, 0.95, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	button.add_theme_stylebox_override("normal", style)
	button.pressed.connect(_on_vehicle_button_pressed)
	layer.add_child(button)
	_vehicle_button = button

func _on_vehicle_button_pressed() -> void:
	if _passenger_mode:
		_selected_vehicle = 3 + ((_selected_vehicle - 3 + 1) % 3)
	else:
		_selected_vehicle = (_selected_vehicle + 1) % FLEET_SCENES.size()
	_spawn_vehicle()
	_save_progress()

func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.12, 0.36, 0.62)
	sky_material.sky_horizon_color = Color(0.72, 0.82, 0.91)
	sky_material.ground_bottom_color = Color(0.38, 0.28, 0.18)
	sky_material.ground_horizon_color = Color(0.72, 0.62, 0.48)
	environment.sky.sky_material = sky_material
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.76, 0.82)
	environment.ambient_light_energy = 0.65
	world_environment.environment = environment
	add_child(world_environment)

	var ground := StaticBody3D.new()
	ground.name = "DesertGround"
	add_child(ground)
	var ground_mesh := MeshInstance3D.new()
	var ground_box := BoxMesh.new()
	ground_box.size = Vector3(180.0, 1.0, 180.0)
	ground_mesh.mesh = ground_box
	ground_mesh.position.y = -0.55
	var sand := StandardMaterial3D.new()
	sand.albedo_color = Color(0.67, 0.49, 0.30)
	ground_mesh.material_override = sand
	ground.add_child(ground_mesh)
	var ground_collision := CollisionShape3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = ground_box.size
	ground_collision.shape = ground_shape
	ground_collision.position.y = -0.55
	ground.add_child(ground_collision)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

func _build_oman_test_road() -> void:
	var road := _make_box("AsphaltRoad", Vector3(9.0, 0.12, 150.0), Vector3(0.0, 0.03, -48.0), Color(0.12, 0.13, 0.14))
	add_child(road)

	# Fine procedural aggregate gives the road surface visual texture without external assets.
	var asphalt_noise := FastNoiseLite.new()
	asphalt_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	asphalt_noise.frequency = 0.075
	asphalt_noise.fractal_octaves = 3
	var asphalt_texture := NoiseTexture2D.new()
	asphalt_texture.width = 512
	asphalt_texture.height = 512
	asphalt_texture.seamless = true
	asphalt_texture.noise = asphalt_noise
	var asphalt_surface := MeshInstance3D.new()
	asphalt_surface.name = "TexturedAsphaltSurface"
	var asphalt_plane := PlaneMesh.new()
	asphalt_plane.size = Vector2(9.0, 150.0)
	asphalt_surface.mesh = asphalt_plane
	asphalt_surface.position = Vector3(0.0, 0.094, -48.0)
	var asphalt_material := StandardMaterial3D.new()
	asphalt_material.albedo_color = Color(0.31, 0.32, 0.33)
	asphalt_material.albedo_texture = asphalt_texture
	asphalt_material.roughness = 0.96
	asphalt_material.uv1_scale = Vector3(1.0, 7.0, 1.0)
	asphalt_surface.material_override = asphalt_material
	add_child(asphalt_surface)

	# Continuous edge lines and reflective road studs improve road scale and night readability.
	for side in [-1.0, 1.0]:
		var edge_line := _make_box("RoadEdgeLine_%s" % side, Vector3(0.12, 0.025, 150.0), Vector3(side * 4.18, 0.108, -48.0), Color(0.88, 0.87, 0.79))
		add_child(edge_line)
		for stud_index in range(30):
			var stud := _make_box("ReflectiveRoadStud_%s_%02d" % [side, stud_index], Vector3(0.10, 0.035, 0.16), Vector3(side * 4.02, 0.115, 23.0 - float(stud_index) * 4.9), Color(0.92, 0.78, 0.36))
			add_child(stud)
	var shoulder_left := _make_box("LeftRoadShoulder", Vector3(1.0, 0.10, 150.0), Vector3(-5.0, 0.0, -48.0), Color(0.48, 0.39, 0.29))
	add_child(shoulder_left)
	var shoulder_right := _make_box("RightRoadShoulder", Vector3(1.0, 0.10, 150.0), Vector3(5.0, 0.0, -48.0), Color(0.48, 0.39, 0.29))
	add_child(shoulder_right)

	for i in range(15):
		var dash := _make_box("CentreLine_%02d" % i, Vector3(0.14, 0.025, 3.2), Vector3(0.0, 0.105, 18.0 - float(i) * 8.5), Color(0.92, 0.91, 0.82))
		add_child(dash)

	for i in range(7):
		var side := -1.0 if i % 2 == 0 else 1.0
		var hill := MeshInstance3D.new()
		var hill_mesh := SphereMesh.new()
		hill_mesh.radius = 1.0
		hill_mesh.height = 2.0
		hill.mesh = hill_mesh
		hill.scale = Vector3(10.0 + float(i % 3) * 3.0, 5.0 + float(i % 2) * 2.0, 8.0)
		hill.position = Vector3(side * (17.0 + float(i % 2) * 5.0), 2.0, -12.0 - float(i) * 18.0)
		var rock := StandardMaterial3D.new()
		rock.albedo_color = Color(0.48, 0.35, 0.25) if i % 2 == 0 else Color(0.58, 0.43, 0.30)
		hill.material_override = rock
		add_child(hill)

	for i in range(12):
		var side := -1.0 if i % 2 == 0 else 1.0
		var marker := _make_box("RoadMarker_%02d" % i, Vector3(0.18, 0.8, 0.18), Vector3(side * 6.0, 0.4, 12.0 - float(i) * 11.0), Color(0.88, 0.84, 0.72))
		add_child(marker)



func _build_oman_roadside_vegetation() -> void:
	for tree_index in range(6):
		var side := -1.0 if tree_index % 2 == 0 else 1.0
		var tree := Node3D.new()
		tree.name = "OmanDatePalm_%02d" % tree_index
		tree.position = Vector3(side * (12.0 + float(tree_index % 2) * 2.0), 0.0, 12.0 - float(tree_index) * 23.0)
		add_child(tree)
		var trunk := MeshInstance3D.new()
		trunk.name = "PalmTrunk"
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.17
		trunk_mesh.bottom_radius = 0.34
		trunk_mesh.height = 4.5
		trunk.mesh = trunk_mesh
		trunk.position.y = 2.25
		var trunk_material := StandardMaterial3D.new()
		trunk_material.albedo_color = Color(0.34, 0.21, 0.12)
		trunk.material_override = trunk_material
		tree.add_child(trunk)
		var leaf_material := StandardMaterial3D.new()
		leaf_material.albedo_color = Color(0.13, 0.31, 0.16)
		leaf_material.roughness = 0.9
		for leaf_index in range(8):
			var angle := TAU * float(leaf_index) / 8.0
			var leaf := MeshInstance3D.new()
			leaf.name = "PalmFrond_%d" % leaf_index
			var leaf_mesh := BoxMesh.new()
			leaf_mesh.size = Vector3(0.18, 0.12, 2.55)
			leaf.mesh = leaf_mesh
			leaf.position = Vector3(sin(angle) * 0.78, 4.25 - (0.12 if leaf_index % 2 == 0 else 0.0), cos(angle) * 0.78)
			leaf.rotation.y = angle
			leaf.rotation.x = -0.22
			leaf.material_override = leaf_material
			tree.add_child(leaf)
		var crown := MeshInstance3D.new()
		crown.name = "PalmCrown"
		var crown_mesh := SphereMesh.new()
		crown_mesh.radius = 0.34
		crown_mesh.height = 0.58
		crown.mesh = crown_mesh
		crown.position.y = 4.12
		crown.material_override = leaf_material
		tree.add_child(crown)

	for shrub_index in range(10):
		var side := -1.0 if shrub_index % 2 == 0 else 1.0
		var shrub := MeshInstance3D.new()
		shrub.name = "DesertShrub_%02d" % shrub_index
		var shrub_mesh := SphereMesh.new()
		shrub_mesh.radius = 0.65
		shrub_mesh.height = 0.72
		shrub.mesh = shrub_mesh
		shrub.scale = Vector3(1.3, 0.65, 0.9)
		shrub.position = Vector3(side * (8.0 + float(shrub_index % 3)), 0.25, 8.0 - float(shrub_index) * 13.0)
		var shrub_material := StandardMaterial3D.new()
		shrub_material.albedo_color = Color(0.34, 0.35, 0.19)
		shrub.material_override = shrub_material
		add_child(shrub)

func _build_roadside_signs() -> void:
	for i in range(3):
		var z_pos := -18.0 - float(i) * 34.0
		var side := -1.0 if i % 2 == 0 else 1.0
		var post := _make_box("RoadSignPost_%d" % i, Vector3(0.16, 2.7, 0.16), Vector3(side * 6.8, 1.35, z_pos), Color(0.72, 0.74, 0.76))
		add_child(post)
		var panel := _make_box("RoadSignPanel_%d" % i, Vector3(1.9, 1.0, 0.12), Vector3(side * 6.8, 2.55, z_pos), Color(0.03, 0.30, 0.22))
		add_child(panel)
		var sign_text := Label3D.new()
		sign_text.name = "RoadSignText_%d" % i
		sign_text.text = "OMAN\n" + ("MUSCAT" if i == 0 else ("NIZWA" if i == 1 else "SUR"))
		sign_text.position = Vector3(side * 6.8, 2.55, z_pos + 0.08)
		sign_text.font_size = 32
		sign_text.pixel_size = 0.012
		sign_text.modulate = Color.WHITE
		sign_text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(sign_text)

func _build_traffic_vehicle() -> void:
	_traffic_car = Node3D.new()
	_traffic_car.name = "OppositeDirectionTraffic"
	_traffic_car.position = Vector3(2.35, 0.0, -105.0)
	add_child(_traffic_car)
	var body := _make_box("TrafficSedanBody", Vector3(1.75, 0.72, 3.6), Vector3(0.0, 0.72, 0.0), Color(0.72, 0.12, 0.08))
	_traffic_car.add_child(body)
	var cabin := _make_box("TrafficSedanCabin", Vector3(1.48, 0.72, 1.75), Vector3(0.0, 1.38, -0.18), Color(0.12, 0.22, 0.29))
	_traffic_car.add_child(cabin)
	var tire_material := StandardMaterial3D.new()
	tire_material.albedo_color = Color(0.025, 0.025, 0.03)
	for x in [-0.9, 0.9]:
		for z in [-1.15, 1.15]:
			var tire := MeshInstance3D.new()
			var tire_mesh := CylinderMesh.new()
			tire_mesh.top_radius = 0.32
			tire_mesh.bottom_radius = 0.32
			tire_mesh.height = 0.18
			tire.mesh = tire_mesh
			tire.rotation_degrees.z = 90.0
			tire.position = Vector3(x, 0.38, z)
			tire.material_override = tire_material
			_traffic_car.add_child(tire)

func _make_box(node_name: String, dimensions: Vector3, location: Vector3, tint: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var box := BoxMesh.new()
	box.size = dimensions
	mesh_instance.mesh = box
	mesh_instance.position = location
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	mesh_instance.material_override = material
	return mesh_instance


func _build_cargo_depot() -> void:
	_cargo_depot = Node3D.new()
	_cargo_depot.name = "OmanCargoLoadingDepot"
	var pickup_z := (8.0 + ROUTE_TARGETS[_selected_route].z) * 0.5
	_cargo_depot.position = Vector3(10.5, 0.0, pickup_z)
	add_child(_cargo_depot)
	var warehouse := _make_box("DepotWarehouse", Vector3(8.0, 5.2, 11.0), Vector3(0.0, 2.6, -7.0), Color(0.72, 0.67, 0.56))
	_cargo_depot.add_child(warehouse)
	var roof := _make_box("DepotRoof", Vector3(8.6, 0.28, 11.6), Vector3(0.0, 5.25, -7.0), Color(0.16, 0.22, 0.27))
	_cargo_depot.add_child(roof)
	var loading_door := _make_box("LoadingBayDoor", Vector3(4.2, 3.5, 0.16), Vector3(0.0, 1.95, -1.42), Color(0.12, 0.18, 0.21))
	_cargo_depot.add_child(loading_door)
	var sign := Label3D.new()
	sign.name = "DepotSign"
	sign.text = "OMAN LOGISTICS\\nCARGO LOADING"
	sign.position = Vector3(0.0, 4.45, -1.28)
	sign.font_size = 30
	sign.pixel_size = 0.012
	sign.modulate = Color(0.95, 0.9, 0.72)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_cargo_depot.add_child(sign)
	for x in [-3.3, 3.3]:
		var pillar := _make_box("DepotCanopyPillar", Vector3(0.25, 3.5, 0.25), Vector3(x, 1.75, 2.0), Color(0.62, 0.65, 0.67))
		_cargo_depot.add_child(pillar)
	var canopy := _make_box("LoadingCanopy", Vector3(7.2, 0.22, 4.0), Vector3(0.0, 3.55, 2.0), Color(0.12, 0.28, 0.36))
	_cargo_depot.add_child(canopy)
	for pallet_index in range(3):
		var pallet_z := 3.0 + float(pallet_index) * 1.8
		var pallet := _make_box("CargoPallet_%d" % pallet_index, Vector3(1.55, 0.16, 1.35), Vector3(-2.1, 0.18, pallet_z), Color(0.36, 0.22, 0.12))
		_cargo_depot.add_child(pallet)
		for layer_index in range(2):
			var crate_color := Color(0.62, 0.38, 0.18) if pallet_index != 1 else Color(0.25, 0.48, 0.56)
			var crate := _make_box("CargoCrate_%d_%d" % [pallet_index, layer_index], Vector3(1.3, 0.72, 1.12), Vector3(-2.1, 0.62 + float(layer_index) * 0.74, pallet_z), crate_color)
			_cargo_depot.add_child(crate)
	var loading_marker := _make_box("DepotLoadingMarker", Vector3(5.5, 0.025, 2.2), Vector3(0.0, 0.07, 3.1), Color(0.9, 0.65, 0.12))
	_cargo_depot.add_child(loading_marker)
	_build_depot_forklift()


func _build_depot_forklift() -> void:
	var forklift := Node3D.new()
	forklift.name = "DepotForklift"
	forklift.position = Vector3(2.0, 0.0, 3.2)
	forklift.rotation.y = PI * 0.5
	_cargo_depot.add_child(forklift)
	var safety_yellow := Color(0.92, 0.62, 0.08)
	var dark_metal := Color(0.12, 0.15, 0.17)
	var chassis := _make_box("ForkliftChassis", Vector3(1.25, 0.48, 1.9), Vector3(0.0, 0.62, 0.0), safety_yellow)
	forklift.add_child(chassis)
	var counterweight := _make_box("ForkliftCounterweight", Vector3(1.3, 0.72, 0.58), Vector3(0.0, 0.9, 0.62), safety_yellow)
	forklift.add_child(counterweight)
	var seat := _make_box("ForkliftSeat", Vector3(0.58, 0.22, 0.55), Vector3(0.0, 1.05, -0.05), dark_metal)
	forklift.add_child(seat)
	var mast := _make_box("ForkliftMast", Vector3(0.12, 2.05, 0.18), Vector3(0.0, 1.35, -0.93), dark_metal)
	forklift.add_child(mast)
	var mast_rail_left := _make_box("ForkliftMastRailLeft", Vector3(0.12, 2.1, 0.14), Vector3(-0.48, 1.38, -0.93), dark_metal)
	var mast_rail_right := _make_box("ForkliftMastRailRight", Vector3(0.12, 2.1, 0.14), Vector3(0.48, 1.38, -0.93), dark_metal)
	forklift.add_child(mast_rail_left)
	forklift.add_child(mast_rail_right)
	_forklift_carriage = Node3D.new()
	_forklift_carriage.name = "ForkliftMovingCarriage"
	_forklift_carriage.position = Vector3(0.0, 0.48, -0.93)
	forklift.add_child(_forklift_carriage)
	var carriage_bar := _make_box("ForkliftCarriageBar", Vector3(1.05, 0.16, 0.16), Vector3(0.0, 0.0, 0.0), dark_metal)
	_forklift_carriage.add_child(carriage_bar)
	var fork_left := _make_box("ForkliftForkLeft", Vector3(0.16, 0.12, 1.35), Vector3(-0.36, -0.12, -0.62), Color(0.65, 0.68, 0.7))
	var fork_right := _make_box("ForkliftForkRight", Vector3(0.16, 0.12, 1.35), Vector3(0.36, -0.12, -0.62), Color(0.65, 0.68, 0.7))
	_forklift_carriage.add_child(fork_left)
	_forklift_carriage.add_child(fork_right)
	for x in [-0.68, 0.68]:
		for z in [-0.58, 0.62]:
			var wheel := MeshInstance3D.new()
			wheel.name = "ForkliftWheel"
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.31
			wheel_mesh.bottom_radius = 0.31
			wheel_mesh.height = 0.2
			wheel.mesh = wheel_mesh
			wheel.rotation.z = PI * 0.5
			wheel.position = Vector3(x, 0.34, z)
			var rubber := StandardMaterial3D.new()
			rubber.albedo_color = Color(0.025, 0.027, 0.03)
			wheel.material_override = rubber
			forklift.add_child(wheel)
	for x in [-0.62, 0.62]:
		var guard_post := _make_box("ForkliftOverheadGuardPost", Vector3(0.1, 1.45, 0.1), Vector3(x, 1.55, 0.28), dark_metal)
		forklift.add_child(guard_post)
	var guard_roof := _make_box("ForkliftOverheadGuardRoof", Vector3(1.45, 0.12, 1.45), Vector3(0.0, 2.3, 0.28), dark_metal)
	forklift.add_child(guard_roof)
	var beacon := MeshInstance3D.new()
	beacon.name = "ForkliftAmberBeacon"
	var beacon_mesh := CylinderMesh.new()
	beacon_mesh.top_radius = 0.13
	beacon_mesh.bottom_radius = 0.13
	beacon_mesh.height = 0.2
	beacon.mesh = beacon_mesh
	beacon.position = Vector3(0.0, 2.48, 0.28)
	var beacon_material := StandardMaterial3D.new()
	beacon_material.albedo_color = Color(1.0, 0.48, 0.04)
	beacon_material.emission_enabled = true
	beacon_material.emission = Color(1.0, 0.32, 0.015)
	beacon.material_override = beacon_material
	forklift.add_child(beacon)
	_forklift_beacon = OmniLight3D.new()
	_forklift_beacon.name = "ForkliftBeaconLight"
	_forklift_beacon.light_color = Color(1.0, 0.42, 0.06)
	_forklift_beacon.light_energy = 0.8
	_forklift_beacon.omni_range = 3.5
	_forklift_beacon.position = Vector3(0.0, 2.5, 0.28)
	forklift.add_child(_forklift_beacon)

func _build_mission() -> void:
	_checkpoint_area = Area3D.new()
	_checkpoint_area.name = "DeliveryCheckpoint"
	_checkpoint_area.position = _mission_target
	var trigger := CollisionShape3D.new()
	var trigger_shape := BoxShape3D.new()
	trigger_shape.size = Vector3(8.0, 4.0, 5.0)
	trigger.shape = trigger_shape
	trigger.position.y = 1.5
	_checkpoint_area.add_child(trigger)
	_checkpoint_area.body_entered.connect(_on_checkpoint_entered)
	add_child(_checkpoint_area)

	var gate_material := StandardMaterial3D.new()
	gate_material.albedo_color = Color(0.05, 0.55, 0.34)
	var left_post := _make_box("CheckpointLeftPost", Vector3(0.22, 3.2, 0.22), Vector3(-4.0, 1.6, _mission_target.z), gate_material.albedo_color)
	var right_post := _make_box("CheckpointRightPost", Vector3(0.22, 3.2, 0.22), Vector3(4.0, 1.6, _mission_target.z), gate_material.albedo_color)
	var top_bar := _make_box("CheckpointTopBar", Vector3(8.2, 0.22, 0.22), Vector3(0.0, 3.1, _mission_target.z), gate_material.albedo_color)
	_checkpoint_gate_parts = [left_post, right_post, top_bar]
	_checkpoint_label = Label3D.new()
	_checkpoint_label.name = "CheckpointSign"
	_checkpoint_label.position = Vector3(0.0, 3.75, _mission_target.z)
	_checkpoint_label.text = "DELIVERY"
	_checkpoint_label.font_size = 40
	_checkpoint_label.pixel_size = 0.01
	_checkpoint_label.modulate = Color(0.85, 1.0, 0.9)
	_checkpoint_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_checkpoint_label)
	add_child(left_post)
	add_child(right_post)
	add_child(top_bar)

func _build_mission_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
	_cargo_button = Button.new()
	_cargo_button.name = "CargoSelector"
	_cargo_button.text = "CARGO: " + CARGO_NAMES[_selected_cargo]
	_cargo_button.position = Vector2(24.0, 78.0)
	_cargo_button.custom_minimum_size = Vector2(250.0, 48.0)
	_cargo_button.add_theme_font_size_override("font_size", 16)
	_cargo_button.pressed.connect(_cycle_cargo)
	layer.add_child(_cargo_button)

	_mission_type_button = Button.new()
	_mission_type_button.name = "MissionTypeSelector"
	_mission_type_button.text = "JOB: PASSENGER" if _passenger_mode else "JOB: CARGO"
	_mission_type_button.position = Vector2(24.0, 134.0)
	_mission_type_button.custom_minimum_size = Vector2(250.0, 48.0)
	_mission_type_button.add_theme_font_size_override("font_size", 16)
	_mission_type_button.pressed.connect(_toggle_passenger_mode)
	layer.add_child(_mission_type_button)
	_cargo_button.visible = not _passenger_mode

	_route_button = Button.new()
	_route_button.name = "RouteSelector"
	_route_button.text = "ROUTE: " + ROUTE_NAMES[_selected_route]
	_route_button.position = Vector2(24.0, 22.0)
	_route_button.custom_minimum_size = Vector2(250.0, 48.0)
	_route_button.add_theme_font_size_override("font_size", 16)
	_route_button.pressed.connect(_cycle_route)
	layer.add_child(_route_button)


	var company_button := Button.new()
	company_button.name = "TransportCompany"
	company_button.text = "MY TRANSPORT COMPANY"
	company_button.anchor_left = 1.0
	company_button.anchor_right = 1.0
	company_button.offset_left = -224.0
	company_button.offset_right = -20.0
	company_button.offset_top = 204.0
	company_button.offset_bottom = 252.0
	company_button.add_theme_font_size_override("font_size", 15)
	company_button.pressed.connect(_toggle_company_panel)
	layer.add_child(company_button)

	_cash_label = Label.new()
	_cash_label.name = "CashBalance"
	_cash_label.text = "WALLET  |  OMR %d  |  DELIVERIES %d" % [_cash_balance, _delivery_count]
	_cash_label.position = Vector2(24.0, 190.0)
	_cash_label.add_theme_font_size_override("font_size", 20)
	_cash_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.72))
	layer.add_child(_cash_label)

	_passenger_status_label = Label.new()
	_passenger_status_label.name = "PassengerManifest"
	_passenger_status_label.text = "PASSENGERS ON BOARD: 0"
	_passenger_status_label.position = Vector2(24.0, 222.0)
	_passenger_status_label.add_theme_font_size_override("font_size", 18)
	_passenger_status_label.add_theme_color_override("font_color", Color(0.72, 0.88, 1.0))
	_passenger_status_label.visible = _passenger_mode
	layer.add_child(_passenger_status_label)

	_cargo_status_label = Label.new()
	_cargo_status_label.name = "CargoManifest"
	_cargo_status_label.text = "CARGO STATUS: WAITING FOR LOAD"
	_cargo_status_label.position = Vector2(24.0, 222.0)
	_cargo_status_label.add_theme_font_size_override("font_size", 18)
	_cargo_status_label.add_theme_color_override("font_color", Color(1.0, 0.83, 0.58))
	_cargo_status_label.visible = not _passenger_mode
	layer.add_child(_cargo_status_label)

	_mission_label = Label.new()
	_mission_label.name = "MissionStatus"
	_mission_label.text = "DELIVERY RUN  |  CHECKPOINT: 000 m"
	_mission_label.anchor_left = 0.5
	_mission_label.anchor_right = 0.5
	_mission_label.offset_left = -190.0
	_mission_label.offset_right = 190.0
	_mission_label.offset_top = 76.0
	_mission_label.offset_bottom = 112.0
	_mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mission_label.add_theme_font_size_override("font_size", 18)
	_mission_label.add_theme_color_override("font_color", Color.WHITE)
	layer.add_child(_mission_label)

	_restart_button = Button.new()
	_restart_button.name = "RestartDelivery"
	_restart_button.text = "RESTART ROUTE"
	_restart_button.anchor_left = 1.0
	_restart_button.anchor_right = 1.0
	_restart_button.offset_left = -190.0
	_restart_button.offset_right = -20.0
	_restart_button.offset_top = 88.0
	_restart_button.offset_bottom = 136.0
	_restart_button.add_theme_font_size_override("font_size", 16)
	_restart_button.pressed.connect(_restart_delivery)
	layer.add_child(_restart_button)


func _build_company_management() -> void:
	_company_trip_timer = Timer.new()
	_company_trip_timer.name = "CompanyDriverTripTimer"
	_company_trip_timer.one_shot = true
	_company_trip_timer.wait_time = 45.0
	_company_trip_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_company_trip_timer.timeout.connect(_on_company_driver_trip_completed)
	add_child(_company_trip_timer)

	var layer := CanvasLayer.new()
	layer.name = "CompanyManagementLayer"
	layer.layer = 30
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	_company_panel = ColorRect.new()
	_company_panel.name = "CompanyManagementOverlay"
	_company_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_company_panel.color = Color(0.015, 0.035, 0.06, 0.94)
	_company_panel.visible = false
	layer.add_child(_company_panel)

	var panel := PanelContainer.new()
	panel.name = "CompanyManagementPanel"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -260.0
	panel.offset_top = -245.0
	panel.offset_right = 260.0
	panel.offset_bottom = 245.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.075, 0.11, 1.0)
	panel_style.border_color = Color(0.12, 0.58, 0.78, 1.0)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(16)
	panel.add_theme_stylebox_override("panel", panel_style)
	_company_panel.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	var heading := Label.new()
	heading.text = "TRANSPORT COMPANY"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 25)
	heading.add_theme_color_override("font_color", Color(0.35, 0.82, 1.0))
	content.add_child(heading)

	_company_name_edit = LineEdit.new()
	_company_name_edit.placeholder_text = "Enter your company name"
	_company_name_edit.text = _company_name
	_company_name_edit.max_length = 28
	_company_name_edit.text_submitted.connect(_on_company_name_submitted)
	content.add_child(_company_name_edit)

	_company_summary_label = Label.new()
	_company_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_company_summary_label.add_theme_font_size_override("font_size", 17)
	content.add_child(_company_summary_label)

	_company_status_label = Label.new()
	_company_status_label.text = "Your company is ready to operate."
	_company_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_company_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_company_status_label.add_theme_color_override("font_color", Color(0.65, 0.85, 0.92))
	content.add_child(_company_status_label)

	var hire_button := Button.new()
	hire_button.text = "HIRE DRIVER  |  OMR 80"
	hire_button.custom_minimum_size.y = 48
	hire_button.pressed.connect(_hire_company_driver)
	content.add_child(hire_button)

	var bus_button := Button.new()
	bus_button.text = "BUY ADDITIONAL BUS  |  OMR 450"
	bus_button.custom_minimum_size.y = 48
	bus_button.pressed.connect(_buy_company_bus)
	content.add_child(bus_button)

	_company_dispatch_button = Button.new()
	_company_dispatch_button.text = "ASSIGN DRIVER & SEND TO WORK"
	_company_dispatch_button.custom_minimum_size.y = 52
	_company_dispatch_button.pressed.connect(_dispatch_company_driver)
	content.add_child(_company_dispatch_button)

	var close_button := Button.new()
	close_button.text = "CLOSE"
	close_button.custom_minimum_size.y = 44
	close_button.pressed.connect(_toggle_company_panel)
	content.add_child(close_button)
	_refresh_company_panel()

func _toggle_company_panel() -> void:
	if not is_instance_valid(_company_panel):
		return
	_company_panel.visible = not _company_panel.visible
	if _company_panel.visible:
		_refresh_company_panel()

func _on_company_name_submitted(value: String) -> void:
	var cleaned := value.strip_edges()
	if not cleaned.is_empty():
		_company_name = cleaned
	_save_progress()
	_refresh_company_panel()

func _hire_company_driver() -> void:
	if _company_funds < 80:
		_company_status_label.text = "Not enough company funds. You need OMR 80 to hire a driver."
		return
	_company_funds -= 80
	_company_driver_count += 1
	_company_status_label.text = "Driver hired. Assign a bus and send your driver to work."
	_save_progress()
	_refresh_company_panel()

func _buy_company_bus() -> void:
	if _company_funds < 450:
		_company_status_label.text = "Not enough company funds. You need OMR 450 for another bus."
		return
	_company_funds -= 450
	_company_bus_count += 1
	_company_status_label.text = "Bus purchased and added to your company fleet."
	_save_progress()
	_refresh_company_panel()

func _dispatch_company_driver() -> void:
	if _company_trip_active:
		_company_status_label.text = "A company driver is already completing a route."
		return
	if _company_driver_count < 1 or _company_bus_count < 1:
		_company_status_label.text = "You need at least one hired driver and one company bus."
		return
	if _company_funds < 35:
		_company_status_label.text = "Your company needs OMR 35 available for trip fuel and driver costs."
		return
	_company_funds -= 35
	_company_trip_active = true
	_company_trip_timer.start()
	_company_status_label.text = "Driver dispatched on %s. You can keep driving your own vehicle." % ROUTE_NAMES[_selected_route]
	_refresh_company_panel()
	_save_progress()

func _on_company_driver_trip_completed() -> void:
	_company_trip_active = false
	_company_completed_trips += 1
	# Illustrative game-economy figures: OMR 85 fare revenue, less OMR 20 fuel
	# and OMR 15 driver pay. OMR 15 operating cost was reserved at dispatch.
	_company_funds += 50
	_company_status_label.text = "Company driver completed the route. Net company profit: OMR 50."
	_refresh_company_panel()
	_save_progress()

func _refresh_company_panel() -> void:
	if is_instance_valid(_company_summary_label):
		_company_summary_label.text = "%s\nCOMPANY FUNDS: OMR %d\nBUSES: %d     DRIVERS: %d\nCOMPLETED COMPANY TRIPS: %d" % [_company_name, _company_funds, _company_bus_count, _company_driver_count, _company_completed_trips]
	if is_instance_valid(_company_dispatch_button):
		_company_dispatch_button.disabled = _company_trip_active or _company_driver_count < 1 or _company_bus_count < 1 or _company_funds < 35
		_company_dispatch_button.text = "DRIVER EN ROUTE..." if _company_trip_active else "ASSIGN DRIVER & SEND TO WORK"

func _restart_delivery() -> void:
	_set_paused(false)
	_spawn_vehicle()

func _build_pause_menu() -> void:
	var layer := CanvasLayer.new()
	layer.name = "PauseMenuLayer"
	layer.layer = 20
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_pause_button = Button.new()
	_pause_button.name = "PauseButton"
	_pause_button.text = "PAUSE"
	_pause_button.anchor_left = 1.0
	_pause_button.anchor_right = 1.0
	_pause_button.offset_left = -112.0
	_pause_button.offset_right = -20.0
	_pause_button.offset_top = 146.0
	_pause_button.offset_bottom = 192.0
	_pause_button.add_theme_font_size_override("font_size", 16)
	_pause_button.pressed.connect(_set_paused.bind(true))
	layer.add_child(_pause_button)

	_pause_overlay = Control.new()
	_pause_overlay.name = "PauseOverlay"
	_pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_overlay.visible = false
	_pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(_pause_overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.035, 0.06, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.add_child(shade)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.06
	panel.anchor_top = 0.08
	panel.anchor_right = 0.94
	panel.anchor_bottom = 0.92
	panel.offset_left = 0.0
	panel.offset_top = 0.0
	panel.offset_right = 0.0
	panel.offset_bottom = 0.0
	_pause_overlay.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	var heading := Label.new()
	heading.text = "ZAYRON SIMULATOR"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 24)
	column.add_child(heading)
	var subtitle := Label.new()
	subtitle.text = "PAUSED  |  SETTINGS"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle)
	var volume_label := Label.new()
	volume_label.text = "MASTER VOLUME"
	column.add_child(volume_label)
	_audio_slider = HSlider.new()
	_audio_slider.min_value = 0.0
	_audio_slider.max_value = 1.0
	_audio_slider.step = 0.05
	_audio_slider.value = _master_volume
	_audio_slider.custom_minimum_size = Vector2(220.0, 40.0)
	_audio_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_audio_slider.value_changed.connect(_on_master_volume_changed)
	column.add_child(_audio_slider)
	var steering_label := Label.new()
	steering_label.text = "STEERING SENSITIVITY"
	column.add_child(steering_label)
	_steering_slider = HSlider.new()
	_steering_slider.min_value = 0.5
	_steering_slider.max_value = 1.8
	_steering_slider.step = 0.05
	_steering_slider.value = _steering_sensitivity
	_steering_slider.custom_minimum_size = Vector2(220.0, 40.0)
	_steering_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_steering_slider.value_changed.connect(_on_steering_sensitivity_changed)
	column.add_child(_steering_slider)
	var resume := Button.new()
	resume.text = "RESUME DRIVING"
	resume.custom_minimum_size = Vector2(220.0, 52.0)
	resume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resume.pressed.connect(_set_paused.bind(false))
	column.add_child(resume)
	var restart := Button.new()
	restart.text = "RESTART ROUTE"
	restart.custom_minimum_size = Vector2(220.0, 52.0)
	restart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restart.pressed.connect(_restart_delivery)
	column.add_child(restart)

func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	if is_instance_valid(_pause_overlay):
		_pause_overlay.visible = paused
	if is_instance_valid(_pause_button):
		_pause_button.visible = not paused

func _on_master_volume_changed(value: float) -> void:
	_master_volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(_master_volume, 0.001)))
	_save_progress()

func _on_steering_sensitivity_changed(value: float) -> void:
	_steering_sensitivity = clampf(value, 0.5, 1.8)
	_apply_vehicle_settings()
	_save_progress()

func _cycle_route() -> void:
	_selected_route = (_selected_route + 1) % ROUTE_TARGETS.size()
	if is_instance_valid(_route_button):
		_route_button.text = "ROUTE: " + ROUTE_NAMES[_selected_route]
	_spawn_vehicle()
	_save_progress()

func _move_checkpoint_gate() -> void:
	for i in range(_checkpoint_gate_parts.size()):
		var gate_part := _checkpoint_gate_parts[i]
		if not is_instance_valid(gate_part):
			continue
		if i == 0:
			gate_part.position = Vector3(-4.0, 1.6, _mission_target.z)
		elif i == 1:
			gate_part.position = Vector3(4.0, 1.6, _mission_target.z)
		else:
			gate_part.position = Vector3(0.0, 3.1, _mission_target.z)
	if is_instance_valid(_checkpoint_label):
		_checkpoint_label.position.z = _mission_target.z
		if _passenger_mode:
			_checkpoint_label.text = "PICKUP" if not _passenger_pickup_done else "DROP-OFF"
		else:
			_checkpoint_label.text = "LOAD CARGO" if not _cargo_pickup_done else "DELIVER CARGO"

func _toggle_passenger_mode() -> void:
	_passenger_mode = not _passenger_mode
	if _passenger_mode and _selected_vehicle < 3:
		_selected_vehicle = 3
	if is_instance_valid(_mission_type_button):
		_mission_type_button.text = "JOB: PASSENGER" if _passenger_mode else "JOB: CARGO"
	if is_instance_valid(_cargo_button):
		_cargo_button.visible = not _passenger_mode
	if is_instance_valid(_passenger_status_label):
		_passenger_status_label.visible = _passenger_mode
		_passenger_status_label.text = "PASSENGERS ON BOARD: 0"
	if is_instance_valid(_cargo_status_label):
		_cargo_status_label.visible = not _passenger_mode
		_cargo_status_label.text = "CARGO STATUS: WAITING FOR LOAD"
	_spawn_vehicle()
	_save_progress()

func _cycle_cargo() -> void:
	_selected_cargo = (_selected_cargo + 1) % CARGO_NAMES.size()
	if is_instance_valid(_cargo_button):
		_cargo_button.text = "CARGO: " + CARGO_NAMES[_selected_cargo]
	_save_progress()

func _on_checkpoint_entered(body: Node3D) -> void:
	if body != _active_vehicle or _mission_complete:
		return
	if _passenger_mode and not _passenger_pickup_done:
		_passenger_pickup_done = true
		if is_instance_valid(_passenger_status_label):
			_passenger_status_label.text = "PASSENGERS ON BOARD: %d" % PASSENGER_GROUP_SIZE
		_mission_target = ROUTE_TARGETS[_selected_route]
		if is_instance_valid(_checkpoint_area):
			_checkpoint_area.position = _mission_target
		_move_checkpoint_gate()
		if is_instance_valid(_mission_label):
			_mission_label.text = "PASSENGERS ON BOARD  |  CONTINUE TO " + ROUTE_NAMES[_selected_route].split(" -> ")[1]
		return
	if not _passenger_mode and not _cargo_pickup_done:
		_cargo_pickup_done = true
		_sync_vehicle_cargo_payload()
		if is_instance_valid(_cargo_status_label):
			_cargo_status_label.text = "CARGO LOADED: " + CARGO_NAMES[_selected_cargo]
		if is_instance_valid(_cargo_depot):
			_cargo_depot.visible = false
		_mission_target = ROUTE_TARGETS[_selected_route]
		if is_instance_valid(_checkpoint_area):
			_checkpoint_area.position = _mission_target
		_move_checkpoint_gate()
		if is_instance_valid(_mission_label):
			_mission_label.text = "CARGO LOADED  |  CONTINUE TO " + ROUTE_NAMES[_selected_route].split(" -> ")[1]
		return
	_mission_complete = true
	if _passenger_mode and is_instance_valid(_passenger_status_label):
		_passenger_status_label.text = "PASSENGERS ON BOARD: 0"
	if not _passenger_mode and is_instance_valid(_cargo_status_label):
		_cargo_status_label.text = "CARGO DELIVERED: " + CARGO_NAMES[_selected_cargo]
	_delivery_count += 1
	_cash_balance += PASSENGER_TRIP_REWARD if _passenger_mode else CARGO_REWARDS[_selected_cargo]
	if is_instance_valid(_cash_label):
		_cash_label.text = "WALLET  |  OMR %d  |  DELIVERIES %d" % [_cash_balance, _delivery_count]
	_save_progress()
	if is_instance_valid(_mission_label):
		if _passenger_mode:
			_mission_label.text = "%s COMPLETE  |  PASSENGERS DELIVERED  |  +%d OMR" % [ROUTE_NAMES[_selected_route], PASSENGER_TRIP_REWARD]
		else:
			_mission_label.text = "%s COMPLETE  |  %s  |  +%d OMR" % [ROUTE_NAMES[_selected_route], CARGO_NAMES[_selected_cargo], CARGO_REWARDS[_selected_cargo]]


func _load_progress() -> void:
	var progress := ConfigFile.new()
	if progress.load(SAVE_PATH) != OK:
		return
	_delivery_count = int(progress.get_value("career", "deliveries", 0))
	_cash_balance = int(progress.get_value("career", "wallet_omr", 0))
	_selected_vehicle = clampi(int(progress.get_value("career", "selected_vehicle", 0)), 0, FLEET_SCENES.size() - 1)
	_selected_route = clampi(int(progress.get_value("career", "selected_route", 0)), 0, ROUTE_TARGETS.size() - 1)
	_selected_cargo = clampi(int(progress.get_value("career", "selected_cargo", 0)), 0, CARGO_NAMES.size() - 1)
	_passenger_mode = bool(progress.get_value("career", "passenger_mode", false))
	_company_name = str(progress.get_value("company", "name", _company_name))
	_company_funds = maxi(0, int(progress.get_value("company", "funds_omr", _company_funds)))
	_company_bus_count = maxi(1, int(progress.get_value("company", "buses", _company_bus_count)))
	_company_driver_count = maxi(0, int(progress.get_value("company", "drivers", _company_driver_count)))
	_company_completed_trips = maxi(0, int(progress.get_value("company", "completed_trips", _company_completed_trips)))
	_steering_sensitivity = clampf(float(progress.get_value("settings", "steering_sensitivity", 1.0)), 0.5, 1.8)
	_master_volume = clampf(float(progress.get_value("settings", "master_volume", 1.0)), 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(_master_volume, 0.001)))
	if _passenger_mode and _selected_vehicle < 3:
		_selected_vehicle = 3

func _save_progress() -> void:
	var progress := ConfigFile.new()
	progress.set_value("career", "deliveries", _delivery_count)
	progress.set_value("career", "wallet_omr", _cash_balance)
	progress.set_value("career", "selected_vehicle", _selected_vehicle)
	progress.set_value("career", "selected_route", _selected_route)
	progress.set_value("career", "selected_cargo", _selected_cargo)
	progress.set_value("career", "passenger_mode", _passenger_mode)
	progress.set_value("company", "name", _company_name)
	progress.set_value("company", "funds_omr", _company_funds)
	progress.set_value("company", "buses", _company_bus_count)
	progress.set_value("company", "drivers", _company_driver_count)
	progress.set_value("company", "completed_trips", _company_completed_trips)
	progress.set_value("settings", "steering_sensitivity", _steering_sensitivity)
	progress.set_value("settings", "master_volume", _master_volume)
	var save_error := progress.save(SAVE_PATH)
	if save_error != OK:
		push_warning("Could not save Zayron Simulator progress. Error: %s" % save_error)
