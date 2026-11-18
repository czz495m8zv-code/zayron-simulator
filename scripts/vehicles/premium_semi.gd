extends "res://scripts/vehicles/prototype_truck.gd"

@export var cab_paint: Color = Color(0.04, 0.24, 0.38)
@export var trailer_paint: Color = Color(0.78, 0.8, 0.82)
@export var trim_paint: Color = Color(0.82, 0.65, 0.28)

func _build_truck() -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.55, 3.0, 7.2)
	collision.shape = shape
	collision.position = Vector3(0.0, 1.5, 1.0)
	add_child(collision)
	_add_box("Chassis", Vector3(2.25, 0.55, 7.6), Vector3(0.0, 0.75, 1.0), Color(0.08, 0.09, 0.1))
	_add_box("PremiumCab", Vector3(2.5, 2.9, 2.8), Vector3(0.0, 2.0, -1.75), cab_paint)
	_add_box("CabRoof", Vector3(2.45, 0.18, 2.7), Vector3(0.0, 3.48, -1.75), trim_paint)
	_add_box("WideWindscreen", Vector3(2.12, 1.0, 0.06), Vector3(0.0, 2.65, -3.17), Color(0.06, 0.17, 0.24))
	_add_box("Trailer", Vector3(2.55, 3.65, 8.4), Vector3(0.0, 2.35, 5.9), trailer_paint)
	_add_box("TrailerTopTrim", Vector3(2.58, 0.12, 8.42), Vector3(0.0, 4.22, 5.9), trim_paint)
	_add_box("TrailerLowerTrim", Vector3(2.59, 0.16, 8.42), Vector3(0.0, 0.55, 5.9), cab_paint)
	for side in [-1.0, 1.0]:
		_add_box("CabSideGlass_%s" % side, Vector3(0.05, 0.9, 1.05), Vector3(side * 1.27, 2.65, -1.8), Color(0.06, 0.17, 0.24))
		for z in [-2.5, 0.4, 3.6, 7.6, 8.6]:
			_add_wheel(Vector3(side * 1.35, 0.55, z), 0.48)
		_add_box("MirrorArm_%s" % side, Vector3(0.08, 0.08, 0.65), Vector3(side * 1.42, 2.55, -2.7), trim_paint)
	_add_box("FrontBumper", Vector3(2.45, 0.28, 0.22), Vector3(0.0, 0.65, -3.2), trim_paint)
	_add_box("FuelTank", Vector3(0.48, 0.5, 1.4), Vector3(1.32, 0.82, 0.2), Color(0.45, 0.48, 0.5))

func _add_box(label: String, dimensions: Vector3, location: Vector3, tint: Color) -> void:
	var part := MeshInstance3D.new()
	part.name = label
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	part.mesh = mesh
	part.position = location
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.metallic = 0.24
	material.roughness = 0.34
	part.material_override = material
	add_child(part)

func _add_wheel(location: Vector3, radius: float) -> void:
	var wheel := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.34
	wheel.mesh = mesh
	wheel.rotation_degrees.z = 90.0
	wheel.position = location
	var rubber := StandardMaterial3D.new()
	rubber.albedo_color = Color(0.025, 0.028, 0.032)
	wheel.material_override = rubber
	add_child(wheel)
