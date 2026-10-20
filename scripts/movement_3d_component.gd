# scripts/components/movement_3d_component.gd
class_name Movement3DComponent
extends PlatformerMovementBase

#region Exports
@export_group("Movement")
@export var move_speed: float = 5.0
@export var run_speed: float = 8.0
@export_range(0.0, 200.0, 0.5) var move_acceleration: float = 30.0
@export_range(0.0, 200.0, 0.5) var turn_acceleration: float = 90.0
@export_range(0.0, 200.0, 0.5) var move_friction: float = 30.0
@export var locks_during_interact: bool = true

@export_group("Jump")
@export_range(0.0, 20.0, 0.1) var jump_height: float = 2.0
@export_range(0.0, 100.0, 0.5) var jump_gravity: float = 0.0
@export_range(0.0, 1.0, 0.01) var coyote_time: float = 0.1
@export_range(0.0, 1.0, 0.01) var jump_buffer_time: float = 0.1
@export_range(1, 10, 1) var default_max_jumps: int = 2
@export var jump_ability_id: String = String(AbilityIds.EXTRA_JUMPS)
@export_range(0.0, 1.0, 0.05) var jump_cut_multiplier: float = 0.5
@export_range(0.0, 3.0, 0.05) var running_jump_height_multiplier: float = 1.5
@export_range(0.0, 3.0, 0.05) var momentum_jump_distance_multiplier: float = 1.5

@export_group("Fall")
@export_range(0.0, 100.0, 0.5) var max_fall_speed: float = 20.0
@export_range(-50.0, 50.0, 0.5) var fall_gravity_offset: float = 0.0
@export_range(0.0, 20.0, 0.1) var apex_hang_threshold: float = 1.0
@export_range(0.0, 1.0, 0.05) var apex_hang_gravity_multiplier: float = 0.5

@export_group("Wall")
@export var wall_jump_enabled: bool = true
@export_range(0.0, 50.0, 0.5) var wall_slide_speed: float = 2.5
@export_range(0.0, 50.0, 0.5) var wall_jump_push_speed: float = 7.0
@export_range(0.0, 1.0, 0.01) var wall_jump_lock_duration: float = 0.1

@export_group("Dash")
@export_range(0.0, 100.0, 0.5) var dash_speed: float = 18.0
@export_range(0.0, 1.0, 0.01) var dash_duration: float = 0.2
@export_range(0.0, 5.0, 0.01) var dash_cooldown: float = 0.5
@export_range(1, 10, 1) var max_dashes: int = 1

@export_group("Crouch")
@export_range(0.0, 1.0, 0.01) var crouch_collision_scale: float = 0.5
## Negative moves the shape down so the feet stay on the floor when it is scaled.
@export_range(-5.0, 5.0, 0.05) var crouch_shape_y_offset: float = -0.45
@export_range(0.0, 1.0, 0.05) var crouch_speed_multiplier: float = 0.5
#endregion

#region State
var facing_component: FacingComponent
var collision_shape: CollisionShape3D
var input_component: InputComponent
var ability_component: AbilityComponent
var launch_component: LaunchComponent

var _was_moving: bool = false
var _locked: bool = false
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _jumps_used: int = 0
var _current_motion: StringName = Motions.IDLE
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dashes_used: int = 0
var _standing_shape_position: Vector3
var _dash_direction: Vector3 = Vector3.FORWARD
var _is_running: bool = false
var _wall_jump_lock_timer: float = 0.0
var _was_falling: bool = false

@onready var body: CharacterBody3D = get_parent() as CharacterBody3D
@onready var state_chart: StateChart = %StateChart
@onready var ground_state: StateChartState = %Ground
@onready var air_state: StateChartState = %Air
@onready var wall_slide_state: StateChartState = %WallSlide
@onready var dash_state: StateChartState = %Dash
@onready var crouch_state: StateChartState = %Crouch
@onready var base_gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
#endregion


#region Lifecycle
func _physics_process(delta: float) -> void:
	if not body or not input_component or not facing_component:
		return
	_is_running = input_component.run_held() and not _locked
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
	input_component = get_component(InputComponent) as InputComponent
	collision_shape = get_component(CollisionShape3D, false) as CollisionShape3D
	launch_component = get_component(LaunchComponent, false) as LaunchComponent
	ability_component = get_component(AbilityComponent, false) as AbilityComponent
	if collision_shape:
		_standing_shape_position = collision_shape.position
	if launch_component:
		track(launch_component.landed, _on_launch_landed)

	if locks_during_interact:
		var interact_component: InteractComponent = get_component(InteractComponent, false) as InteractComponent
		if interact_component:
			track(
				interact_component.interact_started,
				func() -> void:
					_locked = true,
			)
			track(
				interact_component.interact_ended,
				func() -> void:
					_locked = false,
			)
