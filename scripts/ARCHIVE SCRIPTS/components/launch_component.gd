# launch_componet
class_name LaunchComponent
extends Component

signal launched
signal landed
signal fell

var input_component: InputComponent

var movement: MovementBase
var _target: Vector2
var _speed: float = 0.0

var _pad_direction: Vector2
var _pad_speed: float = 0.0
var _pad_distance: float = 0.0
var _pad_active: bool = false

@onready var body: CharacterBody2D = get_parent() as CharacterBody2D
@onready var state_chart: StateChart = %StateChart
@onready var launch_state: StateChartState = %Launch


func _unhandled_input(event: InputEvent) -> void:
	if _pad_active and input_component.is_launch_accept_event(event):
		launch(_pad_direction, _pad_speed, _pad_distance)


func launch(direction: Vector2, speed: float, distance: float) -> void:
	if direction.is_zero_approx() or speed <= 0.0 or distance <= 0.0:
		return
	_speed = speed
	_target = body.global_position + direction.normalized() * distance
	if movement:
		movement.is_uninterruptible = true
	launched.emit()
	state_chart.send_event(StateEvents.LAUNCH)


func register_pad(direction: Vector2, speed: float, distance: float) -> void:
	_pad_direction = direction
	_pad_speed = speed
	_pad_distance = distance
	_pad_active = true


func clear_pad() -> void:
	_pad_active = false


func _on_setup() -> void:
	input_component = get_component(InputComponent) as InputComponent
	movement = get_component(MovementBase, false) as MovementBase


func _on_ready() -> void:
	launch_state.state_physics_processing.connect(_on_launch_physics)
	launch_state.state_entered.connect(fell.emit)


func _on_launch_physics(delta: float) -> void:
	var to_target: Vector2 = _target - body.global_position
	var remaining: float = to_target.length()
	var step: float = _speed * delta
	if remaining <= step:
		body.global_position = _target
		body.velocity = Vector2.ZERO
		if movement:
			movement.is_uninterruptible = false
		state_chart.send_event(StateEvents.LAUNCH_END)
		if body.is_on_floor():
			landed.emit()
		return
	body.velocity = to_target.normalized() * _speed
	body.move_and_slide()
