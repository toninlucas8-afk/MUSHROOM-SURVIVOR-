extends Node
## Dati di gioco (personaggi, armi, passivi, nemici, trama) e salvataggio.
## Autoload "Data": accessibile ovunque come Data.WEAPONS, Data.save_best(), ecc.

const SAVE_PATH := "user://salvataggio.cfg"
const RUN_LENGTH := 900.0 # 15 minuti per completare la spedizione
const WEAPON_MAX := 8
const PASSIVE_MAX := 5
const MAX_SLOTS := 6

# ---------------------------------------------------------------- personaggi
# signature: arma iniziale, che per quel personaggio fa +20% danno (sinergia).
const CHARACTERS := {
	"nyx": {
		"name": "Nyx", "title": "La Spora Fantasma",
		"desc": "Piccola, veloce e letale. Si muove tra i nemici come un'ombra e lascia una scia di spore che esplodono.",
		"ability": "Scia di spore esplosive mentre ti muovi.",
		"cap": Color(0.62, 0.22, 0.95), "spot": Color(0.85, 0.75, 1.0), "eyes": Color(0.3, 1.0, 1.0),
		"scarf": Color(0.35, 0.1, 0.55), "body": Color(0.93, 0.88, 0.8),
		"hp": 80.0, "speed": 1.2, "might": 1.0, "armor": 0.0, "signature": "spore_fotoniche",
	},
	"myco": {
		"name": "Myco", "title": "Il Risvegliato",
		"desc": "Equilibrio perfetto tra forza e agilità. Le sue spore si auto-guidano verso i nemici vicini.",
		"ability": "Tutti i proiettili inseguono i nemici.",
		"cap": Color(0.15, 0.85, 0.85), "spot": Color(1.0, 0.35, 0.7), "eyes": Color(1.0, 0.3, 0.25),
		"scarf": Color(0.1, 0.4, 0.5), "body": Color(0.93, 0.88, 0.8),
		"hp": 100.0, "speed": 1.0, "might": 1.05, "armor": 0.0, "signature": "famiglio_spora",
	},
	"bront": {
		"name": "Bront", "title": "Il Colosso Miceliare",
		"desc": "Gigante e resistente. Scatena onde d'urto di spore e assorbe i danni.",
		"ability": "Onda d'urto ogni 6 secondi. +2 armatura.",
		"cap": Color(0.15, 0.2, 0.6), "spot": Color(0.6, 1.0, 0.2), "eyes": Color(1.0, 0.6, 0.15),
		"scarf": Color(0.2, 0.4, 0.15), "body": Color(0.75, 0.8, 0.7),
		"hp": 160.0, "speed": 0.85, "might": 1.0, "armor": 2.0, "signature": "anello_gravitazionale",
	},
	"morv": {
		"name": "Morv", "title": "Il Micologo Proibito",
		"desc": "Sacrifica la sua salute per potenziare le armi e diffonde zone d'infezione.",
		"ability": "Più vita gli manca, più danno fa (fino a +80%).",
		"cap": Color(0.9, 0.1, 0.35), "spot": Color(1.0, 0.5, 0.8), "eyes": Color(1.0, 0.2, 0.2),
		"scarf": Color(0.45, 0.05, 0.2), "body": Color(0.9, 0.82, 0.8),
		"hp": 90.0, "speed": 1.0, "might": 1.1, "armor": 0.0, "signature": "nebbia_tossica",
	},
	"zephyr": {
		"name": "Zephyr", "title": "Il Viaggiatore",
		"desc": "Controlla la gravità delle spore e si teletrasporta per brevi tratti. Per chi ama il rischio.",
		"ability": "Scatto con Spazio (o tasto sullo schermo). Raccolta x2.",
		"cap": Color(0.3, 0.45, 1.0), "spot": Color(0.7, 0.9, 1.0), "eyes": Color(1.0, 0.45, 0.85),
		"scarf": Color(0.15, 0.2, 0.55), "body": Color(0.85, 0.88, 0.95),
		"hp": 90.0, "speed": 1.05, "might": 1.0, "armor": 0.0, "signature": "fulmine_violetto",
	},
}
const CHARACTER_ORDER := ["nyx", "myco", "bront", "morv", "zephyr"]