#endregion


#region Helpers
func _move_input() -> Vector2:
	if _locked:
		return Vector2.ZERO
	return input_component.get_movement_vector().limit_length(1.0)


## Converts 2D input into a world-space direction on the XZ plane.
func _world_direction(input_dir: Vector2) -> Vector3:
	return body.transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)


func _horizontal_velocity() -> Vector2:
	return Vector2(body.velocity.x, body.velocity.z)


func _set_horizontal_velocity(value: Vector2) -> void:
	body.velocity.x = value.x
	body.velocity.z = value.y


func _is_pushing_into_wall(input_dir: Vector2) -> bool:
	if input_dir.is_zero_approx():
		return false
	var wall_normal: Vector3 = body.get_wall_normal()
	return _world_direction(input_dir).dot(-wall_normal) > 0.0


func _apply_horizontal(delta: float, input_dir: Vector2, is_running: bool, speed_multiplier: float = 1.0) -> void:
	if _wall_jump_lock_timer > 0.0:
		return
	var velocity_xz: Vector2 = _horizontal_velocity()

	if input_dir.is_zero_approx():
		velocity_xz = velocity_xz.move_toward(Vector2.ZERO, move_friction * delta)
		_set_horizontal_velocity(velocity_xz)
		if _was_moving and velocity_xz.is_zero_approx():
			stopped.emit()
			_was_moving = false
		return

	var world_dir: Vector3 = _world_direction(input_dir)
	var dir_xz: Vector2 = Vector2(world_dir.x, world_dir.z)
	var turning: bool = not velocity_xz.is_zero_approx() and velocity_xz.dot(dir_xz) < 0.0
	var accel_rate: float = turn_acceleration if turning else move_acceleration
	var target_speed: float = (run_speed if is_running else move_speed) * speed_multiplier
	velocity_xz = velocity_xz.move_toward(dir_xz * target_speed, accel_rate * delta)
	_set_horizontal_velocity(velocity_xz)

	var changed: bool = facing_component.update(input_dir)
	if not _was_moving or changed:
		moved.emit(facing_component.facing)
	_was_moving = true


func _update_current_motion(on_ground: bool, input_dir: Vector2, is_running: bool) -> void:
	var motion: StringName
	if not input_dir.is_zero_approx() and body.is_on_wall():
		motion = Motions.PUSH
	elif is_running and not input_dir.is_zero_approx():
		motion = Motions.RUN
	elif not input_dir.is_zero_approx():
		motion = Motions.WALK
	else:
		motion = Motions.IDLE

	if motion == _current_motion:
		return
	_current_motion = motion
	if on_ground:
		ground_motion_changed.emit(motion)


func _update_jump_buffer(delta: float) -> void:
	if not _locked and input_component.jump_just_pressed():
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer -= delta


func _try_jump(is_running: bool, is_wall_jump: bool = false) -> bool:
	var can_jump: bool = _coyote_timer > 0.0 or _jumps_used < _max_jumps()
	if _jump_buffer_timer <= 0.0 or not can_jump:
		return false

	var height: float = jump_height * (running_jump_height_multiplier if is_running else 1.0)
	var rise_gravity: float = jump_gravity if jump_gravity > 0.0 else base_gravity
	body.velocity.y = sqrt(2.0 * rise_gravity * height)

	if is_wall_jump:
		var wall_normal: Vector3 = body.get_wall_normal()
		body.velocity.x = wall_normal.x * wall_jump_push_speed
		body.velocity.z = wall_normal.z * wall_jump_push_speed
		_wall_jump_lock_timer = wall_jump_lock_duration
	else:
		var speed_ratio: float = clampf(_horizontal_velocity().length() / run_speed, 0.0, 1.0)
		var boost: float = lerpf(1.0, momentum_jump_distance_multiplier, speed_ratio)
		body.velocity.x *= boost
		body.velocity.z *= boost

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
	if _locked or _dash_cooldown_timer > 0.0 or _dashes_used >= max_dashes:
		return false
	return input_component.dash_just_pressed()


func _land(reset_jumps: bool = false) -> void:
	_dashes_used = 0
	_was_falling = false
	if reset_jumps:
		_jumps_used = 0
	landed.emit(_current_motion)
	state_chart.send_event(StateEvents.LAND)
	ground_motion_changed.emit(_current_motion)


func _max_jumps() -> int:
	var bonus: int = (ability_component.get_level(StringName(jump_ability_id))
		if ability_component
		else 0)
	return default_max_jumps + bonus
