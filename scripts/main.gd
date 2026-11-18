extends Node3D

const TRUCK_SCENE: PackedScene = preload("res://scenes/vehicles/prototype_truck.tscn")
const BUS_SCENE: PackedScene = preload("res://scenes/vehicles/prototype_bus.tscn")

var _active_vehicle: Node3D
var _using_bus: bool = false
var _vehicle_button: Button
var _mission_label: Label
var _mission_complete: bool = false
var _mission_target := Vector3(0.0, 0.0, -82.0)

func _ready() -> void:
	_build_environment()
	_build_oman_test_road()
	_build_mission()
	_spawn_vehicle()
	_build_vehicle_selector()
	_build_mission_hud()

func _process(_delta: float) -> void:
	if not is_instance_valid(_mission_label) or _mission_complete or not is_instance_valid(_active_vehicle):
		return
	var distance := Vector2(_active_vehicle.global_position.x - _mission_target.x, _active_vehicle.global_position.z - _mission_target.z).length()
	_mission_label.text = "DELIVERY RUN  |  CHECKPOINT: %d m" % int(distance)

func _spawn_vehicle() -> void:
	if is_instance_valid(_active_vehicle):
		_active_vehicle.queue_free()
	_active_vehicle = (BUS_SCENE if _using_bus else TRUCK_SCENE).instantiate()
	_active_vehicle.position = Vector3(0.0, 0.15, 8.0)
	add_child(_active_vehicle)
	if is_instance_valid(_vehicle_button):
		_vehicle_button.text = "BUS" if not _using_bus else "TRUCK"

func _build_vehicle_selector() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var button := Button.new()
	button.name = "VehicleSelector"
	button.text = "BUS"
	button.custom_minimum_size = Vector2(112.0, 54.0)
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.anchor_top = 0.0
	button.anchor_bottom = 0.0
	button.offset_left = -136.0
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
	_using_bus = not _using_bus
	_spawn_vehicle()

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
	var checkpoint := Area3D.new()
	checkpoint.name = "DeliveryCheckpoint"
	checkpoint.position = _mission_target
	var trigger := CollisionShape3D.new()
	var trigger_shape := BoxShape3D.new()
	trigger_shape.size = Vector3(8.0, 4.0, 5.0)
	trigger.shape = trigger_shape
	trigger.position.y = 1.5
	checkpoint.add_child(trigger)
	checkpoint.body_entered.connect(_on_checkpoint_entered)
	add_child(checkpoint)

	var gate_material := StandardMaterial3D.new()
	gate_material.albedo_color = Color(0.05, 0.55, 0.34)
	var left_post := _make_box("CheckpointLeftPost", Vector3(0.22, 3.2, 0.22), Vector3(-4.0, 1.6, _mission_target.z), gate_material.albedo_color)
	var right_post := _make_box("CheckpointRightPost", Vector3(0.22, 3.2, 0.22), Vector3(4.0, 1.6, _mission_target.z), gate_material.albedo_color)
	var top_bar := _make_box("CheckpointTopBar", Vector3(8.2, 0.22, 0.22), Vector3(0.0, 3.1, _mission_target.z), gate_material.albedo_color)
	add_child(left_post)
	add_child(right_post)
	add_child(top_bar)

func _build_mission_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
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

func _on_checkpoint_entered(body: Node3D) -> void:
	if body != _active_vehicle or _mission_complete:
		return
	_mission_complete = true
	if is_instance_valid(_mission_label):
		_mission_label.text = "DELIVERY COMPLETE  |  WELL DONE!"
