extends Node

var captured = true

func _ready():
	set_process_input(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if (event.is_action_pressed("releace_cursor")):
		if captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			captured = false
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			captured = true
