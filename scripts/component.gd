## base class for everything that lives on a character as a "component".
## extend this instead of [Node] and you get [method get_component] for free,
## so components can find each other without hard references.
##
## override [method _on_ready] and [method _on_setup] instead of [method Node._ready].
## [method _on_ready] runs right away; [method _on_setup] is deferred so all the siblings
## exist by then (that's when you call [method get_component]).
##
## components should sit directly under the body (or under other components),
## not inside a plain [Node] container, or the root lookup stops there.
##
## [method _on_ready] and [method _on_setup] are NOT chained: subclasses extending
## [Component] directly must not call [code]super()[/code] in those overrides. The
## base implementations are intentionally empty and must stay empty. If a shared
## lifecycle hook is ever needed, use a signal or an explicit method call from
## [method _run_setup], not a virtual override.
##
## Subclasses of non-leaf components (e.g. [Movement3DComponent] extending
## [PlatformerMovementBase]) DO call [code]super()[/code], because the
## intermediate parent's implementation does real work.
class_name Component
extends Node

var _component_cache: Dictionary[Variant, Node] = { }


static func find_component(root: Node, type: Variant, warn: bool = false) -> Node:
	for child: Node in root.get_children():
		if is_instance_of(child, type):
			return child
		var found: Node = find_component(child, type, false)
		if found:
			return found
	if warn:
		push_warning("%s: no %s found." % [root.name, type])
	return null


func _ready() -> void:
	_on_ready()
	call_deferred("_run_setup")


func get_component(type: Variant, warn: bool = true) -> Node:
	if _component_cache.has(type):
		return _component_cache[type]
	var root: Node = _find_root()
	if root == null:
		if warn:
			push_warning("%s: no root found above this component." % name)
		return null
	var result: Node = find_component(root, type, warn)
	if result:
		_component_cache[type] = result
	return result


func _run_setup() -> void:
	_on_setup()


func _on_ready() -> void:
	pass


func _on_setup() -> void:
	pass


func _find_root() -> Node:
	var current: Node = get_parent()
	while current and current is Component:
		current = current.get_parent()
	return current
