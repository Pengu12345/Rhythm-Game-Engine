extends "res://scripts/minigame.gd"

var cats

onready var jumping = false

# Called when the node enters the scene tree for the first time.
func _on_ready(): 
	$focus.visible = false
	cats = [$cats/cat1, $cats/cat2, $cats/cat3]
	
	for cat in cats: cat.play("default")
	
func _on_process(delta): pass

func play_event(event):
	match event["name"]:
		"knit":
			jumping = false
			cats[0].play("knit")
			cats[1].play("knit")
			
			cats[0].frame = 0
			cats[1].frame = 0
		
		"jump1":
			$cats/cat1/jump.play("RESET")
			$cats/cat1/jump.play("jump")
			cats[0].play("show")
			jumping = true
		
		"jump2":
			$cats/cat2/jump.play("RESET")
			$cats/cat2/jump.play("jump")
			cats[1].play("show")
			jumping = true
		"set_focus":
			$focus.visible = event["value"]
	
func play_sfx(name):
	match name :
		"snd_knit": play_sound("knit",self)
		"snd_jump": play_sound("jump",self)
		"snd_cowbell": play_sound("cowbell",self,-3,2)

func on_good_input(input):
	if !jumping:
		cats[2].play("knit")
		cats[2].frame = 0
		play_sound("knit",self,-10,0.8)
	else:
		$cats/cat3/jump.play("RESET")
		$cats/cat3/jump.play("jump")
		cats[2].play("show")
		cats[2].frame = 0
		play_sound("jump",self,1,1.1)
		jumping = false

func on_missed_input(input):
	if jumping:
		cats[0].play("angry")
		cats[0].frame = 0
		
		cats[1].play("angry")
		cats[1].frame = 0

func on_blank_input():
	if !jumping:
		cats[2].play("knit_fail")
		cats[2].frame = 0
		play_sound("knit",self,-10,2)
	else:
		cats[0].play("angry")
		cats[0].frame = 0
		
		cats[1].play("angry")
		cats[1].frame = 0
		
		$cats/cat3/jump.play("RESET")
		$cats/cat3/jump.play("jump")
		cats[2].play("show_fail")
		cats[2].frame = 0
		
		play_sound("jump_fail",self,-5)
		play_sound("jump",self,1,0.9)

func _on_new_beat(beat):
	pass

func _on_new_bar(bar):
	pass
