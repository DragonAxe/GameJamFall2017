extends Label

onready var fps_label = get_node('.')

func _ready():
	set_process(true)

func _process(delta):
	fps_label.set_text("FPS: " + str(Engine.get_frames_per_second()))
