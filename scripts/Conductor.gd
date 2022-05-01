# CLASS THAT IS USED TO KEEP TRACK OF THE SONG POSITION //ONLY.
# FOR ANYTHING CHART/INPUT RELATED, CHECK THE RHYTHMENGINE.
# ------------------------------------------------------------

extends Node2D

signal new_beat(beat)
signal new_bar(bar)

signal looping
signal end_song

export (AudioStream) var music

export var loop = false
onready var iterated = 0

export var bpm = 120.0

export var time_signature = 4

export var audio_offset = 0.0


export var music_offset = 0.0

onready var music_player = $music_player

onready var song_started = false

var music_length

var crotchet
var song_position
var raw_song_position

var previous_frame_time
var previous_song_position

var delta_position

var last_beat_position
var last_bar_position

var next_beat_position
var next_bar_position

var current_beat
var current_bar

# Setup functions
func _ready():
	update_music_properties()

func update_music_properties():
	if music:
		music_player.stream = music
		music_length = music_player.stream.get_length()
	else:
		music_length = 0
	
func start_song():
	crotchet  = (120.0/bpm) / 2.0 #I will never change it to 60.0/bpm
	
	last_beat_position = 0
	last_bar_position = 0
	
	current_beat = 0
	current_bar = 0
	
	next_beat_position = 0
	next_bar_position = 0
	
	previous_frame_time = OS.get_ticks_msec()
	previous_song_position = 0
	delta_position = 0
	song_position = 0
	raw_song_position = 0
	
	if music: music_player.play()
	song_started = true

#Process functions
func _process(_delta):
	
	if !song_started: return
	
#	delta_position = music_player.get_playback_position() - previous_song_position
#	previous_song_position = music_player.get_playback_position()
#	raw_song_position += delta_position

	delta_position += (OS.get_ticks_msec() - previous_frame_time)/1000
	raw_song_position += delta_position
	previous_frame_time = OS.get_ticks_msec()

	if get_loop_playback_position() != previous_song_position :
		raw_song_position = (raw_song_position + get_loop_playback_position())/2
		previous_song_position = get_loop_playback_position()
	
	song_position = raw_song_position - audio_offset - music_offset
	
	if song_position > next_beat_position:
		last_beat_position = next_beat_position
		next_beat_position += crotchet
		current_beat += 1
		emit_signal("new_beat", current_beat)
	if song_position > next_bar_position:
		last_bar_position = next_bar_position
		next_bar_position += crotchet*time_signature
		current_bar += 1
		emit_signal("new_bar", current_bar)

func _on_music_player_finished():
	if loop:
		print("Looping...")
		previous_song_position = previous_song_position-music_length
		iterated+=1
		emit_signal("looping")
		$music_player.play()
	else:
		song_started = false
		emit_signal("end_song")

#GETTERS
func get_raw_song_position(): return raw_song_position
func get_song_position(): return song_position
func get_beat(): return current_beat
func get_bar(): return current_bar
func get_time_signature(): return time_signature
func get_bpm(): return bpm
func get_music_length(): return music_length

func get_relative_beat(): return current_beat % time_signature

func get_loop_playback_position():
	return music_player.get_playback_position() + (music_length*iterated)

func get_beat_length():
	return crotchet
func get_bar_length():
	return crotchet*time_signature

#SETTERS
func set_bpm(new_bpm):
	var factor = new_bpm/bpm
	bpm = new_bpm
	crotchet  = (120.0/bpm) / 2.0
	next_beat_position = ((next_beat_position - last_beat_position) / factor) + last_beat_position
	next_bar_position = ((next_bar_position - last_bar_position) / factor) + last_bar_position
	
func set_time_signature(new_ts):
	time_signature = new_ts
	
func set_audio_offset(new_offset): audio_offset = new_offset

func set_volume(value):
	music_player.volume_db = value
