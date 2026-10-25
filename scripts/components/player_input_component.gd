# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
# player_input_component.gd
## reads keyboard/mouse/controller into an [InputFrame].
## also adds the parent to the "player" group.
class_name PlayerInputComponent
extends InputComponent


func _on_ready() -> void:
	get_parent().add_to_group(&"player")


func _build_frame() -> InputFrame:
	var frame := InputFrame.new()
	frame.move = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	frame.run = Input.is_action_pressed(&"run")
	frame.jump_pressed = Input.is_action_just_pressed(&"jump")
	frame.jump_released = Input.is_action_just_released(&"jump")
	frame.crouch = Input.is_action_pressed(&"crouch")
	frame.dash_pressed = Input.is_action_just_pressed(&"dash")
	frame.interact_pressed = Input.is_action_just_pressed(&"ui_select")
	return frame
