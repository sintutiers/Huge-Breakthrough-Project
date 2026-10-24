# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2

# one_shot_particles.gd
extends Node2D

func _ready() -> void:
	var particles := find_child("*", false, false) as CPUParticles2D
	if not particles:
		push_error("one_shot_particles: missing CPUParticles2D child")
		return
	particles.one_shot = true
	particles.emitting = true
	particles.finished.connect(queue_free)
