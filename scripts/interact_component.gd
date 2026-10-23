# interact_component.gd
class_name InteractComponent
extends Component

signal interact_started
signal interact_ended

var is_locked: bool = false

@onready var interact_state: StateChartState = %Interact


func _on_ready() -> void:
	super()
	interact_state.state_entered.connect(_on_entered)
	interact_state.state_exited.connect(_on_exited)


func _on_entered() -> void:
	is_locked = true
	interact_started.emit()


func _on_exited() -> void:
	is_locked = false
	interact_ended.emit()
