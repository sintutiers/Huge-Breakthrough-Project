# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
class_name WeaponResource
extends Resource

@export var fire_rate: float = 0.2
@export var damage: float = 10.0
@export var behavior: WeaponBehavior
@export var ability_id: StringName
@export var gun_texture: Texture2D
@export var gun_scale: Vector2 = Vector2.ONE
