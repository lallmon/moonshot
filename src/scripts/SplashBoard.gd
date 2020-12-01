extends Control

var deepest:int setget set_deepest
var longest:int setget set_longest

func _ready() -> void:
	game.load_game()
	self.deepest = game.deepest
	self.longest = game.longest
	$Deepest.visible = true
	$Longest.visible = true
	if deepest == null:
		$Deepest.visible = false
	if longest == null:
		$Longest.visible = false
	$AnimationPlayer.play("fade_in")

func set_deepest(newvar):
	deepest = newvar
	$Deepest/DeepestValue.text = String(deepest) + "m"
	return

func set_longest(newvar):
	longest = newvar
	var longest_string
	if int(longest)<=60:
		longest_string = String(longest) + "seconds"
	else:
		longest_string = String(int(longest/60)) + "min, " + String((int(longest%60))) + "sec"
	$Longest/LongestValue.text = longest_string
	return

func _on_SplashBoardFade_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if not $AnimationPlayer.is_playing():
			$AnimationPlayer.play("fade_out")
		if game.gui!=null:
			var gui_animation = game.gui.get_node("AnimationPlayer")
			if not gui_animation.is_playing():
				gui_animation.play("flicker_in")
		body.begin()
		yield ($AnimationPlayer,"animation_finished")
		queue_free()
