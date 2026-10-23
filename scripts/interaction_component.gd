# interaction_component.gd
## finds the closest [InteractableThing] in range and triggers it on interact press.
## sends the interact events to the state chart and locks input while the Interact state is active.
## emits [signal interact_started] and [signal interact_ended].
class_name InteractionComponent
extends Component

signal interacted(target: InteractableThing)
signal interact_started
signal interact_ended

@export var interact_radius: float = 2.0
@export var input_component: InputComponent
@export var state_chart: StateChart
@export var interact_area: Area3D

var is_locked: bool = false
var body: Node3D

@onready var interact_state: StateChartState = %Interact


#region Lifecycle
func _physics_process(_delta: float) -> void:
	if is_locked or not input_component or not body:
		return
	if input_component.get_frame().interact_pressed:
		_interact()


func _on_ready() -> void:
	super()
	interact_state.state_entered.connect(_on_entered)
	interact_state.state_exited.connect(_on_exited)


func _on_setup() -> void:
	super()
	body = _find_root() as Node3D
	if not input_component:
		input_component = get_component(InputComponent) as InputComponent
	if not state_chart:
		state_chart = get_component(StateChart) as StateChart
	if not interact_area:
		interact_area = get_component(Area3D, false) as Area3D

	var missing: PackedStringArray = PackedStringArray()
	if not body:
		missing.append("body")
	if not input_component:
		missing.append("input_component")
	if not state_chart:
		missing.append("state_chart")
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
	state_chart.send_event(StateEvents.INTERACT)
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
	state_chart.send_event(StateEvents.INTERACT_END)
#endregion


#region Lock
func _on_entered() -> void:
	is_locked = true
	interact_started.emit()


func _on_exited() -> void:
	is_locked = false
	interact_ended.emit()
#endregion
