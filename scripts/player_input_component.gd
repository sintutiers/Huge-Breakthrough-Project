class_name PlayerInputComponent
extends InputComponent


# player_input_component.gd
func get_movement_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func get_aim_world_position() -> Vector2:
	var mouse_pos := get_viewport().get_mouse_position()
	return get_viewport().get_canvas_transform().affine_inverse() * mouse_pos


func move_axis() -> float:
	return Input.get_axis("move_left", "move_right")


func run_held() -> bool:
	return Input.is_action_pressed("run")


func jump_just_pressed() -> bool:
	return Input.is_action_just_pressed("jump")


func jump_just_released() -> bool:
	return Input.is_action_just_released("jump")


func crouch_held() -> bool:
	return Input.is_action_pressed("crouch")


func dash_just_pressed() -> bool:
	return Input.is_action_just_pressed("dash")


func fire_held() -> bool:
	return Input.is_action_pressed("fire")


func is_interact_event(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_select")


func is_launch_accept_event(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_accept")


func weapon_scroll_direction(event: InputEvent) -> int:
	if not event.is_action_pressed("weapon_scroll"):
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
	get_parent().add_to_group(&"player")
