extends Node3D

const FLEET_SCENES: Array[PackedScene] = [
	preload("res://scenes/vehicles/prototype_truck.tscn"),
	preload("res://scenes/vehicles/premium_semi.tscn"),
	preload("res://scenes/vehicles/royal_red_semi.tscn"),
	preload("res://scenes/vehicles/prototype_bus.tscn"),
	preload("res://scenes/vehicles/luxury_coach.tscn"),
	preload("res://scenes/vehicles/vip_silver_coach.tscn")
]
const FLEET_NAMES: Array[String] = [
	"STARTER TRUCK",
	"PREMIUM BLUE SEMI",
	"ROYAL RED SEMI",
	"OMAN CITY BUS",
	"LUXURY COACH",
	"VIP SILVER COACH"
]

var _active_vehicle: Node3D
var _active_vehicle_index: int = -1
var _vehicle_fuel_levels: Array[float] = [100.0, 100.0, 100.0, 100.0, 100.0, 100.0]
var _vehicle_damage_levels: Array[int] = [0, 0, 0, 0, 0, 0]
var _selected_vehicle: int = 0
var _vehicle_button: Button
var _mission_label: Label
var _junction_status_label: Label
var _speed_limit_status_label: Label
var _road_position_status_label: Label
var _pedestrian_warning_label: Label
var _stop_line_warning_label: Label
var _mission_complete: bool = false
var _mission_target := Vector3(0.0, 0.0, -82.0)
var _delivery_count: int = 0
var _cash_balance: int = 0
var _cash_label: Label
var _restart_button: Button
var _traffic_vehicles: Array[Node3D] = []
var _traffic_vehicle_speeds: Array[float] = []
var _traffic_current_speeds: Array[float] = []
var _traffic_signal_lamps: Array[MeshInstance3D] = []
var _traffic_signal_materials: Array[StandardMaterial3D] = []
var _traffic_signal_countdown_labels: Array[Label3D] = []
var _traffic_signal_clock: float = 0.0
var _side_road_traffic_vehicle: Node3D
var _side_road_traffic_speed: float = 0.0
var _junction_pedestrian: Node3D
var _junction_pedestrian_crossing: bool = false
var _junction_pedestrian_phase_consumed: bool = false
var _junction_pedestrian_clock: float = 3.0
var _junction_pedestrian_walk_time: float = 0.0
var _junction_pedestrian_legs: Array[Node3D] = []
var _pedestrian_signal_materials: Array[StandardMaterial3D] = []
var _pedestrian_wait_label: Label3D
var _pedestrian_walk_label: Label3D
var _pedestrian_countdown_label: Label3D
var _pedestrian_signal_flash_clock: float = 0.0
const TRAFFIC_LOOP_LENGTH: float = 142.0
const SAVE_PATH := "user://zayron_progress.cfg"
const ROUTE_NAMES: Array[String] = ["MUSCAT -> NIZWA", "NIZWA -> SUR", "SUR -> MUSCAT"]
const ROUTE_TARGETS: Array[Vector3] = [Vector3(0.0, 0.0, -82.0), Vector3(0.0, 0.0, -48.0), Vector3(0.0, 0.0, -112.0)]
const CARGO_NAMES: Array[String] = ["GENERAL GOODS", "CONSTRUCTION SUPPLIES", "CHILLED GOODS"]
const CARGO_REWARDS: Array[int] = [25, 40, 35]
const PASSENGER_TRIP_REWARD: int = 30
const PASSENGER_GROUP_SIZE: int = 8
const COMPANY_TRIP_SCRIPT = preload("res://scripts/company_bus_trip.gd")

var _selected_route: int = 0
var _route_button: Button
var _checkpoint_area: Area3D
var _checkpoint_gate_parts: Array[MeshInstance3D] = []
var _selected_cargo: int = 0
var _cargo_button: Button
var _passenger_mode: bool = false
var _mission_type_button: Button
var _passenger_pickup_done: bool = false
var _passenger_pickup_target := Vector3(0.0, 0.0, -37.0)
var _checkpoint_label: Label3D
var _passenger_status_label: Label
var _passenger_waiting_group: Node3D
var _cargo_status_label: Label
var _cargo_pickup_done: bool = false
var _cargo_depot: Node3D
var _depot_crates: Array[Node3D] = []
var _depot_crate_home_positions: Array[Vector3] = []
var _forklift_carriage: Node3D
var _forklift_beacon: OmniLight3D
var _forklift_animation_time: float = 0.0
var _forklift_lift_level: float = 0.48
var _forklift_tilt_angle: float = 0.0
var _forklift_tilt_label: Label
var _forklift_lift_label: Label
var _forklift_root: Node3D
var _forklift_held_crate: Node3D
var _forklift_held_pallet: Node3D
var _depot_pallets: Array[Node3D] = []
var _depot_staging_positions: Array[Vector3] = [
	Vector3(0.0, 0.18, 2.4),
	Vector3(0.0, 0.18, 4.1),
	Vector3(0.0, 0.18, 5.8)
]
var _depot_pallet_staging_slots: Array[int] = []
var _forklift_cargo_label: Label
var _warehouse_load_button: Button
var _cargo_unload_button: Button
var _forklift_wheel_nodes: Array[MeshInstance3D] = []
var _pause_button: Button
var _pause_overlay: Control
var _audio_slider: HSlider
var _steering_slider: HSlider
var _steering_sensitivity: float = 1.0
var _master_volume: float = 1.0

# First playable transport-company management layer.
var _company_name: String = "ZAYRON TRANSPORT"
var _company_funds: int = 500
var _company_bus_count: int = 1
var _company_driver_count: int = 0
var _company_completed_trips: int = 0
var _company_trip_active: bool = false
var _company_trip_timer: Timer
var _company_panel: Control
var _company_summary_label: Label
var _company_status_label: Label
var _company_name_edit: LineEdit
var _company_dispatch_button: Button
var _company_roster_label: Label
var _company_route_option: OptionButton
var _company_config_bus_option: OptionButton
var _company_config_route_option: OptionButton
var _company_config_vehicle_option: OptionButton
var _company_config_driver_option: OptionButton
var _company_schedule_option: OptionButton
var _company_config_bus_index: int = 0
var _company_selected_route: int = 0
var _company_fleet: Array[Dictionary] = []
var _company_drivers: Array[Dictionary] = []
var _company_trip_driver_index: int = -1
var _company_trip_bus_index: int = -1
var _company_ai_bus: Node3D
var _company_ai_bus_phase: int = 0 # 0 outbound, 1 station stop, 2 return
var _company_ai_bus_stop_time: float = 0.0
var _company_ai_bus_start := Vector3(-2.0, 0.15, 8.0)
var _company_ai_bus_destination := Vector3(-2.0, 0.15, -82.0)
var _company_ai_bus_speed: float = 7.0
var _company_ai_bus_current_speed: float = 0.0
var _company_ai_bus_acceleration: float = 2.8
var _company_ai_route_points: Array[Vector3] = []
var _company_ai_waypoint_index: int = 0
var _company_ai_stop_passengers: Node3D
var _company_ai_boarded_passengers: int = 0

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_save_progress()


func _ready() -> void:
	_load_progress()
	_initialize_company_records()
	_mission_target = ROUTE_TARGETS[_selected_route]
	_passenger_pickup_target = Vector3(0.0, 0.0, (8.0 + _mission_target.z) * 0.5)
	_mission_target = _passenger_pickup_target
	_build_environment()
	_build_oman_test_road()
	_build_test_intersection()
	_build_oman_roadside_vegetation()
	_build_roadside_signs()
	_build_traffic_vehicle()
	_build_mission()
	_build_passenger_waiting_group()
	_build_cargo_depot()
	_build_roadside_fuel_station()
	_spawn_vehicle()
	_build_vehicle_selector()
	_build_mission_hud()
	_build_pause_menu()
	_build_company_management()

func _process(delta: float) -> void:
	for traffic_index in range(_traffic_vehicles.size()):
		var traffic_vehicle := _traffic_vehicles[traffic_index]
		if not is_instance_valid(traffic_vehicle):
			continue
		# Traffic follows the vehicle ahead in the same lane instead of passing
		# through it. The loop distance accounts for cars that have wrapped.
		var nearest_gap := TRAFFIC_LOOP_LENGTH
		for other_index in range(_traffic_vehicles.size()):
			if other_index == traffic_index or not is_instance_valid(_traffic_vehicles[other_index]):
				continue
			var gap := fposmod(_traffic_vehicles[other_index].position.z - traffic_vehicle.position.z, TRAFFIC_LOOP_LENGTH)
			if gap > 0.1:
				nearest_gap = minf(nearest_gap, gap)
		# Scale the desired following distance with current speed so faster
		# traffic begins slowing earlier instead of relying on a fixed gap.
		var safe_following_gap := 4.5 + _traffic_current_speeds[traffic_index] * 1.25
		var gap_factor := clampf((nearest_gap - 2.0) / maxf(safe_following_gap - 2.0, 0.1), 0.0, 1.0)
		var target_speed := _traffic_vehicle_speeds[traffic_index] * gap_factor
		# The main-lane traffic stops before the junction whenever its signal
		# is red or amber, then accelerates again after green.
		var signal_is_green := _traffic_signal_clock < 8.0
		var stop_line_z := -52.0
		var distance_to_stop_line := stop_line_z - traffic_vehicle.position.z
		# Only brake for the stop line while still before it. Vehicles that
		# entered legally on green must clear the junction if the phase changes.
		if not signal_is_green and distance_to_stop_line >= 0.0 and distance_to_stop_line < 18.0:
			if distance_to_stop_line <= 0.75:
				target_speed = 0.0
			elif distance_to_stop_line > 0.0:
				var safe_approach_speed := sqrt(2.0 * 4.0 * distance_to_stop_line)
				target_speed = minf(target_speed, safe_approach_speed)
		var side_vehicle_crossing := is_instance_valid(_side_road_traffic_vehicle) and _side_road_traffic_vehicle.position.x <= 5.5 and _side_road_traffic_vehicle.position.x >= -5.5
		if side_vehicle_crossing and absf(traffic_vehicle.position.z + 48.0) > 3.0 and absf(traffic_vehicle.position.z + 48.0) < 18.0:
			target_speed = 0.0
		if _junction_pedestrian_crossing and absf(traffic_vehicle.position.z + 48.0) < 8.0:
			target_speed = 0.0
		# Brake more firmly than the traffic accelerates, approximating a
		# conservative driver response when a queue forms ahead.
		var speed_response := 7.0 if target_speed < _traffic_current_speeds[traffic_index] else 2.5
		_traffic_current_speeds[traffic_index] = move_toward(_traffic_current_speeds[traffic_index], target_speed, speed_response * delta)
		traffic_vehicle.position.z += _traffic_current_speeds[traffic_index] * delta
		if traffic_vehicle.position.z > 24.0:
			# Keep every respawn inside the same 142 m loop and preserve the
			# original traffic order; offsets outside the loop caused phase overlap.
			traffic_vehicle.position.z = -118.0 + float(traffic_index) * 46.0
	_traffic_signal_clock = fposmod(_traffic_signal_clock + delta, 26.0)
	_update_junction_pedestrian(delta)
	_update_side_road_traffic(delta)
	_update_player_signal_rule()
	if is_instance_valid(_road_position_status_label) and is_instance_valid(_active_vehicle):
		var road_x := absf(_active_vehicle.global_position.x)
		var on_test_highway := _active_vehicle.global_position.z <= 27.0 and _active_vehicle.global_position.z >= -123.0
		if not on_test_highway:
			_road_position_status_label.text = "ROAD POSITION: OFF TEST HIGHWAY"
			_road_position_status_label.add_theme_color_override("font_color", Color(0.68, 0.78, 0.9))
		elif road_x >= 4.35:
			_road_position_status_label.text = "ROAD EDGE  |  RETURN TO ROAD"
			_road_position_status_label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.2))
		elif road_x >= 3.0:
			_road_position_status_label.text = "LANE DEPARTURE WARNING"
			_road_position_status_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.25))
		else:
			_road_position_status_label.text = "ROAD POSITION: OK"
			_road_position_status_label.add_theme_color_override("font_color", Color(0.68, 0.9, 0.76))
	if is_instance_valid(_pedestrian_warning_label) and is_instance_valid(_active_vehicle):
		var pedestrian_nearby := _junction_pedestrian_crossing and is_instance_valid(_junction_pedestrian) and absf(_active_vehicle.global_position.x - _junction_pedestrian.global_position.x) < 9.0 and absf(_active_vehicle.global_position.z - _junction_pedestrian.global_position.z) < 15.0
		if pedestrian_nearby:
			_pedestrian_warning_label.text = "PEDESTRIAN CROSSING  |  SLOW DOWN"
			_pedestrian_warning_label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.2))
		else:
			_pedestrian_warning_label.text = "PEDESTRIAN AREA: CLEAR"
			_pedestrian_warning_label.add_theme_color_override("font_color", Color(0.68, 0.9, 0.76))
	if is_instance_valid(_speed_limit_status_label) and is_instance_valid(_active_vehicle) and _active_vehicle.has_method("get_speed_kmh"):
		var player_speed_kmh := float(_active_vehicle.get_speed_kmh())
		if player_speed_kmh > 82.0:
			_speed_limit_status_label.text = "SPEED LIMIT 80 km/h  |  OVERSPEED"
			_speed_limit_status_label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.2))
		elif player_speed_kmh > 80.0:
			_speed_limit_status_label.text = "SPEED LIMIT 80 km/h  |  SLOW DOWN"
			_speed_limit_status_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.25))
		else:
			_speed_limit_status_label.text = "SPEED LIMIT 80 km/h"
			_speed_limit_status_label.add_theme_color_override("font_color", Color(0.68, 0.9, 0.76))
	if is_instance_valid(_stop_line_warning_label) and is_instance_valid(_active_vehicle):
		var stop_line_distance := _active_vehicle.global_position.z + 52.0
		var on_approach := stop_line_distance >= 0.0 and stop_line_distance <= 35.0
		if on_approach:
			var side_vehicle_in_conflict := is_instance_valid(_side_road_traffic_vehicle) and _side_road_traffic_vehicle.position.x <= 5.5 and _side_road_traffic_vehicle.position.x >= -5.5
			if side_vehicle_in_conflict:
				_stop_line_warning_label.text = "CROSS TRAFFIC  |  STOP  |  %.0f m" % stop_line_distance
				_stop_line_warning_label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.2))
			elif _traffic_signal_clock >= 8.0:
				_stop_line_warning_label.text = "SIGNAL: STOP / PREPARE TO STOP  |  %.0f m" % stop_line_distance
				_stop_line_warning_label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.24))
			else:
				_stop_line_warning_label.text = "SIGNAL: GREEN  |  STOP LINE %.0f m" % stop_line_distance
				_stop_line_warning_label.add_theme_color_override("font_color", Color(0.68, 0.9, 0.76))
		else:
			_stop_line_warning_label.text = "JUNCTION APPROACH: CLEAR"
			_stop_line_warning_label.add_theme_color_override("font_color", Color(0.68, 0.78, 0.9))
	if is_instance_valid(_junction_status_label):
		var junction_phase_name := "MAIN ROAD GREEN"
		var junction_phase_end := 8.0
		if _traffic_signal_clock >= 8.0 and _traffic_signal_clock < 10.0:
			junction_phase_name = "MAIN ROAD AMBER"
			junction_phase_end = 10.0
		elif _traffic_signal_clock >= 10.0 and _traffic_signal_clock < 16.0:
			junction_phase_name = "MAIN ROAD RED  |  PEDESTRIAN WALK"
			junction_phase_end = 16.0
		elif _traffic_signal_clock >= 16.0 and _traffic_signal_clock < 18.0:
			junction_phase_name = "ALL-RED CLEARANCE"
			junction_phase_end = 18.0
		elif _traffic_signal_clock >= 18.0 and _traffic_signal_clock < 24.0:
			junction_phase_name = "SIDE-ROAD CROSSING"
			junction_phase_end = 24.0
		elif _traffic_signal_clock >= 24.0:
			junction_phase_name = "ALL-RED CLEARANCE"
			junction_phase_end = 26.0
		var junction_seconds_left := maxi(0, ceili(junction_phase_end - _traffic_signal_clock))
		_junction_status_label.text = "%s  |  %02d s" % [junction_phase_name, junction_seconds_left]
	var active_signal := 2 if _traffic_signal_clock < 8.0 else (1 if _traffic_signal_clock < 10.0 else 0)
	for lamp_index in range(_traffic_signal_lamps.size()):
		var lamp_material := _traffic_signal_materials[lamp_index]
		var lamp_on := lamp_index % 3 == active_signal
		lamp_material.emission_energy_multiplier = 1.8 if lamp_on else 0.08
		_traffic_signal_lamps[lamp_index].visible = true
	var signal_phase_end := 8.0 if _traffic_signal_clock < 8.0 else (10.0 if _traffic_signal_clock < 10.0 else 26.0)
	var signal_seconds_left := maxi(0, ceili(signal_phase_end - _traffic_signal_clock))
	for countdown_label in _traffic_signal_countdown_labels:
		countdown_label.text = "%02d" % signal_seconds_left
	var pedestrian_walk_allowed := _traffic_signal_clock >= 10.0 and _traffic_signal_clock < 16.0
	# Flash WALK during the final two seconds as a clearance warning before WAIT.
	_pedestrian_signal_flash_clock += delta
	var pedestrian_clearance_warning := pedestrian_walk_allowed and _traffic_signal_clock >= 14.0
	var pedestrian_walk_lit := pedestrian_walk_allowed and (not pedestrian_clearance_warning or fposmod(_pedestrian_signal_flash_clock, 0.8) < 0.4)
	for pedestrian_index in range(_pedestrian_signal_materials.size()):
		var lamp_active := pedestrian_walk_lit if pedestrian_index == 1 else not pedestrian_walk_allowed
		_pedestrian_signal_materials[pedestrian_index].emission_energy_multiplier = 1.8 if lamp_active else 0.08
	if is_instance_valid(_pedestrian_wait_label):
		_pedestrian_wait_label.visible = not pedestrian_walk_allowed
	if is_instance_valid(_pedestrian_walk_label):
		_pedestrian_walk_label.visible = pedestrian_walk_lit
	if is_instance_valid(_pedestrian_countdown_label):
		var seconds_to_change := 10.0 - _traffic_signal_clock if _traffic_signal_clock < 10.0 else (16.0 - _traffic_signal_clock if _traffic_signal_clock < 16.0 else 36.0 - _traffic_signal_clock)
		_pedestrian_countdown_label.text = "%02d" % maxi(0, ceili(seconds_to_change))
	_forklift_animation_time += delta
	if is_instance_valid(_forklift_beacon):
		_forklift_beacon.light_energy = 0.15 + (0.85 if sin(_forklift_animation_time * 4.0) > 0.15 else 0.0)
	_update_company_ai_bus(delta)
	_update_refuel_station_access()
	_update_warehouse_load_prompt()
	_update_cargo_unload_prompt()
	if not is_instance_valid(_mission_label) or _mission_complete or not is_instance_valid(_active_vehicle):
		return
	var distance := Vector2(_active_vehicle.global_position.x - _mission_target.x, _active_vehicle.global_position.z - _mission_target.z).length()
	var stage_name := "LOAD CARGO" if not _cargo_pickup_done else "DELIVER CARGO"
	if _passenger_mode:
		stage_name = "PICKUP STOP" if not _passenger_pickup_done else "PASSENGER DROP-OFF"
	_mission_label.text = "%s  |  %s: %d m" % [ROUTE_NAMES[_selected_route], stage_name, int(distance)]
	# Cargo handling is only allowed while stationary with the parking brake on.
	if not _passenger_mode and distance <= 5.0 and _active_vehicle.has_method("can_handle_cargo") and _active_vehicle.can_handle_cargo():
		_on_checkpoint_entered(_active_vehicle)
	# Let the driver open the passenger doors after arriving; the trigger itself
	# may already have fired while the doors were closed, so poll safely here.
	if _passenger_mode and _passenger_pickup_done and distance <= 5.0:
		if _active_vehicle.has_method("can_board_passengers") and _active_vehicle.can_board_passengers():
			_complete_passenger_dropoff()

