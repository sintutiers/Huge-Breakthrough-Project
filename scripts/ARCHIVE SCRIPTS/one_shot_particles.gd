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
