# CLASS THAT HANDLES EVERYTHING INPUT AND CHART RELATED. 
# LOADS A JSON AND LAUNCH THE MINIGAME RELATED. 
# DOES NOT KEEP TRACK OF THE SONG POSITION. FOR THAT,  CHECK THE CONDUCTOR CLASS 
# -------------------------------------------------------------------------------

extends Node2D

var conductor

export var chart_path = ""
var cue_list = []
var input_list = []
var pattern_list = []

var minigame_list = {}

var iterated = 0

var loaded_music

export var transition_time = 0.1

export var input_margin = 0.1
export var input_offset = 0.0

var starting_minigame
var current_minigame

func _ready():
	conductor = $Conductor
	parse_minigame_data(chart_path)
	load_minigame(starting_minigame)
	
	yield(get_tree().create_timer(1.0), "timeout")
	
	conductor.start_song()

func _process(delta):
	if !conductor.song_started : return
	
	#Cues in general
	if cue_list.size() != 0:
		var cue = cue_list[0]
		if conductor.get_song_position() > cue["position"]:
			match cue["type"]:
				"sfx": current_minigame.play_sfx(cue["name"])
				"event":
					match cue["name"]:
						"set_bpm":
							update_chart_bpm(conductor.get_bpm(), cue["value"], cue["position"])
							conductor.set_bpm(cue["value"])
						"load_minigame": load_minigame(cue["value"])
						_:current_minigame.play_event(cue)
				
			cue_list.remove(0)
	
	#Inputs in general
	if input_list.size() != 0:
		var input = input_list[0]
		var input_pos = input["position"]
		var pos = conductor.get_raw_song_position() - input_offset - input_margin
		if pos > input_pos:
			current_minigame.on_missed_input(input)
			input_list.remove(0)
	
	 #Check input
	if Input.is_action_just_pressed("control_action"):
		if input_list.size() == 0:
			current_minigame.on_blank_input()
			return
		var input = input_list[0]
		on_input(input)
	
	current_minigame._on_process(delta)

#-----------------#
# INPUT FUNCTIONS #
#-----------------#
func on_input(input):
	var input_pos = input["position"]
	if is_input_in_rythm(input_pos):
		current_minigame.on_good_input(input)
		input_list.remove(0)
	else:
		current_minigame.on_blank_input()

#Return true if the input requested is right relative to the current song position
func is_input_in_rythm(hit_position):
	var timing = get_input_timing(hit_position)
	return is_input_timing_right(timing)

#Returns in milliseconds the timing of the hit position relative to the song position
func get_input_timing(hit_position):
	var song_pos = conductor.get_raw_song_position() - input_offset
	var timing = hit_position - song_pos
	return timing

#Checks if the timing enters within the input margins of the conductor
func is_input_timing_right(timing):
	return timing < input_margin and timing > -input_margin

func set_input_margin(new_margin): input_margin = new_margin
func set_input_offset(new_offset): input_offset = new_offset

func update_chart_bpm(old_bpm,new_bpm, reference_point):
	var factor = new_bpm/old_bpm
	for cue in cue_list:
		cue["position"] =  ((cue["position"] - reference_point) / factor) + reference_point

func load_minigame(name):
	if !minigame_list.has(name):
		print("Could not load minigame " + name + " correctly.")

	var scene = minigame_list[name]
	if current_minigame:
		current_minigame.queue_free()
	
	current_minigame = scene.instance()
	current_minigame.set_conductor(conductor)
	
	yield(get_tree().create_timer(transition_time), "timeout") #Makeshift transition
	add_child(current_minigame)


#########################
# PARSING MINIGAME DATA #
#########################

func parse_minigame_data(path):
	var file = File.new()
	file.open(path, File.READ)
	var content = file.get_as_text()
	file.close()
	#Parse the content
	var res = JSON.parse(content).get_result()
	
	#-----------------------------------#
	# GETTING ALL THE DATA OF THE CHART #
	#-----------------------------------#
	
	#Loading all of the patterns
	for pattern_name in res["loaded_patterns"]:
		pattern_list += ResManager.load_patterns(pattern_name)
	
	#Loading all of the minigame scenes
	for name in res["minigames"]:
		minigame_list[name] = ResManager.get_scene_by_name(name)
	
	#Get general informations about the song
	var beat_length = (120.0 / res["bpm"]) / 2
	var bar_length = beat_length*res["time_signature"]
	starting_minigame = res["starting_minigame"]
	conductor.bpm = res["bpm"]
	
	# Getting the chart ready
	var chart = res["chart"]
	
	#Parsing the cues if it's necessary and add it to the cue_list
	for cue in chart:
		var cue_result = []
		#If it has a repeat instruction, make sure it repeats, baby.
		if cue.has("repeat") and cue.has("interval"):
			var i = 0
			var time_signature = res["time_signature"]
			for _j in range(0,cue["repeat"]):
				var c = cue.duplicate()
				c["beat"] += fmod(i,time_signature)
				c["bar"] += floor(i/time_signature)
				cue_result += parse_cue(c)
				i += cue["interval"]
		else:
			cue_result += parse_cue(cue)
		cue_list += cue_result

	#Finally, add an index position to know the position of the cue relative to the song
	for cue in cue_list:
		var position_res = beat_length*cue["beat"]
		position_res += bar_length*cue["bar"] + conductor.get_music_length()*iterated
		cue["position"] = position_res
		
		if cue["type"] == "input":
			input_list.append(cue)
	
	#Sort the lists to be in order
	cue_list.sort_custom(self, "sort_by_position")
	input_list.sort_custom(self, "sort_by_position")
	
	
#We assume that both elements are two cues that have an index "position".
func sort_by_position(a,b):
	return a['position'] < b['position']

func parse_cue(cue):
	var res = []
	
	match cue["type"]:
		"pattern":
			#Find the corresponding pattern
			var pattern_res = null
			for pattern in pattern_list:
				if pattern["name"] == cue["name"]: pattern_res = pattern
			#Could not find pattern, we just return nothing
			if !pattern_res:
				print("ERROR: Pattern '" + cue["name"] + "' not found." )
				return []
			# We found a corresponding pattern. For each cue in that pattern, append it and pay attention
			# to the relative beat
			for c in pattern_res["cues"]:
				var cue_res = c.duplicate()
				cue_res["bar"]  += cue["bar"]
				cue_res["beat"] += cue["beat"]
				res += parse_cue(cue_res)
		_ : res.append(cue)
	
	return res


func _loop():
	iterated += 1
	update_chart_bpm(conductor.get_bpm(),120,0)
	conductor.set_bpm(120)
	parse_minigame_data(chart_path)
