# audio_component.gd
class_name AudioComponent
extends Component

@export var footstep_sounds: Array[AudioStream] = []

@export_custom(ETP.NONE, ETP.PROPERTY)
var fire_sound: AudioStream
@export_custom(ETP.NONE, ETP.PROPERTY)
var footstep_interval: float = 0.35

var _is_walking: bool = false
var _footstep_timer: float = 0.0


func _physics_process(delta: float) -> void:
	if not _is_walking:
		return
	_footstep_timer -= delta
	if _footstep_timer <= 0.0:
		_footstep_timer = footstep_interval
		play_footstep()


func play_footstep() -> void:
	if footstep_sounds.is_empty():
		return
	SoundManager.play_sound(footstep_sounds.pick_random())


func play_fire() -> void:
	if not fire_sound:
		return
	SoundManager.play_sound(fire_sound)


func _on_setup() -> void:
	var movement := get_component(MovementBase, false) as MovementBase
	if movement:
		track(movement.moved, _on_moved)
		track(movement.stopped, _on_stopped)


func _on_moved(_direction: Vector2) -> void:
	_is_walking = true


func _on_stopped() -> void:
	_is_walking = false
	_footstep_timer = 0.0
