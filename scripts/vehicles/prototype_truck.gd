extends CharacterBody3D

signal refuel_requested(cost_omr: int)
signal repair_requested(cost_omr: int)
signal vehicle_damage_changed(damage_percent: int)

@export var acceleration: float = 8.0
@export var service_brake: float = 18.0
@export var rolling_resistance: float = 1.4
@export var max_forward_speed: float = 25.0
@export var max_reverse_speed: float = 6.0
@export var steering_speed: float = 1.15
@export var steering_response: float = 3.5
@export var lateral_grip: float = 12.0
@export var supports_passenger_doors: bool = false
@export var supports_trailer: bool = false

var _speed: float = 0.0
var _collision_warning_timer: float = 0.0
var _collision_damage_cooldown: float = 0.0
var _vehicle_damage := 0
var _service_station_available := false
var _repair_button: Button
var _throttle_input: float = 0.0
var _cruise_control_on := false
var _cruise_target_speed := 0.0
var _automatic_gear := 1
var _engine_rpm := 650.0
var _brake_input: float = 0.0
var _traffic_signal_brake: float = 0.0
var _reverse_input: float = 0.0
var _steering_input: float = 0.0
var _steering_current: float = 0.0
var _steering_multiplier: float = 1.0
var _steer_left_held: bool = false
var _steer_right_held: bool = false
var _speed_label: Label
var _gear_label: Label
var _rpm_label: Label
var _vehicle_status_label: Label
var _fuel_label: Label
var _refuel_button: Button
var _refuel_station_available := false
var _fuel_level := 100.0
var _engine_temperature := 22.0
var _cargo_loaded := false
var _cargo_secured := false
var _cargo_straps_button: Button
var _exterior_camera: Camera3D
var _close_camera: Camera3D
var _cockpit_camera: Camera3D
var _rear_camera: Camera3D
var _camera_before_rear: Camera3D
var _rear_camera_active := false
var _rear_camera_button: Button
var _camera_button: Button
var _camera_mode: int = 0
var _headlights_on: bool = true
var _headlight_lights: Array[SpotLight3D] = []
var _headlight_meshes: Array[MeshInstance3D] = []
var _rear_lamp_material: StandardMaterial3D
var _reverse_lamp_material: StandardMaterial3D
var _reverse_lamp_meshes: Array[MeshInstance3D] = []
var _headlight_button: Button
var _handbrake_on := false
var _seatbelt_fastened := false
var _hazard_on := false
var _left_indicator_on := false
var _right_indicator_on := false
var _indicator_clock := 0.0
var _indicator_elapsed := 0.0
var _indicator_visible := true
var _indicator_lights: Array[MeshInstance3D] = []
var _wipers_on := false
var _wiper_arm: MeshInstance3D
var _door_open := false
var _door_hinge: Node3D
var _passenger_door_hinge: Node3D
var _passenger_doors_open := false
var _visible_passenger_count := 0
const PASSENGER_SEAT_CAPACITY := 10
var _horn_playback: AudioStreamGeneratorPlayback
var _horn_frames_left := 0
var _horn_phase := 0.0
var _steering_wheel_mesh: MeshInstance3D
var _seat_adjustment := 0.0
var _high_beam_on := false
var _parking_lights_on := false
var _boot_open := false
var _engine_running := true
var _gear_mode := "D"
var _engine_button: Button
var _trailer_assembly: Node3D
var _trailer_attached := false
var _trailer_legs_down := false
var _trailer_doors_open := false
var _trailer_home_transform := Transform3D.IDENTITY
var _trailer_button: Button
var _landing_legs_button: Button
@export var cockpit_camera_position: Vector3 = Vector3(0.0, 2.45, -1.35)
var _engine_playback: AudioStreamGeneratorPlayback
var _engine_phase: float = 0.0
const ENGINE_SAMPLE_RATE: float = 22050.0

func _ready() -> void:
	_build_truck()
	_initialize_trailer_system()
	_build_camera()
	_build_vehicle_lights()
	_build_extra_vehicle_controls()
	_build_passenger_door_controls()
	_build_mobile_controls()
	_build_engine_audio()

func _process(delta: float) -> void:
	if _engine_playback != null:
		var frames := _engine_playback.get_frames_available()
		var frequency := (38.0 + _engine_rpm * 0.055) if _engine_running else 0.0
		for i in range(frames):
			var sample := (sin(_engine_phase) * 0.055 + sin(_engine_phase * 2.0) * 0.018 + sin(_engine_phase * 0.5) * 0.022) if _engine_running else 0.0
			_engine_playback.push_frame(Vector2(sample, sample))
			_engine_phase = fmod(_engine_phase + TAU * frequency / ENGINE_SAMPLE_RATE, TAU)
	if _horn_playback != null and _horn_frames_left > 0:
		var horn_frames := mini(_horn_playback.get_frames_available(), _horn_frames_left)
		for i in range(horn_frames):
			var sample := sin(_horn_phase) * 0.18
			_horn_playback.push_frame(Vector2(sample, sample))
			_horn_phase += TAU * 440.0 / ENGINE_SAMPLE_RATE
			_horn_frames_left -= 1
	if _left_indicator_on or _right_indicator_on or _hazard_on:
		_indicator_clock += delta
		if not _hazard_on and (_left_indicator_on or _right_indicator_on):
			_indicator_elapsed += delta
			if _indicator_elapsed >= 5.0:
				_left_indicator_on = false
				_right_indicator_on = false
				_indicator_elapsed = 0.0
		else:
			_indicator_elapsed = 0.0
		if _indicator_clock >= 0.45:
			_indicator_clock = 0.0
			_indicator_visible = not _indicator_visible
		_update_indicator_lights()
	_update_rear_lighting()
	if _wipers_on and is_instance_valid(_wiper_arm):
		_wiper_arm.rotation.z = sin(float(Time.get_ticks_msec()) / 1000.0 * 3.2) * 0.48

func _build_engine_audio() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = ENGINE_SAMPLE_RATE
	generator.buffer_length = 0.18
	var player := AudioStreamPlayer.new()
	player.name = "ProceduralEngineAudio"
	player.stream = generator
	player.volume_db = -8.0
	add_child(player)
	player.play()
	_engine_playback = player.get_stream_playback() as AudioStreamGeneratorPlayback

