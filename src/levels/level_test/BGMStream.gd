extends AudioStreamPlayer

func _ready():
	if game.player!=null:
		game.player.connect("depth_status", self, "_on_Sub_depth_status")
	
func _on_Sub_depth_status(depth):
	var meters = Utilities.pixels_to_meters(depth)
	if (meters >= 10 and meters < 12) && playing == false:
		play()
	if depth > 0 and depth < 30:
		$Zone.text = "Sunlight Zone"
	elif depth > 200 and depth < 230:
		$Zone.text = "Twilight Zone"
	elif depth > 1000 and depth < 1030:
		$Zone.text = "Midnight Zone"
	elif depth > 3000 and depth < 4030:
		$Zone.text = "The Abyss"
	elif depth > 6000 and depth < 6030:
		$Zone.text = "Basin"
	elif depth > 7000 and depth < 7030:
		$Zone.text = "The Trenches"
	else:
		$Zone.text = ""
