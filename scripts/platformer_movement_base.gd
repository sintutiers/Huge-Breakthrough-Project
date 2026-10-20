# scripts/platformer_movement_base.gd
@abstract
class_name PlatformerMovementBase
extends MovementBase

signal jumped(jump_count: int)
signal extra_jumped(jump_count: int)
signal wall_jumped
signal landed(motion: StringName)
signal started_falling
signal wall_slid
signal fell_from_wall
signal dashed
signal dash_ended

@export var profile: MovementProfile
@export var locks_during_interact: bool = true
@export var input_component: InputComponent
@export var facing_component: FacingComponent
@export var ability_component: AbilityComponent
@export var launch_component: LaunchComponent
@export var interact_component: InteractComponent

var _empty_frame: InputFrame = InputFrame.new()
var _post_move: Callable
var _transition_sent: bool = false
var _grounded_before_move: bool = false
var _was_moving: bool = false
var _locked: bool = false
var _disabled: bool = false
var _last_land_frame: int = -1
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _jumps_used: int = 0
var _current_motion: StringName = Motions.IDLE
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dashes_used: int = 0
var _dash_direction: Vector2 = Vector2.RIGHT
var _wall_jump_lock_timer: float = 0.0
var _was_falling: bool = false

@onready var state_chart: StateChart = %StateChart
@onready var ground_state: StateChartState = %Ground
@onready var air_state: StateChartState = %Air
@onready var wall_slide_state: StateChartState = %WallSlide
@onready var dash_state: StateChartState = %Dash
@onready var crouch_state: StateChartState = %Crouch


#region Lifecycle
func _physics_process(delta: float) -> void:
	if _disabled or not input_component or not facing_component:
		return
	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer -= delta
	if _wall_jump_lock_timer > 0.0:
		_wall_jump_lock_timer -= delta
	_grounded_before_move = _is_on_floor()
	_move_and_slide()
	if not _transition_sent:
		_post_move.call()
	_transition_sent = false


#region Abstract
@abstract func _gravity() -> float


@abstract func _read_move(frame: InputFrame) -> Vector2


@abstract func _to_world(direction: Vector2) -> Vector2


@abstract func _default_dash_direction() -> Vector2


@abstract func _get_horizontal_velocity() -> Vector2


@abstract func _set_horizontal_velocity(value: Vector2) -> void


@abstract func _get_vertical_velocity() -> float


@abstract func _set_vertical_velocity(value: float) -> void


@abstract func _wall_normal() -> Vector2


@abstract func _move_and_slide() -> void


@abstract func _is_on_floor() -> bool


@abstract func _is_on_wall() -> bool


@abstract func _is_on_wall_only() -> bool


@abstract func _is_on_ceiling() -> bool


@abstract func _set_crouched(crouched: bool) -> void
#endregion


func _on_ready() -> void:
	super()
	state_chart.process_physics_priority = 0
	process_physics_priority = 1
	_post_move = _after_ground
	ground_state.state_entered.connect(_on_ground_entered)
	ground_state.state_physics_processing.connect(_on_ground_physics)
	air_state.state_entered.connect(_on_air_entered)
	air_state.state_physics_processing.connect(_on_air_physics)
	wall_slide_state.state_entered.connect(_on_wall_slide_entered)
	wall_slide_state.state_physics_processing.connect(_on_wall_slide_physics)
	dash_state.state_entered.connect(_on_dash_entered)
	dash_state.state_physics_processing.connect(_on_dash_physics)
	crouch_state.state_entered.connect(_on_crouch_entered)
	crouch_state.state_physics_processing.connect(_on_crouch_physics)
	crouch_state.state_exited.connect(_on_crouch_exited)


func _on_setup() -> void:
	super()
	if not input_component:
		input_component = get_component(InputComponent) as InputComponent
	if not facing_component:
		facing_component = get_component(FacingComponent) as FacingComponent
	if not ability_component:
		ability_component = get_component(AbilityComponent, false) as AbilityComponent
	if not launch_component:
		launch_component = get_component(LaunchComponent, false) as LaunchComponent
	if not interact_component:
		interact_component = get_component(InteractComponent, false) as InteractComponent

	var missing: PackedStringArray = PackedStringArray()
	if not profile:
		missing.append("profile")
	if not input_component:
		missing.append("input_component")
	if not facing_component:
		missing.append("facing_component")
	if not missing.is_empty():
		push_error("%s: missing required components: %s" % [name, ", ".join(missing)])
		_disabled = true
		set_physics_process(false)
		if state_chart:
			state_chart.process_mode = Node.PROCESS_MODE_DISABLED
		return

	if launch_component:
		launch_component.landed.connect(_on_launch_landed)
	if locks_during_interact and interact_component:
		interact_component.interact_started.connect(_set_locked.bind(true))
		interact_component.interact_ended.connect(_set_locked.bind(false))

	if air_state and air_state.active:
		_post_move = _after_air
	elif wall_slide_state and wall_slide_state.active:
		_post_move = _after_wall_slide
	elif dash_state and dash_state.active:
		_post_move = _after_dash
	elif crouch_state and crouch_state.active:
		_post_move = _after_crouch
