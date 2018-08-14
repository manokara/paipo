extends Node2D

enum PipeType {
	Horizontal,
	Vertical,
	LeftBottom,
	RightBottom,
	TopLeft,
	TopRight,
}

const RECTS = {
	# X Offset (from (8,0)), Flip (0 = no, 1 = H, 2 = V, 3 = HV), Rotate 90
	Horizontal: [0, 0, true],
	Vertical: [0, 0, false],
	LeftBottom: [8, 0, false],
	RightBottom: [8, 1, false],
	TopLeft: [8, 2, false],
	TopRight: [8, 3, false]
}

var type = null

func _ready():
	pass

func fill():
	$fill.show()

func unfill():
	$fill.hide()

func flip():
	match type:
		Horizontal:
			set_type(Vertical)
		Vertical:
			set_type(Horizontal)
		LeftBottom:
			set_type(TopLeft)
		TopLeft:
			set_type(TopRight)
		TopRight:
			set_type(RightBottom)
		RightBottom:
			set_type(LeftBottom)

func set_type(type):
	self.type = type
	update_rect()
	if not $pipe.visible: 
		$placeholder.hide()
		$pipe.show()

func update_rect():
	var rect = RECTS[type]
	$pipe.region_rect.position.x = 8+rect[0]
	$fill.region_rect.position.x = 8+rect[0]
	$pipe.flip_h = rect[1] & 1
	$pipe.flip_v = rect[1] & 2
	$fill.flip_h = $pipe.flip_h
	$fill.flip_v = $pipe.flip_v
	if rect[2]:
		$pipe.rotation_degrees = 90
		$fill.rotation_degrees = 90
	else:
		$pipe.rotation_degrees = 0
		$fill.rotation_degrees = 0
