extends FSMState

## Executes after the state is entered.
func _on_enter(actor: Node, _blackboard: Blackboard):
	actor.animation_tree.set("parameters/Animation/conditions/run", true)

## Executes every _process call, if the state is active.
func _on_update(_delta: float, _actor: Node, _blackboard: Blackboard):
	_actor = _actor as PlayerCharacter
	
	if _actor.velocity == Vector2.ZERO:
		_actor.travel_state("to_idle")
	else:
		_actor.animation_tree.set("parameters/Animation/conditions/sneak", _actor.sneaking)
		#_actor.animation_tree.set("parameters/Animation/conditions/sneak_aim", (_actor.active_weapon_index != 0 and _actor.aiming) and _actor.sneaking)
		_actor.animation_tree.set("parameters/Animation/conditions/run", (_actor.active_weapon_index == 0 or !_actor.aiming) and !_actor.sneaking)
		_actor.animation_tree.set("parameters/Animation/conditions/run_aim",( _actor.active_weapon_index != 0 and _actor.aiming) and !_actor.sneaking)
		blend_all_animation(_actor, _actor.get_aim_input() if _actor.aiming else _actor.velocity)

func blend_all_animation(actor: PlayerCharacter,blend_dir):
	actor.animation_tree.set("parameters/Animation/run/blend_position", blend_dir)
	actor.animation_tree.set("parameters/Animation/idle/blend_position", blend_dir)
	actor.animation_tree.set("parameters/Animation/run_aim/blend_position", blend_dir)
	actor.animation_tree.set("parameters/Animation/idle_aim/blend_position", blend_dir)
	actor.animation_tree.set("parameters/Animation/sneak_idle/blend_position", blend_dir)
	actor.animation_tree.set("parameters/Animation/sneak/blend_position", blend_dir)
	actor.animation_tree.set("parameters/Animation/sneak_aim/blend_position", blend_dir)

## Executes before the state is exited.
func _on_exit(actor: Node, _blackboard: Blackboard):
	actor.animation_tree.set("parameters/Animation/conditions/run", false)
	actor.animation_tree.set("parameters/Animation/conditions/run_aim", false)
	actor.animation_tree.set("parameters/Animation/conditions/sneak", false)
	actor.animation_tree.set("parameters/Animation/conditions/sneak_aim", false)
