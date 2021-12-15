extends Node2D

export (PackedScene) var rhythm_engine

var song_playing = false
var song_instance = null

# Called when the node enters the scene tree for the first time.
func _ready():
	$FileDialog.popup()

func _process(delta):
	pass


func _on_FileDialog_file_selected(path):
	$FileDialog.visible = false
	var instance = rhythm_engine.instance()
	instance.chart_path = path
	song_instance = instance
	$remix_display.add_child(instance)
	
	instance.connect("load_failed",self,"_on_load_failed")
	if !(instance.play() is bool):
		song_playing = true
	
func _on_load_failed(message):
	$AcceptDialog.dialog_text = "Error while loading remix: \n" + message
	$AcceptDialog.popup()
	song_instance.queue_free()
	
	


func _on_AcceptDialog_confirmed():
	$FileDialog.popup()
