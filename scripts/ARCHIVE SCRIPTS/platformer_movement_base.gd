# scripts/platformer_movement_base.gd
class_name PlatformerMovementBase
extends MovementBase

signal jumped(jump_number: int)
signal wall_jumped
signal extra_jumped(jump_number: int)
signal landed(motion: StringName)
signal wall_slid
signal fell_from_wall
signal dashed
signal dash_ended
signal started_falling
