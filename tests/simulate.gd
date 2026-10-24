extends SceneTree
## Test automatico senza schermo: simula partite con ogni personaggio, tutte le armi ed evoluzioni.
## Uso: godot --headless --path . -s tests/simulate.gd --fixed-fps 60

var main: Node
var phase := 0
var frames := 0
var chars := ["nyx", "myco", "bront", "morv", "zephyr"]
var char_idx := 0
var finished := false
var max_enemies := 0


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _start(id: String) -> void:
	main.start_game(id)
	frames = 0


func _game() -> Game:
	return Game.current


func _process(_delta: float) -> bool:
	frames += 1
	if phase == 0:
		if frames > 5:
			_start(chars[char_idx])
			phase = 1
		return false
	var g := _game()
	if g == null:
		return false
	if g.popup.visible:
		g.popup.close()
	if g.level_up.visible:
		g.level_up._choose(0)
	max_enemies = maxi(max_enemies, g.enemies.size())
	match phase:
		1: # partita normale con ogni personaggio (vita bloccata)
			g.player.hp = g.player.max_hp
			if char_idx == 4 and frames % 120 == 0:
				g.player.try_dash()
			if frames >= (12000 if char_idx == 0 else 2400):
				print("[ok] %s: tempo %s, livello %d, nemici uccisi %d, in campo %d\n%s" % [chars[char_idx], _data().format_time(g.elapsed), g.level, g.kills, g.enemies.size(), g.player.build_summary()])
				char_idx += 1
				if char_idx < chars.size():
					main._end_game()
					_start(chars[char_idx])
				else:
					main._end_game()
					_start("nyx")
					phase = 2
		2: # tutte le armi al massimo ed evolute
			if frames == 2:
				for id in Player.WEAPON_SCRIPTS:
					g.player.add_weapon(id)
					g.player.weapons[id].level = _data().WEAPON_MAX
				for id in _data().PASSIVES:
					g.player.passives[id] = 1
				g.player.recompute_stats()
				var offer := g.player.build_offer()
				print("[ok] offerta con armi al massimo: ", offer.map(func(o): return o["kind"]))
				for id in g.player.weapons:
					g.player.weapons[id].evolve()
				g.elapsed = 400.0
			g.player.hp = g.player.max_hp
			if frames >= 2400:
				print("[ok] evoluzioni: tempo %s, uccisi %d\n%s" % [_data().format_time(g.elapsed), g.kills, g.player.build_summary()])
				g.player.hp = 1.0
				g.player.invuln = 0.0
				g.player.take_damage(50.0)
				phase = 3
		3:
			if not g.running:
				print("[ok] game over raggiunto, picco nemici: ", max_enemies)
				print("[ok] schermata finale: ", main._screen != null)
				return true
	return false


func _data() -> Node:
	return root.get_node("Data")
