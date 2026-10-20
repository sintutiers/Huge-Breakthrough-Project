class_name LockedGateComponent
extends Component

enum UnlockTrigger {
	AUTOMATIC,
	ON_INTERACT,
	ON_OVERLAP,
}

@export var requirements: Array[GateRequirement] = []
@export var require_all: bool = true
@export var stays_as_walkthrough: bool = false
@export var unlock_mode: UnlockTrigger = UnlockTrigger.AUTOMATIC

var _collision_shape: CollisionShape2D
var _interactable: InteractableThing
var _overlap_area: Area2D
var _unlocked: bool = false


func _on_setup() -> void:
	_collision_shape = get_component(CollisionShape2D, false) as CollisionShape2D

	if unlock_mode == UnlockTrigger.ON_INTERACT:
		_interactable = get_component(InteractableThing, false) as InteractableThing
		if _interactable:
			track(_interactable.interacted, _on_interacted)
	elif unlock_mode == UnlockTrigger.ON_OVERLAP:
		_overlap_area = get_component(Area2D, false) as Area2D
		if _overlap_area:
			track(_overlap_area.body_entered, _on_body_entered)
		else:
			push_warning("LockedGateComponent: ON_OVERLAP set but no Area2D found.")

	# Only automatic gates react to requirement changes and check immediately.
	if unlock_mode == UnlockTrigger.AUTOMATIC:
		for req: GateRequirement in requirements:
			req.setup(self)
			track(req.requirement_changed, _check_unlocked)
		_check_unlocked()


func _on_interacted(_by: Area2D) -> void:
	_check_unlocked()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	_check_unlocked()


func _check_unlocked() -> void:
	if _unlocked or requirements.is_empty():
		return
	var player := get_tree().get_first_node_in_group(&"player")
	if not player:
		return
	var met: bool = require_all
	for req: GateRequirement in requirements:
		var r: bool = req.is_met(player)
		met = (met and r) if require_all else (met or r)
	if met:
		_unlock()


func _unlock() -> void:
	_unlocked = true
	if _collision_shape:
		_collision_shape.set_deferred("disabled", true)
	if not stays_as_walkthrough:
		get_parent().queue_free()
