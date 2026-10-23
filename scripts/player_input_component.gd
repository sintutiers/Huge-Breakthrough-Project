# player_input_component.gd
## reads keyboard/mouse/controller into an [InputFrame].
## also adds the parent to the "player" group and provides the event-y bits
## ([method fire_held], launch accept, weapon scroll) that don't fit a per-frame bool.
class_name PlayerInputComponent
extends InputComponent


func get_movement_vector() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


func get_aim_world_position() -> Vector2:
	var mouse_pos := get_viewport().get_mouse_position()
	return get_viewport().get_canvas_transform().affine_inverse() * mouse_pos


func fire_held() -> bool:
	return Input.is_action_pressed(&"fire")


func is_launch_accept_event(event: InputEvent) -> bool:
	return event.is_action_pressed(&"ui_accept")


func weapon_scroll_direction(event: InputEvent) -> int:
	if not event.is_action_pressed(&"weapon_scroll"):
		return 0
	var mb := event as InputEventMouseButton
	if not mb:
		return 0
	if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
		return 1
	if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		return -1
	return 0


func _on_ready() -> void:
	super()
	get_parent().add_to_group(&"player")


func _build_frame() -> InputFrame:
	var frame := InputFrame.new()
	frame.move = get_movement_vector()
	frame.axis = Input.get_axis(&"move_left", &"move_right")
	frame.run = Input.is_action_pressed(&"run")
	frame.jump_pressed = Input.is_action_just_pressed(&"jump")
	frame.jump_released = Input.is_action_just_released(&"jump")
	frame.crouch = Input.is_action_pressed(&"crouch")
	frame.dash_pressed = Input.is_action_just_pressed(&"dash")
	frame.interact_pressed = Input.is_action_just_pressed(&"ui_select")
	return frame
