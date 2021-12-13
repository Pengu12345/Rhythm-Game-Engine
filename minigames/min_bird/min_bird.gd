extends "res://scripts/minigame.gd"


func _on_ready(): pass
func _on_process(delta):pass

func play_event(event):pass

func play_sfx(sfx_name):
	match sfx_name:
		"snd_tongue": play_sound("snd_tongue",self)

func on_missed_input(input):pass

func on_blank_input():pass

func on_good_input(input):pass

func _on_new_beat(beat):
	$Sus.flip_h = !$Sus.flip_h

func _on_new_bar(bar): pass
