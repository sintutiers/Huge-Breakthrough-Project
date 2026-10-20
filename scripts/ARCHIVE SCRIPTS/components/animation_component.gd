# animation_component.gd
class_name AnimationComponent
extends Component

@export_group("Flip")
@export var flip_duration: float = 0.1

var _is_airborne: bool = false
var _is_landing: bool = false
var _is_tumbling: bool = false
var _pending_ground_motion: StringName = Motions.IDLE
var _current_motion: StringName = Motions.IDLE
var _is_aiming: bool = false
var _flip_tween: Tween

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D


func _on_ready() -> void:
	sprite.animation_finished.connect(_on_animation_finished)


func _on_setup() -> void:
	var movement := get_component(PlatformerMovementBase, false) as PlatformerMovementBase
	if movement:
		movement.ground_motion_changed.connect(_on_ground_motion_changed)
		movement.jumped.connect(_on_jumped)
		movement.wall_jumped.connect(_on_wall_jumped)
		movement.extra_jumped.connect(_on_extra_jumped)
		movement.landed.connect(_on_landed)
		movement.wall_slid.connect(_on_wall_slid)
		movement.fell_from_wall.connect(_on_airspin)
		movement.dashed.connect(_on_dashed)
		movement.dash_ended.connect(_on_dash_ended)
		movement.started_falling.connect(_on_started_falling)
	var launch := get_component(LaunchComponent, false) as LaunchComponent
	if launch:
		launch.fell.connect(_on_launched)
	var attack := get_component(AttackComponent, false) as AttackComponent
	if attack:
		attack.fired.connect(_on_fired)
		attack.aim_started.connect(_on_aim_started)
		attack.aim_ended.connect(_on_aim_ended)
	var facing := get_component(FacingComponent, false) as FacingComponent
	if facing:
		facing.flipped.connect(_on_flipped)


func _on_ground_motion_changed(motion: StringName) -> void:
	_current_motion = motion
	if _is_aiming:
		return
	if _is_landing:
		if motion == Motions.WALK or motion == Motions.RUN:
			_is_landing = false
			sprite.play(motion)
			return
		_pending_ground_motion = motion
		return
	if _is_airborne:
		return
	sprite.play(motion)


func _on_jumped(jump_number: int) -> void:
	_is_airborne = true
	_is_tumbling = jump_number != 1
	sprite.play(Animations.JUMP if jump_number == 1 else Animations.AIRSPIN)


func _on_wall_jumped() -> void:
	_is_airborne = true
	_is_tumbling = false
	sprite.play(Animations.JUMP)


func _on_airspin() -> void:
	_is_airborne = true
	_is_tumbling = true
	sprite.play(Animations.AIRSPIN)


func _on_extra_jumped(_jump_number: int) -> void:
	_is_airborne = true
	_is_tumbling = true
	sprite.play(Animations.AIRSPIN)


func _on_wall_slid() -> void:
	_is_airborne = true
	_is_tumbling = false
	if sprite.animation != Animations.WALL_SLIDE:
		sprite.play(Animations.WALL_SLIDE)


func _on_dashed() -> void:
	_is_airborne = true
	_is_tumbling = false
	sprite.play(Animations.DASH)


func _on_dash_ended() -> void:
	sprite.play(Animations.FALL)


func _on_launched() -> void:
	_is_airborne = true
	sprite.play(Animations.AIRSPIN)


func _on_landed(motion: StringName) -> void:
	_is_airborne = false
	_is_landing = true
	_is_tumbling = false
	_pending_ground_motion = motion
	sprite.play(Animations.FALL)


func _on_fired() -> void:
	if _is_airborne:
		return
	var is_moving: bool = _current_motion == Motions.WALK or _current_motion == Motions.RUN
	sprite.play(Animations.SHOOT_RUNNING if is_moving else Animations.SHOOT)


func _on_aim_started() -> void:
	_is_aiming = true
	if _is_airborne:
		return
	sprite.play(Animations.AIM)


func _on_aim_ended() -> void:
	_is_aiming = false
	if _is_airborne:
		return
	sprite.play(_current_motion)


func _on_started_falling() -> void:
	if _is_aiming or _is_tumbling:
		return
	_is_airborne = true
	sprite.play(Animations.FALLING)


func _on_animation_finished() -> void:
	if sprite.animation != Animations.FALL:
		return
	_is_landing = false
	sprite.play(_pending_ground_motion)


func _on_flipped(new_facing_x: float) -> void:
	var target_scale_x: float = -1.0 if new_facing_x < 0.0 else 1.0
	if _flip_tween and _flip_tween.is_running():
		_flip_tween.kill()
	_flip_tween = create_tween()
	_flip_tween.tween_property(sprite, "scale:x", target_scale_x, flip_duration)
