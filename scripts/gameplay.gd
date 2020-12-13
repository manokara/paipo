extends ColorRect

enum PipeType {
	Horizontal,
	Vertical,
	LeftDown,
	RightDown,
	UpLeft,
	UpRight,
}

enum FlowDir {
	Right,
	Up,
	Left,
	Down,
}

const TIME = 120
const PIPE_COUNT = 6 # number of pipe types
const GRID_MAX = [7, 6]
const FILL_START = [0, 0]
const snd_turn = preload("res://sounds/turn.wav")
const snd_ohno = preload("res://sounds/ohno.wav")
const snd_clear = preload("res://sounds/clear.wav")
var cursor = Vector2(0, 0)
var stopped = false
var fill_mutex = Mutex.new()
var fill_state
var grid = [
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
]

func _ready():
	init_grid()
	$fader.show()
	reset()
	setup_pipes()
	$tm_blink.start()
	$time/tm.start()
	$music.play()
	$anim.play("fade_out")

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			on_key_pressed(event.scancode)

func init_grid():
	var pipes = $pipes.get_children()

	for y in range(7):
		for x in range(8):
			if x == 7 and y == 6:
				pass # end sink
			else:
				grid[y][x] = pipes[x * 7 + y]

func setup_pipes():
	var last_type = null
	var last_type_count = 0

	# Main horizontal pass
	for y in range(7):
		for x in range(8):
			if x == 7 and y == 6:
				break

			var type = randi() % PIPE_COUNT
			var pipe = grid[y][x]
			pipe.set_type(type)

			if last_type == type:
				last_type_count += 1

				if last_type_count == 0:
					while last_type != type:
						type = randi() % PIPE_COUNT

					pipe.set_type(type)
			else:
				last_type_count = 1

			last_type = type

	last_type = null
	last_type_count = 0

	# Vertical deduplication pass
	for x in range(8):
		for y in range(7):
			if x == 7 and y == 6:
				break

			var pipe = grid[y][x]
			var type = pipe.type

			if last_type == type:
				last_type_count += 1

				if last_type_count == 0:
					while last_type != type:
						type = randi() % PIPE_COUNT

					pipe.set_type(type)
			else:
				last_type_count = 1

			last_type = type

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
	$water.play()

func unfill():
	for pipe in $pipes.get_children():
		pipe.unfill()

	$start/fill.hide()
	$end/fill.hide()

func flip_pipe():
	var pipe = get_pipe_at_cursor()
	assert(pipe != null)
	$sfx.play()
	pipe.flip()

func on_key_pressed(key):
	if stopped: return

	if key == KEY_R:
		do_reset()
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

func on_time_finished():
	fill()

func reset():
	fill_state = {
		"passable": true,
		"goal": false,
		"cursor": Vector2(0, -1),
		"flowdir": FlowDir.Down,
		"last_pipe": null,
	}

	$sfx.stream = snd_turn
	unfill()
	$endround.hide()
	$time.pause()
	$time.time = TIME
	cursor.x = 0; cursor.y = 0
	update_cursor()
	setup_pipes()
	$time.start()
	$cursor.show()
	$tm_blink.start()
	stopped = false

func do_reset():
	stop_everything()
	$anim.play("fade_in")

func fade_func():
	reset()
	$anim.play("fade_out")

func stop_everything():
	stopped = true
	$time.pause()
	$tm_blink.stop()
	$cursor.hide()

func update_cursor():
	var vec = cursor*8
	$cursor.position = $pipes.position+vec

func _on_tm_blink_timeout():
	$cursor.visible = not $cursor.visible

func _on_tm_fill_timeout():
	# As Timer calls are not synchronized, sometimes this runs before the
	# function even finishes.
	fill_mutex.lock()

	var last_pipe = fill_state.last_pipe
	var cur = fill_state.cursor
	var flowdir = fill_state.flowdir
	var passable = fill_state.passable
	var goal = fill_state.goal
	var pipe

	if last_pipe != null:
		if not last_pipe.filled:
			return

	if not goal and not passable:
		$tm_fill.stop()
		$water.stop()
		$sfx.stream = snd_ohno
		$sfx.play()
		$anim.play("ohno")
		return
	elif goal:
		$tm_fill.stop()
		$water.stop()
		$sfx.stream = snd_clear
		$sfx.play()
		$anim.play("clear")
		return

	if flowdir == FlowDir.Right:
		pipe = get_pipe_at(cur+Vector2(1, 0))

		if pipe == null:
			# Check if the fill cursor is beside the end pipe
			if cur.x == 6 and cur.y == 6:
				fill_state.goal = true
				$end/fill.show()
			else:
				fill_state.passable = false

			return

		match pipe.type:
			PipeType.Horizontal, PipeType.LeftDown, PipeType.UpLeft:
				fill_state.cursor.x += 1

				if pipe.type == PipeType.LeftDown:
					fill_state.flowdir = 3
				elif pipe.type == PipeType.UpLeft:
					fill_state.flowdir = 1

				pipe.fill(fill_state.flowdir)
			_:
				fill_state.passable = false

	elif flowdir == FlowDir.Up:
		pipe = get_pipe_at(cur+Vector2(0, -1))

		if pipe == null:
			fill_state.passable = false
			return

		match pipe.type:
			PipeType.Vertical, PipeType.LeftDown, PipeType.RightDown:
				fill_state.cursor.y -= 1

				if pipe.type == PipeType.LeftDown:
					fill_state.flowdir = 2
				elif pipe.type == PipeType.RightDown:
					fill_state.flowdir = 0

				pipe.fill(fill_state.flowdir)
			_:
				fill_state.passable = false

	elif flowdir == FlowDir.Left:
		pipe = get_pipe_at(cur+Vector2(-1, 0))

		if pipe == null:
			fill_state.passable = false
			return

		match pipe.type:
			PipeType.Horizontal, PipeType.RightDown, PipeType.UpRight:
				fill_state.cursor.x -= 1
				last_pipe.fill(flowdir)

				if pipe.type == PipeType.RightDown:
					fill_state.flowdir = 3
				elif pipe.type == PipeType.UpRight:
					fill_state.flowdir = 1

				pipe.fill(fill_state.flowdir)
			_:
				fill_state.passable = false

	elif flowdir == FlowDir.Down:
		pipe = get_pipe_at(cur+Vector2(0, 1))

		if pipe == null:
			fill_state.passable = false
			return

		match pipe.type:
			PipeType.Vertical, PipeType.UpLeft, PipeType.UpRight:
				fill_state.cursor.y += 1

				if pipe.type == PipeType.UpLeft:
					fill_state.flowdir = 2
				elif pipe.type == PipeType.UpRight:
					fill_state.flowdir = 0

				pipe.fill(fill_state.flowdir)
			_:
				fill_state.passable = false

	if fill_state.passable:
		fill_state.last_pipe = pipe

	fill_mutex.unlock()

