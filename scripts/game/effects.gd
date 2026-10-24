class_name Effects
extends Node2D
## Effetti visivi leggeri, tutti disegnati da un unico nodo: particelle, anelli, fulmini, numeri, scritte.

var parts := []
var rings := []
var bolts := []
var texts := []
var blasts := []
var _shake := 0.0
var _banner := ""
var _banner_t := 0.0
var _font: Font


func _ready() -> void:
	material = Game.additive_material()
	_font = ThemeDB.fallback_font
	z_index = 5


func burst(pos: Vector2, color: Color, n: int, spd: float) -> void:
	for i in n:
		var a := randf() * TAU
		var s := randf_range(40.0, spd)
		parts.append({"p": pos, "v": Vector2(cos(a), sin(a)) * s, "life": randf_range(0.3, 0.8), "max": 0.8, "r": randf_range(2.0, 5.0), "c": Color.from_hsv(fmod(color.h + randf_range(-0.1, 0.1), 1.0), 0.9, 1.0)})
	if parts.size() > 900:
		parts = parts.slice(parts.size() - 900)


func ring(pos: Vector2, radius: float, color: Color, life: float = 0.4) -> void:
	rings.append({"p": pos, "r": radius, "c": color, "life": life, "max": life})


func bolt(points: PackedVector2Array, color: Color) -> void:
	bolts.append({"pts": points, "c": color, "life": 0.25})


func text(pos: Vector2, s: String, color: Color) -> void:
	texts.append({"p": pos, "s": s, "c": color, "life": 0.6})
	if texts.size() > 120:
		texts.pop_front()


func delayed_blast(pos: Vector2, delay: float, radius: float, dmg: float, color: Color) -> void:
	blasts.append({"p": pos, "t": delay, "r": radius, "d": dmg, "c": color, "max": delay})


func shake(v: float) -> void:
	_shake = maxf(_shake, v)


func banner(s: String) -> void:
	_banner = s
	_banner_t = 3.0


func _process(delta: float) -> void:
	for p in parts:
		p["p"] += p["v"] * delta
		p["v"] *= 0.92
		p["life"] -= delta
	parts = parts.filter(func(p): return p["life"] > 0.0)
	for r in rings:
		r["life"] -= delta
	rings = rings.filter(func(r): return r["life"] > 0.0)
	for b in bolts:
		b["life"] -= delta
	bolts = bolts.filter(func(b): return b["life"] > 0.0)
	for t in texts:
		t["p"].y -= 40.0 * delta
		t["life"] -= delta
	texts = texts.filter(func(t): return t["life"] > 0.0)
	var g := Game.current
	for b in blasts:
		b["t"] -= delta
		if b["t"] <= 0.0:
			g.hit_area(b["p"], b["r"], b["d"], 40.0, b["c"])
			burst(b["p"], b["c"], 5, 120.0)
	blasts = blasts.filter(func(b): return b["t"] > 0.0)
	_shake = maxf(0.0, _shake - delta * 30.0)
	g.camera.offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
	_banner_t -= delta
	queue_redraw()


func _draw() -> void:
	for b in blasts:
		var k: float = 1.0 - b["t"] / b["max"]
		draw_circle(b["p"], 5.0 + 3.0 * sin(k * 20.0), Color(b["c"], 0.8))
		draw_arc(b["p"], b["r"] * k, 0.0, TAU, 24, Color(b["c"], 0.25), 2.0)
	for p in parts:
		draw_circle(p["p"], p["r"], Color(p["c"], p["life"] / p["max"]))
	for r in rings:
		var k: float = 1.0 - r["life"] / r["max"]
		draw_arc(r["p"], r["r"] * (0.4 + 0.6 * k), 0.0, TAU, 40, Color(r["c"], 1.0 - k), 4.0)
	for b in bolts:
		var pts: PackedVector2Array = b["pts"]
		var jag := PackedVector2Array()
		for i in pts.size():
			if i > 0:
				var a := pts[i - 1]
				var c := pts[i]
				for k in range(1, 4):
					jag.append(a.lerp(c, k / 4.0) + Vector2(randf_range(-10, 10), randf_range(-10, 10)))
			jag.append(pts[i])
		if jag.size() >= 2:
			draw_polyline(jag, Color(b["c"], b["life"] * 4.0), 3.0)
			draw_polyline(jag, Color(1, 1, 1, b["life"] * 3.0), 1.2)
	for t in texts:
		draw_string(_font, t["p"] - Vector2(10, 0), t["s"], HORIZONTAL_ALIGNMENT_CENTER, 20, 14, Color(t["c"], minf(1.0, t["life"] * 2.0)))
	if _banner_t > 0.0:
		var c := Game.current.camera.get_screen_center_position()
		var vs := get_viewport_rect().size
		draw_string(_font, c + Vector2(-vs.x * 0.5, -vs.y * 0.28), _banner, HORIZONTAL_ALIGNMENT_CENTER, vs.x, 30, Color.from_hsv(fmod(_banner_t * 0.4, 1.0), 0.6, 1.0, minf(1.0, _banner_t)))