func _spawn_vehicle() -> void:
	_release_forklift_load_for_mission()
	_mission_complete = false
	_passenger_pickup_done = false
	if is_instance_valid(_active_vehicle) and _active_vehicle.has_method("set_visible_passenger_manifest"):
		_active_vehicle.set_visible_passenger_manifest(0)
	_cargo_pickup_done = false
	if is_instance_valid(_cargo_status_label):
		_cargo_status_label.text = "CARGO STATUS: WAITING FOR LOAD"
	if is_instance_valid(_cargo_depot):
		_cargo_depot.visible = not _passenger_mode
		_cargo_depot.position.z = (8.0 + ROUTE_TARGETS[_selected_route].z) * 0.5
		for pallet_index in range(_depot_pallets.size()):
			var reset_pallet := _depot_pallets[pallet_index]
			if is_instance_valid(reset_pallet):
				reset_pallet.visible = true
				reset_pallet.position = Vector3(-2.1, 0.18, 3.0 + float(pallet_index) * 1.8)
		_depot_pallet_staging_slots.clear()
		for pallet_index in range(_depot_pallets.size()):
			_depot_pallet_staging_slots.append(-1)
		for crate_index in range(_depot_crates.size()):
			var depot_crate := _depot_crates[crate_index]
			if is_instance_valid(depot_crate):
				var home_pallet_index := int(crate_index / 2)
				if home_pallet_index < _depot_pallets.size() and is_instance_valid(_depot_pallets[home_pallet_index]):
					depot_crate.reparent(_depot_pallets[home_pallet_index], false)
				depot_crate.position = _depot_crate_home_positions[crate_index]
				depot_crate.scale = Vector3.ONE
				depot_crate.visible = true
	if is_instance_valid(_passenger_status_label):
		_passenger_status_label.text = "PASSENGERS ON BOARD: 0"
	if is_instance_valid(_passenger_waiting_group):
		_passenger_waiting_group.visible = _passenger_mode
		_passenger_waiting_group.position.z = (8.0 + ROUTE_TARGETS[_selected_route].z) * 0.5
	if _passenger_mode or not _cargo_pickup_done:
		_mission_target = Vector3(0.0, 0.0, (8.0 + ROUTE_TARGETS[_selected_route].z) * 0.5)
	else:
		_mission_target = ROUTE_TARGETS[_selected_route]
	if is_instance_valid(_checkpoint_area):
		_checkpoint_area.position = _mission_target
	_move_checkpoint_gate()
	if is_instance_valid(_active_vehicle):
		_store_active_vehicle_fuel()
		_active_vehicle.queue_free()
	_active_vehicle = FLEET_SCENES[_selected_vehicle].instantiate() as Node3D
	_active_vehicle_index = _selected_vehicle
	if _active_vehicle.has_method("set_fuel_level"):
		_active_vehicle.set_fuel_level(_vehicle_fuel_levels[_selected_vehicle])
	if _active_vehicle.has_method("set_vehicle_damage"):
		_active_vehicle.set_vehicle_damage(_vehicle_damage_levels[_selected_vehicle])
	_active_vehicle.position = Vector3(0.0, 0.15, 8.0)
	add_child(_active_vehicle)
	if _active_vehicle.has_signal("refuel_requested"):
		_active_vehicle.refuel_requested.connect(_on_vehicle_refuel_requested)
	if _active_vehicle.has_signal("repair_requested"):
		_active_vehicle.repair_requested.connect(_on_vehicle_repair_requested)
	if _active_vehicle.has_signal("vehicle_damage_changed"):
		_active_vehicle.vehicle_damage_changed.connect(_on_active_vehicle_damage_changed)
	_sync_vehicle_cargo_payload()
	_apply_vehicle_settings()
	if is_instance_valid(_vehicle_button):
		_vehicle_button.text = "NEXT: " + FLEET_NAMES[(_selected_vehicle + 1) % FLEET_NAMES.size()]
	if is_instance_valid(_mission_label):
		_mission_label.text = "%s  |  CHECKPOINT: 000 m" % ROUTE_NAMES[_selected_route]


func _apply_vehicle_settings() -> void:
	if is_instance_valid(_active_vehicle) and _active_vehicle.has_method("set_steering_sensitivity"):
		_active_vehicle.set_steering_sensitivity(_steering_sensitivity)

func _update_warehouse_load_prompt() -> void:
	if not is_instance_valid(_warehouse_load_button):
		return
	if _passenger_mode or _cargo_pickup_done or _mission_complete or not is_instance_valid(_active_vehicle) or not is_instance_valid(_cargo_depot):
		_warehouse_load_button.visible = false
		return
	var near_bay := Vector2(_active_vehicle.global_position.x - _cargo_depot.global_position.x, _active_vehicle.global_position.z - _cargo_depot.global_position.z).length() <= 8.5
	var parked := _active_vehicle.has_method("can_handle_cargo") and _active_vehicle.can_handle_cargo()
	var has_staged_pallet := false
	for slot_owner in _depot_pallet_staging_slots:
		if slot_owner >= 0 and slot_owner < _depot_pallets.size() and is_instance_valid(_depot_pallets[slot_owner]) and _depot_pallets[slot_owner].visible:
			has_staged_pallet = true
			break
	_warehouse_load_button.visible = near_bay and has_staged_pallet and parked


func _update_cargo_unload_prompt() -> void:
	if not is_instance_valid(_cargo_unload_button):
		return
	if _passenger_mode or not _cargo_pickup_done or _mission_complete or not is_instance_valid(_active_vehicle):
		_cargo_unload_button.visible = false
		return
	var distance := Vector2(_active_vehicle.global_position.x - _mission_target.x, _active_vehicle.global_position.z - _mission_target.z).length()
	var parked := _active_vehicle.has_method("can_handle_cargo") and _active_vehicle.can_handle_cargo()
	_cargo_unload_button.visible = distance <= 5.0 and parked


func _unload_delivered_cargo() -> void:
	if _passenger_mode or not _cargo_pickup_done or _mission_complete or not is_instance_valid(_active_vehicle):
		return
	if not _active_vehicle.has_method("can_handle_cargo") or not _active_vehicle.can_handle_cargo():
		if is_instance_valid(_mission_label):
			_mission_label.text = "STOP COMPLETELY AND APPLY PARK BRAKE BEFORE UNLOADING"
		return
	var distance := Vector2(_active_vehicle.global_position.x - _mission_target.x, _active_vehicle.global_position.z - _mission_target.z).length()
	if distance > 5.0:
		if is_instance_valid(_mission_label):
			_mission_label.text = "PARK INSIDE THE DELIVERY UNLOADING AREA"
		return
	_mission_complete = true
	if is_instance_valid(_cargo_status_label):
		_cargo_status_label.text = "CARGO DELIVERED: " + CARGO_NAMES[_selected_cargo]
	_animate_depot_cargo(false)
	if _active_vehicle.has_method("set_cargo_payload"):
		_active_vehicle.set_cargo_payload(_selected_cargo, false)
	_delivery_count += 1
	_cash_balance += CARGO_REWARDS[_selected_cargo]
	if is_instance_valid(_cash_label):
		_cash_label.text = "WALLET  |  OMR %d  |  DELIVERIES %d" % [_cash_balance, _delivery_count]
	if is_instance_valid(_cargo_unload_button):
		_cargo_unload_button.visible = false
	_save_progress()
	if is_instance_valid(_mission_label):
		_mission_label.text = "%s COMPLETE  |  %s UNLOADED  |  +%d OMR" % [ROUTE_NAMES[_selected_route], CARGO_NAMES[_selected_cargo], CARGO_REWARDS[_selected_cargo]]


func _load_truck_from_warehouse() -> void:
	if _passenger_mode or _cargo_pickup_done or _mission_complete or not is_instance_valid(_active_vehicle) or not is_instance_valid(_cargo_depot):
		return
	if not _active_vehicle.has_method("can_handle_cargo") or not _active_vehicle.can_handle_cargo():
		if is_instance_valid(_mission_label):
			_mission_label.text = "STOP IN THE BAY AND APPLY PARK BRAKE"
		return
	var bay_distance := Vector2(_active_vehicle.global_position.x - _cargo_depot.global_position.x, _active_vehicle.global_position.z - _cargo_depot.global_position.z).length()
	if bay_distance > 8.5:
		if is_instance_valid(_mission_label):
			_mission_label.text = "PARK INSIDE THE TRUCK LOADING BAY"
		return
	var staged_pallet_index := -1
	for slot_owner in _depot_pallet_staging_slots:
		if slot_owner >= 0 and slot_owner < _depot_pallets.size() and is_instance_valid(_depot_pallets[slot_owner]) and _depot_pallets[slot_owner].visible:
			staged_pallet_index = slot_owner
			break
	if staged_pallet_index < 0:
		if is_instance_valid(_mission_label):
			_mission_label.text = "NO PALLET IN A STAGING BAY - MOVE ONE WITH THE FORKLIFT"
		return
	var staged_pallet := _depot_pallets[staged_pallet_index]
	_cargo_pickup_done = true
	_sync_vehicle_cargo_payload()
	staged_pallet.visible = false
	for crate in _depot_crates:
		if is_instance_valid(crate) and crate.get_parent() == staged_pallet:
			crate.reparent(_cargo_depot, true)
			var tween := create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(crate, "global_position", _cargo_depot.to_global(Vector3(-5.1, 1.1, 2.7)), 0.55)
			tween.tween_property(crate, "scale", Vector3.ZERO, 0.3)
			tween.tween_callback(crate.hide)
	if is_instance_valid(_cargo_status_label):
		_cargo_status_label.text = "CARGO LOADED: " + CARGO_NAMES[_selected_cargo] + " | PALLET %02d" % (staged_pallet_index + 1)
	_mission_target = ROUTE_TARGETS[_selected_route]
	if is_instance_valid(_checkpoint_area):
		_checkpoint_area.position = _mission_target
	_move_checkpoint_gate()
	if is_instance_valid(_mission_label):
		_mission_label.text = "PALLET LOADED  |  CONTINUE TO " + ROUTE_NAMES[_selected_route].split(" -> ")[1]
	if is_instance_valid(_warehouse_load_button):
		_warehouse_load_button.visible = false


func _sync_vehicle_cargo_payload() -> void:
	if not is_instance_valid(_active_vehicle) or not _active_vehicle.has_method("set_cargo_payload"):
		return
	var show_payload := _selected_vehicle == 0 and not _passenger_mode and _cargo_pickup_done
	_active_vehicle.set_cargo_payload(_selected_cargo, show_payload)


func _build_vehicle_selector() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var button := Button.new()
	button.name = "VehicleSelector"
	button.text = "NEXT: PREMIUM BLUE SEMI"
	button.custom_minimum_size = Vector2(180.0, 54.0)
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.anchor_top = 0.0
	button.anchor_bottom = 0.0
	button.offset_left = -204.0
	button.offset_right = -20.0
	button.offset_top = 22.0
	button.offset_bottom = 76.0
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color.WHITE)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.16, 0.25, 0.92)
	style.border_color = Color(0.2, 0.72, 0.95, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	button.add_theme_stylebox_override("normal", style)
	button.pressed.connect(_on_vehicle_button_pressed)
	layer.add_child(button)
	_vehicle_button = button

func _on_vehicle_button_pressed() -> void:
	if _passenger_mode:
		_selected_vehicle = 3 + ((_selected_vehicle - 3 + 1) % 3)
	else:
		_selected_vehicle = (_selected_vehicle + 1) % FLEET_SCENES.size()
	_spawn_vehicle()
	_save_progress()

func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.12, 0.36, 0.62)
	sky_material.sky_horizon_color = Color(0.72, 0.82, 0.91)
	sky_material.ground_bottom_color = Color(0.38, 0.28, 0.18)
	sky_material.ground_horizon_color = Color(0.72, 0.62, 0.48)
	environment.sky.sky_material = sky_material
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.76, 0.82)
	environment.ambient_light_energy = 0.65
	world_environment.environment = environment
	add_child(world_environment)

	var ground := StaticBody3D.new()
	ground.name = "DesertGround"
	add_child(ground)
	var ground_mesh := MeshInstance3D.new()
	var ground_box := BoxMesh.new()
	ground_box.size = Vector3(180.0, 1.0, 180.0)
	ground_mesh.mesh = ground_box
	ground_mesh.position.y = -0.55
	var sand := StandardMaterial3D.new()
	sand.albedo_color = Color(0.67, 0.49, 0.30)
	ground_mesh.material_override = sand
	ground.add_child(ground_mesh)
	var ground_collision := CollisionShape3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = ground_box.size
	ground_collision.shape = ground_shape
	ground_collision.position.y = -0.55
	ground.add_child(ground_collision)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

func _build_oman_test_road() -> void:
	var road := _make_box("AsphaltRoad", Vector3(9.0, 0.12, 150.0), Vector3(0.0, 0.03, -48.0), Color(0.12, 0.13, 0.14))
	add_child(road)

	# Fine procedural aggregate gives the road surface visual texture without external assets.
	var asphalt_noise := FastNoiseLite.new()
	asphalt_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	asphalt_noise.frequency = 0.075
	asphalt_noise.fractal_octaves = 3
	var asphalt_texture := NoiseTexture2D.new()
	asphalt_texture.width = 512
	asphalt_texture.height = 512
	asphalt_texture.seamless = true
	asphalt_texture.noise = asphalt_noise
	var asphalt_surface := MeshInstance3D.new()
	asphalt_surface.name = "TexturedAsphaltSurface"
	var asphalt_plane := PlaneMesh.new()
	asphalt_plane.size = Vector2(9.0, 150.0)
	asphalt_surface.mesh = asphalt_plane
	asphalt_surface.position = Vector3(0.0, 0.094, -48.0)
	var asphalt_material := StandardMaterial3D.new()
	asphalt_material.albedo_color = Color(0.31, 0.32, 0.33)
	asphalt_material.albedo_texture = asphalt_texture
	asphalt_material.roughness = 0.96
	asphalt_material.uv1_scale = Vector3(1.0, 7.0, 1.0)
	asphalt_surface.material_override = asphalt_material
	add_child(asphalt_surface)

	# Continuous edge lines and reflective road studs improve road scale and night readability.
	for side in [-1.0, 1.0]:
		var edge_line := _make_box("RoadEdgeLine_%s" % side, Vector3(0.12, 0.025, 150.0), Vector3(side * 4.18, 0.108, -48.0), Color(0.88, 0.87, 0.79))
		add_child(edge_line)
		for stud_index in range(30):
			var stud := _make_box("ReflectiveRoadStud_%s_%02d" % [side, stud_index], Vector3(0.10, 0.035, 0.16), Vector3(side * 4.02, 0.115, 23.0 - float(stud_index) * 4.9), Color(0.92, 0.78, 0.36))
			add_child(stud)
	var shoulder_left := _make_box("LeftRoadShoulder", Vector3(1.0, 0.10, 150.0), Vector3(-5.0, 0.0, -48.0), Color(0.48, 0.39, 0.29))
	add_child(shoulder_left)
	var shoulder_right := _make_box("RightRoadShoulder", Vector3(1.0, 0.10, 150.0), Vector3(5.0, 0.0, -48.0), Color(0.48, 0.39, 0.29))
	add_child(shoulder_right)

	for i in range(15):
		var dash := _make_box("CentreLine_%02d" % i, Vector3(0.14, 0.025, 3.2), Vector3(0.0, 0.105, 18.0 - float(i) * 8.5), Color(0.92, 0.91, 0.82))
		add_child(dash)

	for i in range(7):
		var side := -1.0 if i % 2 == 0 else 1.0
		var hill := MeshInstance3D.new()
		var hill_mesh := SphereMesh.new()
		hill_mesh.radius = 1.0
		hill_mesh.height = 2.0
		hill.mesh = hill_mesh
		hill.scale = Vector3(10.0 + float(i % 3) * 3.0, 5.0 + float(i % 2) * 2.0, 8.0)
		hill.position = Vector3(side * (17.0 + float(i % 2) * 5.0), 2.0, -12.0 - float(i) * 18.0)
		var rock := StandardMaterial3D.new()
		rock.albedo_color = Color(0.48, 0.35, 0.25) if i % 2 == 0 else Color(0.58, 0.43, 0.30)
		hill.material_override = rock
		add_child(hill)

	for i in range(12):
		var side := -1.0 if i % 2 == 0 else 1.0
		var marker := _make_box("RoadMarker_%02d" % i, Vector3(0.18, 0.8, 0.18), Vector3(side * 6.0, 0.4, 12.0 - float(i) * 11.0), Color(0.88, 0.84, 0.72))
		add_child(marker)



func _build_oman_roadside_vegetation() -> void:
	for tree_index in range(6):
		var side := -1.0 if tree_index % 2 == 0 else 1.0
		var tree := Node3D.new()
		tree.name = "OmanDatePalm_%02d" % tree_index
		tree.position = Vector3(side * (12.0 + float(tree_index % 2) * 2.0), 0.0, 12.0 - float(tree_index) * 23.0)
		add_child(tree)
		var trunk := MeshInstance3D.new()
		trunk.name = "PalmTrunk"
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.17
		trunk_mesh.bottom_radius = 0.34
		trunk_mesh.height = 4.5
		trunk.mesh = trunk_mesh
		trunk.position.y = 2.25
		var trunk_material := StandardMaterial3D.new()
		trunk_material.albedo_color = Color(0.34, 0.21, 0.12)
		trunk.material_override = trunk_material
		tree.add_child(trunk)
		var leaf_material := StandardMaterial3D.new()
		leaf_material.albedo_color = Color(0.13, 0.31, 0.16)
		leaf_material.roughness = 0.9
		for leaf_index in range(8):
			var angle := TAU * float(leaf_index) / 8.0
			var leaf := MeshInstance3D.new()
			leaf.name = "PalmFrond_%d" % leaf_index
			var leaf_mesh := BoxMesh.new()
			leaf_mesh.size = Vector3(0.18, 0.12, 2.55)
			leaf.mesh = leaf_mesh
			leaf.position = Vector3(sin(angle) * 0.78, 4.25 - (0.12 if leaf_index % 2 == 0 else 0.0), cos(angle) * 0.78)
			leaf.rotation.y = angle
			leaf.rotation.x = -0.22
			leaf.material_override = leaf_material
			tree.add_child(leaf)
		var crown := MeshInstance3D.new()
		crown.name = "PalmCrown"
		var crown_mesh := SphereMesh.new()
		crown_mesh.radius = 0.34
		crown_mesh.height = 0.58
		crown.mesh = crown_mesh
		crown.position.y = 4.12
		crown.material_override = leaf_material
		tree.add_child(crown)

	for shrub_index in range(10):
		var side := -1.0 if shrub_index % 2 == 0 else 1.0
		var shrub := MeshInstance3D.new()
		shrub.name = "DesertShrub_%02d" % shrub_index
		var shrub_mesh := SphereMesh.new()
		shrub_mesh.radius = 0.65
		shrub_mesh.height = 0.72
		shrub.mesh = shrub_mesh
		shrub.scale = Vector3(1.3, 0.65, 0.9)
		shrub.position = Vector3(side * (8.0 + float(shrub_index % 3)), 0.25, 8.0 - float(shrub_index) * 13.0)
		var shrub_material := StandardMaterial3D.new()
		shrub_material.albedo_color = Color(0.34, 0.35, 0.19)
		shrub.material_override = shrub_material
		add_child(shrub)

