extends Node3D

signal trip_completed(driver_index: int, bus_index: int)

const PASSENGER_GROUP_SIZE := 8
const CRUISE_SPEED := 7.0
const ACCELERATION := 2.8

var _driver_index := -1
var _bus_index := -1
var _route_name := ""
var _bus: Node3D
var _route_points: Array[Vector3] = []
var _waypoint_index := 1
var _phase := 0 # outbound, passenger stop, return
var _current_speed := 0.0
var _stop_time := 0.0
var _passenger_group: Node3D
var _boarded_passengers := 0

func configure(vehicle_scene: PackedScene, start: Vector3, destination: Vector3, route_name: String, driver_index: int, bus_index: int) -> void:
	_driver_index = driver_index
	_bus_index = bus_index
	_route_name = route_name
	_bus = vehicle_scene.instantiate() as Node3D
	_bus.name = "CompanyBus_%03d" % (bus_index + 1)
	_bus.position = start
	_bus.set_process(false)
	_bus.set_physics_process(false)
	add_child(_bus)
	_route_points = [
		start,
		Vector3(start.x, start.y, lerpf(start.z, destination.z, 0.25)),
		Vector3(start.x, start.y, lerpf(start.z, destination.z, 0.5)),
		Vector3(start.x, start.y, lerpf(start.z, destination.z, 0.75)),
		destination
	]
	var marker := Label3D.new()
	marker.text = "COMPANY SERVICE %02d" % (bus_index + 1)
	marker.position = Vector3(0.0, 3.3, 0.0)
	marker.font_size = 22
	marker.pixel_size = 0.009
	marker.modulate = Color(0.55, 0.9, 1.0)
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bus.add_child(marker)

func _process(delta: float) -> void:
	if not is_instance_valid(_bus):
		return
	if _phase == 0:
		if _move_toward(_route_points[_waypoint_index], delta):
			_waypoint_index += 1
			if _waypoint_index >= _route_points.size():
				_phase = 1
				_stop_time = 6.5
				_current_speed = 0.0
				_spawn_passengers()
	elif _phase == 1:
		_stop_time -= delta
		if _stop_time <= 0.0:
			_phase = 2
			_route_points.reverse()
			_waypoint_index = 1
			if is_instance_valid(_passenger_group):
				_passenger_group.queue_free()
			_passenger_group = null
	elif _phase == 2:
		if _move_toward(_route_points[_waypoint_index], delta):
			_waypoint_index += 1
			if _waypoint_index >= _route_points.size():
				set_process(false)
				trip_completed.emit(_driver_index, _bus_index)
				queue_free()

func _move_toward(target: Vector3, delta: float) -> bool:
	var offset := target - _bus.position
	var distance := offset.length()
	if distance <= 0.12:
		_bus.position = target
		_current_speed = 0.0
		return true
	var direction := offset / distance
	var old_rotation := _bus.rotation
	_bus.look_at(_bus.position + direction, Vector3.UP)
	var desired_yaw := _bus.rotation.y
	_bus.rotation = old_rotation
	_bus.rotation.y = lerp_angle(_bus.rotation.y, desired_yaw, minf(delta * 2.8, 1.0))
	_current_speed = move_toward(_current_speed, CRUISE_SPEED, ACCELERATION * delta)
	_bus.position += direction * minf(distance, _current_speed * delta)
	return _bus.position.distance_to(target) <= 0.12

func _spawn_passengers() -> void:
	_passenger_group = Node3D.new()
	_passenger_group.name = "CompanyBusStopPassengers"
	_passenger_group.position = Vector3(0.2, 0.0, _bus.position.z - 3.0)
	add_child(_passenger_group)
	var clothing_colors: Array[Color] = [Color(0.12, 0.32, 0.62), Color(0.58, 0.20, 0.14), Color(0.18, 0.43, 0.30), Color(0.68, 0.48, 0.20)]
	for i in range(PASSENGER_GROUP_SIZE):
		var passenger := Node3D.new()
		passenger.name = "WaitingPassenger_%02d" % i
		passenger.position = Vector3(float(i % 4) * 0.62, 0.0, float(i / 4) * 0.85)
		_passenger_group.add_child(passenger)
		var body := MeshInstance3D.new()
		var body_mesh := CapsuleMesh.new()
		body_mesh.radius = 0.19
		body_mesh.height = 0.82
		body.mesh = body_mesh
		body.position.y = 0.62
		var clothing := StandardMaterial3D.new()
		clothing.albedo_color = clothing_colors[i % clothing_colors.size()]
		body.material_override = clothing
		passenger.add_child(body)
		var head := MeshInstance3D.new()
		var head_mesh := SphereMesh.new()
		head_mesh.radius = 0.15
		head_mesh.height = 0.3
		head.mesh = head_mesh
		head.position.y = 1.12
		passenger.add_child(head)
		var tween := passenger.create_tween()
		tween.tween_interval(float(i) * 0.55)
		tween.tween_property(passenger, "position", Vector3(1.25, 0.0, 3.0), 0.8)
		tween.tween_property(passenger, "scale", Vector3.ZERO, 0.2)
	var stop_sign := Label3D.new()
	stop_sign.text = "BUS STOP  |  8 WAITING"
	stop_sign.position = Vector3(2.8, 2.1, 0.0)
	stop_sign.font_size = 22
	stop_sign.pixel_size = 0.01
	stop_sign.modulate = Color(0.55, 0.9, 1.0)
	stop_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_passenger_group.add_child(stop_sign)
