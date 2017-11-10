extends Spatial

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var speed = (randi() % 2 + 8) * 0.1

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_physics_process(true)

func _physics_process(delta):
	rotate_y(speed*delta)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