func _physics_process(delta: float) -> void:
	var trailer_ready := not (supports_trailer and ((_trailer_attached and _trailer_legs_down) or _trailer_doors_open))
	var passenger_door_ready := not (supports_passenger_doors and _passenger_doors_open)
	var cab_door_ready := not _door_open
	var boot_ready := not _boot_open
	var cargo_ready := not _cargo_loaded or _cargo_secured
	var drive_ready := _engine_running and _fuel_level > 0.0 and _seatbelt_fastened and trailer_ready and passenger_door_ready and cab_door_ready and boot_ready and cargo_ready
	var throttle := _throttle_input if drive_ready and _gear_mode == "D" else 0.0
	var brake := maxf(_brake_input, _traffic_signal_brake)
	# Cruise control maintains the captured road speed without overriding braking.
	if _cruise_control_on and drive_ready and _gear_mode == "D" and brake <= 0.01:
		var cruise_error := _cruise_target_speed - _speed
		throttle = clampf(cruise_error * 0.65, 0.0, 1.0) if cruise_error > 0.25 else 0.0
	elif brake > 0.01 or not drive_ready or _gear_mode != "D":
		_cruise_control_on = false
	var reverse := _reverse_input if drive_ready and _gear_mode == "R" else 0.0
	var steering := _steering_input

	if not OS.has_feature("android"):
		# Desktop fallback obeys the same ignition, gear and safety interlocks as touch controls.
		throttle = Input.get_action_strength("ui_up") if drive_ready and _gear_mode == "D" else 0.0
		brake = Input.get_action_strength("ui_down")
		steering = Input.get_axis("ui_left", "ui_right")
		reverse = 0.0

	throttle = clampf(throttle, 0.0, 1.0)
	brake = clampf(brake, 0.0, 1.0)
	reverse = clampf(reverse, 0.0, 1.0)
	var damage_factor := 1.0 - (float(_vehicle_damage) / 100.0) * 0.45
	var overheating_factor := 1.0 - clampf((_engine_temperature - 105.0) / 35.0, 0.0, 1.0) * 0.35
	var speed_ratio := clampf(absf(_speed) / maxf(max_forward_speed * damage_factor * overheating_factor, 0.1), 0.0, 1.0)

	if is_instance_valid(_rear_lamp_material):
		_rear_lamp_material.emission_energy_multiplier = 0.8 + brake * 2.2
	for tail_lamp in get_children():
		if tail_lamp is MeshInstance3D and String(tail_lamp.name) == "RearTailLamp":
			tail_lamp.visible = _parking_lights_on or brake > 0.01
	for reverse_lamp in _reverse_lamp_meshes:
		if is_instance_valid(reverse_lamp):
			reverse_lamp.visible = _engine_running and _gear_mode == "R"

	# A simple torque curve: strongest pull at low speed, tapering near top speed.
	if _handbrake_on:
		_speed = move_toward(_speed, 0.0, service_brake * 1.8 * delta)
	elif brake > 0.0:
		_speed = move_toward(_speed, 0.0, service_brake * brake * delta)
	elif reverse > 0.0 and absf(_speed) < 0.8 and not _handbrake_on:
		_speed = move_toward(_speed, -max_reverse_speed, acceleration * 0.48 * delta)
	elif throttle > 0.0 and _speed >= -0.1 and not _handbrake_on:
		var torque_factor := lerpf(1.0, 0.42, speed_ratio)
		var payload_factor := 0.78 if _cargo_loaded else 1.0
		_speed = move_toward(_speed, max_forward_speed * damage_factor * (0.90 if _cargo_loaded else 1.0), acceleration * torque_factor * payload_factor * damage_factor * overheating_factor * throttle * delta)
	else:
		# Engine braking plus speed-dependent aerodynamic/rolling drag.
		var drag := rolling_resistance + (absf(_speed) * absf(_speed) * 0.018)
		_speed = move_toward(_speed, 0.0, drag * delta)

	# Automatic transmission model: speed bands select six forward ratios.
	# It is intentionally a lightweight drivetrain approximation, not a clutch
	# or torque-converter simulation.
	if _gear_mode == "D":
		_update_automatic_transmission(throttle, delta)
	elif _engine_running:
		_engine_rpm = move_toward(_engine_rpm, 850.0 if _gear_mode == "R" else 650.0, delta * 1800.0)
	else:
		_engine_rpm = move_toward(_engine_rpm, 0.0, delta * 2400.0)

	# Steering input eases in and out rather than snapping instantly.
	_steering_current = move_toward(_steering_current, steering, steering_response * delta)

	# Steering authority fades at highway speed to avoid unrealistically sharp turns.
	if absf(_speed) > 0.2:
		var direction := 1.0 if _speed >= 0.0 else -1.0
		var steering_authority := lerpf(1.0, 0.38, speed_ratio)
		# Heavy cargo and hard braking make steering response more conservative.
		var payload_steering_factor := 0.90 if _cargo_loaded else 1.0
		var braking_steering_factor := 1.0 - brake * 0.22
		steering_authority *= payload_steering_factor * braking_steering_factor
		rotate_y(-_steering_current * steering_speed * _steering_multiplier * steering_authority * delta * direction)

	# Preserve a little lateral momentum, then let a friction-budget
	# approximation settle it. Braking and a loaded cargo body leave less
	# grip available for cornering, especially in a heavy vehicle.
	var forward := -global_transform.basis.z
	var previous_horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var lateral_velocity := previous_horizontal - forward * previous_horizontal.dot(forward)
	var braking_grip_factor := 1.0 - brake * 0.35
	var payload_grip_factor := 0.88 if _cargo_loaded else 1.0
	var speed_grip_factor := 1.0 + clampf(absf(_speed) / maxf(max_forward_speed, 0.1), 0.0, 1.0) * 0.2
	var available_lateral_grip := lateral_grip * braking_grip_factor * payload_grip_factor * speed_grip_factor
	lateral_velocity = lateral_velocity.move_toward(Vector3.ZERO, available_lateral_grip * delta)
	velocity = forward * _speed + lateral_velocity
	move_and_slide()
	if _collision_warning_timer > 0.0:
		_collision_warning_timer = maxf(0.0, _collision_warning_timer - delta)
	if _collision_damage_cooldown > 0.0:
		_collision_damage_cooldown = maxf(0.0, _collision_damage_cooldown - delta)
	# Highway traffic uses AnimatableBody3D collision bodies. On impact, apply
	# a strong speed loss and activate hazards so the player notices the crash.
	for collision_index in range(get_slide_collision_count()):
		var impact := get_slide_collision(collision_index)
		var hit_body := impact.get_collider()
		if hit_body is AnimatableBody3D and String(hit_body.name) == "TrafficCollisionBody":
			if absf(_speed) > 2.0 and _collision_damage_cooldown <= 0.0:
				var impact_speed := absf(_speed)
				_speed *= 0.22
				_vehicle_damage = mini(100, _vehicle_damage + maxi(8, int(impact_speed * 1.4)))
				_collision_damage_cooldown = 1.5
				vehicle_damage_changed.emit(_vehicle_damage)
				_hazard_on = true
				_collision_warning_timer = 4.0
				_update_indicator_lights()
			break
	# Fuel is consumed only while the engine is running. Distance use models
	# road load; the additional idle/load term drains fuel while stationary too.
	if _engine_running:
		var distance_moved := absf(_speed) * delta
		var idle_and_load_use := (0.00006 + throttle * 0.00008) * delta
		_fuel_level = maxf(0.0, _fuel_level - distance_moved * 0.0008 - idle_and_load_use)

	if is_instance_valid(_speed_label):
		_speed_label.text = "%03d km/h" % int(absf(_speed) * 3.6)
	if is_instance_valid(_gear_label):
		var display_gear := "D%d" % _automatic_gear if _gear_mode == "D" else _gear_mode
		_gear_label.text = display_gear + ("  •  OFF" if not _engine_running else "  •  ON")
	var rpm_value := _engine_rpm
	if _engine_running:
		# Simplified thermal balance: engine load and secured cargo add heat;
		# road speed provides airflow cooling. Sustained overload can overheat.
		var heat_gain := 0.15 + throttle * 0.78 + (0.08 if _cargo_loaded else 0.0)
		var airflow_cooling := 0.12 + absf(_speed) * 0.012
		_engine_temperature = clampf(_engine_temperature + (heat_gain - airflow_cooling) * delta, 22.0, 135.0)
	else:
		_engine_temperature = move_toward(_engine_temperature, 22.0, delta * 0.45)
	if is_instance_valid(_rpm_label):
		_rpm_label.text = "RPM  %04d    TEMP  %02d°C" % [int(clampf(rpm_value, 0.0, 3200.0)), int(_engine_temperature)]
	if is_instance_valid(_fuel_label):
		_fuel_label.text = _fuel_display_text()
		_fuel_label.add_theme_color_override("font_color", Color(1.0, 0.34, 0.22) if _fuel_level <= 15.0 else Color(0.55, 0.9, 1.0))
	if is_instance_valid(_vehicle_status_label):
		var status_parts: Array[String] = []
		if _fuel_level <= 0.0:
			status_parts.append("OUT OF FUEL")
		elif _fuel_level <= 15.0:
			status_parts.append("LOW FUEL")
		if _handbrake_on:
			status_parts.append("PARK BRAKE")
		if _traffic_signal_brake > 0.05:
			status_parts.append("TRAFFIC SIGNAL")
		if _collision_warning_timer > 0.0:
			status_parts.append("COLLISION - CHECK VEHICLE")
		if _vehicle_damage > 0:
			status_parts.append("VEHICLE DAMAGE %d%%" % _vehicle_damage)
		if _vehicle_damage >= 60:
			status_parts.append("ENGINE POWER REDUCED")
		if _engine_temperature >= 105.0:
			status_parts.append("ENGINE OVERHEATING - REDUCE LOAD")
		if supports_passenger_doors and _passenger_doors_open:
			status_parts.append("CLOSE PASSENGER DOORS")
		if _door_open:
			status_parts.append("CLOSE CAB DOOR")
		if _boot_open:
			status_parts.append("CLOSE BOOT BEFORE DRIVING")
		if supports_trailer and _trailer_doors_open:
			status_parts.append("CLOSE TRAILER DOORS")
		if _cargo_loaded and not _cargo_secured:
			status_parts.append("SECURE CARGO")
		if absf(_speed) > 0.5 and not _seatbelt_fastened:
			status_parts.append("SEAT BELT WARNING")
		if _headlights_on:
			status_parts.append("HEADLIGHTS")
		if _hazard_on:
			status_parts.append("HAZARD")
		elif _left_indicator_on:
			status_parts.append("LEFT SIGNAL")
		elif _right_indicator_on:
			status_parts.append("RIGHT SIGNAL")
		if supports_trailer and _trailer_legs_down:
			status_parts.append("TRAILER LEGS DOWN")
		if supports_passenger_doors and _visible_passenger_count > 0:
			status_parts.append("PASSENGERS %d/%d" % [_visible_passenger_count, PASSENGER_SEAT_CAPACITY])
		if _cargo_loaded:
			status_parts.append("CARGO SECURED" if _cargo_secured else "SECURE CARGO BEFORE DRIVING")
		_vehicle_status_label.text = "  |  ".join(status_parts) if not status_parts.is_empty() else "SYSTEMS NORMAL"
	if is_instance_valid(_steering_wheel_mesh):
		_steering_wheel_mesh.rotation.z = -_steering_current * 0.72

