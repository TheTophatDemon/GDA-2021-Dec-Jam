extends Particles2D

export(float) var life_timer = 0.5
var timer = 0.0

func _ready():
	emitting = true

func _process(delta):
	timer += delta
	if timer > life_timer:
		queue_free()
