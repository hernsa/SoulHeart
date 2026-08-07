class_name FightBar

var marker := 0.0
var speed := 1.0
var _dir := 1.0

func tick(delta: float) -> void:
	marker += _dir * speed * delta
	if marker >= 1.0:
		marker = 1.0
		_dir = -1.0
	elif marker <= 0.0:
		marker = 0.0
		_dir = 1.0

func press() -> float:
	return 1.0 - absf(marker - 0.5) * 2.0
