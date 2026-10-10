# scripts/components/sideways_movement_component.gd
class_name SidewaysMovementComponent
extends PlatformerMovementBase

@export_group("Movement")
@export_range(0.0, 1000.0, 10.0, ETP.PROPERTY)
var move_speed: float = 200.0
@export_range(0.0, 1000.0, 10.0, ETP.PROPERTY)
var run_speed: float = 400.0
@export_range(0.0, 5000.0, 100.0, ETP.PROPERTY)
var move_acceleration: float = 1200.0
@export_range(0.0, 5000.0, 100.0, ETP.PROPERTY)
var turn_acceleration: float = 3600.0
@export_range(0.0, 5000.0, 100.0, ETP.PROPERTY)
var move_friction: float = 1200.0

@export_group("Jump")
@export_range(0.0, 500.0, 5.0, ETP.PROPERTY)
var jump_height: float = 80.0
@export_range(0.0, 3000.0, 10.0, ETP.PROPERTY)
var jump_gravity: float = 0.0
@export_range(0.0, 1.0, 0.01, ETP.PROPERTY)
var coyote_time: float = 0.1
@export_range(0.0, 1.0, 0.01, ETP.PROPERTY)
var jump_buffer_time: float = 0.1
@export_range(1, 10, 1, ETP.PROPERTY)
var default_max_jumps: int = 2
@export_custom(ETP.NONE, ETP.PROPERTY)
var jump_ability_id: String = String(AbilityIds.EXTRA_JUMPS)
@export_range(0.0, 1.0, 0.05, ETP.PROPERTY)
var jump_cut_multiplier: float = 0.5
@export_range(0.0, 3.0, 0.05, ETP.PROPERTY)
var running_jump_height_multiplier: float = 1.5
@export_range(0.0, 3.0, 0.05, ETP.PROPERTY)
var momentum_jump_distance_multiplier: float = 1.5

@export_group("Fall")
@export_range(0.0, 2000.0, 10.0, ETP.PROPERTY)
var max_fall_speed: float = 600.0
@export_range(-1000.0, 1000.0, 10.0, ETP.PROPERTY)
var fall_gravity_offset: float = 0.0
@export_range(0.0, 500.0, 5.0, ETP.PROPERTY)
var apex_hang_threshold: float = 40.0
@export_range(0.0, 1.0, 0.05, ETP.PROPERTY)
var apex_hang_gravity_multiplier: float = 0.5

@export_group("Wall")
@export_custom(ETP.NONE, ETP.PROPERTY)
var wall_jump_enabled: bool = true
@export_range(0.0, 1000.0, 10.0, ETP.PROPERTY)
var wall_slide_speed: float = 100.0
@export_range(0.0, 1000.0, 10.0, ETP.PROPERTY)
var wall_jump_push_speed: float = 300.0
@export_range(0.0, 1.0, 0.01, ETP.PROPERTY)
var wall_jump_lock_duration: float = 0.1

@export_group("Dash")
@export_range(0.0, 2000.0, 10.0, ETP.PROPERTY)
var dash_speed: float = 800.0
@export_range(0.0, 1.0, 0.01, ETP.PROPERTY)
var dash_duration: float = 0.2
@export_range(0.0, 5.0, 0.01, ETP.PROPERTY)
var dash_cooldown: float = 0.5
@export_range(1, 10, 1, ETP.PROPERTY)
var max_dashes: int = 1

@export_group("Crouch")
@export_range(0.0, 1.0, 0.01, ETP.PROPERTY)
var crouch_collision_scale: float = 0.5
@export_range(-100.0, 100.0, 1.0, ETP.PROPERTY)
var crouch_shape_y_offset: float = 8.0
@export_range(0.0, 1.0, 0.05, ETP.PROPERTY)
var crouch_speed_multiplier: float = 0.5

var facing_component: FacingComponent
var collision_shape: CollisionShape2D
var input_component: InputComponent

var ability_component: AbilityComponent

var launch_component: LaunchComponent
var _was_moving: bool = false
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _jumps_used: int = 0
var _current_motion: StringName = Motions.IDLE
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dashes_used: int = 0
var _standing_shape_position: Vector2
var _dash_direction: float = 1.0
var _is_running: bool = false
var _wall_jump_lock_timer: float = 0.0
var _was_falling: bool = false

@onready var body: CharacterBody2D = get_parent() as CharacterBody2D
@onready var state_chart: StateChart = %StateChart
@onready var ground_state: StateChartState = %Ground
@onready var air_state: StateChartState = %Air
@onready var wall_slide_state: StateChartState = %WallSlide
@onready var dash_state: StateChartState = %Dash
@onready var crouch_state: StateChartState = %Crouch
@onready var base_gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta: float) -> void:
	_is_running = input_component.run_held()
	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer -= delta
	if _wall_jump_lock_timer > 0.0:
		_wall_jump_lock_timer -= delta


