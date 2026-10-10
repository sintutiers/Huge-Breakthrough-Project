class_name DeanHurtBox2D
extends BasicHurtBox2D

func _ready() -> void:
	if not health:
		health = Component.find_component(get_parent(), Health, true) as Health
	super()
