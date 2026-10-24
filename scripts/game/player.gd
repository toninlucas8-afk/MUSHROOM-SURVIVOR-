class_name Player
extends Node2D
## Il fungo giocante: movimento, statistiche, abilità del personaggio, armi e passivi.

const WEAPON_SCRIPTS := {
	"spore_fotoniche": preload("res://scripts/weapons/spore_fotoniche.gd"),
	"lame_micelio": preload("res://scripts/weapons/lame_micelio.gd"),
	"nebbia_tossica": preload("res://scripts/weapons/nebbia_tossica.gd"),
	"fulmine_violetto": preload("res://scripts/weapons/fulmine_violetto.gd"),
	"cristalli_fungini": preload("res://scripts/weapons/cristalli_fungini.gd"),
	"anello_gravitazionale": preload("res://scripts/weapons/anello_gravitazionale.gd"),
	"radici_perforanti": preload("res://scripts/weapons/radici_perforanti.gd"),
	"famiglio_spora": preload("res://scripts/weapons/famiglio_spora.gd"),
}
const SIZE := 22.0

var char_id := "nyx"
var look: Dictionary
var texture: Texture2D
var radius := 14.0

# statistiche (ricalcolate da personaggio + passivi)
var max_hp := 100.0
var hp := 100.0
var armor := 0.0
var speed := 170.0
var magnet := 90.0
var base_might := 1.0
var cooldown := 1.0
var area := 1.0
var amount := 0
var regen := 0.0

var weapons := {} # id -> Weapon
var passives := {} # id -> livello
var facing := 1.0
var move_dir := Vector2.ZERO
var aim_dir := Vector2.RIGHT
var invuln := 0.0
var _walk := 0.0
var _flash := 0.0
var _trail_timer := 0.0
var _shock_timer := 6.0
var _dash_cd := 0.0
var _dash_time := 0.0
var _dash_dir := Vector2.ZERO
var _t := 0.0


func setup(id: String) -> void:
	char_id = id
	look = Data.CHARACTERS[id]
	texture = Data.sprite_for(id)
	recompute_stats()
	hp = max_hp


var might: float:
	get:
		var m := base_might
		if char_id == "morv":
			m *= 1.0 + 0.8 * (1.0 - hp / max_hp)
		return m


func p(id: String) -> int:
	return passives.get(id, 0)


func recompute_stats() -> void:
	var c: Dictionary = Data.CHARACTERS[char_id]
	var old_max := max_hp
	max_hp = c["hp"] * (1.0 + 0.2 * p("cappello"))
	if max_hp > old_max:
		hp += max_hp - old_max
	hp = minf(hp, max_hp)
	armor = c["armor"] + p("cappello")
	speed = 170.0 * c["speed"] * (1.0 + 0.1 * p("gambo"))
	magnet = 90.0 * (1.0 + 0.35 * p("magnete")) * (2.0 if char_id == "zephyr" else 1.0)
	base_might = c["might"] * (1.0 + 0.12 * p("potenza"))
	cooldown = 1.0 - 0.08 * p("metabolismo")
	regen = 0.4 * p("muschio")
	area = 1.0 + 0.12 * p("espansione")
	amount = (p("occhio") + 1) / 2


func _process(delta: float) -> void:
	_t += delta
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var g := Game.current
	if g and g.joystick and g.joystick.vector != Vector2.ZERO:
		input = g.joystick.vector
	move_dir = input
	if input != Vector2.ZERO:
		aim_dir = input.normalized()
		if absf(input.x) > 0.1:
			facing = signf(input.x)
		_walk += delta * 12.0
	var vel := input * speed
	if _dash_time > 0.0:
		_dash_time -= delta
		vel = _dash_dir * 900.0
	position += vel * delta
	invuln = maxf(0.0, invuln - delta)
	_flash = maxf(0.0, _flash - delta)
	hp = minf(max_hp, hp + regen * delta)
	_character_ability(delta)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dash"):
		try_dash()


func try_dash() -> void:
	if char_id != "zephyr" or _dash_cd > 0.0:
		return
	_dash_cd = 2.5
	_dash_time = 0.16
	_dash_dir = aim_dir
	invuln = maxf(invuln, 0.35)
	Game.current.effects.ring(position, 40.0, look["cap"], 0.3)


func dash_ready() -> float:
	return 1.0 - clampf(_dash_cd / 2.5, 0.0, 1.0)


