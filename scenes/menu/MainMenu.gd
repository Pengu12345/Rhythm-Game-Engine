extends Node2D

export (PackedScene) var rhythm_engine

var song_playing = false
var song_instance = null

# Called when the node enters the scene tree for the first time.
func _ready():
	$FileDialog.popup()
	
	var error_message = GameManager.error_message
	if(error_message != ""):
		$AcceptDialog.dialog_text = "Error while loading remix: \n" + error_message
		$AcceptDialog.popup()
	

func _process(delta):
	pass


func _on_FileDialog_file_selected(path):
	GameManager.load_chart(path)
	
func _on_AcceptDialog_confirmed():
	$FileDialog.popup()
