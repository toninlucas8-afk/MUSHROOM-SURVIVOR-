class_name Game
extends Node2D
## Partita in corso: crea il mondo, gestisce ondate, esperienza, level up e fine partita.

signal finished(won: bool, summary: Dictionary)

const CELL := 64.0
const MAX_ENEMIES := 320
const MAX_GEMS := 300

static var current: Game

var elapsed := 0.0
var kills := 0
var level := 1
var xp := 0
var xp_next := 4
var pending_levels := 0
var memories_this_run := 0
var enemies: Array[Enemy] = []
var grid := {}
var running := true

var player: Player
var camera: Camera2D
var gems_layer: Node2D
var pickups_layer: Node2D
var enemies_layer: Node2D
var projectiles_layer: Node2D
var effects: Effects
var bg_material: ShaderMaterial
var ui: CanvasLayer
var hud: Hud
var level_up: LevelUp
var popup: StoryPopup
var joystick: Joystick

var _spawn_acc := 0.0
var _next_swarm := 60.0
var _next_boss := 180.0
var _pulse := 0.0


func _ready() -> void:
	current = self
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_background()
	gems_layer = Node2D.new(); add_child(gems_layer)
	pickups_layer = Node2D.new(); add_child(pickups_layer)
	enemies_layer = Node2D.new(); add_child(enemies_layer)
	player = Player.new()
	player.setup(Data.selected_character)
	add_child(player)
	projectiles_layer = Node2D.new()
	projectiles_layer.material = additive_material()
	add_child(projectiles_layer)
	effects = Effects.new()
	add_child(effects)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)
	camera.make_current()
	_build_ui()
	player.add_weapon(Data.CHARACTERS[Data.selected_character]["signature"])
	get_tree().paused = true
	popup.show_text("MYCELIUM: Neon Abyss", Data.INTRO, "INIZIA")


static func additive_material() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m


func _build_background() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_material = ShaderMaterial.new()
	bg_material.shader = load("res://shaders/background.gdshader")
	rect.material = bg_material
	layer.add_child(rect)


func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 10
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui)
	joystick = Joystick.new()
	ui.add_child(joystick)
	hud = Hud.new()
	ui.add_child(hud)
	level_up = LevelUp.new()
	ui.add_child(level_up)
	level_up.chosen.connect(_on_upgrade_chosen)
	popup = StoryPopup.new()
	ui.add_child(popup)
	popup.closed.connect(_on_popup_closed)


