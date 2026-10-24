extends Weapon
## Cristalli Fungini → Cattedrale di Cristallo: anello di cristalli (poi boomerang perforanti).


func fire() -> float:
	var n := 6 + 3 * int(level >= 2) + 3 * int(level >= 5) + 4 * int(level >= 8) + player.amount * 2
	var base := 11.0 + 4.0 * int(level >= 3) + 5.0 * int(level >= 6)
	var off := randf() * TAU
	for i in n:
		var a := off + TAU * i / n
		var p := shoot(Vector2(cos(a), sin(a)), 340.0, dmg(base * (1.4 if evolved else 1.0)), 7.0 * area(), 99 if evolved else 3, 1.6 if evolved else 1.1, Color.from_hsv(float(i) / n, 0.6, 1.0), "crystal")
		p.boomerang = evolved
	game().effects.ring(player.position, 30.0, color(), 0.5)
	return cd(3.4 - 0.4 * int(level >= 4) - 0.4 * int(level >= 7))
