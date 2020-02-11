tool
extends Control

const TEX = preload("res://textures/sheet.png")
const BASEPOS = Vector2(66, 1)
const CHARSIZE = Vector2(5, 5)
export var time = 0 # Seconds

signal finished

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	update()

func _draw():
	var digits = [
		time/600 % 10,
		time/60 % 10,
		10,
		(time % 60) / 10,
		time % 10
	]
	
	var i = 0
	
	for x in range(0, 5*CHARSIZE.x, CHARSIZE.x):
		var d_rect = Rect2(x, 0, CHARSIZE.x, CHARSIZE.y)
		var s_rect = Rect2(BASEPOS+Vector2(CHARSIZE.x*digits[i], 0), CHARSIZE)
		draw_texture_rect_region(TEX, d_rect, s_rect)
		i+=1

func start():
	$tm.start()
	update()

func pause():
	$tm.stop()

func stop():
	pause()
	emit_signal("finished")

func _on_tm_timeout():
	time -= 1
	update()
	if time == 0:
		stop()
