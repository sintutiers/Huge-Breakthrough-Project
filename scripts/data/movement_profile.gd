# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
class_name MovementProfile
extends Resource

@export_group("Movement")
@export var move_speed: float = 10.0
@export var run_speed: float = 20.0
@export var move_acceleration: float = 120.0
@export var turn_acceleration: float = 360.0
@export var move_friction: float = 120.0

@export_group("Jump")
@export var jump_height: float = 5.0
@export var jump_gravity: float = 10.0
@export_range(0.0, 1.0, 0.01) var coyote_time: float = 0.1
@export_range(0.0, 1.0, 0.01) var jump_buffer_time: float = 0.1
@export_range(1, 10, 1) var default_max_jumps: int = 2
@export_range(0.0, 1.0, 0.05) var jump_cut_multiplier: float = 0.5
@export_range(0.0, 3.0, 0.05) var running_jump_height_multiplier: float = 1.5
@export_range(0.0, 3.0, 0.05) var momentum_jump_distance_multiplier: float = 1.5

@export_group("Fall")
@export var max_fall_speed: float = 600.0
@export var fall_gravity_offset: float = 0.0
@export var apex_hang_threshold: float = 40.0
@export_range(0.0, 1.0, 0.05) var apex_hang_gravity_multiplier: float = 0.5

@export_group("Wall")
@export var wall_jump_enabled: bool = true
@export var wall_slide_speed: float = 100.0
@export var wall_jump_push_speed: float = 300.0
@export_range(0.0, 1.0, 0.01) var wall_jump_lock_duration: float = 0.1

@export_group("Dash")
@export var dash_speed: float = 80.0
@export_range(0.0, 1.0, 0.01) var dash_duration: float = 0.2
@export_range(0.0, 5.0, 0.01) var dash_cooldown: float = 0.5
@export_range(1, 10, 1) var max_dashes: int = 1

@export_group("Crouch")
@export_range(0.0, 1.0, 0.01) var crouch_collision_scale: float = 0.5
@export var crouch_shape_y_offset: float = 8.0
@export_range(0.0, 1.0, 0.05) var crouch_speed_multiplier: float = 0.5
