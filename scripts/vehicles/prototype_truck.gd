extends CharacterBody3D

@export var acceleration: float = 7.0
@export var braking: float = 12.0
@export var max_speed: float = 22.0
@export var reverse_speed: float = 7.0
@export var steering_speed: float = 1.25

var _speed: float = 0.0
var _throttle_input: float = 0.0
var _steering_input: float = 0.0

func _ready() -> void:
	_build_truck()
	_build_camera()
	_build_mobile_controls()

func _physics_process(delta: float) -> void:
	var throttle := _throttle_input
	var steering := _steering_input

	# Keep keyboard controls available for desktop testing.
	if not OS.has_feature("android"):
		throttle = Input.get_axis("ui_down", "ui_up")
		steering = Input.get_axis("ui_left", "ui_right")

	if throttle > 0.0:
		_speed = move_toward(_speed, max_speed, acceleration * delta)
	elif throttle < 0.0:
		_speed = move_toward(_speed, -reverse_speed, braking * delta)
	else:
		_speed = move_toward(_speed, 0.0, braking * 0.35 * delta)

	if absf(_speed) > 0.15:
		var direction := 1.0 if _speed >= 0.0 else -1.0
		rotate_y(-steering * steering_speed * delta * direction)

	velocity = -global_transform.basis.z * _speed
	move_and_slide()

func _build_truck() -> void:
	var body_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 2.0, 4.8)
	body_shape.shape = box
	body_shape.position.y = 1.0
	add_child(body_shape)

	var body_mesh := MeshInstance3D.new()
	var body := BoxMesh.new()
	body.size = box.size
	body_mesh.mesh = body
	body_mesh.position.y = 1.0
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.82, 0.22, 0.08)
	body_mesh.material_override = paint
	add_child(body_mesh)

	var cabin_mesh := MeshInstance3D.new()
	var cabin := BoxMesh.new()
	cabin.size = Vector3(2.0, 1.5, 1.8)
	cabin_mesh.mesh = cabin
	cabin_mesh.position = Vector3(0.0, 2.65, -1.0)
	cabin_mesh.material_override = paint
	add_child(cabin_mesh)

func _build_camera() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 5.0, 10.0)
	camera.rotation_degrees = Vector3(-18.0, 0.0, 0.0)
	camera.current = true
	add_child(camera)

func _build_mobile_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "MobileControls"
	add_child(layer)

	var ui := Control.new()
	ui.name = "TouchUI"
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)

	_add_hold_button(ui, "◀", Vector2(28.0, -118.0), Vector2(90.0, 90.0), "steer_left")
	_add_hold_button(ui, "▶", Vector2(128.0, -118.0), Vector2(90.0, 90.0), "steer_right")
	_add_hold_button(ui, "BRAKE", Vector2(-218.0, -118.0), Vector2(90.0, 90.0), "brake")
	_add_hold_button(ui, "GAS", Vector2(-118.0, -118.0), Vector2(90.0, 90.0), "accelerate")

func _add_hold_button(parent: Control, label: String, offset: Vector2, button_size: Vector2, control_name: String) -> void:
	var button := Button.new()
	button.name = control_name
	button.text = label
	button.custom_minimum_size = button_size
	button.size = button_size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.modulate = Color(1.0, 1.0, 1.0, 0.88)

	if control_name == "steer_left" or control_name == "steer_right":
		button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		button.position = offset
	else:
		button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		button.position = offset

	button.button_down.connect(_on_control_down.bind(control_name))
	button.button_up.connect(_on_control_up.bind(control_name))
	parent.add_child(button)

func _on_control_down(control_name: String) -> void:
	match control_name:
		"accelerate":
			_throttle_input = 1.0
		"brake":
			_throttle_input = -1.0
		"steer_left":
			_steering_input = -1.0
		"steer_right":
			_steering_input = 1.0

func _on_control_up(control_name: String) -> void:
	match control_name:
		"accelerate", "brake":
			_throttle_input = 0.0
		"steer_left", "steer_right":
			_steering_input = 0.0