func _build_truck() -> void:
	var body_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 2.0, 4.8)
	body_shape.shape = box
	body_shape.position.y = 1.0
	add_child(body_shape)

	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.78, 0.19, 0.07)
	var body_mesh := MeshInstance3D.new()
	var body := BoxMesh.new()
	body.size = box.size
	body_mesh.mesh = body
	body_mesh.position.y = 1.0
	body_mesh.material_override = paint
	add_child(body_mesh)

	var cabin_mesh := MeshInstance3D.new()
	var cabin := BoxMesh.new()
	cabin.size = Vector3(2.0, 1.5, 1.8)
	cabin_mesh.mesh = cabin
	cabin_mesh.position = Vector3(0.0, 2.65, -1.0)
	cabin_mesh.material_override = paint
	add_child(cabin_mesh)

	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.12, 0.24, 0.31, 0.82)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var windscreen := MeshInstance3D.new()
	var windscreen_mesh := BoxMesh.new()
	windscreen_mesh.size = Vector3(1.72, 0.92, 0.06)
	windscreen.mesh = windscreen_mesh
	windscreen.position = Vector3(0.0, 2.83, -1.92)
	windscreen.material_override = glass
	add_child(windscreen)

	_add_cockpit_steering_wheel(Vector3(-0.62, 2.15, -1.55))

	var wheel_material := StandardMaterial3D.new()
	wheel_material.albedo_color = Color(0.045, 0.045, 0.05)
	for x in [-1.12, 1.12]:
		for z in [-1.55, 1.55]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.48
			wheel_mesh.bottom_radius = 0.48
			wheel_mesh.height = 0.28
			wheel.mesh = wheel_mesh
			wheel.rotation_degrees.z = 90.0
			wheel.position = Vector3(x, 0.55, z)
			wheel.material_override = wheel_material
			add_child(wheel)


func set_traffic_signal_brake(value: float) -> void:
	_traffic_signal_brake = clampf(value, 0.0, 1.0)


func set_steering_sensitivity(value: float) -> void:
	_steering_multiplier = clampf(value, 0.5, 1.8)

func set_cargo_payload(cargo_type: int, loaded: bool) -> void:
	_cargo_loaded = loaded
	_cargo_secured = false
	if is_instance_valid(_cargo_straps_button):
		_cargo_straps_button.visible = loaded
		_cargo_straps_button.text = "SECURE CARGO" if loaded else "NO CARGO"
	var payload := get_node_or_null("CargoPayload") as Node3D
	if payload == null:
		payload = Node3D.new()
		payload.name = "CargoPayload"
		add_child(payload)
		var deck := MeshInstance3D.new()
		deck.name = "CargoDeck"
		var deck_mesh := BoxMesh.new()
		deck_mesh.size = Vector3(1.95, 0.12, 2.0)
		deck.mesh = deck_mesh
		deck.position = Vector3(0.0, 1.08, 1.55)
		var deck_mat := StandardMaterial3D.new()
		deck_mat.albedo_color = Color(0.16, 0.18, 0.2)
		deck.material_override = deck_mat
		payload.add_child(deck)
		var cargo_colors := [Color(0.62, 0.36, 0.16), Color(0.72, 0.58, 0.32), Color(0.24, 0.48, 0.62)]
		var cargo_color: Color = cargo_colors[clampi(cargo_type, 0, cargo_colors.size() - 1)]
		for i in range(4):
			var crate := MeshInstance3D.new()
			crate.name = "CargoCrate_%d" % i
			var crate_mesh := BoxMesh.new()
			crate_mesh.size = Vector3(0.88, 0.72, 0.88)
			crate.mesh = crate_mesh
			crate.position = Vector3(-0.48 if i % 2 == 0 else 0.48, 1.5, 1.05 + (float(i) / 2.0) * 0.92)
			var crate_mat := StandardMaterial3D.new()
			crate_mat.albedo_color = cargo_color
			crate_mat.roughness = 0.82
			crate.material_override = crate_mat
			payload.add_child(crate)
			for strap_index in range(2):
				var strap := MeshInstance3D.new()
				strap.name = "CargoStrap_%d_%d" % [i, strap_index]
				var strap_mesh := BoxMesh.new()
				strap_mesh.size = Vector3(0.045, 0.76, 0.92)
				strap.mesh = strap_mesh
				var strap_offset := -0.24 if strap_index == 0 else 0.24
				strap.position = crate.position + Vector3(strap_offset, 0.0, 0.0)
				var strap_mat := StandardMaterial3D.new()
				strap_mat.albedo_color = Color(0.055, 0.07, 0.085)
				strap_mat.metallic = 0.18
				strap.material_override = strap_mat
				payload.add_child(strap)
				var buckle := MeshInstance3D.new()
				buckle.name = "CargoStrapBuckle_%d_%d" % [i, strap_index]
				var buckle_mesh := BoxMesh.new()
				buckle_mesh.size = Vector3(0.11, 0.07, 0.045)
				buckle.mesh = buckle_mesh
				buckle.position = crate.position + Vector3(strap_offset, -0.23, -0.47)
				var buckle_mat := StandardMaterial3D.new()
				buckle_mat.albedo_color = Color(0.42, 0.46, 0.49)
				buckle_mat.metallic = 0.72
				buckle_mat.roughness = 0.34
				buckle.material_override = buckle_mat
				payload.add_child(buckle)
	payload.visible = loaded
	_update_cargo_strap_visuals()


func _update_cargo_strap_visuals() -> void:
	var payload := get_node_or_null("CargoPayload") as Node3D
	if not is_instance_valid(payload):
		return
	for child in payload.get_children():
		if child is MeshInstance3D and (String(child.name).begins_with("CargoStrap_") or String(child.name).begins_with("CargoStrapBuckle_")):
			child.visible = _cargo_loaded and _cargo_secured


