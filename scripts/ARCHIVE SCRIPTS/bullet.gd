class_name Bullet
extends BasicHitBox2D

@export var speed: float = 600.0
@export var lifetime: float = 3.0

@export_custom(ETP.NONE, ETP.PROPERTY)
var shake_trauma: float = 0.3


func _ready() -> void:
	super()
	affect = Health.Affect.DAMAGE
	hurt_box_entered.connect(_on_hurt_box_entered)
	unknown_area_entered.connect(_on_unknown_area_entered)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += transform.x * speed * delta


func set_damage(value: float) -> void:
	amount = roundi(value)


func _on_hurt_box_entered(_hurt_box: HurtBox2D) -> void:
	ignore_collisions = true
	var room_instance := MetSys.get_current_room_instance()
	var room_camera := room_instance.get_node_or_null(^"PhantomCamera2D") as PhantomCamera2D
	if room_camera and room_camera.has_method("add_trauma"):
		room_camera.add_trauma(shake_trauma)
	queue_free()


func _on_unknown_area_entered(_area: Area2D) -> void:
	ignore_collisions = true
	queue_free()


func _on_body_entered(_body: Node) -> void:
	ignore_collisions = true
	queue_free()
