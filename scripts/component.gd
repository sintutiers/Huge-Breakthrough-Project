class_name Component
extends Node

var _tracked: Array[Dictionary] = []
var _component_cache: Dictionary = { }


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


func _exit_tree() -> void:
	for entry: Dictionary in _tracked:
		if entry.signal.is_connected(entry.callable):
			entry.signal.disconnect(entry.callable)
	_tracked.clear()


func get_component(type: Variant, warn: bool = true) -> Node:
	if _component_cache.has(type):
		return _component_cache[type]
	var root: Node = _find_root()
	if root == null:
		if warn:
			push_warning("%s: no root found above this component." % name)
		return null
	var result: Node = find_component(root, type, warn)
	_component_cache[type] = result
	return result


func track(sig: Signal, callable: Callable, flags: int = 0) -> void:
	sig.connect(callable, flags)
	_tracked.append({ "signal": sig, "callable": callable, "flags": flags })


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