func _build_roadside_signs() -> void:
	for i in range(3):
		var z_pos := -18.0 - float(i) * 34.0
		var side := -1.0 if i % 2 == 0 else 1.0
		var post := _make_box("RoadSignPost_%d" % i, Vector3(0.16, 2.7, 0.16), Vector3(side * 6.8, 1.35, z_pos), Color(0.72, 0.74, 0.76))
		add_child(post)
		var panel := _make_box("RoadSignPanel_%d" % i, Vector3(1.9, 1.0, 0.12), Vector3(side * 6.8, 2.55, z_pos), Color(0.03, 0.30, 0.22))
		add_child(panel)
		var sign_text := Label3D.new()
		sign_text.name = "RoadSignText_%d" % i
		sign_text.text = "OMAN\n" + ("MUSCAT" if i == 0 else ("NIZWA" if i == 1 else "SUR"))
		sign_text.position = Vector3(side * 6.8, 2.55, z_pos + 0.08)
		sign_text.font_size = 32
		sign_text.pixel_size = 0.012
		sign_text.modulate = Color.WHITE
		sign_text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(sign_text)


	# Prototype Oman highway speed-limit boards along the test segment.
	for sign_index in range(3):
		var sign_side := -1.0 if sign_index % 2 == 0 else 1.0
		var sign_z := -28.0 - float(sign_index) * 42.0
		var sign_x := sign_side * 6.7
		var speed_post := _make_box("SpeedLimitPost_%02d" % sign_index, Vector3(0.14, 2.35, 0.14), Vector3(sign_x, 1.175, sign_z), Color(0.72, 0.74, 0.76))
		add_child(speed_post)
		var sign_back := _make_box("SpeedLimitBoard_%02d" % sign_index, Vector3(1.35, 1.35, 0.16), Vector3(sign_x, 2.45, sign_z), Color(0.82, 0.08, 0.07))
		add_child(sign_back)
		var sign_face := _make_box("SpeedLimitFace_%02d" % sign_index, Vector3(1.12, 1.12, 0.04), Vector3(sign_x, 2.45, sign_z + 0.105), Color(0.96, 0.95, 0.9))
		add_child(sign_face)
		var speed_text := Label3D.new()
		speed_text.name = "SpeedLimitText_%02d" % sign_index
		speed_text.text = "80\\nkm/h"
		speed_text.position = Vector3(sign_x, 2.45, sign_z + 0.14)
		speed_text.font_size = 38
		speed_text.pixel_size = 0.012
		speed_text.modulate = Color(0.08, 0.08, 0.08)
		speed_text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(speed_text)


func _update_player_signal_rule() -> void:
	if not is_instance_valid(_active_vehicle) or not _active_vehicle.has_method("set_traffic_signal_brake"):
		return
	var signal_is_green := _traffic_signal_clock < 8.0
	var distance_to_stop_line := _active_vehicle.global_position.z + 52.0
	var brake_amount := 0.0
	var side_vehicle_crossing := is_instance_valid(_side_road_traffic_vehicle) and _side_road_traffic_vehicle.position.x <= 5.5 and _side_road_traffic_vehicle.position.x >= -5.5
	if side_vehicle_crossing and distance_to_stop_line > 0.0 and distance_to_stop_line < 22.0:
		brake_amount = 1.0
	# Do not stop the player's vehicle after it has crossed the stop line;
	# clear the junction instead of stopping in the conflict area.
	elif not signal_is_green and distance_to_stop_line >= 0.0 and distance_to_stop_line < 22.0:
		if distance_to_stop_line <= 1.0:
			brake_amount = 1.0
		elif distance_to_stop_line > 0.0:
			var safe_speed := sqrt(2.0 * 5.0 * distance_to_stop_line)
			var current_speed := float(_active_vehicle.get("_speed"))
			if current_speed > safe_speed:
				brake_amount = clampf((current_speed - safe_speed) / 3.0, 0.0, 1.0)
	_active_vehicle.set_traffic_signal_brake(brake_amount)


func _build_test_intersection() -> void:
	# Short access road creates a visible T-junction beside the test highway.
	var junction_road := _make_box("OmanJunctionAccessRoad", Vector3(20.0, 0.12, 8.0), Vector3(10.5, 0.035, -48.0), Color(0.12, 0.13, 0.14))
	add_child(junction_road)
	var junction_surface := _make_box("JunctionAsphaltSurface", Vector3(20.0, 0.025, 8.0), Vector3(10.5, 0.105, -48.0), Color(0.29, 0.30, 0.31))
	add_child(junction_surface)
	# Extend the access road across the highway so crossing traffic has a
	# visible exit lane instead of being reset immediately at the carriageway.
	var west_exit_road := _make_box("OmanJunctionWestExitRoad", Vector3(20.0, 0.12, 8.0), Vector3(-9.5, 0.035, -48.0), Color(0.12, 0.13, 0.14))
	add_child(west_exit_road)
	var west_exit_surface := _make_box("JunctionWestExitAsphalt", Vector3(20.0, 0.025, 8.0), Vector3(-9.5, 0.105, -48.0), Color(0.29, 0.30, 0.31))
	add_child(west_exit_surface)
	var junction_center_dash_material := Color(0.92, 0.91, 0.84)
	for dash_index in range(6):
		var dash := _make_box("JunctionCentreDash_%d" % dash_index, Vector3(1.45, 0.025, 0.12), Vector3(4.0 + float(dash_index) * 2.45, 0.13, -48.0), junction_center_dash_material)
		add_child(dash)
	for dash_index in range(7):
		var west_dash := _make_box("JunctionWestCentreDash_%d" % dash_index, Vector3(1.45, 0.025, 0.12), Vector3(-2.0 - float(dash_index) * 2.35, 0.13, -48.0), junction_center_dash_material)
		add_child(west_dash)
	# Side-road traffic receives a clear give-way marking before joining the highway.
	var give_way_bar := _make_box("JunctionGiveWayBar", Vector3(0.34, 0.035, 7.0), Vector3(2.1, 0.14, -48.0), Color(0.96, 0.94, 0.87))
	add_child(give_way_bar)
	# A marked pedestrian crossing makes the side-road entrance easier to read.
	# Stripes span the access road and sit just inside the junction mouth.
	for crossing_index in range(6):
		var crossing_stripe := _make_box("JunctionPedestrianStripe_%d" % crossing_index, Vector3(0.38, 0.03, 6.4), Vector3(5.0 + float(crossing_index) * 0.72, 0.15, -48.0), Color(0.96, 0.95, 0.88))
		add_child(crossing_stripe)
	# Raised kerb-edge guides define both sides of the pedestrian crossing.
	for kerb_z in [-51.9, -44.1]:
		var crossing_kerb := _make_box("JunctionCrossingKerb_%s" % str(kerb_z), Vector3(5.0, 0.16, 0.18), Vector3(5.0, 0.08, kerb_z), Color(0.68, 0.67, 0.61))
		add_child(crossing_kerb)
	for triangle_index in range(3):
		var triangle_base := _make_box("GiveWayTriangleBase_%d" % triangle_index, Vector3(0.85, 0.025, 0.12), Vector3(3.15, 0.145, -50.4 + float(triangle_index) * 2.4), Color(0.96, 0.94, 0.87))
		add_child(triangle_base)
		var triangle_left := _make_box("GiveWayTriangleLeft_%d" % triangle_index, Vector3(0.12, 0.025, 0.62), Vector3(2.78, 0.145, -50.7 + float(triangle_index) * 2.4), Color(0.96, 0.94, 0.87))
		triangle_left.rotation.y = deg_to_rad(-35.0)
		add_child(triangle_left)
		var triangle_right := _make_box("GiveWayTriangleRight_%d" % triangle_index, Vector3(0.12, 0.025, 0.62), Vector3(2.78, 0.145, -50.1 + float(triangle_index) * 2.4), Color(0.96, 0.94, 0.87))
		triangle_right.rotation.y = deg_to_rad(35.0)
		add_child(triangle_right)
	var junction_sign_pole := _make_box("GiveWaySignPole", Vector3(0.12, 2.2, 0.12), Vector3(17.8, 1.1, -44.2), Color(0.22, 0.23, 0.24))
	add_child(junction_sign_pole)
	var junction_sign := _make_box("GiveWaySignBoard", Vector3(1.25, 0.9, 0.12), Vector3(17.8, 2.45, -44.2), Color(0.90, 0.88, 0.78))
	add_child(junction_sign)
	var give_way_label := Label3D.new()
	give_way_label.name = "GiveWaySignText"
	give_way_label.text = "GIVE WAY"
	give_way_label.font_size = 30
	give_way_label.pixel_size = 0.008
	give_way_label.position = Vector3(17.8, 2.45, -44.1)
	give_way_label.rotation_degrees.y = 180.0
	give_way_label.modulate = Color(0.12, 0.13, 0.14)
	add_child(give_way_label)
	var stop_bar := _make_box("JunctionStopLine", Vector3(8.3, 0.035, 0.38), Vector3(0.0, 0.13, -52.0), Color(0.95, 0.94, 0.88))
	add_child(stop_bar)
	for pole_index in range(2):
		var side := -1.0 if pole_index == 0 else 1.0
		var pole_x := side * 5.7
		var pole_z := -43.2
		var pole := _make_box("TrafficSignalPole_%d" % pole_index, Vector3(0.18, 4.0, 0.18), Vector3(pole_x, 2.0, pole_z), Color(0.20, 0.22, 0.23))
		add_child(pole)
		var head := _make_box("TrafficSignalHead_%d" % pole_index, Vector3(0.62, 1.85, 0.48), Vector3(pole_x, 4.05, pole_z), Color(0.035, 0.04, 0.045))
		add_child(head)
		for lamp_index in range(3):
			var lamp := MeshInstance3D.new()
			lamp.name = "TrafficSignalLamp_%d_%d" % [pole_index, lamp_index]
			var sphere := SphereMesh.new()
			sphere.radius = 0.19
			sphere.height = 0.38
			lamp.mesh = sphere
			lamp.position = Vector3(pole_x, 4.62 - float(lamp_index) * 0.57, pole_z + 0.26)
			var material := StandardMaterial3D.new()
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.emission_enabled = true
			material.emission = [Color(0.95, 0.035, 0.025), Color(1.0, 0.55, 0.02), Color(0.03, 0.85, 0.12)][lamp_index]
			material.emission_energy_multiplier = 0.08
			lamp.material_override = material
			add_child(lamp)
			_traffic_signal_lamps.append(lamp)
			_traffic_signal_materials.append(material)
		var signal_countdown := Label3D.new()
		signal_countdown.name = "TrafficSignalCountdown_%d" % pole_index
		signal_countdown.text = "08"
		signal_countdown.font_size = 30
		signal_countdown.pixel_size = 0.006
		signal_countdown.position = Vector3(pole_x, 2.75, pole_z + 0.28)
		signal_countdown.modulate = Color(0.95, 0.96, 0.98)
		add_child(signal_countdown)
		_traffic_signal_countdown_labels.append(signal_countdown)
	# Pedestrian signal faces the zebra crossing: red WAIT / green WALK.
	var pedestrian_head := _make_box("PedestrianSignalHousing", Vector3(0.48, 0.92, 0.34), Vector3(8.0, 2.75, -43.4), Color(0.035, 0.04, 0.045))
	add_child(pedestrian_head)
	for lamp_index in range(2):
		var pedestrian_lamp := MeshInstance3D.new()
		pedestrian_lamp.name = "PedestrianSignalLamp_%d" % lamp_index
		var pedestrian_sphere := SphereMesh.new()
		pedestrian_sphere.radius = 0.13
		pedestrian_sphere.height = 0.26
		pedestrian_lamp.mesh = pedestrian_sphere
		pedestrian_lamp.position = Vector3(8.0, 2.98 - float(lamp_index) * 0.43, -43.2)
		var pedestrian_material := StandardMaterial3D.new()
		pedestrian_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		pedestrian_material.emission_enabled = true
		pedestrian_material.emission = Color(0.95, 0.035, 0.025) if lamp_index == 0 else Color(0.03, 0.85, 0.12)
		pedestrian_material.emission_energy_multiplier = 1.8 if lamp_index == 0 else 0.08
		pedestrian_lamp.material_override = pedestrian_material
		add_child(pedestrian_lamp)
		_pedestrian_signal_materials.append(pedestrian_material)
	_pedestrian_wait_label = Label3D.new()
	_pedestrian_wait_label.name = "PedestrianWaitText"
	_pedestrian_wait_label.text = "WAIT"
	_pedestrian_wait_label.font_size = 28
	_pedestrian_wait_label.pixel_size = 0.006
	_pedestrian_wait_label.position = Vector3(8.0, 3.55, -43.15)
	_pedestrian_wait_label.modulate = Color(1.0, 0.22, 0.18)
	add_child(_pedestrian_wait_label)
	_pedestrian_walk_label = Label3D.new()
	_pedestrian_walk_label.name = "PedestrianWalkText"
	_pedestrian_walk_label.text = "WALK"
	_pedestrian_walk_label.font_size = 28
	_pedestrian_walk_label.pixel_size = 0.006
	_pedestrian_walk_label.position = Vector3(8.0, 3.55, -43.15)
	_pedestrian_walk_label.modulate = Color(0.18, 1.0, 0.3)
	_pedestrian_walk_label.visible = false
	add_child(_pedestrian_walk_label)
	_pedestrian_countdown_label = Label3D.new()
	_pedestrian_countdown_label.name = "PedestrianSignalCountdown"
	_pedestrian_countdown_label.text = "10"
	_pedestrian_countdown_label.font_size = 24
	_pedestrian_countdown_label.pixel_size = 0.005
	_pedestrian_countdown_label.position = Vector3(8.0, 2.25, -43.15)
	_pedestrian_countdown_label.modulate = Color(0.92, 0.94, 0.98)
	add_child(_pedestrian_countdown_label)

func _build_traffic_vehicle() -> void:
	var traffic_colors: Array[Color] = [Color(0.72, 0.12, 0.08), Color(0.12, 0.32, 0.72), Color(0.78, 0.78, 0.72)]
	var traffic_speeds: Array[float] = [7.5, 8.2, 6.8]
	var traffic_positions: Array[float] = [-105.0, -58.0, -12.0]
	for traffic_index in range(traffic_colors.size()):
		var traffic_car := Node3D.new()
		traffic_car.name = "HighwayTrafficSedan_%02d" % (traffic_index + 1)
		traffic_car.position = Vector3(2.35, 0.0, traffic_positions[traffic_index])
		add_child(traffic_car)
		_add_traffic_collision_body(traffic_car, Vector3(1.9, 1.5, 3.8))
		traffic_car.add_child(_make_box("TrafficSedanBody", Vector3(1.75, 0.72, 3.6), Vector3(0.0, 0.72, 0.0), traffic_colors[traffic_index]))
		traffic_car.add_child(_make_box("TrafficSedanCabin", Vector3(1.48, 0.72, 1.75), Vector3(0.0, 1.38, -0.18), Color(0.12, 0.22, 0.29)))
		for x in [-0.9, 0.9]:
			for z in [-1.15, 1.15]:
				var tire := MeshInstance3D.new()
				var tire_mesh := CylinderMesh.new()
				tire_mesh.top_radius = 0.32
				tire_mesh.bottom_radius = 0.32
				tire_mesh.height = 0.18
				tire.mesh = tire_mesh
				tire.rotation_degrees.z = 90.0
				tire.position = Vector3(x, 0.38, z)
				var tire_material := StandardMaterial3D.new()
				tire_material.albedo_color = Color(0.025, 0.025, 0.03)
				tire.material_override = tire_material
				traffic_car.add_child(tire)
		_traffic_vehicles.append(traffic_car)
		_traffic_vehicle_speeds.append(traffic_speeds[traffic_index])
		_traffic_current_speeds.append(traffic_speeds[traffic_index])
	# A side-road vehicle waits at the give-way line while main-road traffic
	# has priority, then crosses during the red/amber phase.
	_side_road_traffic_vehicle = Node3D.new()
	_side_road_traffic_vehicle.name = "SideRoadGiveWaySedan"
	_side_road_traffic_vehicle.position = Vector3(18.0, 0.0, -48.0)
	add_child(_side_road_traffic_vehicle)
	_add_traffic_collision_body(_side_road_traffic_vehicle, Vector3(3.8, 1.5, 1.9))
	_side_road_traffic_vehicle.add_child(_make_box("SideRoadSedanBody", Vector3(3.6, 0.72, 1.75), Vector3(0.0, 0.72, 0.0), Color(0.82, 0.48, 0.08)))
	_side_road_traffic_vehicle.add_child(_make_box("SideRoadSedanCabin", Vector3(1.75, 0.72, 1.48), Vector3(0.15, 1.38, 0.0), Color(0.12, 0.22, 0.29)))
	for wheel_x in [-1.15, 1.15]:
		for wheel_z in [-0.9, 0.9]:
			var side_tire := MeshInstance3D.new()
			var side_tire_mesh := CylinderMesh.new()
			side_tire_mesh.top_radius = 0.31
			side_tire_mesh.bottom_radius = 0.31
			side_tire_mesh.height = 0.18
			side_tire.mesh = side_tire_mesh
			side_tire.rotation_degrees.x = 90.0
			side_tire.position = Vector3(wheel_x, 0.36, wheel_z)
			var side_tire_material := StandardMaterial3D.new()
			side_tire_material.albedo_color = Color(0.025, 0.025, 0.03)
			side_tire.material_override = side_tire_material
			_side_road_traffic_vehicle.add_child(side_tire)
	# Procedural pedestrian waits at the kerb, crosses the marked zebra crossing,
	# then returns to the far pavement for another crossing cycle.
	_junction_pedestrian = Node3D.new()
	_junction_pedestrian.name = "JunctionPedestrian"
	_junction_pedestrian.position = Vector3(7.0, 0.0, -52.7)
	add_child(_junction_pedestrian)
	_junction_pedestrian.add_child(_make_box("PedestrianTorso", Vector3(0.48, 0.82, 0.28), Vector3(0.0, 1.05, 0.0), Color(0.12, 0.38, 0.72)))
	_junction_pedestrian.add_child(_make_box("PedestrianHead", Vector3(0.34, 0.34, 0.34), Vector3(0.0, 1.66, 0.0), Color(0.72, 0.52, 0.38)))
	for leg_side in [-1.0, 1.0]:
		var leg_pivot := Node3D.new()
		leg_pivot.name = "PedestrianLegPivot_%s" % str(leg_side)
		leg_pivot.position = Vector3(leg_side * 0.13, 0.65, 0.0)
		_junction_pedestrian.add_child(leg_pivot)
		var leg_mesh := _make_box("PedestrianLeg", Vector3(0.16, 0.55, 0.18), Vector3(0.0, -0.27, 0.0), Color(0.12, 0.12, 0.15))
		leg_pivot.add_child(leg_mesh)
		_junction_pedestrian_legs.append(leg_pivot)


