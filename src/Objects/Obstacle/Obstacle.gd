extends StaticBody2D

export var damage : int = 5
export var hue_variation = true
export var rotate = true
export var spawn_decorations = true

var textures = [
	preload("res://Objects/Obstacle/Rock_02.png"),
	preload("res://Objects/Obstacle/Rock_01.png"),
	preload("res://Objects/Obstacle/Rock_03.png")
]

var decorations = [
	preload("res://Objects/decorations/Coral.tscn"),
]
#	preload("res://objects/decorations/shell.tscn"),
#	preload("res://objects/decorations/shell.tscn"),
#	preload("res://objects/decorations/shell.tscn"),
#]

func _ready():
	add_to_group("obstacle")
	if hue_variation == true: modulate= Color(0.9+(randf()/10.0),0.9+(randf()/10.0),0.9+(randf()/10.0),1.0)
	if spawn_decorations == true: decorate()
	
func pick_decoration(index = -1):
	var item = null
	if index>=0 and index<decorations.size():
		item = decorations[index]
	else:
		item = decorations[randi()%decorations.size()]
	return item

func set_texture(depth):
	var tex = textures[0]
	if depth>=800:
		tex = textures[1]
	if depth>=2000:
		tex = textures[2]
	$Polygon2D.texture = tex
	

func decorate():
	#get all the object spawn raycasts
	var spawn_locations = $DecorationLocations.get_children()
	
	# if there aren't any print to the console and return fail (null)
	if spawn_locations.empty():
		if game.debug == true and self.debug==true:
			print("AddObject(): no spawners on prefab %d, skipping...", name)
		return null
	
	for x in spawn_locations:
		var chance = randi()%100
		if chance<=25:
			var item = pick_decoration().instance()
			item.position = x.position
			item.rotation_degrees = randi()%360
			$Decorations.add_child(item)
			
