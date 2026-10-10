#interact_component.gd
class_name InteractComponent
extends Component

signal interact_started
signal interact_ended

var is_locked: bool = false

@onready var interact_state: StateChartState = %Interact


func _on_ready() -> void:
	track(interact_state.state_entered, _on_entered)
	track(interact_state.state_exited, _on_exited)


func _on_entered() -> void:
	is_locked = true
	interact_started.emit()


func _on_exited() -> void:
	is_locked = false
	interact_ended.emit()