func _on_ready() -> void:
	track(ground_state.state_physics_processing, _on_ground_physics)
	track(air_state.state_physics_processing, _on_air_physics)
	track(wall_slide_state.state_physics_processing, _on_wall_slide_physics)
	track(wall_slide_state.state_entered, _on_wall_slide_entered)
	track(dash_state.state_entered, _on_dash_entered)
	track(dash_state.state_physics_processing, _on_dash_physics)
	track(crouch_state.state_entered, _on_crouch_entered)
	track(crouch_state.state_physics_processing, _on_crouch_physics)
	track(crouch_state.state_exited, _on_crouch_exited)


func _on_setup() -> void:
	facing_component = get_component(FacingComponent) as FacingComponent
	collision_shape = get_component(CollisionShape2D, false) as CollisionShape2D
	launch_component = get_component(LaunchComponent, false) as LaunchComponent
	input_component = get_component(InputComponent) as InputComponent
	ability_component = get_component(AbilityComponent, false) as AbilityComponent
	if collision_shape:
		_standing_shape_position = collision_shape.position
	if launch_component:
		track(launch_component.landed, _on_launch_landed)


func _on_wall_slide_entered() -> void:
	_jump_buffer_timer = 0.0
	_was_falling = false
	if wall_jump_enabled:
		_jumps_used = 0
		_coyote_timer = coyote_time


func _apply_horizontal(
		delta: float,
		input_dir: float,
		is_running: bool,
		speed_multiplier: float = 1.0,
) -> void:
	if _wall_jump_lock_timer > 0.0:
		return
	if input_dir == 0.0:
		body.velocity.x = move_toward(body.velocity.x, 0.0, move_friction * delta)
		if _was_moving and is_zero_approx(body.velocity.x):
			stopped.emit()
			_was_moving = false
	else:
		var turning: bool = (
				not is_zero_approx(body.velocity.x) and signf(body.velocity.x) != signf(input_dir)
		)
		var accel_rate: float = turn_acceleration if turning else move_acceleration
		var target_speed: float = (run_speed if is_running else move_speed) * speed_multiplier
		body.velocity.x = move_toward(body.velocity.x, input_dir * target_speed, accel_rate * delta)

		var changed: bool = facing_component.update(Vector2(input_dir, 0.0))
		if not _was_moving or changed:
			moved.emit(facing_component.facing)
		_was_moving = true


func _update_current_motion(on_ground: bool, input_dir: float, is_running: bool) -> void:
	var motion: StringName
	if input_dir != 0.0 and body.is_on_wall():
		motion = Motions.PUSH
	elif is_running:
		motion = Motions.RUN
	elif input_dir != 0.0:
		motion = Motions.WALK
	else:
		motion = Motions.IDLE

	if motion == _current_motion:
		return
	_current_motion = motion
	if on_ground:
		ground_motion_changed.emit(motion)


func _try_jump(is_running: bool, is_wall_jump: bool = false) -> bool:
	var can_jump: bool = _coyote_timer > 0.0 or _jumps_used < _max_jumps()
	if _jump_buffer_timer <= 0.0 or not can_jump:
		return false

	var height: float = jump_height * (running_jump_height_multiplier if is_running else 1.0)
	var rise_gravity: float = jump_gravity if jump_gravity > 0.0 else base_gravity
	body.velocity.y = -sqrt(2.0 * rise_gravity * height)

	if is_wall_jump:
		body.velocity.x = body.get_wall_normal().x * wall_jump_push_speed
		_wall_jump_lock_timer = wall_jump_lock_duration
	else:
		var speed_ratio: float = clampf(absf(body.velocity.x) / run_speed, 0.0, 1.0)
		body.velocity.x *= lerpf(1.0, momentum_jump_distance_multiplier, speed_ratio)

	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_jumps_used += 1
	_was_falling = false

	if is_wall_jump:
		wall_jumped.emit()
	elif _jumps_used <= 2:
		jumped.emit(_jumps_used)
	else:
		extra_jumped.emit(_jumps_used)
	return true


func _try_dash() -> bool:
	if _dash_cooldown_timer > 0.0 or _dashes_used >= max_dashes:
		return false
	return input_component.dash_just_pressed()


func _update_jump_buffer(delta: float) -> void:
	if input_component.jump_just_pressed():
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer -= delta


func _land(reset_jumps: bool = false) -> void:
	_dashes_used = 0
	_was_falling = false
	if reset_jumps:
		_jumps_used = 0
	landed.emit(_current_motion)
	state_chart.send_event(StateEvents.LAND)
	ground_motion_changed.emit(_current_motion)


