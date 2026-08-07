class_name EnemyStats
extends Resource

@export var enemy_id: String = ""
@export var display_name: String = ""
@export var max_hp: int = 1
@export var hp: int = 1
@export var attack: int = 1
@export var defense: int = 0
@export var acts: Array[Dictionary] = []
@export var spare_after_acts: int = 0
@export var intro_line: String = ""
@export var attack_lines: Array[String] = []
@export var patterns: Array[Dictionary] = []

func is_dead() -> bool:
	return hp <= 0

func act_labels() -> Array[String]:
	var out: Array[String] = []
	for act in acts:
		out.append(str(act.get("label", "?")))
	return out

func act_by_label(label: String) -> Dictionary:
	for act in acts:
		if str(act.get("label", "")) == label:
			return act
	return {}