func _update_junction_pedestrian(delta: float) -> void:
	if not is_instance_valid(_junction_pedestrian):
		return
	_junction_pedestrian_walk_time += delta
	if _junction_pedestrian_crossing:
		_junction_pedestrian.position.z += 1.8 * delta
		for leg_index in range(_junction_pedestrian_legs.size()):
			var leg_swing := sin(_junction_pedestrian_walk_time * 8.0 + float(leg_index) * PI) * 0.34
			_junction_pedestrian_legs[leg_index].rotation.x = leg_swing
		if _junction_pedestrian.position.z >= -43.3:
			_junction_pedestrian_crossing = false
			_junction_pedestrian.position.z = -43.3
			_junction_pedestrian_clock = 7.0
	else:
		for leg in _junction_pedestrian_legs:
			leg.rotation.x = move_toward(leg.rotation.x, 0.0, delta * 2.5)
		# Trigger once per red phase; otherwise the pedestrian would restart
		# crossing immediately after reaching the far kerb in the same cycle.
		if _traffic_signal_clock < 10.0:
			_junction_pedestrian_phase_consumed = false
		if _traffic_signal_clock >= 10.0 and not _junction_pedestrian_phase_consumed:
			_junction_pedestrian_crossing = true
			_junction_pedestrian_phase_consumed = true


func _update_side_road_traffic(delta: float) -> void:
	if not is_instance_valid(_side_road_traffic_vehicle):
		return
	# Main road: green 0-8 s, amber 8-10 s, then red.
	# Pedestrians cross 10-16 s; 16-18 s is all-red clearance.
	# Side-road traffic receives a protected 18-24 s crossing window,
	# followed by 2 s all-red clearance before the next main-road green.
	var side_road_has_priority := _traffic_signal_clock >= 18.0 and _traffic_signal_clock < 24.0
	var junction_occupied := false
	# Do not enter the conflict zone while a main-road vehicle or the player
	# is physically passing through it. A vehicle already crossing is allowed
	# to clear the junction rather than stopping sideways in the carriageway.
	for traffic_vehicle in _traffic_vehicles:
		if is_instance_valid(traffic_vehicle) and absf(traffic_vehicle.position.z + 48.0) < 3.0:
			junction_occupied = true
			break
	if is_instance_valid(_active_vehicle) and absf(_active_vehicle.global_position.z + 48.0) < 4.0:
		junction_occupied = true
	var target_speed := 0.0
	var vehicle_committed_to_crossing := _side_road_traffic_vehicle.position.x <= 2.8
	var distance_to_yield_line := maxf(0.0, _side_road_traffic_vehicle.position.x - 2.8)
	# Give pedestrians the entire WALK interval and its clearance before
	# side-road traffic is permitted to enter the crossing.
	var pedestrian_conflict := _junction_pedestrian_crossing and _side_road_traffic_vehicle.position.x > 3.8 and _side_road_traffic_vehicle.position.x < 11.5
	if pedestrian_conflict:
		target_speed = 0.0
	elif vehicle_committed_to_crossing:
		# Once beyond the give-way line, clear the junction even as the phase ends.
		target_speed = 7.5
	elif side_road_has_priority and _side_road_traffic_vehicle.position.x > -5.5:
		# Enter only in the dedicated side-road window and when the junction is clear.
		if not junction_occupied:
			target_speed = 7.5
		else:
			# If another vehicle occupies the junction, stop smoothly at the line.
			target_speed = minf(3.8, sqrt(2.0 * 3.0 * distance_to_yield_line))
	else:
		# Approach the give-way line gently and calculate a stopping speed
		# from the remaining distance instead of braking abruptly at the marker.
		target_speed = minf(3.8, sqrt(2.0 * 3.0 * distance_to_yield_line))
	_side_road_traffic_speed = move_toward(_side_road_traffic_speed, target_speed, 5.0 * delta)
	_side_road_traffic_vehicle.position.x -= _side_road_traffic_speed * delta
	if _side_road_traffic_vehicle.position.x <= -18.0:
		# Complete the full crossing and clear the west exit before recycling.
		_side_road_traffic_vehicle.position.x = 18.0
		_side_road_traffic_speed = 0.0


func _add_traffic_collision_body(vehicle_root: Node3D, dimensions: Vector3) -> void:
	# Moving physics body makes traffic a real obstacle for the player vehicle,
	# rather than a visual-only mesh. Keep the collider slightly inside the body.
	var traffic_body := AnimatableBody3D.new()
	traffic_body.name = "TrafficCollisionBody"
	traffic_body.sync_to_physics = true
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	collision.position.y = 0.88
	traffic_body.add_child(collision)
	vehicle_root.add_child(traffic_body)