func _on_ground_physics(delta: float) -> void:
	var input_dir: float = input_component.move_axis()

	_coyote_timer = coyote_time
	_update_jump_buffer(delta)

	if _try_dash():
		state_chart.send_event(StateEvents.DASH)
		return

	if input_component.crouch_held():
		state_chart.send_event(StateEvents.CROUCH)
		return

	_apply_horizontal(delta, input_dir, _is_running)

	if _try_jump(_is_running):
		state_chart.send_event(StateEvents.JUMP)
		return

	body.move_and_slide()
	_update_current_motion(true, input_dir, _is_running)
	if not body.is_on_floor():
		state_chart.send_event(StateEvents.FALL)


func _on_air_physics(delta: float) -> void:
	if _try_dash():
		state_chart.send_event(StateEvents.DASH)
		return

	var gravity: float = (
			jump_gravity
			if (jump_gravity > 0.0 and body.velocity.y < 0.0)
			else base_gravity + fall_gravity_offset
	)
	if absf(body.velocity.y) < apex_hang_threshold:
		gravity *= apex_hang_gravity_multiplier
	body.velocity.y = minf(body.velocity.y + gravity * delta, max_fall_speed)

	if body.is_on_ceiling() and body.velocity.y < 0.0:
		body.velocity.y = 0.0

	if body.velocity.y > 0.0 and not _was_falling:
		_was_falling = true
		started_falling.emit()
	elif body.velocity.y <= 0.0:
		_was_falling = false

	_coyote_timer -= delta
	_update_jump_buffer(delta)

	if input_component.jump_just_released() and body.velocity.y < 0.0:
		body.velocity.y *= jump_cut_multiplier

	var input_dir: float = input_component.move_axis()
	_apply_horizontal(delta, input_dir, false)
	_try_jump(false)

	var was_grounded: bool = body.is_on_floor()
	body.move_and_slide()
	_update_current_motion(false, input_dir, false)

	if not was_grounded and body.is_on_floor():
		_land(true)
		_jumps_used = 0
		return

	if body.is_on_wall_only() and input_dir != 0.0:
		state_chart.send_event(StateEvents.WALL_SLIDE)


func _on_wall_slide_physics(delta: float) -> void:
	body.velocity.y = minf(
		body.velocity.y + (base_gravity + fall_gravity_offset) * delta,
		wall_slide_speed,
	)
	wall_slid.emit()
	_update_jump_buffer(delta)

	if wall_jump_enabled and _try_jump(false, true):
		state_chart.send_event(StateEvents.JUMP)
		return

	var input_dir: float = input_component.move_axis()
	_apply_horizontal(delta, input_dir, false)

	var was_grounded: bool = body.is_on_floor()
	body.move_and_slide()

	if not was_grounded and body.is_on_floor():
		_land()
		return

	if not body.is_on_wall():
		state_chart.send_event(StateEvents.FALL)
		fell_from_wall.emit()


func _on_dash_entered() -> void:
	_dash_timer = dash_duration
	_dash_cooldown_timer = dash_cooldown
	_dashes_used += 1
	_was_falling = false
	is_uninterruptible = true
	_dash_direction = facing_component.facing.x if not is_zero_approx(facing_component.facing.x) else 1.0
	dashed.emit()


func _on_dash_physics(delta: float) -> void:
	body.velocity = Vector2(_dash_direction * dash_speed, 0.0)
	_dash_timer -= delta
	body.move_and_slide()

	if _dash_timer > 0.0:
		return

	is_uninterruptible = false
	if body.is_on_floor():
		_update_current_motion(true, input_component.move_axis(), _is_running)
		_land()
	else:
		dash_ended.emit()
		state_chart.send_event(StateEvents.FALL)


func _on_crouch_entered() -> void:
	if not collision_shape:
		return
	collision_shape.scale.y = crouch_collision_scale
	collision_shape.position.y = _standing_shape_position.y + crouch_shape_y_offset


func _on_crouch_physics(delta: float) -> void:
	var input_dir: float = input_component.move_axis()
	_apply_horizontal(delta, input_dir, false, crouch_speed_multiplier)
	body.move_and_slide()

	var motion: StringName = Motions.CROUCH_WALK if input_dir != 0.0 else Motions.CROUCH_IDLE
	if motion != _current_motion:
		_current_motion = motion
		ground_motion_changed.emit(motion)

	if not body.is_on_floor():
		state_chart.send_event(StateEvents.FALL)
		return
	if not input_component.crouch_held():
		state_chart.send_event(StateEvents.CROUCH_END)


func _on_crouch_exited() -> void:
	if not collision_shape:
		return
	collision_shape.scale.y = 1.0
	collision_shape.position.y = _standing_shape_position.y


func _on_launch_landed() -> void:
	_coyote_timer = coyote_time
	_update_current_motion(true, input_component.move_axis(), _is_running)
	_land(true)


func _max_jumps() -> int:
	var bonus: int = (
			ability_component.get_level(StringName(jump_ability_id))
			if ability_component
			else 0
	)
	return default_max_jumps + bonus
