extends Node2D

const MENU_GRID := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]

var _enemy: EnemyStats
var _state := BattleState.new()
var _mood := 0
var _menu: Control
var _menu_items: Array[String] = []
var _menu_index := 0
var _submenu_open := false
var _submenu_index := 0
var _submenu_context := ""
var _fight_bar := FightBar.new()
var _fight_bar_ui: Control
var _fight_marker: ColorRect
var _dodge_box: DodgeBox
var _text: DialogueUI
var _enemy_sprite: Sprite2D
var _name_label: Label
var _hp_label: Label
var _hp_bar: ColorRect
var _player_name_label: Label
var _player_hp_label: Label
var _player_hp_bar: ColorRect
var _ending := false

func _ready() -> void:
	Audio.play_music("battle")
	_build_ui()
	_enemy = EnemyLibrary.get_enemy(str(GameState.flags.get("pending_enemy", "willowisp")))
	_enemy_sprite.texture = Sprites.wisp_texture()
	_refresh_enemy_ui()
	_refresh_player_ui()
	await _say([{"speaker": "", "text": _enemy.intro_line}])
	if _ending:
		return
	_enter_player_turn()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.size = Vector2(640, 480)
	add_child(bg)
	_enemy_sprite = Sprite2D.new()
	_enemy_sprite.position = Vector2(480, 220)
	add_child(_enemy_sprite)
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 20)
	_name_label.position = Vector2(30, 30)
	add_child(_name_label)
	_hp_label = Label.new()
	_hp_label.add_theme_font_size_override("font_size", 14)
	_hp_label.position = Vector2(30, 60)
	add_child(_hp_label)
	_hp_bar = ColorRect.new()
	_hp_bar.position = Vector2(30, 82)
	_hp_bar.size = Vector2(120, 8)
	_hp_bar.color = Color.YELLOW
	add_child(_hp_bar)
	_player_name_label = Label.new()
	_player_name_label.text = "DREAMCATCHER"
	_player_name_label.add_theme_font_size_override("font_size", 20)
	_player_name_label.position = Vector2(30, 300)
	add_child(_player_name_label)
	_player_hp_bar = ColorRect.new()
	_player_hp_bar.position = Vector2(30, 322)
	_player_hp_bar.size = Vector2(120, 8)
	_player_hp_bar.color = Color.RED
	add_child(_player_hp_bar)
	_player_hp_label = Label.new()
	_player_hp_label.add_theme_font_size_override("font_size", 14)
	_player_hp_label.position = Vector2(30, 336)
	add_child(_player_hp_label)
	_build_menu()
	_build_fight_bar()
	_dodge_box = DodgeBox.new()
	add_child(_dodge_box)
	_dodge_box.set_active(false)
	_dodge_box.player_hit.connect(_on_player_hit)
	_text = load("res://scripts/dialogue/dialogue_ui.gd").new()
	add_child(_text)

func _build_menu() -> void:
	_menu = Control.new()
	_menu_items = ["FIGHT", "ACT", "ITEM", "MERCY"]
	_render_menu_labels()
	add_child(_menu)
	_menu.visible = false
	_update_menu_colors()

func _render_menu_labels() -> void:
	for child in _menu.get_children():
		child.queue_free()
	for i in _menu_items.size():
		var l := Label.new()
		l.text = _menu_items[i]
		l.add_theme_font_size_override("font_size", 18)
		l.position = Vector2(240 + MENU_GRID[i].x * 110, 400 + MENU_GRID[i].y * 30)
		l.name = "item_%d" % i
		_menu.add_child(l)

func _update_menu_colors() -> void:
	var idx := _submenu_index if _submenu_open else _menu_index
	for i in _menu_items.size():
		var l := _menu.get_node("item_%d" % i) as Label
		if l == null:
			continue
		l.add_theme_color_override("font_color", Color.WHITE if i == idx else Color(1, 1, 1, 0.5))

