extends FSMState

## Executes after the state is entered.
func _on_enter(actor: Node, _blackboard: Blackboard):
	actor.animation_tree.set("parameters/Animation/conditions/idle", true)
	
## Executes every _process call, if the state is active.
func _on_update(_delta: float, _actor: Node, _blackboard: Blackboard):
	_actor = _actor as PlayerCharacter
	if !_actor.can_move():
		return 
	
	_actor.animation_tree.set("parameters/Animation/conditions/idle", (_actor.active_weapon_index == 0 or !_actor.aiming) and !_actor.sneaking)
	_actor.animation_tree.set("parameters/Animation/conditions/sneak_idle", (_actor.active_weapon_index == 0 or !_actor.aiming) and _actor.sneaking)
	_actor.animation_tree.set("parameters/Animation/conditions/sneak_aim", (_actor.active_weapon_index != 0 and _actor.aiming) and _actor.sneaking)
	_actor.animation_tree.set("parameters/Animation/conditions/idle_aim", (_actor.active_weapon_index != 0 and _actor.aiming)  and !_actor.sneaking)
	
	if _actor.aiming:
		blend_all_animation(_actor, _actor.get_last_aim_input())

	if _actor.velocity != Vector2.ZERO:
		_actor.travel_state("to_run")
	

func blend_all_animation( actor: PlayerCharacter,blend_dir):
	actor.animation_tree.set("parameters/Animation/idle/blend_position", blend_dir)
	actor.animation_tree.set("parameters/Animation/idle_aim/blend_position", blend_dir)
	actor.animation_tree.set("parameters/Animation/sneak_idle/blend_position", blend_dir)
	actor.animation_tree.set("parameters/Animation/sneak_aim/blend_position", blend_dir)

## Executes before the state is exited.
func _on_exit(actor: Node, _blackboard: Blackboard):
	actor.animation_tree.set("parameters/Animation/conditions/idle", false)
	actor.animation_tree.set("parameters/Animation/conditions/sneak_idle", false)
	actor.animation_tree.set("parameters/Animation/conditions/idle_aim", false)
	actor.animation_tree.set("parameters/Animation/conditions/sneak_aim", false)
