class_name Battle
extends Node2D

const MENU_GRID := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
const FLEE_CHANCE := 0.5
const SUBMENU_BOXES := {
	"ACT": Rect2(250, 385, 152, 44),
	"ITEM": Rect2(250, 385, 292, 80),
	"MERCY": Rect2(250, 385, 152, 80),
}

var max_hp := 20
var hp := 20
var lv := 1

var _enemy: Dictionary
var _enemy_max_hp := 0
var _state := BattleState.new()
var _mood := 0
var _menu: Control
var _menu_items: Array[String] = []
var _menu_index := 0
var _submenu_open := false
var _submenu_index := 0
var _submenu_context := ""
var _submenu_items: Array[String] = []
var _fight_bar := FightBar.new()
var _fight_bar_ui: Control
var _fight_marker: ColorRect
var _dodge_box: DodgeBox
var _text: DialogueUI
var _enemy_sprite: Sprite2D
var _name_label: Label
var _hp_label: Label
var _hp_bar: ColorRect
var _hp_bar_bg: ColorRect
var _hp_bar_w := 16.0
var _player_name_label: Label
var _player_hp_label: Label
var _player_hp_bar: ColorRect
var _player_hp_fill: ColorRect
var _menu_box: Panel
var _menu_cursor: Sprite2D
var _enemy_hp_display := 0.0
var _enemy_in := false
var _ending := false
var _forms: Array = []
var _form_index := 0
var _monologue_shown: Array = []
var _form_label: Label
var _turn_count := 0

func _ready() -> void:
	Audio.play_music("battle")
	_build_ui()
	_enemy = EnemyLibrary.get_enemy(str(GameState.flags.get("pending_enemy", "froggit")))
	_forms = _enemy.get("forms", [])
	_update_form_label()
	_spawn_enemy_sprite()
	_enemy_sprite.position = Vector2(216, -40)
	if bool(_enemy.get("boss", false)):
		await _show_boss_intro()
	_enemy_max_hp = int(_enemy["hp"])
	_enemy_hp_display = float(_enemy_max_hp)
	var bar_w := clampf(_enemy_sprite.texture.get_width() * 0.8, 16.0, 60.0)
	_hp_bar_w = bar_w
	_hp_bar.size.x = bar_w
	_hp_bar_bg.size.x = bar_w + 2.0
	var entrance := create_tween()
	entrance.tween_property(_enemy_sprite, "position", Vector2(216, 136), 0.4)
	await entrance.finished
	_enemy_in = true
	_refresh_enemy_ui()
	_refresh_player_ui()
	await _say([{"speaker": "", "text": _enemy["intro_line"]}])
	if _ending:
		return
	_enter_player_turn()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.size = Vector2(640, 480)
	add_child(bg)
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 16)
	_name_label.position = Vector2(30, 30)
	add_child(_name_label)
	_hp_label = Label.new()
	_hp_label.add_theme_font_size_override("font_size", 16)
	_hp_label.position = Vector2(30, 60)
	add_child(_hp_label)
	_form_label = Label.new()
	_form_label.add_theme_font_size_override("font_size", 10)
	_form_label.position = Vector2(30, 48)
	_form_label.visible = false
	add_child(_form_label)
	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.position = Vector2(207, 161)
	_hp_bar_bg.size = Vector2(18, 6)
	_hp_bar_bg.color = Color.BLACK
	add_child(_hp_bar_bg)
	_hp_bar = ColorRect.new()
	_hp_bar.position = Vector2(208, 162)
	_hp_bar.size = Vector2(16, 4)
	_hp_bar.color = Color(0.75, 1.0, 0.25)
	add_child(_hp_bar)
	_build_hud()
	_build_menu()
	_build_fight_bar()
	_dodge_box = DodgeBox.new()
	add_child(_dodge_box)
	_dodge_box.set_active(false)
	_dodge_box.player_hit.connect(_on_player_hit)
	_dodge_box.heal_requested.connect(_on_heal_collected)
	_text = load("res://scripts/dialogue/dialogue_ui.gd").new()
	add_child(_text)