func _build_fight_bar() -> void:
	_fight_bar_ui = Control.new()
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.85)
	sb.set_border_width_all(1)
	sb.border_color = Color.WHITE
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(220, 210)
	panel.size = Vector2(200, 28)
	_fight_bar_ui.add_child(panel)
	_fight_marker = ColorRect.new()
	_fight_marker.color = Color.WHITE
	_fight_marker.size = Vector2(2, 28)
	_fight_bar_ui.add_child(_fight_marker)
	add_child(_fight_bar_ui)
	_fight_bar_ui.visible = false

func _process(delta: float) -> void:
	if _ending:
		return
	match _state.phase:
		BattleState.Phase.PLAYER_TURN:
			if _submenu_open:
				_handle_submenu_input()
			else:
				_handle_menu_input()
		BattleState.Phase.FIGHT:
			_fight_bar.tick(delta)
			_fight_marker.position = Vector2(222 + _fight_bar.marker * 196.0, 210)
			if Input.is_action_just_pressed("confirm"):
				_resolve_fight()

func _handle_menu_input() -> void:
	var prev := _menu_index
	if Input.is_action_just_pressed("move_up"):
		_menu_index = _move_in_grid(prev, Vector2i(0, -1))
	elif Input.is_action_just_pressed("move_down"):
		_menu_index = _move_in_grid(prev, Vector2i(0, 1))
	elif Input.is_action_just_pressed("move_left"):
		_menu_index = _move_in_grid(prev, Vector2i(-1, 0))
	elif Input.is_action_just_pressed("move_right"):
		_menu_index = _move_in_grid(prev, Vector2i(1, 0))
	if _menu_index != prev:
		_update_menu_colors()
	if Input.is_action_just_pressed("confirm"):
		_choose()

func _move_in_grid(current: int, delta_grid: Vector2i) -> int:
	var pos: Vector2i = MENU_GRID[current] + delta_grid
	for i in 4:
		if MENU_GRID[i] == pos:
			return i
	pos.x = wrapi(pos.x, 0, 2)
	for i in 4:
		if MENU_GRID[i] == pos:
			return i
	return current

func _choose() -> void:
	match _menu_items[_menu_index]:
		"FIGHT":
			_state.transition(BattleState.Phase.FIGHT)
			_menu.visible = false
			_fight_bar = FightBar.new()
			_fight_bar_ui.visible = true
		"ACT":
			_open_submenu(_enemy.act_labels(), "ACT")
		"ITEM":
			_open_submenu(_item_labels(), "ITEM")
		"MERCY":
			_open_submenu(["Spare", "Flee"], "MERCY")

func _item_labels() -> Array[String]:
	var out: Array[String] = []
	for item in GameState.inventory:
		out.append(str(item.get("name", "?")))
	if out.is_empty():
		out.append("(empty)")
	return out

func _open_submenu(items: Array[String], context: String) -> void:
	_submenu_context = context
	_submenu_open = true
	_submenu_index = 0
	_menu_items = items
	_render_menu_labels()
	_menu.visible = true
	_update_menu_colors()

func _handle_submenu_input() -> void:
	if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_left"):
		_submenu_index = clampi(_submenu_index - 1, 0, _menu_items.size() - 1)
		_update_menu_colors()
	elif Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("move_right"):
		_submenu_index = clampi(_submenu_index + 1, 0, _menu_items.size() - 1)
		_update_menu_colors()
	elif Input.is_action_just_pressed("confirm"):
		_submenu_open = false
		_menu.visible = false
		_resolve_submenu()
	elif Input.is_action_just_pressed("cancel"):
		_submenu_open = false
		_menu.visible = false
		_enter_player_turn()

