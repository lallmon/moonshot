extends Control

func reset_values():
	$DepthGuage/Value.text = "0"
	$Hull/HullMeter/Progress.value = 100.0
	$Power/PowerMeter/Progress.value = 100.0
	$Oxygen/OxygenMeter/Progress.value = 100.0
	
func _on_Sub_depth_status(depth : float):
	depth = Utilities.pixels_to_meters(depth)
	
	$DepthGuage/Value.text = ("%d" % depth)
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

func _on_activated():
	reset_values()
#	$AnimationPlayer.play("flicker_in")

func _on_sub_destroyed():
	$AnimationPlayer.play("fade_out")

func _on_Sub_hull_status(integrity: int):
	$Hull/HullMeter/Progress.value = integrity

func _on_heavy_damage(damage: int):
	#TO DO: dynamically change the effect based on how much damage has been taken
	if not $DamageOverlay/AnimationPlayer.is_playing():
		$DamageOverlay/AnimationPlayer.play("take_damage")

func _on_Sub_oxygen_status(oxygen:float):
	$Oxygen/OxygenMeter/Progress.value = oxygen

func _on_Sub_power_status(power: float):
	$Power/PowerMeter/Progress.value = power
