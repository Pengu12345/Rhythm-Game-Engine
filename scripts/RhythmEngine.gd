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

export var transition_time = 0.05

export var input_margin = 0.1
export var input_barely_margin = 0.1
export var input_offset = 0.0

var starting_minigame
var current_minigame

var faded_out = false

var max_mistakes_superb = 3
var max_mistakes_ok = 8
var nb_mistakes = 0
var final_rating = 2 # 0 -> Try again; 1 -> OK; 2 -> Superb

func _ready():
	conductor = $Conductor
	chart_path = GameManager.loaded_chart
	
	# Treshold to avoid paradoxes
	if max_mistakes_superb > max_mistakes_ok:
		max_mistakes_superb = max_mistakes_ok
	
	play()

func play():
	if !parse_minigame_data(chart_path):
		return false
		
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
						"set_volume": conductor.set_volume(cue["value"])
						"fade_in":
							if faded_out:
								$BlackScreen/fader.play("fade_in",-1)
								faded_out = false
						"fade_out":
							if !faded_out:
								$BlackScreen/fader.play("fade_out",-1)
								faded_out = true
						"load_minigame": load_minigame(cue["value"])
						"end_chart":
							conductor.song_started = false
							_on_Conductor_end_song()
						_:current_minigame.play_event(cue)
				
			cue_list.remove(0)
	
	#Inputs in general
	if input_list.size() != 0:
		var input = input_list[0]
		var input_pos = input["position"]
		var pos = conductor.get_raw_song_position() - input_offset - input_margin - input_barely_margin
		if pos > input_pos:
			current_minigame.manage_input("missed", input)
			input_list.remove(0)
	
	 #Check input
	if Input.is_action_just_pressed("control_action"):
		if input_list.size() == 0: # If there's no inputs
			# 0 is the action id (relevant if the minigame has multiple inputs
			current_minigame.manage_input("blank",0)
			return
		var input = input_list[0]
		# Launch the event function.
		on_input(input,0)
	
	current_minigame._on_process(delta)

#-----------------#
# INPUT FUNCTIONS #
#-----------------#
func on_input(input,action_id):
	var input_pos = input["position"]
	
	# Get the input rating relative to the cue's position and the song position
	var input_rating = get_input_rating(input_pos)
	
	# 0 --> Blank; 1 --> Barely; 2 --> Ok
	if input_rating != 0:
		if input_rating == 1: current_minigame.manage_input("barely",input)
		if input_rating == 2: current_minigame.manage_input("good", input)
		input_list.remove(0)
	else:
		current_minigame.manage_input("blank",action_id)

#Returns the rating of the input. 0 --> Blank; 1 --> Barely; 2 --> Ok
func get_input_rating(hit_position):
	var timing = get_input_timing(hit_position)
	if !is_input_timing_right(timing):
		return 0 # Blank. Can be considered a fail in some minigames
	else:
		if is_input_barely(timing):
			return 1 # Barely
		else:
			return 2 # Ok

#Returns in milliseconds the timing of the hit position relative to the song position
func get_input_timing(hit_position):
	var song_pos = conductor.get_raw_song_position() - input_offset
	var timing = hit_position - song_pos
	print(str(timing) + " -- " + str(input_margin+input_barely_margin))
	return timing

#Checks if the timing enters within the input margins of the conductor (ok + barely)
func is_input_timing_right(timing):
	return timing < input_margin + input_barely_margin and timing > -input_margin - input_barely_margin

func is_input_barely(timing):
	#We first see if our input is correct (ok margin + barely margin)
	var is_input_right = is_input_timing_right(timing)
	#If it's not an ok margin, then it MUST be a barely margin
	return is_input_right and (timing > input_margin or timing < -input_margin)

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
	
	current_minigame.connect("miss", self, "_on_miss")
	current_minigame.connect("auto_ok", self, "_on_auto_ok")
	current_minigame.connect("auto_fail", self, "_on_auto_fail")
	
	yield(get_tree().create_timer(transition_time), "timeout") # Papercrafted
	$Display.add_child(current_minigame)


#########################
# PARSING MINIGAME DATA #
#########################

func parse_minigame_data(path):
	var res = ResManager.parse_JSON(path)
	
	if typeof(res) != TYPE_DICTIONARY:
		throw_error("Error loading the JSON file. There is probably a typo somewhere.\n" + str(res))
		return false
	
	#-----------------------------------#
	# GETTING ALL THE DATA OF THE CHART #
	#-----------------------------------#
	
	var needed_properties = [
		"name",
		"loaded_patterns",
		"minigames",
		"starting_minigame",
		"music_path",
		"bpm",
		"time_signature",
		"loop",
		"input_margin",
		"input_barely_margin",
		"chart"
		]
	
	var potential_missed = []
	for p in needed_properties:
		if !res.has(p):
			potential_missed.append(str(p + " "))
	
	if potential_missed.size() != 0:
		throw_error("Missing properties in chart: " + str(potential_missed))
		return false
	
	#Loading all of the patterns
	for pattern_name in res["loaded_patterns"]:
		pattern_list += ResManager.load_patterns(pattern_name)
	
	#Loading all of the minigame scenes
	for name in res["minigames"]:
		minigame_list[name] = ResManager.get_scene_by_name(name)
	
	#Loading the music
	conductor.music = load(res["music_path"])
	if !conductor.music:
		throw_error("Couldn't load the music at the specified path " + res["music_path"])
		return false
	conductor.update_music_properties()
	
	#Get general informations about the song
	var beat_length = (120.0 / res["bpm"]) / 2
	var bar_length = beat_length*res["time_signature"]
	starting_minigame = res["starting_minigame"]
	conductor.bpm = res["bpm"]
	conductor.loop = res["loop"]
	
	input_margin = res["input_margin"]
	input_barely_margin = res["input_barely_margin"]
	
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
	
	return true

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

func throw_error(error_message):
	GameManager.load_previous_scene(error_message)

#-------------------------#
# END OF SONGS AND RATING #
#-------------------------#

# final_rating ==>  0 -> Try again; 1 -> OK; 2 -> Superb
func _on_miss(weight = 1):
	nb_mistakes += weight
	if(nb_mistakes >= max_mistakes_superb and final_rating == 2): final_rating = 1
	if(nb_mistakes >= max_mistakes_ok and final_rating == 1): final_rating = 0

func _on_auto_ok():
	final_rating = 1

func _on_auto_fail():
	final_rating = 0

func _loop():
	iterated += 1
	update_chart_bpm(conductor.get_bpm(),120,0)
	conductor.set_bpm(120)
	parse_minigame_data(chart_path)

func _on_Conductor_end_song():
	var animator = $BlackScreen/fader
	yield(get_tree().create_timer(2.0), "timeout")
	if !faded_out:
		animator.play("fade_out",-1,1.5)
		yield(animator, "animation_finished")
	
	print(nb_mistakes)
	print(final_rating)
	GameManager.loaded_rating = final_rating
	GameManager.load_rating_screen()
