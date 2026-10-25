# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
# player_input_component.gd
## reads keyboard/mouse/controller into an [InputFrame].
## also adds the parent to the "player" group.
class_name PlayerInputComponent
extends InputComponent


func get_movement_vector() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


func get_aim_world_position() -> Vector2:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return Vector2.ZERO
	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	var player := get_parent() as Node3D
	var plane_y := player.global_position.y if player else 0.0
	if is_zero_approx(ray_dir.y):
		return Vector2(ray_origin.x, ray_origin.z)
	var t := (plane_y - ray_origin.y) / ray_dir.y
	if t < 0.0:
		return Vector2.ZERO
	var world_pos := ray_origin + ray_dir * t
	return Vector2(world_pos.x, world_pos.z)


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
