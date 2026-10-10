class_name InvincibilityComponent
extends Component

@export_custom(ETP.NONE, ETP.PROPERTY)
var duration: float = 0.5

var is_invincible: bool = false

var _timer: float = 0.0
var _health: Health


func _physics_process(delta: float) -> void:
	if not is_invincible:
		return
	_timer -= delta
	if _timer <= 0.0:
		_end_invincibility()


func _on_setup() -> void:
	_health = get_component(Health, false) as Health
	if _health:
		track(_health.damaged, _on_damaged)


func _on_damaged(
		_entity: Node,
		_type: HealthActionType.Enum,
		_amount: int,
		_incrementer: int,
		_multiplier: float,
		applied: int,
) -> void:
	if applied <= 0 or duration <= 0.0:
		return
	is_invincible = true
	_health.damageable = false
	_timer = duration


func _end_invincibility() -> void:
	is_invincible = false
	if _health:
		_health.damageable = true
