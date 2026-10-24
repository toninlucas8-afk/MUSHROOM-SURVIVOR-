extends Weapon
## Radici Perforanti → Labirinto Divoratore: zone di radici sotto i nemici (poi persistenti e curative).

var zones := [] # {p, life, max, r}
var _tick := 0.0


func fire() -> float:
	var n := 1 + int(level >= 2) + int(level >= 5) + int(level >= 8) + player.amount + (2 if evolved else 0)
	var targets := game().nearest(player.position, 450.0, n * 2)
	targets.shuffle()
	var life := (2.0 + 1.5 * int(level >= 6)) * (2.0 if evolved else 1.0)
	var r := (55.0 + 15.0 * int(level >= 4)) * area() * (1.5 if evolved else 1.0)
	for i in n:
		var p: Vector2 = targets[i].position if i < targets.size() else player.position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(60, 250)
		zones.append({"p": p, "life": life, "max": life, "r": r})
	return cd(3.0 - 0.3 * int(level >= 7))


func tick(delta: float) -> void:
	_tick -= delta
	var hit_now := _tick <= 0.0
	if hit_now:
		_tick = 0.33
	var base := dmg((6.0 + 3.0 * int(level >= 3) + 4.0 * int(level >= 7)) * (1.3 if evolved else 1.0))
	for z in zones:
		z["life"] -= delta
		if evolved:
			# il labirinto si allarga lentamente verso il giocatore
			z["p"] = z["p"].lerp(player.position, delta * 0.1)
		if hit_now:
			for e in game().query(z["p"], z["r"] + 30.0):
				if e.position.distance_to(z["p"]) < z["r"] + e.radius:
					e.take_damage(base, Vector2.ZERO, 0.0)
					e.slow = 0.3
	zones = zones.filter(func(z): return z["life"] > 0.0)


func on_kill(e: Enemy) -> void:
	if evolved:
		for z in zones:
			if e.position.distance_to(z["p"]) < z["r"]:
				player.hp = minf(player.max_hp, player.hp + 0.5)
				return


func _draw() -> void:
	for z in zones:
		var lp: Vector2 = z["p"] - player.position
		var k: float = clampf(z["life"] / 0.4, 0.0, 1.0) * clampf((z["max"] - z["life"]) / 0.2, 0.0, 1.0)
		var c := Color.from_hsv(fmod(color().h + t * 0.05, 1.0), 0.75, 0.85)
		draw_circle(lp, z["r"], Color(c.darkened(0.5), 0.25 * k))
		for i in 7:
			var a: float = TAU * i / 7.0 + z["max"]
			var base_p: Vector2 = lp + Vector2(cos(a), sin(a)) * z["r"] * 0.55
			var tip: Vector2 = base_p + Vector2(cos(a + 1.2), sin(a + 1.2) - 1.0) * z["r"] * 0.45 * k
			draw_line(base_p, tip, Color(c, k), 5.0)
			draw_circle(tip, 3.0, Color(c.lightened(0.4), k))
