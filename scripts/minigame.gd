# Minigame interfaces that handle general functions shared between every other minigame

extends Node

signal miss
signal auto_ok
signal auto_fail

var conductor

export var loaded_sfxs = {}
var playing_sfxs = []

var is_ready = false
var input_enabled = false

func _ready():
	is_ready = true
	input_enabled = true
	_on_ready()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		GameManager.load_previous_scene()

# I'm using a "bridge" function in order to control inputs better
func manage_input(input_name, input):
	# Doesn't work if either inputs or game overall are disabled
	if !input_enabled or !is_ready: return

	match input_name:
		"good": on_good_input(input)
		"barely": on_barely_input(input)
		"missed": on_missed_input(input)
		"blank": on_blank_input(input)

func _process(delta):
	if !is_ready: return
	_on_process(delta)
	
	# Handcrafted filter function since Godot doesn't implement it
	# Remove the sfxs that aren't playing from the list
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
func play_sound(sound_name, node, _db = 0, _pitch = 1, _bus = ""):
	var ap = AudioStreamPlayer.new()
	
	if loaded_sfxs.has(sound_name):
		var stream = loaded_sfxs[sound_name] 
		ap.stream = stream
		ap.pitch_scale = _pitch
		ap.volume_db = _db
		if stream is AudioStreamSample:
			stream.set_loop_mode(AudioStreamSample.LOOP_DISABLED)
		else:
			stream.set_loop(AudioStreamSample.LOOP_DISABLED)
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
func on_blank_input(action_id):pass
func on_good_input(input):pass
func on_barely_input(input):pass

func _on_new_beat(beat): pass
func _on_new_bar(bar): pass
