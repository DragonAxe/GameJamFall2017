extends Label

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	set_process(true)
	pass

func _process(delta):
	var size = get_viewport().get_visible_rect().size
	size.x -= 250;
	size.y = 20;
	set_begin(size)