extends "res://scripts/vehicles/prototype_truck.gd"

func _build_truck() -> void:
	cockpit_camera_position = Vector3(0.0, 2.35, -3.8)
	var chassis_shape := CollisionShape3D.new()
	var chassis_box := BoxShape3D.new()
	chassis_box.size = Vector3(2.5, 2.8, 9.0)
	chassis_shape.shape = chassis_box
	chassis_shape.position.y = 1.4
	add_child(chassis_shape)

	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = Color(0.86, 0.82, 0.68)
	var body_mesh := MeshInstance3D.new()
	var body_box := BoxMesh.new()
	body_box.size = Vector3(2.5, 2.8, 9.0)
	body_mesh.mesh = body_box
	body_mesh.position.y = 1.4
	body_mesh.material_override = body_material
	add_child(body_mesh)

	var lower_band := MeshInstance3D.new()
	var band_box := BoxMesh.new()
	band_box.size = Vector3(2.53, 0.42, 9.02)
	lower_band.mesh = band_box
	lower_band.position = Vector3(0.0, 0.48, 0.0)
	var band_material := StandardMaterial3D.new()
	band_material.albedo_color = Color(0.02, 0.28, 0.48)
	lower_band.material_override = band_material
	add_child(lower_band)

	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.08, 0.20, 0.27, 0.82)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var front_glass := MeshInstance3D.new()
	var front_box := BoxMesh.new()
	front_box.size = Vector3(2.12, 1.05, 0.06)
	front_glass.mesh = front_box
	front_glass.position = Vector3(0.0, 2.22, -4.53)
	front_glass.material_override = glass
	add_child(front_glass)

	for side in [-1.0, 1.0]:
		for i in range(5):
			var window := MeshInstance3D.new()
			var window_box := BoxMesh.new()
			window_box.size = Vector3(0.055, 0.92, 1.18)
			window.mesh = window_box
			window.position = Vector3(side * 1.27, 2.12, -3.15 + float(i) * 1.48)
			window.material_override = glass
			add_child(window)

	var wheel_material := StandardMaterial3D.new()
	wheel_material.albedo_color = Color(0.035, 0.035, 0.04)
	for side in [-1.0, 1.0]:
		for z in [-3.0, 3.0]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.52
			wheel_mesh.bottom_radius = 0.52
			wheel_mesh.height = 0.30
			wheel.mesh = wheel_mesh
			wheel.rotation_degrees.z = 90.0
			wheel.position = Vector3(side * 1.28, 0.55, z)
			wheel.material_override = wheel_material
			add_child(wheel)

	_add_cockpit_steering_wheel(Vector3(-0.62, 1.95, -3.85))

	var destination_sign := MeshInstance3D.new()
	var sign_box := BoxMesh.new()
	sign_box.size = Vector3(1.35, 0.22, 0.04)
	destination_sign.mesh = sign_box
	destination_sign.position = Vector3(0.0, 2.88, -4.54)
	var sign_material := StandardMaterial3D.new()
	sign_material.albedo_color = Color(0.02, 0.16, 0.26)
	destination_sign.material_override = sign_material
	add_child(destination_sign)
