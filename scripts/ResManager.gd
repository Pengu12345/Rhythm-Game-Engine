extends Node

onready var routes_path = "res://data/scene_route.json"

var scenes_path = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	load_paths()


func get_scene_by_name(name):
	if scenes_path.has(name):
		return load(scenes_path[name])
	else:
		print("Error: Could not load scene with name " + name + ". Is the route correct?")
	
func load_paths():
	var file = File.new()
	file.open(routes_path, File.READ)
	var content = file.get_as_text()
	file.close()
	
	#Parse the content
	var res = JSON.parse(content).get_result()
	
	for route in res["routes"]:
		scenes_path[route["name"]] = route["path"]

func load_patterns(pattern_name):
	var file = File.new()
	file.open("res://data/patterns/" + pattern_name + ".json", File.READ)
	var content = file.get_as_text()
	file.close()
	
	var res = JSON.parse(content).get_result()
	
	return res
