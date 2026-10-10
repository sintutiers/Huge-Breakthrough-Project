# scripts/gate_requirement.gd
class_name GateRequirement
extends Resource

signal requirement_changed

enum CheckType {
	ABILITY,
	OBJECT_COLLECTED,
}

@export_custom(ETP.NONE, ETP.PROPERTY)
var check_type: CheckType = CheckType.ABILITY
@export_custom(ETP.NONE, ETP.PROPERTY)
var ability_id: StringName
@export_custom(ETP.NONE, ETP.PROPERTY)
var min_level: int = 1
@export_custom(ETP.NONE, ETP.PROPERTY)
var object_id: StringName


func is_met(player: Node) -> bool:
	match check_type:
		CheckType.ABILITY:
			var ability := Component.find_component(player, AbilityComponent, false) as AbilityComponent
			return ability and ability.get_level(ability_id) >= min_level
		CheckType.OBJECT_COLLECTED:
			return MetSys.is_object_id_stored(object_id)
	return false


func setup(gate: Node) -> void:
	match check_type:
		CheckType.ABILITY:
			_setup_ability(gate)
		CheckType.OBJECT_COLLECTED:
			_setup_object_collected(gate)


func _setup_ability(gate: Node) -> void:
	var tree := gate.get_tree()
	if not tree:
		return
	var player := tree.get_first_node_in_group(&"player")
	if not player:
		return
	var ability_component := Component.find_component(player, AbilityComponent, false) as AbilityComponent
	if ability_component:
		ability_component.ability_granted.connect(_on_ability_granted)


func _setup_object_collected(gate: Node) -> void:
	var tree := gate.get_tree()
	if not tree:
		return
	for node in tree.get_nodes_in_group(&"collectible"):
		var collectible := node as CollectibleObject
		if collectible and collectible.object_id == object_id:
			collectible.collected.connect(_on_collected)


func _on_ability_granted(_id: StringName, _level: int) -> void:
	requirement_changed.emit()


func _on_collected() -> void:
	requirement_changed.emit()