# ---------------------------------------------------------------- armi
# levels: testo del potenziamento per i livelli 2..8 (indice 0 = livello 2).
# evo_passive: passivo richiesto (insieme al livello 8) per l'evoluzione.
const WEAPONS := {
	"spore_fotoniche": {
		"name": "Spore Fotoniche", "color": Color(1.0, 0.4, 0.85),
		"desc": "Spara spore di luce al nemico più vicino.",
		"levels": ["+1 spora", "+danno", "+1 spora", "Trapassa 1 nemico in più", "+1 spora", "+danno", "+1 spora, ricarica più rapida"],
		"evo": "Supernova Miceliare", "evo_passive": "metabolismo",
		"evo_desc": "Raffiche di spore che esplodono in piccole supernove.",
	},
	"lame_micelio": {
		"name": "Lame di Micelio", "color": Color(0.7, 1.0, 0.4),
		"desc": "Fendenti di micelio ai tuoi lati.",
		"levels": ["Colpisce anche dietro", "+danno", "+area", "+danno", "+area", "+danno", "+danno, più rapido"],
		"evo": "Corona di Lame Dimensionali", "evo_passive": "potenza",
		"evo_desc": "Una corona di lame che taglia in tutte le direzioni.",
	},
	"nebbia_tossica": {
		"name": "Nebbia Tossica", "color": Color(0.5, 1.0, 0.3),
		"desc": "Una nube velenosa ti circonda e corrode i nemici vicini.",
		"levels": ["+raggio", "+danno", "+raggio", "Rallenta i nemici", "+danno", "+raggio", "+danno"],
		"evo": "Eclissi della Peste", "evo_passive": "espansione",
		"evo_desc": "Un'eclissi oscura: enorme, rallenta molto e infetta chi muore.",
	},
	"fulmine_violetto": {
		"name": "Fulmine Violetto", "color": Color(0.75, 0.4, 1.0),
		"desc": "Fulmini colpiscono nemici a caso intorno a te.",
		"levels": ["+1 fulmine", "+danno", "+area", "+1 fulmine", "+danno", "+1 fulmine", "+danno, più rapido"],
		"evo": "Tempesta Prismatica", "evo_passive": "occhio",
		"evo_desc": "Fulmini arcobaleno che rimbalzano tra i nemici.",
	},
	"cristalli_fungini": {
		"name": "Cristalli Fungini", "color": Color(0.4, 0.85, 1.0),
		"desc": "Un anello di cristalli esplode da te a intervalli.",
		"levels": ["+3 cristalli", "+danno", "Più frequente", "+3 cristalli", "+danno", "Più frequente", "+4 cristalli"],
		"evo": "Cattedrale di Cristallo", "evo_passive": "cappello",
		"evo_desc": "I cristalli tornano indietro come boomerang e trapassano tutto.",
	},
	"anello_gravitazionale": {
		"name": "Anello Gravitazionale", "color": Color(1.0, 0.75, 0.3),
		"desc": "Sfere che orbitano intorno a te.",
		"levels": ["+1 sfera", "+danno", "Orbita più ampia", "+1 sfera", "+danno", "Più veloce", "+1 sfera"],
		"evo": "Singolarità Vivente", "evo_passive": "magnete",
		"evo_desc": "Le sfere generano buchi neri che risucchiano i nemici.",
	},
	"radici_perforanti": {
		"name": "Radici Perforanti", "color": Color(0.95, 0.55, 0.25),
		"desc": "Radici spuntano dal terreno sotto i nemici.",
		"levels": ["+1 radice", "+danno", "+area", "+1 radice", "Durano di più", "+danno", "+1 radice"],
		"evo": "Labirinto Divoratore", "evo_passive": "muschio",
		"evo_desc": "Un labirinto di radici che divora i nemici e ti cura.",
	},
	"famiglio_spora": {
		"name": "Famiglio Spora", "color": Color(0.3, 1.0, 0.8),
		"desc": "Una piccola spora vivente che combatte al tuo fianco.",
		"levels": ["+danno", "Spara più spesso", "+1 famiglio", "+danno", "Spara più spesso", "+1 famiglio", "+danno"],
		"evo": "Sciame Cosciente", "evo_passive": "gambo",
		"evo_desc": "Uno sciame di famigli che caccia da solo.",
	},
}

