# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2

# scripts/movement_base.gd
class_name MovementBase
extends Component

signal moved(direction: Vector2)
signal stopped
signal ground_motion_changed(motion: StringName)

var is_uninterruptible: bool = false
