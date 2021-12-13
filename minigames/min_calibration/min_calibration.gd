extends Node2D

onready var conductor = $conductor

var next_beats = []

var beat_hit = 0
var total = 0.0
var average = 0.0


var mute = false
var mute2 = false
# Called when the node enters the scene tree for the first time.
func _ready():
	yield(get_tree().create_timer(1.0), "timeout")
	conductor.start_song()
	$animation/Control/a_offset.value = conductor.audio_offset
	$animation/Control/a_offset/txt.text = "Audio offset: " + str(conductor.audio_offset * 1000) + " ms"
	
	next_beats.append(conductor.next_beat_position)

func _process(delta):
	if !conductor.song_started : return
	if next_beats.size() <= 1: return
	
	if Input.is_action_just_pressed("control_action"):
		var song_pos = conductor.get_raw_song_position()
		var pos_1 = next_beats[0]
		var pos_2 = next_beats[1]
		#Get the beat closest to the hit position
		var res = min( song_pos-pos_1, pos_2-song_pos )
		if res == pos_2 - song_pos: res *=-1
		beat_hit +=1
		total += res * 1000
		average = total / beat_hit
		$animation/Control/i_offset/txt.text = str(res*1000) + " ms - Average = " + str(average) + " ms"
		if !mute2 : $sounds/snd_cowbell_2.play()
		
		var anim = $animation2/AnimationPlayer

		if conductor.is_input_timing_right(res):
			anim.stop(true)
			anim.play("pulse_yes")
		else:
			anim.stop(true)
			anim.play("pulse_no")

func _on_conductor_new_beat(beat):
	$animation/animator.stop()
	$animation/animator.play("pulse")
	if !mute: $sounds/snd_cowbell_1.play()

	next_beats.append(conductor.next_beat_position)
	if next_beats.size() >= 3:
		next_beats.remove(0)

func _on_conductor_new_bar(bar):
	pass


func _on_a_offset_value_changed(value):
	conductor.set_audio_offset(value)
	$animation/Control/a_offset/txt.text = "Audio offset: " + str(value*1000) + " ms "


func _on_double_toggled(button_pressed):
	if button_pressed:
		conductor.set_bpm(240)
	else:
		conductor.set_bpm(120)


func _on_reset_pressed():
	average = 0.0
	beat_hit = 0
	total = 0
	$animation/Control/i_offset/txt.text = "0 ms - Average = 0 ms"


func _on_mute_toggled(button_pressed):
	mute = button_pressed


func _on_mute2_toggled(button_pressed):
	mute2 = button_pressed
