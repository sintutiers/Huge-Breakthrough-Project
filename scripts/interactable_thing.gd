# interactable_thing.gd
class_name InteractableThing
extends Node3D

signal interacted(by: Area3D)
signal interaction_finished

@export var enabled: bool = true
@export var animate_on_interact: bool = false
@export var holds_interact_lock: bool = false
@export var sprite: AnimatedSprite3D


func _ready() -> void:
	add_to_group(&"interactable")
	if not animate_on_interact:
		return
	if not sprite:
		sprite = Component.find_component(self, AnimatedSprite3D, true) as AnimatedSprite3D
	if sprite:
		sprite.pause()


func trigger(by: Area3D) -> void:
	if not enabled:
		return
	if animate_on_interact and sprite:
		sprite.play()
	interacted.emit(by)


func finish_interaction() -> void:
	interaction_finished.emit()