func _spawn_enemy_sprite() -> void:
	_enemy_sprite = Sprite2D.new()
	_enemy_sprite.texture = Sprites.battle_enemy_texture(_enemy["sprite_id"], false)
	_enemy_sprite.position = Vector2(216, 136)
	_enemy_sprite.scale = Vector2(0.8, 0.8)
	add_child(_enemy_sprite)
	var shadow := Sprite2D.new()
	shadow.texture = load("res://assets/sprites/shadow_ellipse.png")
	shadow.position = Vector2(216, 152)
	shadow.modulate = Color(0, 0, 0, 0.4)
	shadow.z_index = -1
	add_child(shadow)
	if _hp_bar_bg != null:
		_hp_bar_bg.position = Vector2(207, 161)
	if _hp_bar != null:
		_hp_bar.position = Vector2(208, 162)

func _on_enemy_hurt_frame() -> void:
	var hurt_tex := Sprites.battle_enemy_texture(_enemy["sprite_id"], true)
	if hurt_tex != _enemy_sprite.texture:
		_enemy_sprite.texture = hurt_tex
		var tree := Engine.get_main_loop() as SceneTree
		if tree == null:
			return
		await tree.create_timer(0.3).timeout
		_restore_enemy_frame()

func _restore_enemy_frame() -> void:
	_enemy_sprite.texture = Sprites.battle_enemy_texture(_enemy["sprite_id"], false)

func _show_boss_intro() -> void:
	var tree := get_tree()
	if tree == null:
		return
	Fade.fade_to_black(0.4)
	await tree.create_timer(0.45).timeout
	if not is_inside_tree():
		return
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	var label := Label.new()
	var intro_name := str(_enemy["name"]).to_upper()
	if intro_name.begins_with("THE "):
		intro_name = intro_name.substr(4)
	label.text = "THE %s" % intro_name
	label.add_theme_font_size_override("font_size", 32)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(640, 40)
	label.position = Vector2(0, 220)
	layer.add_child(label)
	await tree.create_timer(1.1).timeout
	layer.queue_free()
	Fade.fade_from_black(0.4)
	await tree.create_timer(0.45).timeout

func _spawn_vaporize_poof(at: Vector2) -> void:
	Audio.play_sfx("vaporize")
	var poof := ColorRect.new()
	poof.name = "VaporizePoof"
	poof.color = Color(1, 1, 1)
	poof.position = at
	poof.size = Vector2(8, 8)
	poof.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(poof)
	var tween := create_tween()
	tween.tween_property(poof, "size", Vector2(64, 64), 0.3)
	tween.parallel().tween_property(poof, "color:a", 0.0, 0.3)
	tween.tween_callback(poof.queue_free)

func _build_hud() -> void:
	_player_name_label = Label.new()
	_player_name_label.name = "NameLabel"
	_player_name_label.text = "DREAMCATCHER LV %d" % lv
	_player_name_label.add_theme_font_size_override("font_size", 16)
	_player_name_label.position = Vector2(30, 400)
	add_child(_player_name_label)
	_player_hp_bar = ColorRect.new()
	_player_hp_bar.name = "HPUnderlay"
	_player_hp_bar.color = Color(0.753, 0.0, 0.0)
	_player_hp_bar.position = Vector2(275, 400)
	_player_hp_bar.size = Vector2(float(max_hp) * 1.25, 21.0)
	add_child(_player_hp_bar)
	_player_hp_fill = ColorRect.new()
	_player_hp_fill.name = "HPFill"
	_player_hp_fill.color = Color(1.0, 1.0, 0.0)
	_player_hp_fill.position = Vector2(275, 400)
	_player_hp_fill.size = Vector2(float(hp) * 1.25, 21.0)
	add_child(_player_hp_fill)
	_player_hp_label = Label.new()
	_player_hp_label.name = "HPLabel"
	_player_hp_label.add_theme_font_size_override("font_size", 16)
	_player_hp_label.position = Vector2(275 + float(max_hp) * 1.25 + 4.0, 404)
	_player_hp_label.text = "%02d / %02d" % [hp, max_hp]
	add_child(_player_hp_label)

