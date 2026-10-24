extends Node
## Punto di ingresso: menu principale, scelta del personaggio, partita e schermata finale.

const GAME_SCENE := preload("res://scenes/game.tscn")

var _ui: CanvasLayer
var _screen: Control
var _game: Game
var _bg: ColorRect
var _bg_mat: ShaderMaterial
var _bg_cam := Vector2.ZERO


func _ready() -> void:
	randomize()
	_ui = CanvasLayer.new()
	_ui.layer = 20
	_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ui)
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -20
	add_child(bg_layer)
	_bg = ColorRect.new()
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_mat = ShaderMaterial.new()
	_bg_mat.shader = load("res://shaders/background.gdshader")
	_bg.material = _bg_mat
	bg_layer.add_child(_bg)
	show_menu()


func _process(delta: float) -> void:
	if _bg.visible:
		_bg_cam += Vector2(30, 12) * delta
		_bg_mat.set_shader_parameter("cam_pos", _bg_cam)
		_bg_mat.set_shader_parameter("screen_size", get_viewport().get_visible_rect().size)
		_bg_mat.set_shader_parameter("intensity", 0.8)


func _set_screen(c: Control) -> void:
	if _screen:
		_screen.queue_free()
	_screen = c
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(c)


func _centered(c: Control) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.add_child(center)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 16)
	center.add_child(v)
	return v


# ------------------------------------------------------------- menu
func show_menu() -> void:
	_end_game()
	var root := Control.new()
	_set_screen(root)
	var v := _centered(root)
	v.add_child(UiStyle.label("MYCELIUM", 96, Color(1.0, 0.4, 0.9)))
	v.add_child(UiStyle.label("NEON ABYSS", 36, Color(0.5, 0.9, 1.0)))
	v.add_child(UiStyle.label("Sopravvivi alla rete. Ricorda chi eri.", 20, Color(1, 1, 1, 0.8)))
	var play := UiStyle.button("GIOCA", 30)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.pressed.connect(show_character_select)
	v.add_child(play)
	play.grab_focus.call_deferred()
	var info := "WASD / frecce per muoverti · su telefono trascina il dito · P o Esc pausa"
	if Data.best_time > 0.0:
		info += "\nRecord: %s · Frammenti di memoria: %d / %d" % [Data.format_time(Data.best_time), Data.memories_found, Data.MEMORIES.size()]
	v.add_child(UiStyle.label(info, 16, Color(1, 1, 1, 0.65)))


func show_character_select() -> void:
	var root := Control.new()
	_set_screen(root)
	var v := _centered(root)
	v.add_child(UiStyle.label("Scegli il tuo fungo", 40, Color(1.0, 0.5, 0.9)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	for id in Data.CHARACTER_ORDER:
		row.add_child(_character_card(id))
	var back := UiStyle.button("INDIETRO", 20)
	back.custom_minimum_size = Vector2(180, 50)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(show_menu)
	v.add_child(back)


func _character_card(id: String) -> Button:
	var c: Dictionary = Data.CHARACTERS[id]
	var col: Color = c["cap"]
	var b := Button.new()
	b.custom_minimum_size = Vector2(228, 420)
	b.add_theme_stylebox_override("normal", UiStyle.box(Color(col.darkened(0.8), 0.95), col, 18, 2 if id != Data.selected_character else 4))
	b.add_theme_stylebox_override("hover", UiStyle.box(Color(col.darkened(0.6), 0.95), Color.WHITE, 18, 3))
	b.add_theme_stylebox_override("pressed", UiStyle.box(Color(col.darkened(0.5), 0.95), Color.WHITE, 18, 3))
	b.add_theme_stylebox_override("focus", UiStyle.box(Color(col.darkened(0.6), 0.95), Color.WHITE, 18, 3))
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var prev := CharacterPreview.new()
	prev.char_id = id
	prev.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(prev)
	v.add_child(UiStyle.label(c["name"].to_upper(), 26, col.lightened(0.35)))
	v.add_child(UiStyle.label(c["title"], 14, Color(1, 1, 1, 0.75)))
	v.add_child(UiStyle.label(c["desc"], 13, Color.WHITE))
	v.add_child(UiStyle.label("Arma: " + Data.WEAPONS[c["signature"]]["name"], 13, Data.WEAPONS[c["signature"]]["color"]))
	v.add_child(UiStyle.label(c["ability"], 13, Color(1.0, 0.9, 0.5)))
	b.pressed.connect(start_game.bind(id))
	return b


# ------------------------------------------------------------- partita
func start_game(id: String) -> void:
	Data.selected_character = id
	Data.save()
	if _screen:
		_screen.queue_free()
		_screen = null
	_bg.visible = false
	_game = GAME_SCENE.instantiate()
	add_child(_game)
	_game.finished.connect(_on_game_finished)


func _end_game() -> void:
	get_tree().paused = false
	if _game:
		_game.queue_free()
		_game = null
	_bg.visible = true


func _on_game_finished(won: bool, s: Dictionary) -> void:
	var root := Control.new()
	_set_screen(root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.0, 0.05, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var v := _centered(root)
	if won:
		v.add_child(UiStyle.label("HAI RAGGIUNTO IL CUORE DELLA RETE", 40, Color(0.5, 1.0, 0.8)))
		v.add_child(UiStyle.label("La rete ti riconosce. Il resto della storia ti aspetta nella prossima spedizione.", 18))
	else:
		v.add_child(UiStyle.label("IL VIAGGIO È FINITO", 44, Color(1.0, 0.45, 0.8)))
	v.add_child(UiStyle.label("Sopravvissuto: %s · Livello %d · Nemici %d · Memorie trovate %d" % [Data.format_time(s["time"]), s["level"], s["kills"], s["memories"]], 20))
	v.add_child(UiStyle.label("Record: " + Data.format_time(Data.best_time), 18, Color(1.0, 0.85, 0.3)))
	v.add_child(UiStyle.label(s["build"], 16, Color(1, 1, 1, 0.85)))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	var again := UiStyle.button("RIPROVA")
	again.pressed.connect(func():
		_end_game()
		start_game(s["character"]))
	row.add_child(again)
	var menu := UiStyle.button("MENU")
	menu.pressed.connect(show_menu)
	row.add_child(menu)
	again.grab_focus.call_deferred()
