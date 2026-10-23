## owns every component on the player [CharacterBody3D] and wires
## their dependencies in [method Node._enter_tree]. this is the single wiring site
## components never look up their siblings themselves. the body is the ancestor
## that mediates every sibling relationship.
##
## exports win over auto-resolution: if you drag a component or node into an
## inspector slot, that reference is used. otherwise the body finds the child by
## type. [MovementProfile] is a [Resource], not a [Node], so it can't be found in
## the tree — it defaults to a fresh instance if no profile is exported.
class_name PlayerBody
extends CharacterBody3D

@export_group("Components")
@export var input: InputComponent
@export var facing: FacingComponent
@export var movement: Movement3DComponent
@export var interaction: InteractionComponent
@export var animation: AnimationComponent
#@export var launch: LaunchComponent
@export var attack: AttackComponent
@export var ability: AbilityComponent

@export_group("Data")
@export var movement_profile: MovementProfile

@export_group("Scene Nodes")
@export var sprite: AnimatedSprite3D
@export var collision_shape: CollisionShape3D
@export var interact_area: Area3D
@export var state_chart: StateChart


func _enter_tree() -> void:
	_wire_components()


func _wire_components() -> void:
	if not input:
		input = _find_child_of_type(InputComponent)
	if not facing:
		facing = _find_child_of_type(FacingComponent)
	if not movement:
		movement = _find_child_of_type(PlatformerMovementBase) as Movement3DComponent
	if not interaction:
		interaction = _find_child_of_type(InteractionComponent)
	if not animation:
		animation = _find_child_of_type(AnimationComponent)
	#if not launch:
	#launch = _find_child_of_type(LaunchComponent)
	if not attack:
		attack = _find_child_of_type(AttackComponent)
	if not ability:
		ability = _find_child_of_type(AbilityComponent)

	if not sprite:
		sprite = _find_child_of_type(AnimatedSprite3D)
	if not collision_shape:
		collision_shape = _find_child_of_type(CollisionShape3D)
	if not interact_area:
		interact_area = _find_child_of_type(Area3D)
	if not state_chart:
		state_chart = _find_child_of_type(StateChart)

	if not movement_profile:
		movement_profile = MovementProfile.new()

	if movement:
		movement.body = self
		movement.profile = movement_profile
		movement.input_component = input
		movement.facing_component = facing
		movement.ability_component = ability
		#movement.launch_component = launch
		movement.interact_component = interaction
		movement.collision_shape = collision_shape
		movement.state_chart = state_chart
	if interaction:
		interaction.body = self
		interaction.input_component = input
		interaction.state_chart = state_chart
		interaction.interact_area = interact_area
	if animation:
		animation.sprite = sprite
		animation.movement = movement
		animation.facing = facing
		#animation.launch = launch
		animation.attack = attack


func _find_child_of_type(type: Variant) -> Node:
	return Component.find_component(self, type, false)
