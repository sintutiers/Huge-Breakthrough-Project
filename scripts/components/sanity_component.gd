# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
# sanity_component.gd
## the sanity meter. changes through [method add] or a flat [member drain_per_second].
## emits [signal changed] on every change, [signal zone_changed] when the ratio crosses
## one of [member thresholds] (up or down) and [signal depleted] when it hits 0.
## drain pauses during interaction (injected by the body) or while [member drain_paused] is set.
class_name SanityComponent
extends Component

signal changed(value: float, ratio: float)
signal zone_changed(zone: int)
signal depleted

@export var max_sanity: float = 100.0

@export var drain_per_second: float = 0.0

@export var thresholds: PackedFloat32Array = PackedFloat32Array([0.25, 0.5, 0.75])

var interact_component: InteractionComponent

## set by anything that should freeze the drain (dialogue, cutscenes, etc).
var drain_paused: bool = false
var value: float
var zone: int = 0


func _physics_process(delta: float) -> void:
	if drain_per_second <= 0.0 or drain_paused:
		return
	if interact_component and interact_component.is_locked:
		return
	add(-drain_per_second * delta)


func get_ratio() -> float:
	return value / max_sanity


func add(amount: float) -> void:
	set_value(value + amount)


func set_value(new_value: float) -> void:
	new_value = clampf(new_value, 0.0, max_sanity)
	if is_equal_approx(new_value, value):
		return
	value = new_value
	changed.emit(value, get_ratio())

	var new_zone: int = _zone_for(get_ratio())
	if new_zone != zone:
		zone = new_zone
		zone_changed.emit(zone)

	if value <= 0.0:
		depleted.emit()


func _on_ready() -> void:
	value = max_sanity
	zone = _zone_for(get_ratio())


func _zone_for(ratio: float) -> int:
	var count: int = 0
	for threshold: float in thresholds:
		if ratio >= threshold:
			count += 1
	return count