func _character_ability(delta: float) -> void:
	var g := Game.current
	_dash_cd = maxf(0.0, _dash_cd - delta)
	match char_id:
		"nyx":
			# scia di spore che esplodono dopo poco
			if move_dir != Vector2.ZERO:
				_trail_timer -= delta
				if _trail_timer <= 0.0:
					_trail_timer = 0.35
					g.effects.delayed_blast(position, 0.9, 42.0 * area, 6.0 * might, look["cap"])
		"bront":
			_shock_timer -= delta
			if _shock_timer <= 0.0:
				_shock_timer = 6.0 * cooldown
				g.hit_area(position, 150.0 * area, 15.0 * might, 260.0, look["spot"])


func take_damage(amount_in: float) -> void:
	if invuln > 0.0 or not Game.current.running:
		return
	var dmg: float = maxf(1.0, amount_in - armor)
	hp -= dmg
	invuln = 0.45
	_flash = 0.15
	Game.current.effects.shake(8.0)
	if hp <= 0.0:
		hp = 0.0
		Game.current.finish(false)


func heal(v: float) -> void:
	hp = minf(max_hp, hp + v)
	Game.current.effects.text(position + Vector2(0, -30), "+%d" % int(v), Color(0.4, 1.0, 0.5))


func on_kill(e: Enemy) -> void:
	for w in weapons.values():
		w.on_kill(e)


# ------------------------------------------------------------- armi e passivi
func add_weapon(id: String) -> void:
	if weapons.has(id):
		return
	var w: Weapon = WEAPON_SCRIPTS[id].new()
	w.id = id
	w.player = self
	weapons[id] = w
	add_child(w)


func build_offer() -> Array:
	var evos := []
	var opts := []
	for id in weapons:
		var w: Weapon = weapons[id]
		if w.evolved:
			continue
		if w.level >= Data.WEAPON_MAX:
			if passives.has(Data.WEAPONS[id]["evo_passive"]):
				evos.append({"kind": "evo", "id": id})
		else:
			opts.append({"kind": "weapon", "id": id, "level": w.level + 1})
	if weapons.size() < Data.MAX_SLOTS:
		for id in Data.WEAPONS:
			if not weapons.has(id):
				opts.append({"kind": "weapon", "id": id, "level": 1})
	for id in Data.PASSIVES:
		if passives.has(id):
			if passives[id] < Data.PASSIVE_MAX:
				opts.append({"kind": "passive", "id": id, "level": passives[id] + 1})
		elif passives.size() < Data.MAX_SLOTS:
			opts.append({"kind": "passive", "id": id, "level": 1})
	opts.shuffle()
	var out := evos + opts
	out = out.slice(0, 3)
	if out.is_empty():
		out.append({"kind": "heal"})
	return out


func apply_upgrade(o: Dictionary) -> void:
	match o["kind"]:
		"weapon":
			if weapons.has(o["id"]):
				weapons[o["id"]].level = o["level"]
			else:
				add_weapon(o["id"])
		"evo":
			weapons[o["id"]].evolve()
			Game.current.effects.banner("Evoluzione: " + Data.WEAPONS[o["id"]]["evo"])
		"passive":
			passives[o["id"]] = o["level"]
			recompute_stats()
		"heal":
			heal(40.0)


func build_summary() -> String:
	var lines := PackedStringArray()
	lines.append("%s — %s" % [look["name"], look["title"]])
	for id in weapons:
		var w: Weapon = weapons[id]
		var n: String = Data.WEAPONS[id]["evo"] if w.evolved else Data.WEAPONS[id]["name"]
		lines.append("• %s  %s" % [n, "EVO" if w.evolved else "Lv %d" % w.level])
	for id in passives:
		lines.append("◦ %s  Lv %d" % [Data.PASSIVES[id]["name"], passives[id]])
	return "\n".join(lines)


# ------------------------------------------------------------- disegno
func _draw() -> void:
	var blink := invuln > 0.0 and int(_t * 20.0) % 2 == 0
	if not blink:
		var bob := -absf(sin(_walk)) * 3.0 if move_dir != Vector2.ZERO else sin(_t * 3.0) * 1.2
		if texture:
			var s := SIZE * 3.2
			var rect := Rect2(Vector2(-s * 0.5 * facing, -s * 0.6 + bob), Vector2(s * facing, s))
			draw_texture_rect(texture, rect, false, Color(3, 3, 3) if _flash > 0.0 else Color.WHITE)
		else:
			Art.draw_mushroom(self, Vector2(0, -6), SIZE, look, _t, facing, _flash > 0.0, bob)
	# barra vita
	draw_rect(Rect2(-20, 26, 40, 5), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(-20, 26, 40.0 * hp / max_hp, 5), Color(0.25, 1.0, 0.6) if hp / max_hp > 0.3 else Color(1.0, 0.25, 0.35))
