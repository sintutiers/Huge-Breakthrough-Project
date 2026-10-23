## base class for everything that lives on a character as a "component".
## extend this instead of [Node] and you get the [method _on_ready] /
## [method _on_setup] lifecycle hooks for free.
##
## dependencies are injected by the body (the scene-tree ancestor that owns the
## components) in its [method Node._enter_tree]. because Godot's [method Node._enter_tree]
## is called top-down, components see injected dependencies in both [method _on_ready]
## and [method _on_setup].
##
## components declare dependencies as plain typed fields (not [code]@export[/code]).
## the body holds [code]@export[/code] references and assigns them once — see
## [PlatformerBody] for the concrete wiring. the body is the ancestor that mediates
## every sibling relationship, matching the Godot "parent mediates" best practice.
##
## [method _on_ready] and [method _on_setup] are NOT chained: subclasses extending
## [Component] directly must not call [code]super()[/code] in those overrides.
## subclasses of non-leaf components (e.g. [Movement3DComponent] extending
## [PlatformerMovementBase]) DO call [code]super()[/code], because the intermediate
## parent's implementation does real work.
class_name Component
extends Node


static func find_component(root: Node, type: Variant, warn: bool = false) -> Node:
	for node: Node in root.find_children("*", "", true, false):
		if is_instance_of(node, type):
			return node
	if warn:
		push_warning("%s: no %s found." % [root.name, type])
	return null


func _ready() -> void:
	_on_ready()
	call_deferred("_run_setup")


func _run_setup() -> void:
	_on_setup()


func _on_ready() -> void:
	pass


func _on_setup() -> void:
	pass
