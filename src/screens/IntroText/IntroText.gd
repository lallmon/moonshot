extends Node2D

var state=0

func _ready():
	$Music.play()
	$Music/AnimationPlayer.play("fade_in")

func _input(event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(1) or Input.is_mouse_button_pressed(2) or Input.is_action_just_pressed("pause_btn"):
		game.main.load_screen(game.main.GAME_SCN)

func _on_NextTimer_timeout() -> void:
	match (state):
		0:
			$AnimationPlayer.play("one_fade")
			state = 1
		1:
			$AnimationPlayer.play_backwards("one_fade")
			state = 2
		2:
			$AnimationPlayer.play("two_fade")
			state = 3
		3:
			$AnimationPlayer.play_backwards("two_fade")
			state = 4
		4:
			$AnimationPlayer.play("three_fade")
			state = 5
		5:
			$AnimationPlayer.play_backwards("three_fade")
			state = 6
		6:
			$AnimationPlayer.play("four_fade")
			state = 7
		7:
			$AnimationPlayer.play_backwards("four_fade")
			$Music/AnimationPlayer.play("fade_out")
			state = 8
		8:
			game.main.load_screen(game.main.GAME_SCN)
