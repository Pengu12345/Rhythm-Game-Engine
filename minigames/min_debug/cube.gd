extends Node2D

var conductor = null
var speed = 700
var dying = false

var label = 0.0

func _process(delta):
	if !conductor: return
	
	if !dying: position.y += speed * delta * (conductor.get_bpm()/120.0)
	if position.y > 1500: queue_free()
	
func die():
	dying = true
	$animator.play("pass")


func _on_animator_animation_finished(anim_name):
	if anim_name == "pass": queue_free()