func _make_box(node_name: String, dimensions: Vector3, location: Vector3, tint: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var box := BoxMesh.new()
	box.size = dimensions
	mesh_instance.mesh = box
	mesh_instance.position = location
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	mesh_instance.material_override = material
	return mesh_instance


func _build_cargo_depot() -> void:
	_cargo_depot = Node3D.new()
	_cargo_depot.name = "OmanCargoLoadingDepot"
	var pickup_z := (8.0 + ROUTE_TARGETS[_selected_route].z) * 0.5
	_cargo_depot.position = Vector3(10.5, 0.0, pickup_z)
	add_child(_cargo_depot)
	var warehouse := _make_box("DepotWarehouse", Vector3(8.0, 5.2, 11.0), Vector3(0.0, 2.6, -7.0), Color(0.72, 0.67, 0.56))
	_cargo_depot.add_child(warehouse)
	var roof := _make_box("DepotRoof", Vector3(8.6, 0.28, 11.6), Vector3(0.0, 5.25, -7.0), Color(0.16, 0.22, 0.27))
	_cargo_depot.add_child(roof)
	var loading_door := _make_box("LoadingBayDoor", Vector3(4.2, 3.5, 0.16), Vector3(0.0, 1.95, -1.42), Color(0.12, 0.18, 0.21))
	_cargo_depot.add_child(loading_door)
	var sign := Label3D.new()
	sign.name = "DepotSign"
	sign.text = "OMAN LOGISTICS\\nCARGO LOADING"
	sign.position = Vector3(0.0, 4.45, -1.28)
	sign.font_size = 30
	sign.pixel_size = 0.012
	sign.modulate = Color(0.95, 0.9, 0.72)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_cargo_depot.add_child(sign)
	for x in [-3.3, 3.3]:
		var pillar := _make_box("DepotCanopyPillar", Vector3(0.25, 3.5, 0.25), Vector3(x, 1.75, 2.0), Color(0.62, 0.65, 0.67))
		_cargo_depot.add_child(pillar)
	var canopy := _make_box("LoadingCanopy", Vector3(7.2, 0.22, 4.0), Vector3(0.0, 3.55, 2.0), Color(0.12, 0.28, 0.36))
	_cargo_depot.add_child(canopy)
	for pallet_index in range(3):
		var pallet_z := 3.0 + float(pallet_index) * 1.8
		var pallet_root := Node3D.new()
		pallet_root.name = "CargoPalletAssembly_%d" % pallet_index
		pallet_root.position = Vector3(-2.1, 0.18, pallet_z)
		_cargo_depot.add_child(pallet_root)
		_depot_pallets.append(pallet_root)
		var pallet_deck := _make_box("PalletDeck", Vector3(1.55, 0.16, 1.35), Vector3.ZERO, Color(0.36, 0.22, 0.12))
		pallet_root.add_child(pallet_deck)
		for layer_index in range(2):
			var crate_color := Color(0.62, 0.38, 0.18) if pallet_index != 1 else Color(0.25, 0.48, 0.56)
			var crate := _make_box("CargoCrate_%d_%d" % [pallet_index, layer_index], Vector3(1.3, 0.72, 1.12), Vector3(0.0, 0.44 + float(layer_index) * 0.74, 0.0), crate_color)
			pallet_root.add_child(crate)
			_depot_crates.append(crate)
			_depot_crate_home_positions.append(crate.position)
	for slot_index in range(_depot_staging_positions.size()):
		var slot_position := _depot_staging_positions[slot_index]
		var staging_pad := _make_box("PalletStagingBay_%02d" % (slot_index + 1), Vector3(1.9, 0.035, 1.48), Vector3(slot_position.x, 0.075, slot_position.z), Color(0.9, 0.65, 0.12))
		_cargo_depot.add_child(staging_pad)
		var bay_label := Label3D.new()
		bay_label.name = "PalletBayLabel_%02d" % (slot_index + 1)
		bay_label.text = "STAGING BAY %02d" % (slot_index + 1)
		bay_label.position = Vector3(slot_position.x, 0.12, slot_position.z - 0.72)
		bay_label.font_size = 18
		bay_label.pixel_size = 0.009
		bay_label.modulate = Color(1.0, 0.88, 0.48)
		bay_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_cargo_depot.add_child(bay_label)
	_depot_pallet_staging_slots.clear()
	for pallet_index in range(_depot_pallets.size()):
		_depot_pallet_staging_slots.append(-1)
	var truck_bay_floor := _make_box("TruckLoadingBayFloor", Vector3(4.8, 0.035, 7.0), Vector3(-5.1, 0.065, 2.7), Color(0.24, 0.27, 0.28))
	_cargo_depot.add_child(truck_bay_floor)
	for bay_side in [-1.0, 1.0]:
		var bay_line := _make_box("TruckLoadingBayLine", Vector3(0.12, 0.025, 7.0), Vector3(-5.1 + bay_side * 2.3, 0.095, 2.7), Color(0.95, 0.78, 0.18))
		_cargo_depot.add_child(bay_line)
	var truck_bay_label := Label3D.new()
	truck_bay_label.name = "TruckLoadingBaySign"
	truck_bay_label.text = "TRUCK LOADING BAY"
	truck_bay_label.position = Vector3(-5.1, 0.18, -1.0)
	truck_bay_label.font_size = 22
	truck_bay_label.pixel_size = 0.01
	truck_bay_label.modulate = Color(1.0, 0.9, 0.55)
	truck_bay_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_cargo_depot.add_child(truck_bay_label)
	_build_depot_forklift()
	_build_depot_fuel_station()


func _build_depot_fuel_station() -> void:
	var station := Node3D.new()
	station.name = "OmanDepotFuelStation"
	station.position = Vector3(-9.0, 0.0, 5.2)
	_cargo_depot.add_child(station)
	var pad := _make_box("FuelStationConcretePad", Vector3(5.2, 0.12, 4.2), Vector3.ZERO, Color(0.34, 0.37, 0.38))
	station.add_child(pad)
	var canopy := _make_box("FuelStationCanopy", Vector3(5.0, 0.22, 3.8), Vector3(0.0, 3.35, 0.0), Color(0.08, 0.28, 0.38))
	station.add_child(canopy)
	for side in [-1.0, 1.0]:
		var pillar := _make_box("FuelCanopyPillar", Vector3(0.16, 3.3, 0.16), Vector3(side * 2.25, 1.65, 1.55), Color(0.72, 0.75, 0.76))
		station.add_child(pillar)
	var pump := _make_box("FuelDispenser", Vector3(0.72, 1.45, 0.62), Vector3(0.0, 0.82, -0.35), Color(0.88, 0.9, 0.86))
	station.add_child(pump)
	var display := _make_box("FuelDispenserScreen", Vector3(0.48, 0.28, 0.035), Vector3(0.0, 1.05, -0.68), Color(0.02, 0.12, 0.15))
	station.add_child(display)
	var label := Label3D.new()
	label.name = "FuelStationSign"
	label.text = "OMAN FUEL\\nDIESEL / PETROL"
	label.position = Vector3(0.0, 3.72, -0.05)
	label.font_size = 24
	label.pixel_size = 0.012
	label.modulate = Color(0.75, 0.95, 1.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	station.add_child(label)


func _build_roadside_fuel_station() -> void:
	var station := Node3D.new()
	station.name = "MuscatNizwaHighwayFuelStation"
	station.position = Vector3(-11.5, 0.0, -55.0)
	add_child(station)
	station.add_child(_make_box("FuelStationAccessLane", Vector3(8.0, 0.1, 12.0), Vector3(3.5, 0.04, 0.0), Color(0.22, 0.24, 0.25)))
	station.add_child(_make_box("FuelStationForecourt", Vector3(10.0, 0.14, 10.0), Vector3.ZERO, Color(0.38, 0.4, 0.39)))
	station.add_child(_make_box("HighwayFuelCanopy", Vector3(7.0, 0.24, 5.5), Vector3(0.0, 3.5, 0.0), Color(0.05, 0.3, 0.42)))
	for x in [-3.0, 3.0]:
		for z in [-2.2, 2.2]:
			station.add_child(_make_box("HighwayCanopyPillar", Vector3(0.18, 3.45, 0.18), Vector3(x, 1.72, z), Color(0.78, 0.8, 0.78)))
	for pump_index in range(2):
		var pump_x := -1.7 + float(pump_index) * 3.4
		station.add_child(_make_box("HighwayFuelDispenser", Vector3(0.72, 1.55, 0.68), Vector3(pump_x, 0.9, 0.0), Color(0.9, 0.91, 0.86)))
		station.add_child(_make_box("HighwayFuelScreen", Vector3(0.48, 0.3, 0.04), Vector3(pump_x, 1.15, -0.36), Color(0.02, 0.12, 0.15)))
	var sign := Label3D.new()
	sign.name = "HighwayFuelStationSign"
	sign.text = "OMAN FUEL  |  24H"
	sign.position = Vector3(0.0, 4.0, -3.5)
	sign.font_size = 28
	sign.pixel_size = 0.012
	sign.modulate = Color(0.76, 0.96, 1.0)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	station.add_child(sign)
	var price_board := Label3D.new()
	price_board.name = "FuelPriceBoard"
	price_board.text = "DIESEL  /  PETROL"
	price_board.position = Vector3(0.0, 2.0, 4.8)
	price_board.font_size = 18
	price_board.pixel_size = 0.01
	price_board.modulate = Color(1.0, 0.88, 0.45)
	price_board.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	station.add_child(price_board)


func _is_near_refuel_station() -> bool:
	if not is_instance_valid(_active_vehicle):
		return false
	var vehicle_position := _active_vehicle.global_position
	if is_instance_valid(_cargo_depot):
		var depot_station := _cargo_depot.to_global(Vector3(-9.0, 0.0, 5.2))
		if Vector2(vehicle_position.x - depot_station.x, vehicle_position.z - depot_station.z).length() <= 6.0:
			return true
	var roadside_station := Vector3(-11.5, 0.0, -55.0)
	return Vector2(vehicle_position.x - roadside_station.x, vehicle_position.z - roadside_station.z).length() <= 7.0


func _update_refuel_station_access() -> void:
	if not is_instance_valid(_active_vehicle):
		return
	if _active_vehicle.has_method("set_refuel_station_available"):
		_active_vehicle.set_refuel_station_available(_is_near_refuel_station(), _cash_balance)
	if _active_vehicle.has_method("set_service_station_available"):
		_active_vehicle.set_service_station_available(_is_near_refuel_station(), _cash_balance)


func _on_active_vehicle_damage_changed(_damage_percent: int) -> void:
	# Persist an impact immediately so an app interruption cannot discard vehicle condition.
	_save_progress()


func _on_vehicle_repair_requested(cost_omr: int) -> void:
	if not is_instance_valid(_active_vehicle) or not _is_near_refuel_station():
		return
	if not _active_vehicle.has_method("can_service_vehicle") or not _active_vehicle.can_service_vehicle():
		return
	if cost_omr <= 0 or _cash_balance < cost_omr:
		return
	_cash_balance -= cost_omr
	if _active_vehicle.has_method("complete_vehicle_repair"):
		_active_vehicle.complete_vehicle_repair()
	if _active_vehicle_index >= 0 and _active_vehicle_index < _vehicle_damage_levels.size():
		_vehicle_damage_levels[_active_vehicle_index] = 0
	if is_instance_valid(_cash_label):
		_cash_label.text = "WALLET  |  OMR %d  |  DELIVERIES %d" % [_cash_balance, _delivery_count]
	_save_progress()
	_update_refuel_station_access()

func _on_vehicle_refuel_requested(cost_omr: int) -> void:
	if not is_instance_valid(_active_vehicle):
		return
	if not _is_near_refuel_station() or not _active_vehicle.has_method("can_handle_cargo") or not _active_vehicle.can_handle_cargo():
		return
	if cost_omr <= 0 or _cash_balance < cost_omr:
		return
	_cash_balance -= cost_omr
	if _active_vehicle.has_method("complete_refuel"):
		_active_vehicle.complete_refuel()
	if is_instance_valid(_cash_label):
		_cash_label.text = "WALLET  |  OMR %d  |  DELIVERIES %d" % [_cash_balance, _delivery_count]
	_save_progress()


func _animate_depot_cargo(loading: bool) -> void:
	# A simple visible depot transfer sequence: crates move between the pallet area
	# and loading bay; the truck's own payload visibility is managed separately.
	for crate_index in range(_depot_crates.size()):
		var crate := _depot_crates[crate_index]
		if not is_instance_valid(crate):
			continue
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_IN_OUT)
		if loading:
			var staging := Vector3(0.0, 1.0 + float(crate_index % 2) * 0.08, 2.2)
			tween.tween_property(crate, "global_position", _cargo_depot.to_global(staging), 0.45 + float(crate_index) * 0.08)
			tween.tween_property(crate, "scale", Vector3.ZERO, 0.28)
			tween.tween_callback(crate.hide)
		else:
			crate.visible = true
			crate.scale = Vector3.ZERO
			crate.global_position = _cargo_depot.to_global(Vector3(0.0, 1.0 + float(crate_index % 2) * 0.08, 2.2))
			tween.tween_property(crate, "global_position", crate.get_parent().to_global(_depot_crate_home_positions[crate_index]), 0.45 + float(crate_index) * 0.08)
			tween.parallel().tween_property(crate, "scale", Vector3.ONE, 0.55)


func _build_depot_forklift() -> void:
	_forklift_root = Node3D.new()
	_forklift_root.name = "DepotForklift"
	var forklift := _forklift_root
	forklift.position = Vector3(2.0, 0.0, 3.2)
	forklift.rotation.y = PI * 0.5
	_cargo_depot.add_child(forklift)
	var safety_yellow := Color(0.92, 0.62, 0.08)
	var dark_metal := Color(0.12, 0.15, 0.17)
	var chassis := _make_box("ForkliftChassis", Vector3(1.25, 0.48, 1.9), Vector3(0.0, 0.62, 0.0), safety_yellow)
	forklift.add_child(chassis)
	var counterweight := _make_box("ForkliftCounterweight", Vector3(1.3, 0.72, 0.58), Vector3(0.0, 0.9, 0.62), safety_yellow)
	forklift.add_child(counterweight)
	var seat := _make_box("ForkliftSeat", Vector3(0.58, 0.22, 0.55), Vector3(0.0, 1.05, -0.05), dark_metal)
	forklift.add_child(seat)
	var mast := _make_box("ForkliftMast", Vector3(0.12, 2.05, 0.18), Vector3(0.0, 1.35, -0.93), dark_metal)
	forklift.add_child(mast)
	var mast_rail_left := _make_box("ForkliftMastRailLeft", Vector3(0.12, 2.1, 0.14), Vector3(-0.48, 1.38, -0.93), dark_metal)
	var mast_rail_right := _make_box("ForkliftMastRailRight", Vector3(0.12, 2.1, 0.14), Vector3(0.48, 1.38, -0.93), dark_metal)
	forklift.add_child(mast_rail_left)
	forklift.add_child(mast_rail_right)
	_forklift_carriage = Node3D.new()
	_forklift_carriage.name = "ForkliftMovingCarriage"
	_forklift_carriage.position = Vector3(0.0, _forklift_lift_level, -0.93)
	forklift.add_child(_forklift_carriage)
	var carriage_bar := _make_box("ForkliftCarriageBar", Vector3(1.05, 0.16, 0.16), Vector3(0.0, 0.0, 0.0), dark_metal)
	_forklift_carriage.add_child(carriage_bar)
	var fork_left := _make_box("ForkliftForkLeft", Vector3(0.16, 0.12, 1.35), Vector3(-0.36, -0.12, -0.62), Color(0.65, 0.68, 0.7))
	var fork_right := _make_box("ForkliftForkRight", Vector3(0.16, 0.12, 1.35), Vector3(0.36, -0.12, -0.62), Color(0.65, 0.68, 0.7))
	_forklift_carriage.add_child(fork_left)
	_forklift_carriage.add_child(fork_right)
	for x in [-0.68, 0.68]:
		for z in [-0.58, 0.62]:
			var wheel := MeshInstance3D.new()
			wheel.name = "ForkliftWheel"
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.31
			wheel_mesh.bottom_radius = 0.31
			wheel_mesh.height = 0.2
			wheel.mesh = wheel_mesh
			wheel.rotation.z = PI * 0.5
			wheel.position = Vector3(x, 0.34, z)
			var rubber := StandardMaterial3D.new()
			rubber.albedo_color = Color(0.025, 0.027, 0.03)
			wheel.material_override = rubber
			forklift.add_child(wheel)
			_forklift_wheel_nodes.append(wheel)
	for x in [-0.62, 0.62]:
		var guard_post := _make_box("ForkliftOverheadGuardPost", Vector3(0.1, 1.45, 0.1), Vector3(x, 1.55, 0.28), dark_metal)
		forklift.add_child(guard_post)
	var guard_roof := _make_box("ForkliftOverheadGuardRoof", Vector3(1.45, 0.12, 1.45), Vector3(0.0, 2.3, 0.28), dark_metal)
	forklift.add_child(guard_roof)
	var beacon := MeshInstance3D.new()
	beacon.name = "ForkliftAmberBeacon"
	var beacon_mesh := CylinderMesh.new()
	beacon_mesh.top_radius = 0.13
	beacon_mesh.bottom_radius = 0.13
	beacon_mesh.height = 0.2
	beacon.mesh = beacon_mesh
	beacon.position = Vector3(0.0, 2.48, 0.28)
	var beacon_material := StandardMaterial3D.new()
	beacon_material.albedo_color = Color(1.0, 0.48, 0.04)
	beacon_material.emission_enabled = true
	beacon_material.emission = Color(1.0, 0.32, 0.015)
	beacon.material_override = beacon_material
	forklift.add_child(beacon)
	_forklift_beacon = OmniLight3D.new()
	_forklift_beacon.name = "ForkliftBeaconLight"
	_forklift_beacon.light_color = Color(1.0, 0.42, 0.06)
	_forklift_beacon.light_energy = 0.8
	_forklift_beacon.omni_range = 3.5
	_forklift_beacon.position = Vector3(0.0, 2.5, 0.28)
	forklift.add_child(_forklift_beacon)

func _raise_forklift_forks() -> void:
	_set_forklift_lift_level(_forklift_lift_level + 0.18)


func _lower_forklift_forks() -> void:
	_set_forklift_lift_level(_forklift_lift_level - 0.18)


func _tilt_forklift_back() -> void:
	_set_forklift_tilt(_forklift_tilt_angle - 0.06)


func _tilt_forklift_forward() -> void:
	_set_forklift_tilt(_forklift_tilt_angle + 0.06)


func _set_forklift_tilt(value: float) -> void:
	_forklift_tilt_angle = clampf(value, -0.18, 0.18)
	if is_instance_valid(_forklift_carriage):
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(_forklift_carriage, "rotation:x", _forklift_tilt_angle, 0.18)
	if is_instance_valid(_forklift_tilt_label):
		if absf(_forklift_tilt_angle) < 0.015:
			_forklift_tilt_label.text = "FORK TILT: LEVEL"
		else:
			_forklift_tilt_label.text = "FORK TILT: %s %.0f deg" % ["BACK" if _forklift_tilt_angle < 0.0 else "FORWARD", rad_to_deg(absf(_forklift_tilt_angle))]


func _set_forklift_lift_level(value: float) -> void:
	_forklift_lift_level = clampf(value, 0.18, 1.72)
	if is_instance_valid(_forklift_carriage):
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(_forklift_carriage, "position:y", _forklift_lift_level, 0.22)
	if is_instance_valid(_forklift_lift_label):
		_forklift_lift_label.text = "FORK HEIGHT: %.2f m" % _forklift_lift_level


func _move_forklift_forward() -> void:
	_move_forklift_local(Vector3(0.0, 0.0, -0.38))


func _move_forklift_back() -> void:
	_move_forklift_local(Vector3(0.0, 0.0, 0.38))


func _move_forklift_left() -> void:
	_move_forklift_local(Vector3(-0.38, 0.0, 0.0))


func _move_forklift_right() -> void:
	_move_forklift_local(Vector3(0.38, 0.0, 0.0))


func _turn_forklift_left() -> void:
	_rotate_forklift(0.16)


func _turn_forklift_right() -> void:
	_rotate_forklift(-0.16)


func _rotate_forklift(amount: float) -> void:
	if not is_instance_valid(_forklift_root):
		return
	_forklift_root.rotate_y(amount)


func _move_forklift_local(offset: Vector3) -> void:
	if not is_instance_valid(_forklift_root):
		return
	if is_instance_valid(_forklift_held_pallet) and _forklift_lift_level > 0.82:
		_forklift_cargo_label.text = "LOWER LOAD BEFORE DRIVING"
		return
	var world_offset := _forklift_root.basis * offset
	_forklift_root.position += Vector3(world_offset.x, 0.0, world_offset.z)
	_forklift_root.position.x = clampf(_forklift_root.position.x, -3.2, 3.5)
	_forklift_root.position.z = clampf(_forklift_root.position.z, -0.2, 6.2)
	for wheel in _forklift_wheel_nodes:
		if is_instance_valid(wheel):
			wheel.rotate_x(-offset.z * 1.8)


func _toggle_forklift_crate() -> void:
	if is_instance_valid(_forklift_held_pallet):
		if _forklift_lift_level > 0.42:
			_forklift_cargo_label.text = "LOWER FORKS TO SET PALLET DOWN"
			return
		var pallet_index := _depot_pallets.find(_forklift_held_pallet)
		var nearest_slot := -1
		var nearest_slot_distance := 1.25
		for slot_index in range(_depot_staging_positions.size()):
			if slot_index < _depot_pallet_staging_slots.size() and _depot_pallet_staging_slots[slot_index] != -1:
				continue
			var slot_world := _cargo_depot.to_global(_depot_staging_positions[slot_index])
			var distance := _forklift_held_pallet.global_position.distance_to(slot_world)
			if distance < nearest_slot_distance:
				nearest_slot_distance = distance
				nearest_slot = slot_index
		_forklift_held_pallet.reparent(_cargo_depot, true)
		if nearest_slot >= 0:
			_forklift_held_pallet.position = _depot_staging_positions[nearest_slot]
			if pallet_index >= 0:
				_depot_pallet_staging_slots[nearest_slot] = pallet_index
			_forklift_cargo_label.text = "PALLET STAGED: BAY %02d" % (nearest_slot + 1)
		else:
			_forklift_cargo_label.text = "PALLET PARKED - ALIGN WITH A STAGING BAY"
		_forklift_held_pallet = null
		_set_forklift_tilt(0.0)
		return
	if not is_instance_valid(_forklift_root) or not is_instance_valid(_forklift_carriage):
		return
	if _forklift_lift_level > 0.72:
		_forklift_cargo_label.text = "LOWER FORKS TO GRAB"
		return
	var fork_tip := _forklift_root.to_global(Vector3(0.0, _forklift_lift_level - 0.12, -1.55))
	var forklift_forward := -_forklift_root.global_basis.z.normalized()
	var forklift_right := _forklift_root.global_basis.x.normalized()
	var nearest_pallet: Node3D
	var nearest_distance := 1.35
	for pallet in _depot_pallets:
		if not is_instance_valid(pallet) or not pallet.visible:
			continue
		var to_pallet := pallet.global_position - fork_tip
		var distance := to_pallet.length()
		if distance >= nearest_distance:
			continue
		var direction := to_pallet.normalized()
		var forward_alignment := forklift_forward.dot(direction)
		var side_offset := absf(forklift_right.dot(direction))
		if forward_alignment < 0.78 or side_offset > 0.42:
			continue
		nearest_distance = distance
		nearest_pallet = pallet
	if not is_instance_valid(nearest_pallet):
		_forklift_cargo_label.text = "ALIGN FORKS WITH PALLET"
		return
	var picked_index := _depot_pallets.find(nearest_pallet)
	if picked_index >= 0:
		for slot_index in range(_depot_pallet_staging_slots.size()):
			if _depot_pallet_staging_slots[slot_index] == picked_index:
				_depot_pallet_staging_slots[slot_index] = -1
	_forklift_held_pallet = nearest_pallet
	_forklift_held_pallet.reparent(_forklift_carriage, true)
	_forklift_held_pallet.position = Vector3(0.0, 0.34, -0.92)
	var crate_count := 0
	for crate in _depot_crates:
		if is_instance_valid(crate) and crate.get_parent() == _forklift_held_pallet:
			crate_count += 1
	_forklift_cargo_label.text = "PALLET SECURED: %d CRATES" % crate_count

func _release_forklift_load_for_mission() -> void:
	if not is_instance_valid(_forklift_held_pallet):
		return
	_forklift_held_pallet.reparent(_cargo_depot, true)
	var pallet_index := _depot_pallets.find(_forklift_held_pallet)
	if pallet_index >= 0:
		_forklift_held_pallet.position = Vector3(-2.1, 0.18, 3.0 + float(pallet_index) * 1.8)
		for slot_index in range(_depot_pallet_staging_slots.size()):
			if _depot_pallet_staging_slots[slot_index] == pallet_index:
				_depot_pallet_staging_slots[slot_index] = -1
		for crate_index in range(_depot_crates.size()):
			if _depot_crates[crate_index].get_parent() == _forklift_held_pallet:
				_depot_crates[crate_index].position = _depot_crate_home_positions[crate_index]
	_forklift_held_pallet = null
	if is_instance_valid(_forklift_cargo_label):
		_forklift_cargo_label.text = "LOAD: EMPTY"


func _build_passenger_waiting_group() -> void:
	_passenger_waiting_group = Node3D.new()
	_passenger_waiting_group.name = "PassengerPickupCrowd"
	_passenger_waiting_group.visible = _passenger_mode
	var stop_z := (8.0 + ROUTE_TARGETS[_selected_route].z) * 0.5
	_passenger_waiting_group.position = Vector3(5.2, 0.0, stop_z)
	add_child(_passenger_waiting_group)
	var shirt_colors := [Color(0.12, 0.32, 0.62), Color(0.62, 0.18, 0.12), Color(0.16, 0.46, 0.28), Color(0.58, 0.42, 0.18)]
	for i in range(PASSENGER_GROUP_SIZE):
		var person := Node3D.new()
		person.name = "WaitingPassenger_%02d" % (i + 1)
		person.position = Vector3(float(i % 2) * 0.72, 0.0, float(i / 2) * 0.82)
		_passenger_waiting_group.add_child(person)
		var torso_node := MeshInstance3D.new()
		var torso := CapsuleMesh.new()
		torso.radius = 0.19
		torso.height = 0.82
		torso_node.mesh = torso
		torso_node.position.y = 0.78
		var shirt_mat := StandardMaterial3D.new()
		shirt_mat.albedo_color = shirt_colors[i % shirt_colors.size()]
		torso_node.material_override = shirt_mat
		person.add_child(torso_node)
		var head := MeshInstance3D.new()
		var head_mesh := SphereMesh.new()
		head_mesh.radius = 0.15
		head_mesh.height = 0.3
		head.mesh = head_mesh
		head.position.y = 1.34
		var skin := StandardMaterial3D.new()
		skin.albedo_color = Color(0.66, 0.48, 0.34)
		head.material_override = skin
		person.add_child(head)

func _build_mission() -> void:
	_checkpoint_area = Area3D.new()
	_checkpoint_area.name = "DeliveryCheckpoint"
	_checkpoint_area.position = _mission_target
	var trigger := CollisionShape3D.new()
	var trigger_shape := BoxShape3D.new()
	trigger_shape.size = Vector3(8.0, 4.0, 5.0)
	trigger.shape = trigger_shape
	trigger.position.y = 1.5
	_checkpoint_area.add_child(trigger)
	_checkpoint_area.body_entered.connect(_on_checkpoint_entered)
	add_child(_checkpoint_area)

	var gate_material := StandardMaterial3D.new()
	gate_material.albedo_color = Color(0.05, 0.55, 0.34)
	var left_post := _make_box("CheckpointLeftPost", Vector3(0.22, 3.2, 0.22), Vector3(-4.0, 1.6, _mission_target.z), gate_material.albedo_color)
	var right_post := _make_box("CheckpointRightPost", Vector3(0.22, 3.2, 0.22), Vector3(4.0, 1.6, _mission_target.z), gate_material.albedo_color)
	var top_bar := _make_box("CheckpointTopBar", Vector3(8.2, 0.22, 0.22), Vector3(0.0, 3.1, _mission_target.z), gate_material.albedo_color)
	_checkpoint_gate_parts = [left_post, right_post, top_bar]
	_checkpoint_label = Label3D.new()
	_checkpoint_label.name = "CheckpointSign"
	_checkpoint_label.position = Vector3(0.0, 3.75, _mission_target.z)
	_checkpoint_label.text = "DELIVERY"
	_checkpoint_label.font_size = 40
	_checkpoint_label.pixel_size = 0.01
	_checkpoint_label.modulate = Color(0.85, 1.0, 0.9)
	_checkpoint_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_checkpoint_label)
	add_child(left_post)
	add_child(right_post)
	add_child(top_bar)

