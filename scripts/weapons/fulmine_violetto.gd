extends Weapon
## Fulmine Violetto → Tempesta Prismatica: colpisce nemici a caso sullo schermo (poi rimbalza).


func fire() -> float:
	var pool := game().enemies_on_screen()
	if pool.is_empty():
		return 0.3
	var strikes := 1 + int(level >= 2) + int(level >= 5) + int(level >= 7) + player.amount + (2 if evolved else 0)
	var base := 16.0 + 6.0 * int(level >= 3) + 7.0 * int(level >= 6) + 8.0 * int(level >= 8)
	var rad := (34.0 + 14.0 * int(level >= 4)) * area()
	for i in strikes:
		var tgt: Enemy = pool.pick_random()
		if evolved:
			_chain(tgt, dmg(base * 1.3), 4, rad)
		else:
			var top := tgt.position + Vector2(randf_range(-30, 30), -420)
			game().effects.bolt(PackedVector2Array([top, tgt.position]), color())
			game().hit_area(tgt.position, rad, dmg(base), 20.0, color())
	return cd(2.4 - 0.25 * int(level >= 8))


func _chain(first: Enemy, damage: float, hops: int, rad: float) -> void:
	var pts := PackedVector2Array([first.position + Vector2(0, -420)])
	var used := {}
	var cur: Enemy = first
	var i := 0
	while cur and i <= hops:
		used[cur.get_instance_id()] = true
		pts.append(cur.position)
		game().hit_area(cur.position, rad, damage, 20.0, Color.from_hsv(randf(), 0.7, 1.0), false)
		var best: Enemy = null
		var bd := 200.0 * 200.0
		for e in game().query(cur.position, 200.0):
			if used.has(e.get_instance_id()):
				continue
			var d2 := cur.position.distance_squared_to(e.position)
			if d2 < bd:
				bd = d2
				best = e
		cur = best
		i += 1
	game().effects.bolt(pts, Color.from_hsv(fmod(t * 0.7, 1.0), 0.8, 1.0))
