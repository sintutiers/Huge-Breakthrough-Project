# scripts/gate_requirement.gd
class_name GateRequirement
extends Resource

signal requirement_changed

@export var ability_id: StringName
@export var min_level: int = 1


func is_met(player: Node) -> bool:
	var ability := Component.find_component(player, AbilityComponent, false) as AbilityComponent
	return ability != null and ability.get_level(ability_id) >= min_level


func setup(gate: Node) -> void:
	var tree := gate.get_tree()
	if not tree:
		return
	var player := tree.get_first_node_in_group(&"player")
	if not player:
		return
	var ability_component := Component.find_component(player, AbilityComponent, false) as AbilityComponent
	if ability_component:
		ability_component.ability_granted.connect(_on_ability_granted)


func _on_ability_granted(_id: StringName, _level: int) -> void:
	requirement_changed.emit()