func _build_camera() -> void:
	_exterior_camera = Camera3D.new()
	_exterior_camera.name = "ChaseCamera"
	_exterior_camera.position = Vector3(0.0, 5.2, 10.5)
	_exterior_camera.rotation_degrees = Vector3(-19.0, 0.0, 0.0)
	_exterior_camera.current = true
	_exterior_camera.fov = 72.0
	add_child(_exterior_camera)

	_close_camera = Camera3D.new()
	_close_camera.name = "CloseDrivingCamera"
	_close_camera.position = Vector3(0.0, 3.4, 5.2)
	_close_camera.rotation_degrees = Vector3(-11.0, 0.0, 0.0)
	_close_camera.current = false
	_close_camera.fov = 78.0
	add_child(_close_camera)

	_cockpit_camera = Camera3D.new()
	_cockpit_camera.name = "CockpitCamera"
	_cockpit_camera.position = cockpit_camera_position
	_cockpit_camera.current = false
	_cockpit_camera.fov = 76.0
	add_child(_cockpit_camera)

	_rear_camera = Camera3D.new()
	_rear_camera.name = "RearViewCamera"
	_rear_camera.position = Vector3(0.0, 2.55, 2.48)
	_rear_camera.rotation_degrees = Vector3(-9.0, 180.0, 0.0)
	_rear_camera.current = false
	_rear_camera.fov = 82.0
	add_child(_rear_camera)

func _toggle_camera() -> void:
	if _rear_camera_active:
		_toggle_rear_camera()
	_camera_mode = (_camera_mode + 1) % 3
	match _camera_mode:
		0:
			_exterior_camera.make_current()
			_camera_button.text = "VIEW: CHASE"
		1:
			_close_camera.make_current()
			_camera_button.text = "VIEW: CLOSE"
		2:
			_cockpit_camera.make_current()
			_camera_button.text = "VIEW: CABIN"

func _build_vehicle_lights() -> void:
	var lamp_material := StandardMaterial3D.new()
	lamp_material.albedo_color = Color(0.92, 0.88, 0.68)
	lamp_material.emission_enabled = true
	lamp_material.emission = Color(0.95, 0.86, 0.58)
	lamp_material.emission_energy_multiplier = 1.4
	for x in [-0.72, 0.72]:
		var lamp := MeshInstance3D.new()
		lamp.name = "FrontHeadlamp"
		var lamp_mesh := BoxMesh.new()
		lamp_mesh.size = Vector3(0.34, 0.2, 0.08)
		lamp.mesh = lamp_mesh
		lamp.position = Vector3(x, 1.25, -2.43)
		lamp.material_override = lamp_material
		add_child(lamp)
		_headlight_meshes.append(lamp)
		var beam := SpotLight3D.new()
		beam.name = "HeadlightBeam"
		beam.position = Vector3(x, 1.28, -2.52)
		beam.light_color = Color(1.0, 0.9, 0.72)
		beam.light_energy = 1.15
		beam.spot_range = 25.0
		beam.spot_angle = 38.0
		beam.shadow_enabled = false
		add_child(beam)
		_headlight_lights.append(beam)
	_rear_lamp_material = StandardMaterial3D.new()
	_rear_lamp_material.albedo_color = Color(0.55, 0.025, 0.018)
	_rear_lamp_material.emission_enabled = true
	_rear_lamp_material.emission = Color(0.8, 0.025, 0.012)
	_rear_lamp_material.emission_energy_multiplier = 0.8
	for x in [-0.78, 0.78]:
		var tail := MeshInstance3D.new()
		tail.name = "RearTailLamp"
		var tail_mesh := BoxMesh.new()
		tail_mesh.size = Vector3(0.24, 0.28, 0.08)
		tail.mesh = tail_mesh
		tail.position = Vector3(x, 1.18, 2.43)
		tail.material_override = _rear_lamp_material
		add_child(tail)


	_reverse_lamp_material = StandardMaterial3D.new()
	_reverse_lamp_material.albedo_color = Color(0.92, 0.96, 1.0)
	_reverse_lamp_material.emission_enabled = true
	_reverse_lamp_material.emission = Color(0.82, 0.9, 1.0)
	_reverse_lamp_material.emission_energy_multiplier = 1.5
	for x in [-0.48, 0.48]:
		var reverse_lamp := MeshInstance3D.new()
		reverse_lamp.name = "ReverseLamp"
		var reverse_mesh := BoxMesh.new()
		reverse_mesh.size = Vector3(0.22, 0.16, 0.07)
		reverse_lamp.mesh = reverse_mesh
		reverse_lamp.position = Vector3(x, 1.12, 2.49)
		reverse_lamp.material_override = _reverse_lamp_material
		reverse_lamp.visible = false
		add_child(reverse_lamp)
		_reverse_lamp_meshes.append(reverse_lamp)

func _toggle_headlights() -> void:
	_headlights_on = not _headlights_on
	for beam in _headlight_lights:
		if is_instance_valid(beam):
			beam.visible = _headlights_on
	for lamp in _headlight_meshes:
		if is_instance_valid(lamp):
			lamp.visible = _headlights_on or _parking_lights_on
	if is_instance_valid(_headlight_button):
		_headlight_button.text = "LIGHTS: ON" if _headlights_on else "LIGHTS: OFF"