func _process(delta: float) -> void:
	if not running:
		return
	elapsed += delta
	_rebuild_grid()
	_spawn(delta)
	camera.position = player.position
	_pulse = maxf(0.0, _pulse - delta * 1.5)
	var vs := get_viewport_rect().size
	bg_material.set_shader_parameter("cam_pos", camera.get_screen_center_position())
	bg_material.set_shader_parameter("screen_size", vs)
	bg_material.set_shader_parameter("intensity", minf(1.0, 0.45 + level * 0.03))
	bg_material.set_shader_parameter("pulse", _pulse)
	if elapsed >= Data.RUN_LENGTH:
		finish(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and running and not level_up.visible and not popup.visible:
		toggle_pause()


func toggle_pause() -> void:
	if popup.visible:
		return
	get_tree().paused = true
	popup.show_text("PAUSA", player.build_summary(), "RIPRENDI")


# ------------------------------------------------------------- griglia spaziale
func _rebuild_grid() -> void:
	grid.clear()
	for e in enemies:
		var k := Vector2i(floori(e.position.x / CELL), floori(e.position.y / CELL))
		if grid.has(k):
			grid[k].append(e)
		else:
			grid[k] = [e]


## Nemici nelle celle che toccano il cerchio (pos, r). Il controllo preciso lo fa chi chiama.
func query(pos: Vector2, r: float) -> Array:
	var out := []
	var x0 := floori((pos.x - r) / CELL)
	var x1 := floori((pos.x + r) / CELL)
	var y0 := floori((pos.y - r) / CELL)
	var y1 := floori((pos.y + r) / CELL)
	for cx in range(x0, x1 + 1):
		for cy in range(y0, y1 + 1):
			var cell = grid.get(Vector2i(cx, cy))
			if cell:
				for e in cell:
					if not e.dead:
						out.append(e)
	return out


func nearest(pos: Vector2, max_dist: float, count: int = 1) -> Array:
	var list := []
	var md2 := max_dist * max_dist
	for e in enemies:
		if e.dead:
			continue
		var d2 := pos.distance_squared_to(e.position)
		if d2 < md2:
			list.append([d2, e])
	list.sort_custom(func(a, b): return a[0] < b[0])
	var out := []
	for i in mini(count, list.size()):
		out.append(list[i][1])
	return out


func enemies_on_screen() -> Array:
	var half := get_viewport_rect().size * 0.5
	var c := camera.get_screen_center_position()
	var rect := Rect2(c - half, half * 2.0)
	return enemies.filter(func(e): return not e.dead and rect.has_point(e.position))


func hit_area(pos: Vector2, radius: float, dmg: float, knock: float = 40.0, color: Color = Color.WHITE, show_ring: bool = true) -> void:
	for e in query(pos, radius + 50.0):
		if e.position.distance_to(pos) < radius + e.radius:
			e.take_damage(dmg, e.position - pos, knock)
	if show_ring:
		effects.ring(pos, radius, color, 0.35)


# ------------------------------------------------------------- ondate
func _spawn_table() -> Array:
	if elapsed < 30.0:
		return [["lumaca", 1]]
	if elapsed < 70.0:
		return [["lumaca", 3], ["zanzara", 2]]
	if elapsed < 140.0:
		return [["lumaca", 3], ["zanzara", 3], ["bruco", 2]]
	if elapsed < 240.0:
		return [["lumaca", 2], ["zanzara", 3], ["bruco", 3], ["occhio", 1]]
	return [["lumaca", 1], ["zanzara", 3], ["bruco", 3], ["occhio", 2]]


func _weighted(table: Array) -> String:
	var tot := 0.0
	for row in table:
		tot += row[1]
	var r := randf() * tot
	for row in table:
		r -= row[1]
		if r <= 0.0:
			return row[0]
	return table[0][0]


func _spawn(delta: float) -> void:
	_spawn_acc += (1.1 + elapsed / 18.0) * delta
	var table := _spawn_table()
	while _spawn_acc >= 1.0:
		_spawn_acc -= 1.0
		if enemies.size() < MAX_ENEMIES:
			spawn_enemy(_weighted(table), offscreen_point())
	if elapsed >= _next_swarm:
		_next_swarm += 60.0
		var n := 24 + int(elapsed / 20.0)
		var rad := get_viewport_rect().size.length() * 0.5 + 40.0
		for i in n:
			var a := TAU * i / n
			spawn_enemy("zanzara", player.position + Vector2(cos(a), sin(a)) * rad)
	if elapsed >= _next_boss:
		_next_boss += 180.0
		spawn_enemy("boss", offscreen_point())
		_pulse = 1.0
		effects.banner("Il Re della Muffa si risveglia...")


func offscreen_point() -> Vector2:
	var a := randf() * TAU
	return player.position + Vector2(cos(a), sin(a)) * (get_viewport_rect().size.length() * 0.5 + 60.0)


func spawn_enemy(type: String, pos: Vector2) -> Enemy:
	var e := Enemy.new()
	e.setup(type, elapsed)
	e.position = pos
	enemies_layer.add_child(e)
	enemies.append(e)
	return e


func on_enemy_killed(e: Enemy) -> void:
	kills += 1
	enemies.erase(e)
	effects.burst(e.position, e.base_color, 60 if e.type == "boss" else 7, 400.0 if e.type == "boss" else 180.0)
	drop_gem(e.position, e.xp_value)
	player.on_kill(e)
	if e.type == "boss":
		for i in 10:
			drop_gem(e.position + Vector2(randf_range(-60, 60), randf_range(-60, 60)), 8)
		spawn_pickup("cuore", e.position + Vector2(24, 0))
		spawn_pickup("memoria", e.position + Vector2(-24, 0))
		_pulse = 1.0
	else:
		var r := randf()
		if r < 0.012:
			spawn_pickup("cuore", e.position)
		elif r < 0.016:
			spawn_pickup("calamita", e.position)


func drop_gem(pos: Vector2, value: int) -> void:
	var count := gems_layer.get_child_count()
	if count > MAX_GEMS:
		var g: Gem = gems_layer.get_child(randi() % count)
		g.value += value
		return
	var gem := Gem.new()
	gem.value = value
	gem.position = pos
	gems_layer.add_child(gem)


func spawn_pickup(kind: String, pos: Vector2) -> void:
	var p := Pickup.new()
	p.kind = kind
	p.position = pos
	pickups_layer.add_child(p)


func collect_pickup(kind: String) -> void:
	match kind:
		"cuore":
			player.heal(30.0)
		"calamita":
			for g in gems_layer.get_children():
				g.pulled = true
		"memoria":
			var idx: int = mini(Data.memories_found, Data.MEMORIES.size() - 1)
			Data.memories_found = mini(Data.memories_found + 1, Data.MEMORIES.size())
			memories_this_run += 1
			Data.save()
			get_tree().paused = true
			var parts: PackedStringArray = Data.MEMORIES[idx].split("\n", true, 1)
			popup.show_text(parts[0], parts[1], "CONTINUA")


# ------------------------------------------------------------- esperienza
func gain_xp(v: int) -> void:
	xp += v
	while xp >= xp_next:
		xp -= xp_next
		level += 1
		xp_next = int(5 + level * 4 + pow(level, 1.65))
		pending_levels += 1
	_try_open_level_up()


func _try_open_level_up() -> void:
	if pending_levels > 0 and running and not level_up.visible and not popup.visible:
		get_tree().paused = true
		level_up.open(player.build_offer())


func _on_upgrade_chosen(option: Dictionary) -> void:
	player.apply_upgrade(option)
	pending_levels -= 1
	get_tree().paused = false
	_pulse = 0.6
	_try_open_level_up()


func _on_popup_closed() -> void:
	if not running:
		return
	get_tree().paused = false
	_try_open_level_up()


func finish(won: bool) -> void:
	if not running:
		return
	running = false
	get_tree().paused = true
	Data.best_time = maxf(Data.best_time, elapsed)
	Data.save()
	finished.emit(won, {
		"time": elapsed, "level": level, "kills": kills, "memories": memories_this_run,
		"build": player.build_summary(), "character": player.char_id,
	})


func _exit_tree() -> void:
	if current == self:
		current = null
