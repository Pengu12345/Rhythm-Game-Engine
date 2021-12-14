extends "res://scripts/minigame.gd"


func _on_ready(): pass
func _on_process(delta):pass

func play_event(event):pass

func play_sfx(sfx_name):
	match sfx_name:
		"snd_chirp": play_sound(sfx_name, self,-5, rand_range(0.8,1.1))

func on_missed_input(input):pass

func on_blank_input():
	play_sound("snd_hit", self,-10)

func on_good_input(input):pass

func _on_new_beat(beat):
	pass

func _on_new_bar(bar): pass
