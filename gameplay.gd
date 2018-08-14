extends ColorRect

enum PipeType {
	Horizontal,
	Vertical,
	LeftBottom,
	RightBottom,
	TopLeft,
	TopRight,
}

const TIME = 120
const PIPE_COUNT = 6 # number of pipe types
const GRID_MAX = [7, 6]
const FILL_START = [0, 0]
var cursor = Vector2(0, 0)
var stopped = false
var fill_state

func _ready():
	reset()
	arrange_pipes()
	$tm_blink.start()
	$time.connect("finished", self, "on_time_finished")
	$time.start()
	$anim.play("fade_out")

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			on_key_pressed(event.scancode)
		else:
			on_key_released(event.scancode)

func arrange_pipes():
	randomize()
	for pipe in $pipes.get_children():
		var type = randi() % PIPE_COUNT
		pipe.set_type(type)

func get_pipe_at(vec):
	var v = vec*8
	for pipe in $pipes.get_children():
		if pipe.position == v:
			return pipe
	
	return null

func get_pipe_at_cursor():
	return get_pipe_at(cursor)

func fill():
	stop_everything()
	$start/fill.show()
	$tm_fill.start()

func unfill():
	for pipe in $pipes.get_children():
		pipe.unfill()

	$start/fill.hide()
	$end/fill.hide()
	
func flip_pipe():
	var pipe = get_pipe_at_cursor()
	assert pipe != null
	pipe.flip()

func on_key_pressed(key):
	if stopped: return
	
	if key == KEY_R:
		do_reset()
	elif key == KEY_C:
		$time.time = 5
	elif key == KEY_SPACE:
		flip_pipe()
	elif key == KEY_F:
		fill()
	elif key == KEY_RIGHT and cursor[0] < GRID_MAX[0]:
		if cursor.y == 6 and cursor.x+1 == 7:
			return
		cursor.x += 1
		update_cursor()
	elif key == KEY_LEFT and cursor[0] > 0:
		cursor.x -= 1
		update_cursor()
	elif key == KEY_UP and cursor[1] > 0:
		cursor.y -= 1
		update_cursor()
	elif key == KEY_DOWN and cursor[1] < GRID_MAX[1]:
		if cursor.x == 7 and cursor.y+1 == 6:
			return
		cursor.y += 1
		update_cursor()

func on_key_released(key):
	pass

func on_time_finished():
	fill()

func reset():
	$endround.hide()
	unfill()
	$time.pause()
	$time.time = TIME
	$cursor.self_modulate.b8 = 255
	cursor.x = 0
	cursor.y = 0
	update_cursor()
	$cursor.show()
	$tm_blink.start()
	arrange_pipes()
	$time.start()
	stopped = false
	fill_state = {
		"passable": true,
		"goal": false,
		"cursor": Vector2(0, -1),
		"flow_dir": 3, # 0 Right, 1 Top, 2 Left, 3 Bottom
	}

func do_reset():
	stop_everything()
	$anim.play("fade_in")

func fade_func():
	reset()
	$anim.play("fade_out")

func stop_everything():
	stopped = true
	$tm_blink.stop()
	#$cursor.hide()

func update_cursor():
	var vec = cursor*8
	$cursor.position = $pipes.position+vec

func _on_tm_blink_timeout():
	$cursor.visible = not $cursor.visible

func _on_tm_fill_timeout():
	print("PIPE FILL ITER\n")
	
	if not fill_state["goal"] and not fill_state["passable"]:
		$tm_fill.stop()
		$anim.play("ohno")
		print("LOSE!\n\n")
		return
	elif fill_state["goal"]:
		$tm_fill.stop()
		$anim.play("clear")
		print("WIN!\n\n")
		return
	
	var cur = fill_state["cursor"]
	print("Cursor: ", cur)
	print("Flow dir: ", fill_state["flow_dir"])
	print("----------------")
	
	if fill_state["flow_dir"] == 3:
		# Bottom
		var pipe = get_pipe_at(cur+Vector2(0, 1))
		if pipe == null:
			fill_state["passable"] = false
			return
		print("Pipe Pos/Type: ", pipe.position, "/", pipe.type)
			
		match pipe.type:
			Vertical, TopLeft, TopRight:
				fill_state["cursor"].y += 1
				if pipe.type == TopLeft: fill_state["flow_dir"] = 2
				elif pipe.type == TopRight: fill_state["flow_dir"] = 0
				pipe.fill()
			_:
				fill_state["passable"] = false
	
	elif fill_state["flow_dir"] == 2:
		# Left
		var pipe = get_pipe_at(cur+Vector2(-1, 0))
		if pipe == null:
			fill_state["passable"] = false
			return
			
		match pipe.type:
			Horizontal, RightBottom, TopRight:
				fill_state["cursor"].x -= 1
				if pipe.type == RightBottom: fill_state["flow_dir"] = 3
				elif pipe.type == TopRight: fill_state["flow_dir"] = 1
				pipe.fill()
			_:
				fill_state["passable"] = false

	elif fill_state["flow_dir"] == 1:
		# Top
		var pipe = get_pipe_at(cur+Vector2(0, -1))
		if pipe == null:
			fill_state["passable"] = false
			return
		
		match pipe.type:
			Vertical, LeftBottom, RightBottom:
				fill_state["cursor"].y -= 1
				if pipe.type == LeftBottom: fill_state["flow_dir"] = 2
				elif pipe.type == RightBottom: fill_state["flow_dir"] = 0
				pipe.fill()
			_:
				fill_state["passable"] = false
	
	elif fill_state["flow_dir"] == 0:
		# Right
		var pipe = get_pipe_at(cur+Vector2(1, 0))
		if pipe == null:
			if cur.x == 6 and cur.y == 6:
				fill_state["goal"] = true
				$end/fill.show()
			else:
				fill_state["passable"] = false

			return
		
		match pipe.type:
			Horizontal, LeftBottom, TopLeft:
				fill_state["cursor"].x += 1
				if pipe.type == LeftBottom: fill_state["flow_dir"] = 3
				elif pipe.type == TopLeft: fill_state["flow_dir"] = 1
				pipe.fill()
			_:
				fill_state["passable"] = false
	
	print("Cursor: ", fill_state["cursor"])
	print("Flow dir: ", fill_state["flow_dir"])
	print("========================")
