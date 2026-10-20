# scripts/components/ability_component.gd
class_name AbilityComponent
extends Component

signal ability_granted(id: StringName, new_level: int)

@export var starting_levels: Dictionary[StringName, int] = { }

var _levels: Dictionary[StringName, int] = { }


func get_level(id: StringName) -> int:
	return _levels.get(id, 0)


func has_ability(id: StringName) -> bool:
	return get_level(id) > 0


func grant(id: StringName, amount: int = 1) -> void:
	_levels[id] = get_level(id) + amount
	ability_granted.emit(id, _levels[id])


func set_level(id: StringName, level: int) -> void:
	_levels[id] = level
	ability_granted.emit(id, level)


func get_all_levels() -> Dictionary[StringName, int]:
	return _levels.duplicate()


func _on_setup() -> void:
	_levels = starting_levels.duplicate()
