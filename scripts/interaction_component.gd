# interaction_component.gd
class_name InteractionComponent
extends Component

signal interacted(target: InteractableThing)

@export var interact_radius: float = 2.0
@export var input_component: InputComponent
@export var interact_component: InteractComponent
@export var state_chart: StateChart
@export var interact_area: Area3D

var body: Node3D


#region Lifecycle
func _physics_process(_delta: float) -> void:
	if not input_component or not body:
		return
	if interact_component and interact_component.is_locked:
		return
	if input_component.get_frame().interact_pressed:
		_interact()


func _on_setup() -> void:
	super()
	body = _find_root() as Node3D
	if not input_component:
		input_component = get_component(InputComponent) as InputComponent
	if not interact_component:
		interact_component = get_component(InteractComponent, false) as InteractComponent
	if not state_chart:
		state_chart = get_component(StateChart, false) as StateChart
	if not interact_area:
		interact_area = get_component(Area3D, false) as Area3D

	var missing: PackedStringArray = PackedStringArray()
	if not body:
		missing.append("body")
	if not input_component:
		missing.append("input_component")
	if not missing.is_empty():
		push_error("%s: missing required components: %s" % [name, ", ".join(missing)])
		set_physics_process(false)
#endregion


#region Interaction
func _interact() -> void:
	var target: InteractableThing = _find_closest()
	if not target:
		return
	target.trigger(interact_area)
	interacted.emit(target)
	_send(StateEvents.INTERACT)
	if target.holds_interact_lock:
		target.interaction_finished.connect(_end_interact, CONNECT_ONE_SHOT)
	else:
		_end_interact()


func _find_closest() -> InteractableThing:
	var closest: InteractableThing = null
	var closest_dist_sq: float = interact_radius * interact_radius
	var origin: Vector3 = body.global_position
	for node: Node in get_tree().get_nodes_in_group(&"interactable"):
		var candidate := node as InteractableThing
		if not candidate or not candidate.enabled:
			continue
		var dist_sq: float = origin.distance_squared_to(candidate.global_position)
		if dist_sq <= closest_dist_sq:
			closest_dist_sq = dist_sq
			closest = candidate
	return closest


func _end_interact() -> void:
	_send(StateEvents.INTERACT_END)


func _send(event: StringName) -> void:
	if state_chart:
		state_chart.send_event(event)
#endregion
