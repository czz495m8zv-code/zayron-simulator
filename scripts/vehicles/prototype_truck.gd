extends CharacterBody3D

@export var acceleration: float = 7.0
@export var braking: float = 12.0
@export var max_speed: float = 22.0
@export var reverse_speed: float = 7.0
@export var steering_speed: float = 1.25

var _speed: float = 0.0
var _throttle_input: float = 0.0
var _steering_input: float = 0.0
var _speed_label: Label

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
	if is_instance_valid(_speed_label):
		_speed_label.text = "SPEED  %03d km/h" % int(absf(_speed) * 3.6)

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
	layer.layer = 10
	add_child(layer)

	var ui := Control.new()
	ui.name = "TouchUI"
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(ui)

	_speed_label = Label.new()
	_speed_label.name = "SpeedDisplay"
	_speed_label.text = "SPEED  000 km/h"
	_speed_label.position = Vector2(24.0, 24.0)
	_speed_label.add_theme_font_size_override("font_size", 26)
	_speed_label.add_theme_color_override("font_color", Color.WHITE)
	_speed_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_speed_label.add_theme_constant_override("shadow_offset_x", 2)
	_speed_label.add_theme_constant_override("shadow_offset_y", 2)
	ui.add_child(_speed_label)

	_add_hold_button(ui, "◀", true, 24.0, -124.0, 112.0, -24.0, "steer_left")
	_add_hold_button(ui, "▶", true, 132.0, -124.0, 220.0, -24.0, "steer_right")
	_add_hold_button(ui, "BRAKE", false, -224.0, -124.0, -124.0, -24.0, "brake")
	_add_hold_button(ui, "GAS", false, -112.0, -124.0, -12.0, -24.0, "accelerate")

func _add_hold_button(parent: Control, label: String, left_side: bool, left: float, top: float, right: float, bottom: float, control_name: String) -> void:
	var button := Button.new()
	button.name = control_name
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.04, 0.10, 0.17, 0.82)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.08, 0.24, 0.36, 0.94)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.0, 0.55, 0.75, 0.98)))
	if left_side:
		button.anchor_left = 0.0
		button.anchor_right = 0.0
	else:
		button.anchor_left = 1.0
		button.anchor_right = 1.0
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
