extends Weapon
## Anello Gravitazionale → Singolarità Vivente: sfere orbitanti (poi buchi neri che risucchiano).

var orbs: Array[Vector2] = []
var _hole_timer := 3.0
var holes := [] # {p, life}


func _process(delta: float) -> void:
	super._process(delta)
	var n := 2 + int(level >= 2) + int(level >= 5) + int(level >= 8) + player.amount + (1 if evolved else 0)
	var rad := (70.0 + 25.0 * int(level >= 4)) * area()
	var spd := 2.6 + 1.0 * int(level >= 7)
	var dmg_v := dmg((8.0 + 4.0 * int(level >= 3) + 5.0 * int(level >= 6)) * (1.5 if evolved else 1.0))
	orbs.clear()
	for i in n:
		var a := t * spd + TAU * i / n
		var local := Vector2(cos(a), sin(a)) * rad
		orbs.append(local)
		var wp := player.position + local
		for e in game().query(wp, 60.0):
			if e.position.distance_to(wp) < e.radius + 12.0 * area():
				e.take_damage(dmg_v, e.position - player.position, 80.0, "anello", 0.4)
	if evolved:
		_hole_timer -= delta
		if _hole_timer <= 0.0:
			_hole_timer = cd(4.0)
			var tgt := game().nearest(player.position, 400.0, 1)
			var hp: Vector2 = player.position + (tgt[0].position - player.position if tgt.size() > 0 else Vector2(150, 0))
			holes.append({"p": hp, "life": 2.5})
		for h in holes:
			h["life"] -= delta
			for e in game().query(h["p"], 180.0):
				var to: Vector2 = h["p"] - e.position
				if to.length() < 180.0:
					e.position += to.normalized() * 140.0 * delta
					e.take_damage(dmg(6.0), Vector2.ZERO, 0.0, "singolarita", 0.3)
		holes = holes.filter(func(h): return h["life"] > 0.0)


func fire() -> float:
	return 99.0


func _ready() -> void:
	material = Game.additive_material()


func _draw() -> void:
	for i in orbs.size():
		var c := Color.from_hsv(fmod(color().h + i * 0.08 + t * 0.2, 1.0), 0.7, 1.0)
		draw_circle(orbs[i], 18.0 * area(), Color(c, 0.25))
		draw_circle(orbs[i], 9.0 * area(), c)
	for h in holes:
		var lp: Vector2 = h["p"] - player.position
		var k: float = clampf(h["life"], 0.0, 1.0)
		draw_circle(lp, 40.0 * k, Color(0.4, 0.1, 0.8, 0.5 * k))
		for j in 3:
			draw_arc(lp, 60.0 + j * 35.0 - fmod(t * 80.0, 35.0), 0, TAU, 32, Color(0.7, 0.4, 1.0, 0.3 * k), 2.0)
