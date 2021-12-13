# Minigame interfaces that handle general functions shared between every other minigame

extends Node

var conductor

export var loaded_sfxs = {}
var playing_sfxs = []

func _ready():
	_on_ready()

func _process(delta):
	_on_process(delta)
	
	#Handcrafted filter function since Godot doesn't implement it
	#Remove the sfxs that aren't playing from the list
	var new_playing_sfxs = []
	for ap in playing_sfxs:
		if ap.playing:
			new_playing_sfxs.append(ap)
		else:
			ap.queue_free()
	playing_sfxs = new_playing_sfxs
	
	
func set_conductor(node):
	conductor = node
	conductor.connect("new_beat",self,"_on_new_beat")
	conductor.connect("new_bar",self,"_on_new_bar")

# Creates an AudioStreamPlayer on the go. I don't know if it's any less efficient.
# Should be looked into eventually.
func play_sound(sound_name, node, _bus = ""):
	var ap = AudioStreamPlayer.new()
	
	if loaded_sfxs.has(sound_name):
		var stream = loaded_sfxs[sound_name] 
		ap.stream = stream
		stream.loop_mode = AudioStreamSample.LOOP_DISABLED
		if _bus != "": ap.bus = _bus
		node.add_child(ap)
		ap.play()
		playing_sfxs.append(ap)
	else:
		print("Could not load sfx of name "  + sound_name + ".")

# ---------------------------------#
# METHODS USED BY CHILDREN CLASSES #
# ---------------------------------#
func _on_ready(): pass
func _on_process(delta):pass
func play_event(event):pass
func play_sfx(sfx_name):pass
func on_missed_input(input):pass
func on_blank_input():pass
func on_good_input(input):pass

func _on_new_beat(beat): pass
func _on_new_bar(bar): pass
