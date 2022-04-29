extends "res://scripts/minigame.gd"

var cube_spwn = preload("res://minigames/min_debug/cube.tscn")

var cubes = []

var flag_pulse = false
var flag_dancers = false

# Called when the node enters the scene tree for the first time.
func _on_ready(): pass
func _on_process(delta): pass

func play_event(event):
	match event["name"]:
		"spawn_cube":
			var inst = cube_spwn.instance()
			inst.conductor = conductor
			cubes.append(inst)
			$cue_spawner.add_child(inst)
		"set_pulse":
			flag_pulse = event["value"]
		"set_dancers":
			flag_dancers = event["value"]

func play_sfx(name):
	match name:
		"snd_glass": play_sound("glass", self)
		"snd_shake": play_sound("shake", self)

func on_fail():
	play_sound("fail",self)
	emit_signal("miss",0.5)

func on_good_input(input):
	play_sound("hit",self)
	if !cubes.empty():
		cubes[0].die()
		cubes.remove(0)

func on_barely_input(input):
	on_good_input(input)

func on_missed_input(input):
	on_fail()
	if !cubes.empty(): cubes.remove(0)

func on_blank_input(action_id):
	print('blank input')

func _on_new_beat(beat):
	$Dancer1/anim.stop()
	$Dancer1/anim.play("pulse")
	
	$Dancer2/anim.stop()
	$Dancer2/anim.play("pulse")
	
	if flag_pulse:
		$Background/animator.stop()
		$Background/animator.play("pulse")
	
	if flag_dancers:
		$Dancer1.flip_h = !$Dancer1.flip_h
		$Dancer2.flip_h = !$Dancer1.flip_h
	
func _on_new_bar(bar):
	if flag_dancers:
		$Dancer1.flip_v = !$Dancer1.flip_v
		$Dancer2.flip_v = !$Dancer2.flip_v
	
