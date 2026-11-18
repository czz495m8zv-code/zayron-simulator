extends CharacterBody3D

@export var acceleration: float = 7.0
@export var braking: float = 12.0
@export var max_speed: float = 22.0
@export var reverse_speed: float = 7.0
@export var steering_speed: float = 1.25

var _speed: float = 0.0

func _ready() -> void:
	_build_truck()
	_build_camera()

func _physics_process(delta: float) -> void:
	var throttle := Input.get_axis("ui_down", "ui_up")
	var steering := Input.get_axis("ui_left", "ui_right")

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
