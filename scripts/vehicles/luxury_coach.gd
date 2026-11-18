extends "res://scripts/vehicles/prototype_truck.gd"

@export var primary_paint: Color = Color(0.035, 0.12, 0.24)
@export var accent_paint: Color = Color(0.78, 0.62, 0.32)

func _build_truck() -> void:
	var shell := BoxShape3D.new()
	shell.size = Vector3(2.55, 3.0, 10.0)
	var collision := CollisionShape3D.new()
	collision.shape = shell
	collision.position.y = 1.5
	add_child(collision)
	_add_box("LowerCoachBody", Vector3(2.5, 1.15, 9.9), Vector3(0.0, 0.82, 0.0), primary_paint)
	_add_box("CoachRoof", Vector3(2.52, 0.22, 9.9), Vector3(0.0, 2.98, 0.0), primary_paint)
	_add_box("FrontCoachPanel", Vector3(2.5, 1.0, 0.18), Vector3(0.0, 2.45, -4.92), primary_paint)
	_add_box("RearCoachPanel", Vector3(2.5, 1.0, 0.18), Vector3(0.0, 2.35, 4.92), primary_paint)
	_add_box("LowerLuxurySkirt", Vector3(2.58, 0.38, 9.9), Vector3(0.0, 0.42, 0.0), accent_paint)
	_add_box("FrontWindscreen", Vector3(2.18, 1.12, 0.06), Vector3(0.0, 2.45, -5.03), Color(0.06, 0.17, 0.24))
	_add_box("RearWindow", Vector3(2.0, 0.9, 0.06), Vector3(0.0, 2.35, 5.03), Color(0.06, 0.17, 0.24))
	for side in [-1.0, 1.0]:
		_add_box("GoldCoachBelt_%s" % side, Vector3(0.035, 0.12, 9.7), Vector3(side * 1.29, 1.0, 0.0), accent_paint)
		_add_box("WindowSill_%s" % side, Vector3(0.06, 0.18, 9.7), Vector3(side * 1.29, 1.55, 0.0), primary_paint)
		for i in range(8):
			_add_box("WindowPillar_%s_%02d" % [side, i], Vector3(0.07, 1.2, 0.09), Vector3(side * 1.29, 2.12, -4.1 + float(i) * 1.17), accent_paint)
		for i in range(7):
			_add_box("PanoramicWindow_%s_%02d" % [side, i], Vector3(0.035, 1.05, 1.05), Vector3(side * 1.29, 2.12, -3.52 + float(i) * 1.3), Color(0.07, 0.20, 0.29))
		for z in [-3.65, 0.0, 3.65]:
			_add_wheel(Vector3(side * 1.34, 0.55, z), 0.48)
	for side in [-1.0, 1.0]:
		_add_box("Headlamp_%s" % side, Vector3(0.34, 0.2, 0.08), Vector3(side * 0.82, 1.18, -5.06), Color(0.9, 0.94, 1.0))
	_add_box("RoofAC", Vector3(1.45, 0.25, 2.2), Vector3(0.0, 3.12, 1.0), Color(0.72, 0.76, 0.8))
	_add_box("LuxuryDestinationPanel", Vector3(1.3, 0.22, 0.04), Vector3(0.0, 2.92, -5.05), Color(0.02, 0.04, 0.07))
	_add_box("DriverDashboard", Vector3(2.0, 0.32, 0.72), Vector3(0.0, 1.85, -4.05), Color(0.035, 0.045, 0.06))
	_add_box("DashboardDisplay", Vector3(0.55, 0.22, 0.035), Vector3(0.0, 2.08, -4.18), Color(0.08, 0.62, 0.78))
	_add_box("SteeringColumn", Vector3(0.12, 0.48, 0.12), Vector3(-0.62, 2.0, -3.85), Color(0.12, 0.13, 0.14))
	for row in range(5):
		for seat_side in [-0.58, 0.58]:
			var seat_z := -2.6 + float(row) * 1.35
			_add_box("PassengerSeatBase_%d_%s" % [row, seat_side], Vector3(0.48, 0.18, 0.5), Vector3(seat_side, 1.25, seat_z), Color(0.12, 0.16, 0.2))
			_add_box("PassengerSeatBack_%d_%s" % [row, seat_side], Vector3(0.48, 0.72, 0.16), Vector3(seat_side, 1.68, seat_z + 0.16), Color(0.16, 0.21, 0.26))

func _add_box(label: String, dimensions: Vector3, location: Vector3, tint: Color) -> void:
	var part := MeshInstance3D.new()
	part.name = label
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	part.mesh = mesh
	part.position = location
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.metallic = 0.28 if tint == accent_paint else 0.12
	material.roughness = 0.3
	part.material_override = material
	add_child(part)

func _add_wheel(location: Vector3, radius: float) -> void:
	var wheel := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.32
	wheel.mesh = mesh
	wheel.rotation_degrees.z = 90.0
	wheel.position = location
	var rubber := StandardMaterial3D.new()
	rubber.albedo_color = Color(0.025, 0.028, 0.032)
	wheel.material_override = rubber
	add_child(wheel)
