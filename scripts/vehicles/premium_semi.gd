extends "res://scripts/vehicles/prototype_truck.gd"

@export var cab_paint: Color = Color(0.04, 0.24, 0.38)
@export var trailer_paint: Color = Color(0.78, 0.8, 0.82)
@export var trim_paint: Color = Color(0.82, 0.65, 0.28)

func _build_truck() -> void:
	cockpit_camera_position = Vector3(0.0, 2.55, -2.55)
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
	_add_box("Dashboard", Vector3(2.05, 0.34, 0.72), Vector3(0.0, 1.55, -2.72), Color(0.035, 0.045, 0.06))
	_add_box("DigitalInstrumentPanel", Vector3(0.62, 0.24, 0.04), Vector3(0.0, 1.78, -2.92), Color(0.04, 0.55, 0.72))
	_add_box("DriverSeat", Vector3(0.72, 0.9, 0.72), Vector3(-0.62, 1.35, -0.9), Color(0.09, 0.11, 0.13))
	_add_cockpit_steering_wheel(Vector3(-0.62, 2.05, -2.65))
	_add_box("PassengerSeat", Vector3(0.72, 0.9, 0.72), Vector3(0.62, 1.35, -0.9), Color(0.09, 0.11, 0.13))
	_add_box("LeftHeadlamp", Vector3(0.42, 0.22, 0.08), Vector3(-0.82, 1.0, -3.2), Color(0.92, 0.95, 1.0))
	_add_box("RightHeadlamp", Vector3(0.42, 0.22, 0.08), Vector3(0.82, 1.0, -3.2), Color(0.92, 0.95, 1.0))
	_add_box("TrailerSideStripeLeft", Vector3(0.035, 0.12, 8.2), Vector3(-1.29, 1.0, 5.9), trim_paint)
	_add_box("TrailerSideStripeRight", Vector3(0.035, 0.12, 8.2), Vector3(1.29, 1.0, 5.9), trim_paint)
	# Reinforced trailer underframe and tandem-axle cross members.
	for side in [-1.0, 1.0]:
		_add_box("TrailerFrameRail_%s" % side, Vector3(0.18, 0.28, 8.15), Vector3(side * 0.88, 0.38, 5.9), Color(0.12, 0.14, 0.16))
	for z in [7.55, 8.55]:
		_add_box("TrailerAxleBeam_%s" % z, Vector3(2.05, 0.18, 0.22), Vector3(0.0, 0.43, z), Color(0.16, 0.18, 0.2))
 	# Tandem wheels gain visible metal hubs and simple protective mudguards.
	for side in [-1.0, 1.0]:
		_add_box("TandemMudguardTop_%s" % side, Vector3(0.16, 0.14, 2.18), Vector3(side * 1.42, 1.12, 8.05), Color(0.18, 0.2, 0.22))
		_add_box("TandemMudguardFront_%s" % side, Vector3(0.16, 0.62, 0.14), Vector3(side * 1.42, 0.78, 6.98), Color(0.18, 0.2, 0.22))
		_add_box("TandemMudguardRear_%s" % side, Vector3(0.16, 0.62, 0.14), Vector3(side * 1.42, 0.78, 9.12), Color(0.18, 0.2, 0.22))
		for z in [7.55, 8.55]:
			_add_wheel_hub(Vector3(side * 1.55, 0.55, z))
		_add_box("TrailerMudflap_%s" % side, Vector3(0.12, 0.62, 0.08), Vector3(side * 1.4, 0.35, 9.35), Color(0.045, 0.05, 0.055))
	# Retractable-looking landing legs and feet beneath the trailer nose.
	for side in [-1.0, 1.0]:
		_add_box("LandingLeg_%s" % side, Vector3(0.14, 0.62, 0.14), Vector3(side * 0.78, 0.24, 2.25), Color(0.3, 0.32, 0.34))
		_add_box("LandingFoot_%s" % side, Vector3(0.42, 0.08, 0.34), Vector3(side * 0.78, -0.08, 2.25), Color(0.22, 0.24, 0.26))
	_add_box("KingpinCouplingPlate", Vector3(1.5, 0.12, 0.72), Vector3(0.0, 0.48, 1.78), Color(0.16, 0.18, 0.2))
	# Rear double doors, hinges, locking bars and lower impact protection.
	_add_box("RearDoorLeft", Vector3(1.22, 3.42, 0.075), Vector3(-0.63, 2.35, 10.13), trailer_paint)
	_add_box("RearDoorRight", Vector3(1.22, 3.42, 0.075), Vector3(0.63, 2.35, 10.13), trailer_paint)
	for side in [-1.0, 1.0]:
		_add_box("RearDoorHingeTop_%s" % side, Vector3(0.09, 0.22, 0.12), Vector3(side * 1.19, 3.75, 10.19), trim_paint)
		_add_box("RearDoorHingeBottom_%s" % side, Vector3(0.09, 0.22, 0.12), Vector3(side * 1.19, 0.95, 10.19), trim_paint)
		_add_box("RearDoorLockBar_%s" % side, Vector3(0.055, 2.9, 0.09), Vector3(side * 0.72, 2.35, 10.2), Color(0.22, 0.25, 0.28))
		_add_box("RearDoorHandle_%s" % side, Vector3(0.16, 0.12, 0.12), Vector3(side * 0.72, 2.3, 10.27), trim_paint)
		_add_box("RearTailLamp_%s" % side, Vector3(0.38, 0.48, 0.12), Vector3(side * 0.92, 0.82, 10.2), Color(0.78, 0.035, 0.025))
		_add_box("RearReverseLamp_%s" % side, Vector3(0.22, 0.18, 0.12), Vector3(side * 0.92, 1.17, 10.2), Color(0.88, 0.9, 0.82))
	_add_box("RearBumper", Vector3(2.62, 0.2, 0.22), Vector3(0.0, 0.48, 10.18), Color(0.2, 0.22, 0.24))
	_add_box("RearTopHeader", Vector3(2.55, 0.16, 0.12), Vector3(0.0, 4.12, 10.16), trim_paint)
	# Small amber side markers make the trailer outline easier to read.
	for side in [-1.0, 1.0]:
		for z in [2.6, 5.0, 7.4, 9.2]:
			_add_box("TrailerSideMarker_%s_%s" % [side, z], Vector3(0.07, 0.16, 0.24), Vector3(side * 1.31, 1.25, z), Color(0.95, 0.48, 0.06))

func _add_wheel_hub(location: Vector3) -> void:
	var hub := MeshInstance3D.new()
	var hub_mesh := CylinderMesh.new()
	hub_mesh.top_radius = 0.22
	hub_mesh.bottom_radius = 0.22
	hub_mesh.height = 0.075
	hub.mesh = hub_mesh
	hub.rotation_degrees.z = 90.0
	hub.position = location
	var hub_material := StandardMaterial3D.new()
	hub_material.albedo_color = Color(0.48, 0.51, 0.54)
	hub_material.metallic = 0.78
	hub_material.roughness = 0.3
	hub.material_override = hub_material
	add_child(hub)
	var cap := MeshInstance3D.new()
	var cap_mesh := CylinderMesh.new()
	cap_mesh.top_radius = 0.085
	cap_mesh.bottom_radius = 0.085
	cap_mesh.height = 0.09
	cap.mesh = cap_mesh
	cap.rotation_degrees.z = 90.0
	cap.position = location + Vector3(signf(location.x) * 0.045, 0.0, 0.0)
	cap.material_override = hub_material
	add_child(cap)

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
