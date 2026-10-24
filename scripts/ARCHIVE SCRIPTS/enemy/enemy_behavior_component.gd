#class_name EnemyBehaviorComponent
#extends MovementBase
#
#enum State {
#PATROL,
#CHASE,
#ATTACK,
#}
#
#@export_group("Flight")
#@export var is_flying: bool = false
#
#@export_group("Patrol")
#@export var patrol_speed: float = 60.0
#
#@export_group("Chase")
#@export var chase_speed: float = 120.0
#@export var detection_radius: float = 150.0
#@export var lose_radius: float = 220.0
#
#@export_group("Aggro On Hit")
#@export var aggro_on_hit: bool = true
#@export var aggro_duration: float = 4.0
#
#@export_group("Attack")
#@export var attack_range: float = 24.0
#@export var attack_cooldown: float = 1.0
#@export var attack_damage: int = 10
#
#var state: State = State.PATROL
#
#var facing_component: FacingComponent
#var _health: Health
#var _direction: float = 1.0
#var _player: Node2D
#var _attack_timer: float = 0.0
#var _aggro_timer: float = 0.0
#
#@onready var body: CharacterBody2D = get_parent() as CharacterBody2D
#@onready var wall_check: RayCast2D = get_node_or_null(^"%WallCheck") as RayCast2D
#@onready var ledge_check: RayCast2D = get_node_or_null(^"%LedgeCheck") as RayCast2D
#@onready var base_gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
#
#
#func _physics_process(delta: float) -> void:
#if _attack_timer > 0.0:
#_attack_timer -= delta
#
#if _aggro_timer > 0.0:
#_aggro_timer -= delta
#
#_player = get_tree().get_first_node_in_group(&"player")
#
#match state:
#State.PATROL:
#_patrol(delta)
#State.CHASE:
#_chase(delta)
#State.ATTACK:
#_attack(delta)
#
#if not is_flying:
#body.velocity.y += base_gravity * delta
#body.move_and_slide()
#
#
#func _on_setup() -> void:
#facing_component = get_component(FacingComponent, false) as FacingComponent
#_health = get_component(Health, false) as Health
#if _health and aggro_on_hit:
#_health.damaged.connect(_on_damaged)
#
#
#func _on_damaged(_entity: Node, _type: HealthActionType.Enum, _amount: int, _incrementer: int, _multiplier: float, applied: int) -> void:
#if applied <= 0:
#return
#_aggro_timer = aggro_duration
#if state == State.PATROL:
#state = State.CHASE
#
#
#func _current_detection_radius() -> float:
#return lose_radius if _aggro_timer > 0.0 else detection_radius
#
#
#func _patrol(_delta: float) -> void:
#if is_flying:
#body.velocity = Vector2.ZERO
#else:
#if wall_check.is_colliding() or not ledge_check.is_colliding():
#_direction *= -1.0
#_set_facing(_direction)
#body.velocity.x = _direction * patrol_speed
#
#if _player and body.global_position.distance_to(_player.global_position) <= _current_detection_radius():
#state = State.CHASE
#
#
#func _chase(_delta: float) -> void:
#if not _player:
#state = State.PATROL
#return
#
#var dist: float = body.global_position.distance_to(_player.global_position)
#
#if _aggro_timer <= 0.0 and dist > lose_radius:
#state = State.PATROL
#return
#
#if dist <= attack_range:
#state = State.ATTACK
#return
#
#if is_flying:
#var to_player: Vector2 = (_player.global_position - body.global_position).normalized()
#body.velocity = to_player * chase_speed
#_set_facing(signf(to_player.x))
#else:
#_direction = signf(_player.global_position.x - body.global_position.x)
#_set_facing(_direction)
#body.velocity.x = _direction * chase_speed
#
#
#func _attack(_delta: float) -> void:
#if is_flying:
#body.velocity = Vector2.ZERO
#else:
#body.velocity.x = 0.0
#
#if not _player:
#state = State.PATROL
#return
#if body.global_position.distance_to(_player.global_position) > attack_range:
#state = State.CHASE
#return
#if _attack_timer <= 0.0:
#_attack_timer = attack_cooldown
#var player_health := Component.find_component(_player, Health, false) as Health
#if player_health:
#player_health.damage(attack_damage, 0, 1.0, HealthActionType.Enum.KINETIC)
#
#
#func _set_facing(dir: float) -> void:
#if facing_component:
#var changed := facing_component.update(Vector2(dir, 0.0))
#if changed:
#moved.emit(facing_component.facing)
