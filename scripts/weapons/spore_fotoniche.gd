extends Weapon
## Spore Fotoniche → Supernova Miceliare


func fire() -> float:
	var count := 1 + int(level >= 2) + int(level >= 4) + int(level >= 6) + int(level >= 8) + player.amount
	if evolved:
		count += 2
	var targets := game().nearest(player.position, 650.0, count)
	if targets.is_empty():
		return 0.2
	var base := 9.0 + 3.0 * int(level >= 3) + 4.0 * int(level >= 7)
	for i in count:
		var tgt: Enemy = targets[i % targets.size()]
		var dir := (tgt.position - player.position).rotated(randf_range(-0.08, 0.08) * i)
		var p := shoot(dir, 520.0 if evolved else 440.0, dmg(base * (1.6 if evolved else 1.0)), 6.0 * area(), (1 if level < 5 else 2) + (3 if evolved else 0), 1.4, color())
		if evolved:
			p.explode_radius = 55.0 * area()
	var c := 0.95 - 0.04 * level - (0.15 if level >= 8 else 0.0)
	return cd(c * (0.6 if evolved else 1.0))