# ---------------------------------------------------------------- passivi
const PASSIVES := {
	"cappello": {"name": "Cappello Robusto", "desc": "+20% vita massima, +1 armatura", "color": Color(1.0, 0.3, 0.3)},
	"gambo": {"name": "Gambo Veloce", "desc": "+10% velocità di movimento", "color": Color(0.6, 1.0, 0.4)},
	"magnete": {"name": "Micelio Magnetico", "desc": "+35% raggio di raccolta", "color": Color(0.3, 0.8, 1.0)},
	"potenza": {"name": "Spore Concentrate", "desc": "+12% danno", "color": Color(1.0, 0.5, 0.2)},
	"metabolismo": {"name": "Metabolismo Rapido", "desc": "-8% tempo di ricarica", "color": Color(0.4, 1.0, 0.8)},
	"muschio": {"name": "Muschio Curativo", "desc": "+0.4 vita al secondo", "color": Color(0.3, 1.0, 0.4)},
	"espansione": {"name": "Espansione Mentale", "desc": "+12% area degli attacchi", "color": Color(0.8, 0.4, 1.0)},
	"occhio": {"name": "Terzo Occhio", "desc": "+1 proiettile ai livelli 1, 3 e 5", "color": Color(1.0, 0.9, 0.3)},
}

# ---------------------------------------------------------------- nemici
const ENEMIES := {
	"lumaca": {"name": "Lumaca Acida", "hp": 9.0, "speed": 48.0, "radius": 13.0, "damage": 7.0, "xp": 1, "color": Color(0.5, 1.0, 0.3)},
	"zanzara": {"name": "Zanzara Ronzante", "hp": 5.0, "speed": 100.0, "radius": 9.0, "damage": 5.0, "xp": 1, "color": Color(0.3, 0.9, 1.0)},
	"bruco": {"name": "Bruco Ipnotico", "hp": 30.0, "speed": 42.0, "radius": 17.0, "damage": 10.0, "xp": 3, "color": Color(1.0, 0.3, 0.9)},
	"occhio": {"name": "Occhio Fluttuante", "hp": 75.0, "speed": 60.0, "radius": 21.0, "damage": 14.0, "xp": 6, "color": Color(1.0, 0.8, 0.2)},
	"boss": {"name": "Re della Muffa", "hp": 1500.0, "speed": 58.0, "radius": 50.0, "damage": 25.0, "xp": 60, "color": Color(0.6, 0.9, 0.2)},
}

# ---------------------------------------------------------------- trama
const INTRO := "Una rete miceliare antichissima collega ogni organismo del pianeta.\nUna civiltà ha tentato di controllarla per eliminare la morte.\nHa risvegliato invece una coscienza che altera la realtà.\n\nTu sei un fungo mutato. Ricordi solo frammenti.\nSopravvivi, e ricorda."
# Ogni boss sconfitto custodisce un frammento di memoria.
const MEMORIES := [
	"FRAMMENTO I — Il Giardino\nRicordo serre di vetro sotto la città. Gli scienziati chiamavano la rete \"il Paziente\". Dicevano che non poteva morire, e che presto non sarebbe morto nessuno.",
	"FRAMMENTO II — L'Innesto\nCi hanno iniettato le loro memorie. Per questo sogno volti che non ho mai visto. Forse non sono un fungo. Forse sono quello che resta di loro.",
	"FRAMMENTO III — Il Risveglio\nLa rete ha aperto gli occhi. Non odiava nessuno. Ha solo smesso di distinguere tra un uomo, una lumaca e un sogno.",
	"FRAMMENTO IV — La Muffa Reale\nI re della muffa erano i direttori del progetto. Li ha tenuti in vita, come promesso. Per sempre.",
	"FRAMMENTO V — Il Cuore\nIl cuore della rete è vicino. Se lo raggiungo potrò scegliere: spegnerla, o diventare lei.",
]

# ---------------------------------------------------------------- stato condiviso
var selected_character := "nyx"
var best_time := 0.0
var memories_found := 0


func _ready() -> void:
	_setup_input()
	_load()


func _setup_input() -> void:
	var map := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"dash": [KEY_SPACE, KEY_SHIFT], "pause": [KEY_P, KEY_ESCAPE],
		"choose_1": [KEY_1], "choose_2": [KEY_2], "choose_3": [KEY_3], "choose_4": [KEY_4],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best_time = cfg.get_value("record", "best_time", 0.0)
		memories_found = cfg.get_value("trama", "memories_found", 0)
		selected_character = cfg.get_value("scelte", "character", "nyx")


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("record", "best_time", best_time)
	cfg.set_value("trama", "memories_found", memories_found)
	cfg.set_value("scelte", "character", selected_character)
	cfg.save(SAVE_PATH)


static func format_time(t: float) -> String:
	var s := int(t)
	return "%02d:%02d" % [s / 60, s % 60]


## Cerca uno sprite in assets/sprites/<nome>.png: se non c'è si usa il disegno a codice.
static func sprite_for(id: String) -> Texture2D:
	var path := "res://assets/sprites/%s.png" % id
	if ResourceLoader.exists(path):
		return load(path)
	return null
