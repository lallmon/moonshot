extends Node

onready var track1 = $Track01
onready var track2 = $Track02

var sunlight_depth = 10
var twilight_depth = 200
var midnight_depth = 1000
var abyss_depth = 4000
var hades_depth = 7000
var space_depth = 10000

export (Array, AudioStream) var streams = []

func _ready() -> void:
	if game.player!=null:
		game.player.connect("depth_status", self, "_on_Sub_depth_status")

func _on_Sub_depth_status(depth):
	var meters = Utilities.pixels_to_meters(depth)
	if (meters >= sunlight_depth && meters < sunlight_depth+2) && not track1.playing:
		track1.stream = streams[0]
		$AnimationPlayer.play("track1_fade_in")
	if (meters >= twilight_depth && meters < twilight_depth+2) && not track2.playing:
		track2.stream = streams[1]
		$AnimationPlayer.play("cross_fade_track1_to_track2")
	if (meters >= midnight_depth && meters < midnight_depth+2) && not track1.playing:
		track1.stream = streams[2]
		$AnimationPlayer.play("cross_fade_track2_to_track1")
	if (meters >= abyss_depth && meters < abyss_depth+2) && not track2.playing:
		track2.stream = streams[1]
		$AnimationPlayer.play("cross_fade_track1_to_track2")
