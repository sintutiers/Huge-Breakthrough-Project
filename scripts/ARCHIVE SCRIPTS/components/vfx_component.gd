# vfx_component.gd
class_name VFXComponent
extends Component

enum RunDustMode {
	CONTINUOUS,
	FOOTSTEP,
}

@export_group("One-Shot Effects")
@export_custom(ETP.NONE, ETP.PROPERTY)
var jump_dust: PackedScene
@export_custom(ETP.NONE, ETP.PROPERTY)
var jump_dust_offset: Vector2 = Vector2.ZERO
@export_custom(ETP.NONE, ETP.PROPERTY)
var land_dust: PackedScene
@export_custom(ETP.NONE, ETP.PROPERTY)
var land_dust_offset: Vector2 = Vector2.ZERO
@export_custom(ETP.NONE, ETP.PROPERTY)
var dash_trail: PackedScene
@export_custom(ETP.NONE, ETP.PROPERTY)
var dash_trail_offset: Vector2 = Vector2.ZERO

@export_group("Run Dust")
@export_custom(ETP.NONE, ETP.PROPERTY)
var run_dust_scene: PackedScene
@export_custom(ETP.NONE, ETP.PROPERTY)
var run_dust_mode: RunDustMode = RunDustMode.CONTINUOUS
@export_custom(ETP.NONE, ETP.PROPERTY)
var footstep_interval: float = 0.3
@export_custom(ETP.NONE, ETP.PROPERTY)
var run_dust_offset: Vector2 = Vector2.ZERO
@export_custom(ETP.NONE, ETP.PROPERTY)
var footstep_offset: Vector2 = Vector2.ZERO

@export_group("Wall Dust")
@export_custom(ETP.NONE, ETP.PROPERTY)
var wall_dust_scene: PackedScene
@export_custom(ETP.NONE, ETP.PROPERTY)
var wall_dust_offset: Vector2 = Vector2.ZERO

var entity: Node2D
var _run_dust: CPUParticles2D
var _wall_dust: CPUParticles2D
var _footstep_timer: float = 0.0
var _is_running_motion: bool = false


func _physics_process(delta: float) -> void:
	if run_dust_mode != RunDustMode.FOOTSTEP or not run_dust_scene:
		return
	if not _is_running_motion:
		return
	_footstep_timer -= delta
	if _footstep_timer <= 0.0:
		_footstep_timer = footstep_interval
		_spawn_one_shot(run_dust_scene, footstep_offset)


func _on_setup() -> void:
	entity = get_parent() as Node2D
	var movement := get_component(PlatformerMovementBase, false) as PlatformerMovementBase
	if movement:
		track(movement.ground_motion_changed, _on_ground_motion_changed)
		track(movement.jumped, _on_jumped)
		track(movement.wall_jumped, _on_jumped)
		track(movement.extra_jumped, _on_extra_jumped)
		track(movement.landed, _on_landed)
		track(movement.dashed, _on_dashed)
		track(movement.wall_slid, _on_wall_slid)
		track(movement.fell_from_wall, _on_wall_dust_end)
	if run_dust_scene and run_dust_mode == RunDustMode.CONTINUOUS:
		_run_dust = _spawn_persistent(run_dust_scene, run_dust_offset)
	if wall_dust_scene:
		_wall_dust = _spawn_persistent(wall_dust_scene, wall_dust_offset)


func _on_ground_motion_changed(motion: StringName) -> void:
	_is_running_motion = motion == &"run" or motion == &"walk"
	if _run_dust:
		_run_dust.emitting = _is_running_motion
	if not _is_running_motion:
		_footstep_timer = 0.0


func _on_jumped(_jump_number: int = 0) -> void:
	_spawn_one_shot(jump_dust, jump_dust_offset)


func _on_extra_jumped(_jump_number: int) -> void:
	_spawn_one_shot(jump_dust, jump_dust_offset)


func _on_landed(_motion: StringName) -> void:
	_spawn_one_shot(land_dust, land_dust_offset)
	if _wall_dust:
		_wall_dust.emitting = false


func _on_dashed() -> void:
	_spawn_one_shot(dash_trail, dash_trail_offset)


func _on_wall_slid() -> void:
	if _wall_dust:
		_wall_dust.emitting = true


func _on_wall_dust_end() -> void:
	if _wall_dust:
		_wall_dust.emitting = false


func _spawn_one_shot(scene: PackedScene, offset: Vector2 = Vector2.ZERO) -> void:
	if not scene or not entity:
		return
	var instance := scene.instantiate() as Node2D
	if not instance:
		push_error("VFXComponent: expected Node2D root")
		return
	get_tree().current_scene.add_child(instance)
	instance.global_position = entity.global_position + offset


func _spawn_persistent(scene: PackedScene, offset: Vector2 = Vector2.ZERO) -> CPUParticles2D:
	var instance := scene.instantiate() as Node2D
	if not instance:
		push_error("VFXComponent: expected Node2D root")
		return null

	entity.add_child(instance)
	instance.position = offset

	var particles := instance.find_child("*", false, false) as CPUParticles2D
	if not particles:
		push_error("VFXComponent: missing CPUParticles2D child")
		return null

	particles.emitting = false
	return particles