#endregion


#region Helpers
func _set_locked(value: bool) -> void:
	_locked = value


func _frame() -> InputFrame:
	if _locked or not input_component:
		return _empty_frame
	return input_component.get_frame()


func _move_input() -> Vector2:
	return _read_move(_frame()).limit_length(1.0)


func _send(event: StringName) -> void:
	_transition_sent = true
	state_chart.send_event(event)


func _is_pushing_into_wall(input_dir: Vector2) -> bool:
	if input_dir.is_zero_approx():
		return false
	return _to_world(input_dir).dot(-_wall_normal()) > 0.0


func _apply_horizontal(delta: float, input_dir: Vector2, is_running: bool, speed_multiplier: float = 1.0) -> void:
	if _wall_jump_lock_timer > 0.0:
		return
	var velocity_xz: Vector2 = _get_horizontal_velocity()

	if input_dir.is_zero_approx():
		velocity_xz = velocity_xz.move_toward(Vector2.ZERO, profile.move_friction * delta)
		_set_horizontal_velocity(velocity_xz)
		if _was_moving and velocity_xz.is_zero_approx():
			stopped.emit()
			_was_moving = false
		return

	var direction: Vector2 = _to_world(input_dir)
	var turning: bool = not velocity_xz.is_zero_approx() and velocity_xz.dot(direction) < 0.0
	var accel_rate: float = profile.turn_acceleration if turning else profile.move_acceleration
	var target_speed: float = (profile.run_speed if is_running else profile.move_speed) * speed_multiplier
	_set_horizontal_velocity(velocity_xz.move_toward(direction * target_speed, accel_rate * delta))

	var changed: bool = facing_component.update(input_dir)
	if not _was_moving or changed:
		moved.emit(facing_component.facing)
	_was_moving = true


func _update_current_motion(on_ground: bool, input_dir: Vector2, is_running: bool) -> void:
	var motion: StringName
	if not input_dir.is_zero_approx() and _is_on_wall():
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
	if _frame().jump_pressed:
		_jump_buffer_timer = profile.jump_buffer_time
	else:
		_jump_buffer_timer -= delta


func _try_jump(is_running: bool, is_wall_jump: bool = false) -> bool:
	var can_jump: bool = _coyote_timer > 0.0 or _jumps_used < _max_jumps()
	if _jump_buffer_timer <= 0.0 or not can_jump:
		return false

	var height: float = profile.jump_height * (profile.running_jump_height_multiplier if is_running else 1.0)
	var rise_gravity: float = profile.jump_gravity if profile.jump_gravity > 0.0 else _gravity()
	_set_vertical_velocity(sqrt(2.0 * rise_gravity * height))

	if is_wall_jump:
		_set_horizontal_velocity(_wall_normal() * profile.wall_jump_push_speed)
		_wall_jump_lock_timer = profile.wall_jump_lock_duration
	else:
		var velocity_xz: Vector2 = _get_horizontal_velocity()
		var speed_ratio: float = clampf(velocity_xz.length() / profile.run_speed, 0.0, 1.0)
		_set_horizontal_velocity(velocity_xz * lerpf(1.0, profile.momentum_jump_distance_multiplier, speed_ratio))

	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_jumps_used += 1
	_was_falling = false

	if is_wall_jump:
		wall_jumped.emit()
	elif _jumps_used <= profile.default_max_jumps:
		jumped.emit(_jumps_used)
	else:
		extra_jumped.emit(_jumps_used)
	return true


func _try_dash() -> bool:
	if _dash_cooldown_timer > 0.0 or _dashes_used >= profile.max_dashes:
		return false
	return _frame().dash_pressed


func _land(reset_jumps: bool = false) -> void:
	var frame: int = Engine.get_physics_frames()
	if _last_land_frame == frame:
		return
	_last_land_frame = frame
	_dashes_used = 0
	_was_falling = false
	if reset_jumps:
		_jumps_used = 0
	landed.emit(_current_motion)
	_send(StateEvents.LAND)
	ground_motion_changed.emit(_current_motion)


func _max_jumps() -> int:
	var bonus: int = (ability_component.get_level(profile.jump_ability_id)
		if ability_component
		else 0)
	return profile.default_max_jumps + bonus
#endregion


#region Ground
func _on_ground_entered() -> void:
	_post_move = _after_ground


func _on_ground_physics(delta: float) -> void:
	if _disabled:
		return
	var frame: InputFrame = _frame()

	_coyote_timer = profile.coyote_time
	_update_jump_buffer(delta)

	if _try_dash():
		_send(StateEvents.DASH)
		return

	if frame.crouch:
		_send(StateEvents.CROUCH)
		return

	_apply_horizontal(delta, _move_input(), frame.run)

	if _try_jump(frame.run):
		_send(StateEvents.JUMP)


