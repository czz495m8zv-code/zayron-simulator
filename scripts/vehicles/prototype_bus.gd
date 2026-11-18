extends "res://scripts/vehicles/prototype_truck.gd"

func _add_bus_body_panel(panel_name: String, panel_size: Vector3, panel_position: Vector3, panel_material: Material) -> void:
	var panel := MeshInstance3D.new()
	panel.name = panel_name
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = panel_size
	panel.mesh = panel_mesh
	panel.position = panel_position
	panel.material_override = panel_material
	add_child(panel)


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
	# Separate body panels leave open window bays for a visible passenger cabin.
	_add_bus_body_panel("RoofPanel", Vector3(2.5, 0.28, 9.0), Vector3(0.0, 2.66, 0.0), body_material)
	_add_bus_body_panel("FrontBulkhead", Vector3(2.5, 2.8, 0.14), Vector3(0.0, 1.4, -4.43), body_material)
	_add_bus_body_panel("RearBulkhead", Vector3(2.5, 2.8, 0.14), Vector3(0.0, 1.4, 4.43), body_material)
	for side in [-1.0, 1.0]:
		_add_bus_body_panel("LowerSidePanel_%s" % side, Vector3(0.08, 1.32, 9.0), Vector3(side * 1.22, 0.82, 0.0), body_material)
		_add_bus_body_panel("UpperSidePanel_%s" % side, Vector3(0.08, 0.34, 9.0), Vector3(side * 1.22, 2.39, 0.0), body_material)
		for pillar_index in range(6):
			var pillar_z := -3.9 + float(pillar_index) * 1.56
			_add_bus_body_panel("WindowPillar_%s_%d" % [side, pillar_index], Vector3(0.09, 0.94, 0.12), Vector3(side * 1.22, 2.08, pillar_z), body_material)

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
	# Passenger cabin: paired seats leave a central aisle for boarding.
	var seat_fabric := StandardMaterial3D.new()
	seat_fabric.albedo_color = Color(0.055, 0.19, 0.29)
	seat_fabric.roughness = 0.72
	var seat_trim := StandardMaterial3D.new()
	seat_trim.albedo_color = Color(0.68, 0.62, 0.48)
	for row in range(5):
		for seat_side in [-0.66, 0.66]:
			var seat_z := -2.65 + float(row) * 1.38
			var cushion := MeshInstance3D.new()
			cushion.name = "PassengerSeatCushion_%d_%s" % [row, seat_side]
			var cushion_mesh := BoxMesh.new()
			cushion_mesh.size = Vector3(0.48, 0.16, 0.52)
			cushion.mesh = cushion_mesh
			cushion.position = Vector3(seat_side, 1.15, seat_z)
			cushion.material_override = seat_fabric
			add_child(cushion)
			var back := MeshInstance3D.new()
			back.name = "PassengerSeatBack_%d_%s" % [row, seat_side]
			var back_mesh := BoxMesh.new()
			back_mesh.size = Vector3(0.48, 0.7, 0.14)
			back.mesh = back_mesh
			back.position = Vector3(seat_side, 1.56, seat_z + 0.18)
			back.material_override = seat_fabric
			add_child(back)
			var grab_rail := MeshInstance3D.new()
			grab_rail.name = "SeatGrabRail_%d_%s" % [row, seat_side]
			var rail_mesh := BoxMesh.new()
			rail_mesh.size = Vector3(0.035, 0.42, 0.035)
			grab_rail.mesh = rail_mesh
			grab_rail.position = Vector3(seat_side + (0.27 if seat_side < 0.0 else -0.27), 1.65, seat_z + 0.05)
			grab_rail.material_override = seat_trim
			add_child(grab_rail)
	var aisle := MeshInstance3D.new()
	aisle.name = "PassengerCentralAisle"
	var aisle_mesh := BoxMesh.new()
	aisle_mesh.size = Vector3(0.42, 0.035, 7.2)
	aisle.mesh = aisle_mesh
	aisle.position = Vector3(0.0, 0.64, 0.0)
	var aisle_material := StandardMaterial3D.new()
	aisle_material.albedo_color = Color(0.18, 0.2, 0.22)
	aisle.material_override = aisle_material
	add_child(aisle)


	var destination_sign := MeshInstance3D.new()
	var sign_box := BoxMesh.new()
	sign_box.size = Vector3(1.35, 0.22, 0.04)
	destination_sign.mesh = sign_box
	destination_sign.position = Vector3(0.0, 2.88, -4.54)
	var sign_material := StandardMaterial3D.new()
	sign_material.albedo_color = Color(0.02, 0.16, 0.26)
	destination_sign.material_override = sign_material
	add_child(destination_sign)
