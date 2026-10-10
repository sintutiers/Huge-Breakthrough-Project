class_name DeathResponseComponent
extends Component

signal respawned

@export_custom(ETP.NONE, ETP.PROPERTY)
var free_on_death: bool = true
@export_custom(ETP.NONE, ETP.PROPERTY)
var respawn_on_death: bool = false
@export_custom(ETP.NONE, ETP.PROPERTY)
var respawn_heal_amount: int = 0
@export_custom(ETP.NONE, ETP.PROPERTY)
var heal_on_respawn: bool = true

var is_respawning: bool = false
var reset_position: Vector2
var _has_reset_position: bool = false

var _health: Health

@onready var body: CharacterBody2D = get_parent() as CharacterBody2D


func mark_room_entry_point() -> void:
	reset_position = body.global_position
	_has_reset_position = true


func fall_and_respawn(respawn_position: Vector2) -> void:
	if is_respawning:
		return
	is_respawning = true
	body.velocity = Vector2.ZERO
	body.global_position = respawn_position
	is_respawning = false
	respawned.emit()
	if heal_on_respawn and _health:
		if respawn_heal_amount <= 0:
			_health.fill()
		else:
			_health.heal(respawn_heal_amount)


func _on_setup() -> void:
	_health = get_component(Health, false) as Health
	if _health:
		track(_health.died, _on_died)


func _on_died(_entity: Node) -> void:
	if free_on_death:
		get_parent().queue_free()
	elif respawn_on_death:
		fall_and_respawn(reset_position if _has_reset_position else body.global_position)