func _after_ground() -> void:
	_update_current_motion(true, _move_input(), _frame().run)
	if not _is_on_floor():
		_send(StateEvents.FALL)
#endregion


#region Air
func _on_air_entered() -> void:
	_post_move = _after_air


func _on_air_physics(delta: float) -> void:
	if _disabled:
		return
	if _try_dash():
		_send(StateEvents.DASH)
		return

	var vertical: float = _get_vertical_velocity()
	var gravity: float = (profile.jump_gravity
		if (profile.jump_gravity > 0.0 and vertical > 0.0)
		else _gravity() + profile.fall_gravity_offset)
	if absf(vertical) < profile.apex_hang_threshold:
		gravity *= profile.apex_hang_gravity_multiplier
	vertical = maxf(vertical - gravity * delta, -profile.max_fall_speed)

	if _is_on_ceiling() and vertical > 0.0:
		vertical = 0.0

	if vertical < 0.0 and not _was_falling:
		_was_falling = true
		started_falling.emit()
	elif vertical >= 0.0:
		_was_falling = false

	_coyote_timer -= delta
	_update_jump_buffer(delta)

	if _frame().jump_released and vertical > 0.0:
		vertical *= profile.jump_cut_multiplier
	_set_vertical_velocity(vertical)

	_apply_horizontal(delta, _move_input(), false)
	_try_jump(false)


func _after_air() -> void:
	var input_dir: Vector2 = _move_input()
	_update_current_motion(false, input_dir, false)

	if not _grounded_before_move and _is_on_floor():
		_land(true)
		return

	if _is_on_wall_only() and _is_pushing_into_wall(input_dir):
		_send(StateEvents.WALL_SLIDE)
#endregion


#region Wall slide
func _on_wall_slide_entered() -> void:
	if _disabled:
		return
	_post_move = _after_wall_slide
	_jump_buffer_timer = 0.0
	_was_falling = false
	if profile.wall_jump_enabled:
		_jumps_used = 0
		_coyote_timer = profile.coyote_time


func _on_wall_slide_physics(delta: float) -> void:
	if _disabled:
		return
	var gravity: float = _gravity() + profile.fall_gravity_offset
	_set_vertical_velocity(maxf(_get_vertical_velocity() - gravity * delta, -profile.wall_slide_speed))
	wall_slid.emit()
	_update_jump_buffer(delta)

	if profile.wall_jump_enabled and _try_jump(false, true):
		_send(StateEvents.JUMP)
		return

	_apply_horizontal(delta, _move_input(), false)


func _after_wall_slide() -> void:
	if not _grounded_before_move and _is_on_floor():
		_land()
		return

	if not _is_on_wall():
		_send(StateEvents.FALL)
		fell_from_wall.emit()
#endregion


#region Dash
func _on_dash_entered() -> void:
	if _disabled:
		return
	_post_move = _after_dash
	_dash_timer = profile.dash_duration
	_dash_cooldown_timer = profile.dash_cooldown
	_dashes_used += 1
	_was_falling = false
	is_uninterruptible = true

	var direction: Vector2 = _to_world(_move_input())
	_dash_direction = direction.normalized() if not direction.is_zero_approx() else _default_dash_direction()
	dashed.emit()


func _on_dash_physics(delta: float) -> void:
	if _disabled:
		return
	_set_horizontal_velocity(_dash_direction * profile.dash_speed)
	_set_vertical_velocity(0.0)
	_dash_timer -= delta


func _after_dash() -> void:
	if _dash_timer > 0.0:
		return

	is_uninterruptible = false
	if _is_on_floor():
		_update_current_motion(true, _move_input(), _frame().run)
		_land()
	else:
		dash_ended.emit()
		_send(StateEvents.FALL)
#endregion


#region Crouch
func _on_crouch_entered() -> void:
	_post_move = _after_crouch
	_set_crouched(true)


func _on_crouch_physics(delta: float) -> void:
	if _disabled:
		return
	_apply_horizontal(delta, _move_input(), false, profile.crouch_speed_multiplier)
	_set_vertical_velocity(minf(_get_vertical_velocity(), 0.0) - _gravity() * delta)


func _after_crouch() -> void:
	var input_dir: Vector2 = _move_input()
	var motion: StringName = Motions.CROUCH_WALK if not input_dir.is_zero_approx() else Motions.CROUCH_IDLE
	if motion != _current_motion:
		_current_motion = motion
		ground_motion_changed.emit(motion)

	if not _is_on_floor():
		_send(StateEvents.FALL)
		return
	if not _frame().crouch:
		_send(StateEvents.CROUCH_END)


func _on_crouch_exited() -> void:
	_set_crouched(false)
#endregion


#region Launch
func _on_launch_landed() -> void:
	if _disabled:
		return
	_coyote_timer = profile.coyote_time
	_update_current_motion(true, _move_input(), _frame().run)
	_land(true)
#endregion