#endregion


#region Ground
func _on_ground_physics(delta: float) -> void:
	var input_dir: Vector2 = _move_input()

	_coyote_timer = coyote_time
	_update_jump_buffer(delta)

	if _try_dash():
		state_chart.send_event(StateEvents.DASH)
		return

	if not _locked and input_component.crouch_held():
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
#endregion


#region Air
func _on_air_physics(delta: float) -> void:
	if _try_dash():
		state_chart.send_event(StateEvents.DASH)
		return

	var gravity: float = (jump_gravity
		if (jump_gravity > 0.0 and body.velocity.y > 0.0)
		else base_gravity + fall_gravity_offset)
	if absf(body.velocity.y) < apex_hang_threshold:
		gravity *= apex_hang_gravity_multiplier
	body.velocity.y = maxf(body.velocity.y - gravity * delta, -max_fall_speed)

	if body.is_on_ceiling() and body.velocity.y > 0.0:
		body.velocity.y = 0.0

	if body.velocity.y < 0.0 and not _was_falling:
		_was_falling = true
		started_falling.emit()
	elif body.velocity.y >= 0.0:
		_was_falling = false

	_coyote_timer -= delta
	_update_jump_buffer(delta)

	if input_component.jump_just_released() and body.velocity.y > 0.0:
		body.velocity.y *= jump_cut_multiplier

	var input_dir: Vector2 = _move_input()
	_apply_horizontal(delta, input_dir, false)
	_try_jump(false)

	var was_grounded: bool = body.is_on_floor()
	body.move_and_slide()
	_update_current_motion(false, input_dir, false)

	if not was_grounded and body.is_on_floor():
		_land(true)
		return

	if body.is_on_wall_only() and _is_pushing_into_wall(input_dir):
		state_chart.send_event(StateEvents.WALL_SLIDE)
#endregion


#region Wall slide
func _on_wall_slide_entered() -> void:
	_jump_buffer_timer = 0.0
	_was_falling = false
	if wall_jump_enabled:
		_jumps_used = 0
		_coyote_timer = coyote_time


func _on_wall_slide_physics(delta: float) -> void:
	body.velocity.y = maxf(body.velocity.y - (base_gravity + fall_gravity_offset) * delta, -wall_slide_speed)
	wall_slid.emit()
	_update_jump_buffer(delta)

	if wall_jump_enabled and _try_jump(false, true):
		state_chart.send_event(StateEvents.JUMP)
		return

	var input_dir: Vector2 = _move_input()
	_apply_horizontal(delta, input_dir, false)

	var was_grounded: bool = body.is_on_floor()
	body.move_and_slide()

	if not was_grounded and body.is_on_floor():
		_land()
		return

	if not body.is_on_wall():
		state_chart.send_event(StateEvents.FALL)
		fell_from_wall.emit()
#endregion


#region Dash
func _on_dash_entered() -> void:
	_dash_timer = dash_duration
	_dash_cooldown_timer = dash_cooldown
	_dashes_used += 1
	_was_falling = false
	is_uninterruptible = true

	var facing: Vector2 = facing_component.facing
	if facing.is_zero_approx():
		_dash_direction = -body.transform.basis.z
	else:
		_dash_direction = _world_direction(facing)
	_dash_direction.y = 0.0
	_dash_direction = _dash_direction.normalized()
	dashed.emit()


func _on_dash_physics(delta: float) -> void:
	body.velocity = _dash_direction * dash_speed
	_dash_timer -= delta
	body.move_and_slide()

	if _dash_timer > 0.0:
		return

	is_uninterruptible = false
	if body.is_on_floor():
		_update_current_motion(true, _move_input(), _is_running)
		_land()
	else:
		dash_ended.emit()
		state_chart.send_event(StateEvents.FALL)
#endregion


#region Crouch
func _on_crouch_entered() -> void:
	if not collision_shape:
		return
	collision_shape.scale.y = crouch_collision_scale
	collision_shape.position.y = _standing_shape_position.y + crouch_shape_y_offset


func _on_crouch_physics(delta: float) -> void:
	var input_dir: Vector2 = _move_input()
	_apply_horizontal(delta, input_dir, false, crouch_speed_multiplier)
	body.velocity.y = minf(body.velocity.y, 0.0) - base_gravity * delta
	body.move_and_slide()

	var motion: StringName = Motions.CROUCH_WALK if not input_dir.is_zero_approx() else Motions.CROUCH_IDLE
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
#endregion


#region Launch
func _on_launch_landed() -> void:
	_coyote_timer = coyote_time
	_update_current_motion(true, _move_input(), _is_running)
	_land(true)
#endregion
