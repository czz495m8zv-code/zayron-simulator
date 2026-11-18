extends Node3D

const TRUCK_SCENE: PackedScene = preload("res://scenes/vehicles/prototype_truck.tscn")

func _ready() -> void:
	_build_environment()
	var truck := TRUCK_SCENE.instantiate()
	truck.position = Vector3(0.0, 1.0, 0.0)
	add_child(truck)

func _build_environment() -> void:
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	add_child(ground)

	var ground_mesh := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(100.0, 1.0, 100.0)
	ground_mesh.mesh = plane
	ground_mesh.position.y = -0.5
	ground.add_child(ground_mesh)

	var ground_collision := CollisionShape3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = plane.size
	ground_collision.shape = ground_shape
	ground_collision.position.y = -0.5
	ground.add_child(ground_collision)

	var road := MeshInstance3D.new()
	var road_mesh := BoxMesh.new()
	road_mesh.size = Vector3(9.0, 0.08, 100.0)
	road.mesh = road_mesh
	road.position = Vector3(0.0, 0.05, -10.0)
	var road_material := StandardMaterial3D.new()
	road_material.albedo_color = Color(0.12, 0.13, 0.15)
	road.material_override = road_material
	add_child(road)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