func _build_mobile_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "MobileControls"
	layer.layer = 10
	add_child(layer)

	var ui := Control.new()
	ui.name = "TouchUI"
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(ui)

	_speed_label = Label.new()
	_speed_label.text = "000 km/h"
	_speed_label.position = Vector2(24.0, 24.0)
	_speed_label.add_theme_font_size_override("font_size", 30)
	_speed_label.add_theme_color_override("font_color", Color.WHITE)
	_speed_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_speed_label.add_theme_constant_override("shadow_offset_x", 2)
	_speed_label.add_theme_constant_override("shadow_offset_y", 2)
	ui.add_child(_speed_label)

	_gear_label = Label.new()
	_gear_label.text = "N"
	_gear_label.position = Vector2(28.0, 62.0)
	_gear_label.add_theme_font_size_override("font_size", 20)
	_gear_label.add_theme_color_override("font_color", Color(0.35, 0.85, 1.0))
	ui.add_child(_gear_label)

	_rpm_label = Label.new()
	_rpm_label.text = "RPM  0650    TEMP  22°C"
	_rpm_label.position = Vector2(28.0, 90.0)
	_rpm_label.add_theme_font_size_override("font_size", 15)
	_rpm_label.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0))
	_rpm_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	ui.add_child(_rpm_label)

	_vehicle_status_label = Label.new()
	_vehicle_status_label.text = "SYSTEMS NORMAL"
	_vehicle_status_label.position = Vector2(28.0, 114.0)
	_vehicle_status_label.add_theme_font_size_override("font_size", 12)
	_vehicle_status_label.add_theme_color_override("font_color", Color(0.7, 0.92, 0.75))
	_vehicle_status_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	ui.add_child(_vehicle_status_label)

	_fuel_label = Label.new()
	_fuel_label.text = "FUEL  100%  |  RANGE ~125 km"
	_fuel_label.position = Vector2(28.0, 136.0)
	_fuel_label.add_theme_font_size_override("font_size", 14)
	_fuel_label.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0))
	_fuel_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	ui.add_child(_fuel_label)

	_add_hold_button(ui, "◀", true, 24.0, -124.0, 112.0, -24.0, "steer_left")
	_add_hold_button(ui, "▶", true, 132.0, -124.0, 220.0, -24.0, "steer_right")
	_add_hold_button(ui, "BRAKE", false, -224.0, -124.0, -124.0, -24.0, "brake")
	_add_hold_button(ui, "GAS", false, -112.0, -124.0, -12.0, -24.0, "accelerate")
	_add_hold_button(ui, "R", false, -112.0, -224.0, -12.0, -136.0, "reverse")
	_add_camera_button(ui)
	_add_headlight_button(ui)
	_refuel_button = _add_action_button(ui, "FUEL STATION ONLY", -36.0, 548.0, "refuel")
	_refuel_button.disabled = true
	_repair_button = _add_action_button(ui, "SERVICE ONLY", -36.0, 592.0, "repair")
	_repair_button.disabled = true
	_add_action_button(ui, "REAR CAM", -180.0, 456.0, "rear_camera")
	_add_action_button(ui, "HORN", -210.0, 180.0, "horn")
	_add_action_button(ui, "LEFT", -132.0, 180.0, "left")
	_add_action_button(ui, "HAZARD", -54.0, 180.0, "hazard")
	_add_action_button(ui, "RIGHT", 24.0, 180.0, "right")
	_add_action_button(ui, "WIPER", 102.0, 180.0, "wiper")
	_add_action_button(ui, "PARK", 180.0, 180.0, "park")
	_add_action_button(ui, "DOOR", -36.0, 226.0, "door")
	_add_action_button(ui, "SEAT +", -210.0, 272.0, "seat_up")
	_add_action_button(ui, "SEAT -", -132.0, 272.0, "seat_down")
	_add_action_button(ui, "DIPPER", -54.0, 272.0, "dipper")
	_add_action_button(ui, "HIGH/LOW", 24.0, 272.0, "beam")
	_add_action_button(ui, "PARK LIGHT", 102.0, 272.0, "parking_lights")
	_add_action_button(ui, "BOOT", 180.0, 272.0, "boot")
	_add_action_button(ui, "WHEEL HORN", -72.0, 318.0, "horn")
	_add_action_button(ui, "P", -160.0, 364.0, "gear_p")
	_add_action_button(ui, "R", -82.0, 364.0, "gear_r")
	_add_action_button(ui, "N", -4.0, 364.0, "gear_n")
	_add_action_button(ui, "D", 74.0, 364.0, "gear_d")
	_add_action_button(ui, "ENGINE", -72.0, 410.0, "engine")
	_add_action_button(ui, "CRUISE", 24.0, 410.0, "cruise")
	_add_action_button(ui, "SEAT BELT", 16.0, 364.0, "seatbelt")
	_cargo_straps_button = Button.new()
	_cargo_straps_button.name = "VehicleAction_CargoStraps"
	_cargo_straps_button.text = "SECURE CARGO"
	_cargo_straps_button.focus_mode = Control.FOCUS_NONE
	_cargo_straps_button.anchor_left = 0.5
	_cargo_straps_button.anchor_right = 0.5
	_cargo_straps_button.offset_left = -90.0
	_cargo_straps_button.offset_top = 548.0
	_cargo_straps_button.offset_right = -18.0
	_cargo_straps_button.offset_bottom = 588.0
	_cargo_straps_button.add_theme_font_size_override("font_size", 12)
	_cargo_straps_button.add_theme_color_override("font_color", Color.WHITE)
	_cargo_straps_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.04, 0.10, 0.17, 0.92)))
	_cargo_straps_button.pressed.connect(_on_vehicle_action.bind("cargo_straps", _cargo_straps_button))
	_cargo_straps_button.visible = false
	ui.add_child(_cargo_straps_button)
	if supports_trailer:
		_add_action_button(ui, "TRAILER", 16.0, 410.0, "trailer")
		_add_action_button(ui, "LANDING LEGS", 124.0, 410.0, "trailer_legs")
		_add_action_button(ui, "TRAILER DOORS", -90.0, 502.0, "trailer_doors")
	if supports_passenger_doors:
		_add_action_button(ui, "PASSENGER DOOR", -90.0, 456.0, "passenger_door")

func _build_extra_vehicle_controls() -> void:
	var horn_stream := AudioStreamGenerator.new()
	horn_stream.mix_rate = ENGINE_SAMPLE_RATE
	horn_stream.buffer_length = 0.22
	var horn_player := AudioStreamPlayer.new()
	horn_player.name = "VehicleHorn"
	horn_player.stream = horn_stream
	horn_player.volume_db = -2.0
	add_child(horn_player)
	horn_player.play()
	_horn_playback = horn_player.get_stream_playback() as AudioStreamGeneratorPlayback
	var amber := StandardMaterial3D.new()
	amber.albedo_color = Color(1.0, 0.42, 0.035)
	amber.emission_enabled = true
	amber.emission = Color(1.0, 0.28, 0.015)
	for pos in [Vector3(-0.95, 1.18, -2.46), Vector3(0.95, 1.18, -2.46), Vector3(-0.95, 1.18, 2.46), Vector3(0.95, 1.18, 2.46)]:
		var lamp := MeshInstance3D.new()
		var lamp_mesh := BoxMesh.new()
		lamp_mesh.size = Vector3(0.18, 0.14, 0.08)
		lamp.mesh = lamp_mesh
		lamp.position = pos
		lamp.material_override = amber
		lamp.visible = false
		add_child(lamp)
		_indicator_lights.append(lamp)
	_wiper_arm = MeshInstance3D.new()
	var wiper_mesh := BoxMesh.new()
	wiper_mesh.size = Vector3(1.45, 0.045, 0.07)
	_wiper_arm.mesh = wiper_mesh
	_wiper_arm.position = Vector3(0.0, 2.0, -2.48)
	add_child(_wiper_arm)
	_door_hinge = Node3D.new()
	_door_hinge.name = "InteractiveCabDoor"
	_door_hinge.position = Vector3(1.13, 1.2, -1.15)
	add_child(_door_hinge)
	var door_panel := MeshInstance3D.new()
	var door_mesh := BoxMesh.new()
	door_mesh.size = Vector3(0.08, 1.45, 0.92)
	door_panel.mesh = door_mesh
	door_panel.position.z = 0.46
	_door_hinge.add_child(door_panel)


func get_fuel_level() -> float:
	return _fuel_level

func get_vehicle_damage() -> int:
	return _vehicle_damage

func set_vehicle_damage(value: int) -> void:
	_vehicle_damage = clampi(value, 0, 100)

func set_service_station_available(available: bool, wallet_omr: int) -> void:
	_service_station_available = available
	if not is_instance_valid(_repair_button):
		return
	var cost := _vehicle_damage
	var safe_to_service := absf(_speed) <= 0.15 and _handbrake_on and not _engine_running
	_repair_button.disabled = not available or not safe_to_service or cost <= 0 or wallet_omr < cost
	if not available:
		_repair_button.text = "SERVICE DEPOT ONLY"
	elif not safe_to_service:
		_repair_button.text = "STOP + PARK + ENGINE OFF"
	elif cost <= 0:
		_repair_button.text = "NO REPAIRS NEEDED"
	elif wallet_omr < cost:
		_repair_button.text = "NEED OMR %d" % cost
	else:
		_repair_button.text = "REPAIR OMR %d" % cost

func complete_vehicle_repair() -> void:
	_vehicle_damage = 0
	if is_instance_valid(_repair_button):
		_repair_button.text = "VEHICLE REPAIRED"
		_repair_button.disabled = true


func set_fuel_level(value: float) -> void:
	_fuel_level = clampf(value, 0.0, 100.0)
	_update_fuel_display()


func _fuel_display_text() -> String:
	# Range is a moving-distance estimate based on the current distance fuel rate;
	# idling, payload, terrain and driving style can reduce the real range.
	var estimated_range_km := int(floor((_fuel_level / 0.0008) / 1000.0))
	return "FUEL  %02d%%  |  RANGE ~%d km" % [int(ceil(_fuel_level)), estimated_range_km]


func _update_fuel_display() -> void:
	if is_instance_valid(_fuel_label):
		_fuel_label.text = _fuel_display_text()
		_fuel_label.add_theme_color_override("font_color", Color(1.0, 0.34, 0.22) if _fuel_level <= 15.0 else Color(0.55, 0.9, 1.0))


