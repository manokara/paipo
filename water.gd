extends AudioStreamPlayer

const BEGIN = 1.762
const END = 2.107

func _ready():
	stream.loop_begin = BEGIN*stream.mix_rate
	stream.loop_end = END*stream.mix_rate

