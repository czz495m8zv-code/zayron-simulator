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

func _ready() -> void:
	_load_progress()
	_mission_target = ROUTE_TARGETS[_selected_route]
	_passenger_pickup_target = Vector3(0.0, 0.0, (8.0 + _mission_target.z) * 0.5)
	if _passenger_mode:
		_mission_target = _passenger_pickup_target
	_build_environment()
	_build_oman_test_road()
	_build_roadside_signs()
	_build_traffic_vehicle()
	_build_mission()
	_spawn_vehicle()
	_build_vehicle_selector()
	_build_mission_hud()

func _process(delta: float) -> void:
	if is_instance_valid(_traffic_car):
		_traffic_car.position.z += _traffic_speed * delta
		if _traffic_car.position.z > 24.0:
			_traffic_car.position.z = -118.0
	if not is_instance_valid(_mission_label) or _mission_complete or not is_instance_valid(_active_vehicle):
		return
	var distance := Vector2(_active_vehicle.global_position.x - _mission_target.x, _active_vehicle.global_position.z - _mission_target.z).length()
	_mission_label.text = "%s  |  CHECKPOINT: %d m" % [ROUTE_NAMES[_selected_route], int(distance)]

func _spawn_vehicle() -> void:
	_mission_complete = false
	_passenger_pickup_done = false
	if _passenger_mode:
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
	if is_instance_valid(_vehicle_button):
		_vehicle_button.text = "NEXT: " + FLEET_NAMES[(_selected_vehicle + 1) % FLEET_NAMES.size()]
	if is_instance_valid(_mission_label):
		_mission_label.text = "%s  |  CHECKPOINT: 000 m" % ROUTE_NAMES[_selected_route]

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

	_cash_label = Label.new()
	_cash_label.name = "CashBalance"
	_cash_label.text = "WALLET  |  OMR %d  |  DELIVERIES %d" % [_cash_balance, _delivery_count]
	_cash_label.position = Vector2(24.0, 190.0)
	_cash_label.add_theme_font_size_override("font_size", 20)
	_cash_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.72))
	layer.add_child(_cash_label)

	_mission_label = Label.new()
	_mission_label.name = "MissionStatus"
	_mission_label.text = "DELIVERY RUN  |  CHECKPOINT: 000 m"
	_mission_label.anchor_left = 0.5
	_mission_label.anchor_right = 0.5
	_mission_label.offset_left = -190.0
	_mission_label.offset_right = 190.0
	_mission_label.offset_top = 22.0
	_mission_label.offset_bottom = 58.0
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

func _restart_delivery() -> void:
	_spawn_vehicle()

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

func _toggle_passenger_mode() -> void:
	_passenger_mode = not _passenger_mode
	if _passenger_mode and _selected_vehicle < 3:
		_selected_vehicle = 3
	if is_instance_valid(_mission_type_button):
		_mission_type_button.text = "JOB: PASSENGER" if _passenger_mode else "JOB: CARGO"
	if is_instance_valid(_cargo_button):
		_cargo_button.visible = not _passenger_mode
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
		_mission_target = ROUTE_TARGETS[_selected_route]
		if is_instance_valid(_checkpoint_area):
			_checkpoint_area.position = _mission_target
		_move_checkpoint_gate()
		if is_instance_valid(_mission_label):
			_mission_label.text = "PASSENGERS ON BOARD  |  CONTINUE TO " + ROUTE_NAMES[_selected_route].split(" -> ")[1]
		return
	_mission_complete = true
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
	var save_error := progress.save(SAVE_PATH)
	if save_error != OK:
		push_warning("Could not save Zayron Simulator progress. Error: %s" % save_error)