func _build_mission_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
	_cargo_button = Button.new()
	_cargo_button.name = "CargoSelector"
	_cargo_button.text = "CARGO: " + CARGO_NAMES[_selected_cargo]
	_cargo_button.position = Vector2(24.0, 78.0)
	_cargo_button.custom_minimum_size = Vector2(250.0, 48.0)
	_cargo_button.add_theme_font_size_override("font_size", 16)
	_cargo_button.pressed.connect(_cycle_cargo)
	layer.add_child(_cargo_button)

	_mission_type_button = Button.new()
	_mission_type_button.name = "MissionTypeSelector"
	_mission_type_button.text = "JOB: PASSENGER" if _passenger_mode else "JOB: CARGO"
	_mission_type_button.position = Vector2(24.0, 134.0)
	_mission_type_button.custom_minimum_size = Vector2(250.0, 48.0)
	_mission_type_button.add_theme_font_size_override("font_size", 16)
	_mission_type_button.pressed.connect(_toggle_passenger_mode)
	layer.add_child(_mission_type_button)
	_cargo_button.visible = not _passenger_mode

	_route_button = Button.new()
	_route_button.name = "RouteSelector"
	_route_button.text = "ROUTE: " + ROUTE_NAMES[_selected_route]
	_route_button.position = Vector2(24.0, 22.0)
	_route_button.custom_minimum_size = Vector2(250.0, 48.0)
	_route_button.add_theme_font_size_override("font_size", 16)
	_route_button.pressed.connect(_cycle_route)
	layer.add_child(_route_button)


	var company_button := Button.new()
	company_button.name = "TransportCompany"
	company_button.text = "MY TRANSPORT COMPANY"
	company_button.anchor_left = 1.0
	company_button.anchor_right = 1.0
	company_button.offset_left = -224.0
	company_button.offset_right = -20.0
	company_button.offset_top = 204.0
	company_button.offset_bottom = 252.0
	company_button.add_theme_font_size_override("font_size", 15)
	company_button.pressed.connect(_toggle_company_panel)
	layer.add_child(company_button)

	_cash_label = Label.new()
	_cash_label.name = "CashBalance"
	_cash_label.text = "WALLET  |  OMR %d  |  DELIVERIES %d" % [_cash_balance, _delivery_count]
	_cash_label.position = Vector2(24.0, 190.0)
	_cash_label.add_theme_font_size_override("font_size", 20)
	_cash_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.72))
	layer.add_child(_cash_label)

	_passenger_status_label = Label.new()
	_passenger_status_label.name = "PassengerManifest"
	_passenger_status_label.text = "PASSENGERS ON BOARD: 0"
	_passenger_status_label.position = Vector2(24.0, 222.0)
	_passenger_status_label.add_theme_font_size_override("font_size", 18)
	_passenger_status_label.add_theme_color_override("font_color", Color(0.72, 0.88, 1.0))
	_passenger_status_label.visible = _passenger_mode
	layer.add_child(_passenger_status_label)

	_cargo_status_label = Label.new()
	_cargo_status_label.name = "CargoManifest"
	_cargo_status_label.text = "CARGO STATUS: WAITING FOR LOAD"
	_cargo_status_label.position = Vector2(24.0, 222.0)
	_cargo_status_label.add_theme_font_size_override("font_size", 18)
	_cargo_status_label.add_theme_color_override("font_color", Color(1.0, 0.83, 0.58))
	_cargo_status_label.visible = not _passenger_mode
	layer.add_child(_cargo_status_label)

	_warehouse_load_button = Button.new()
	_warehouse_load_button.name = "WarehouseTruckLoad"
	_warehouse_load_button.text = "LOAD STAGED PALLET"
	_warehouse_load_button.position = Vector2(24.0, 278.0)
	_warehouse_load_button.custom_minimum_size = Vector2(250.0, 48.0)
	_warehouse_load_button.add_theme_font_size_override("font_size", 16)
	_warehouse_load_button.visible = false
	_warehouse_load_button.pressed.connect(_load_truck_from_warehouse)
	layer.add_child(_warehouse_load_button)

	_cargo_unload_button = Button.new()
	_cargo_unload_button.name = "CargoDeliveryUnload"
	_cargo_unload_button.text = "UNLOAD DELIVERED CARGO"
	_cargo_unload_button.position = Vector2(24.0, 334.0)
	_cargo_unload_button.custom_minimum_size = Vector2(250.0, 48.0)
	_cargo_unload_button.add_theme_font_size_override("font_size", 16)
	_cargo_unload_button.visible = false
	_cargo_unload_button.pressed.connect(_unload_delivered_cargo)
	layer.add_child(_cargo_unload_button)

	var forklift_panel := VBoxContainer.new()
	forklift_panel.name = "ForkliftLiftControls"
	forklift_panel.anchor_left = 1.0
	forklift_panel.anchor_top = 1.0
	forklift_panel.anchor_right = 1.0
	forklift_panel.anchor_bottom = 1.0
	forklift_panel.offset_left = -190.0
	forklift_panel.offset_top = -530.0
	forklift_panel.offset_right = -20.0
	forklift_panel.offset_bottom = -24.0
	forklift_panel.add_theme_constant_override("separation", 6)
	layer.add_child(forklift_panel)
	var forklift_title := Label.new()
	forklift_title.text = "DEPOT FORKLIFT"
	forklift_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	forklift_panel.add_child(forklift_title)
	_forklift_lift_label = Label.new()
	_forklift_lift_label.text = "FORK HEIGHT: 0.48 m"
	_forklift_lift_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	forklift_panel.add_child(_forklift_lift_label)
	_forklift_tilt_label = Label.new()
	_forklift_tilt_label.text = "FORK TILT: LEVEL"
	_forklift_tilt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	forklift_panel.add_child(_forklift_tilt_label)
	var tilt_back_button := Button.new()
	tilt_back_button.text = "TILT BACK"
	tilt_back_button.custom_minimum_size.y = 40
	tilt_back_button.pressed.connect(_tilt_forklift_back)
	forklift_panel.add_child(tilt_back_button)
	var tilt_forward_button := Button.new()
	tilt_forward_button.text = "TILT FORWARD"
	tilt_forward_button.custom_minimum_size.y = 40
	tilt_forward_button.pressed.connect(_tilt_forklift_forward)
	forklift_panel.add_child(tilt_forward_button)
	var lift_up_button := Button.new()
	lift_up_button.text = "FORKS UP  +"
	lift_up_button.custom_minimum_size.y = 48
	lift_up_button.pressed.connect(_raise_forklift_forks)
	forklift_panel.add_child(lift_up_button)
	var lift_down_button := Button.new()
	lift_down_button.text = "FORKS DOWN  -"
	lift_down_button.custom_minimum_size.y = 48
	lift_down_button.pressed.connect(_lower_forklift_forks)
	forklift_panel.add_child(lift_down_button)

	_forklift_cargo_label = Label.new()
	_forklift_cargo_label.text = "LOAD: EMPTY"
	_forklift_cargo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_forklift_panel.add_child(_forklift_cargo_label)
	var forklift_forward := Button.new()
	forklift_forward.text = "MOVE FORWARD"
	forklift_forward.custom_minimum_size.y = 42
	forklift_forward.pressed.connect(_move_forklift_forward)
	forklift_panel.add_child(forklift_forward)
	var forklift_back := Button.new()
	forklift_back.text = "MOVE BACK"
	forklift_back.custom_minimum_size.y = 42
	forklift_back.pressed.connect(_move_forklift_back)
	forklift_panel.add_child(forklift_back)
	var forklift_left := Button.new()
	forklift_left.text = "MOVE LEFT"
	forklift_left.custom_minimum_size.y = 42
	forklift_left.pressed.connect(_move_forklift_left)
	forklift_panel.add_child(forklift_left)
	var forklift_right := Button.new()
	forklift_right.text = "MOVE RIGHT"
	forklift_right.custom_minimum_size.y = 42
	forklift_right.pressed.connect(_move_forklift_right)
	forklift_panel.add_child(forklift_right)
	var forklift_turn_left := Button.new()
	forklift_turn_left.text = "STEER LEFT"
	forklift_turn_left.custom_minimum_size.y = 38
	forklift_turn_left.pressed.connect(_turn_forklift_left)
	forklift_panel.add_child(forklift_turn_left)
	var forklift_turn_right := Button.new()
	forklift_turn_right.text = "STEER RIGHT"
	forklift_turn_right.custom_minimum_size.y = 38
	forklift_turn_right.pressed.connect(_turn_forklift_right)
	forklift_panel.add_child(forklift_turn_right)
	var forklift_load_button := Button.new()
	forklift_load_button.text = "GRAB / RELEASE CRATE"
	forklift_load_button.custom_minimum_size.y = 48
	forklift_load_button.pressed.connect(_toggle_forklift_crate)
	forklift_panel.add_child(forklift_load_button)

	_mission_label = Label.new()
	_mission_label.name = "MissionStatus"
	_mission_label.text = "DELIVERY RUN  |  CHECKPOINT: 000 m"
	_mission_label.anchor_left = 0.5
	_mission_label.anchor_right = 0.5
	_mission_label.offset_left = -190.0
	_mission_label.offset_right = 190.0
	_mission_label.offset_top = 76.0
	_mission_label.offset_bottom = 112.0
	_mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mission_label.add_theme_font_size_override("font_size", 18)
	_mission_label.add_theme_color_override("font_color", Color.WHITE)
	layer.add_child(_mission_label)

	_junction_status_label = Label.new()
	_junction_status_label.name = "JunctionPhaseStatus"
	_junction_status_label.anchor_left = 0.05
	_junction_status_label.anchor_right = 0.95
	_junction_status_label.offset_top = 112.0
	_junction_status_label.offset_bottom = 138.0
	_junction_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_junction_status_label.add_theme_font_size_override("font_size", 14)
	_junction_status_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.42))
	layer.add_child(_junction_status_label)

	_speed_limit_status_label = Label.new()
	_speed_limit_status_label.name = "SpeedLimitStatus"
	_speed_limit_status_label.anchor_left = 0.05
	_speed_limit_status_label.anchor_right = 0.95
	_speed_limit_status_label.offset_top = 138.0
	_speed_limit_status_label.offset_bottom = 160.0
	_speed_limit_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speed_limit_status_label.add_theme_font_size_override("font_size", 13)
	_speed_limit_status_label.add_theme_color_override("font_color", Color(0.68, 0.9, 0.76))
	layer.add_child(_speed_limit_status_label)

	_road_position_status_label = Label.new()
	_road_position_status_label.name = "RoadPositionStatus"
	_road_position_status_label.anchor_left = 0.05
	_road_position_status_label.anchor_right = 0.95
	_road_position_status_label.offset_top = 160.0
	_road_position_status_label.offset_bottom = 182.0
	_road_position_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_road_position_status_label.add_theme_font_size_override("font_size", 13)
	_road_position_status_label.add_theme_color_override("font_color", Color(0.68, 0.9, 0.76))
	layer.add_child(_road_position_status_label)

	_pedestrian_warning_label = Label.new()
	_pedestrian_warning_label.name = "PedestrianWarning"
	_pedestrian_warning_label.anchor_left = 0.05
	_pedestrian_warning_label.anchor_right = 0.95
	_pedestrian_warning_label.offset_top = 182.0
	_pedestrian_warning_label.offset_bottom = 204.0
	_pedestrian_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pedestrian_warning_label.add_theme_font_size_override("font_size", 13)
	_pedestrian_warning_label.add_theme_color_override("font_color", Color(0.68, 0.9, 0.76))
	layer.add_child(_pedestrian_warning_label)

	_stop_line_warning_label = Label.new()
	_stop_line_warning_label.name = "StopLineWarning"
	_stop_line_warning_label.anchor_left = 0.05
	_stop_line_warning_label.anchor_right = 0.95
	_stop_line_warning_label.offset_top = 204.0
	_stop_line_warning_label.offset_bottom = 226.0
	_stop_line_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stop_line_warning_label.add_theme_font_size_override("font_size", 13)
	_stop_line_warning_label.add_theme_color_override("font_color", Color(0.68, 0.78, 0.9))
	layer.add_child(_stop_line_warning_label)

	_restart_button = Button.new()
	_restart_button.name = "RestartDelivery"
	_restart_button.text = "RESTART ROUTE"
	_restart_button.anchor_left = 1.0
	_restart_button.anchor_right = 1.0
	_restart_button.offset_left = -190.0
	_restart_button.offset_right = -20.0
	_restart_button.offset_top = 88.0
	_restart_button.offset_bottom = 136.0
	_restart_button.add_theme_font_size_override("font_size", 16)
	_restart_button.pressed.connect(_restart_delivery)
	layer.add_child(_restart_button)


func _initialize_company_records() -> void:
	if _company_fleet.is_empty():
		for bus_index in range(maxi(_company_bus_count, 1)):
			_company_fleet.append({"name": "Company Bus %03d" % (bus_index + 1), "type": "INTERCITY COACH", "status": "AVAILABLE"})
	if _company_drivers.is_empty():
		for driver_index in range(_company_driver_count):
			_company_drivers.append({"name": "Driver %03d" % (driver_index + 1), "status": "AVAILABLE", "route": "UNASSIGNED", "bus": "NO BUS"})
	# A simulated trip is not yet persisted across app restarts; release any
	# vehicles and employees that were marked ON ROUTE in the previous session.
	for bus in _company_fleet:
		bus["status"] = "AVAILABLE"
	for driver in _company_drivers:
		driver["status"] = "AVAILABLE"
		driver["route"] = "UNASSIGNED"
		driver["bus"] = "NO BUS"
	for bus in _company_fleet:
		if not bus.has("route_index"):
			bus["route_index"] = _company_selected_route
		if not bus.has("vehicle_index"):
			bus["vehicle_index"] = 3
		if not bus.has("assigned_driver_index"):
			bus["assigned_driver_index"] = -1
		if not bus.has("condition"):
			bus["condition"] = 100
	_company_bus_count = _company_fleet.size()
	_company_driver_count = _company_drivers.size()

func _build_company_management() -> void:
	_company_trip_timer = Timer.new()
	_company_trip_timer.name = "CompanyDriverTripTimer"
	_company_trip_timer.one_shot = true
	_company_trip_timer.wait_time = 30.0
	_company_trip_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_company_trip_timer.timeout.connect(_on_company_driver_trip_completed)
	add_child(_company_trip_timer)

	var layer := CanvasLayer.new()
	layer.name = "CompanyManagementLayer"
	layer.layer = 30
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	_company_panel = ColorRect.new()
	_company_panel.name = "CompanyManagementOverlay"
	_company_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_company_panel.color = Color(0.015, 0.035, 0.06, 0.94)
	_company_panel.visible = false
	layer.add_child(_company_panel)

	var panel := PanelContainer.new()
	panel.name = "CompanyManagementPanel"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -260.0
	panel.offset_top = -365.0
	panel.offset_right = 260.0
	panel.offset_bottom = 365.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.075, 0.11, 1.0)
	panel_style.border_color = Color(0.12, 0.58, 0.78, 1.0)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(16)
	panel.add_theme_stylebox_override("panel", panel_style)
	_company_panel.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)

	var heading := Label.new()
	heading.text = "TRANSPORT COMPANY"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 25)
	heading.add_theme_color_override("font_color", Color(0.35, 0.82, 1.0))
	content.add_child(heading)

	_company_name_edit = LineEdit.new()
	_company_name_edit.placeholder_text = "Enter your company name"
	_company_name_edit.text = _company_name
	_company_name_edit.max_length = 28
	_company_name_edit.text_submitted.connect(_on_company_name_submitted)
	content.add_child(_company_name_edit)

	_company_summary_label = Label.new()
	_company_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_company_summary_label.add_theme_font_size_override("font_size", 17)
	content.add_child(_company_summary_label)

	var route_label := Label.new()
	route_label.text = "COMPANY DISPATCH ROUTE"
	route_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(route_label)

	_company_route_option = OptionButton.new()
	_company_route_option.custom_minimum_size.y = 42
	for route_name in ROUTE_NAMES:
		_company_route_option.add_item(route_name)
	_company_route_option.select(_company_selected_route)
	_company_route_option.item_selected.connect(_on_company_route_selected)
	content.add_child(_company_route_option)

	var bus_config_label := Label.new()
	bus_config_label.text = "CONFIGURE INDIVIDUAL COMPANY BUS"
	bus_config_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(bus_config_label)
	_company_config_bus_option = OptionButton.new()
	_company_config_bus_option.custom_minimum_size.y = 38
	_company_config_bus_option.item_selected.connect(_on_company_config_bus_selected)
	content.add_child(_company_config_bus_option)
	_company_config_route_option = OptionButton.new()
	_company_config_route_option.custom_minimum_size.y = 38
	for route_name in ROUTE_NAMES:
		_company_config_route_option.add_item(route_name)
	_company_config_route_option.item_selected.connect(_on_company_config_route_selected)
	content.add_child(_company_config_route_option)
	var vehicle_label := Label.new()
	vehicle_label.text = "VEHICLE MODEL FOR THIS COMPANY BUS"
	vehicle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(vehicle_label)
	_company_config_vehicle_option = OptionButton.new()
	_company_config_vehicle_option.custom_minimum_size.y = 38
	for vehicle_name in FLEET_NAMES:
		_company_config_vehicle_option.add_item(vehicle_name)
	_company_config_vehicle_option.item_selected.connect(_on_company_config_vehicle_selected)
	content.add_child(_company_config_vehicle_option)
	var driver_label := Label.new()
	driver_label.text = "PREFERRED DRIVER FOR THIS BUS"
	driver_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(driver_label)
	_company_config_driver_option = OptionButton.new()
	_company_config_driver_option.custom_minimum_size.y = 38
	_company_config_driver_option.item_selected.connect(_on_company_config_driver_selected)
	content.add_child(_company_config_driver_option)
	var schedule_label := Label.new()
	schedule_label.text = "DEPARTURE SCHEDULE"
	schedule_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(schedule_label)
	_company_schedule_option = OptionButton.new()
	_company_schedule_option.custom_minimum_size.y = 38
	_company_schedule_option.add_item("Depart immediately", 0)
	_company_schedule_option.add_item("Depart in 10 seconds", 10)
	_company_schedule_option.add_item("Depart in 30 seconds", 30)
	content.add_child(_company_schedule_option)

	_company_roster_label = Label.new()
	_company_roster_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_company_roster_label.add_theme_font_size_override("font_size", 13)
	_company_roster_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_company_roster_label)

	_company_status_label = Label.new()
	_company_status_label.text = "Your company is ready to operate."
	_company_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_company_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_company_status_label.add_theme_color_override("font_color", Color(0.65, 0.85, 0.92))
	content.add_child(_company_status_label)

	var hire_button := Button.new()
	hire_button.text = "HIRE DRIVER  |  OMR 80"
	hire_button.custom_minimum_size.y = 48
	hire_button.pressed.connect(_hire_company_driver)
	content.add_child(hire_button)

	var service_button := Button.new()
	service_button.text = "SERVICE SELECTED BUS  |  OMR 1 PER CONDITION POINT"
	service_button.custom_minimum_size.y = 48
	service_button.pressed.connect(_service_selected_company_bus)
	content.add_child(service_button)

	var bus_button := Button.new()
	bus_button.text = "BUY ADDITIONAL BUS  |  OMR 450"
	bus_button.custom_minimum_size.y = 48
	bus_button.pressed.connect(_buy_company_bus)
	content.add_child(bus_button)

	_company_dispatch_button = Button.new()
	_company_dispatch_button.text = "ASSIGN DRIVER & SEND TO WORK"
	_company_dispatch_button.custom_minimum_size.y = 52
	_company_dispatch_button.pressed.connect(_dispatch_company_driver)
	content.add_child(_company_dispatch_button)

	var close_button := Button.new()
	close_button.text = "CLOSE"
	close_button.custom_minimum_size.y = 44
	close_button.pressed.connect(_toggle_company_panel)
	content.add_child(close_button)
	_company_route_option.select(_company_selected_route)
	_refresh_company_configuration()
	_refresh_company_panel()

func _toggle_company_panel() -> void:
	if not is_instance_valid(_company_panel):
		return
	_company_panel.visible = not _company_panel.visible
	if _company_panel.visible:
		_refresh_company_panel()

func _on_company_route_selected(index: int) -> void:
	_company_selected_route = clampi(index, 0, ROUTE_NAMES.size() - 1)
	_save_progress()
	_refresh_company_panel()

func _on_company_name_submitted(value: String) -> void:
	var cleaned := value.strip_edges()
	if not cleaned.is_empty():
		_company_name = cleaned
	_save_progress()
	_refresh_company_panel()

func _hire_company_driver() -> void:
	if _company_funds < 80:
		_company_status_label.text = "Not enough company funds. You need OMR 80 to hire a driver."
		return
	_company_funds -= 80
	_company_drivers.append({"name": "Driver %03d" % (_company_drivers.size() + 1), "status": "AVAILABLE", "route": "UNASSIGNED", "bus": "NO BUS"})
	_company_driver_count = _company_drivers.size()
	_company_status_label.text = "Driver hired. Assign an available company bus and route."
	_save_progress()
	_refresh_company_panel()

func _service_selected_company_bus() -> void:
	if _company_config_bus_index < 0 or _company_config_bus_index >= _company_fleet.size():
		_company_status_label.text = "Select a company bus before servicing."
		return
	var bus: Dictionary = _company_fleet[_company_config_bus_index]
	if str(bus.get("status", "AVAILABLE")) != "AVAILABLE":
		_company_status_label.text = "A bus must return to the depot before it can be serviced."
		return
	var condition := clampi(int(bus.get("condition", 100)), 0, 100)
	var service_cost := 100 - condition
	if service_cost <= 0:
		_company_status_label.text = "This bus is already in full condition."
		return
	if _company_funds < service_cost:
		_company_status_label.text = "Service requires OMR %d. Your company does not have enough funds." % service_cost
		return
	_company_funds -= service_cost
	_company_fleet[_company_config_bus_index]["condition"] = 100
	_company_status_label.text = "%s serviced to 100%% condition for OMR %d." % [str(bus.get("name", "Company bus")), service_cost]
	_save_progress()
	_refresh_company_panel()

func _buy_company_bus() -> void:
	if _company_funds < 450:
		_company_status_label.text = "Not enough company funds. You need OMR 450 for another bus."
		return
	_company_funds -= 450
	_company_fleet.append({"name": "Company Bus %03d" % (_company_fleet.size() + 1), "type": FLEET_NAMES[3], "vehicle_index": 3, "status": "AVAILABLE", "route_index": _company_selected_route, "assigned_driver_index": -1, "condition": 100})
	_company_bus_count = _company_fleet.size()
	_refresh_company_configuration()
	_company_status_label.text = "Bus purchased and added to your company fleet."
	_save_progress()
	_refresh_company_panel()


