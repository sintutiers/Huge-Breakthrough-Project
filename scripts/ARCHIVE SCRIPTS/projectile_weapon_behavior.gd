class_name ProjectileWeaponBehavior
extends WeaponBehavior

@export var projectile_scene: PackedScene
@export var projectile_count: int = 1
@export var spread_degrees: float = 0.0


func fire(attack_component: AttackComponent, muzzle: Node2D) -> void:
	if not projectile_scene:
		return
	var mid_index: float = (projectile_count - 1) / 2.0
	for i in projectile_count:
		var angle_offset: float = deg_to_rad((i - mid_index) * spread_degrees)
		var projectile: Node2D = projectile_scene.instantiate()
		attack_component.get_tree().current_scene.add_child(projectile)
		projectile.global_transform = muzzle.global_transform
		projectile.rotate(angle_offset)
		var bullet := projectile as Bullet
		if bullet:
			bullet.set_damage(attack_component.weapon.damage)