func get_refuel_cost_omr() -> int:
	return int(ceil(maxf(0.0, 100.0 - _fuel_level) * 0.12))


func set_refuel_station_available(available: bool, wallet_omr: int) -> void:
	_refuel_station_available = available
	if not is_instance_valid(_refuel_button):
		return
	var cost := get_refuel_cost_omr()
	var can_pay := wallet_omr >= cost
	var safe_to_refuel := absf(_speed) <= 0.15 and _handbrake_on and not _engine_running
	_refuel_button.disabled = not available or not safe_to_refuel or not can_pay or cost <= 0
	if not available:
		_refuel_button.text = "FUEL STATION ONLY"
	elif _engine_running:
		_refuel_button.text = "ENGINE OFF TO REFUEL"
	elif absf(_speed) > 0.15 or not _handbrake_on:
		_refuel_button.text = "STOP + PARK TO REFUEL"
	elif cost <= 0:
		_refuel_button.text = "TANK FULL"
	elif not can_pay:
		_refuel_button.text = "NEED OMR %d" % cost
	else:
		_refuel_button.text = "REFUEL OMR %d" % cost


func complete_refuel() -> void:
	set_fuel_level(100.0)
	if is_instance_valid(_refuel_button):
		_refuel_button.text = "TANK FULL"
		_refuel_button.disabled = true

func _add_action_button(parent: Control, label: String, x: float, y: float, action: String) -> Button:
	var button := Button.new()
	button.name = "VehicleAction_" + action
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.anchor_left = 0.5
	button.anchor_right = 0.5
	button.offset_left = x
	button.offset_top = y
	button.offset_right = x + 72.0
	button.offset_bottom = y + 40.0
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.04, 0.10, 0.17, 0.92)))
	button.pressed.connect(_on_vehicle_action.bind(action, button))
	parent.add_child(button)
	return button

func _on_vehicle_action(action: String, button: Button) -> void:
	match action:
		"repair":
			if not _service_station_available or absf(_speed) > 0.15 or not _handbrake_on or _engine_running:
				button.text = "STOP + PARK + ENGINE OFF"
				return
			if _vehicle_damage <= 0:
				button.text = "NO REPAIRS NEEDED"
				return
			repair_requested.emit(_vehicle_damage)
		"refuel":
			if not _refuel_station_available:
				button.text = "FUEL STATION ONLY"
				return
			if absf(_speed) > 0.15 or not _handbrake_on:
				button.text = "STOP + PARK FIRST"
				return
			if _engine_running:
				button.text = "ENGINE OFF TO REFUEL"
				return
			var refuel_cost := get_refuel_cost_omr()
			if refuel_cost <= 0:
				button.text = "TANK FULL"
				return
			refuel_requested.emit(refuel_cost)
		"cruise":
			if _cruise_control_on:
				_cruise_control_on = false
				button.text = "CRUISE: OFF"
			else:
				if not _engine_running or _fuel_level <= 0.0 or not _seatbelt_fastened or _gear_mode != "D" or _speed < 4.0 or _brake_input > 0.01:
					button.text = "CRUISE: DRIVE 15+ KM/H"
					return
				_cruise_target_speed = _speed
				_cruise_control_on = true
				button.text = "CRUISE: %d KM/H" % int(round(_cruise_target_speed * 3.6))
		"horn":
			_horn_frames_left = 6600
			_horn_phase = 0.0
		"gear_p":
			_set_gear("P")
		"gear_r":
			_set_gear("R")
		"gear_n":
			_set_gear("N")
		"gear_d":
			_set_gear("D")
		"rear_camera":
			_toggle_rear_camera(button)
		"seatbelt":
			_seatbelt_fastened = not _seatbelt_fastened
			button.text = "BELT: FASTENED" if _seatbelt_fastened else "SEAT BELT"
		"cargo_straps":
			if not _cargo_loaded:
				button.text = "NO CARGO"
				return
			# Cargo straps must be handled from a stationary, parked vehicle
			# with the engine off; never allow securing or releasing while moving.
			if absf(_speed) > 0.15 or not _handbrake_on or _engine_running:
				button.text = "STOP + PARK + ENGINE OFF"
				return
			_cargo_secured = not _cargo_secured
			button.text = "LOAD SECURED" if _cargo_secured else "SECURE CARGO"
			_update_cargo_strap_visuals()
		"engine":
			if _engine_running:
				if absf(_speed) > 0.15:
					button.text = "STOP BEFORE ENGINE OFF"
					return
				_engine_running = false
				_throttle_input = 0.0
				_reverse_input = 0.0
				button.text = "ENGINE: OFF"
			else:
				if _fuel_level <= 0.0:
					button.text = "NO FUEL - REFUEL"
					return
				if absf(_speed) > 0.15 or not _handbrake_on:
					button.text = "STOP + PARK TO START"
					return
				if _gear_mode != "P" and _gear_mode != "N":
					button.text = "SELECT P OR N"
					return
				_engine_running = true
				button.text = "ENGINE: ON"
		"trailer":
			_toggle_trailer_coupling(button)
		"trailer_legs":
			_toggle_trailer_legs(button)
		"trailer_doors":
			_toggle_trailer_doors(button)
		"left":
			_left_indicator_on = not _left_indicator_on
			_indicator_elapsed = 0.0
			if _left_indicator_on:
				_right_indicator_on = false
				_hazard_on = false
		"right":
			_right_indicator_on = not _right_indicator_on
			_indicator_elapsed = 0.0
			if _right_indicator_on:
				_left_indicator_on = false
				_hazard_on = false
		"hazard":
			_hazard_on = not _hazard_on
			_indicator_elapsed = 0.0
			if _hazard_on:
				_left_indicator_on = false
				_right_indicator_on = false
		"wiper":
			_wipers_on = not _wipers_on
			button.text = "WIPER: ON" if _wipers_on else "WIPER"
		"park":
			_handbrake_on = not _handbrake_on
			button.text = "PARK: ON" if _handbrake_on else "PARK"
		"door":
			if not _door_open and (absf(_speed) > 0.15 or not _handbrake_on):
				button.text = "STOP + PARK FIRST"
				return
			if not _door_open and _engine_running:
				button.text = "ENGINE OFF TO OPEN"
				return
			_door_open = not _door_open
			_door_hinge.rotation.y = deg_to_rad(-68.0 if _door_open else 0.0)
			button.text = "CLOSE" if _door_open else "DOOR"
		"passenger_door":
			if not _passenger_doors_open and (absf(_speed) > 0.15 or not _handbrake_on):
				button.text = "STOP + PARK FIRST"
				return
			if not _passenger_doors_open and _engine_running:
				button.text = "ENGINE OFF TO BOARD"
				return
			_passenger_doors_open = not _passenger_doors_open
			_passenger_door_hinge.rotation.y = deg_to_rad(-82.0 if _passenger_doors_open else 0.0)
			button.text = "CLOSE PASSENGER" if _passenger_doors_open else "PASSENGER DOOR"
		"seat_up":
			_adjust_seat(0.08)
		"seat_down":
			_adjust_seat(-0.08)
		"dipper":
			_high_beam_on = not _high_beam_on
			_apply_beam_mode()
			button.text = "DIPPER: ON" if _high_beam_on else "DIPPER"
		"beam":
			_high_beam_on = not _high_beam_on
			_apply_beam_mode()
			button.text = "HIGH BEAM" if _high_beam_on else "LOW BEAM"
		"parking_lights":
			_parking_lights_on = not _parking_lights_on
			_apply_parking_lights()
			button.text = "PARK: ON" if _parking_lights_on else "PARK LIGHT"
		"boot":
			if not _boot_open and (absf(_speed) > 0.15 or not _handbrake_on):
				button.text = "STOP + PARK FIRST"
				return
			if not _boot_open and _engine_running:
				button.text = "ENGINE OFF TO OPEN"
				return
			_boot_open = not _boot_open
			var payload := get_node_or_null("CargoPayload") as Node3D
			if is_instance_valid(payload):
				payload.visible = payload.visible or _boot_open
			button.text = "BOOT: OPEN" if _boot_open else "BOOT"
	_update_indicator_lights()

