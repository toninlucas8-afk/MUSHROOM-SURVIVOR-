class_name Hud
extends Control
## Interfaccia in partita: esperienza, tempo, vita, uccisioni, armi e passivi, tasti touch.

var _font: Font
var _dash_btn: Button
var _pause_btn: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	_pause_btn = UiStyle.button("II", 22)
	_pause_btn.custom_minimum_size = Vector2(56, 56)
	_place(_pause_btn, Vector2(1, 0), Rect2(-72, 60, 56, 56))
	_pause_btn.focus_mode = Control.FOCUS_NONE
	_pause_btn.pressed.connect(func(): Game.current.toggle_pause())
	add_child(_pause_btn)
	if Data.selected_character == "zephyr":
		_dash_btn = UiStyle.button("SCATTO", 20)
		_dash_btn.custom_minimum_size = Vector2(130, 90)
		_place(_dash_btn, Vector2(1, 1), Rect2(-160, -120, 130, 90))
		_dash_btn.focus_mode = Control.FOCUS_NONE
		_dash_btn.pressed.connect(func(): Game.current.player.try_dash())
		add_child(_dash_btn)


## Ancora un pulsante a un angolo dello schermo (anchor 0/1) con un rettangolo relativo.
func _place(c: Control, anchor: Vector2, r: Rect2) -> void:
	c.anchor_left = anchor.x
	c.anchor_right = anchor.x
	c.anchor_top = anchor.y
	c.anchor_bottom = anchor.y
	c.offset_left = r.position.x
	c.offset_top = r.position.y
	c.offset_right = r.position.x + r.size.x
	c.offset_bottom = r.position.y + r.size.y


func _process(_delta: float) -> void:
	if _dash_btn:
		_dash_btn.modulate.a = 0.4 + 0.6 * Game.current.player.dash_ready()
	queue_redraw()


func _draw() -> void:
	var g := Game.current
	if g == null:
		return
	var w := size.x
	var t := g.elapsed
	# barra esperienza arcobaleno
	draw_rect(Rect2(0, 0, w, 16), Color(0, 0, 0, 0.55))
	var fill := w * clampf(float(g.xp) / g.xp_next, 0.0, 1.0)
	var steps := 24
	for i in steps:
		var x0 := fill * i / steps
		draw_rect(Rect2(x0, 0, fill / steps + 1.0, 16), Color.from_hsv(fmod(t * 0.2 + float(i) / steps, 1.0), 0.8, 1.0))
	draw_string(_font, Vector2(w - 70, 13), "LV %d" % g.level, HORIZONTAL_ALIGNMENT_RIGHT, 60, 14, Color.WHITE)
	# tempo
	var tc := Color.from_hsv(fmod(t * 0.25, 1.0), 0.5, 1.0)
	draw_string(_font, Vector2(0, 54), Data.format_time(t), HORIZONTAL_ALIGNMENT_CENTER, w, 34, tc)
	# vita e uccisioni
	var p := g.player
	draw_string(_font, Vector2(14, 44), "Vita %d / %d" % [ceili(p.hp), int(p.max_hp)], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.5, 1.0, 0.6))
	draw_string(_font, Vector2(w - 214, 44), "Nemici %d" % g.kills, HORIZONTAL_ALIGNMENT_RIGHT, 200, 18, Color.WHITE)
	# armi e passivi
	var x := 14.0
	for id in p.weapons:
		var wpn: Weapon = p.weapons[id]
		var c: Color = Data.WEAPONS[id]["color"]
		draw_circle(Vector2(x + 14, 72), 14.0, Color(c, 0.85))
		if wpn.evolved:
			draw_arc(Vector2(x + 14, 72), 17.0, 0, TAU, 24, Color.WHITE, 2.0)
		draw_string(_font, Vector2(x, 77), "E" if wpn.evolved else str(wpn.level), HORIZONTAL_ALIGNMENT_CENTER, 28, 14, Color.BLACK)
		x += 34.0
	x = 14.0
	for id in p.passives:
		var c2: Color = Data.PASSIVES[id]["color"]
		draw_rect(Rect2(x + 2, 94, 24, 24), Color(c2, 0.85))
		draw_string(_font, Vector2(x, 111), str(p.passives[id]), HORIZONTAL_ALIGNMENT_CENTER, 28, 14, Color.BLACK)
		x += 34.0
