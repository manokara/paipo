extends Node2D

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

var RECTS = {
	# X Offset (from (8,0)), Flip (0 = no, 1 = H, 2 = V, 3 = HV), Rotate 90
	PipeType.Horizontal: [0, 0, true],
	PipeType.Vertical: [0, 0, false],
	PipeType.LeftDown: [8, 0, false],
	PipeType.RightDown: [8, 1, false],
	PipeType.UpLeft: [8, 2, false],
	PipeType.UpRight: [8, 3, false]
}

var type = null
export var anim_frame = 0
var anim_mut = Mutex.new()
var filled = false
var filling = false

func _ready():
	pass

func fill(flowdir):

	match [flowdir, self.type]:
		[_, PipeType.Horizontal], [_, PipeType.Vertical]:
			if flowdir == FlowDir.Right:
				$pipe/fill.flip_v = true
		[FlowDir.Left, _], [FlowDir.Right, _]:
			$pipe/fill.region_rect.position.y = 72

	$pipe/fill.show()
	$tm_next.start()
	$tm_end.start()

func unfill():
	$pipe/fill.hide()
	$pipe/fill.region_rect.position.x = 96
	$pipe/fill.region_rect.position.y = 56
	filled = false

func flip():
	match type:
		PipeType.Horizontal:
			set_type(PipeType.Vertical)
		PipeType.Vertical:
			set_type(PipeType.Horizontal)
		PipeType.LeftDown:
			set_type(PipeType.UpLeft)
		PipeType.UpLeft:
			set_type(PipeType.UpRight)
		PipeType.UpRight:
			set_type(PipeType.RightDown)
		PipeType.RightDown:
			set_type(PipeType.LeftDown)

func set_type(type):
	self.type = type
	update_rect()
	if not $pipe.visible:
		$placeholder.hide()
		$pipe.show()

func update_rect():
	var rect = RECTS[type]
	$pipe.region_rect.position.x = 8+rect[0]
	$pipe/fill.region_rect.position.y = 56+rect[0]
	$pipe.flip_h = rect[1] & 1
	$pipe.flip_v = rect[1] & 2
	$pipe/fill.flip_h = $pipe.flip_h
	$pipe/fill.flip_v = $pipe.flip_v

	if rect[2]:
		$pipe.rotation_degrees = 90
	else:
		$pipe.rotation_degrees = 0

func _on_tm_next_timeout():
	var x = $pipe/fill.region_rect.position.x
	x = min(x+8, 120)
	$pipe/fill.region_rect.position.x = x

func _on_tm_end_timeout():
	$tm_next.stop()
	filled = true

