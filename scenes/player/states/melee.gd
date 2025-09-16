extends FSMState

## Executes after the state is entered.
func _on_enter(actor: Node, _blackboard: Blackboard):
	actor.animation_tree.set("parameters/Animation/conditions/melee", true)
	blend_all_animation(actor, actor.get_aim_input())

## Executes every _process call, if the state is active.
func _on_update(_delta: float, _actor: Node, _blackboard: Blackboard):
	#if _actor.get_input() == Vector2.ZERO:
		#_actor.state_machine.fire_event("to_idle")
	
	#else:
		#blend_all_animation(_actor, _actor.get_aim_input())
	pass
	
func blend_all_animation(actor: PlayerCharacter,blend_dir):
	actor.animation_tree.set("parameters/Animation/run/blend_position", blend_dir)
	actor.animation_tree.set("parameters/Animation/idle/blend_position", blend_dir)
	actor.animation_tree.set("parameters/Animation/run_aim/blend_position", blend_dir)
	actor.animation_tree.set("parameters/Animation/idle_aim/blend_position", blend_dir)
	actor.animation_tree.set("parameters/Animation/sneak_idle/blend_position", blend_dir)
	actor.animation_tree.set("parameters/Animation/sneak/blend_position", blend_dir)
	actor.animation_tree.set("parameters/Animation/melee/blend_position", blend_dir)

## Executes before the state is exited.
func _on_exit(actor: Node, _blackboard: Blackboard):
	#actor.animation_tree.set("parameters/Animation/conditions/run", false)
	actor.animation_tree.set("parameters/Animation/conditions/melee", false)
	#actor.animation_tree.set("parameters/Animation/conditions/idle", false)