func _build_menu() -> void:
	_menu = Control.new()
	_menu_items = ["FIGHT", "ACT", "ITEM", "MERCY"]
	_menu_box = Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 1)
	sb.set_border_width_all(1)
	sb.border_color = Color.WHITE
	_menu_box.add_theme_stylebox_override("panel", sb)
	_menu_box.position = Vector2(400, 385)
	_menu_box.size = Vector2(202, 80)
	_menu.add_child(_menu_box)
	var buttons := Node2D.new()
	buttons.name = "MenuButtons"
	add_child(buttons)
	var names: Array[String] = ["FIGHT", "ACT", "ITEM", "MERCY"]
	for i in 4:
		var spr := Sprite2D.new()
		spr.name = names[i]
		spr.texture = load("res://assets/sprites/" + names[i] + "_sprite_button.png")
		spr.position = _button_center(i)
		spr.scale = Vector2(0.5, 0.5)
		buttons.add_child(spr)
	_render_menu_labels()
	add_child(_menu)
	_menu.visible = false
	_update_menu_colors()

func _button_center(i: int) -> Vector2:
	return Vector2(432 + MENU_GRID[i].x * 90.0 + 55.0, 413 + MENU_GRID[i].y * 30.0 + 21.0)

func _submenu_pos(i: int) -> Vector2:
	match _submenu_context:
		"ACT":
			return Vector2(276 + (i % 2) * 70, 413 + int(i / 2) * 30)
		"ITEM":
			return Vector2(276 + (i % 4) * 70, 413 + int(i / 4) * 30)
		_:
			return Vector2(276, 413 + i * 30)

func _render_menu_labels() -> void:
	for child in _menu.get_children():
		child.queue_free()
	if not _submenu_open:
		_menu_cursor = Sprite2D.new()
		_menu_cursor.texture = Sprites.soul_texture("Red")
		_menu.add_child(_menu_cursor)
		return
	var items: Array[String] = _submenu_items
	for i in items.size():
		var l := Label.new()
		l.text = items[i]
		l.add_theme_font_size_override("font_size", 16)
		l.position = _submenu_pos(i)
		l.name = "item_%d" % i
		_menu.add_child(l)
	_menu_cursor = Sprite2D.new()
	_menu_cursor.texture = Sprites.soul_texture("Red")
	_menu.add_child(_menu_cursor)

func _update_menu_colors() -> void:
	var idx := _submenu_index if _submenu_open else _menu_index
	var count: int = _submenu_items.size() if _submenu_open else _menu_items.size()
	for i in count:
		var l := _menu.get_node_or_null("item_%d" % i) as Label
		if l == null:
			continue
		l.add_theme_color_override("font_color", Color.WHITE if i == idx else Color(1, 1, 1, 0.5))
	var menu_names: Array[String] = ["FIGHT", "ACT", "ITEM", "MERCY"]
	for i in menu_names.size():
		var b := get_node_or_null("MenuButtons/" + menu_names[i]) as Sprite2D
		if b == null:
			continue
		b.modulate = Color(1, 1, 1, 1.0 if i == _menu_index else 0.5)
	if _menu_cursor == null:
		return
	var target: Vector2
	if _submenu_open:
		target = _submenu_pos(idx) + Vector2(-14, 0)
	else:
		target = _button_center(idx) + Vector2(-40, 0)
	_menu_cursor.position = target

