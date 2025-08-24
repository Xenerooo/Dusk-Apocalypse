extends FSMState

## Executes after the state is entered.
func _on_enter(actor: Node, _blackboard: Blackboard):
	actor.animation_tree.set("parameters/Animation/conditions/idle", true)
	
## Executes every _process call, if the state is active.
func _on_update(_delta: float, _actor: Node, _blackboard: Blackboard):
	#if _actor is PlayerCharacter:
	
	#blend_all_animation(_actor, _actor.get_input())
	
	if _actor.get_input() != Vector2.ZERO:
		_actor.state_machine.fire_event("to_run")
		
func blend_all_animation( actor: PlayerCharacter,blend_dir):
	actor.animation_tree.set("parameters/Animation/idle/blend_position", blend_dir)
	

## Executes before the state is exited.
func _on_exit(actor: Node, _blackboard: Blackboard):
	actor.animation_tree.set("parameters/Animation/conditions/idle", false)
	
