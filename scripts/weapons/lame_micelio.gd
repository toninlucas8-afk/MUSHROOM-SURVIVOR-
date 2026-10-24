extends Weapon
## Lame di Micelio → Corona di Lame Dimensionali: fendenti ai lati (poi in tutte le direzioni).

var slashes := [] # {dir, life}


func fire() -> float:
	var dirs := []
	if evolved:
		for i in 8:
			dirs.append(Vector2.RIGHT.rotated(TAU * i / 8.0 + t))
	else:
		dirs.append(Vector2(player.facing, 0))
		if level >= 2:
			dirs.append(Vector2(-player.facing, 0))
		for i in player.amount:
			dirs.append(Vector2(0, -1 if i % 2 == 0 else 1))
	var reach := (110.0 + 18.0 * int(level >= 4) + 18.0 * int(level >= 6)) * area() * (1.3 if evolved else 1.0)
	var base := 12.0 + 5.0 * int(level >= 3) + 5.0 * int(level >= 5) + 6.0 * int(level >= 7) + 6.0 * int(level >= 8)
	var damage := dmg(base * (1.5 if evolved else 1.0))
	for d in dirs:
		slashes.append({"dir": d, "life": 0.22, "reach": reach})
		var center: Vector2 = player.position + d * reach * 0.55
		for e in game().query(center, reach * 0.6 + 40.0):
			var rel: Vector2 = e.position - player.position
			if rel.length() < reach + e.radius and rel.normalized().dot(d) > 0.55:
				e.take_damage(damage, d, 120.0)
	return cd((1.3 - 0.15 * int(level >= 8)) * (0.7 if evolved else 1.0))


func tick(delta: float) -> void:
	for s in slashes:
		s["life"] -= delta
	slashes = slashes.filter(func(s): return s["life"] > 0.0)


func _ready() -> void:
	material = Game.additive_material()


func _draw() -> void:
	for s in slashes:
		var k: float = s["life"] / 0.22
		var a: float = s["dir"].angle()
		var r: float = s["reach"]
		var c := Color.from_hsv(fmod(color().h + t * 0.5, 1.0), 0.7, 1.0, k)
		draw_arc(Vector2.ZERO, r * 0.8, a - 0.6, a + 0.6, 16, c, 14.0 * k)
		draw_arc(Vector2.ZERO, r * 0.55, a - 0.45, a + 0.45, 12, Color(1, 1, 1, k * 0.7), 5.0 * k)
