extends ColorRect

const MAX_TICK = 6
var press_tick = 0
var pressed = true

func _input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_ENTER and not pressed:
			pressed = true
			$press.visible = false
			$timer.start()

func enable_press():
	pressed = false

func _on_anim_animation_finished(anim_name):
	if anim_name == "start":
		$anim.play("waterstream")

func _on_timer_timeout():
	press_tick += 1
	$press.visible = !$press.visible
	if press_tick == MAX_TICK:
		get_tree().change_scene("res://gameplay.tscn")