func _build_fight_bar() -> void:
	_fight_bar_ui = Control.new()
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.85)
	sb.set_border_width_all(1)
	sb.border_color = Color.WHITE
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(45, 415)
	panel.size = Vector2(260, 28)
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
	if _enemy_in:
		var t := Time.get_ticks_msec() * 0.004
		_enemy_sprite.position.y = 136.0 + sin(Time.get_ticks_msec() * 0.003) * 3.0
		_enemy_sprite.scale = Vector2(0.8 * (1.0 + sin(t + 1.5) * 0.015), 0.8 * (1.0 + sin(t) * 0.02))
		_enemy_hp_display = CombatMath.drain_toward(_enemy_hp_display, float(_enemy["hp"]), delta, 40.0)
		_hp_bar.size.x = _hp_bar_w * (_enemy_hp_display / float(_enemy_max_hp))
	match _state.phase:
		BattleState.Phase.PLAYER_TURN:
			if _submenu_open:
				_handle_submenu_input()
			else:
				_handle_menu_input()
		BattleState.Phase.FIGHT:
			_fight_bar.tick(delta)
			_fight_marker.position = Vector2(45 + _fight_bar.marker * 256.0, 415)
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
		Audio.play_sfx("select")
		_update_menu_colors()
	if Input.is_action_just_pressed("confirm"):
		Audio.play_sfx("confirm")
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
			_open_submenu(EnemyLibrary.act_labels(_enemy["acts"]), "ACT")
		"ITEM":
			_open_submenu(_item_labels(), "ITEM")
		"MERCY":
			var mercy: Array[String] = ["Spare"]
			if not bool(_enemy.get("no_flee", false)):
				mercy.append("Flee")
			_open_submenu(mercy, "MERCY")

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
	_submenu_items = items
	var box: Rect2 = SUBMENU_BOXES[context]
	_menu_box.position = box.position
	_menu_box.size = box.size
	_render_menu_labels()
	_menu.visible = true
	_update_menu_colors()
	Audio.play_sfx("select")

func _handle_submenu_input() -> void:
	if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_left"):
		_submenu_index = clampi(_submenu_index - 1, 0, _submenu_items.size() - 1)
		Audio.play_sfx("select")
		_update_menu_colors()
	elif Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("move_right"):
		_submenu_index = clampi(_submenu_index + 1, 0, _submenu_items.size() - 1)
		Audio.play_sfx("select")
		_update_menu_colors()
	elif Input.is_action_just_pressed("confirm"):
		Audio.play_sfx("confirm")
		_submenu_open = false
		_menu.visible = false
		_resolve_submenu()
	elif Input.is_action_just_pressed("cancel"):
		Audio.play_sfx("cancel")
		_submenu_open = false
		_menu.visible = false
		_enter_player_turn()

func _resolve_submenu() -> void:
	_state.transition(BattleState.Phase.ENEMY_TURN)
	var choice: String = _submenu_items[_submenu_index]
	match _submenu_context:
		"ACT":
			var act: Dictionary = EnemyLibrary.act_by_label(_enemy["acts"], choice)
			_mood += int(act.get("mood", 0))
			await _say([{"speaker": "", "text": str(act.get("text", "You try something."))}])
		"ITEM":
			if choice == "(empty)":
				await _say([{"speaker": "", "text": "Your pockets are empty."}])
			else:
				var item: Dictionary = GameState.use_item(_submenu_index)
				Audio.play_sfx("heal")
				await _say([{"speaker": "", "text": "You used %s. It hums warmly." % item.get("name", "it")}])
				_refresh_player_ui()
		"MERCY":
			if choice == "Spare":
				if _mood >= int(_enemy["spare_after"]):
					_state.transition(BattleState.Phase.SPARED)
					GameState.add_spare()
					_dodge_box.fade_out_bullets()
					await get_tree().create_timer(0.5).timeout
					await _say([{"speaker": "", "text": "You spare %s. It settles, grateful." % _enemy["name"]}])
					_end_battle()
					return
				else:
					await _say([{"speaker": "", "text": "%s wavers, but stays on guard." % _enemy["name"]}])
			else:
				if bool(_enemy.get("no_flee", false)):
					await _say([{"speaker": "", "text": "There is nowhere to flee."}])
				elif flee_roll(randf()):
					Audio.play_sfx("flee")
					await _say([{"speaker": "", "text": "You flee, heart pounding."}])
					_end_battle()
					return
				else:
					await _say([{"speaker": "", "text": "But it failed."}])
	_refresh_enemy_ui()
	_enemy_turn()