func _toggle_rear_camera(button: Button = null) -> void:
	if not is_instance_valid(_rear_camera):
		return
	_rear_camera_active = not _rear_camera_active
	if _rear_camera_active:
		_camera_before_rear = get_viewport().get_camera_3d()
		_rear_camera.make_current()
		if is_instance_valid(button):
			button.text = "REAR CAM: ON"
	else:
		if is_instance_valid(_camera_before_rear):
			_camera_before_rear.make_current()
		else:
			_exterior_camera.make_current()
		if is_instance_valid(button):
			button.text = "REAR CAM"

func _initialize_trailer_system() -> void:
	if not supports_trailer:
		return
	_trailer_assembly = get_node_or_null("TrailerAssembly") as Node3D
	if is_instance_valid(_trailer_assembly):
		_trailer_attached = true
		_trailer_home_transform = _trailer_assembly.transform

func _toggle_trailer_coupling(button: Button) -> void:
	if not is_instance_valid(_trailer_assembly):
		return
	if absf(_speed) > 0.15 or not _handbrake_on:
		button.text = "STOP + PARK FIRST"
		return
	if _trailer_attached:
		if not _trailer_legs_down:
			button.text = "LOWER LEGS FIRST"
			return
		_trailer_assembly.reparent(get_parent(), true)
		_trailer_attached = false
		button.text = "COUPLED: NO"
	else:
		if global_position.distance_to(_trailer_assembly.global_position) > 14.0:
			button.text = "TRAILER TOO FAR"
			return
		_trailer_assembly.reparent(self, false)
		_trailer_assembly.transform = _trailer_home_transform
		_trailer_attached = true
		_trailer_legs_down = false
		_set_landing_leg_positions()
		button.text = "TRAILER: ATTACHED"

func _toggle_trailer_doors(button: Button) -> void:
	if not is_instance_valid(_trailer_assembly):
		return
	if absf(_speed) > 0.15 or not _handbrake_on:
		button.text = "STOP + PARK FIRST"
		return
	if not _trailer_doors_open and _engine_running:
		button.text = "ENGINE OFF TO OPEN"
		return
	_trailer_doors_open = not _trailer_doors_open
	var left_door := _trailer_assembly.get_node_or_null("RearDoorLeft") as Node3D
	var right_door := _trailer_assembly.get_node_or_null("RearDoorRight") as Node3D
	if is_instance_valid(left_door):
		left_door.rotation.y = deg_to_rad(82.0 if _trailer_doors_open else 0.0)
	if is_instance_valid(right_door):
		right_door.rotation.y = deg_to_rad(-82.0 if _trailer_doors_open else 0.0)
	button.text = "CLOSE TRAILER" if _trailer_doors_open else "TRAILER DOORS"

func _toggle_trailer_legs(button: Button) -> void:
	if not is_instance_valid(_trailer_assembly):
		return
	if _trailer_attached and not _trailer_legs_down:
		if absf(_speed) > 0.15 or not _handbrake_on:
			button.text = "STOP + PARK FIRST"
			return
		_trailer_legs_down = true
	elif not _trailer_attached:
		_trailer_legs_down = not _trailer_legs_down
	else:
		_trailer_legs_down = false
	_set_landing_leg_positions()
	button.text = "LEGS: DOWN" if _trailer_legs_down else "LANDING LEGS"

func _set_landing_leg_positions() -> void:
	if not is_instance_valid(_trailer_assembly):
		return
	for child in _trailer_assembly.get_children():
		if child is Node3D and String(child.name).begins_with("LandingLeg_"):
			child.position.y = 0.02 if _trailer_legs_down else 0.24
		elif child is Node3D and String(child.name).begins_with("LandingFoot_"):
			child.position.y = -0.12 if _trailer_legs_down else -0.08

func _update_automatic_transmission(throttle: float, delta: float) -> void:
	if not _engine_running:
		_engine_rpm = 0.0
		return
	var speed := absf(_speed)
	var shift_thresholds: Array[float] = [0.0, 4.2, 7.8, 11.8, 15.8, 20.0]
	var target_gear := 1
	for index in range(shift_thresholds.size()):
		if speed >= shift_thresholds[index]:
			target_gear = index + 1
	# Add hysteresis so the gearbox does not hunt between ratios at a boundary.
	if target_gear > _automatic_gear and speed < shift_thresholds[target_gear - 1] + 0.8:
		target_gear = _automatic_gear
	elif target_gear < _automatic_gear and speed > shift_thresholds[_automatic_gear - 1] - 0.8:
		target_gear = _automatic_gear
	_automatic_gear = clampi(target_gear, 1, 6)
	var gear_lower_speed := shift_thresholds[_automatic_gear - 1]
	var gear_upper_speed := 25.0 if _automatic_gear == 6 else shift_thresholds[_automatic_gear] + 0.8
	var ratio := clampf((speed - gear_lower_speed) / maxf(gear_upper_speed - gear_lower_speed, 0.1), 0.0, 1.0)
	var target_rpm := 850.0 + ratio * 1750.0 + throttle * 220.0
	if speed < 0.35:
		target_rpm = 720.0 + throttle * 1050.0
	_engine_rpm = move_toward(_engine_rpm, target_rpm, delta * (3200.0 if target_rpm > _engine_rpm else 2200.0))

func _set_gear(next_gear: String) -> void:
	if absf(_speed) > 0.28:
		return
	_gear_mode = next_gear
	if next_gear == "P":
		_handbrake_on = true
		_reverse_input = 0.0
		_throttle_input = 0.0
	elif next_gear == "N":
		_reverse_input = 0.0
		_throttle_input = 0.0
	if is_instance_valid(_gear_label):
		_gear_label.text = _gear_mode + ("  •  ON" if _engine_running else "  •  OFF")

func _build_passenger_door_controls() -> void:
	if not supports_passenger_doors:
		return
	_passenger_door_hinge = Node3D.new()
	_passenger_door_hinge.name = "PassengerEntryDoorHinge"
	_passenger_door_hinge.position = Vector3(1.28, 1.35, -3.35)
	add_child(_passenger_door_hinge)
	var panel := MeshInstance3D.new()
	panel.name = "PassengerEntryDoor"
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(0.075, 1.9, 0.92)
	panel.mesh = panel_mesh
	panel.position = Vector3(0.0, 0.0, 0.46)
	var panel_material := StandardMaterial3D.new()
	panel_material.albedo_color = Color(0.12, 0.18, 0.22)
	panel_material.metallic = 0.28
	panel.material_override = panel_material
	_passenger_door_hinge.add_child(panel)

func can_board_passengers() -> bool:
	return supports_passenger_doors and _passenger_doors_open and _handbrake_on and not _engine_running and absf(_speed) < 0.25


func can_handle_cargo() -> bool:
	return _handbrake_on and not _engine_running and absf(_speed) < 0.25


func can_service_vehicle() -> bool:
	return _handbrake_on and absf(_speed) <= 0.15 and not _engine_running

func _adjust_seat(amount: float) -> void:
	_seat_adjustment = clampf(_seat_adjustment + amount, -0.24, 0.24)
	if is_instance_valid(_cockpit_camera):
		_cockpit_camera.position.y = cockpit_camera_position.y + _seat_adjustment

func _apply_beam_mode() -> void:
	for beam in _headlight_lights:
		if is_instance_valid(beam):
			beam.light_energy = 2.0 if _high_beam_on else 1.15
			beam.spot_range = 42.0 if _high_beam_on else 25.0
			beam.spot_angle = 48.0 if _high_beam_on else 38.0

