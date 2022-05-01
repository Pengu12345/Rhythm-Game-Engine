extends "res://scripts/minigame.gd"

var oldman_arm

var has_caught = false

# Called when the node enters the scene tree for the first time.
func _on_ready(): 
	oldman_arm = $oldman/arm
	
func _on_process(delta): pass

func play_event(event):
	match event["name"]:
		_:pass
	
func play_sfx(name):
	match name :
		_:pass

func on_good_input(input):
	pass

func on_missed_input(input):
	pass

func on_barely_input(input):
	pass

func on_blank_input(action_id):
	$oldman/arm_animator.stop(true)
	$oldman/arm_animator.play("catch_full")

func _on_new_beat(beat):
	$oldman/animator.stop(true)
	$oldman/animator.play("bop")

func _on_new_bar(bar):
	pass


func _on_arm_animator_animation_finished(anim_name):
	if(anim_name != "RESET"):
		$oldman/arm_animator.stop(true)
		$oldman/arm_animator.play("RESET")
