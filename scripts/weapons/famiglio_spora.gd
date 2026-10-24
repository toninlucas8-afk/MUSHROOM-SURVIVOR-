extends Weapon
## Famiglio Spora → Sciame Cosciente: piccoli compagni che volano intorno e sparano.

var familiars := [] # posizioni locali


func _process(delta: float) -> void:
	super._process(delta)
	var n := 1 + int(level >= 4) + int(level >= 7) + (3 if evolved else 0)
	while familiars.size() < n:
		familiars.append(Vector2(randf_range(-40, 40), randf_range(-40, 40)))
	for i in familiars.size():
		var target := Vector2(cos(t * 1.5 + i * TAU / n), sin(t * 2.1 + i * TAU / n)) * (55.0 + 10.0 * i)
		familiars[i] = familiars[i].lerp(target, minf(1.0, delta * 3.0))


func fire() -> float:
	var base := 9.0 + 4.0 * int(level >= 2) + 5.0 * int(level >= 5) + 6.0 * int(level >= 8)
	for f in familiars:
		var origin: Vector2 = player.position + f
		var tgt := game().nearest(origin, 420.0, 1)
		if tgt.is_empty():
			continue
		var p := shoot(tgt[0].position - origin, 380.0, dmg(base * (1.3 if evolved else 1.0)), 5.0, 1 + (1 if evolved else 0), 1.3, color())
		p.position = origin
		if evolved:
			p.homing = 5.0
	return cd((1.4 - 0.25 * int(level >= 3) - 0.25 * int(level >= 6)) * (0.75 if evolved else 1.0))


func _draw() -> void:
	for i in familiars.size():
		var f: Vector2 = familiars[i]
		var b := sin(t * 6.0 + i) * 2.0
		var look := {"cap": Color.from_hsv(fmod(color().h + i * 0.1, 1.0), 0.7, 1.0), "spot": Color.WHITE, "eyes": Color(1, 1, 0.6), "scarf": Color(0.1, 0.3, 0.3), "body": Color(0.9, 0.95, 0.9)}
		Art.draw_mushroom(self, f, 8.0, look, t + i, 1.0, false, b)
