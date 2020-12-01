extends Node2D

export (Array, Texture) var variants

func _ready():
	$Sprite.texture = variants[randi()%variants.size()]
	
