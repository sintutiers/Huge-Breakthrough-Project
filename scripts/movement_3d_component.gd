# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2

# movement_3d_component.gd
## [PlatformerMovementBase] for a [CharacterBody3D].
## dependencies (body, collision_shape) are injected by the body.
class_name Movement3DComponent
extends PlatformerMovementBase

var body: CharacterBody3D
var collision_shape: CollisionShape3D

var _standing_shape_position: Vector3


func _on_setup() -> void:
	super()
	if collision_shape:
		_standing_shape_position = collision_shape.position


func _gravity() -> float:
	return -body.get_gravity().dot(body.up_direction)


func _read_move(frame: InputFrame) -> Vector2:
	return frame.move


func _to_world(direction: Vector2) -> Vector2:
	var world: Vector3 = body.global_basis * Vector3(direction.x, 0.0, direction.y)
	return Vector2(world.x, world.z)


func _default_dash_direction() -> Vector2:
	return _to_world(Vector2.UP)


func _get_horizontal_velocity() -> Vector2:
	return Vector2(body.velocity.x, body.velocity.z)


func _set_horizontal_velocity(value: Vector2) -> void:
	body.velocity.x = value.x
	body.velocity.z = value.y


func _get_vertical_velocity() -> float:
	return body.velocity.dot(body.up_direction)


func _set_vertical_velocity(value: float) -> void:
	body.velocity += body.up_direction * (value - body.velocity.dot(body.up_direction))


func _wall_normal() -> Vector2:
	var normal: Vector3 = body.get_wall_normal()
	return Vector2(normal.x, normal.z)


func _move_and_slide() -> void:
	body.move_and_slide()


func _is_on_floor() -> bool:
	return body.is_on_floor()


func _is_on_wall() -> bool:
	return body.is_on_wall()


func _is_on_wall_only() -> bool:
	return body.is_on_wall_only()


func _is_on_ceiling() -> bool:
	return body.is_on_ceiling()


func _set_crouched(crouched: bool) -> void:
	if not collision_shape:
		return
	collision_shape.scale.y = profile.crouch_collision_scale if crouched else 1.0
	collision_shape.position.y = _standing_shape_position.y + (profile.crouch_shape_y_offset if crouched else 0.0)
