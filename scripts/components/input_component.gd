# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
# input_component.gd
## base class for input sources. builds one [InputFrame] per physics frame and caches it,
## so everyone asking in the same frame gets the same object.
## extend it and override [method _build_frame] for a new source (AI, replay, etc).
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


func get_movement_vector() -> Vector2:
	return Vector2.ZERO


func get_aim_world_position() -> Vector2:
	return Vector2.ZERO


func _build_frame() -> InputFrame:
	return InputFrame.new()
