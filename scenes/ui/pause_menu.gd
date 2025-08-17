extends Control


func _on_resume_pressed() -> void:
	GameSession.resume_game()


func _on_exit_pressed() -> void:
	if MultiplayerManager.is_host():
		GameSession.save_world()
	GameSession.reset_session()