func _on_company_config_bus_selected(index: int) -> void:
	_company_config_bus_index = clampi(index, 0, maxi(_company_fleet.size() - 1, 0))
	_refresh_company_configuration()

func _on_company_config_route_selected(index: int) -> void:
	if _company_config_bus_index < 0 or _company_config_bus_index >= _company_fleet.size():
		return
	_company_fleet[_company_config_bus_index]["route_index"] = clampi(index, 0, ROUTE_NAMES.size() - 1)
	_save_progress()
	_refresh_company_panel()

func _on_company_config_vehicle_selected(index: int) -> void:
	if _company_config_bus_index < 0 or _company_config_bus_index >= _company_fleet.size():
		return
	var vehicle_index := clampi(index, 0, FLEET_SCENES.size() - 1)
	_company_fleet[_company_config_bus_index]["vehicle_index"] = vehicle_index
	_company_fleet[_company_config_bus_index]["type"] = FLEET_NAMES[vehicle_index]
	_save_progress()
	_refresh_company_panel()

func _on_company_config_driver_selected(index: int) -> void:
	if _company_config_bus_index < 0 or _company_config_bus_index >= _company_fleet.size():
		return
	_company_fleet[_company_config_bus_index]["assigned_driver_index"] = _company_config_driver_option.get_item_id(index)
	_save_progress()
	_refresh_company_panel()

func _refresh_company_configuration() -> void:
	if not is_instance_valid(_company_config_bus_option) or not is_instance_valid(_company_config_route_option) or not is_instance_valid(_company_config_vehicle_option) or not is_instance_valid(_company_config_driver_option):
		return
	_company_config_bus_option.clear()
	for i in range(_company_fleet.size()):
		_company_config_bus_option.add_item(str(_company_fleet[i].get("name", "Company Bus %03d" % (i + 1))))
	if _company_fleet.is_empty():
		_company_config_bus_option.add_item("No company buses")
		_company_config_bus_option.disabled = true
		_company_config_route_option.disabled = true
		_company_config_vehicle_option.disabled = true
		_company_config_driver_option.disabled = true
		return
	_company_config_bus_option.disabled = false
	_company_config_route_option.disabled = false
	_company_config_vehicle_option.disabled = false
	_company_config_driver_option.disabled = false
	_company_config_bus_index = clampi(_company_config_bus_index, 0, _company_fleet.size() - 1)
	_company_config_bus_option.select(_company_config_bus_index)
	var route_index := clampi(int(_company_fleet[_company_config_bus_index].get("route_index", _company_selected_route)), 0, ROUTE_NAMES.size() - 1)
	_company_config_route_option.select(route_index)
	var vehicle_index := clampi(int(_company_fleet[_company_config_bus_index].get("vehicle_index", 3)), 0, FLEET_SCENES.size() - 1)
	_company_config_vehicle_option.select(vehicle_index)
	_company_config_driver_option.clear()
	_company_config_driver_option.add_item("AUTO ASSIGN AVAILABLE DRIVER", -1)
	for driver_index in range(_company_drivers.size()):
		var driver_name := str(_company_drivers[driver_index].get("name", "Driver %03d" % (driver_index + 1)))
		var driver_status := str(_company_drivers[driver_index].get("status", "AVAILABLE"))
		_company_config_driver_option.add_item("%s  |  %s" % [driver_name, driver_status], driver_index)
	var preferred_driver := int(_company_fleet[_company_config_bus_index].get("assigned_driver_index", -1))
	var selected_driver_item := 0
	for item_index in range(_company_config_driver_option.item_count):
		if _company_config_driver_option.get_item_id(item_index) == preferred_driver:
			selected_driver_item = item_index
			break
	_company_config_driver_option.select(selected_driver_item)

func _dispatch_company_driver() -> void:
	if _company_funds < 35:
		_company_status_label.text = "Your company needs OMR 35 available for trip costs."
		return
	var driver_index := -1
	var bus_index := _company_config_bus_index
	if bus_index < 0 or bus_index >= _company_fleet.size() or str(_company_fleet[bus_index].get("status", "AVAILABLE")) != "AVAILABLE":
		bus_index = -1
		for i in range(_company_fleet.size()):
			if str(_company_fleet[i].get("status", "AVAILABLE")) == "AVAILABLE":
				bus_index = i
				break
	if bus_index < 0:
		_company_status_label.text = "No available company bus. Purchase a bus first."
		return
	var bus_condition := clampi(int(_company_fleet[bus_index].get("condition", 100)), 0, 100)
	if bus_condition <= 15:
		_company_status_label.text = "This bus needs servicing before another dispatch. Select it and use SERVICE SELECTED BUS."
		return
	var preferred_driver := int(_company_fleet[bus_index].get("assigned_driver_index", -1))
	if preferred_driver >= 0:
		if preferred_driver >= _company_drivers.size():
			_company_status_label.text = "Invalid driver assignment. Choose another driver or AUTO ASSIGN."
			return
		if str(_company_drivers[preferred_driver].get("status", "AVAILABLE")) != "AVAILABLE":
			_company_status_label.text = "The assigned driver is busy. Choose another driver or AUTO ASSIGN."
			return
		driver_index = preferred_driver
	else:
		for i in range(_company_drivers.size()):
			if str(_company_drivers[i].get("status", "AVAILABLE")) == "AVAILABLE":
				driver_index = i
				break
	if driver_index < 0:
		_company_status_label.text = "No available driver. Hire a driver or change this bus to AUTO ASSIGN."
		return
	_company_funds -= 35
	var route_index := clampi(int(_company_fleet[bus_index].get("route_index", _company_selected_route)), 0, ROUTE_NAMES.size() - 1)
	var departure_delay := int(_company_schedule_option.get_item_id(_company_schedule_option.selected)) if is_instance_valid(_company_schedule_option) else 0
	var trip_status := "SCHEDULED" if departure_delay > 0 else "ON ROUTE"
	_company_drivers[driver_index]["status"] = trip_status
	_company_drivers[driver_index]["route"] = ROUTE_NAMES[route_index]
	_company_drivers[driver_index]["bus"] = str(_company_fleet[bus_index].get("name", "Company Bus"))
	_company_fleet[bus_index]["status"] = trip_status
	var trip := COMPANY_TRIP_SCRIPT.new()
	trip.name = "CompanyTrip_%03d" % (bus_index + 1)
	trip.trip_completed.connect(_on_company_trip_completed)
	var vehicle_index := clampi(int(_company_fleet[bus_index].get("vehicle_index", 3)), 0, FLEET_SCENES.size() - 1)
	trip.configure(FLEET_SCENES[vehicle_index], _company_ai_bus_start, Vector3(-2.0, 0.15, ROUTE_TARGETS[route_index].z), ROUTE_NAMES[route_index], driver_index, bus_index, departure_delay)
	add_child(trip)
	_company_trip_active = true
	_company_status_label.text = "%s assigned to %s on %s. %s" % [_company_drivers[driver_index]["name"], _company_fleet[bus_index]["name"], ROUTE_NAMES[route_index], "Departure scheduled." if departure_delay > 0 else "Bus is on route."]
	_refresh_company_panel()
	_save_progress()

func _on_company_trip_completed(driver_index: int, bus_index: int) -> void:
	if driver_index >= 0 and driver_index < _company_drivers.size():
		_company_drivers[driver_index]["status"] = "AVAILABLE"
		_company_drivers[driver_index]["route"] = "UNASSIGNED"
		_company_drivers[driver_index]["bus"] = "NO BUS"
	if bus_index >= 0 and bus_index < _company_fleet.size():
		_company_fleet[bus_index]["status"] = "AVAILABLE"
		_company_fleet[bus_index]["condition"] = maxi(int(_company_fleet[bus_index].get("condition", 100)) - 8, 0)
	_company_completed_trips += 1
	_company_funds += 85
	_company_trip_active = false
	for driver in _company_drivers:
		if str(driver.get("status", "AVAILABLE")) in ["ON ROUTE", "SCHEDULED"]:
			_company_trip_active = true
			break
	_company_status_label.text = "Company trip completed. Net company profit: OMR 50. Fleet and staff updated."
	_refresh_company_panel()
	_save_progress()

func _spawn_company_ai_bus() -> void:
	if is_instance_valid(_company_ai_bus):
		_company_ai_bus.queue_free()
	_company_ai_bus = FLEET_SCENES[3].instantiate() as Node3D
	_company_ai_bus.name = "CompanyAIDispatchedBus"
	_company_ai_bus.position = _company_ai_bus_start
	_company_ai_bus.rotation.y = 0.0
	add_child(_company_ai_bus)
	# The company vehicle uses the same bus model, but its movement is driven by
	# this route controller rather than the player's touch/keyboard input script.
	_company_ai_bus.set_process(false)
	_company_ai_bus.set_physics_process(false)
	_company_ai_bus_phase = 0
	if is_instance_valid(_company_ai_stop_passengers):
		_company_ai_stop_passengers.queue_free()
	_company_ai_stop_passengers = null
	_company_ai_bus_stop_time = 0.0
	_company_ai_boarded_passengers = 0
	_company_ai_bus_current_speed = 0.0
	_company_ai_bus_destination = Vector3(-2.0, 0.15, ROUTE_TARGETS[_company_selected_route].z)
	# Follow a sequence of road-centre waypoints instead of cutting directly to the endpoint.
	_company_ai_route_points = [
		_company_ai_bus_start,
		Vector3(-2.0, 0.15, lerpf(_company_ai_bus_start.z, _company_ai_bus_destination.z, 0.25)),
		Vector3(-2.0, 0.15, lerpf(_company_ai_bus_start.z, _company_ai_bus_destination.z, 0.5)),
		Vector3(-2.0, 0.15, lerpf(_company_ai_bus_start.z, _company_ai_bus_destination.z, 0.75)),
		_company_ai_bus_destination
	]
	_company_ai_waypoint_index = 1
	var route_marker := Label3D.new()
	route_marker.name = "CompanyBusRouteMarker"
	route_marker.text = "COMPANY SERVICE"
	route_marker.position = Vector3(0.0, 3.3, 0.0)
	route_marker.font_size = 24
	route_marker.pixel_size = 0.009
	route_marker.modulate = Color(0.55, 0.9, 1.0)
	route_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_company_ai_bus.add_child(route_marker)


func _spawn_company_stop_passengers() -> void:
	if is_instance_valid(_company_ai_stop_passengers):
		_company_ai_stop_passengers.queue_free()
	_company_ai_stop_passengers = Node3D.new()
	_company_ai_stop_passengers.name = "CompanyBusStopWaitingPassengers"
	_company_ai_stop_passengers.position = Vector3(0.2, 0.0, _company_ai_bus_destination.z - 3.0)
	add_child(_company_ai_stop_passengers)

	var clothing_colors: Array[Color] = [
		Color(0.12, 0.32, 0.62), Color(0.58, 0.20, 0.14),
		Color(0.18, 0.43, 0.30), Color(0.68, 0.48, 0.20)
	]
	for passenger_index in range(PASSENGER_GROUP_SIZE):
		var passenger := Node3D.new()
		passenger.name = "WaitingPassenger_%02d" % (passenger_index + 1)
		passenger.position = Vector3(float(passenger_index % 4) * 0.62, 0.0, float(passenger_index / 4) * 0.85)
		_company_ai_stop_passengers.add_child(passenger)

		var body := MeshInstance3D.new()
		var body_mesh := CapsuleMesh.new()
		body_mesh.radius = 0.19
		body_mesh.height = 0.82
		body.mesh = body_mesh
		body.position.y = 0.62
		var clothing := StandardMaterial3D.new()
		clothing.albedo_color = clothing_colors[passenger_index % clothing_colors.size()]
		body.material_override = clothing
		passenger.add_child(body)

		var head := MeshInstance3D.new()
		var head_mesh := SphereMesh.new()
		head_mesh.radius = 0.15
		head_mesh.height = 0.3
		head.mesh = head_mesh
		head.position.y = 1.12
		var skin := StandardMaterial3D.new()
		skin.albedo_color = Color(0.66, 0.46, 0.33)
		head.material_override = skin
		passenger.add_child(head)

	var stop_sign := Label3D.new()
	stop_sign.name = "CompanyBusStopSign"
	stop_sign.text = "BUS STOP  |  8 WAITING"
	stop_sign.position = Vector3(2.8, 2.1, 0.0)
	stop_sign.font_size = 22
	stop_sign.pixel_size = 0.01
	stop_sign.modulate = Color(0.55, 0.9, 1.0)
	stop_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_company_ai_stop_passengers.add_child(stop_sign)

	# Stagger each passenger's walk toward the bus entrance, then remove the
	# simple placeholder figure to represent boarding. This is not seat/door logic.
	for passenger_index in range(PASSENGER_GROUP_SIZE):
		var passenger := _company_ai_stop_passengers.get_node_or_null("WaitingPassenger_%02d" % (passenger_index + 1)) as Node3D
		if passenger == null:
			continue
		var boarding_tween := passenger.create_tween()
		boarding_tween.tween_interval(float(passenger_index) * 0.55)
		boarding_tween.tween_property(passenger, "position", Vector3(1.25, 0.0, 3.0), 0.8)
		boarding_tween.tween_property(passenger, "scale", Vector3.ZERO, 0.2)
		boarding_tween.tween_callback(_update_company_boarding_status.bind(passenger_index + 1))


func _update_company_boarding_status(boarded_count: int) -> void:
	_company_ai_boarded_passengers = maxi(_company_ai_boarded_passengers, boarded_count)
	if is_instance_valid(_company_status_label):
		_company_status_label.text = "Company bus boarding passengers: %d / %d" % [_company_ai_boarded_passengers, PASSENGER_GROUP_SIZE]


func _move_company_bus_toward(target: Vector3, delta: float) -> bool:
	var offset := target - _company_ai_bus.position
	var distance := offset.length()
	if distance <= 0.12:
		_company_ai_bus.position = target
		_company_ai_bus_current_speed = 0.0
		return true
	var direction := offset / distance
	var old_rotation := _company_ai_bus.rotation
	_company_ai_bus.look_at(_company_ai_bus.position + direction, Vector3.UP)
	var desired_yaw := _company_ai_bus.rotation.y
	_company_ai_bus.rotation = old_rotation
	_company_ai_bus.rotation.y = lerp_angle(_company_ai_bus.rotation.y, desired_yaw, minf(delta * 2.8, 1.0))
	_company_ai_bus_current_speed = move_toward(_company_ai_bus_current_speed, _company_ai_bus_speed, _company_ai_bus_acceleration * delta)
	var step_distance := minf(distance, _company_ai_bus_current_speed * delta)
	_company_ai_bus.position += direction * step_distance
	return _company_ai_bus.position.distance_to(target) <= 0.12


func _advance_company_ai_waypoint() -> bool:
	_company_ai_waypoint_index += 1
	return _company_ai_waypoint_index >= _company_ai_route_points.size()


func _update_company_ai_bus(delta: float) -> void:
	if not _company_trip_active or not is_instance_valid(_company_ai_bus):
		return

	if _company_ai_bus_phase == 0:
		var outbound_target: Vector3 = _company_ai_route_points[_company_ai_waypoint_index]
		if _move_company_bus_toward(outbound_target, delta):
			if _advance_company_ai_waypoint():
				_company_ai_bus_phase = 1
				_company_ai_bus_stop_time = 6.5
				_company_ai_bus_current_speed = 0.0
				_spawn_company_stop_passengers()
				if is_instance_valid(_company_status_label):
					_company_status_label.text = "Company bus reached %s. Passengers are waiting to board." % ROUTE_NAMES[_company_selected_route].split(" -> ")[1]
	elif _company_ai_bus_phase == 1:
		_company_ai_bus_current_speed = move_toward(_company_ai_bus_current_speed, 0.0, _company_ai_bus_acceleration * delta)
		_company_ai_bus_stop_time -= delta
		if _company_ai_bus_stop_time <= 0.0:
			_company_ai_boarded_passengers = PASSENGER_GROUP_SIZE
			if is_instance_valid(_company_ai_stop_passengers):
				_company_ai_stop_passengers.queue_free()
			_company_ai_stop_passengers = null
			_company_ai_bus_phase = 2
			_company_ai_route_points.reverse()
			_company_ai_waypoint_index = 1
			if is_instance_valid(_company_status_label):
				_company_status_label.text = "%d passengers boarded. Company bus returning to depot." % _company_ai_boarded_passengers
	elif _company_ai_bus_phase == 2:
		var return_target: Vector3 = _company_ai_route_points[_company_ai_waypoint_index]
		if _move_company_bus_toward(return_target, delta):
			if _advance_company_ai_waypoint():
				if is_instance_valid(_company_trip_timer):
					_company_trip_timer.stop()
				_on_company_driver_trip_completed()


func _on_company_driver_trip_completed() -> void:
	_company_trip_active = false
	if is_instance_valid(_company_ai_stop_passengers):
		_company_ai_stop_passengers.queue_free()
	_company_ai_stop_passengers = null
	if is_instance_valid(_company_ai_bus):
		_company_ai_bus.queue_free()
	_company_ai_bus = null
	if _company_trip_driver_index >= 0 and _company_trip_driver_index < _company_drivers.size():
		_company_drivers[_company_trip_driver_index]["status"] = "AVAILABLE"
		_company_drivers[_company_trip_driver_index]["route"] = "UNASSIGNED"
		_company_drivers[_company_trip_driver_index]["bus"] = "NO BUS"
	if _company_trip_bus_index >= 0 and _company_trip_bus_index < _company_fleet.size():
		_company_fleet[_company_trip_bus_index]["status"] = "AVAILABLE"
	_company_trip_driver_index = -1
	_company_trip_bus_index = -1
	_company_completed_trips += 1
	# Illustrative game-economy figures: OMR 85 fare revenue is credited
	# after OMR 35 trip costs were reserved at dispatch, for OMR 50 net profit.
	_company_funds += 85
	_company_status_label.text = "Company driver completed the route. Net company profit: OMR 50."
	_refresh_company_panel()
	_save_progress()

