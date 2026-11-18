extends CharacterBody3D

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
var _throttle_input: float = 0.0
var _brake_input: float = 0.0
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
var _engine_temperature := 22.0
var _cargo_loaded := false
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
var _hazard_on := false
var _left_indicator_on := false
var _right_indicator_on := false
var _indicator_clock := 0.0
var _indicator_visible := true
var _indicator_lights: Array[MeshInstance3D] = []
var _wipers_on := false
var _wiper_arm: MeshInstance3D
var _door_open := false
var _door_hinge: Node3D
var _passenger_door_hinge: Node3D
var _passenger_doors_open := false
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
		var frequency := (42.0 + absf(_speed) * 5.0 + _throttle_input * 24.0) if _engine_running else 0.0
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
		if _indicator_clock >= 0.45:
			_indicator_clock = 0.0
			_indicator_visible = not _indicator_visible
		_update_indicator_lights()
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
	var trailer_ready := not (supports_trailer and _trailer_attached and _trailer_legs_down)
	var throttle := _throttle_input if _engine_running and _gear_mode == "D" and trailer_ready else 0.0
	var brake := _brake_input
	var reverse := _reverse_input if _engine_running and _gear_mode == "R" and trailer_ready else 0.0
	var steering := _steering_input

	if not OS.has_feature("android"):
		throttle = Input.get_action_strength("ui_up")
		brake = Input.get_action_strength("ui_down")
		steering = Input.get_axis("ui_left", "ui_right")
		reverse = 0.0

	throttle = clampf(throttle, 0.0, 1.0)
	brake = clampf(brake, 0.0, 1.0)
	reverse = clampf(reverse, 0.0, 1.0)
	var speed_ratio := clampf(absf(_speed) / maxf(max_forward_speed, 0.1), 0.0, 1.0)

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
		_speed = move_toward(_speed, max_forward_speed * (0.90 if _cargo_loaded else 1.0), acceleration * torque_factor * payload_factor * throttle * delta)
	else:
		# Engine braking plus speed-dependent aerodynamic/rolling drag.
		var drag := rolling_resistance + (absf(_speed) * absf(_speed) * 0.018)
		_speed = move_toward(_speed, 0.0, drag * delta)

	# Steering input eases in and out rather than snapping instantly.
	_steering_current = move_toward(_steering_current, steering, steering_response * delta)

	# Steering authority fades at highway speed to avoid unrealistically sharp turns.
	if absf(_speed) > 0.2:
		var direction := 1.0 if _speed >= 0.0 else -1.0
		var steering_authority := lerpf(1.0, 0.38, speed_ratio)
		rotate_y(-_steering_current * steering_speed * _steering_multiplier * steering_authority * delta * direction)

	# Preserve a little lateral momentum, then let tire-grip approximation settle it.
	# This creates mild body inertia without pretending to be full wheel physics.
	var forward := -global_transform.basis.z
	var previous_horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var lateral_velocity := previous_horizontal - forward * previous_horizontal.dot(forward)
	lateral_velocity = lateral_velocity.move_toward(Vector3.ZERO, lateral_grip * delta)
	velocity = forward * _speed + lateral_velocity
	move_and_slide()

	if is_instance_valid(_speed_label):
		_speed_label.text = "%03d km/h" % int(absf(_speed) * 3.6)
	if is_instance_valid(_gear_label):
		_gear_label.text = _gear_mode + ("  •  OFF" if not _engine_running else "  •  ON")
	var rpm_value := 0.0
	if _engine_running:
		rpm_value = 650.0 + absf(_speed) * 48.0 + _throttle_input * 720.0
		_engine_temperature = move_toward(_engine_temperature, 90.0, delta * (0.12 + _throttle_input * 0.24))
	else:
		_engine_temperature = move_toward(_engine_temperature, 22.0, delta * 0.45)
	if is_instance_valid(_rpm_label):
		_rpm_label.text = "RPM  %04d    TEMP  %02d°C" % [int(minf(rpm_value, 2800.0)), int(_engine_temperature)]
	if is_instance_valid(_vehicle_status_label):
		var status_parts: Array[String] = []
		if _handbrake_on:
			status_parts.append("PARK BRAKE")
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
		if _cargo_loaded:
			status_parts.append("CARGO ONBOARD")
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


func set_steering_sensitivity(value: float) -> void:
	_steering_multiplier = clampf(value, 0.5, 1.8)

func set_cargo_payload(cargo_type: int, loaded: bool) -> void:
	_cargo_loaded = loaded
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

	_add_hold_button(ui, "◀", true, 24.0, -124.0, 112.0, -24.0, "steer_left")
	_add_hold_button(ui, "▶", true, 132.0, -124.0, 220.0, -24.0, "steer_right")
	_add_hold_button(ui, "BRAKE", false, -224.0, -124.0, -124.0, -24.0, "brake")
	_add_hold_button(ui, "GAS", false, -112.0, -124.0, -12.0, -24.0, "accelerate")
	_add_hold_button(ui, "R", false, -112.0, -224.0, -12.0, -136.0, "reverse")
	_add_camera_button(ui)
	_add_headlight_button(ui)
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

func _add_action_button(parent: Control, label: String, x: float, y: float, action: String) -> void:
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

func _on_vehicle_action(action: String, button: Button) -> void:
	match action:
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
		"engine":
			_engine_running = not _engine_running
			button.text = "ENGINE: ON" if _engine_running else "ENGINE: OFF"
			if not _engine_running:
				_throttle_input = 0.0
				_reverse_input = 0.0
		"trailer":
			_toggle_trailer_coupling(button)
		"trailer_legs":
			_toggle_trailer_legs(button)
		"trailer_doors":
			_toggle_trailer_doors(button)
		"left":
			_left_indicator_on = not _left_indicator_on
			if _left_indicator_on:
				_right_indicator_on = false
				_hazard_on = false
		"right":
			_right_indicator_on = not _right_indicator_on
			if _right_indicator_on:
				_left_indicator_on = false
				_hazard_on = false
		"hazard":
			_hazard_on = not _hazard_on
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
			_door_open = not _door_open
			_door_hinge.rotation.y = deg_to_rad(-68.0 if _door_open else 0.0)
			button.text = "CLOSE" if _door_open else "DOOR"
		"passenger_door":
			if not _passenger_doors_open and (absf(_speed) > 0.15 or not _handbrake_on):
				button.text = "STOP + PARK FIRST"
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
	return supports_passenger_doors and _passenger_doors_open and _handbrake_on and absf(_speed) < 0.25

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
	for tail in get_children():
		if tail is MeshInstance3D and String(tail.name) == "RearTailLamp":
			tail.visible = _parking_lights_on or _brake_input > 0.0

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