func _resolve_submenu() -> void:
	_state.transition(BattleState.Phase.ENEMY_TURN)
	var choice: String = _menu_items[_submenu_index]
	match _submenu_context:
		"ACT":
			var act: Dictionary = _enemy.act_by_label(choice)
			_mood += int(act.get("mood", 0))
			await _say([{"speaker": "", "text": str(act.get("text", "You try something."))}])
		"ITEM":
			if choice == "(empty)":
				await _say([{"speaker": "", "text": "Your pockets are empty."}])
			else:
				var item: Dictionary = GameState.use_item(_submenu_index)
				await _say([{"speaker": "", "text": "You used %s. It hums warmly." % item.get("name", "it")}])
				_refresh_player_ui()
		"MERCY":
			if choice == "Spare":
				if _mood >= _enemy.spare_after_acts:
					_state.transition(BattleState.Phase.SPARED)
					GameState.add_spare()
					await _say([{"speaker": "", "text": "You spare %s. It settles, grateful." % _enemy.display_name}])
					_end_battle()
					return
				else:
					await _say([{"speaker": "", "text": "%s wavers, but stays on guard." % _enemy.display_name}])
			else:
				await _say([{"speaker": "", "text": "You flee, heart pounding."}])
				_end_battle()
				return
	_refresh_enemy_ui()
	_enemy_turn()

func _resolve_fight() -> void:
	_state.transition(BattleState.Phase.ENEMY_TURN)
	_fight_bar_ui.visible = false
	var intent := _fight_bar.press()
	if intent < 0.1:
		await _say([{"speaker": "", "text": "MISS."}])
	else:
		var dmg := CombatMath.calculate_damage(int(GameState.player_stats["atk"]), _enemy.defense, intent)
		_enemy.hp -= dmg
		_refresh_enemy_ui()
		await _say([{"speaker": "", "text": "You strike. %s takes %d damage." % [_enemy.display_name, dmg]}])
	if _enemy.is_dead():
		_state.transition(BattleState.Phase.WIN)
		GameState.add_kill()
		GameState.player_stats["gold"] = int(GameState.player_stats["gold"]) + 2
		await _say([{"speaker": "", "text": "%s fades into soft light. You feel colder." % _enemy.display_name}])
		_end_battle()
	else:
		_enemy_turn()

func _enemy_turn() -> void:
	var line: String = _enemy.attack_lines[randi() % _enemy.attack_lines.size()]
	await _say([{"speaker": "", "text": line}])
	_dodge_box.set_active(true)
	for pattern in _enemy.patterns:
		_dodge_box.spawn_patterns(BulletPatterns.make(pattern))
		var frames := 0
		while _dodge_box.has_bullets() and frames < 60 * 15:
			await get_tree().process_frame
			frames += 1
	_dodge_box.set_active(false)
	_refresh_player_ui()
	if int(GameState.player_stats["hp"]) <= 0:
		_state.transition(BattleState.Phase.LOSE)
		await _say([{"speaker": "", "text": "You cannot give up just yet."}])
		GameState.heal_full()
		_end_battle()
	else:
		_enter_player_turn()

func _enter_player_turn() -> void:
	_state.transition(BattleState.Phase.PLAYER_TURN)
	_menu_items = ["FIGHT", "ACT", "ITEM", "MERCY"]
	_render_menu_labels()
	_menu_index = 0
	_menu.visible = true
	_update_menu_colors()

func _refresh_enemy_ui() -> void:
	_name_label.text = _enemy.display_name
	_name_label.add_theme_color_override("font_color", Color.YELLOW if _mood >= _enemy.spare_after_acts else Color.WHITE)
	_hp_label.text = "%d/%d" % [_enemy.hp, _enemy.max_hp]
	_hp_bar.size.x = 120.0 * float(_enemy.hp) / float(_enemy.max_hp)

func _refresh_player_ui() -> void:
	var hp := int(GameState.player_stats["hp"])
	var max_hp := int(GameState.player_stats["max_hp"])
	_player_hp_label.text = "HP %d / %d" % [hp, max_hp]
	_player_hp_bar.size.x = maxi(0, int(120.0 * float(hp) / float(max_hp)))

func _on_player_hit() -> void:
	Audio.play_sfx("hurt")
	GameState.change_hp(-1)
	_refresh_player_ui()

func _say(lines: Array[Dictionary]) -> void:
	_text.open(lines)
	await _text.finished

func _end_battle() -> void:
	_ending = true
	var room: String = str(GameState.flags.get("from_room", "res://scenes/rooms/DrizzleFields.tscn"))
	get_tree().change_scene_to_file(room)
