extends Node

onready var track1 = $Track01
onready var track2 = $Track02

var first_depth = 0
var second_depth = 30
var third_depth = 1000
var fourth_depth = 1030
var fifth_depth = 4000
var sixth_depth = 4030

export (Array, AudioStream) var streams = []

func _ready() -> void:
	if game.player!=null:
		game.player.connect("depth_status", self, "_on_Sub_depth_status")
		game.player.connect("sub_destroyed", self, "_on_Sub_destroyed")

func _on_Sub_destroyed():
	if track1.playing:
		$AnimationPlayer.play("track1_fade_out")
	elif track2.playing:
		$AnimationPlayer.play("track2_fade_out")
	
func _on_Sub_depth_status(depth):
	var meters = Utilities.pixels_to_meters(depth)
	if (meters >= first_depth && meters < first_depth+2) && not track1.playing:
		track1.stream = streams[0]
		$AnimationPlayer.play("track1_fade_in")
	if (meters >= second_depth && meters < second_depth+2) && not track2.playing:
		track2.stream = streams[1]
		$AnimationPlayer.play("cross_fade_track1_to_track2")
	if (meters >= third_depth && meters < third_depth+2) && not track1.playing:
		track1.stream = streams[2]
		$AnimationPlayer.play("cross_fade_track2_to_track1")
	if (meters >= fourth_depth && meters < fourth_depth+2) && not track2.playing:
		track2.stream = streams[3]
		$AnimationPlayer.play("cross_fade_track1_to_track2")
	if (meters >= fifth_depth && meters < fifth_depth+2) && not track1.playing:
		track1.stream = streams[4]
		$AnimationPlayer.play("cross_fade_track2_to_track1")
	if (meters >= sixth_depth && meters < sixth_depth+2) && not track2.playing:
		track2.stream = streams[5]
		$AnimationPlayer.play("cross_fade_track1_to_track2")