func _resolve_fight() -> void:
	_state.transition(BattleState.Phase.ENEMY_TURN)
	_fight_bar_ui.visible = false
	var intent := _fight_bar.press()
	if intent < 0.1:
		_spawn_damage_digit(0, true)
		await _say([{"speaker": "", "text": "MISS."}])
	else:
		var dmg := CombatMath.calculate_damage(int(GameState.player_stats["atk"]), int(_enemy["def"]), intent)
		_enemy["hp"] = int(_enemy["hp"]) - dmg
		Audio.play_sfx("slice")
		_enemy_sprite.modulate = Color(3.0, 3.0, 3.0)
		var flash := create_tween()
		flash.tween_property(_enemy_sprite, "modulate", Color(1, 1, 1), 0.1)
		_on_enemy_hurt_frame()
		_spawn_damage_digit(dmg, false)
		_refresh_enemy_ui()
		await _say([{"speaker": "", "text": "You strike. %s takes %d damage." % [_enemy["name"], dmg]}])
	if int(_enemy["hp"]) <= 0:
		if _form_index < _forms.size() - 1:
			_form_index += 1
			EnemyLibrary.apply_form(_enemy, _forms[_form_index])
			_enemy_max_hp = int(_enemy["hp"])
			_enemy_hp_display = float(_enemy_max_hp)
			_mood = 0
			_enemy_sprite.texture = Sprites.battle_enemy_texture(_enemy["sprite_id"], false)
			var form_flash := create_tween()
			form_flash.tween_property(_enemy_sprite, "modulate", Color(3.0, 3.0, 3.0), 0.05)
			form_flash.tween_property(_enemy_sprite, "modulate", Color(1, 1, 1), 0.1)
			_refresh_enemy_ui()
			_update_form_label()
			await _say([{"speaker": "", "text": str(_enemy["intro_line"])}])
			_enemy_turn()
			return
		_state.transition(BattleState.Phase.WIN)
		GameState.add_kill()
		GameState.player_stats["gold"] = int(GameState.player_stats["gold"]) + 2
		await _say([{"speaker": "", "text": "%s fades into soft light. You feel colder." % _enemy["name"]}])
		_spawn_vaporize_poof(_enemy_sprite.position)
		_enemy_sprite.visible = false
		await get_tree().create_timer(0.3).timeout
		var ending_id := Ending.end_for_victory(str(GameState.flags.get("pending_enemy", "")))
		if not ending_id.is_empty():
			GameState.set_flag("keeper_victory", ending_id)
		_end_battle()
	else:
		_enemy_turn()

func _spawn_damage_digit(amount: int, miss: bool) -> void:
	var digit := Label.new()
	digit.text = "MISS" if miss else "-%d" % amount
	digit.add_theme_font_size_override("font_size", 16)
	digit.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6) if miss else Color(1.0, 0.2, 0.2))
	digit.position = _enemy_sprite.position + Vector2(-10, -16)
	add_child(digit)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(digit, "position:y", digit.position.y + 12.0, 0.6)
	t.tween_property(digit, "modulate:a", 0.0, 0.6)
	t.chain().tween_callback(digit.queue_free)

