# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
class_name DeanHurtBox2D
extends BasicHurtBox2D

func _ready() -> void:
	if not health:
		health = Component.find_component(get_parent(), Health, true) as Health
	super()
