extends FSMState

## Executes after the state is entered.
func _on_enter(actor: Node, _blackboard: Blackboard):
	actor.animation_tree.set("parameters/Animation/conditions/interact", true)
	
## Executes every _process call, if the state is active.
func _on_update(_delta: float, _actor: Node, _blackboard: Blackboard):
	pass
	

## Executes before the state is exited.
func _on_exit(actor: Node, _blackboard: Blackboard):
	actor.animation_tree.set("parameters/Animation/conditions/interact", false)
	
