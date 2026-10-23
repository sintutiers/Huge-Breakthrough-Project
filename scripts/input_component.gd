class_name InputComponent
extends Component

var _frame: InputFrame = InputFrame.new()
var _frame_index: int = -1


func get_frame() -> InputFrame:
	var index: int = Engine.get_physics_frames()
	if index != _frame_index:
		_frame_index = index
		_frame = _build_frame()
	return _frame


func fire_held() -> bool:
	return false


func is_launch_accept_event(_event: InputEvent) -> bool:
	return false


func weapon_scroll_direction(_event: InputEvent) -> int:
	return 0


func get_movement_vector() -> Vector2:
	return Vector2.ZERO


func get_aim_world_position() -> Vector2:
	return Vector2.ZERO


func _build_frame() -> InputFrame:
	return InputFrame.new()
