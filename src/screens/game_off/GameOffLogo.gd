extends Node2D

func _input(event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(1) or Input.is_mouse_button_pressed(2) or Input.is_action_just_pressed("pause_btn"):
		game.main.load_screen(game.main.INTRO_SCN)
		
func _on_NextTimer_timeout() -> void:
	game.main.load_screen(game.main.INTRO_SCN)