func _enemy_turn() -> void:
	_turn_count += 1
	var hp_frac: float = float(_enemy["hp"]) / float(_enemy_max_hp) if _enemy_max_hp > 0 else 1.0
	var monologue: Array = EnemyLibrary.monologue_lines(_enemy.get("monologue", []), hp_frac, _monologue_shown)
	if not monologue.is_empty():
		_monologue_shown.append(monologue[0]["at"])
		await _say([{"speaker": str(monologue[0].get("speaker", "")), "text": str(monologue[0]["text"])}])
	var attack_lines: Array = _enemy["attack_lines"]
	var line: String = str(attack_lines[randi() % attack_lines.size()])
	await _say([{"speaker": "", "text": line}])
	_dodge_box.set_mode(str(_enemy.get("soul_mode", "red")))
	_dodge_box.set_active(true)
	for i in _enemy["patterns"].size():
		var pattern: Dictionary = _enemy["patterns"][i]
		if bool(pattern.get("telegraph", false)):
			await _dodge_box.show_telegraph(0.6)
		var mult := minf(1.0 + 0.08 * float(maxi(_turn_count - 1, 0)), 1.6)
		var bullets := BulletPatterns.make(pattern, _dodge_box.heart_position())
		if mult > 1.0:
			for d in bullets:
				if str(d.get("behavior", "straight")) != "orbit":
					d["vel"] = (d.get("vel", Vector2.ZERO) as Vector2) * mult
		_dodge_box.spawn_patterns(bullets)
		match str(pattern.get("type", "burst")):
			"bone_wall":
				Audio.play_sfx("bone_clack")
			"spear_volley", "ring", "spiral":
				Audio.play_sfx("whoosh")
			"laser_sweep":
				Audio.play_sfx("laser")
			_:
				Audio.play_sfx("whoosh")
		var frames := 0
		while _dodge_box.has_bullets() and frames < 60 * 15:
			await get_tree().process_frame
			frames += 1
		if i < _enemy["patterns"].size() - 1:
			await get_tree().create_timer(0.8).timeout
	_dodge_box.set_active(false)
	_refresh_player_ui()
	if int(GameState.player_stats["hp"]) <= 0:
		_state.transition(BattleState.Phase.LOSE)
		await _say([{"speaker": "", "text": "You cannot give up just yet."}])
		Audio.play_music("death")
		Fade.fade_to_black(0.8)
		await get_tree().create_timer(0.9).timeout
		_show_stay_determined()
		await get_tree().create_timer(2.2).timeout
		GameState.heal_full()
		_end_battle()
	else:
		_enter_player_turn()

func _enter_player_turn() -> void:
	_state.transition(BattleState.Phase.PLAYER_TURN)
	_dodge_box.set_mode("red")
	_menu_items = ["FIGHT", "ACT", "ITEM", "MERCY"]
	_render_menu_labels()
	_menu_index = 0
	_menu.visible = true
	_update_menu_colors()

func _update_form_label() -> void:
	if _form_label == null:
		return
	if _forms.is_empty():
		_form_label.visible = false
	else:
		_form_label.visible = true
		_form_label.text = "FORM %d/%d" % [_form_index + 1, _forms.size()]

func _refresh_enemy_ui() -> void:
	_name_label.text = str(_enemy["name"])
	_name_label.add_theme_color_override("font_color", Color.YELLOW if _mood >= int(_enemy["spare_after"]) else Color.WHITE)
	_hp_label.text = "%d/%d" % [int(_enemy["hp"]), _enemy_max_hp]

func _refresh_player_ui() -> void:
	max_hp = int(GameState.player_stats["max_hp"])
	hp = int(GameState.player_stats["hp"])
	_player_hp_label.text = "%02d / %02d" % [hp, max_hp]
	_player_hp_fill.size.x = float(hp) * 1.25
	_player_hp_bar.size.x = float(max_hp) * 1.25

func _on_player_hit() -> void:
	Audio.play_sfx("hurt")
	GameState.change_hp(-1)
	_refresh_player_ui()
	var shake := create_tween()
	shake.tween_property(_dodge_box, "position", Vector2(2, 0), 0.05)
	shake.tween_property(_dodge_box, "position", Vector2(-2, 0), 0.05)
	shake.tween_property(_dodge_box, "position", Vector2.ZERO, 0.1)

func _on_heal_collected(amount: int) -> void:
	GameState.change_hp(amount)
	Audio.play_sfx("heal")
	_refresh_player_ui()

func _say(lines: Array[Dictionary]) -> void:
	_text.open(lines, true)
	await _text.finished

func _end_battle() -> void:
	_ending = true
	var room: String = str(GameState.flags.get("from_room", "res://scenes/rooms/DrizzleFields.tscn"))
	get_tree().change_scene_to_file(room)

func _show_stay_determined() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 60
	add_child(layer)
	var label := Label.new()
	label.text = "Stay determined!"
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(640, 40)
	label.position = Vector2(0, 220)
	layer.add_child(label)

static func flee_roll(roll: float) -> bool:
	return roll < FLEE_CHANCE
