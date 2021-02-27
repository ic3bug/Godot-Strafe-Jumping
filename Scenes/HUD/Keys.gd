extends Control

func _physics_process(delta):
	$Space.modulate.a = lerp($Space.modulate.a, float(Input.is_action_pressed("jump")), delta * 25.0)
	$ArrowUp.modulate.a = lerp($ArrowUp.modulate.a, float(Input.is_action_pressed("forward")), delta * 25.0)
	$ArrowDown.modulate.a = lerp($ArrowDown.modulate.a, float(Input.is_action_pressed("backward")), delta * 25.0)
	$ArrowLeft.modulate.a = lerp($ArrowLeft.modulate.a, float(Input.is_action_pressed("left")), delta * 25.0)
	$ArrowRight.modulate.a = lerp($ArrowRight.modulate.a, float(Input.is_action_pressed("right")), delta * 25.0)
