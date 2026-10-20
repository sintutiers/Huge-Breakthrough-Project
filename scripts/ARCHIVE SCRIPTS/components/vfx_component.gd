# vfx_component.gd
class_name VFXComponent
extends Component

enum RunDustMode {
	CONTINUOUS,
	FOOTSTEP,
}

@export_group("One-Shot Effects")
@export var jump_dust: PackedScene
@export var jump_dust_offset: Vector2 = Vector2.ZERO
@export var land_dust: PackedScene
@export var land_dust_offset: Vector2 = Vector2.ZERO
@export var dash_trail: PackedScene
@export var dash_trail_offset: Vector2 = Vector2.ZERO

@export_group("Run Dust")
@export var run_dust_scene: PackedScene
@export var run_dust_mode: RunDustMode = RunDustMode.CONTINUOUS
@export var footstep_interval: float = 0.3
@export var run_dust_offset: Vector2 = Vector2.ZERO
@export var footstep_offset: Vector2 = Vector2.ZERO

@export_group("Wall Dust")
@export var wall_dust_scene: PackedScene
@export var wall_dust_offset: Vector2 = Vector2.ZERO

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
		movement.ground_motion_changed.connect(_on_ground_motion_changed)
		movement.jumped.connect(_on_jumped)
		movement.wall_jumped.connect(_on_jumped)
		movement.extra_jumped.connect(_on_extra_jumped)
		movement.landed.connect(_on_landed)
		movement.dashed.connect(_on_dashed)
		movement.wall_slid.connect(_on_wall_slid)
		movement.fell_from_wall.connect(_on_wall_dust_end)
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
