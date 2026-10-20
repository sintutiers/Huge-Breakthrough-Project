# scripts/components/weapon_inventory_component.gd
class_name WeaponInventoryComponent
extends Component

signal weapon_changed(weapon: WeaponResource)

@export var weapon_catalog: Array[WeaponResource] = []

var owned_weapons: Array[WeaponResource] = []
var current_index: int = 0

var input_component: InputComponent
var ability_component: AbilityComponent


func _unhandled_input(event: InputEvent) -> void:
	if owned_weapons.size() <= 1:
		return
	var dir: int = input_component.weapon_scroll_direction(event)
	if dir != 0:
		_cycle(dir)


func current_weapon() -> WeaponResource:
	return owned_weapons[current_index] if not owned_weapons.is_empty() else null


func _on_setup() -> void:
	input_component = get_component(InputComponent) as InputComponent
	ability_component = get_component(AbilityComponent, false) as AbilityComponent
	if ability_component:
		ability_component.ability_granted.connect(_on_ability_granted)
	owned_weapons = _resolve_owned_weapons()
	if not owned_weapons.is_empty():
		weapon_changed.emit(current_weapon())


func _on_ability_granted(_id: StringName, _new_level: int) -> void:
	var new_owned: Array[WeaponResource] = _resolve_owned_weapons()
	if new_owned == owned_weapons:
		return
	owned_weapons = new_owned
	current_index = owned_weapons.size() - 1
	weapon_changed.emit(current_weapon())


func _resolve_owned_weapons() -> Array[WeaponResource]:
	var result: Array[WeaponResource] = []
	if not ability_component:
		return result
	result.assign(
		weapon_catalog.filter(
			func(weapon: WeaponResource) -> bool:
				return ability_component.has_ability(weapon.ability_id),
		),
	)
	return result


func _cycle(delta: int) -> void:
	current_index = wrapi(current_index + delta, 0, owned_weapons.size())
	weapon_changed.emit(current_weapon())
