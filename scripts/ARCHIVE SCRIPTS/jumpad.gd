class_name Launchpad
extends Area2D

@export var direction: Vector2 = Vector2.UP
@export var speed: float = 1200.0
@export var distance: float = 300.0
@export var require_input: bool = false
@export var squash_scale: Vector2 = Vector2(1.3, 0.7)
@export var squash_out_duration: float = 0.28
@export var squash_exp_speed: float = 18.0

var _target: LaunchComponent
var _sprite: Node2D
var _base_scale: Vector2 = Vector2.ONE

var _squash_active: bool = false
var _squash_t: float = 0.0
var _squash_out: bool = true


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_sprite = Component.find_component(self, Sprite2D, false) as Sprite2D
	if not _sprite:
		_sprite = Component.find_component(self, AnimatedSprite2D, false) as AnimatedSprite2D
	if _sprite:
		_base_scale = _sprite.scale


func _process(delta: float) -> void:
	if not _squash_active:
		return
	var target: Vector2 = _base_scale * squash_scale if _squash_out else _base_scale
	_sprite.scale = _sprite.scale.lerp(target, 1.0 - exp(-squash_exp_speed * delta))
	_squash_t += delta
	if _squash_out and _squash_t >= squash_out_duration:
		_squash_out = false
	elif not _squash_out and _sprite.scale.distance_to(_base_scale) < 0.01:
		_squash_active = false
		_sprite.scale = _base_scale


func _on_body_entered(body: Node2D) -> void:
	_target = Component.find_component(body, LaunchComponent) as LaunchComponent
	if not _target:
		return
	_target.launched.connect(_play_squash)
	if require_input:
		_target.register_pad(direction, speed, distance)
	else:
		_target.launch(direction, speed, distance)


func _on_body_exited(_body: Node2D) -> void:
	if _target:
		_target.clear_pad()
		if _target.launched.is_connected(_play_squash):
			_target.launched.disconnect(_play_squash)
	_target = null


func _play_squash() -> void:
	if not _sprite:
		return
	_squash_active = true
	_squash_t = 0.0
	_squash_out = true
