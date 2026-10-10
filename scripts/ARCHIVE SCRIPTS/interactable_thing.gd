# interactable_thing.gd
class_name InteractableThing
extends Node2D

signal interacted(by: Area2D)
signal interaction_finished

@export_custom(ETP.NONE, ETP.PROPERTY)
var animate_on_interact: bool = false
@export_custom(ETP.NONE, ETP.PROPERTY)
var holds_interact_lock: bool = false
@export_custom(PROPERTY_HINT_NODE_PATH_TO_EDITED_NODE, "AnimatedSprite2D")
var sprite: AnimatedSprite2D


func _ready() -> void:
	add_to_group(&"interactable")
	if animate_on_interact:
		if not sprite:
			sprite = _find_sprite()
		if sprite:
			sprite.pause()
		else:
			push_warning("No sprite.")


func trigger(by: Area2D) -> void:
	if animate_on_interact and sprite:
		sprite.play()
	interacted.emit(by)


func finish_interaction() -> void:
	interaction_finished.emit()


func _find_sprite() -> AnimatedSprite2D:
	for child: Node in get_children():
		if child is AnimatedSprite2D:
			return child
	return null
