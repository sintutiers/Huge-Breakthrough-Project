# scripts/collectible_object.gd
class_name CollectibleObject
extends InteractableThing

signal collected

enum PickupMode {
	ON_INTERACT,
	ON_OVERLAP,
}

#const is_importer_node := true
@export var pickup_mode: PickupMode = PickupMode.ON_INTERACT
@export var object_id: StringName
@export var show_marker_on_map: bool = true
@export var marker_index: int = -1
@export var vanishes_when_collected: bool = true
@export var granted_ability_id: StringName
@export var granted_ability_amount: int = 1

var _pickup_area: Area2D


## -1 = use map theme's default marker for collectibles, per MetSys docs.
func _ready() -> void:
	super()
	add_to_group(&"collectible")
	print("CollectibleObject ready: ", name, " object_id=", object_id)
	set_meta(&"object_id", object_id)
	if MetSys.register_storable_object(self):
		return

	if pickup_mode == PickupMode.ON_OVERLAP:
		_pickup_area = Component.find_component(self, Area2D, false) as Area2D
		if _pickup_area:
			_pickup_area.body_entered.connect(_on_body_entered)
		else:
			push_warning("CollectibleObject: ON_OVERLAP set but no Area2D found.")
	else:
		interacted.connect(_on_interacted, CONNECT_ONE_SHOT)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	_on_interacted(null)


func _on_interacted(_by: Area2D) -> void:
	MetSys.store_object(self)
	collected.emit()
	if not granted_ability_id.is_empty():
		var player := get_tree().get_first_node_in_group(&"player")
		if player:
			var ability_component := Component.find_component(player, AbilityComponent, false) as AbilityComponent
			if ability_component:
				ability_component.grant(granted_ability_id, granted_ability_amount)
	finish_interaction()
	if vanishes_when_collected:
		queue_free()