func _apply_parking_lights() -> void:
	for lamp in _headlight_meshes:
		if is_instance_valid(lamp):
			lamp.visible = _headlights_on or _parking_lights_on
	_update_rear_lighting()

func _update_rear_lighting() -> void:
	# Rear running lamps stay visible; braking increases their intensity.
	var braking := _brake_input > 0.05 or _traffic_signal_brake > 0.05
	if is_instance_valid(_rear_lamp_material):
		_rear_lamp_material.emission_energy_multiplier = 3.0 if braking else (1.25 if _parking_lights_on else 0.8)
	for tail in get_children():
		if tail is MeshInstance3D and String(tail.name) == "RearTailLamp":
			tail.visible = true
	var reverse_active := _engine_running and _gear_mode == "R"
	for lamp in _reverse_lamp_meshes:
		if is_instance_valid(lamp):
			lamp.visible = reverse_active

func _update_indicator_lights() -> void:
	for i in range(_indicator_lights.size()):
		var active := _hazard_on or (_left_indicator_on and (i == 0 or i == 2)) or (_right_indicator_on and (i == 1 or i == 3))
		_indicator_lights[i].visible = active and _indicator_visible
func _add_camera_button(parent: Control) -> void:
	var button := Button.new()
	button.name = "CameraToggle"
	button.text = "VIEW: CHASE"
	_camera_button = button
	button.focus_mode = Control.FOCUS_NONE
	button.anchor_left = 0.5
	button.anchor_right = 0.5
	button.anchor_top = 0.0
	button.anchor_bottom = 0.0
	button.offset_left = -82.0
	button.offset_top = 22.0
	button.offset_right = 82.0
	button.offset_bottom = 68.0
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.04, 0.10, 0.17, 0.9)))
	button.pressed.connect(_toggle_camera)
	parent.add_child(button)

func _add_headlight_button(parent: Control) -> void:
	var button := Button.new()
	button.name = "HeadlightToggle"
	button.text = "LIGHTS: ON"
	_headlight_button = button
	button.focus_mode = Control.FOCUS_NONE
	button.anchor_left = 0.5
	button.anchor_right = 0.5
	button.anchor_top = 0.0
	button.anchor_bottom = 0.0
	button.offset_left = -70.0
	button.offset_top = 126.0
	button.offset_right = 70.0
	button.offset_bottom = 170.0
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.04, 0.10, 0.17, 0.9)))
	button.pressed.connect(_toggle_headlights)
	parent.add_child(button)

func _add_hold_button(parent: Control, label: String, left_side: bool, left: float, top: float, right: float, bottom: float, control_name: String) -> void:
	var button := Button.new()
	button.name = control_name
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.04, 0.10, 0.17, 0.84)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.08, 0.24, 0.36, 0.94)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.0, 0.48, 0.68, 0.98)))
	button.anchor_left = 0.0 if left_side else 1.0
	button.anchor_right = 0.0 if left_side else 1.0
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = left
	button.offset_top = top
	button.offset_right = right
	button.offset_bottom = bottom
	button.button_down.connect(_on_control_down.bind(control_name))
	button.button_up.connect(_on_control_up.bind(control_name))
	parent.add_child(button)

func _make_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.25, 0.75, 0.95, 0.9)
	return style

func _on_control_down(control_name: String) -> void:
	match control_name:
		"accelerate":
			_throttle_input = 1.0
		"brake":
			_brake_input = 1.0
		"reverse":
			_reverse_input = 1.0
		"steer_left":
			_steer_left_held = true
			_update_steering_input()
		"steer_right":
			_steer_right_held = true
			_update_steering_input()

func _on_control_up(control_name: String) -> void:
	match control_name:
		"accelerate":
			_throttle_input = 0.0
		"brake":
			_brake_input = 0.0
		"reverse":
			_reverse_input = 0.0
		"steer_left":
			_steer_left_held = false
			_update_steering_input()
		"steer_right":
			_steer_right_held = false
			_update_steering_input()

func _update_steering_input() -> void:
	_steering_input = float(int(_steer_right_held) - int(_steer_left_held))

func _add_cockpit_steering_wheel(location: Vector3) -> void:
	var wheel := MeshInstance3D.new()
	wheel.name = "CockpitSteeringWheel"
	_steering_wheel_mesh = wheel
	var ring := TorusMesh.new()
	ring.inner_radius = 0.205
	ring.outer_radius = 0.255
	wheel.mesh = ring
	wheel.rotation_degrees.x = 90.0
	wheel.position = location
	var wheel_material := StandardMaterial3D.new()
	wheel_material.albedo_color = Color(0.055, 0.065, 0.075)
	wheel_material.metallic = 0.22
	wheel.material_override = wheel_material
	add_child(wheel)
	var hub := MeshInstance3D.new()
	hub.name = "SteeringWheelHub"
	var hub_mesh := CylinderMesh.new()
	hub_mesh.top_radius = 0.075
	hub_mesh.bottom_radius = 0.075
	hub_mesh.height = 0.09
	hub.mesh = hub_mesh
	hub.rotation_degrees.x = 90.0
	hub.position = location + Vector3(0.0, 0.0, -0.025)
	hub.material_override = wheel_material
	add_child(hub)
	for spoke_index in range(3):
		var spoke := MeshInstance3D.new()
		spoke.name = "SteeringWheelSpoke_%d" % spoke_index
		var spoke_mesh := BoxMesh.new()
		spoke_mesh.size = Vector3(0.045, 0.22, 0.055)
		spoke.mesh = spoke_mesh
		spoke.position = location + Vector3(0.0, -0.07, 0.0)
		spoke.rotation.z = TAU * float(spoke_index) / 3.0
		spoke.material_override = wheel_material
		add_child(spoke)


func set_visible_passenger_manifest(passenger_count: int) -> void:
	_visible_passenger_count = clampi(passenger_count, 0, PASSENGER_SEAT_CAPACITY)
	var old_manifest := get_node_or_null("PassengerManifest")
	if is_instance_valid(old_manifest):
		old_manifest.queue_free()
	if _visible_passenger_count <= 0:
		return
	var manifest := Node3D.new()
	manifest.name = "PassengerManifest"
	add_child(manifest)
	var shirt_colors: Array[Color] = [
		Color(0.12, 0.32, 0.62), Color(0.62, 0.18, 0.12),
		Color(0.16, 0.46, 0.28), Color(0.58, 0.42, 0.18)
	]
	for passenger_index in range(_visible_passenger_count):
		var seat_row := int(passenger_index / 2)
		var seat_side := -0.66 if passenger_index % 2 == 0 else 0.66
		var seat_z := -2.65 + float(seat_row) * 1.38
		var occupant := Node3D.new()
		occupant.name = "SeatedPassenger_%02d" % (passenger_index + 1)
		occupant.position = Vector3(seat_side, 1.24, seat_z - 0.04)
		manifest.add_child(occupant)
		var torso := MeshInstance3D.new()
		var torso_mesh := CapsuleMesh.new()
		torso_mesh.radius = 0.16
		torso_mesh.height = 0.58
		torso.mesh = torso_mesh
		torso.position.y = 0.36
		var shirt := StandardMaterial3D.new()
		shirt.albedo_color = shirt_colors[passenger_index % shirt_colors.size()]
		torso.material_override = shirt
		occupant.add_child(torso)
		var head := MeshInstance3D.new()
		var head_mesh := SphereMesh.new()
		head_mesh.radius = 0.12
		head_mesh.height = 0.24
		head.mesh = head_mesh
		head.position.y = 0.76
		var skin := StandardMaterial3D.new()
		skin.albedo_color = Color(0.66, 0.48, 0.34)
		head.material_override = skin
		occupant.add_child(head)



func get_speed_kmh() -> float:
	return absf(_speed) * 3.6
