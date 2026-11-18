extends Node3D

const TRUCK_SCENE: PackedScene = preload("res://scenes/vehicles/prototype_truck.tscn")

func _ready() -> void:
	_build_environment()
	_build_oman_test_road()
	var truck := TRUCK_SCENE.instantiate()
	truck.position = Vector3(0.0, 0.15, 8.0)
	add_child(truck)

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

	# Broken white centre line, like a simple two-way test road.
	for i in range(15):
		var dash := _make_box("CentreLine_%02d" % i, Vector3(0.14, 0.025, 3.2), Vector3(0.0, 0.105, 18.0 - float(i) * 8.5), Color(0.92, 0.91, 0.82))
		add_child(dash)

	# Simple low-poly rocky hills frame the first Oman-inspired test route.
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

	# Sparse roadside markers.
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
