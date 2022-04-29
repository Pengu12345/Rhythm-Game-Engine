extends Node

onready var return_menu = null

var previous_scene : PackedScene
var rhythm_engine : PackedScene
var rating_screen : PackedScene

onready var loaded_chart  = ""
onready var loaded_rating = 0 # 0 -> Try again; 1 -> OK; 2 -> Superb
onready var error_message = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	previous_scene = null
	rhythm_engine = load("res://scenes/RhythmEngine.tscn")
	rating_screen = load("res://scenes/RatingScreen.tscn")

# Loads the chart specified within the parameters
func load_chart(chart_path):
	loaded_chart = chart_path
	previous_scene = load(get_tree().current_scene.filename)
	get_tree().change_scene_to(rhythm_engine)

# Loads the rating screen automatically with the last loaded chart path and rating
func load_rating_screen():
	get_tree().change_scene_to(rating_screen)

#Load the previously loaded scene. Throw any errors if there is any.
func load_previous_scene(error = ""):
	if previous_scene:
		#We reset the previous scene variable since we're gonna switch it anyway
		var scene_tmp = previous_scene
		previous_scene = null
		#If there's any errors to throw while switching scenes (There's not by default)
		error_message = error
		get_tree().change_scene_to(scene_tmp)
	else:
		print("Can't load previous scene!")
		if error != "": print("[ERROR]: " + error_message)
