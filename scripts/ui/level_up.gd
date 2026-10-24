class_name LevelUp
extends Control
## Scelta del potenziamento al passaggio di livello (tasti 1-3 o clic/tocco).

signal chosen(option: Dictionary)

var _cards: HBoxContainer
var _options: Array = []


func _ready() -> void:
	visible = false
	var v := UiStyle.overlay(self)
	v.add_child(UiStyle.label("LIVELLO SUPERIORE!", 48, Color(1.0, 0.5, 0.9)))
	v.add_child(UiStyle.label("Scegli un potenziamento", 20, Color(1, 1, 1, 0.8)))
	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 18)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(_cards)


func open(options: Array) -> void:
	_options = options
	for c in _cards.get_children():
		c.queue_free()
	for i in options.size():
		_cards.add_child(_make_card(i, options[i]))
	visible = true


func _make_card(i: int, o: Dictionary) -> Button:
	var title := ""
	var kind := ""
	var desc := ""
	var col := Color.WHITE
	match o["kind"]:
		"weapon":
			var w: Dictionary = Data.WEAPONS[o["id"]]
			title = w["name"]
			col = w["color"]
			kind = "ARMA · NUOVA" if o["level"] == 1 else "ARMA · LV %d" % o["level"]
			desc = w["desc"] if o["level"] == 1 else w["levels"][o["level"] - 2]
			if o["level"] == 1:
				desc += "\nEvolve con: " + Data.PASSIVES[w["evo_passive"]]["name"]
		"evo":
			var w2: Dictionary = Data.WEAPONS[o["id"]]
			title = w2["evo"]
			col = Color(1.0, 0.85, 0.3)
			kind = "★ EVOLUZIONE ★"
			desc = w2["evo_desc"]
		"passive":
			var pz: Dictionary = Data.PASSIVES[o["id"]]
			title = pz["name"]
			col = pz["color"]
			kind = "POTERE · NUOVO" if o["level"] == 1 else "POTERE · LV %d" % o["level"]
			desc = pz["desc"]
		"heal":
			title = "Zuppa di Funghi"
			col = Color(1.0, 0.6, 0.3)
			kind = "CURA"
			desc = "Recupera 40 vita."
	var b := Button.new()
	b.custom_minimum_size = Vector2(270, 230)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", UiStyle.box(Color(col.darkened(0.75), 0.95), col, 18, 3))
	b.add_theme_stylebox_override("hover", UiStyle.box(Color(col.darkened(0.55), 0.95), Color.WHITE, 18, 3))
	b.add_theme_stylebox_override("pressed", UiStyle.box(Color(col.darkened(0.4), 0.95), Color.WHITE, 18, 3))
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 8)
	b.add_child(v)
	v.add_child(UiStyle.label("[%d] %s" % [i + 1, kind], 13, Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_LEFT))
	v.add_child(UiStyle.label(title, 22, col.lightened(0.3), HORIZONTAL_ALIGNMENT_LEFT))
	v.add_child(UiStyle.label(desc, 16, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
	b.pressed.connect(_choose.bind(i))
	return b


func _input(event: InputEvent) -> void:
	if not visible:
		return
	for i in 4:
		if event.is_action_pressed("choose_%d" % (i + 1)) and i < _options.size():
			_choose(i)
			get_viewport().set_input_as_handled()
			return


func _choose(i: int) -> void:
	if not visible:
		return
	visible = false
	chosen.emit(_options[i])
