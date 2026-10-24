class_name Art
## Disegni a codice usati finché non ci sono gli sprite definitivi.
## Tutto è disegnato in coordinate "unitarie" e poi scalato con draw_set_transform.

const TAU_F := PI * 2.0


static func ellipse(center: Vector2, rx: float, ry: float, n: int = 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU_F * i / n
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func _bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	return a.lerp(b, t).lerp(b.lerp(c, t), t)


## Fungo nello stile del riferimento: cappello conico morbido, occhi luminosi in ombra, sciarpa, gambo.
static func draw_mushroom(ci: CanvasItem, pos: Vector2, size: float, look: Dictionary, t: float, face: float = 1.0, flash: bool = false, bob: float = 0.0) -> void:
	var cap: Color = look["cap"]
	var spot: Color = look["spot"]
	var eyes: Color = look["eyes"]
	var scarf: Color = look["scarf"]
	var body: Color = look["body"]
	if flash:
		cap = Color.WHITE; body = Color.WHITE; scarf = Color.WHITE
	ci.draw_set_transform(pos + Vector2(0, bob), 0.0, Vector2(size * face, size))
	# ombra a terra
	ci.draw_colored_polygon(ellipse(Vector2(0, 1.12 - bob / size), 0.75, 0.18), Color(0, 0, 0, 0.35))
	# gambo / corpo
	var stem := PackedVector2Array()
	for i in 13:
		var a := PI * i / 12.0
		stem.append(Vector2(-cos(a) * 0.5, 0.95 + sin(a) * 0.12))
	stem.append(Vector2(0.42, 0.2))
	stem.append(Vector2(-0.42, 0.2))
	var stem_rev := PackedVector2Array()
	for i in range(stem.size() - 1, -1, -1):
		stem_rev.append(stem[i])
	ci.draw_colored_polygon(stem_rev, body)
	# piedi bluastri
	ci.draw_colored_polygon(ellipse(Vector2(-0.22, 1.0), 0.2, 0.1), body.darkened(0.45).lerp(Color(0.3, 0.45, 0.6), 0.5))
	ci.draw_colored_polygon(ellipse(Vector2(0.22, 1.0), 0.2, 0.1), body.darkened(0.45).lerp(Color(0.3, 0.45, 0.6), 0.5))
	# macchioline sul gambo
	ci.draw_circle(Vector2(-0.28, 0.75), 0.05, body.darkened(0.4))
	ci.draw_circle(Vector2(-0.2, 0.83), 0.035, body.darkened(0.4))
	# braccino
	ci.draw_colored_polygon(ellipse(Vector2(0.38, 0.5), 0.13, 0.2), body.darkened(0.08))
	# sciarpa
	var sc := PackedVector2Array([Vector2(-0.48, 0.12), Vector2(0.48, 0.12), Vector2(0.42, 0.36), Vector2(0.1, 0.42), Vector2(-0.44, 0.34)])
	ci.draw_colored_polygon(sc, scarf)
	var tail_sway := sin(t * 4.0) * 0.08
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-0.3, 0.3), Vector2(-0.12, 0.32), Vector2(-0.22 + tail_sway, 0.7), Vector2(-0.38 + tail_sway, 0.66)]), scarf.darkened(0.2))
	# cappello conico
	var cap_pts := PackedVector2Array()
	var left := Vector2(-1.15, 0.08)
	var right := Vector2(1.15, 0.08)
	var tip := Vector2(0.05, -1.2)
	for i in 17:
		cap_pts.append(_bezier(left, Vector2(-0.85, -1.0), tip, i / 16.0))
	for i in range(1, 17):
		cap_pts.append(_bezier(tip, Vector2(0.95, -1.0), right, i / 16.0))
	for i in range(1, 12):
		cap_pts.append(_bezier(right, Vector2(0.0, 0.32), left, i / 12.0))
	ci.draw_colored_polygon(cap_pts, cap)
	if not flash:
		# luce morbida in alto e ombra sul bordo
		ci.draw_colored_polygon(ellipse(Vector2(0.25, -0.6), 0.55, 0.3), Color(1, 1, 1, 0.12))
		ci.draw_colored_polygon(ellipse(Vector2(0.0, 0.05), 1.02, 0.14), cap.darkened(0.35))
		# puntini
		for p in [Vector3(0.35, -0.75, 0.13), Vector3(0.55, -0.35, 0.16), Vector3(0.0, -0.45, 0.1), Vector3(-0.5, -0.3, 0.09), Vector3(0.85, -0.12, 0.08), Vector3(-0.15, -0.85, 0.06)]:
			ci.draw_colored_polygon(ellipse(Vector2(p.x, p.y), p.z * 1.35, p.z), Color(spot, 0.9))
	# zona d'ombra sotto il cappello con occhi luminosi
	ci.draw_colored_polygon(ellipse(Vector2(0.05, 0.16), 0.62, 0.13), Color(0.05, 0.02, 0.08, 0.95))
	var blink := 1.0 if fmod(t, 3.7) > 0.12 else 0.15
	for ex in [-0.13, 0.3]:
		ci.draw_circle(Vector2(ex, 0.16), 0.13, Color(eyes, 0.25))
		ci.draw_colored_polygon(ellipse(Vector2(ex, 0.16), 0.09, 0.05 * blink, 10), eyes.lightened(0.5))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func draw_enemy(ci: CanvasItem, type: String, pos: Vector2, r: float, base: Color, t: float, look_dir: Vector2, flash: bool, phase: float) -> void:
	var col := Color.WHITE if flash else Color.from_hsv(fmod(base.h + t * 0.08 + phase * 0.05, 1.0), 0.8, 0.95)
	var dark := Color.WHITE if flash else col.darkened(0.55)
	var ang := look_dir.angle()
	match type:
		"lumaca":
			ci.draw_colored_polygon(ellipse(pos + Vector2(0, r * 0.45), r * 1.2, r * 0.45), dark)
			ci.draw_circle(pos + Vector2(0, -r * 0.1), r * 0.85, col)
			var spiral := PackedVector2Array()
			for i in 30:
				var a := i * 0.45 + t * 3.0
				var rr := float(i) / 30.0 * r * 0.75
				spiral.append(pos + Vector2(0, -r * 0.1) + Vector2(cos(a), sin(a)) * rr)
			ci.draw_polyline(spiral, dark, 2.5)
		"zanzara":
			var flap := sin(t * 40.0 + phase) * 0.6
			ci.draw_set_transform(pos + Vector2(-r * 0.6, -r * 0.5), -0.6 + flap, Vector2.ONE)
			ci.draw_colored_polygon(ellipse(Vector2.ZERO, r * 0.8, r * 0.35), Color(1, 1, 1, 0.45))
			ci.draw_set_transform(pos + Vector2(r * 0.6, -r * 0.5), 0.6 - flap, Vector2.ONE)
			ci.draw_colored_polygon(ellipse(Vector2.ZERO, r * 0.8, r * 0.35), Color(1, 1, 1, 0.45))
			ci.draw_set_transform(pos, ang + PI / 2.0, Vector2.ONE)
			ci.draw_colored_polygon(ellipse(Vector2.ZERO, r * 0.55, r * 0.9), col)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			ci.draw_circle(pos + look_dir * r * 0.5, r * 0.25, Color(1, 0.12, 0.3))
		"bruco":
			var side := look_dir.orthogonal()
			for i in range(3, -1, -1):
				var off := float(i) * r * 0.55
				var w := sin(t * 6.0 + i + phase) * 4.0
				var c := Color.WHITE if flash else Color.from_hsv(fmod(col.h + i * 0.11, 1.0), 0.85, 0.95 - i * 0.07)
				ci.draw_circle(pos - look_dir * off + side * w, r * (0.75 - i * 0.08), c)
			ci.draw_circle(pos + look_dir * r * 0.3 + Vector2(0, -3), 3.5, Color.WHITE)
		"occhio":
			var blob := PackedVector2Array()
			for i in 12:
				var a := TAU_F * i / 12.0
				blob.append(pos + Vector2(cos(a), sin(a)) * r * (1.15 + 0.15 * sin(t * 5.0 + i)))
			ci.draw_colored_polygon(blob, col)
			ci.draw_circle(pos, r * 0.85, Color.WHITE)
			ci.draw_circle(pos + look_dir * r * 0.3, r * 0.45, Color.from_hsv(fmod(col.h + 0.5, 1.0), 0.9, 0.8))
			ci.draw_circle(pos + look_dir * r * 0.4, r * 0.2, Color.BLACK)
		"boss":
			var blob := PackedVector2Array()
			for i in 28:
				var a := TAU_F * i / 28.0
				blob.append(pos + Vector2(cos(a), sin(a)) * r * (1.0 + 0.12 * sin(t * 3.0 + i * 1.7) + 0.06 * sin(t * 7.0 + i * 3.0)))
			ci.draw_colored_polygon(blob, Color.WHITE if flash else col.darkened(0.45))
			# corona fungina
			for i in 5:
				var a := -PI / 2.0 + (i - 2) * 0.35
				var base_p := pos + Vector2(cos(a), sin(a)) * r * 0.95
				ci.draw_colored_polygon(ellipse(base_p + Vector2(0, -r * 0.18), r * 0.18, r * 0.1), col)
				ci.draw_line(base_p, base_p + Vector2(0, -r * 0.18), col.lightened(0.4), 3.0)
			for i in 5:
				var a := TAU_F * i / 5.0 + t * 0.4
				var ep := pos + Vector2(cos(a), sin(a)) * r * 0.5
				ci.draw_circle(ep, r * 0.18, Color.WHITE)
				ci.draw_circle(ep + look_dir * 4.0, r * 0.08, Color(0.1, 0, 0))