func _refresh_company_panel() -> void:
	_refresh_company_configuration()
	if is_instance_valid(_company_summary_label):
		_company_summary_label.text = "%s\nCOMPANY FUNDS: OMR %d\nBUSES: %d     DRIVERS: %d\nCOMPLETED COMPANY TRIPS: %d" % [_company_name, _company_funds, _company_bus_count, _company_driver_count, _company_completed_trips]
	if is_instance_valid(_company_roster_label):
		var roster_text := "FLEET"
		for bus in _company_fleet:
			var bus_route := clampi(int(bus.get("route_index", _company_selected_route)), 0, ROUTE_NAMES.size() - 1)
			var assigned_index := int(bus.get("assigned_driver_index", -1))
			var assigned_name := "AUTO" if assigned_index < 0 or assigned_index >= _company_drivers.size() else str(_company_drivers[assigned_index].get("name", "Driver"))
			var model_index := clampi(int(bus.get("vehicle_index", 3)), 0, FLEET_NAMES.size() - 1)
			var condition := clampi(int(bus.get("condition", 100)), 0, 100)
			var service_state := "SERVICE DUE" if condition <= 15 else "CONDITION %d%%" % condition
			roster_text += "\n%s  |  %s  |  %s  |  %s  |  %s  |  DRIVER: %s" % [str(bus.get("name", "Bus")), str(bus.get("status", "AVAILABLE")), FLEET_NAMES[model_index], ROUTE_NAMES[bus_route], service_state, assigned_name]
		roster_text += "\nDRIVER STAFF"
		for driver in _company_drivers:
			roster_text += "\n%s  |  %s" % [str(driver.get("name", "Driver")), str(driver.get("status", "AVAILABLE"))]
		_company_roster_label.text = roster_text
	if is_instance_valid(_company_dispatch_button):
		var has_available_driver := false
		var has_available_bus := false
		for driver in _company_drivers:
			if str(driver.get("status", "AVAILABLE")) == "AVAILABLE":
				has_available_driver = true
		for bus in _company_fleet:
			if str(bus.get("status", "AVAILABLE")) == "AVAILABLE":
				has_available_bus = true
		_company_dispatch_button.disabled = not has_available_driver or not has_available_bus or _company_funds < 35
		_company_dispatch_button.text = "DISPATCH ANOTHER BUS" if _company_trip_active else "ASSIGN DRIVER & SEND TO WORK"

func _restart_delivery() -> void:
	_set_paused(false)
	_spawn_vehicle()

func _build_pause_menu() -> void:
	var layer := CanvasLayer.new()
	layer.name = "PauseMenuLayer"
	layer.layer = 20
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_pause_button = Button.new()
	_pause_button.name = "PauseButton"
	_pause_button.text = "PAUSE"
	_pause_button.anchor_left = 1.0
	_pause_button.anchor_right = 1.0
	_pause_button.offset_left = -112.0
	_pause_button.offset_right = -20.0
	_pause_button.offset_top = 146.0
	_pause_button.offset_bottom = 192.0
	_pause_button.add_theme_font_size_override("font_size", 16)
	_pause_button.pressed.connect(_set_paused.bind(true))
	layer.add_child(_pause_button)

	_pause_overlay = Control.new()
	_pause_overlay.name = "PauseOverlay"
	_pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_overlay.visible = false
	_pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(_pause_overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.035, 0.06, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.add_child(shade)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.06
	panel.anchor_top = 0.08
	panel.anchor_right = 0.94
	panel.anchor_bottom = 0.92
	panel.offset_left = 0.0
	panel.offset_top = 0.0
	panel.offset_right = 0.0
	panel.offset_bottom = 0.0
	_pause_overlay.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	var heading := Label.new()
	heading.text = "ZAYRON SIMULATOR"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 24)
	column.add_child(heading)
	var subtitle := Label.new()
	subtitle.text = "PAUSED  |  SETTINGS"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle)
	var volume_label := Label.new()
	volume_label.text = "MASTER VOLUME"
	column.add_child(volume_label)
	_audio_slider = HSlider.new()
	_audio_slider.min_value = 0.0
	_audio_slider.max_value = 1.0
	_audio_slider.step = 0.05
	_audio_slider.value = _master_volume
	_audio_slider.custom_minimum_size = Vector2(220.0, 40.0)
	_audio_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_audio_slider.value_changed.connect(_on_master_volume_changed)
	column.add_child(_audio_slider)
	var steering_label := Label.new()
	steering_label.text = "STEERING SENSITIVITY"
	column.add_child(steering_label)
	_steering_slider = HSlider.new()
	_steering_slider.min_value = 0.5
	_steering_slider.max_value = 1.8
	_steering_slider.step = 0.05
	_steering_slider.value = _steering_sensitivity
	_steering_slider.custom_minimum_size = Vector2(220.0, 40.0)
	_steering_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_steering_slider.value_changed.connect(_on_steering_sensitivity_changed)
	column.add_child(_steering_slider)
	var resume := Button.new()
	resume.text = "RESUME DRIVING"
	resume.custom_minimum_size = Vector2(220.0, 52.0)
	resume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resume.pressed.connect(_set_paused.bind(false))
	column.add_child(resume)
	var restart := Button.new()
	restart.text = "RESTART ROUTE"
	restart.custom_minimum_size = Vector2(220.0, 52.0)
	restart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restart.pressed.connect(_restart_delivery)
	column.add_child(restart)

func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	if is_instance_valid(_pause_overlay):
		_pause_overlay.visible = paused
	if is_instance_valid(_pause_button):
		_pause_button.visible = not paused

func _on_master_volume_changed(value: float) -> void:
	_master_volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(_master_volume, 0.001)))
	_save_progress()

func _on_steering_sensitivity_changed(value: float) -> void:
	_steering_sensitivity = clampf(value, 0.5, 1.8)
	_apply_vehicle_settings()
	_save_progress()

func _cycle_route() -> void:
	_selected_route = (_selected_route + 1) % ROUTE_TARGETS.size()
	if is_instance_valid(_route_button):
		_route_button.text = "ROUTE: " + ROUTE_NAMES[_selected_route]
	_spawn_vehicle()
	_save_progress()

func _move_checkpoint_gate() -> void:
	for i in range(_checkpoint_gate_parts.size()):
		var gate_part := _checkpoint_gate_parts[i]
		if not is_instance_valid(gate_part):
			continue
		if i == 0:
			gate_part.position = Vector3(-4.0, 1.6, _mission_target.z)
		elif i == 1:
			gate_part.position = Vector3(4.0, 1.6, _mission_target.z)
		else:
			gate_part.position = Vector3(0.0, 3.1, _mission_target.z)
	if is_instance_valid(_checkpoint_label):
		_checkpoint_label.position.z = _mission_target.z
		if _passenger_mode:
			_checkpoint_label.text = "PICKUP" if not _passenger_pickup_done else "DROP-OFF"
		else:
			_checkpoint_label.text = "LOAD CARGO" if not _cargo_pickup_done else "DELIVER CARGO"

func _toggle_passenger_mode() -> void:
	_passenger_mode = not _passenger_mode
	if _passenger_mode and _selected_vehicle < 3:
		_selected_vehicle = 3
	if is_instance_valid(_mission_type_button):
		_mission_type_button.text = "JOB: PASSENGER" if _passenger_mode else "JOB: CARGO"
	if is_instance_valid(_cargo_button):
		_cargo_button.visible = not _passenger_mode
	if is_instance_valid(_passenger_status_label):
		_passenger_status_label.visible = _passenger_mode
		_passenger_status_label.text = "PASSENGERS ON BOARD: 0"
	if is_instance_valid(_cargo_status_label):
		_cargo_status_label.visible = not _passenger_mode
		_cargo_status_label.text = "CARGO STATUS: WAITING FOR LOAD"
	_spawn_vehicle()
	_save_progress()

func _cycle_cargo() -> void:
	_selected_cargo = (_selected_cargo + 1) % CARGO_NAMES.size()
	if is_instance_valid(_cargo_button):
		_cargo_button.text = "CARGO: " + CARGO_NAMES[_selected_cargo]
	_save_progress()

func _on_checkpoint_entered(body: Node3D) -> void:
	if body != _active_vehicle or _mission_complete:
		return
	if _passenger_mode and not _passenger_pickup_done:
		if _active_vehicle.has_method("can_board_passengers") and not _active_vehicle.can_board_passengers():
			if is_instance_valid(_mission_label):
				_mission_label.text = "STOP THE BUS AND OPEN PASSENGER DOORS TO BOARD"
			return
		_passenger_pickup_done = true
		_animate_passenger_boarding()
		if is_instance_valid(_passenger_status_label):
			_passenger_status_label.text = "BOARDING PASSENGERS: %d" % PASSENGER_GROUP_SIZE
		_mission_target = ROUTE_TARGETS[_selected_route]
		if is_instance_valid(_checkpoint_area):
			_checkpoint_area.position = _mission_target
		_move_checkpoint_gate()
		if is_instance_valid(_mission_label):
			_mission_label.text = "PASSENGERS ON BOARD  |  CONTINUE TO " + ROUTE_NAMES[_selected_route].split(" -> ")[1]
		return
	if not _passenger_mode and not _active_vehicle.has_method("can_handle_cargo") or (not _passenger_mode and not _active_vehicle.can_handle_cargo()):
		if is_instance_valid(_mission_label):
			_mission_label.text = "STOP COMPLETELY AND APPLY PARK BRAKE TO LOAD OR UNLOAD CARGO"
		return
	if not _passenger_mode and not _cargo_pickup_done:
		if is_instance_valid(_mission_label):
			_mission_label.text = "LOAD A STAGED PALLET AT THE WAREHOUSE TRUCK BAY"
		return
	if _passenger_mode and _passenger_pickup_done:
		if not _active_vehicle.has_method("can_board_passengers") or not _active_vehicle.can_board_passengers():
			if is_instance_valid(_mission_label):
				_mission_label.text = "STOP AT THE TERMINAL, APPLY PARK BRAKE AND OPEN PASSENGER DOORS TO UNLOAD"
			return
		_complete_passenger_dropoff()
		return
	if not _passenger_mode and _cargo_pickup_done:
		if is_instance_valid(_mission_label):
			_mission_label.text = "DELIVERY ARRIVED  |  APPLY PARK BRAKE AND UNLOAD CARGO"
		return
	_mission_complete = true
	if not _passenger_mode:
		if is_instance_valid(_cargo_status_label):
			_cargo_status_label.text = "CARGO DELIVERED: " + CARGO_NAMES[_selected_cargo]
		_animate_depot_cargo(false)
		if is_instance_valid(_active_vehicle) and _active_vehicle.has_method("set_cargo_payload"):
			_active_vehicle.set_cargo_payload(_selected_cargo, false)
	_delivery_count += 1
	_cash_balance += PASSENGER_TRIP_REWARD if _passenger_mode else CARGO_REWARDS[_selected_cargo]
	if is_instance_valid(_cash_label):
		_cash_label.text = "WALLET  |  OMR %d  |  DELIVERIES %d" % [_cash_balance, _delivery_count]
	_save_progress()
	if is_instance_valid(_mission_label):
		if _passenger_mode:
			_mission_label.text = "%s COMPLETE  |  PASSENGERS DELIVERED  |  +%d OMR" % [ROUTE_NAMES[_selected_route], PASSENGER_TRIP_REWARD]
		else:
			_mission_label.text = "%s COMPLETE  |  %s  |  +%d OMR" % [ROUTE_NAMES[_selected_route], CARGO_NAMES[_selected_cargo], CARGO_REWARDS[_selected_cargo]]


func _animate_passenger_boarding() -> void:
	if not is_instance_valid(_passenger_waiting_group) or not is_instance_valid(_active_vehicle):
		return
	_passenger_waiting_group.visible = true
	var passenger_index := 0
	for person in _passenger_waiting_group.get_children():
		if not person is Node3D:
			continue
		var target := _active_vehicle.global_position + Vector3(-1.8 + float(passenger_index % 2) * 0.55, 0.0, 1.4 + float(passenger_index / 2) * 0.22)
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_IN_OUT)
		var current_index := passenger_index
		tween.tween_property(person, "global_position", target, 0.65 + float(passenger_index % 3) * 0.12)
		tween.tween_callback(func():
			person.visible = false
			if current_index == PASSENGER_GROUP_SIZE - 1 and is_instance_valid(_active_vehicle):
				if _active_vehicle.has_method("set_visible_passenger_manifest"):
					_active_vehicle.set_visible_passenger_manifest(PASSENGER_GROUP_SIZE)
				if is_instance_valid(_passenger_status_label):
					_passenger_status_label.text = "PASSENGERS SEATED: %d" % PASSENGER_GROUP_SIZE
		)
		passenger_index += 1


func _animate_passenger_alighting() -> void:
	if not is_instance_valid(_passenger_waiting_group) or not is_instance_valid(_active_vehicle):
		return
	_passenger_waiting_group.global_position = _active_vehicle.global_position + Vector3(4.0, 0.0, 0.0)
	_passenger_waiting_group.visible = true
	var passenger_index := 0
	for person in _passenger_waiting_group.get_children():
		if not person is Node3D:
			continue
		person.visible = true
		person.global_position = _active_vehicle.global_position + Vector3(1.8, 0.0, 1.1 + float(passenger_index) * 0.12)
		var target := _passenger_waiting_group.global_position + Vector3(float(passenger_index % 2) * 0.72, 0.0, float(passenger_index / 2) * 0.82)
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(person, "global_position", target, 0.8 + float(passenger_index % 3) * 0.1)
		passenger_index += 1


func _complete_passenger_dropoff() -> void:
	if _mission_complete or not _passenger_mode or not _passenger_pickup_done:
		return
	if not is_instance_valid(_active_vehicle) or not _active_vehicle.has_method("can_board_passengers") or not _active_vehicle.can_board_passengers():
		return
	_mission_complete = true
	if _active_vehicle.has_method("set_visible_passenger_manifest"):
		_active_vehicle.set_visible_passenger_manifest(0)
	_animate_passenger_alighting()
	if is_instance_valid(_passenger_status_label):
		_passenger_status_label.text = "PASSENGERS DELIVERED: %d" % PASSENGER_GROUP_SIZE
	_delivery_count += 1
	_cash_balance += PASSENGER_TRIP_REWARD
	if is_instance_valid(_cash_label):
		_cash_label.text = "WALLET  |  OMR %d  |  DELIVERIES %d" % [_cash_balance, _delivery_count]
	_save_progress()
	if is_instance_valid(_mission_label):
		_mission_label.text = "%s COMPLETE  |  PASSENGERS DELIVERED  |  +%d OMR" % [ROUTE_NAMES[_selected_route], PASSENGER_TRIP_REWARD]


func _load_progress() -> void:
	var progress := ConfigFile.new()
	if progress.load(SAVE_PATH) != OK:
		return
	_delivery_count = int(progress.get_value("career", "deliveries", 0))
	_cash_balance = int(progress.get_value("career", "wallet_omr", 0))
	_selected_vehicle = clampi(int(progress.get_value("career", "selected_vehicle", 0)), 0, FLEET_SCENES.size() - 1)
	_selected_route = clampi(int(progress.get_value("career", "selected_route", 0)), 0, ROUTE_TARGETS.size() - 1)
	_selected_cargo = clampi(int(progress.get_value("career", "selected_cargo", 0)), 0, CARGO_NAMES.size() - 1)
	_passenger_mode = bool(progress.get_value("career", "passenger_mode", false))
	_company_name = str(progress.get_value("company", "name", _company_name))
	_company_funds = maxi(0, int(progress.get_value("company", "funds_omr", _company_funds)))
	_company_bus_count = maxi(1, int(progress.get_value("company", "buses", _company_bus_count)))
	_company_driver_count = maxi(0, int(progress.get_value("company", "drivers", _company_driver_count)))
	_company_completed_trips = maxi(0, int(progress.get_value("company", "completed_trips", _company_completed_trips)))
	_company_selected_route = clampi(int(progress.get_value("company", "dispatch_route", 0)), 0, ROUTE_NAMES.size() - 1)
	var saved_fleet: Variant = progress.get_value("company", "fleet", [])
	if saved_fleet is Array:
		for bus_entry in saved_fleet:
			if bus_entry is Dictionary:
				_company_fleet.append(bus_entry.duplicate(true))
	var saved_drivers: Variant = progress.get_value("company", "driver_roster", [])
	if saved_drivers is Array:
		for driver_entry in saved_drivers:
			if driver_entry is Dictionary:
				_company_drivers.append(driver_entry.duplicate(true))
	if _company_fleet.is_empty():
		for bus_index in range(_company_bus_count):
			_company_fleet.append({"name": "Company Bus %03d" % (bus_index + 1), "type": "INTERCITY COACH", "status": "AVAILABLE"})
	if _company_drivers.is_empty():
		for driver_index in range(_company_driver_count):
			_company_drivers.append({"name": "Driver %03d" % (driver_index + 1), "status": "AVAILABLE", "route": "UNASSIGNED", "bus": "NO BUS"})
	_company_bus_count = _company_fleet.size()
	_company_driver_count = _company_drivers.size()
	var saved_damage: Variant = progress.get_value("career", "vehicle_damage_levels", _vehicle_damage_levels)
	if saved_damage is Array:
		for damage_index in range(mini(saved_damage.size(), _vehicle_damage_levels.size())):
			_vehicle_damage_levels[damage_index] = clampi(int(saved_damage[damage_index]), 0, 100)
	var saved_fuel: Variant = progress.get_value("career", "vehicle_fuel_levels", _vehicle_fuel_levels)
	if saved_fuel is Array:
		for fuel_index in range(mini(saved_fuel.size(), _vehicle_fuel_levels.size())):
			_vehicle_fuel_levels[fuel_index] = clampf(float(saved_fuel[fuel_index]), 0.0, 100.0)
	_steering_sensitivity = clampf(float(progress.get_value("settings", "steering_sensitivity", 1.0)), 0.5, 1.8)
	_master_volume = clampf(float(progress.get_value("settings", "master_volume", 1.0)), 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(_master_volume, 0.001)))
	if _passenger_mode and _selected_vehicle < 3:
		_selected_vehicle = 3

func _store_active_vehicle_fuel() -> void:
	if not is_instance_valid(_active_vehicle) or _active_vehicle_index < 0 or _active_vehicle_index >= _vehicle_fuel_levels.size():
		return
	if _active_vehicle.has_method("get_fuel_level"):
		_vehicle_fuel_levels[_active_vehicle_index] = clampf(float(_active_vehicle.get_fuel_level()), 0.0, 100.0)
	if _active_vehicle.has_method("get_vehicle_damage"):
		_vehicle_damage_levels[_active_vehicle_index] = clampi(int(_active_vehicle.get_vehicle_damage()), 0, 100)


func _save_progress() -> void:
	_store_active_vehicle_fuel()
	var progress := ConfigFile.new()
	progress.set_value("career", "deliveries", _delivery_count)
	progress.set_value("career", "wallet_omr", _cash_balance)
	progress.set_value("career", "selected_vehicle", _selected_vehicle)
	progress.set_value("career", "selected_route", _selected_route)
	progress.set_value("career", "selected_cargo", _selected_cargo)
	progress.set_value("career", "passenger_mode", _passenger_mode)
	progress.set_value("career", "vehicle_fuel_levels", _vehicle_fuel_levels)
	progress.set_value("career", "vehicle_damage_levels", _vehicle_damage_levels)
	progress.set_value("company", "name", _company_name)
	progress.set_value("company", "funds_omr", _company_funds)
	progress.set_value("company", "buses", _company_bus_count)
	progress.set_value("company", "drivers", _company_driver_count)
	progress.set_value("company", "completed_trips", _company_completed_trips)
	progress.set_value("company", "dispatch_route", _company_selected_route)
	progress.set_value("company", "fleet", _company_fleet)
	progress.set_value("company", "driver_roster", _company_drivers)
	progress.set_value("settings", "steering_sensitivity", _steering_sensitivity)
	progress.set_value("settings", "master_volume", _master_volume)
	var save_error := progress.save(SAVE_PATH)
	if save_error != OK:
		push_warning("Could not save Zayron Simulator progress. Error: %s" % save_error)
