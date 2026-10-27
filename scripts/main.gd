extends Node3D
## Fatia técnica da Ilha Cafuné: um pedaço de chão com cidade de um lado e floresta do outro,
## o aventureiro escolhido pelo jogador e alguns esqueletos.
##
## Modos pela linha de comando (depois de "--"):
##   --capture  roda uma sequência automática e salva capturas em tools/capturas/
##   --smoke    roda alguns segundos sem tela, atira num esqueleto e imprime os estados

const CITY := "res://assets/env/city/%s.gltf"
const FOREST := "res://assets/env/forest/%s.gltf"
const CITY_SCALE := 5.0
const FOREST_SCALE := 1.8

## Nomes provisórios até os personagens ganharem nome.
const CHARACTER_LABELS := {
	"menino": "Menino",
	"menina": "Menina",
}
const CHARACTER_ORDER := ["menino", "menina"]

const ENEMY_SPAWNS := [
	["Skeleton_Minion", Vector3(3, 0, -10)],
	["Skeleton_Warrior", Vector3(-4, 0, -14)],
	["Skeleton_Rogue", Vector3(6, 0, -18)],
	["Skeleton_Mage", Vector3(-7, 0, -22)],
]

## Pontos de retorno: o primeiro, no começo, já vem ativo.
const CHECKPOINTS := [Vector3(-5, 0, 3), Vector3(14, 0, -32), Vector3(-18, 0, -28)]

## Chance de um esqueleto desmontado deixar cair um coração (sempre cai se restarem 2 ou menos).
const HEART_DROP_CHANCE := 0.4

const ISLAND_SCENE := "res://scenes/ilha.tscn"
## Mar da ilha (igual ao SEA_LEVEL de tools/gerar_ilha.gd). Abaixo disso, "tchibum": volta na bandeira.
const SEA_LEVEL := -0.6

var arena := false
var island: Node3D
## História na ilha (prólogo, lanternas, ondas); fica nula na arena dos testes.
var story: Story
var boss_bar: BossBar
var objective_marker: ObjectiveMarker
var wave_label: Label
var banner_title: Label
var banner_subtitle: Label
var pause_objective: Label
var _banners: Array = []
var _banner_busy := false
var _splashing := false

## Comandos mostrados no menu de pausa (não ficam mais na tela durante o jogo).
const CONTROLS_KEYBOARD := [
	["Andar", "W A S D"], ["Olhar", "mouse"], ["Pular", "Espaço"], ["Mirar", "botão direito"],
	["Atirar", "botão esquerdo"], ["Recarregar", "R"], ["Granada", "G"], ["Pirulitão (corpo a corpo)", "F ou botão do meio"], ["Kart e skate", "E (entrar e sair)"],
	["Blasters", "1 Paçoca · 2 Granulado · 3 Pipoqueira · 4 Pé-de-Moleque (ou rodinha)"], ["Pausa", "Esc ou Tab"], ["Regiões de impacto", "F3"],
]
const CONTROLS_GAMEPAD := [
	["Andar", "analógico esquerdo"], ["Olhar", "analógico direito"], ["Pular", "A"], ["Mirar", "LT"],
	["Atirar", "RT"], ["Recarregar", "X"], ["Granada", "RB"], ["Pirulitão (corpo a corpo)", "R3 (apertar o analógico direito)"], ["Kart e skate", "B (entrar e sair)"],
	["Blasters", "↑ Paçoca · → Granulado · ↓ Pipoqueira · ← Pé-de-Moleque (Y passa para o próximo)"],
	["Pausa", "Start"], ["Regiões de impacto", "Back"],
]
const MENU_KEYBOARD := "Clique, ou use as setas e Enter"
const MENU_GAMEPAD := "Direcional para escolher, A para confirmar"

var player: Player
var enemies: Array[SkeletonEnemy] = []
var crosshair: Crosshair
## Menus: "inicio" (Continuar, Nova campanha, Sair), "escolha" (personagem; ao começar e pela pausa),
## "pausa", "comandos" e "confirmar" (apagar a campanha). Com menu aberto o jogo fica pausado; a interface
## e a música continuam rodando.
var ui_layer: CanvasLayer
var start_panel: Control
var confirm_panel: Control
var select_panel: Control
var pause_panel: Control
var controls_panel: Control
var controls_label: Label
var menu_dim: ColorRect
var menu_state := ""
var _menu_hints: Array[Label] = []
var _buttons: Array[Button] = []
var _pause_buttons: Array[Button] = []
var _controls_back: Button
var _start_buttons: Array[Button] = []
var _continue_button: Button
var _confirm_text: Label
var _confirm_buttons: Array[Button] = []
var _confirm_action: Callable
var _confirm_return := ""
var _show_regions := false
var _game_started := false
var checkpoints: Array[Checkpoint] = []
var current_checkpoint: Checkpoint
var hearts_bar: HeartsBar
var ammo_hud: WeaponHud
var gallery: ShootingGallery
## Céu, ambiente e sol (o epílogo vira noite e o pós-jogo volta ao dia).
var environment: Environment
var sky_material: ProceduralSkyMaterial
var sun_light: DirectionalLight3D
var ending: Ending
## "Festa sem fim" no cemitério (só no pós-jogo).
var party_mode: EndlessParty
## Lojinha de Blasters (barraca na praia), o menu dela, a seta dourada e o contador de moedas.
var shop: Shop
var shop_menu: ShopMenu
var shop_marker: ObjectiveMarker
var coins_bar: CoinsBar
## Atividades extras: corrida de kart e pista de skate.
var kart_race: KartRace
var skate_park: SkatePark
var message_label: Label
## Aviso fixo embaixo, quando dá para fazer algo com o B (ou E): correr de kart, andar de skate.
var hint_label: Label
var _shop_back_time := -1.0
var _message_tween: Tween
## Chance de um esqueleto desmontado deixar cair uma caixa de munição (sempre cai se a munição estiver no fim).
const AMMO_DROP_CHANCE := 0.5
## Pontos fixos de caixa na arena dos testes.
const ARENA_CRATES := [Vector3(4, 0, 4), Vector3(-6, 0, -2)]
## Segundos para a caixa da ilha voltar depois de pega.
const CRATE_RESPAWN := 45.0
var crates: Array[AmmoPickup] = []
var damage_flash: ColorRect
var fade: ColorRect
var dizzy_label: Label
var heart_drop_chance := HEART_DROP_CHANCE


## Moedas embaixo dos corações (aparece depois da primeira moeda); dá um pulinho quando muda.
class CoinsBar:
	extends Control
	var coins := 0
	var _pulse := 0.0
	var _font: FontVariation

	func _ready() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE
		visible = false
		_font = FontVariation.new()
		_font.base_font = ThemeDB.fallback_font
		_font.variation_embolden = 0.7

	func set_coins(n: int, show: bool) -> void:
		if n != coins:
			_pulse = 1.0
		coins = n
		visible = show
		queue_redraw()

	func _process(delta: float) -> void:
		position = Vector2(get_viewport_rect().size.x - 170.0, 60.0)
		if _pulse > 0.0:
			_pulse = move_toward(_pulse, 0.0, delta * 3.0)
			queue_redraw()

	func _draw() -> void:
		var r := 15.0 * (1.0 + 0.25 * _pulse)
		var c := Vector2(140.0, 18.0)
		draw_circle(c, r, Color("#ffd23f"))
		draw_arc(c, r, 0.0, TAU, 32, Color("#c98a10"), 3.0, true)
		draw_arc(c, r * 0.55, 0.0, TAU, 24, Color("#c98a10"), 2.0, true)
		var text := str(coins)
		var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		var p := Vector2(c.x - r - 8.0 - w, 28.0)
		draw_string_outline(_font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 8, Color(0, 0, 0, 0.75))
		draw_string(_font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#ffe9a8"))


## Corações de vida no canto de cima à direita; o que acabou de ser perdido dá um pulinho.
class HeartsBar:
	extends Control
	var hearts := 5
	var max_hearts := 5
	var _pulse := 0.0
	var _pulse_index := -1

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_hearts(h: int, m: int) -> void:
		if h != hearts:
			_pulse = 1.0
			_pulse_index = mini(h, hearts)
		hearts = h
		max_hearts = m
		queue_redraw()

	func _process(delta: float) -> void:
		position = Vector2(get_viewport_rect().size.x - max_hearts * 46.0 - 12.0, 14.0)
		if _pulse > 0.0:
			_pulse = maxf(0.0, _pulse - delta * 3.0)
			queue_redraw()

	func _draw() -> void:
		for i in max_hearts:
			var center := Vector2(22.0 + i * 46.0, 20.0)
			var s := 18.0 * (1.0 + (0.35 * _pulse if i == _pulse_index else 0.0))
			var pts := PackedVector2Array()
			for k in 32:
				var t := TAU * k / 32.0
				var x := 16.0 * pow(sin(t), 3)
				var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
				pts.append(center + Vector2(x, y) * (s / 17.0))
			var outline := pts.duplicate()
			outline.append(pts[0])
			draw_colored_polygon(pts, Color("#ff4d6d") if i < hearts else Color(1, 1, 1, 0.22))
			draw_polyline(outline, Color(0, 0, 0, 0.55), 3.0, true)


## Mira no centro da tela. Recarregando, ganha um anel que vai se completando;
## com a luneta do Pé-de-Moleque, vira um círculo fino com cruz.
class Crosshair:
	extends Control
	var color := Color.WHITE
	var reload_progress := -1.0
	var scoped := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_delta: float) -> void:
		# Filho direto de CanvasLayer: posiciona pelo tamanho da tela em vez de âncoras.
		position = get_viewport_rect().size * 0.5
		queue_redraw()

	func _draw() -> void:
		var shadow := Color(0, 0, 0, 0.6)
		if scoped:
			draw_arc(Vector2.ZERO, 60.0, 0.0, TAU, 64, shadow, 5.0, true)
			draw_arc(Vector2.ZERO, 60.0, 0.0, TAU, 64, color, 2.0, true)
			for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
				draw_line(d * 10.0, d * 60.0, color, 1.5)
		else:
			for c in [[shadow, 2.0], [color, 0.0]]:
				var col: Color = c[0]
				var w: float = 4.0 + c[1]
				for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
					draw_line(d * 6.0, d * 16.0, col, w)
				draw_circle(Vector2.ZERO, 2.0 + c[1] * 0.5, col)
		if reload_progress >= 0.0:
			draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 48, Color(0, 0, 0, 0.45), 7.0, true)
			draw_arc(Vector2.ZERO, 28.0, -PI / 2.0, -PI / 2.0 + TAU * reload_progress, 48, Color("#9fdcff"), 5.0, true)

	func flash(c: Color) -> void:
		color = c
		queue_redraw()
		var tw := create_tween()
		tw.tween_interval(0.12)
		tw.tween_callback(func() -> void:
			color = Color.WHITE
			queue_redraw())


var music: AudioStreamPlayer


## Os testes automáticos rodam na arena plana (previsível); o jogo de verdade, na ilha.
const TEST_MODES := ["--capture", "--smoke", "--controle", "--combate", "--som", "--armas"]


func _ready() -> void:
	_setup_input()
	Sfx.setup_buses()
	music = Sfx.music(self, "tema")
	music.process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	arena = TEST_MODES.any(func(m: String) -> bool: return m in args)
	# Os testes automáticos nunca mexem na campanha de quem joga (o de salvar usa outro arquivo).
	SaveGame.enabled = not Array(args).any(func(a: String) -> bool: return a.begins_with("--"))
	_build_environment()
	var world := _build_arena() if arena else _load_island()
	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.global_position = world.start
	player.set_yaw(world.start_yaw)
	player.hit_confirmed.connect(_on_hit_confirmed)
	player.input_device_changed.connect(_on_input_device_changed)
	player.health_changed.connect(func(h: int, m: int) -> void: hearts_bar.set_hearts(h, m))
	player.damaged.connect(_on_player_damaged)
	player.dizzy_started.connect(_on_player_dizzy)
	player.ammo_changed.connect(_update_ammo_hud)
	player.out_of_ammo.connect(func() -> void: show_message("Sem munição! Procure uma caixa ou troque de blaster", Color("#ff9d9d"), 1.6))
	player.weapon_locked.connect(_on_weapon_locked)
	for spawn in world.enemies:
		var e := SkeletonEnemy.new()
		e.type_name = spawn[0]
		e.name = spawn[2]
		e.position = spawn[1]
		e.target = player
		if arena:
			e.start_awake = true
			e.aggro_radius = 999.0
			e.leash_radius = 999.0
		e.defeated.connect(_on_enemy_defeated)
		e.tree_exiting.connect(func() -> void: enemies.erase(e))
		add_child(e)
		enemies.append(e)
	for person in world.get("people", []):
		spawn_townsperson(person[0], person[1], person[2])
	for spec in world.get("animals", []):
		var animal := Animal.new()
		animal.name = spec[0]
		animal.model_file = spec[2]
		animal.model_scale = spec[3]
		animal.wander_radius = spec[4]
		animal.shy = spec[5]
		animal.player = player
		animal.position = spec[1]
		add_child(animal)
		animal.visual.rotation.y = randf() * TAU
	for school in world.get("schools", []):
		var kinds: PackedStringArray = school[2]
		for k in kinds.size() + 2:
			var fish := Fish.new()
			fish.model_name = kinds[k % kinds.size()]
			fish.center = school[0]
			fish.radius = school[1] * randf_range(0.45, 1.0)
			fish.depth = randf_range(0.2, 0.5)
			fish.speed = randf_range(0.8, 1.6)
			fish.can_jump = school[3]
			add_child(fish)
	if world.has("gallery"):
		gallery = ShootingGallery.new()
		gallery.name = "TiroAoAlvo"
		gallery.transform = world.gallery
		add_child(gallery)
	for cp_spec in world.checkpoints:
		var cp := Checkpoint.new()
		cp.name = cp_spec[1]
		cp.position = cp_spec[0]
		cp.activated.connect(_on_checkpoint_activated)
		add_child(cp)
		checkpoints.append(cp)
	current_checkpoint = checkpoints[0]
	current_checkpoint.set_active.call_deferred(true, true)
	for pos in world.crates:
		_spawn_crate(pos, CRATE_RESPAWN)
	_build_ui()
	if not arena:
		story = Story.new()
		story.name = "Historia"
		add_child(story)
		story.setup(self, island)
		story.objective_changed.connect(func(text: String) -> void: pause_objective.text = "Objetivo: " + text)
		pause_objective.text = "Objetivo: " + story.objective_text
		ending = Ending.new()
		ending.name = "Desfecho"
		add_child(ending)
		ending.setup(self)
		shop = Shop.new()
		shop.name = "Lojinha"
		shop.game = self
		add_child(shop)
		var sea := SeaTraffic.new()
		sea.name = "Barcos"
		sea.game = self
		add_child(sea)
		var fun := island.get_node("Marcadores/Diversao")
		kart_race = KartRace.new()
		kart_race.name = "CorridaDeKart"
		kart_race.game = self
		kart_race.story = story
		kart_race.paddock = (fun.get_node("Kart") as Node3D).global_position
		kart_race.start = (fun.get_node("KartLargada") as Node3D).global_transform
		for v in fun.get_node("Vagas").get_children():
			kart_race.spots.append((v as Node3D).global_transform)
		add_child(kart_race)
		skate_park = SkatePark.new()
		skate_park.name = "PistaDeSkate"
		skate_park.game = self
		skate_park.story = story
		skate_park.entrance = (fun.get_node("Skate") as Node3D).global_position
		skate_park.center = skate_park.entrance + Vector3(0, 0, -23.0)
		skate_park.session_spot = _ground_point(skate_park.center + Vector3(3.0, 0, 13.0))
		add_child(skate_park)
		story.coins_changed.connect(func(n: int) -> void:
			coins_bar.set_coins(n, story.coins_ever)
			if menu_state == "loja":
				shop_menu.refresh())
	_update_ammo_hud()
	hearts_bar.set_hearts(player.hearts, player.max_hearts)
	_on_input_device_changed(Input.get_connected_joypads().size() > 0)

	if "--capture" in args:
		select_panel.hide()
		player.god_mode = true
		_run_capture()
	elif "--smoke" in args:
		select_panel.hide()
		player.god_mode = true
		_run_smoke()
	elif "--controle" in args:
		player.god_mode = true
		open_menu("escolha")
		_run_gamepad_test()
	elif "--combate" in args:
		select_panel.hide()
		_run_combat_test()
	elif "--som" in args:
		Sfx.logging = true
		open_menu("escolha")
		_run_sound_test()
	elif "--armas" in args:
		select_panel.hide()
		_run_weapons_test()
	elif "--ilha" in args:
		select_panel.hide()
		_run_island_test()
	elif "--ilha-captura" in args:
		select_panel.hide()
		_run_island_capture()
	elif "--historia" in args:
		select_panel.hide()
		_run_story_test()
	elif "--historia-captura" in args:
		select_panel.hide()
		_run_story_capture()
	elif "--mata" in args:
		select_panel.hide()
		_run_forest_test()
	elif "--mata-captura" in args:
		select_panel.hide()
		_run_forest_capture()
	elif "--cemiterio" in args:
		select_panel.hide()
		_run_cemetery_test()
	elif "--cemiterio-captura" in args:
		select_panel.hide()
		_run_cemetery_capture()
	elif "--arte-steam" in args:
		select_panel.hide()
		_run_steam_art()
	elif "--festa-captura" in args:
		select_panel.hide()
		_run_festa_capture()
	elif "--paisagem-captura" in args:
		select_panel.hide()
		_run_landscape_capture()
	elif "--extras" in args:
		select_panel.hide()
		_run_extras_test()
	elif "--extras-captura" in args:
		select_panel.hide()
		_run_extras_capture()
	elif "--pirulito-captura" in args:
		select_panel.hide()
		_run_lollipop_capture()
	elif "--loja-captura" in args:
		select_panel.hide()
		_run_shop_capture()
	elif "--atividades" in args:
		select_panel.hide()
		_run_activities_test()
	elif "--veiculos-captura" in args:
		select_panel.hide()
		_run_vehicles_capture()
	elif "--atividades-captura" in args:
		select_panel.hide()
		_run_activities_capture()
	elif "--mapa-captura" in args:
		select_panel.hide()
		_run_map_capture()
	elif "--banda-captura" in args:
		select_panel.hide()
		_run_band_capture()
	elif "--final" in args:
		select_panel.hide()
		_run_ending_test()
	elif "--final-captura" in args:
		select_panel.hide()
		_run_ending_capture()
	elif "--loja" in args:
		select_panel.hide()
		_run_shop_test()
	elif "--festa-sem-fim" in args:
		select_panel.hide()
		_run_endless_test()
	elif "--salvar" in args:
		select_panel.hide()
		_run_save_test()
	elif SaveGame.go_new:
		# Voltou da "Nova campanha" da pausa: direto para a escolha de personagem.
		SaveGame.go_new = false
		open_menu("escolha")
	elif story:
		open_menu("inicio")
	else:
		open_menu("escolha")


## Arena plana dos testes automáticos (o mapa antigo da fatia técnica).
func _build_arena() -> Dictionary:
	_build_ground()
	_build_city()
	_build_forest()
	var spawns := []
	for spawn in ENEMY_SPAWNS:
		spawns.append([spawn[0], spawn[1], spawn[0]])
	var cps := []
	for k in CHECKPOINTS.size():
		cps.append([CHECKPOINTS[k], "Bandeira%d" % (k + 1)])
	return {"start": Vector3.ZERO, "start_yaw": 0.0, "enemies": spawns, "checkpoints": cps, "crates": ARENA_CRATES}


## A ilha de verdade (scenes/ilha.tscn). Início, bandeiras e esqueletos vêm dos marcadores,
## que dá para mover no editor da Godot.
func _load_island() -> Dictionary:
	island = load(ISLAND_SCENE).instantiate()
	add_child(island)
	var start: Marker3D = island.get_node("Marcadores/Inicio")
	var spawns := []
	for m in island.get_node("Marcadores/Esqueletos").get_children():
		spawns.append([m.get_meta("tipo", "Skeleton_Minion"), m.global_position, m.name])
	var cps := []
	for m in island.get_node("Marcadores/PontosDeRetorno").get_children():
		cps.append([m.global_position, m.name])
	var crate_spots := []
	if island.has_node("Marcadores/Municao"):
		for m in island.get_node("Marcadores/Municao").get_children():
			crate_spots.append(m.global_position)
	var people := []
	if island.has_node("Marcadores/Moradores"):
		for m in island.get_node("Marcadores/Moradores").get_children():
			var spec := {"nome": String(m.name)}
			for key in m.get_meta_list():
				spec[String(key)] = m.get_meta(key)
			people.append([spec, m.global_position + Vector3.UP * (float(spec.get("altura", 0.0)) - 0.1), m.rotation.y])
	var animals := []
	if island.has_node("Marcadores/Animais"):
		for m in island.get_node("Marcadores/Animais").get_children():
			animals.append([m.name, m.global_position, m.get_meta("modelo"), m.get_meta("escala"), m.get_meta("raio"), m.get_meta("timido")])
	var schools := []
	if island.has_node("Marcadores/Cardumes"):
		for m in island.get_node("Marcadores/Cardumes").get_children():
			schools.append([m.global_position, m.get_meta("raio"), m.get_meta("peixes"), m.get_meta("pula")])
	var result := {"start": start.global_position + Vector3.UP * 0.3, "start_yaw": start.rotation.y, "enemies": spawns, "checkpoints": cps,
		"crates": crate_spots, "people": people, "animals": animals, "schools": schools}
	if island.has_node("Marcadores/Diversao/TiroAoAlvo"):
		var g: Marker3D = island.get_node("Marcadores/Diversao/TiroAoAlvo")
		result["gallery"] = Transform3D(g.global_basis, g.global_position - Vector3.UP * 0.1)
	return result


# --- entrada -----------------------------------------------------------------

## Teclado e mouse mais controle. Os nomes de botão seguem o controle de Xbox
## (no de PlayStation: A = X, B = círculo, LT/RT = L2/R2, LB/RB = L1/R1, Back = Share, Start = Options).
func _setup_input() -> void:
	_bind_key("frente", [KEY_W, KEY_UP])
	_bind_key("tras", [KEY_S, KEY_DOWN])
	_bind_key("esquerda", [KEY_A, KEY_LEFT])
	_bind_key("direita", [KEY_D, KEY_RIGHT])
	_bind_axis("frente", JOY_AXIS_LEFT_Y, -1.0)
	_bind_axis("tras", JOY_AXIS_LEFT_Y, 1.0)
	_bind_axis("esquerda", JOY_AXIS_LEFT_X, -1.0)
	_bind_axis("direita", JOY_AXIS_LEFT_X, 1.0)
	_bind_axis("olhar_esquerda", JOY_AXIS_RIGHT_X, -1.0)
	_bind_axis("olhar_direita", JOY_AXIS_RIGHT_X, 1.0)
	_bind_axis("olhar_cima", JOY_AXIS_RIGHT_Y, -1.0)
	_bind_axis("olhar_baixo", JOY_AXIS_RIGHT_Y, 1.0)

	_bind_key("correr", [KEY_SHIFT])
	_bind_button("correr_alternar", JOY_BUTTON_LEFT_STICK)
	_bind_key("pular", [KEY_SPACE])
	_bind_button("pular", JOY_BUTTON_A)
	_bind_mouse("atirar", MOUSE_BUTTON_LEFT)
	_bind_axis("atirar", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_bind_key("recarregar", [KEY_R])
	_bind_button("recarregar", JOY_BUTTON_X)
	_bind_key("granada", [KEY_G])
	_bind_button("granada", JOY_BUTTON_RIGHT_SHOULDER)
	_bind_key("interagir", [KEY_E])
	_bind_button("interagir", JOY_BUTTON_B)
	_bind_key("corpo_a_corpo", [KEY_F])
	_bind_mouse("corpo_a_corpo", MOUSE_BUTTON_MIDDLE)
	_bind_button("corpo_a_corpo", JOY_BUTTON_RIGHT_STICK)
	_bind_mouse("arma_proxima", MOUSE_BUTTON_WHEEL_UP)
	_bind_button("arma_proxima", JOY_BUTTON_Y)
	_bind_mouse("arma_anterior", MOUSE_BUTTON_WHEEL_DOWN)
	for i in Weapons.count():
		_bind_key("arma_%d" % (i + 1), [KEY_1 + i])
		_bind_button("arma_%d" % (i + 1), Weapons.DPAD[i])
	_bind_mouse("mirar", MOUSE_BUTTON_RIGHT)
	_bind_axis("mirar", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_bind_button("mirar", JOY_BUTTON_LEFT_SHOULDER)
	InputMap.action_set_deadzone("atirar", 0.3)
	InputMap.action_set_deadzone("mirar", 0.3)

	_bind_key("regioes", [KEY_F3])
	_bind_button("regioes", JOY_BUTTON_BACK)
	_bind_key("menu", [KEY_TAB, KEY_ESCAPE])
	_bind_button("menu", JOY_BUTTON_START)
	# Na Godot 4.7 os menus aceitam o direcional, mas confirmar e voltar não vêm ligados ao controle.
	_bind_button("ui_accept", JOY_BUTTON_A)
	_bind_button("ui_cancel", JOY_BUTTON_B)


func _ensure_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)


func _bind_key(action: String, keys: Array) -> void:
	_ensure_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func _bind_mouse(action: String, button: MouseButton) -> void:
	_ensure_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


func _bind_button(action: String, button: JoyButton) -> void:
	_ensure_action(action)
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	ev.device = -1
	InputMap.action_add_event(action, ev)


func _bind_axis(action: String, axis: JoyAxis, direction: float) -> void:
	_ensure_action(action)
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = direction
	ev.device = -1
	InputMap.action_add_event(action, ev)


## Recebe a entrada dos menus mesmo com o jogo pausado (o resto do jogo para).
class MenuInput:
	extends Node
	var handler: Callable

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _input(event: InputEvent) -> void:
		handler.call(event)


func _menu_input(event: InputEvent) -> void:
	if get_tree().paused:
		player.detect_device(event)
	var back := event.is_action_pressed("menu") or (menu_state != "" and event.is_action_pressed("ui_cancel"))
	if not back:
		return
	get_viewport().set_input_as_handled()
	match menu_state:
		"":
			if event.is_action_pressed("menu") and not player.dizzy and not (ending and ending.busy()):
				open_menu("pausa")
		"pausa":
			close_menus()
		"comandos":
			open_menu("pausa")
		"confirmar":
			open_menu(_confirm_return)
		"loja":
			# Voltar da prévia leva aos cartões; só fora da prévia fecha a loja. Um segundo aperto colado no
			# primeiro (controle que manda o botão duas vezes) não fecha.
			var now := Time.get_ticks_msec() / 1000.0
			if shop_menu.in_preview():
				shop_menu.back()
				_shop_back_time = now
			elif now - _shop_back_time > 0.35:
				close_menus()
		"escolha":
			# Na abertura do jogo voltar leva ao menu inicial; vindo da pausa, à pausa.
			if _game_started:
				open_menu("pausa")
			elif story:
				open_menu("inicio")


func _unhandled_input(event: InputEvent) -> void:
	if menu_state != "":
		return
	if event is InputEventMouseButton and event.pressed \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("regioes"):
		_toggle_regions()


func open_menu(state: String) -> void:
	menu_state = state
	start_panel.visible = state == "inicio"
	confirm_panel.visible = state == "confirmar"
	shop_menu.visible = state == "loja"
	select_panel.visible = state == "escolha"
	pause_panel.visible = state == "pausa"
	controls_panel.visible = state == "comandos"
	menu_dim.visible = true
	crosshair.hide()
	player.input_enabled = false
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	match state:
		"inicio":
			var has_save := SaveGame.exists()
			_continue_button.visible = has_save
			if has_save:
				_continue_button.text = "Continuar · %s" % SaveGame.stage_label(SaveGame.read().get("etapa", "prologo"))
			(_start_buttons[0] if has_save else _start_buttons[1]).grab_focus.call_deferred()
		"confirmar":
			_confirm_buttons[1].grab_focus.call_deferred()
		"loja":
			story.shop_visited = true
			shop_menu.open()
		"escolha":
			var i := maxi(CHARACTER_ORDER.find(player.character_name), 0)
			_buttons[i].grab_focus.call_deferred()
		"pausa":
			if story:
				story.save()
			_pause_buttons[0].grab_focus.call_deferred()
		"comandos":
			_controls_back.grab_focus.call_deferred()


func close_menus() -> void:
	menu_state = ""
	start_panel.hide()
	confirm_panel.hide()
	shop_menu.hide()
	select_panel.hide()
	pause_panel.hide()
	controls_panel.hide()
	menu_dim.hide()
	crosshair.show()
	get_tree().paused = false
	_game_started = true
	if story and story.stage == "antes":
		story.start()
	if not player.using_gamepad:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Libera o boneco um instante depois, para o A que confirmou o menu não virar pulo.
	get_tree().create_timer(0.2).timeout.connect(func() -> void: player.input_enabled = true)


# --- campanha: continuar e começar de novo ------------------------------------

func open_shop() -> void:
	if story and menu_state == "":
		open_menu("loja")


func _continue_campaign() -> void:
	var data := SaveGame.read()
	if data.is_empty():
		open_menu("escolha")
		return
	story.restore(data)
	close_menus()


## Nova campanha pelo menu inicial: com campanha salva, pede confirmação antes de apagar.
func _new_campaign_from_start() -> void:
	if not SaveGame.exists():
		open_menu("escolha")
		return
	_ask("Começar uma campanha nova? A campanha salva e as fotos do álbum serão apagadas.", "inicio", func() -> void:
		SaveGame.erase()
		open_menu("escolha"))


## Nova campanha pela pausa: apaga, recarrega a ilha do zero e vai para a escolha de personagem.
func _new_campaign_from_pause() -> void:
	_ask("Começar uma campanha nova? Todo o progresso e as fotos do álbum serão apagados.", "pausa", func() -> void:
		SaveGame.erase()
		SaveGame.go_new = true
		get_tree().paused = false
		get_tree().reload_current_scene())


func _ask(text: String, back_to: String, action: Callable) -> void:
	_confirm_text.text = text
	_confirm_return = back_to
	_confirm_action = action
	open_menu("confirmar")


func _quit_game() -> void:
	if story and _game_started:
		story.save()
	get_tree().quit()


## Foto do álbum: a tela do jogo sem a interface (sem tela, nos testes, devolve null).
func capture_view() -> Image:
	if DisplayServer.get_name() == "headless":
		return null
	ui_layer.visible = false
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	ui_layer.visible = true
	return image


## Entrou num veículo (o kart): o aventureiro some, para de colidir e de ler o controle; a câmera é a do veículo.
func enter_vehicle() -> void:
	player.in_vehicle = true
	player.input_enabled = false
	player.visible = false
	player.set_physics_process(false)
	player.collision_layer = 0
	player.velocity = Vector3.ZERO
	crosshair.visible = false
	ammo_hud.visible = false


func exit_vehicle(at: Vector3) -> void:
	player.in_vehicle = false
	player.global_position = at
	player.velocity = Vector3.ZERO
	player.visible = true
	player.set_physics_process(true)
	player.collision_layer = 1 << 1
	player.camera.make_current()
	player.input_enabled = true
	crosshair.visible = true
	ammo_hud.visible = true


## Esconde a mira, os corações, os blasters e a seta do objetivo (cena final e créditos).
func set_hud_visible(on: bool) -> void:
	for node in [crosshair, hearts_bar, ammo_hud, objective_marker, shop_marker, wave_label]:
		(node as CanvasItem).visible = on
	coins_bar.visible = on and story != null and story.coins_ever


func _toggle_regions() -> void:
	_show_regions = not _show_regions
	get_tree().call_group(&"regioes_de_impacto", "set_visible", _show_regions)


# --- mundo -------------------------------------------------------------------

func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#4f9cf0")
	sky_mat.sky_horizon_color = Color("#cfe8ff")
	sky_mat.ground_horizon_color = Color("#cfe8ff")
	sky_mat.ground_bottom_color = Color("#7fb26a")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.1
	if not arena:
		# Na ilha: horizonte de mar e uma névoa leve que dá profundidade ao que está longe.
		sky_mat.ground_bottom_color = Color("#3f9fd8")
		env.fog_enabled = true
		env.fog_light_color = Color("#cfe8ff")
		env.fog_density = 0.0016
		env.fog_sky_affect = 0.0
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	environment = env
	sky_material = sky_mat
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_color = Color("#fff4e0")
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0 if arena else 110.0
	add_child(sun)
	sun_light = sun


## Caiu no mar ou no rio: "tchibum", sem perder coração, e volta na última bandeira.
func _physics_process(_delta: float) -> void:
	if _splashing or not is_instance_valid(player) or player.dizzy:
		return
	if player.global_position.y < SEA_LEVEL - 0.9:
		_splash()


func _splash() -> void:
	_splashing = true
	if skate_park:
		skate_park.splash()
	Fx.bubble_pop(self, player.global_position + Vector3.UP * 0.8)
	Fx.confetti(self, player.global_position + Vector3.UP * 0.8, 20, 4.0)
	Sfx.play(self, "splash", 0.0, 0.0)
	Fx.popup_text(self, player.global_position + Vector3.UP * 2.0, "Tchibum!", Color("#9fdcff"))
	var tw := fade.create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, 0.3)
	await tw.finished
	var hearts_before := player.hearts
	player.respawn(current_checkpoint.spawn_position())
	player.hearts = hearts_before
	player.health_changed.emit(player.hearts, player.max_hearts)
	tw = fade.create_tween()
	tw.tween_property(fade, "modulate:a", 0.0, 0.4)
	await tw.finished
	_splashing = false


func _build_ground() -> void:
	var ground := StaticBody3D.new()
	ground.name = "Chao"
	add_child(ground)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(240, 1, 240)
	shape.shape = box
	shape.position.y = -0.5
	ground.add_child(shape)
	_flat(ground, Vector2(240, 240), Vector3.ZERO, Color("#8cc96b"))
	# Praça clarinha do lado da cidade.
	_flat(ground, Vector2(16, 70), Vector3(14, 0.01, -15), Color("#d9cdb3"))


func _flat(parent: Node3D, size: Vector2, pos: Vector3, color: Color) -> void:
	var plane := PlaneMesh.new()
	plane.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	plane.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	mi.position = pos
	parent.add_child(mi)


func _prop(path: String, pos: Vector3, rot_y_deg: float, s: float, collide: bool) -> Node3D:
	var n: Node3D = load(path).instantiate()
	add_child(n)
	n.position = pos
	n.rotation_degrees.y = rot_y_deg
	n.scale = Vector3.ONE * s
	if collide:
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).create_trimesh_collision()
	return n


## Cidade do City Builder Bits, ampliada: o pacote foi feito para jogo de construir cidade
## visto de cima, então em escala original os prédios ficam menores que os personagens.
func _build_city() -> void:
	for i in 7:
		var z := -45.0 + i * 10.0
		var road := _prop(CITY % "road_straight", Vector3(26, -0.45, z), 0.0, CITY_SCALE, false)
		road.name = "Rua_%d" % i
	var buildings := ["building_A", "building_B", "building_C", "building_D", "building_E", "building_F", "building_G"]
	for i in buildings.size():
		_prop(CITY % buildings[i], Vector3(38, 0, -45.0 + i * 10.0), -90.0, CITY_SCALE, true)
	for i in 4:
		_prop(CITY % "streetlight", Vector3(20.5, 0, -40.0 + i * 15.0), 0.0, CITY_SCALE, true)
	# Os carros têm as rodas 7,2 cm abaixo da origem do modelo: sobem 0,36 m na escala 5.
	_prop(CITY % "car_taxi", Vector3(24, 0.36, -20), 0.0, CITY_SCALE, true)
	_prop(CITY % "car_police", Vector3(28, 0.36, 0), 180.0, CITY_SCALE, true)
	_prop(CITY % "bench", Vector3(9, 0, -6), 90.0, CITY_SCALE, true)
	_prop(CITY % "firehydrant", Vector3(10, 0, -24), 0.0, CITY_SCALE, true)
	_prop(CITY % "trash_A", Vector3(9.5, 0, -30), 0.0, CITY_SCALE, true)
	_prop(CITY % "dumpster", Vector3(18, 0, -34), 90.0, CITY_SCALE, true)
	_prop(CITY % "box_A", Vector3(4, 0, -6), 20.0, CITY_SCALE, true)


func _build_forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var trees := ["Tree_1_A_Color1", "Tree_2_A_Color1", "Tree_3_A_Color1", "Tree_4_A_Color1", "Tree_1_B_Color1", "Tree_2_C_Color1"]
	var placed: Array[Vector3] = []
	var tries := 0
	while placed.size() < 28 and tries < 400:
		tries += 1
		var p := Vector3(rng.randf_range(-48, -11), 0, rng.randf_range(-55, 25))
		var ok := true
		for q in placed:
			if p.distance_to(q) < 6.0:
				ok = false
				break
		if ok:
			placed.append(p)
			_prop(FOREST % trees[rng.randi() % trees.size()], p, rng.randf_range(0, 360), FOREST_SCALE * rng.randf_range(0.85, 1.2), true)
	for i in 14:
		var rock := "Rock_%d_%s_Color1" % [rng.randi_range(1, 3), "ABCDE"[rng.randi() % 5]]
		_prop(FOREST % rock, Vector3(rng.randf_range(-40, -9), 0, rng.randf_range(-45, 15)), rng.randf_range(0, 360), FOREST_SCALE * rng.randf_range(0.8, 1.4), true)
	for i in 24:
		var bush := "Bush_%d_A_Color1" % rng.randi_range(1, 4)
		_prop(FOREST % bush, Vector3(rng.randf_range(-46, -6), 0, rng.randf_range(-50, 20)), rng.randf_range(0, 360), FOREST_SCALE, false)
	for i in 70:
		var grass := "Grass_%d_%s_Color1" % [rng.randi_range(1, 2), "ABCD"[rng.randi() % 4]]
		_prop(FOREST % grass, Vector3(rng.randf_range(-46, 8), 0, rng.randf_range(-50, 20)), rng.randf_range(0, 360), FOREST_SCALE, false)


# --- interface ---------------------------------------------------------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	ui_layer = layer
	var menu_input := MenuInput.new()
	menu_input.handler = _menu_input
	add_child(menu_input)
	crosshair = Crosshair.new()
	layer.add_child(crosshair)

	damage_flash = _overlay(layer, Color(1.0, 0.25, 0.3))
	fade = _overlay(layer, Color(0.05, 0.05, 0.12))
	dizzy_label = Label.new()
	dizzy_label.text = "Tonto! Voltando para a bandeira..."
	dizzy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dizzy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dizzy_label.add_theme_font_size_override("font_size", 40)
	dizzy_label.add_theme_constant_override("outline_size", 12)
	dizzy_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	dizzy_label.add_theme_color_override("font_color", Color("#ffd23f"))
	dizzy_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dizzy_label.visible = false
	layer.add_child(dizzy_label)
	dizzy_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	hearts_bar = HeartsBar.new()
	layer.add_child(hearts_bar)
	ammo_hud = WeaponHud.new()
	layer.add_child(ammo_hud)
	objective_marker = ObjectiveMarker.new()
	layer.add_child(objective_marker)
	objective_marker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shop_marker = ObjectiveMarker.new()
	shop_marker.coin = true
	layer.add_child(shop_marker)
	shop_marker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	coins_bar = CoinsBar.new()
	layer.add_child(coins_bar)
	boss_bar = BossBar.new()
	layer.add_child(boss_bar)
	wave_label = _hud_label(layer, 26, Color.WHITE)
	banner_title = _hud_label(layer, 40, Color("#ffd23f"))
	banner_subtitle = _hud_label(layer, 22, Color.WHITE)
	for l in [banner_title, banner_subtitle]:
		l.modulate.a = 0.0
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 30)
	message_label.add_theme_constant_override("outline_size", 10)
	message_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_label.modulate.a = 0.0
	layer.add_child(message_label)
	message_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	message_label.offset_top = -190
	message_label.offset_bottom = -150
	message_label.offset_left = -400
	message_label.offset_right = 400
	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 30)
	hint_label.add_theme_constant_override("outline_size", 10)
	hint_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	hint_label.add_theme_color_override("font_color", Color("#ffd23f"))
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label.visible = false
	layer.add_child(hint_label)
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint_label.offset_top = -250
	hint_label.offset_bottom = -205
	hint_label.offset_left = -500
	hint_label.offset_right = 500

	menu_dim = _overlay(layer, Color(0.03, 0.04, 0.08))
	menu_dim.modulate.a = 0.45
	menu_dim.hide()

	# Foco bem visível: quem joga de controle precisa enxergar de longe qual botão está marcado.
	var focus_style := StyleBoxFlat.new()
	focus_style.draw_center = false
	focus_style.set_border_width_all(5)
	focus_style.border_color = Color("#ffd23f")
	focus_style.set_corner_radius_all(6)
	focus_style.set_expand_margin_all(3)

	# Menu inicial: continuar a campanha salva, começar uma nova ou sair.
	var sbox := _menu_box(layer, "Ilha Cafuné")
	start_panel = sbox.get_parent().get_parent()
	(sbox.get_child(0) as Label).add_theme_font_size_override("font_size", 44)
	(sbox.get_child(0) as Label).add_theme_color_override("font_color", Color("#ffd23f"))
	var tagline := Label.new()
	tagline.text = "A véspera da Festa do Cafuné"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 18)
	tagline.add_theme_color_override("font_color", Color("#d9a8ff"))
	sbox.add_child(tagline)
	for spec in [["Continuar", _continue_campaign], ["Nova campanha", _new_campaign_from_start], ["Sair do jogo", _quit_game]]:
		var b := _menu_button(spec[0], focus_style)
		b.pressed.connect(func() -> void:
			Sfx.play(ui_layer, "ui_ok", 0.0, 0.0)
			spec[1].call())
		sbox.add_child(b)
		_start_buttons.append(b)
	_continue_button = _start_buttons[0]
	_add_menu_hint(sbox)

	# Confirmação antes de apagar a campanha.
	var qbox := _menu_box(layer, "Nova campanha")
	confirm_panel = qbox.get_parent().get_parent()
	_confirm_text = Label.new()
	_confirm_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_text.custom_minimum_size = Vector2(380, 0)
	_confirm_text.add_theme_font_size_override("font_size", 19)
	qbox.add_child(_confirm_text)
	for spec in [["Sim, começar do zero", func() -> void: _confirm_action.call()], ["Voltar", func() -> void: open_menu(_confirm_return)]]:
		var b := _menu_button(spec[0], focus_style)
		b.pressed.connect(func() -> void:
			Sfx.play(ui_layer, "ui_ok", 0.0, 0.0)
			spec[1].call())
		qbox.add_child(b)
		_confirm_buttons.append(b)

	var box := _menu_box(layer, "Escolha quem vai jogar")
	select_panel = box.get_parent().get_parent()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	box.add_child(grid)
	for i in CHARACTER_ORDER.size():
		var key: String = CHARACTER_ORDER[i]
		var button := Button.new()
		button.text = CHARACTER_LABELS[key]
		button.custom_minimum_size = Vector2(220, 56)
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_stylebox_override("focus", focus_style)
		button.pressed.connect(_choose_character.bind(key))
		button.focus_entered.connect(func() -> void: Sfx.play(ui_layer, "ui_mover", 0.0, 0.0))
		grid.add_child(button)
		_buttons.append(button)
	_add_menu_hint(box)

	# Pausa: continuar, trocar de personagem, ver os comandos, começar de novo ou sair.
	var pbox := _menu_box(layer, "Pausa")
	pause_panel = pbox.get_parent().get_parent()
	pause_objective = Label.new()
	pause_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pause_objective.custom_minimum_size = Vector2(320, 0)
	pause_objective.add_theme_font_size_override("font_size", 18)
	pause_objective.add_theme_color_override("font_color", Color("#d9a8ff"))
	pbox.add_child(pause_objective)
	var pause_specs := [["Continuar", close_menus], ["Trocar de personagem", open_menu.bind("escolha")],
			["Comandos", open_menu.bind("comandos")], ["Nova campanha", _new_campaign_from_pause], ["Sair do jogo", _quit_game]]
	if arena:
		pause_specs.remove_at(3)
	for spec in pause_specs:
		var b := _menu_button(spec[0], focus_style)
		b.pressed.connect(func() -> void:
			Sfx.play(ui_layer, "ui_ok", 0.0, 0.0)
			spec[1].call())
		pbox.add_child(b)
		_pause_buttons.append(b)
	_add_menu_hint(pbox)

	# Comandos: a lista do aparelho em uso (teclado e mouse ou controle).
	var cbox := _menu_box(layer, "Comandos")
	controls_panel = cbox.get_parent().get_parent()
	controls_label = Label.new()
	controls_label.add_theme_font_size_override("font_size", 19)
	cbox.add_child(controls_label)
	_controls_back = _menu_button("Voltar", focus_style)
	_controls_back.pressed.connect(func() -> void:
		Sfx.play(ui_layer, "ui_ok", 0.0, 0.0)
		open_menu("pausa"))
	cbox.add_child(_controls_back)
	shop_menu = ShopMenu.new()
	shop_menu.game = self
	shop_menu.focus_style = focus_style
	layer.add_child(shop_menu)
	shop_menu.build()
	for panel_root in [start_panel, confirm_panel, select_panel, pause_panel, controls_panel, shop_menu]:
		panel_root.hide()


func _hud_label(layer: CanvasLayer, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_constant_override("outline_size", maxi(8, font_size / 3))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(l)
	return l


## Faixa grande no alto da tela (título e subtítulo). Várias seguidas entram em fila.
func banner(title: String, subtitle := "", color := Color("#ffd23f"), seconds := 3.2) -> void:
	_banners.append([title, subtitle, color, seconds])
	if not _banner_busy:
		_next_banner()


func _next_banner() -> void:
	if _banners.is_empty():
		_banner_busy = false
		return
	_banner_busy = true
	var b: Array = _banners.pop_front()
	banner_title.text = b[0]
	banner_title.add_theme_color_override("font_color", b[2])
	banner_subtitle.text = b[1]
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(banner_title, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(banner_subtitle, "modulate:a", 1.0, 0.25)
	tw.tween_interval(b[3])
	tw.tween_property(banner_title, "modulate:a", 0.0, 0.4)
	tw.parallel().tween_property(banner_subtitle, "modulate:a", 0.0, 0.4)
	tw.tween_callback(_next_banner)


## Apertou um blaster que ainda não tem: diz onde se ganha.
func _on_weapon_locked(id: String) -> void:
	var def := Weapons.find(id)
	var price := Weapons.price(id)
	var text := "%s: compre na Lojinha de Blasters, na beira da praia (%d moedas)" % [def.nome, price] if story and price > 0 \
			else "%s: ainda não é seu" % def.nome
	show_message(text, Color(1, 1, 1, 0.9), 1.8)
	Sfx.play(self, "sem_municao", 0.0, 0.0)


func show_guardian(b: Boss) -> void:
	boss_bar.track(b)
	banner(b.display_name, b.subtitle, Color("#ff9d7a"), 2.2)


func hide_guardian() -> void:
	boss_bar.release()


func activate_checkpoint(cp_name: String) -> void:
	for cp in checkpoints:
		if cp.name == cp_name:
			_on_checkpoint_activated(cp)


## Esqueleto de onda: sai de uma rachadura e persegue por toda a região.
func spawn_wave_enemy(type_name: String, pos: Vector3) -> SkeletonEnemy:
	var e := SkeletonEnemy.new()
	e.type_name = type_name
	e.from_crack = true
	e.start_awake = true
	e.aggro_radius = 999.0
	e.leash_radius = 999.0
	e.target = player
	e.set_meta("onda", true)
	e.defeated.connect(_on_enemy_defeated)
	e.tree_exiting.connect(func() -> void: enemies.erase(e))
	add_child(e)
	e.global_position = pos
	enemies.append(e)
	return e


## Cria um morador. spec usa os nomes dos metadados do marcador: modelo, atividade, variante, item,
## falas e destino (para quem anda).
func spawn_townsperson(spec: Dictionary, pos: Vector3, yaw: float) -> Townsperson:
	var t := Townsperson.new()
	t.name = spec.get("nome", "Morador")
	t.model_name = spec.get("modelo", "Farmer_A")
	t.model_path = spec.get("modelo_caminho", "")
	t.model_scale = spec.get("escala", 1.0)
	t.hide_meshes = spec.get("esconder", PackedStringArray())
	t.item_scale = spec.get("item_escala", 1.0)
	t.activity = spec.get("atividade", "parado")
	t.variant = spec.get("variante", "")
	t.item = spec.get("item", "")
	t.item_rotation = spec.get("item_rot", Vector3.ZERO)
	t.lines = spec.get("falas", PackedStringArray())
	t.walk_to = spec.get("destino", Vector3.INF)
	t.player = player
	t.position = pos
	add_child(t)
	t.visual.rotation.y = yaw
	return t


func add_boss(b: Boss, pos: Vector3) -> void:
	b.target = player
	add_child(b)
	b.global_position = pos


## Caixa de menu centralizada: CenterContainer > PanelContainer > VBox com título. Devolve a VBox.
func _menu_box(layer: CanvasLayer, title_text: String) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	box.add_child(title)
	return box


func _menu_button(text: String, focus_style: StyleBox) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 52)
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_stylebox_override("focus", focus_style)
	b.focus_entered.connect(func() -> void: Sfx.play(ui_layer, "ui_mover", 0.0, 0.0))
	return b


func _add_menu_hint(box: VBoxContainer) -> void:
	var label := Label.new()
	label.text = MENU_KEYBOARD
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	box.add_child(label)
	_menu_hints.append(label)


## Retângulo de tela cheia transparente, para clarão e escurecer.
func _overlay(layer: CanvasLayer, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.modulate.a = 0.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return rect


func _on_player_damaged() -> void:
	damage_flash.modulate.a = 0.25
	var tw := damage_flash.create_tween()
	tw.tween_property(damage_flash, "modulate:a", 0.0, 0.35)


## Tonto: deita com estrelinhas, a tela escurece e o aventureiro volta na última bandeira.
func _on_player_dizzy() -> void:
	dizzy_label.visible = true
	await _wait(2.4)
	var tw := fade.create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, 0.4)
	await tw.finished
	player.respawn(current_checkpoint.spawn_position())
	player.set_yaw(0.0)
	# Os esqueletos voltam para os seus lugares e acordam de novo: ninguém reaparece cercado.
	for e in enemies:
		e.reset_to_spawn()
	await _wait(0.25)
	dizzy_label.visible = false
	tw = fade.create_tween()
	tw.tween_property(fade, "modulate:a", 0.0, 0.5)


func _on_checkpoint_activated(cp: Checkpoint) -> void:
	if cp == current_checkpoint:
		return
	current_checkpoint.set_active(false, true)
	current_checkpoint = cp
	cp.set_active(true)
	player.rumble(0.3, 0.1, 0.15)
	if story and _game_started:
		story.save()


func _on_enemy_defeated(e: SkeletonEnemy) -> void:
	var wave := e.has_meta("onda")
	var heart_chance := 0.12 if wave else heart_drop_chance
	var crate_chance := 0.15 if wave else AMMO_DROP_CHANCE
	if player.hearts <= (1 if wave else 2) or randf() < heart_chance:
		var heart := HeartPickup.new()
		heart.position = e.global_position
		add_child(heart)
	if player.limited_ammo_fraction() < (0.12 if wave else 0.25) or randf() < crate_chance:
		var crate := AmmoPickup.new()
		crate.dropped = true
		crate.position = e.global_position + e.visual.global_basis.x * 1.4
		add_child(crate)


func _spawn_crate(pos: Vector3, respawn: float) -> AmmoPickup:
	var crate := AmmoPickup.new()
	crate.position = pos
	crate.respawn = respawn
	add_child(crate)
	crates.append(crate)
	return crate


func _update_ammo_hud() -> void:
	if ammo_hud:
		ammo_hud.refresh(player)


## Mensagem rápida no meio de baixo da tela (troca de blaster, munição acabou).
func show_message(text: String, color := Color.WHITE, seconds := 1.2) -> void:
	message_label.text = text
	message_label.add_theme_color_override("font_color", color)
	if _message_tween:
		_message_tween.kill()
	message_label.modulate.a = 1.0
	_message_tween = message_label.create_tween()
	_message_tween.tween_interval(seconds)
	_message_tween.tween_property(message_label, "modulate:a", 0.0, 0.4)


func _process(_delta: float) -> void:
	if is_instance_valid(player) and crosshair:
		crosshair.reload_progress = player.reload_progress()
		crosshair.scoped = player.is_zoomed()
		ammo_hud.refresh(player)
	if story and is_instance_valid(player):
		var d := story.running_defense()
		var hud := ""
		if d:
			hud = d.hud_text()
		elif is_instance_valid(party_mode) and party_mode.running():
			hud = party_mode.hud_text()
		elif kart_race and kart_race.driving():
			hud = kart_race.hud_text()
		elif skate_park and skate_park.riding():
			hud = skate_park.hud_text()
		wave_label.text = hud
		var button := "B" if player.using_gamepad else "E"
		var hint := ""
		if menu_state == "" and kart_race and kart_race.state == "a_pe" and kart_race.nearest:
			hint = "Aperte %s para dirigir: %s" % [button, kart_race.nearest.display_name]
		elif menu_state == "" and skate_park and skate_park.state == "a_pe" and skate_park.near:
			hint = "Aperte %s para pegar o skate" % button
		hint_label.text = hint
		hint_label.visible = hint != ""
		var view := get_viewport().get_visible_rect().size
		var top := 96.0 if boss_bar.visible else 24.0
		wave_label.position = Vector2(view.x * 0.5 - wave_label.size.x * 0.5, top)
		banner_title.position = Vector2(view.x * 0.5 - banner_title.size.x * 0.5, view.y * 0.2)
		banner_subtitle.position = Vector2(view.x * 0.5 - banner_subtitle.size.x * 0.5, view.y * 0.2 + 56.0)
		var show_target := menu_state == "" and not (ending and ending.busy())
		var view_cam := get_viewport().get_camera_3d()
		objective_marker.update_marker(view_cam, story.objective_target if show_target else Vector3.INF, player.global_position)
		shop_marker.update_marker(view_cam, story.shop_target() if show_target else Vector3.INF, player.global_position)


func _choose_character(key: String) -> void:
	player.set_character(key)
	Sfx.play(ui_layer, "ui_ok", 0.0, 0.0)
	close_menus()
	if story and story.stage != "antes":
		story.save()


func _on_input_device_changed(gamepad: bool) -> void:
	for label in _menu_hints:
		label.text = MENU_GAMEPAD if gamepad else MENU_KEYBOARD
	if controls_label:
		var lines := PackedStringArray()
		for row in (CONTROLS_GAMEPAD if gamepad else CONTROLS_KEYBOARD):
			lines.append("%s:  %s" % row)
		controls_label.text = "\n".join(lines)


func _on_hit_confirmed(region: String, _damage: float) -> void:
	crosshair.flash(Color("#ffd23f") if region == "cabeça" else Color("#ff5d5d"))
	Sfx.play(self, "acerto_cabeca" if region == "cabeça" else "acerto")


# --- modos automáticos -------------------------------------------------------

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _aim_for(target: Node3D, height: float, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		if is_instance_valid(target):
			player.aim_at(target.global_position + Vector3.UP * height)
		await get_tree().physics_frame
		t += get_physics_process_delta_time()


func _shot(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://tools/capturas/")
	DirAccess.make_dir_recursive_absolute(dir)
	# A Godot não deve importar as capturas como recursos do jogo.
	if not FileAccess.file_exists(dir + ".gdignore"):
		FileAccess.open(dir + ".gdignore", FileAccess.WRITE).store_string("")
	get_viewport().get_texture().get_image().save_png(dir + file_name)
	print("captura: ", file_name)


func _run_capture() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var minion := enemies[0]
	# Close no blaster primeiro, com os esqueletos escondidos para não taparem a vista.
	for e in enemies:
		e.visible = false
	player.force_aim = true
	var close := Camera3D.new()
	add_child(close)
	for i in Weapons.count():
		player.switch_weapon(i)
		await _wait(0.8)
		var hand: Node3D = player.model.find_child("MaoDireita", true, false)
		close.global_position = hand.global_position + player.visual.global_basis * Vector3(-1.8, 0.5, 1.0)
		close.look_at(hand.global_position + player.visual.global_basis.z * 0.3)
		close.current = true
		await _shot("00_blaster_close_%d_%s.png" % [i + 1, Weapons.get_def(i).id])
	close.queue_free()
	player.switch_weapon(0)
	player.camera.current = true
	player.force_aim = false
	for e in enemies:
		e.visible = true
	await _wait(0.6)
	await _shot("01_inicio.png")
	await _wait(1.5)
	player.force_aim = true
	await _aim_for(minion, 1.0, 0.6)
	await _shot("02_mirando.png")
	player.fire()
	await _wait(0.04)
	await _shot("03_tiro.png")
	# Sequência do coice, de lado: antes, no pico e voltando (esqueletos escondidos para não taparem).
	for e in enemies:
		e.visible = false
	var side := Camera3D.new()
	add_child(side)
	var hand_node: Node3D = player.model.find_child("MaoDireita", true, false)
	side.global_position = hand_node.global_position + player.visual.global_basis * Vector3(-2.2, 0.3, 0.6)
	side.look_at(hand_node.global_position + player.visual.global_basis.z * 0.4)
	side.current = true
	await _wait(0.5)
	await _shot("03a_coice_antes.png")
	player.fire()
	await get_tree().physics_frame
	await get_tree().physics_frame
	await _shot("03b_coice_pico.png")
	await _wait(0.12)
	await _shot("03c_coice_voltando.png")
	side.queue_free()
	player.camera.current = true
	for e in enemies:
		e.visible = true
	# Se o esqueleto chegou colado, a mira não aponta tão para baixo: o personagem recua antes.
	var away := player.global_position - minion.global_position
	away.y = 0.0
	if away.length() < 5.0:
		player.global_position = minion.global_position + away.normalized() * 7.0 + Vector3.UP * 0.2
	var tries := 0
	while minion.state != SkeletonEnemy.State.INDO_EMBORA and tries < 40:
		await _aim_for(minion, 1.0, 0.25)
		player.fire()
		tries += 1
	if minion.state != SkeletonEnemy.State.INDO_EMBORA:
		minion.take_hit(99.0, minion.global_position + Vector3.UP * 2.0, minion.hurtboxes[0])
	await _wait(0.9)
	await _shot("04_balao_enchendo.png")
	_toggle_regions()
	await _aim_for(enemies[1], 1.0, 0.5)
	await _shot("05_regioes.png")
	_toggle_regions()
	await _aim_for(minion, 2.5, 1.2)
	await _shot("06_balao_subindo.png")
	player.force_aim = false
	for key in CHARACTER_ORDER:
		player.set_character(key)
		await _wait(0.6)
		await _shot("07_%s.png" % key)
	# Combate: armas dos esqueletos, flecha voando, golpe recebido, tonto e volta na bandeira.
	player.set_character("menino")
	var warrior := enemies[1]
	await _aim_for(warrior, 1.4, 0.5)
	await _shot("10_armas_esqueletos.png")
	var rogue := enemies[2]
	player.god_mode = false
	var t := 0.0
	while _projectiles(Projectile.Kind.FLECHA).is_empty() and t < 12.0:
		player.hearts = player.max_hearts
		player.aim_at(rogue.global_position + Vector3.UP * 1.2)
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	await _wait(0.12)
	await _shot("11_flecha.png")
	await _wait_until(func() -> bool: return player.hearts < player.max_hearts, 10.0)
	await _wait(0.05)
	await _shot("12_golpe.png")
	player.hearts = 1
	player._invulnerable = 0.0
	await _wait_until(func() -> bool: return player.dizzy, 15.0)
	await _wait(1.2)
	await _shot("13_tonto.png")
	await _wait_until(func() -> bool: return not player.dizzy and fade.modulate.a < 0.05, 8.0)
	player.god_mode = true
	await _shot("14_bandeira.png")
	# Armas: blaster de duas mãos, recarga, luneta, granada e caixa de munição.
	# Longe da bandeira inicial, para o poste não ficar entre a câmera e o aventureiro.
	player.god_mode = true
	player.global_position = Vector3(3, 0.2, -2)
	player.force_aim = true
	var target := enemies[1]
	player.switch_weapon(1)
	await _wait(0.5)
	await _aim_for(target, 1.2, 0.4)
	player.fire()
	await _wait(0.05)
	await _shot("15_granulado.png")
	player.reload()
	await _wait(0.6)
	await _shot("16_recarga.png")
	await _wait(1.2)
	player.switch_weapon(3)
	await _wait(0.9)
	await _aim_for(target, 1.4, 0.3)
	await _shot("17_luneta.png")
	player.switch_weapon(2)
	await _wait(0.5)
	await _aim_for(target, 1.0, 0.3)
	player.fire()
	await _wait(0.05)
	await _shot("18_pipoqueira.png")
	player.force_aim = false
	player.switch_weapon(0)
	await _wait(0.4)
	await _aim_for(target, -1.0, 0.3)
	player.throw_grenade()
	await _wait(1.88)
	await _shot("19_granada.png")
	await _wait(0.5)
	var crate := AmmoPickup.new()
	crate.dropped = true
	crate.position = player.global_position + (-player.camera.global_basis.z * Vector3(1, 0, 1)).normalized() * 4.0
	add_child(crate)
	await _wait(0.6)
	await _shot("20_caixa.png")
	# Com controle: as dicas mudam e o menu abre com foco num botão.
	_joy_axis(JOY_AXIS_LEFT_X, 0.6)
	await get_tree().physics_frame
	_joy_axis(JOY_AXIS_LEFT_X, 0.0)
	await _wait(0.3)
	await _shot("08_hud_controle.png")
	open_menu("escolha")
	await _joy_button(JOY_BUTTON_DPAD_RIGHT)
	await _wait(0.2)
	await _shot("09_menu_controle.png")
	open_menu("pausa")
	await _wait(0.2)
	await _shot("09b_pausa.png")
	open_menu("comandos")
	await _wait(0.2)
	await _shot("09c_comandos.png")
	get_tree().quit()


func _joy_axis(axis: JoyAxis, value: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.device = 0
	ev.axis = axis
	ev.axis_value = value
	Input.parse_input_event(ev)


func _joy_button(button: JoyButton) -> void:
	for pressed in [true, false]:
		var ev := InputEventJoypadButton.new()
		ev.device = 0
		ev.button_index = button
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await get_tree().physics_frame
		await get_tree().physics_frame


func _check(label: String, ok: bool, detail: String = "") -> bool:
	print("%s %s %s" % ["OK    " if ok else "FALHOU", label, detail])
	return ok


## Joga só com eventos de controle simulados (como se viessem de um controle de verdade)
## e confere cada comando. Uso: godot --headless --path . -- --controle
func _run_gamepad_test() -> void:
	var all_ok := true
	await _wait(0.5)

	# Menu: começa aberto, com foco num botão; direcional muda o foco; A confirma.
	all_ok = _check("menu abre com foco", select_panel.visible and get_viewport().gui_get_focus_owner() is Button) and all_ok
	var focus_before := get_viewport().gui_get_focus_owner()
	await _joy_button(JOY_BUTTON_DPAD_RIGHT)
	var focus_after := get_viewport().gui_get_focus_owner()
	all_ok = _check("direcional move o foco no menu", focus_after != focus_before,
			"(%s -> %s)" % [focus_before.text, focus_after.text if focus_after else "nada"]) and all_ok
	await _joy_button(JOY_BUTTON_A)
	await _wait(0.3)
	all_ok = _check("A escolhe o aventureiro e fecha o menu", not select_panel.visible,
			"(agora: %s)" % player.character_name) and all_ok
	all_ok = _check("jogo detectou o controle", player.using_gamepad, "(dica do menu: %s)" % _menu_hints[0].text) and all_ok

	# Analógico direito gira a câmera.
	var yaw0 := player.get_yaw()
	_joy_axis(JOY_AXIS_RIGHT_X, 1.0)
	await _wait(0.5)
	_joy_axis(JOY_AXIS_RIGHT_X, 0.0)
	var turned := rad_to_deg(player.get_yaw() - yaw0)
	all_ok = _check("analógico direito gira a câmera", turned < -30.0, "(%.0f graus em 0,5 s)" % turned) and all_ok
	player.set_yaw(yaw0)

	# Analógico esquerdo anda.
	var p0 := player.global_position
	_joy_axis(JOY_AXIS_LEFT_Y, -1.0)
	await _wait(0.6)
	_joy_axis(JOY_AXIS_LEFT_Y, 0.0)
	var walked := p0.distance_to(player.global_position)
	all_ok = _check("analógico esquerdo anda", walked > 1.5, "(%.1f m em 0,6 s)" % walked) and all_ok
	await _wait(0.3)

	# L3 liga a corrida enquanto anda; parar de andar desliga.
	var p1 := player.global_position
	_joy_axis(JOY_AXIS_LEFT_Y, -1.0)
	await _joy_button(JOY_BUTTON_LEFT_STICK)
	var p_sprint := player.global_position
	await _wait(0.6)
	var sprinted := p_sprint.distance_to(player.global_position)
	var was_sprinting := player.sprinting
	_joy_axis(JOY_AXIS_LEFT_Y, 0.0)
	await _wait(0.3)
	all_ok = _check("L3 corre mais rápido que andar", was_sprinting and sprinted > walked * 1.3 and not player.sprinting,
			"(%.1f m em 0,6 s; andando %.1f m)" % [sprinted, walked]) and all_ok
	await _wait(0.2)

	# A pula.
	var y0 := player.global_position.y
	var ev := InputEventJoypadButton.new()
	ev.device = 0
	ev.button_index = JOY_BUTTON_A
	ev.pressed = true
	Input.parse_input_event(ev)
	await _wait(0.2)
	var jumped := player.global_position.y - y0
	ev = ev.duplicate()
	ev.pressed = false
	Input.parse_input_event(ev)
	all_ok = _check("A pula", jumped > 0.5, "(subiu %.1f m)" % jumped) and all_ok
	await _wait(1.0)

	# LT mira; o auxílio de mira traz a mira de volta para o corpo de um esqueleto.
	var target: SkeletonEnemy = null
	for e in enemies:
		if e.state == SkeletonEnemy.State.PERSEGUINDO or e.state == SkeletonEnemy.State.ESPERANDO:
			target = e
			break
	var body: Hurtbox = null
	for hb in target.hurtboxes:
		if hb.aim_assist:
			body = hb
	_joy_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
	await _wait(0.4)
	all_ok = _check("LT mira", player.aiming) and all_ok
	# Congela o esqueleto durante a medição, para o alvo não andar.
	target.set_physics_process(false)
	target.ap.pause()
	await _aim_for(body, 0.0, 0.4)
	player.set_yaw(player.get_yaw() + deg_to_rad(5.0))
	await get_tree().physics_frame
	var angle0 := rad_to_deg((-player.camera.global_basis.z).angle_to(body.aim_point() - player.camera.global_position))
	await _wait(0.8)
	var angle1 := rad_to_deg((-player.camera.global_basis.z).angle_to(body.aim_point() - player.camera.global_position))
	all_ok = _check("auxílio de mira puxa para o alvo", angle1 < angle0 * 0.4, "(%.1f° -> %.1f° em 0,8 s)" % [angle0, angle1]) and all_ok
	target.set_physics_process(true)
	target.ap.play()

	# RT atira.
	var shots_before := target.health
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _wait(0.5)
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_joy_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	all_ok = _check("RT atira e acerta", target.health < shots_before or target.state == SkeletonEnemy.State.INDO_EMBORA,
			"(vida %.0f -> %.0f, %s)" % [shots_before, target.health, SkeletonEnemy.State.keys()[target.state]]) and all_ok

	# Cada seta do direcional pega um blaster (o personagem só muda pelo menu de pausa).
	var c0 := player.character_name
	var picked: Array[String] = []
	for button in [JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_UP]:
		await _joy_button(button)
		picked.append(player.current_weapon().id)
		await _wait(0.35)
	all_ok = _check("direcional: → Granulado, ↓ Pipoqueira, ← Pé-de-Moleque, ↑ Paçoca",
			picked == ["granulado", "pipoqueira", "pe_de_moleque", "pacoca"] and player.character_name == c0, "(%s)" % ", ".join(picked)) and all_ok

	# X recarrega, Y troca de blaster, RB joga granada.
	player.fire()
	player.fire()
	await _joy_button(JOY_BUTTON_X)
	all_ok = _check("X recarrega", player.reloading, "(pente %d)" % player.mag()) and all_ok
	await _wait_until(func() -> bool: return not player.reloading, 3.0)
	var weapon_before := player.weapon_index
	await _joy_button(JOY_BUTTON_Y)
	all_ok = _check("Y troca de blaster", player.weapon_index != weapon_before, "(%s)" % player.current_weapon().nome) and all_ok
	await _wait(0.4)
	var grenades_before := player.grenades
	await _joy_button(JOY_BUTTON_RIGHT_SHOULDER)
	all_ok = _check("RB joga granada", player.grenades == grenades_before - 1) and all_ok
	await _wait(0.4)
	await _joy_button(JOY_BUTTON_RIGHT_STICK)
	all_ok = _check("R3 dá o golpe do Pirulitão", player._melee_cooldown > 0.0 and player._lollipop.visible) and all_ok
	await _wait(1.0)

	# Back mostra as regiões; Start abre e fecha o menu.
	await _joy_button(JOY_BUTTON_BACK)
	all_ok = _check("Back mostra as regiões de impacto", _show_regions) and all_ok
	await _joy_button(JOY_BUTTON_BACK)
	await _joy_button(JOY_BUTTON_START)
	all_ok = _check("Start abre a pausa e pausa o jogo", pause_panel.visible and get_tree().paused and not player.input_enabled
			and get_viewport().gui_get_focus_owner() == _pause_buttons[0]) and all_ok
	# Pausa > Trocar de personagem > o outro personagem.
	var before := player.character_name
	await _joy_button(JOY_BUTTON_DPAD_DOWN)
	await _joy_button(JOY_BUTTON_A)
	all_ok = _check("pausa leva à escolha de personagem", select_panel.visible and get_tree().paused) and all_ok
	await _joy_button(JOY_BUTTON_DPAD_RIGHT if before == CHARACTER_ORDER[0] else JOY_BUTTON_DPAD_LEFT)
	await _joy_button(JOY_BUTTON_A)
	await _wait(0.3)
	all_ok = _check("troca de personagem pela pausa e volta ao jogo", player.character_name != before and not get_tree().paused
			and player.input_enabled, "(%s -> %s)" % [before, player.character_name]) and all_ok
	# Start abre, B volta ao jogo; Start abre, Start fecha.
	await _joy_button(JOY_BUTTON_START)
	await _joy_button(JOY_BUTTON_B)
	await _wait(0.3)
	all_ok = _check("B fecha a pausa", menu_state == "" and not get_tree().paused) and all_ok
	await _joy_button(JOY_BUTTON_START)
	await _joy_button(JOY_BUTTON_START)
	await _wait(0.3)
	all_ok = _check("Start fecha a pausa e solta o boneco", menu_state == "" and not get_tree().paused and player.input_enabled) and all_ok

	print("CONTROLE OK" if all_ok else "CONTROLE COM FALHAS")
	get_tree().quit()


func _wait_until(cond: Callable, timeout: float) -> float:
	var t := 0.0
	while not cond.call() and t < timeout:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	return t


func _projectiles(kind: Projectile.Kind) -> Array:
	return get_children().filter(func(n: Node) -> bool: return n is Projectile and n.kind == kind)


## Deixa os esqueletos atacarem de verdade e confere o ciclo de combate.
## Uso: godot --headless --path . -- --combate
func _run_combat_test() -> void:
	var all_ok := true
	var melee_names := ["Skeleton_Minion", "Skeleton_Warrior"]

	# 1. Os três jeitos de atacar acertam o aventureiro parado. A vida é reposta a cada golpe
	#    para ele não ficar tonto antes da hora.
	var sources := {}
	var t := 0.0
	while t < 30.0 and not (sources.has("flecha") and sources.has("bolha") and sources.keys().any(func(s: String) -> bool: return s in melee_names)):
		if player.hearts < player.max_hearts:
			sources[player.last_hit_by] = sources.get(player.last_hit_by, 0) + 1
			player.hearts = player.max_hearts
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	all_ok = _check("esqueleto bate de perto", sources.keys().any(func(s: String) -> bool: return s in melee_names), "(golpes: %s em %.0f s)" % [sources, t]) and all_ok
	all_ok = _check("flecha de ventosa acerta", sources.has("flecha")) and all_ok
	all_ok = _check("bolha mágica acerta", sources.has("bolha")) and all_ok

	# 2. Invulnerável logo depois de um golpe.
	player._invulnerable = 0.0
	player.take_damage(1, player.global_position + Vector3.FORWARD, "teste")
	var h := player.hearts
	player.take_damage(1, player.global_position + Vector3.FORWARD, "teste")
	all_ok = _check("fica invulnerável logo depois do golpe", player.hearts == h, "(%d corações)" % h) and all_ok

	# 3. Um tiro estoura a bolha.
	player.god_mode = true
	await _wait_until(func() -> bool: return not _projectiles(Projectile.Kind.BOLHA).is_empty(), 10.0)
	var bubbles := _projectiles(Projectile.Kind.BOLHA)
	var popped := false
	if not bubbles.is_empty():
		var bubble: Projectile = bubbles[0]
		player.force_aim = true
		var tt := 0.0
		while is_instance_valid(bubble) and tt < 3.0:
			player.aim_at(bubble.global_position)
			await get_tree().physics_frame
			await get_tree().physics_frame
			if is_instance_valid(bubble):
				player.aim_at(bubble.global_position)
				player.fire()
			tt += 0.1
		popped = not is_instance_valid(bubble)
		player.force_aim = false
	all_ok = _check("tiro estoura a bolha", popped) and all_ok

	# 4. Sem corações fica tonto, os esqueletos comemoram e ele volta na bandeira com vida cheia.
	player.god_mode = false
	player.hearts = 1
	player._invulnerable = 0.0
	await _wait_until(func() -> bool: return player.dizzy, 15.0)
	all_ok = _check("sem corações fica tonto", player.dizzy, "(golpe de %s)" % player.last_hit_by) and all_ok
	await _wait(0.6)
	all_ok = _check("esqueletos comemoram", enemies.any(func(e: SkeletonEnemy) -> bool: return e.state == SkeletonEnemy.State.COMEMORANDO)) and all_ok
	await _wait_until(func() -> bool: return not player.dizzy, 6.0)
	var spot := current_checkpoint.spawn_position()
	all_ok = _check("volta na bandeira com vida cheia", not player.dizzy and player.hearts == player.max_hearts and player.global_position.distance_to(spot) < 1.5,
			"(%d corações, a %.1f m do ponto)" % [player.hearts, player.global_position.distance_to(spot)]) and all_ok

	# 5. Passar perto de outra bandeira troca o ponto de retorno.
	player.god_mode = true
	player.global_position = checkpoints[1].global_position + Vector3(0, 0.1, 0.8)
	await _wait(0.4)
	all_ok = _check("bandeira nova vira o ponto de retorno", current_checkpoint == checkpoints[1]) and all_ok
	player.god_mode = false
	player.hearts = 1
	player._invulnerable = 0.0
	player.take_damage(1, player.global_position + Vector3.FORWARD, "teste")
	await _wait_until(func() -> bool: return not player.dizzy, 6.0)
	all_ok = _check("volta na bandeira nova", player.global_position.distance_to(checkpoints[1].spawn_position()) < 1.5) and all_ok

	# 6. Coração no chão: pega se faltar vida; com vida cheia ele fica lá.
	player.god_mode = true
	player.hearts = 3
	var heart := HeartPickup.new()
	heart.position = player.global_position
	add_child(heart)
	await _wait(0.8)
	all_ok = _check("coração devolve vida", player.hearts == 4 and not is_instance_valid(heart), "(%d corações)" % player.hearts) and all_ok
	player.hearts = player.max_hearts
	var spare := HeartPickup.new()
	spare.position = player.global_position
	add_child(spare)
	await _wait(0.8)
	all_ok = _check("com vida cheia o coração fica no chão", is_instance_valid(spare)) and all_ok
	spare.queue_free()

	# 7. Com 2 corações ou menos, esqueleto desmontado sempre deixa um coração.
	player.hearts = 2
	var minion := enemies[0]
	await _wait_until(func() -> bool: return minion.state != SkeletonEnemy.State.ACORDANDO, 8.0)
	var count_hearts := func() -> int:
		return get_children().filter(func(n: Node) -> bool: return n is HeartPickup and not n.is_queued_for_deletion()).size()
	var before: int = count_hearts.call()
	minion.take_hit(99.0, minion.global_position + Vector3.UP * 2.0, minion.hurtboxes[0])
	await get_tree().physics_frame
	var after: int = count_hearts.call()
	all_ok = _check("esqueleto desmontado deixa coração", after == before + 1) and all_ok

	print("COMBATE OK" if all_ok else "COMBATE COM FALHAS")
	get_tree().quit()


## Confere que os arquivos de som carregam, a música repete e cada evento dispara o som certo.
## Uso: godot --headless --path . -- --som
func _run_sound_test() -> void:
	var all_ok := true
	var missing: Array[String] = []
	for sfx_name in Sfx.ALL:
		var s := Sfx.stream(sfx_name)
		if s == null or s.get_length() <= 0.0:
			missing.append(sfx_name)
	all_ok = _check("os %d efeitos carregam" % Sfx.ALL.size(), missing.is_empty(), "(faltando: %s)" % ", ".join(missing) if missing else "") and all_ok
	all_ok = _check("canais Musica e Efeitos existem", AudioServer.get_bus_index(Sfx.BUS_MUSIC) != -1 and AudioServer.get_bus_index(Sfx.BUS_SFX) != -1) and all_ok
	var wav := music.stream as AudioStreamWAV
	all_ok = _check("música tocando em loop", music.playing and wav.loop_mode == AudioStreamWAV.LOOP_FORWARD and wav.loop_end > 0,
			"(%.1f s)" % wav.get_length()) and all_ok

	var heard := func(sfx_name: String) -> bool: return sfx_name in Sfx.played
	# Menu: mover o foco e confirmar.
	await _wait(0.3)
	Sfx.played.clear()
	await _joy_button(JOY_BUTTON_DPAD_RIGHT)
	await _joy_button(JOY_BUTTON_A)
	await _wait(0.3)
	all_ok = _check("menu: mover e confirmar", heard.call("ui_mover") and heard.call("ui_ok")) and all_ok

	# Tiro, acerto na cabeça e esqueleto indo embora de balão.
	player.god_mode = true
	var minion := enemies[0]
	await _wait_until(func() -> bool: return minion.state == SkeletonEnemy.State.PERSEGUINDO or minion.state == SkeletonEnemy.State.ESPERANDO, 6.0)
	Sfx.played.clear()
	player.force_aim = true
	while minion.state != SkeletonEnemy.State.INDO_EMBORA and Sfx.played.count("tiro") < 15:
		await _aim_for(minion.hurtboxes[0], 0.0, 0.25)
		player.fire()
	all_ok = _check("tiro e acerto", heard.call("tiro") and (heard.call("acerto_cabeca") or heard.call("acerto")),
			"(%s)" % ", ".join(Sfx.played.slice(0, 6))) and all_ok
	player.force_aim = false
	await _wait_until(func() -> bool: return heard.call("balao"), 2.0)
	all_ok = _check("balão do esqueleto indo embora", heard.call("balao")) and all_ok

	# Ataques dos esqueletos: aviso, golpe de perto, flecha, bolha e o que acontece quando batem.
	Sfx.played.clear()
	player.god_mode = false
	var t := 0.0
	while t < 30.0 and not (heard.call("golpe_ar") and heard.call("flecha") and heard.call("bolha") and heard.call("bonk")):
		player.hearts = player.max_hearts
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	all_ok = _check("aviso e ataques dos esqueletos", heard.call("alerta") and heard.call("golpe_ar") and heard.call("flecha") and heard.call("bolha"),
			"(%.0f s)" % t) and all_ok
	all_ok = _check("golpe no aventureiro e flecha ou bolha batendo", heard.call("bonk") and (heard.call("ventosa") or heard.call("estouro"))) and all_ok

	# Tonto, reaparecer, bandeira e coração.
	Sfx.played.clear()
	player.hearts = 1
	player._invulnerable = 0.0
	await _wait_until(func() -> bool: return player.dizzy, 15.0)
	await _wait_until(func() -> bool: return not player.dizzy, 6.0)
	all_ok = _check("tonto e reaparecer", heard.call("tonto") and heard.call("reaparecer")) and all_ok
	player.god_mode = true
	player.global_position = checkpoints[2].global_position + Vector3(0, 0.1, 0.8)
	await _wait(0.4)
	player.hearts = 3
	var heart := HeartPickup.new()
	heart.position = player.global_position
	add_child(heart)
	await _wait(0.8)
	all_ok = _check("bandeira e coração", heard.call("bandeira") and heard.call("coracao")) and all_ok
	var jumped_before := Sfx.played.count("pulo")
	var ev := InputEventJoypadButton.new()
	ev.device = 0
	ev.button_index = JOY_BUTTON_A
	ev.pressed = true
	Input.parse_input_event(ev)
	await _wait(0.2)
	ev = ev.duplicate()
	ev.pressed = false
	Input.parse_input_event(ev)
	all_ok = _check("pulo", Sfx.played.count("pulo") > jumped_before) and all_ok

	# Armas: recarga, troca, granada, caixa e munição acabada.
	Sfx.played.clear()
	player.fire()
	player.reload()
	await _wait(1.3)
	player.switch_weapon(1)
	await _wait(0.4)
	player.throw_grenade()
	await _wait(2.2)
	player.ammo.granulado.mag = 0
	player.ammo.granulado.reserve = 0
	player.fire()
	var crate := AmmoPickup.new()
	crate.position = player.global_position
	add_child(crate)
	await _wait(0.6)
	all_ok = _check("recarga, troca, granada, caixa e sem munição", heard.call("recarga") and heard.call("troca_arma") and heard.call("arremesso")
			and heard.call("granada") and heard.call("sem_municao") and heard.call("municao"), "(%s)" % ", ".join(Sfx.played)) and all_ok

	print("SOM OK" if all_ok else "SOM COM FALHAS")
	get_tree().quit()


func _enemy(name_prefix: String) -> SkeletonEnemy:
	for e in enemies:
		if e.name.begins_with(name_prefix):
			return e
	return null


## Anda segurando "frente" com a câmera virada para um ponto, por alguns segundos.
func _walk_toward(target: Vector3, seconds: float) -> void:
	var d := target - player.global_position
	player.set_yaw(atan2(-d.x, -d.z))
	Input.action_press("frente")
	await _wait(seconds)
	Input.action_release("frente")


## Confere a ilha de verdade: chão, esqueletos dormindo e acordando, voltar para casa,
## subir o Morro, atravessar a ponte, cair no rio e bandeiras. Uso: godot --headless --path . -- --ilha
func _run_island_test() -> void:
	var all_ok := true
	player.god_mode = true
	await _wait(1.0)
	var start: Vector3 = island.get_node("Marcadores/Inicio").global_position
	all_ok = _check("aventureiro de pé no chão da praça", player.is_on_floor() and absf(player.global_position.y - start.y) < 1.0,
			"(y %.2f, marcador %.2f)" % [player.global_position.y, start.y]) and all_ok
	var markers := island.get_node("Marcadores/Esqueletos").get_child_count()
	var sleeping := enemies.filter(func(e: SkeletonEnemy) -> bool: return e.state == SkeletonEnemy.State.DORMINDO).size()
	all_ok = _check("esqueletos dos marcadores, todos dormindo", enemies.size() == markers and sleeping == markers,
			"(%d marcadores, %d dormindo)" % [markers, sleeping]) and all_ok
	all_ok = _check("bandeiras dos marcadores", checkpoints.size() == island.get_node("Marcadores/PontosDeRetorno").get_child_count(),
			"(%d)" % checkpoints.size()) and all_ok
	all_ok = _check("caixas de munição dos marcadores", crates.size() == island.get_node("Marcadores/Municao").get_child_count() and crates.size() > 0,
			"(%d)" % crates.size()) and all_ok

	# Chegar perto acorda só quem está perto.
	var minion := _enemy("Minion_01")
	player.global_position = minion.global_position + Vector3(0, 0.5, 9)
	await _wait(0.6)
	var others_asleep := enemies.filter(func(e: SkeletonEnemy) -> bool: return e != minion and e.global_position.distance_to(minion.global_position) > 30.0).all(
			func(e: SkeletonEnemy) -> bool: return e.state == SkeletonEnemy.State.DORMINDO)
	all_ok = _check("chegar perto acorda o esqueleto", minion.state != SkeletonEnemy.State.DORMINDO, "(%s)" % SkeletonEnemy.State.keys()[minion.state]) and all_ok
	all_ok = _check("quem está longe continua dormindo", others_asleep) and all_ok
	await _wait(3.0)

	# Ir para longe: ele volta para casa e deita de novo.
	var home := minion._spawn_point
	player.global_position = checkpoints[0].spawn_position()
	await _wait_until(func() -> bool: return minion.state == SkeletonEnemy.State.DORMINDO, 40.0)
	all_ok = _check("longe demais, volta para casa e dorme", minion.state == SkeletonEnemy.State.DORMINDO and minion.global_position.distance_to(home) < 2.5,
			"(a %.1f m de casa)" % minion.global_position.distance_to(home)) and all_ok

	# Subir a encosta do Morro andando.
	var slope := Vector3(0, 0, 0)
	for t in 36:
		var a := TAU * t / 36.0
		var p := Vector3(cos(a) * 62.0, 0, sin(a) * 62.0)
		if p.z < 60.0:
			slope = p
			break
	player.global_position = slope + Vector3(0, 30, 0)
	await _wait(1.5)
	var y0 := player.global_position.y
	await _walk_toward(Vector3(0, 26, 0), 3.0)
	all_ok = _check("dá para subir a encosta do Morro andando", player.global_position.y > y0 + 3.0,
			"(subiu %.1f m em 3 s)" % (player.global_position.y - y0)) and all_ok

	# Atravessar a ponte para a mata.
	var bridge: Node3D = island.get_node("Ponte")
	var south := Vector3(0, 2, -92)
	player.global_position = south
	await _wait(1.0)
	await _walk_toward(Vector3(0, 0, -140), 7.0)
	all_ok = _check("atravessa a ponte até a mata", player.global_position.z < -128.0 and player.global_position.y > SEA_LEVEL and not _splashing,
			"(z %.1f, y %.2f)" % [player.global_position.z, player.global_position.y]) and all_ok
	await _wait(0.5)

	# Cair no rio: tchibum e volta na bandeira, sem perder coração.
	var hearts_before := player.hearts
	player.global_position = Vector3(45, 1.0, -112.0 + 9.0 * sin(45.0 / 38.0))
	await _wait_until(func() -> bool: return _splashing, 4.0)
	await _wait_until(func() -> bool: return not _splashing, 4.0)
	all_ok = _check("caiu no rio, tchibum e volta na bandeira", player.global_position.distance_to(current_checkpoint.spawn_position()) < 2.0 and player.hearts == hearts_before,
			"(bandeira %s)" % current_checkpoint.name) and all_ok

	# Bandeira do topo do Morro.
	var top: Checkpoint = checkpoints.filter(func(c: Checkpoint) -> bool: return c.name == "TopoDoMorro")[0]
	player.global_position = top.global_position + Vector3(0, 0.5, 1.0)
	await _wait(0.6)
	all_ok = _check("bandeira do topo do Morro vira ponto de retorno", current_checkpoint == top) and all_ok

	print("ILHA OK" if all_ok else "ILHA COM FALHAS")
	get_tree().quit()


## Fotos jogando na ilha (precisa de janela). Uso: godot --path . -- --ilha-captura
func _run_island_capture() -> void:
	player.god_mode = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _wait(1.0)
	await _shot("ilha_jogo_01_praca.png")
	# Minion_04 fica na rua norte (z = 110), que corre de leste a oeste: a câmera vem pela rua.
	var minion := _enemy("Minion_04")
	player.global_position = minion.global_position + Vector3(20, 0.5, 0)
	await _aim_for(minion, 0.3, 0.3)
	await _shot("ilha_jogo_02_esqueleto_dormindo.png")
	player.global_position = minion.global_position + Vector3(10, 0.5, 0)
	await _wait(1.6)
	await _aim_for(minion, 1.2, 0.3)
	await _shot("ilha_jogo_03_esqueleto_acorda.png")
	var spiral: Vector3 = (island.get_node("Marcadores/Esqueletos/Rogue_01") as Node3D).global_position
	player.global_position = spiral + Vector3(0, 1.0, 12)
	await _wait(1.2)
	player.aim_at(Vector3(0, 30, 0))
	await _wait(0.3)
	await _shot("ilha_jogo_04_trilha_do_morro.png")
	var top: Checkpoint = checkpoints.filter(func(c: Checkpoint) -> bool: return c.name == "TopoDoMorro")[0]
	player.global_position = top.global_position + Vector3(4, 0.5, 6)
	await _wait(1.0)
	player.aim_at(Vector3(0, 28, 0))
	await _wait(0.4)
	await _shot("ilha_jogo_05_cemiterio.png")
	player.global_position = Vector3(3, 2, -94)
	await _wait(1.0)
	player.set_yaw(0.0)
	await _wait(0.4)
	await _shot("ilha_jogo_06_ponte.png")
	player.global_position = Vector3(30, 2, -162)
	await _wait(1.0)
	player.aim_at(Vector3(40, 8, -180))
	await _wait(0.4)
	await _shot("ilha_jogo_07_clareira.png")
	player.global_position = Vector3(45, 1.0, -112.0 + 9.0 * sin(45.0 / 38.0))
	await _wait(0.55)
	await _shot("ilha_jogo_08_tchibum.png")
	await _wait(1.5)
	get_tree().quit()


func _press_key(key: Key) -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await get_tree().physics_frame
		await get_tree().physics_frame


## Quanto cada osso se afasta da posição média dele (no espaço do corpo) durante alguns segundos
## mirando, atirando sem parar ou não. Devolve {osso: maior distância em metros}.
func _bone_wobble(seconds: float, firing: bool, bones := ["head", "handslot.r"]) -> Dictionary:
	var sk: Skeleton3D = player.model.find_child("Skeleton3D", true, false)
	var samples := {}
	for b in bones:
		samples[b] = []
	player.force_aim = true
	player.force_fire = firing
	var t := 0.0
	while t < seconds:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if t > 0.3:
			for b in bones:
				samples[b].append(sk.get_bone_global_pose(sk.find_bone(b)).origin)
	player.force_fire = false
	player.force_aim = false
	var result := {}
	for b in bones:
		var mean := Vector3.ZERO
		for v in samples[b]:
			mean += v
		mean /= samples[b].size()
		var worst := 0.0
		for v in samples[b]:
			worst = maxf(worst, v.distance_to(mean))
		result[b] = worst
	return result


func _hand_model() -> String:
	var holder: Node = player.model.find_child("Blaster", true, false)
	if holder == null:
		return ""
	for c in holder.get_children():
		if c.scene_file_path != "":
			return c.scene_file_path.get_file()
	return ""


## Pente, estoque, recarga, troca de blaster, escopeta, luneta, granada e caixas.
## Uso: godot --headless --path . -- --armas
func _run_weapons_test() -> void:
	var all_ok := true
	player.god_mode = true
	Sfx.logging = true
	await _wait(0.5)
	all_ok = _check("começa com a Paçoca 12 / infinito e 2 granadas", player.current_weapon().id == "pacoca" and player.mag() == 12
			and player.reserve() == -1 and player.grenades == 2) and all_ok
	player.fire()
	all_ok = _check("atirar gasta uma bala", player.mag() == 11, "(%d)" % player.mag()) and all_ok
	while player.mag() > 0:
		player.fire()
		await get_tree().physics_frame
	await _wait(0.4)
	all_ok = _check("pente vazio recarrega sozinho", player.reloading) and all_ok
	await _wait_until(func() -> bool: return not player.reloading, 3.0)
	all_ok = _check("recarga enche o pente; estoque da Paçoca é infinito", player.mag() == 12 and player.reserve() == -1) and all_ok
	var fired_during_reload := false
	player.fire()
	player.fire()
	await _press_key(KEY_R)
	all_ok = _check("R recarrega antes de zerar", player.reloading, "(pente %d)" % player.mag()) and all_ok
	fired_during_reload = player.fire()
	all_ok = _check("não atira durante a recarga", not fired_during_reload) and all_ok
	await _wait_until(func() -> bool: return not player.reloading, 3.0)
	all_ok = _check("pente cheio depois da recarga manual", player.mag() == 12) and all_ok

	await _press_key(KEY_2)
	await _wait(0.4)
	all_ok = _check("tecla 2 pega o Granulado (modelo novo na mão)", player.current_weapon().id == "granulado" and _hand_model() == "blaster-j.glb",
			"(%s, %s)" % [player.current_weapon().nome, _hand_model()]) and all_ok
	for k in 5:
		player.fire()
	player.reload()
	await _wait_until(func() -> bool: return not player.reloading, 3.0)
	all_ok = _check("recarga do Granulado gasta o estoque", player.mag() == 30 and player.reserve() == 55, "(%d / %d)" % [player.mag(), player.reserve()]) and all_ok

	player.ammo.granulado.mag = 0
	player.ammo.granulado.reserve = 0
	var warned := [false]
	player.out_of_ammo.connect(func() -> void: warned[0] = true, CONNECT_ONE_SHOT)
	Sfx.played.clear()
	var shot := player.fire()
	all_ok = _check("sem munição: não atira, não recarrega e avisa", not shot and not player.reloading and warned[0] and "sem_municao" in Sfx.played) and all_ok

	var crate := AmmoPickup.new()
	crate.position = player.global_position
	add_child(crate)
	await _wait(0.6)
	all_ok = _check("caixa de munição devolve estoque e granada", player.reserve() == 30 and player.grenades == 3 and not is_instance_valid(crate),
			"(estoque %d, granadas %d)" % [player.reserve(), player.grenades]) and all_ok
	for def in Weapons.DEFS:
		if not Weapons.infinite(def):
			player.ammo[def.id].reserve = def.estoque_max
	var spare := AmmoPickup.new()
	spare.position = player.global_position
	add_child(spare)
	await _wait(0.6)
	all_ok = _check("com tudo cheio a caixa fica no chão", is_instance_valid(spare)) and all_ok
	spare.queue_free()

	# Escopeta: vários projéteis no mesmo disparo acertam o mesmo esqueleto.
	var minion := enemies[0]
	await _wait_until(func() -> bool: return minion.hurtboxes[1].is_active(), 8.0)
	minion.set_physics_process(false)
	minion.global_position = player.global_position + Vector3(0, 0, -5)
	minion.health = 99.0  # vida sobrando: todos os projéteis contam, ninguém desmonta no meio
	await _press_key(KEY_3)
	await _wait(0.4)
	player.force_aim = true
	await _aim_for(minion.hurtboxes[1], 0.0, 0.5)
	var hits := [0]
	var count_hit := func(_r: String, _d: float) -> void: hits[0] += 1
	player.hit_confirmed.connect(count_hit)
	player.fire()
	player.hit_confirmed.disconnect(count_hit)
	all_ok = _check("Pipoqueira solta vários projéteis de uma vez", player.current_weapon().id == "pipoqueira" and hits[0] >= 2, "(%d acertos de 7)" % hits[0]) and all_ok
	minion.health = minion.config.health

	# Luneta.
	await _press_key(KEY_4)
	await _wait(0.8)
	all_ok = _check("Pé-de-Moleque aproxima a mira", player.is_zoomed() and player.camera.fov < 35.0, "(campo de visão %.0f)" % player.camera.fov) and all_ok
	player.force_aim = false
	await _wait(0.5)

	# Granada perto de um esqueleto parado.
	await _wait_until(func() -> bool: return minion.state != SkeletonEnemy.State.ACORDANDO, 10.0)
	minion.set_physics_process(false)
	minion.global_position = player.global_position + Vector3(0, 0, -7)
	minion.health = minion.config.health
	await _aim_for(minion, -1.5, 0.4)
	var before_grenades := player.grenades
	player.throw_grenade()
	await _wait(2.4)
	all_ok = _check("granada explode e desmonta o esqueleto perto", player.grenades == before_grenades - 1 and (minion.health < minion.config.health or minion.state == SkeletonEnemy.State.INDO_EMBORA),
			"(vida %.1f, %s)" % [minion.health, SkeletonEnemy.State.keys()[minion.state]]) and all_ok
	minion.set_physics_process(true)
	player.grenades = 0
	all_ok = _check("sem granadas, não joga", not player.throw_grenade()) and all_ok

	# Munição no fim: esqueleto desmontado sempre deixa caixa.
	for def in Weapons.DEFS:
		if not Weapons.infinite(def):
			player.ammo[def.id].mag = 0
			player.ammo[def.id].reserve = 0
	var target := enemies[2]
	await _wait_until(func() -> bool: return target.hurtboxes[1].is_active(), 8.0)
	var count_drops := func() -> int:
		return get_children().filter(func(n: Node) -> bool: return n is AmmoPickup and n.dropped and not n.is_queued_for_deletion()).size()
	var drops_before: int = count_drops.call()
	target.take_hit(99.0, target.global_position + Vector3.UP * 2.0, target.hurtboxes[0])
	await get_tree().physics_frame
	all_ok = _check("munição no fim: esqueleto deixa caixa", count_drops.call() == drops_before + 1) and all_ok

	# Cabeça firme ao atirar sem parar: mede quanto a cabeça se mexe (em relação ao corpo)
	# durante 1,5 s de rajada, com a pistola e com o Granulado.
	player.god_mode = true
	for id in ["pacoca", "granulado"]:
		player.switch_weapon(Weapons.index_of(id))
		player.ammo[id].mag = 200
		await _wait(0.6)
		var still := await _bone_wobble(1.5, false)
		var shooting := await _bone_wobble(1.5, true)
		var nome: String = Weapons.get_def(Weapons.index_of(id)).nome
		all_ok = _check("mira parada firme com %s" % nome, still["head"] < 0.01 and still["handslot.r"] < 0.02,
				"(cabeça %.3f m, mão %.3f m)" % [still["head"], still["handslot.r"]]) and all_ok
		all_ok = _check("cabeça e mão firmes atirando com %s" % nome, shooting["head"] < 0.01 and shooting["handslot.r"] < 0.02,
				"(cabeça %.3f m, mão %.3f m)" % [shooting["head"], shooting["handslot.r"]]) and all_ok

	# Coice: logo depois do tiro a boca do cano sobe em relação à mão, e volta.
	player.switch_weapon(Weapons.index_of("pacoca"))
	player.force_aim = true
	await _wait(0.6)
	var hand: Node3D = player.model.find_child("MaoDireita", true, false)
	var rest_y := player.muzzle.global_position.y - hand.global_position.y
	player.fire()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var kick_y := player.muzzle.global_position.y - hand.global_position.y
	await _wait(0.5)
	var back_y := player.muzzle.global_position.y - hand.global_position.y
	player.force_aim = false
	all_ok = _check("coice levanta o cano e volta", kick_y > rest_y + 0.03 and absf(back_y - rest_y) < 0.01,
			"(boca %.3f -> %.3f -> %.3f m acima da mão)" % [rest_y, kick_y, back_y]) and all_ok

	# Pirulitão (F / R3): acerta quem está na frente, uma vez por golpe, e estoura bolha.
	player.switch_weapon(Weapons.index_of("pacoca"))
	var spot := player.global_position
	var fwd := -player.camera_pivot.global_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var dummy := spawn_wave_enemy("Skeleton_Minion", spot + fwd * 1.6)
	await _wait_until(func() -> bool: return dummy.state != SkeletonEnemy.State.ACORDANDO, 6.0)
	dummy.set_physics_process(false)
	var hp := dummy.health
	var swung := player.melee()
	all_ok = _check("Pirulitão aparece na mão no golpe", swung and player._lollipop.visible and not player._recoil.visible) and all_ok
	await _wait(0.4)
	all_ok = _check("golpe do Pirulitão tira 3 de quem está na frente", is_equal_approx(hp - dummy.health, Weapons.MELEE.dano),
			"(%.0f -> %.0f)" % [hp, dummy.health]) and all_ok
	all_ok = _check("não dá para golpear sem parar", not player.melee()) and all_ok
	await _wait(0.4)
	all_ok = _check("depois do golpe o blaster volta para a mão", not player._lollipop.visible and player._recoil.visible) and all_ok
	var bubble := Projectile.create(Projectile.Kind.BOLHA, spot + fwd * 1.5 + Vector3.UP * 1.1, player)
	add_child(bubble)
	bubble.set_physics_process(false)
	bubble.global_position = spot + fwd * 1.5 + Vector3.UP * 1.1
	player.melee()
	await _wait(0.4)
	all_ok = _check("Pirulitão estoura bolha mágica", not is_instance_valid(bubble) or bubble._popped) and all_ok

	print("ARMAS OK" if all_ok else "ARMAS COM FALHAS")
	get_tree().quit()


# --- teste e fotos da história ------------------------------------------------

func _townsfolk_near(center: Vector3, radius: float) -> Array:
	return get_tree().get_nodes_in_group(&"moradores").filter(
			func(t: Node3D) -> bool: return t.global_position.distance_to(center) < radius)


func _awake_wave_enemy(type_name: String) -> SkeletonEnemy:
	for e: SkeletonEnemy in _wave_enemies():
		if e.type_name == type_name and e.state in [SkeletonEnemy.State.PERSEGUINDO, SkeletonEnemy.State.ESPERANDO]:
			return e
	return null


func _wave_enemies() -> Array:
	var leaving := [SkeletonEnemy.State.AFUNDANDO, SkeletonEnemy.State.INDO_EMBORA]
	return enemies.filter(func(e: SkeletonEnemy) -> bool: return is_instance_valid(e) and e.has_meta("onda") and not (e.state in leaving))


## Derrota os esqueletos da onda atual até ela terminar (e o guardião também, se include_boss).
func _clear_wave(d: Defense, include_boss := true) -> void:
	var start_wave := d.wave_index
	var t := 0.0
	while t < 25.0 and d.wave_index == start_wave and d.state != Defense.State.VENCIDA:
		for e in d.alive.duplicate():
			if is_instance_valid(e) and e is SkeletonEnemy and not (e.state in [SkeletonEnemy.State.ACORDANDO, SkeletonEnemy.State.INDO_EMBORA, SkeletonEnemy.State.AFUNDANDO]):
				e.take_hit(99.0, e.global_position + Vector3.UP * 2.0, e.hurtboxes[0])
		if include_boss and is_instance_valid(d.boss) and d.boss.phase == Boss.Phase.LUTANDO:
			d.boss.take_hit(999.0, d.boss.global_position + Vector3.UP * 4.0, d.boss.hurtboxes[0])
		await get_tree().physics_frame
		t += get_physics_process_delta_time()


func _near_count(type: Variant, center: Vector3, radius: float) -> int:
	return get_children().filter(func(n: Node) -> bool:
		return is_instance_of(n, type) and not n.is_queued_for_deletion() and (n as Node3D).global_position.distance_to(center) < radius).size()


func _stand(pos: Vector3) -> void:
	player.global_position = pos + Vector3.UP * 1.0
	player.velocity = Vector3.ZERO
	await _wait(0.3)


## História na ilha com ondas curtas: prólogo, Lanterna Oeste (Ossão) e Leste (Mira-Torta), ponte.
## Uso: godot --headless --path . -- --historia
func _run_story_test() -> void:
	var all_ok := true
	player.god_mode = true
	story.fast = true
	await _wait(0.5)
	all_ok = _check("história começa só com a Paçoca", player.has_weapon("pacoca") and not player.has_weapon("granulado")
			and player.next_weapon_index(1) == player.weapon_index) and all_ok
	player.using_gamepad = true
	await _joy_button(JOY_BUTTON_DPAD_RIGHT)
	all_ok = _check("seta de blaster ainda não comprado avisa onde comprar", player.current_weapon().id == "pacoca"
			and message_label.modulate.a > 0.5 and "Lojinha" in message_label.text, "(\"%s\")" % message_label.text) and all_ok
	all_ok = _check("antes do prólogo: lanternas apagadas, ponte aberta e cúpula fechada",
			story.lanterns.values().all(func(l: Dictionary) -> bool: return not l.lit) and story.bridge_open() and not story.dome_open()) and all_ok

	# Prólogo na praça.
	var praca: Defense = story.defenses.praca
	story.start()
	await _wait(0.3)
	all_ok = _check("prólogo começa na praça e aponta a praia do cais", praca.state == Defense.State.ESPERANDO
			and story.objective_target.distance_to(praca.center) < 1.0 and player.global_position.distance_to(praca.center) > praca.radius) and all_ok
	await _stand(praca.center + Vector3(0, 0, -6))
	await _wait_until(func() -> bool: return praca.state == Defense.State.ONDA, 4.0)
	await _wait(0.8)
	all_ok = _check("prólogo: a primeira onda sai das rachaduras", praca.state == Defense.State.ONDA and _wave_enemies().size() == 3,
			"(%d esqueletos, \"%s\")" % [_wave_enemies().size(), wave_label.text]) and all_ok
	# A luta é na praia, mas quem torce é a gente da festa na praça, ali do lado.
	var plaza_folks := _townsfolk_near(Vector3(0, 0, 170), 30.0)
	all_ok = _check("moradores na praça torcem durante a onda", plaza_folks.size() >= 10
			and plaza_folks.filter(func(t: Townsperson) -> bool: return t.crowd).size() >= 8,
			"(%d moradores, %d torcendo)" % [plaza_folks.size(), plaza_folks.filter(func(t: Townsperson) -> bool: return t.crowd).size()]) and all_ok
	await _clear_wave(praca)
	await _wait_until(func() -> bool: return praca.state == Defense.State.INTERVALO, 3.0)
	all_ok = _check("intervalo dá munição e coração no centro", _near_count(AmmoPickup, praca.center, 4.0) >= 1
			and _near_count(HeartPickup, praca.center, 4.0) >= 1, "(\"%s\")" % wave_label.text) and all_ok
	await _wait_until(func() -> bool: return praca.state == Defense.State.ONDA, 4.0)
	await _wait(0.6)
	var back := player.global_position
	await _stand(Vector3(120, 0.5, 170))
	all_ok = _check("longe demais, a onda é cancelada", praca.state == Defense.State.PAUSADA) and all_ok
	await _wait(1.8)
	all_ok = _check("os esqueletos da onda afundam e somem", _wave_enemies().is_empty(), "(%d restando)" % _wave_enemies().size()) and all_ok
	await _stand(back)
	await _wait_until(func() -> bool: return praca.state == Defense.State.ONDA, 4.0)
	all_ok = _check("voltando, a mesma onda recomeça", praca.state == Defense.State.ONDA and praca.wave_index == 1) and all_ok
	await _clear_wave(praca)
	await _wait(3.0)
	all_ok = _check("prólogo vencido acende as quatro lanternas", praca.state == Defense.State.VENCIDA and story.stage == "cidade"
			and story.lanterns.values().all(func(l: Dictionary) -> bool: return l.lit)) and all_ok
	all_ok = _check("moradores da praça comemoram a vitória", _townsfolk_near(Vector3(0, 0, 170), 30.0).filter(
			func(t: Townsperson) -> bool: return t.is_celebrating()).size() >= 8) and all_ok
	await get_tree().physics_frame
	all_ok = _check("objetivo aponta uma lanterna da cidade", "cidade" in story.objective_text and story.objective_target != Vector3.INF
			and objective_marker.visible, "(\"%s\")" % story.objective_text) and all_ok

	# Lanterna Oeste: 3 ondas e o Ossão.
	var oeste: Defense = story.defenses.oeste
	await _stand(oeste.center + Vector3(0, 0, 8))
	for k in 2:
		await _wait_until(func() -> bool: return oeste.state == Defense.State.ONDA, 6.0)
		await _clear_wave(oeste)
	await _wait_until(func() -> bool: return oeste.state == Defense.State.ONDA and is_instance_valid(oeste.boss), 6.0)
	var ossao: Boss = oeste.boss
	all_ok = _check("última onda traz o Ossão com barra de vida", is_instance_valid(ossao) and boss_bar.visible and ossao.display_name == "Ossão") and all_ok
	await _wait_until(func() -> bool: return ossao.phase == Boss.Phase.LUTANDO, 5.0)
	player.force_aim = true
	var h0 := ossao.health
	await _aim_for(ossao.hurtboxes[0], 0.0, 0.5)
	player.fire()
	await get_tree().physics_frame
	player.force_aim = false
	all_ok = _check("tiro de verdade na cabeça do Ossão tira vida", ossao.health < h0, "(%.0f -> %.0f)" % [h0, ossao.health]) and all_ok
	ossao.set_physics_process(false)
	player.god_mode = false
	player.hearts = 5
	player._invulnerable = 0.0
	ossao.shockwave(player.global_position + Vector3(4, 0, 0), 9.0, 8.0)
	await _wait(0.9)
	all_ok = _check("onda de choque acerta quem está no chão", player.hearts == 4, "(%d corações)" % player.hearts) and all_ok
	player.hearts = 5
	player._invulnerable = 0.0
	await _wait(0.3)
	player.velocity.y = player.jump_velocity
	ossao.shockwave(player.global_position + Vector3(3.5, 0, 0), 9.0, 8.0)
	await _wait(0.9)
	all_ok = _check("pulando, a onda passa por baixo", player.hearts == 5, "(%d corações)" % player.hearts) and all_ok
	player.god_mode = true
	ossao.set_physics_process(true)
	var before_summon := oeste.remaining
	ossao.take_hit(ossao.health - ossao.max_health * 0.5 + 0.5, ossao.global_position + Vector3.UP * 6.0, ossao.hurtboxes[0])
	await get_tree().physics_frame
	all_ok = _check("na metade da vida o Ossão chama 2 Minions", oeste.remaining == before_summon + 2) and all_ok
	await _clear_wave(oeste)
	await _wait_until(func() -> bool: return oeste.state == Defense.State.VENCIDA, 3.0)
	await get_tree().physics_frame
	all_ok = _check("Oeste vencida: lanterna apagada, bandeira e 50 moedas (sem blaster de presente)", not story.lanterns.Oeste.lit
			and current_checkpoint.name == "CidadeOeste" and story.rewards.is_empty() and story.coins == 50 and story.shop_target() != Vector3.INF,
			"(%d moedas)" % story.coins) and all_ok
	all_ok = _check("convidados chegam para festejar na Oeste", _townsfolk_near(oeste.center, 12.0).size() >= 3,
			"(%d)" % _townsfolk_near(oeste.center, 12.0).size()) and all_ok
	all_ok = _check("comprar o Granulado na lojinha (40) põe ele na mão", shop_menu.buy("granulado") == "comprou" and player.has_weapon("granulado")
			and player.current_weapon().id == "granulado" and story.coins == 10) and all_ok
	var ossao_ref: WeakRef = weakref(ossao)
	await _wait_until(func() -> bool: return ossao_ref.get_ref() == null, 12.0)
	all_ok = _check("o Ossão vai embora de balão e a barra some", ossao_ref.get_ref() == null and not boss_bar.visible) and all_ok

	# Lanterna Leste: ficar tonto cancela; depois as ondas e a Mira-Torta.
	var leste: Defense = story.defenses.leste
	await _stand(leste.center + Vector3(0, 0, 8))
	await _wait_until(func() -> bool: return leste.state == Defense.State.ONDA, 6.0)
	await _wait(0.8)
	player.god_mode = false
	player.hearts = 1
	player._invulnerable = 0.0
	player.take_damage(1, player.global_position + Vector3.FORWARD, "teste")
	await _wait(0.3)
	all_ok = _check("ficar tonto cancela a onda", leste.state == Defense.State.PAUSADA) and all_ok
	await _wait_until(func() -> bool: return not player.dizzy and fade.modulate.a < 0.05, 8.0)
	player.god_mode = true
	await _stand(leste.center + Vector3(0, 0, 8))
	await _wait_until(func() -> bool: return leste.state == Defense.State.ONDA, 6.0)
	all_ok = _check("de volta ao círculo, a defesa continua", leste.state == Defense.State.ONDA and leste.wave_index == 0) and all_ok
	for k in 2:
		await _wait_until(func() -> bool: return leste.state == Defense.State.ONDA, 6.0)
		await _clear_wave(leste)
	await _wait_until(func() -> bool: return leste.state == Defense.State.ONDA and is_instance_valid(leste.boss), 6.0)
	var mira: Boss = leste.boss
	await _wait_until(func() -> bool: return mira.phase == Boss.Phase.LUTANDO, 5.0)
	all_ok = _check("última onda traz a Mira-Torta", mira.display_name == "Mira-Torta" and boss_bar.visible) and all_ok
	mira.set_physics_process(false)
	player.god_mode = false
	player.hearts = 5
	player._invulnerable = 0.0
	mira._rain()
	await get_tree().physics_frame
	var zones := get_children().filter(func(n: Node) -> bool: return n is Boss.DangerZone).size()
	await _wait(2.0)
	all_ok = _check("chuva de flechas: círculos no chão e acerta quem fica", zones >= 4 and player.hearts == 4, "(%d círculos, %d corações)" % [zones, player.hearts]) and all_ok
	player.god_mode = true
	var arrows_before := _projectiles(Projectile.Kind.FLECHA).size()
	mira._fire_fan(mira.forward())
	await get_tree().physics_frame
	all_ok = _check("leque de 5 flechas", _projectiles(Projectile.Kind.FLECHA).size() - arrows_before == 5) and all_ok
	mira.set_physics_process(true)
	await _clear_wave(leste)
	await _wait_until(func() -> bool: return leste.state == Defense.State.VENCIDA, 3.0)
	await get_tree().physics_frame
	all_ok = _check("cidade vencida: as defesas da mata começam", story.stage == "mata" and story.defenses.clareira.active and story.defenses.ventos.active) and all_ok
	all_ok = _check("com as moedas da Leste dá para comprar a Pipoqueira", story.coins == 60 and shop_menu.buy("pipoqueira") == "comprou"
			and player.has_weapon("pipoqueira") and story.coins == 10, "(%d moedas)" % story.coins) and all_ok
	await _stand(Vector3(0, 0.5, 60))
	await _wait(0.2)
	all_ok = _check("objetivo manda atravessar a ponte", "ponte" in story.objective_text, "(\"%s\")" % story.objective_text) and all_ok

	# Ponte livre.
	await _stand(Vector3(0, 1, -92))
	await _walk_toward(Vector3(0, 0, -140), 7.0)
	all_ok = _check("atravessa a ponte agora", player.global_position.z < -128.0, "(z %.1f)" % player.global_position.z) and all_ok
	await _wait(0.3)
	all_ok = _check("na mata, objetivo aponta as lanternas da mata", "mata" in story.objective_text, "(\"%s\")" % story.objective_text) and all_ok

	print("HISTORIA OK" if all_ok else "HISTORIA COM FALHAS")
	get_tree().quit()


## Fotos da história (precisa de janela). Uso: godot --path . -- --historia-captura
func _run_story_capture() -> void:
	player.god_mode = true
	story.fast = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _wait(0.6)
	var praca: Defense = story.defenses.praca
	story.start()
	await _wait(0.8)
	await _shot("h01_inicio_faixa.png")
	await _stand(praca.center + Vector3(0, 0, -6))
	await _wait_until(func() -> bool: return praca.state == Defense.State.ONDA, 4.0)
	await _wait(1.2)
	if not _wave_enemies().is_empty():
		player.aim_at(_wave_enemies()[0].global_position + Vector3.UP)
	await _wait(0.2)
	await _shot("h02_onda_rachaduras.png")
	await _clear_wave(praca)
	await _wait_until(func() -> bool: return praca.state == Defense.State.ONDA, 4.0)
	await _clear_wave(praca)
	await _wait(2.6)
	player.aim_at(Vector3(0, 30, 0))
	await _wait(0.3)
	await _shot("h03_lanternas_acesas.png")
	var oeste: Defense = story.defenses.oeste
	player.set_yaw(PI * 0.5)
	await _wait(0.4)
	await _shot("h04_marcador_objetivo.png")
	await _stand(oeste.center + Vector3(4, 0, 12))
	for k in 2:
		await _wait_until(func() -> bool: return oeste.state == Defense.State.ONDA, 6.0)
		await _clear_wave(oeste)
	await _wait_until(func() -> bool: return is_instance_valid(oeste.boss) and oeste.boss.phase == Boss.Phase.LUTANDO, 8.0)
	var ossao := oeste.boss
	for e in _wave_enemies():
		e.visible = false
	await _aim_for(ossao, 5.0, 0.5)
	await _shot("h05_ossao.png")
	ossao.shockwave(ossao.global_position + ossao.forward() * 2.0, 16.0, 8.0)
	await _wait(0.7)
	await _shot("h06_onda_de_choque.png")
	await _clear_wave(oeste)
	await _wait(1.8)
	await _aim_for(ossao, 8.0, 0.3)
	await _shot("h07_ossao_balao.png")
	await _wait(1.0)
	await _wait(0.2)
	await _shot("h08_moedas_e_festa.png")
	shop_menu.buy("granulado")
	await _wait(1.2)
	await _shot("h09_novo_blaster.png")
	var leste: Defense = story.defenses.leste
	await _stand(leste.center + Vector3(0, 0, 12))
	for k in 2:
		await _wait_until(func() -> bool: return leste.state == Defense.State.ONDA, 6.0)
		await _clear_wave(leste)
	await _wait_until(func() -> bool: return is_instance_valid(leste.boss) and leste.boss.phase == Boss.Phase.LUTANDO, 8.0)
	var mira := leste.boss
	for e in _wave_enemies():
		e.visible = false
	mira.set_physics_process(false)
	mira._rain()
	await _aim_for(mira, 2.0, 0.6)
	await _shot("h10_mira_torta_chuva.png")
	mira.set_physics_process(true)
	await _clear_wave(leste)
	await _wait(1.0)
	await _stand(Vector3(4, 1.5, -86))
	player.set_yaw(0.0)
	await _wait(0.5)
	await _shot("h11_ponte_aberta.png")
	open_menu("pausa")
	await _wait(0.3)
	await _shot("h12_pausa_objetivo.png")
	get_tree().quit()


func _children_of(type: Variant) -> Array:
	return get_children().filter(func(n: Node) -> bool: return is_instance_of(n, type) and not n.is_queued_for_deletion())


## Defesas da mata (Torre de Ossinhos e Minionzão) e o caminho até o cemitério, partindo do
## atalho que dá a cidade como vencida. Uso: godot --headless --path . -- --mata
func _run_forest_test() -> void:
	var all_ok := true
	player.god_mode = true
	story.fast = true
	await _wait(0.5)
	story.skip_to_forest()
	await _wait(0.3)
	all_ok = _check("atalho: mata liberada, com Granulado e Pipoqueira", story.stage == "mata" and story.bridge_open()
			and player.has_weapon("granulado") and player.has_weapon("pipoqueira") and not player.has_weapon("pe_de_moleque")) and all_ok
	# A seta: do lado da cidade (mesmo onde o rio faz curva) leva até o outro lado da ponte; passando a água,
	# aponta a luta mais perto.
	var arrow_ok := true
	for spec in [[Vector3(0, 0, -85), true], [Vector3(0, 0, -100), true], [Vector3(-60, 0, -104), true], [Vector3(0, 0, -112), false],
			[Vector3(8, 0, -133), false]]:
		await _stand(_ground_point(spec[0]))
		await get_tree().physics_frame
		var to_bridge: bool = spec[1]
		arrow_ok = arrow_ok and (story.objective_target.distance_to(Story.BRIDGE_NORTH) < 1.0) == to_bridge \
				and ("ponte" in story.objective_text) == to_bridge
	all_ok = _check("seta da mata: atravessa a ponte e depois aponta a luta", arrow_ok, "(\"%s\")" % story.objective_text) and all_ok

	# Clareira: Torre de Ossinhos.
	var clareira: Defense = story.defenses.clareira
	await _stand(clareira.center + Vector3(0, 0, 9))
	await _wait_until(func() -> bool: return clareira.state == Defense.State.ONDA, 6.0)
	await _clear_wave(clareira)
	# Segunda onda: o Golem de Ossos.
	await _wait_until(func() -> bool: return clareira.state == Defense.State.ONDA, 6.0)
	await _wait_until(func() -> bool: return _awake_wave_enemy("Skeleton_Golem") != null, 8.0)
	var golem := _awake_wave_enemy("Skeleton_Golem")
	all_ok = _check("Golem de Ossos vem na segunda onda com 16 de vida", golem != null and golem.health == 16.0,
			"(%s)" % ("sem golem" if golem == null else "vida %.0f" % golem.health)) and all_ok
	if golem != null:
		var waves_before := _children_of(Boss.Shockwave).size()
		golem._start_attack()
		await _wait(1.3)
		all_ok = _check("pancada do Golem solta uma onda no chão", _children_of(Boss.Shockwave).size() > waves_before) and all_ok
	await _clear_wave(clareira)
	await _wait_until(func() -> bool: return is_instance_valid(clareira.boss) and clareira.boss.phase == Boss.Phase.LUTANDO, 8.0)
	var torre := clareira.boss as BossTorre
	all_ok = _check("última onda traz a Torre de Ossinhos com 5 andares", is_instance_valid(torre) and torre.segments.size() == 5
			and torre.health == BossTorre.SEGMENTS * BossTorre.SEG_HEALTH and boss_bar.visible) and all_ok
	torre.set_physics_process(false)
	player.force_aim = true
	var bottom: Dictionary = torre.segments[0]
	await _aim_for(bottom.hurtboxes[0], 0.0, 0.5)
	player.fire()
	await get_tree().physics_frame
	player.force_aim = false
	all_ok = _check("tiro de verdade na cabeça do andar de baixo", bottom.hp < BossTorre.SEG_HEALTH, "(vida do andar %.0f)" % bottom.hp) and all_ok
	var middle: Dictionary = torre.segments[2]
	var top_holder: Node3D = torre.segments[4].holder
	torre.take_hit(99.0, (middle.holder as Node3D).global_position, middle.hurtboxes[0])
	await _wait(0.6)
	all_ok = _check("andar vencido sai de balão e os de cima descem", torre.segments.size() == 4 and absf(top_holder.position.y - 3 * BossTorre.SPACING) < 0.05
			and is_instance_valid(middle.holder) and (middle.holder as Node3D).get_parent() == self, "(%d andares, topo em %.2f)" % [torre.segments.size(), top_holder.position.y]) and all_ok
	var bubbles_before := _projectiles(Projectile.Kind.BOLHA).size()
	torre._throw()
	await get_tree().physics_frame
	all_ok = _check("o de cima joga bolha", _projectiles(Projectile.Kind.BOLHA).size() == bubbles_before + 1) and all_ok
	for k in 2:
		var seg: Dictionary = torre.segments[-1]
		torre.take_hit(99.0, (seg.holder as Node3D).global_position, seg.hurtboxes[0])
	torre.set_physics_process(true)
	torre._hop_timer = 0.0
	await _wait_until(func() -> bool: return not _children_of(Boss.Shockwave).is_empty(), 4.0)
	all_ok = _check("com 2 andares a torre pula e solta onda", torre.segments.size() == 2 and not _children_of(Boss.Shockwave).is_empty()) and all_ok
	await _clear_wave(clareira)
	await _wait_until(func() -> bool: return clareira.state == Defense.State.VENCIDA, 4.0)
	await get_tree().physics_frame
	all_ok = _check("Clareira vencida: lanterna apagada e recompensa de coração", not story.lanterns.Clareira.lit and story.rewards.size() == 1
			and story.rewards[0].kind == "coracao") and all_ok
	await _stand(story.rewards[0].global_position)
	await _wait(1.0)
	all_ok = _check("pegar o coração aumenta a vida máxima para 6", player.max_hearts == 6 and player.hearts == 6) and all_ok

	# Morro dos Ventos: Minionzão.
	var ventos: Defense = story.defenses.ventos
	await _stand(ventos.center + Vector3(0, 0, 9))
	for k in 2:
		await _wait_until(func() -> bool: return ventos.state == Defense.State.ONDA, 6.0)
		await _clear_wave(ventos)
	await _wait_until(func() -> bool: return is_instance_valid(ventos.boss) and ventos.boss.phase == Boss.Phase.LUTANDO, 8.0)
	var mz := ventos.boss as BossMinionzao
	all_ok = _check("última onda traz o Minionzão", is_instance_valid(mz) and mz.display_name == "Minionzão" and boss_bar.visible) and all_ok
	for e in _wave_enemies():
		e.take_hit(99.0, e.global_position + Vector3.UP * 2.0, e.hurtboxes[0])
	await _stand(mz.global_position + Vector3(0, 0, 12))
	player.god_mode = false
	player.hearts = player.max_hearts
	player._invulnerable = 0.0
	mz._charge_cooldown = 0.0
	mz._rest()
	mz._move_time = 0.8
	var saw_stripe := [false]
	var t := 0.0
	while t < 5.0 and not mz.is_dizzy():
		if is_instance_valid(mz._stripe) and mz._stripe.visible:
			saw_stripe[0] = true
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	all_ok = _check("investida: faixa de aviso no chão e acerta quem fica no caminho", saw_stripe[0] and player.hearts == player.max_hearts - 1,
			"(faixa %s, %d corações)" % [saw_stripe[0], player.hearts]) and all_ok
	player.god_mode = true
	var h0 := mz.health
	mz.take_hit(2.0, mz.global_position + Vector3.UP * 5.0, mz.hurtboxes[1])
	all_ok = _check("depois da investida fica tonto e leva dano em dobro", mz.is_dizzy() and is_equal_approx(h0 - mz.health, 4.0),
			"(%.0f -> %.0f)" % [h0, mz.health]) and all_ok
	await _clear_wave(ventos)
	await _wait_until(func() -> bool: return ventos.state == Defense.State.VENCIDA, 4.0)
	await get_tree().physics_frame
	all_ok = _check("mata vencida: cúpula do cemitério cai", story.stage == "cemiterio" and story.dome_open()) and all_ok
	await _wait(2.6)
	all_ok = _check("o portão do cemitério abre", story.gate_open()) and all_ok
	all_ok = _check("Morro dos Ventos dá moedas, sem blaster de presente", story.coins == 100 and not player.has_weapon("pe_de_moleque")
			and shop_menu.buy("pe_de_moleque") == "comprou" and story.coins == 40, "(%d moedas)" % story.coins) and all_ok
	all_ok = _check("objetivo manda subir até o cemitério", "cemitério" in story.objective_text, "(\"%s\")" % story.objective_text) and all_ok
	await _stand(Vector3(9, 27, 0))
	await _wait(0.5)
	all_ok = _check("chegar ao cemitério começa a defesa final", story.defenses.cemiterio.state in [Defense.State.CHEGANDO, Defense.State.ONDA],
			"(%s)" % Defense.State.keys()[story.defenses.cemiterio.state]) and all_ok

	print("MATA OK" if all_ok else "MATA COM FALHAS")
	get_tree().quit()


## Defesa final no cemitério e as três fases do Mestre Ossinho, partindo do atalho (tudo vencido
## até a cúpula cair). Uso: godot --headless --path . -- --cemiterio
func _run_cemetery_test() -> void:
	var all_ok := true
	player.god_mode = true
	story.fast = true
	await _wait(0.5)
	story.skip_to_cemetery()
	await _wait(0.3)
	var cemiterio: Defense = story.defenses.cemiterio
	all_ok = _check("atalho: cúpula aberta, portão aberto e defesa final ativa", story.stage == "cemiterio" and story.dome_open()
			and story.gate_open() and cemiterio.active) and all_ok
	await _stand(cemiterio.center + Vector3(0, 0, 2))
	await _wait_until(func() -> bool: return cemiterio.state == Defense.State.ONDA, 6.0)
	all_ok = _check("entrar no cemitério começa a defesa", cemiterio.state == Defense.State.ONDA) and all_ok
	for k in 2:
		await _clear_wave(cemiterio, false)
		await _wait_until(func() -> bool: return cemiterio.state == Defense.State.ONDA, 6.0)
	await _wait_until(func() -> bool: return is_instance_valid(cemiterio.boss) and cemiterio.boss.phase == Boss.Phase.LUTANDO, 8.0)
	var mestre := cemiterio.boss as BossMestre
	all_ok = _check("última onda traz o Mestre Ossinho com barra de vida", is_instance_valid(mestre) and mestre.display_name == "Mestre Ossinho"
			and boss_bar.visible and mestre.stage_n == 1) and all_ok
	if mestre == null:
		print("CEMITERIO COM FALHAS")
		get_tree().quit()
		return
	# Os outros da onda saem do caminho.
	await _wait_until(func() -> bool: return _wave_enemies().all(func(e: SkeletonEnemy) -> bool: return e.state != SkeletonEnemy.State.ACORDANDO), 4.0)
	for e in _wave_enemies():
		e.take_hit(99.0, e.global_position + Vector3.UP, e.hurtboxes[0])
	var before := cemiterio.remaining
	mestre.summon()
	await get_tree().physics_frame
	all_ok = _check("fase 1: o Mestre chama dois minions", cemiterio.remaining == before + 2, "(%d -> %d)" % [before, cemiterio.remaining]) and all_ok
	var bubbles := _projectiles(Projectile.Kind.BOLHA).size()
	mestre._release()
	await get_tree().physics_frame
	all_ok = _check("fase 1: joga bolha mágica", _projectiles(Projectile.Kind.BOLHA).size() == bubbles + 1) and all_ok
	mestre.set_physics_process(false)
	var h0 := mestre.health
	player.force_aim = true
	await _aim_for(mestre.hurtboxes[0], 0.0, 0.5)
	player.fire()
	await get_tree().physics_frame
	all_ok = _check("tiro de verdade na cabeça tira vida", mestre.health < h0, "(%.0f -> %.0f)" % [h0, mestre.health]) and all_ok
	mestre.take_hit(mestre.health - 31.0, mestre.global_position + Vector3.UP * 2.0, mestre.hurtboxes[1])
	await get_tree().physics_frame
	all_ok = _check("fase 2: escudo de 6 bolhas", mestre.stage_n == 2 and mestre.shield.size() == 6, "(fase %d, %d bolhas)" % [mestre.stage_n, mestre.shield.size()]) and all_ok
	var h1 := mestre.health
	mestre.take_hit(2.0, mestre.global_position + Vector3.UP * 2.0, mestre.hurtboxes[1])
	all_ok = _check("com o escudo, o golpe é bloqueado", mestre.health == h1) and all_ok
	await _aim_for(mestre.shield[0], 0.0, 0.4)
	player.fire()
	await get_tree().physics_frame
	player.force_aim = false
	all_ok = _check("tiro de verdade estoura uma bolha do escudo", mestre.shield.size() == 5, "(%d bolhas)" % mestre.shield.size()) and all_ok
	for b in mestre.shield.duplicate():
		b.take_hit(1.0, b.global_position, null)
	await get_tree().physics_frame
	var h2 := mestre.health
	mestre.take_hit(2.0, mestre.global_position + Vector3.UP * 2.0, mestre.hurtboxes[1])
	all_ok = _check("sem bolhas, fica tonto e leva dano em dobro", mestre.is_dizzy() and is_equal_approx(h2 - mestre.health, 4.0),
			"(%.0f -> %.0f)" % [h2, mestre.health]) and all_ok
	mestre._dizzy = 0.0
	mestre.set_physics_process(true)
	mestre.take_hit(mestre.health - 15.0, mestre.global_position + Vector3.UP * 2.0, mestre.hurtboxes[1])
	await get_tree().physics_frame
	all_ok = _check("fase 3: escudo some", mestre.stage_n == 3 and mestre.shield.is_empty()) and all_ok
	# is_instance_of não reconhece classes internas: filtra com "is".
	var giants_now := func() -> Array: return get_children().filter(func(n: Node) -> bool: return n is BossMestre.GiantBubble and not n.is_queued_for_deletion())
	var giants: int = giants_now.call().size()
	# No jogo ele mantém distância: a bolha não pode nascer em cima do aventureiro.
	mestre.set_physics_process(false)
	await _stand(mestre.global_position + mestre.forward() * 10.0)
	mestre._release()
	await get_tree().physics_frame
	var giant_list: Array = giants_now.call()
	all_ok = _check("fase 3: bolha gigante", giant_list.size() == giants + 1, "(%d -> %d, fase %d, %s)" % [giants, giant_list.size(), mestre.stage_n, Boss.Phase.keys()[mestre.phase]]) and all_ok
	if not giant_list.is_empty():
		var small := func() -> int: return _projectiles(Projectile.Kind.BOLHA).filter(func(b: Node) -> bool: return not (b is BossMestre.GiantBubble)).size()
		var small_before: int = small.call()
		var g: Projectile = giant_list[-1]
		g.take_hit(1.0, g.global_position, null)
		await get_tree().physics_frame
		all_ok = _check("estourada, a bolha gigante vira três", small.call() == small_before + 3, "(%d -> %d)" % [small_before, small.call()]) and all_ok
	mestre.set_physics_process(true)
	mestre.take_hit(999.0, mestre.global_position + Vector3.UP * 2.0, mestre.hurtboxes[1])
	await _wait(5.0)
	all_ok = _check("derrotado, o Mestre senta e tira a coroa (sem balão)", is_instance_valid(mestre) and mestre.is_sitting()
			and is_instance_valid(mestre.crown_on_floor) and mestre._balloons == null) and all_ok
	await _clear_wave(cemiterio, false)
	await _wait_until(func() -> bool: return cemiterio.state == Defense.State.VENCIDA, 5.0)
	await get_tree().physics_frame
	all_ok = _check("defesa final vencida: começa o desfecho em cena", cemiterio.state == Defense.State.VENCIDA and ending.in_cutscene,
			"(\"%s\")" % story.objective_text) and all_ok
	print("CEMITERIO OK" if all_ok else "CEMITERIO COM FALHAS")
	get_tree().quit()


## Fotos do golpe do Pirulitão num esqueleto (precisa de janela). Uso: godot --path . -- --pirulito-captura
func _run_lollipop_capture() -> void:
	player.god_mode = true
	player.set_character("menino")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _wait(0.6)
	var spot := Ending.PLAZA + Vector3(0, 0, 4.0)
	await _stand(_ground_point(spot))
	player.set_yaw(0.0)
	await _wait(0.5)
	var e := spawn_wave_enemy("Skeleton_Minion", _ground_point(spot + Vector3(0, 0, -1.7)))
	await _wait_until(func() -> bool: return e.state != SkeletonEnemy.State.ACORDANDO, 6.0)
	e.set_physics_process(false)
	for k in 2:
		player.melee()
		await _wait(0.16 + k * 0.08)
		var p := player.global_position
		await _art_shot("res://tools/capturas/g0%d_pirulitao.png" % (k + 1), Vector2i(1280, 720), p + Vector3(3.2, 1.8, -1.2), p + Vector3(0, 1.0, -0.8), 50.0)
		await _wait(0.8)
	player.melee()
	await _wait(0.2)
	await _shot("g03_pirulitao_jogo.png")
	print("capturas do Pirulitão em tools/capturas/")
	get_tree().quit()


## Fotos da lojinha (precisa de janela): a barraca, a seta dourada vista da praça, o menu e a Jujuba na mão.
## Uso: godot --path . -- --loja-captura
func _run_shop_capture() -> void:
	player.god_mode = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _wait(0.6)
	close_menus()
	story.add_coins(140, player.global_position)
	var out := "res://tools/capturas/"
	var size := Vector2i(1280, 720)
	var s := shop.global_position
	await _art_shot(out + "l01_lojinha.png", size, s + Vector3(-3.5, 2.6, -7.5), s + Vector3(0, 1.3, 0), 55.0)
	await _stand(_ground_point(Ending.PLAZA + Vector3(4.0, 0, 8.0)))
	var to := s - player.global_position
	player.set_yaw(atan2(-to.x, -to.z))
	await _wait(3.5)
	if menu_state != "":
		close_menus()
		await _wait(0.4)
	await _shot("l02_seta_da_lojinha.png")
	if menu_state != "":
		close_menus()
	await _stand(shop._mat_point)
	await _wait_until(func() -> bool: return menu_state == "loja", 2.0)
	if menu_state != "loja":
		close_menus()
		open_shop()
	await _wait(0.3)
	await _shot("l03_menu_da_lojinha.png")
	shop_menu.open_preview("granulado")
	await _wait(1.0)
	await _shot("l04_previa_granulado.png")
	shop_menu.buy("granulado")
	await _wait(0.6)
	await _shot("l05_comprou.png")
	shop_menu.back()
	shop_menu.open_preview("bombom")
	await _wait(1.3)
	await _shot("l06_previa_bombom.png")
	shop_menu.back()
	await _wait(0.2)
	await _shot("l07_cartoes_depois.png")
	close_menus()
	await _wait(0.6)
	await _shot("l08_granulado_na_mao.png")
	print("capturas da lojinha em tools/capturas/")
	get_tree().quit()


## Atividades extras: barcos no mar; veículos do box (vazios, entrar perto de um, o aventureiro da cintura
## para cima no banco, dirigir, LARGADA começa a corrida, voltas, chegada, descer na pista volta para a vaga,
## deixar pela ilha e se afastar 50 m volta para a vaga, cair no mar); skate (pegar, perna empurrando,
## marca da sessão, half-pipe, pontos, tombo, fim com moedas, descer deixa no chão, longe volta para a
## pista). Uso: godot --headless --path . -- --atividades
func _run_activities_test() -> void:
	var all_ok := true
	player.god_mode = true
	story.fast = true
	await _wait(0.5)
	close_menus()
	await _wait(0.3)
	var sea: SeaTraffic = get_node("Barcos")
	var fishers := sea.find_children("PescadorDoBarco*", "Townsperson", true, false).size()
	all_ok = _check("barcos no mar: ancorados, pescadores e navios no horizonte", sea._anchored.size() >= 14 and sea._ships.size() == 3
			and fishers >= 5, "(%d ancorados, %d pescadores)" % [sea._anchored.size(), fishers]) and all_ok

	# Veículos do box.
	var cars := kart_race.vehicles
	var models := cars.map(func(v: Kart) -> String: return v.model_name)
	var empty := cars.all(func(v: Kart) -> bool:
		var pilot := v.find_child("character", true, false) as Node3D
		return pilot == null or not pilot.visible)
	all_ok = _check("5 karts vazios nas vagas, cada um de uma cor", cars.size() == 5 and empty
			and cars.all(func(v: Kart) -> bool: return v.is_home()) and models.count("kart-oopi") == 5
			and cars.map(func(v: Kart) -> String: return v.tint.to_html(false)).reduce(func(acc: Array, c: String) -> Array: return acc if c in acc else acc + [c], []).size() == 5,
			"(%s)" % ", ".join(models)) and all_ok
	var car := cars[0]
	await _stand(car.global_position + car.global_basis.z * 2.6)
	await _wait(0.3)
	all_ok = _check("perto de um carrinho, o aviso chama para dirigir", kart_race.nearest == car and hint_label.visible
			and "dirigir" in hint_label.text, "(\"%s\")" % hint_label.text) and all_ok
	var coins0 := story.coins
	await _press_key(KEY_E)
	await _wait(0.2)
	var pilot := car.find_child("PilotoNoBanco", true, false) as Node3D
	var shown := pilot.find_children("*", "MeshInstance3D", true, false).filter(func(m: Node) -> bool: return (m as Node3D).visible) if pilot else []
	var names := shown.map(func(m: Node) -> String: return String(m.name))
	all_ok = _check("B / E entra e já dirige, com o aventureiro da cintura para cima no banco", kart_race.state == "dirigindo"
			and kart_race.kart == car and not player.visible and get_viewport().get_camera_3d() == car.camera
			and names.any(func(n: String) -> bool: return n.ends_with("_Head")) and names.any(func(n: String) -> bool: return n.ends_with("_Body"))
			and not names.any(func(n: String) -> bool: return n.contains("Leg") or n.contains("Backpack")),
			"(%s)" % ", ".join(names)) and all_ok
	Input.action_press("olhar_direita")
	await _wait(0.4)
	Input.action_release("olhar_direita")
	var turned := car._cam_yaw
	await _wait(2.6)
	all_ok = _check("no kart, o analógico direito gira a câmera e ela volta para trás depois", absf(turned) > 0.5 and absf(car._cam_yaw) < 0.2,
			"(girou %.1f, voltou para %.2f)" % [turned, car._cam_yaw]) and all_ok
	var x0 := car.global_position.x
	Input.action_press("frente")
	await _wait(1.4)
	Input.action_release("frente")
	all_ok = _check("acelera e sai da vaga (para a pista, a leste)", car.global_position.x > x0 + 5.0 and kart_race.state == "dirigindo",
			"(andou %.1f m)" % (car.global_position.x - x0)) and all_ok
	# Entra pela LARGADA, vindo de fora da pista.
	var zone := kart_race._entry_zone
	car.global_position = Vector3(zone.position.x - 4.0, 0.4, zone.get_center().y)
	await get_tree().physics_frame
	await get_tree().physics_frame
	car.global_position = Vector3(zone.get_center().x, 0.4, zone.get_center().y)
	await get_tree().physics_frame
	await get_tree().physics_frame
	all_ok = _check("entrar pela LARGADA começa a corrida na largada", kart_race.state == "contagem"
			and car.global_position.distance_to(kart_race.start.origin) < 1.0) and all_ok
	await _wait_until(func() -> bool: return kart_race.state == "correndo", 5.0)
	for lap in KartRace.LAPS:
		for g in kart_race.gates:
			car.global_position = g + Vector3.UP * 0.5
			await get_tree().physics_frame
			await get_tree().physics_frame
	await _wait(0.3)
	all_ok = _check("três voltas: chegada com tempo, recorde e moedas, e continua dirigindo", kart_race.state == "dirigindo"
			and story.records.kart > 0.0 and story.coins == coins0 + KartRace.COINS + KartRace.RECORD_BONUS, "(%d moedas)" % (story.coins - coins0)) and all_ok
	await _press_key(KEY_E)
	await _wait(0.3)
	all_ok = _check("descer na pista: aventureiro fora dela e o carrinho de volta na vaga", kart_race.state == "a_pe" and player.visible
			and car.is_home() and not kart_race.on_track(player.global_position) and get_viewport().get_camera_3d() == player.camera
			and car.find_child("PilotoNoBanco", true, false) == null) and all_ok
	# Passeio pela ilha com outro carrinho, descer longe da pista e se afastar.
	var formula := cars[2]
	await _stand(formula.global_position + formula.global_basis.z * 2.6)
	await _wait(0.2)
	await _press_key(KEY_E)
	await _wait(0.2)
	all_ok = _check("entra em outro carrinho (o mais perto)", kart_race.kart == formula) and all_ok
	var meadow := _ground_point(Vector3(95, 0, 85))
	formula.global_position = meadow + Vector3.UP * 0.5
	await _wait(0.4)
	await _press_key(KEY_E)
	await _wait(0.3)
	all_ok = _check("descer pela ilha: o carro fica onde parou, o aventureiro do lado", kart_race.state == "a_pe" and not formula.is_home()
			and formula.global_position.distance_to(meadow) < 3.0 and player.global_position.distance_to(formula.global_position) < 4.0) and all_ok
	await _stand(meadow + Vector3(0, 0, 30))
	await _wait(0.3)
	all_ok = _check("a 30 m o carro continua lá", not formula.is_home()) and all_ok
	await _stand(meadow + Vector3(0, 0, 60))
	await _wait(0.3)
	all_ok = _check("a mais de 50 m o carro volta para a vaga", formula.is_home()) and all_ok
	# Golpes dentro do carrinho (passeando pelo campo): tira coração, dá tranco e o piloto pisca; a flecha que
	# acerta o carrinho vale; sem corações, fica tonto, desce e o carrinho volta para a vaga.
	var hit_car := cars[3]
	await _stand(hit_car.global_position + hit_car.global_basis.z * 2.6)
	await _wait(0.2)
	await _press_key(KEY_E)
	await _wait(0.2)
	hit_car.global_position = meadow + Vector3.UP * 0.5
	await _wait(0.4)
	player.god_mode = false
	hit_car.speed = 10.0
	var h0 := player.hearts
	player.take_damage(1, player.global_position + Vector3(1, 0, 0), "teste")
	var jolted := hit_car.speed < 5.0
	var blinked := false
	var hit_t := 0.0
	while hit_t < 0.4:
		await get_tree().process_frame
		hit_t += get_process_delta_time()
		blinked = blinked or not hit_car._head.visible
	all_ok = _check("no kart, golpe tira coração, dá tranco e o piloto pisca", player.hearts == h0 - 1 and jolted and blinked
			and kart_race.state == "dirigindo", "(%d -> %d corações, tranco %s, piscou %s, %s)" % [h0, player.hearts, jolted, blinked, kart_race.state]) and all_ok
	await _wait(player.invulnerable_time)
	all_ok = _check("no kart, o tempo invulnerável passa e o piloto para de piscar", player._invulnerable <= 0.0 and hit_car._head.visible) and all_ok
	var h1 := player.hearts
	var behind := hit_car.global_position - hit_car.global_basis.z * 8.0 + Vector3.UP * 1.6
	add_child(Projectile.create(Projectile.Kind.FLECHA, behind, player))
	await _wait_until(func() -> bool: return player.hearts < h1, 2.0)
	all_ok = _check("flecha que acerta o kart tira coração de quem dirige", player.hearts == h1 - 1, "(%d -> %d)" % [h1, player.hearts]) and all_ok
	player._invulnerable = 0.0
	player.hearts = 1
	player.take_damage(1, player.global_position + Vector3(1, 0, 0), "teste")
	await _wait(0.1)
	all_ok = _check("sem corações no kart: fica tonto, desce e o kart volta para a vaga", player.dizzy and kart_race.state == "a_pe"
			and hit_car.is_home() and player.visible and get_viewport().get_camera_3d() == player.camera,
			"(tonto %s, %s, na vaga %s, visível %s)" % [player.dizzy, kart_race.state, hit_car.is_home(), player.visible]) and all_ok
	await _wait_until(func() -> bool: return not player.dizzy, 6.0)
	player.god_mode = true
	# Cair no mar com o carrinho.
	var blue := cars[1]
	await _stand(blue.global_position + blue.global_basis.z * 2.6)
	await _wait(0.2)
	await _press_key(KEY_E)
	await _wait(0.2)
	blue.global_position = Vector3(0, -3.0, 300)
	await _wait(0.3)
	all_ok = _check("caiu no mar: o carrinho volta para a vaga", kart_race.state == "a_pe" and blue.is_home() and player.visible) and all_ok
	await _wait_until(func() -> bool: return not _splashing, 4.0)

	# Skate.
	all_ok = _check("pista de skate perto da cidade", skate_park.center.distance_to(Vector3(-72, 0, 98)) < 50.0,
			"(%.0f m da esquina)" % skate_park.center.distance_to(Vector3(-72, 0, 98))) and all_ok
	await _stand(skate_park.board.global_position + Vector3(1.5, 0, 0))
	await _wait(0.3)
	all_ok = _check("perto do skate, o aviso chama para pegar", skate_park.near and hint_label.visible and "skate" in hint_label.text) and all_ok
	await _press_key(KEY_E)
	await _wait(0.2)
	all_ok = _check("B / E pega o skate (some do chão, aparece nos pés)", player.skating and skate_park.state == "andando"
			and not skate_park.board.visible and is_instance_valid(player._board) and is_instance_valid(player._rider)) and all_ok
	# Perna empurrando: o pé do impulso desce até o chão e o skate ganha velocidade.
	player.global_position = _ground_point(skate_park.center + Vector3(-8, 0, 14)) + Vector3.UP * 0.3
	player._skate_heading = PI / 2.0
	player._skate_speed = 0.0
	await _wait(0.3)
	var lowest := INF
	Input.action_press("frente")
	var t := 0.0
	while t < 1.5:
		await get_tree().process_frame
		t += get_process_delta_time()
		lowest = minf(lowest, player._rider.right_foot_drop)
	Input.action_release("frente")
	all_ok = _check("dar impulso: o pé direito desce até o chão e o skate anda", player._skate_speed > 3.0
			and lowest < -Player.SKATE_LIFT * 0.6, "(%.1f m/s, pé %.2f abaixo da tábua)" % [player._skate_speed, -lowest]) and all_ok
	player.god_mode = false
	var skate_h := player.hearts
	var skate_v := player._skate_speed
	player.take_damage(1, player.global_position + Vector3(1, 0, 0), "teste")
	player.god_mode = true
	all_ok = _check("no skate, golpe tira coração e o skate perde o embalo (sem empurrão)", player.hearts == skate_h - 1 and player.skating
			and player._skate_speed < skate_v * 0.5 and player._knockback == Vector3.ZERO, "(%.1f -> %.1f m/s)" % [skate_v, player._skate_speed]) and all_ok
	var yaw0 := player.get_yaw()
	Input.action_press("olhar_direita")
	await _wait(0.4)
	Input.action_release("olhar_direita")
	await _wait(0.5)
	all_ok = _check("no skate, a câmera gira livre (não volta na hora)", absf(angle_difference(player.get_yaw(), yaw0)) > 0.5,
			"(%.1f)" % angle_difference(player.get_yaw(), yaw0)) and all_ok
	# Passar pela marca da sessão.
	player.global_position = skate_park.session_spot + Vector3.UP * 0.3
	await _wait(0.2)
	all_ok = _check("passar pela marca SESSÃO começa a sessão de pontos", skate_park.state == "sessao") and all_ok
	player.global_position = skate_park.center + Vector3(-5, 0.5, -10)
	player._skate_heading = PI
	player._skate_speed = 11.0
	player.velocity = Vector3(0, 0, -11)
	await get_tree().physics_frame
	var top := -INF
	var came_back := false
	t = 0.0
	while t < 4.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		top = maxf(top, player.global_position.y)
		if top > 1.5 and player.velocity.z > 1.0:
			came_back = true
	all_ok = _check("no half-pipe o skate sobe a rampa e volta", top > 1.5 and came_back, "(subiu %.1f m)" % top) and all_ok
	var s0 := skate_park.score
	player.skate_landed.emit(1.0, TAU * 1.02, true)
	all_ok = _check("pulo com giro 360 vale pontos (ar + meias voltas)", skate_park.score == s0 + SkatePark.trick_points(1.0, TAU * 1.02)
			and SkatePark.trick_points(1.0, TAU * 1.02) == 400 and SkatePark.trick_name(TAU * 1.02) == "Giro 360", "(+%d)" % (skate_park.score - s0)) and all_ok
	var s1 := skate_park.score
	player.skate_landed.emit(1.0, PI, false)
	all_ok = _check("pousar atravessado é tombo, sem pontos", skate_park.score == s1) and all_ok
	var coins1 := story.coins
	skate_park.time_left = 0.05
	await _wait(0.2)
	all_ok = _check("fim da sessão: recorde e moedas, e continua no skate", skate_park.state == "andando" and player.skating
			and story.records.skate == skate_park.score and story.coins == coins1 + mini(skate_park.score / 100, SkatePark.MAX_COINS),
			"(%d pontos)" % skate_park.score) and all_ok
	# Descer pela ilha: o skate fica no chão; longe, volta para a pista.
	var street := _ground_point(Vector3(-17.5, 0, 130))
	player.global_position = street + Vector3.UP * 0.3
	player._skate_speed = 0.0
	player.velocity = Vector3.ZERO
	await _wait(0.3)
	await _press_key(KEY_E)
	await _wait(0.2)
	all_ok = _check("B / E desce: o skate fica no chão onde parou", not player.skating and skate_park.state == "a_pe"
			and skate_park.board.visible and skate_park.board.global_position.distance_to(street) < 3.0 and not is_instance_valid(player._rider),
			"(skate %s, rua %s, estado %s, skating %s)" % [skate_park.board.global_position.snappedf(0.1), street.snappedf(0.1), skate_park.state, player.skating]) and all_ok
	await _stand(street + Vector3(0, 0, 60))
	await _wait(0.3)
	all_ok = _check("a mais de 50 m o skate volta para a pista", skate_park.board_at_home()) and all_ok
	print("ATIVIDADES OK" if all_ok else "ATIVIDADES COM FALHAS")
	get_tree().quit()


## Fotos dos veículos com o aventureiro no banco (os dois personagens) e do impulso no skate, de lado (precisa de janela).
## Uso: godot --path . -- --veiculos-captura
func _run_vehicles_capture() -> void:
	player.god_mode = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _wait(0.6)
	close_menus()
	var out := "res://tools/capturas/"
	var size := Vector2i(1280, 720)
	var row := kart_race.vehicles
	var mid := (row[0].global_position + row[row.size() - 1].global_position) * 0.5
	await _art_shot(out + "v01_vagas_vazias.png", size, mid + Vector3(9.0, 4.0, 3.0), mid + Vector3(0, 0.6, 0), 55.0)
	var n := 2
	for who in ["menina", "menino"]:
		player.set_character(who)
		for k in [0, 2, 3]:
			var v: Kart = row[k]
			v.drive(player)
			v.set_physics_process(false)
			var f := v.global_basis.z
			var side := v.global_basis.x
			await _art_shot(out + "v%02d_%s_%s.png" % [n, v.model_name, who], Vector2i(800, 600), v.global_position + f * 3.4 + side * 2.2 + Vector3.UP * 1.7,
					v.global_position + Vector3.UP * 0.8, 50.0)
			v.park()
			n += 1
	# Impulso no skate, de lado, num trecho plano da praça.
	player.set_character("menina")
	await _stand(_ground_point(Vector3(112, 0, 0)))
	player.start_skating()
	player._skate_heading = PI / 2.0
	player.visual.rotation.y = PI / 2.0
	await _wait(0.3)
	player.force_skate_push = true
	await _wait(0.4)
	for k in 8:
		await _wait(0.05)
		var p := player.global_position
		await _art_shot(out + "v1%d_skate_impulso.png" % k, Vector2i(800, 600), p + Vector3(1.2, 1.3, 4.6), p + Vector3(1.0, 0.9, 0), 45.0)
	player.force_skate_push = false
	print("capturas dos veículos em tools/capturas/")
	get_tree().quit()


## Fotos das atividades extras (precisa de janela): pista de kart, pista de skate e barcos no mar.
## Uso: godot --path . -- --atividades-captura
func _run_activities_capture() -> void:
	player.god_mode = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _wait(0.8)
	var out := "res://tools/capturas/"
	var size := Vector2i(1280, 720)
	var kart := Vector3(125, 0, 15)
	var skate := skate_park.center
	await _art_shot(out + "a01_kart_de_cima.png", size, kart + Vector3(0, 95, 0.5), kart, 50.0)
	await _art_shot(out + "a02_kart_largada.png", size, kart + Vector3(-34, 9, 28), kart + Vector3(-20, 1, 8), 60.0)
	await _art_shot(out + "a03_kart_curva.png", size, kart + Vector3(10, 12, -50), kart + Vector3(0, 0, -30), 60.0)
	await _art_shot(out + "a04_skate_de_cima.png", size, skate + Vector3(0, 70, 0.5), skate, 50.0)
	await _art_shot(out + "a05_skate_lado.png", size, skate + Vector3(18, 12, 34), skate + Vector3(-2, 1, -4), 60.0)
	await _art_shot(out + "a06_half_pipe.png", size, skate + Vector3(-12, 6, -2), skate + Vector3(-8, 1, -16), 60.0)
	await _art_shot(out + "a07_barcos_cais.png", size, Vector3(0, 8, 228), Vector3(0, 0, 275), 65.0)
	await _art_shot(out + "a14_skate_e_cidade.png", size, Vector3(-55, 30, 118), skate + Vector3(-5, 0, -5), 55.0)
	await _art_shot(out + "a15_fazenda_nova.png", size, Vector3(-120, 22, 30), Vector3(-120, 0, -6), 55.0)
	var sea: SeaTraffic = get_node("Barcos")
	for k in sea._ships.size():
		var ship: Node3D = sea._ships[k].no
		var from := ship.global_position * 0.62 + Vector3.UP * 6.0
		await _art_shot(out + "a08_navio_%d.png" % k, size, from, ship.global_position + Vector3.UP * 8.0, 40.0)
	# Em ação: kart andando (câmera do kart) e skate no ar no half-pipe.
	close_menus()
	await _stand(kart_race.paddock)
	var car := kart_race.vehicles[0]
	kart_race.enter(car)
	await _wait(0.3)
	await _shot("a09a_kart_vaga.png")
	car.global_position = Vector3(kart_race._entry_zone.get_center().x, 0.4, kart_race._entry_zone.get_center().y)
	kart_race._armed = true
	await _wait_until(func() -> bool: return kart_race.state == "correndo", 6.0)
	Input.action_press("frente")
	await _wait(1.4)
	await _shot("a09_kart_andando.png")
	Input.action_press("direita")
	await _wait(1.6)
	await _shot("a10_kart_curva.png")
	Input.action_release("direita")
	Input.action_release("frente")
	kart_race.leave()
	await _wait(0.4)
	await _stand(skate_park.entrance + Vector3(0, 0, 4))
	var to_park := skate_park.center - player.global_position
	player.set_yaw(atan2(-to_park.x, -to_park.z))
	await _wait(1.2)
	await _shot("a11_skate_aviso.png")
	skate_park.pick()
	await _wait(0.3)
	player.global_position = skate_park.center + Vector3(-5, 0.5, -10)
	player._skate_heading = PI
	player.set_yaw(0.0)
	player._skate_speed = 11.0
	await _wait(1.25)
	await _shot("a12_skate_no_ar.png")
	await _wait(0.8)
	var p := player.global_position
	await _art_shot(out + "a13_skate_half_pipe.png", size, p + Vector3(9.0, 1.5, 4.0), p + Vector3(0, 0.5, 0), 55.0)
	print("capturas das atividades em tools/capturas/")
	get_tree().quit()


## Foto da ilha vista de cima (precisa de janela), com marcas a cada 50 m para planejar onde pôr as coisas.
## Uso: godot --path . -- --mapa-captura
func _run_map_capture() -> void:
	player.god_mode = true
	await _wait(0.6)
	for x in range(-250, 251, 50):
		for z in range(-250, 251, 50):
			var label := Label3D.new()
			label.text = "%d,%d" % [x, z]
			label.font_size = 64
			label.outline_size = 16
			label.pixel_size = 0.05
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.no_depth_test = true
			add_child(label)
			label.global_position = Vector3(x, 30, z)
	await _art_shot("res://tools/capturas/mapa_de_cima.png", Vector2i(1400, 1400), Vector3(0, 700, 0.5), Vector3(0, 0, 0), 46.0)
	get_tree().quit()


## Fotos da banda tocando (precisa de janela): de frente, de lado e em três instantes, com um esqueleto
## de trompete do epílogo junto. Uso: godot --path . -- --banda-captura
func _run_band_capture() -> void:
	player.god_mode = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _wait(0.6)
	player.global_position = Ending.PLAZA + Vector3(0, 0.5, 14.0)
	var guest := spawn_townsperson({"nome": "TrompeteTeste", "modelo_caminho": Ending.SKELETONS % "Skeleton_Warrior", "atividade": "tocando",
		"item": "moradores/ToySoldier_Trumpet"}, _ground_point(Ending.PLAZA + Vector3(-3.1, 0, -11.2)), 0.0)
	await _wait(1.0)
	var out := "res://tools/capturas/"
	var size := Vector2i(1280, 720)
	var stage := Ending.STAGE_TOP + Vector3(0, 1.0, 0)
	for k in 3:
		await _art_shot(out + "b0%d_banda_frente.png" % (k + 1), size, stage + Vector3(0.5, 1.2, 7.0), stage + Vector3(-0.5, 0.2, 0), 50.0)
		await _wait(0.37)
	await _art_shot(out + "b04_banda_lado.png", size, stage + Vector3(6.5, 1.0, 1.5), stage + Vector3(-0.5, 0.2, -0.2), 50.0)
	await _art_shot(out + "b05_urso_perto.png", size, stage + Vector3(0.6, 0.6, 3.2), stage + Vector3(0, -0.1, -0.9), 45.0)
	await _art_shot(out + "b06_trompetes_perto.png", size, stage + Vector3(-2.4, 0.9, 3.0), stage + Vector3(-1.8, 0.4, -0.6), 45.0)
	guest.queue_free()
	print("capturas da banda em tools/capturas/")
	get_tree().quit()


## Fim do jogo: desfecho em cena no cemitério, festa à noite com os convidados, créditos ao subir no
## palco e o pós-jogo de dia. Uso: godot --headless --path . -- --final
func _run_ending_test() -> void:
	var all_ok := true
	player.god_mode = true
	story.fast = true
	await _wait(0.5)
	story.skip_to_cemetery()
	var cemiterio: Defense = story.defenses.cemiterio
	await _stand(cemiterio.center + Vector3(0, 0, 2))
	await _wait_until(func() -> bool: return cemiterio.state == Defense.State.ONDA, 6.0)
	for k in 2:
		await _clear_wave(cemiterio, false)
		await _wait_until(func() -> bool: return cemiterio.state == Defense.State.ONDA, 6.0)
	await _wait_until(func() -> bool: return is_instance_valid(cemiterio.boss) and cemiterio.boss.phase == Boss.Phase.LUTANDO, 8.0)
	var mestre := cemiterio.boss as BossMestre
	await _wait_until(func() -> bool: return _wave_enemies().all(func(e: SkeletonEnemy) -> bool: return e.state != SkeletonEnemy.State.ACORDANDO), 4.0)
	for e in _wave_enemies():
		e.take_hit(99.0, e.global_position + Vector3.UP, e.hurtboxes[0])
	mestre.take_hit(999.0, mestre.global_position + Vector3.UP * 2.0, mestre.hurtboxes[1])
	await _wait_until(func() -> bool: return ending.in_cutscene, 12.0)
	var cam := get_viewport().get_camera_3d()
	all_ok = _check("Mestre vencido: desfecho em cena, sem controle e sem interface", ending.in_cutscene and not player.input_enabled
			and cam != null and cam.name == "CameraDoDesfecho" and not hearts_bar.visible and not crosshair.visible,
			"(câmera %s)" % (cam.name if cam else "nenhuma")) and all_ok
	await _wait(1.0)
	var friends := get_tree().get_nodes_in_group(&"convidados").filter(func(n: Node) -> bool:
		return String(n.name).begins_with("AmigoDoCemiterio") and (n as Node3D).global_position.distance_to(mestre.global_position) < 12.0)
	all_ok = _check("convite entregue: esqueletos saem do chão comemorando", friends.size() >= 4, "(%d)" % friends.size()) and all_ok
	await _wait_until(func() -> bool: return story.stage == "festa", 10.0)
	all_ok = _check("na noite seguinte: festa na praça, à noite", story.stage == "festa" and ending.night
			and sky_material.sky_top_color.v < 0.4 and player.global_position.distance_to(Ending.PLAZA) < 20.0
			and current_checkpoint.name == "Praca", "(etapa %s)" % story.stage) and all_ok
	all_ok = _check("foto do desfecho no álbum", story.photos.size() == 1 and story.photos[0].legenda == "O Mestre Ossinho tirou a coroa",
			"(%d fotos)" % story.photos.size()) and all_ok
	var guests := get_tree().get_nodes_in_group(&"convidados").filter(func(n: Node) -> bool:
		return (n as Node3D).global_position.distance_to(Ending.PLAZA) < 45.0 and not n.is_queued_for_deletion())
	all_ok = _check("convidados esqueletos chegam de balão na praça", guests.size() >= 12, "(%d)" % guests.size()) and all_ok
	var island_skeletons := enemies.filter(func(e: SkeletonEnemy) -> bool:
		return is_instance_valid(e) and not e.is_queued_for_deletion() and not e.has_meta("onda"))
	all_ok = _check("os esqueletos da ilha viraram amigos (sem luta)", island_skeletons.is_empty()
			and get_tree().get_nodes_in_group(&"convidados").any(func(n: Node) -> bool: return String(n.name).begins_with("Amigo")),
			"(%d inimigos: %s)" % [island_skeletons.size(), ", ".join(island_skeletons.map(func(e: SkeletonEnemy) -> String: return e.name))]) and all_ok
	await _wait_until(func() -> bool: return not ending.in_cutscene, 6.0)
	await _wait_until(func() -> bool: return get_tree().get_nodes_in_group(&"convidados").all(func(n: Node) -> bool:
		return not (n is Townsperson) or not (n as Townsperson).is_dropping()), 6.0)
	var landed := guests.filter(func(n: Node) -> bool:
		return n is Townsperson and absf((n as Node3D).global_position.y - _ground_point((n as Node3D).global_position).y) < 0.6)
	all_ok = _check("todos pousaram e a interface voltou", landed.size() == guests.filter(func(n: Node) -> bool: return n is Townsperson).size()
			and player.input_enabled and hearts_bar.visible, "(%d de %d)" % [landed.size(), guests.size()]) and all_ok
	var bench := get_node_or_null("ConvidadoMestre") as Townsperson
	var crown := bench.find_child("Necromancer_Crown", true, false) as Node3D if bench else null
	all_ok = _check("Mestre sem coroa sentado com o vovô", bench != null and bench.activity == "sentado_banco" and crown != null and not crown.visible
			and bench.global_position.distance_to(get_node("Vovo").global_position) < 2.0) and all_ok
	await _wait(1.0)
	all_ok = _check("foto da festa no álbum e objetivo aponta o palco", story.photos.size() == 2 and "palco" in story.objective_text
			and story.objective_target.distance_to(Ending.STAGE_TOP) < 3.0, "(%d fotos, \"%s\")" % [story.photos.size(), story.objective_text]) and all_ok
	await _stand(Ending.STAGE_TOP + Vector3(0, 0.3, 0))
	await _wait_until(func() -> bool: return ending.credits_running, 3.0)
	all_ok = _check("subir no palco abre os créditos com o álbum", ending.credits_running and get_tree().paused
			and get_children().any(func(n: Node) -> bool: return n is Credits)) and all_ok
	await _wait_until(func() -> bool: return story.stage == "fim", 20.0)
	await _wait(0.5)
	var orb: StandardMaterial3D = story.lanterns.Oeste.orb.material_override
	all_ok = _check("pós-jogo: de dia, lanternas de festa e a brincadeira na praia", story.stage == "fim" and not ending.night
			and not get_tree().paused and sky_material.sky_top_color == Color("#4f9cf0") and orb.emission != Color("#b06cff")
			and is_instance_valid(party_mode) and get_node_or_null("MestreDaBrincadeira") != null and get_node_or_null("ConvidadoMestre") == null) and all_ok
	all_ok = _check("objetivo do pós-jogo chama para a Festa sem fim", "Festa sem fim" in story.objective_text, "(\"%s\")" % story.objective_text) and all_ok
	print("FINAL OK" if all_ok else "FINAL COM FALHAS")
	get_tree().quit()


## Atalho dos testes e fotos: tudo vencido, direto para o pós-jogo.
func _skip_to_post_game() -> void:
	story.skip_to_cemetery()
	var cemiterio: Defense = story.defenses.cemiterio
	cemiterio.state = Defense.State.VENCIDA
	cemiterio.active = false
	ending.post_game(false)


## "Festa sem fim" no cemitério: começa no círculo, ondas que crescem, moedas e recorde por onda, guardião
## na onda 5 e fim ao ficar tonto. Uso: godot --headless --path . -- --festa-sem-fim
func _run_endless_test() -> void:
	var all_ok := true
	story.fast = true
	await _wait(0.5)
	_skip_to_post_game()
	await _wait(0.3)
	var pd := party_mode
	all_ok = _check("pós-jogo: Festa sem fim no cemitério com o Mestre", is_instance_valid(pd) and pd.state == EndlessParty.State.PARADA
			and pd.center.distance_to(story.defenses.cemiterio.center) < 1.0 and is_instance_valid(pd.host) and pd.cracks.size() >= 6,
			"(%d rachaduras)" % pd.cracks.size()) and all_ok
	await _stand(pd.center)
	await _wait_until(func() -> bool: return pd.state == EndlessParty.State.ONDA, 4.0)
	await _wait_until(func() -> bool: return pd.alive.size() == EndlessParty.wave_list(1).size(), 6.0)
	all_ok = _check("ficar no círculo começa a onda 1 com esqueletos de verdade", pd.wave == 1 and pd.alive.size() == 4
			and pd.alive.all(func(e: Node) -> bool: return e is SkeletonEnemy and e.has_meta("onda")), "(%d)" % pd.alive.size()) and all_ok
	var coins_before: int = story.coins
	await _stand(pd.center + Vector3(0, 0, 6))
	await _clear_endless(pd)
	await _wait_until(func() -> bool: return pd.state == EndlessParty.State.INTERVALO, 4.0)
	all_ok = _check("onda vencida dá moedas, recorde e intervalo com munição e coração", story.coins == coins_before + EndlessParty.wave_coins(1)
			and story.records.festa == 1 and _near_count(AmmoPickup, pd.center, 3.0) >= 1, "(%d moedas)" % story.coins) and all_ok
	await _wait_until(func() -> bool: return pd.state == EndlessParty.State.ONDA, 4.0)
	await _wait_until(func() -> bool: return pd.alive.size() >= 5, 6.0)
	all_ok = _check("onda 2 é maior e traz Rogue", pd.wave == 2 and pd.alive.any(func(e: Node) -> bool: return e is SkeletonEnemy and e.type_name == "Skeleton_Rogue"),
			"(onda %d: %s)" % [pd.wave, ", ".join(pd.alive.map(func(e: Node) -> String: return e.type_name if e is SkeletonEnemy else e.name))]) and all_ok
	await _clear_endless(pd)
	await _wait_until(func() -> bool: return pd.state == EndlessParty.State.INTERVALO, 4.0)
	pd.wave = 4
	pd._timer = 0.0
	await _wait_until(func() -> bool: return pd.state == EndlessParty.State.ONDA and is_instance_valid(pd.boss), 4.0)
	all_ok = _check("onda 5 traz um guardião (o Ossão)", pd.wave == 5 and pd.boss is BossOssao and boss_bar.visible) and all_ok
	player.god_mode = false
	for k in player.hearts + 1:
		player._invulnerable = 0.0
		player.take_damage(1, player.global_position + Vector3(1, 0, 0), "teste")
	await _wait_until(func() -> bool: return pd.state == EndlessParty.State.FIM, 3.0)
	await _wait(1.5)
	all_ok = _check("tonto: a festa acaba, os esqueletos afundam e o recorde fica", pd.state != EndlessParty.State.ONDA and pd.alive.is_empty()
			and story.records.festa == 2 and pd.boss == null, "(recorde %d)" % story.records.festa) and all_ok
	await _wait_until(func() -> bool: return pd.state == EndlessParty.State.PARADA, 5.0)
	all_ok = _check("depois dá para começar de novo", pd.state == EndlessParty.State.PARADA and "Recorde: 2" in pd._board.text) and all_ok
	print("FESTA-SEM-FIM OK" if all_ok else "FESTA-SEM-FIM COM FALHAS")
	get_tree().quit()


## Lojinha: a primeira moeda acende a seta dourada, o tapete abre o menu, comprar, equipar, melhorias, caixa de
## munição com o blaster comprado e o que vai para o salvamento. Uso: godot --headless --path . -- --loja
func _run_shop_test() -> void:
	var all_ok := true
	player.god_mode = true
	story.fast = true
	await _wait(0.5)
	close_menus()
	await _wait(0.3)
	all_ok = _check("lojinha montada na praia, sem seta antes da primeira moeda", is_instance_valid(shop)
			and story.shop_target() == Vector3.INF and not coins_bar.visible) and all_ok
	story.add_coins(100, player.global_position)
	await _wait(0.2)
	all_ok = _check("primeira moeda: contador e seta dourada para a lojinha", story.coins == 100 and coins_bar.visible
			and story.shop_target() != Vector3.INF and shop_marker.visible and "Lojinha" in banner_subtitle.text + banner_title.text + str(_banners)) and all_ok
	await _stand(shop._mat_point)
	await _wait_until(func() -> bool: return menu_state == "loja", 2.0)
	all_ok = _check("parar no tapete abre a lojinha e apaga a seta", menu_state == "loja" and shop_menu.visible and story.shop_visited
			and story.shop_target() == Vector3.INF and get_tree().paused) and all_ok
	var r := shop_menu.buy("bombom")
	all_ok = _check("sem moedas não compra", r == "sem_moedas" and story.coins == 100 and not player.has_weapon("bombom")) and all_ok
	r = shop_menu.buy("jujuba")
	await get_tree().process_frame
	all_ok = _check("comprar a Jujuba: desconta, equipa na seta de cima e vai para a mão", r == "comprou" and story.coins == 40
			and player.has_weapon("jujuba") and player.equipped[0] == "jujuba" and player.current_weapon().id == "jujuba" and _hand_model() == "blaster-k.glb",
			"(%s, %d moedas, %s)" % [r, story.coins, _hand_model()]) and all_ok
	r = shop_menu.buy("pacoca")
	all_ok = _check("usar a Paçoca de volta", r == "equipou" and player.equipped[0] == "pacoca" and player.has_weapon("jujuba")) and all_ok
	r = shop_menu.buy("granulado")
	all_ok = _check("o blaster da história também se compra (Granulado, 40)", r == "comprou" and player.has_weapon("granulado") and story.coins == 0) and all_ok
	story.add_coins(70, player.global_position)
	r = shop_menu.buy("granada_extra")
	all_ok = _check("+1 Brigadeiro: cabem 4 granadas", r == "comprou" and player.grenade_max == 4 and player.grenades == 4 and story.coins == 0) and all_ok
	all_ok = _check("melhoria comprada não se compra de novo", shop_menu.buy("granada_extra") == "nada" and story.coins == 0) and all_ok
	shop_menu.open_preview("pipoqueira")
	await get_tree().process_frame
	all_ok = _check("prévia mostra o blaster girando, o tipo, o dano e as barras", shop_menu.in_preview() and shop_menu._turntable.get_child_count() >= 1
			and shop_menu._p_type.text == "ESCOPETA" and shop_menu._p_damage.text == "4,2" and shop_menu._p_bars["Força"].value == 4
			and shop_menu._p_action.text.begins_with("Comprar"), "(%s, %s)" % [shop_menu._p_type.text, shop_menu._p_damage.text]) and all_ok
	shop_menu.back()
	all_ok = _check("voltar da prévia mostra os cartões", not shop_menu.in_preview() and shop_menu._grid.visible) and all_ok
	close_menus()
	await _wait(0.3)
	shop_menu.buy("jujuba")
	player._fire_cooldown = 0.0
	player._switch_left = 0.0
	player.fire()
	all_ok = _check("a Jujuba atira com o pente dela", player.current_weapon().id == "jujuba" and player.mag() == 15 and player.reserve() == -1,
			"(%s %d / %d)" % [player.current_weapon().id, player.mag(), player.reserve()]) and all_ok
	story.add_coins(90, player.global_position)
	shop_menu.buy("beijinho")
	player.ammo.beijinho.reserve = 0
	player.add_ammo_crate()
	all_ok = _check("caixa de munição completa o blaster comprado equipado", player.equipped[1] == "beijinho" and player.ammo.beijinho.reserve == 45,
			"(%d)" % player.ammo.beijinho.reserve) and all_ok
	var snap := story.snapshot()
	all_ok = _check("salvamento guarda moedas, equipados, compras e melhorias", snap.moedas == story.coins and "jujuba" in snap.equipados
			and "beijinho" in snap.blasters and "granada_extra" in snap.melhorias and snap.loja_visitada) and all_ok
	print("LOJA OK" if all_ok else "LOJA COM FALHAS")
	get_tree().quit()


## Derruba os esqueletos da onda atual da Festa sem fim, conforme saem do chão.
func _clear_endless(pd: EndlessParty) -> void:
	var t := 0.0
	var start := pd.wave
	while t < 20.0 and pd.state == EndlessParty.State.ONDA and pd.wave == start:
		for e in pd.alive.duplicate():
			if e is SkeletonEnemy and is_instance_valid(e) and e.hurtboxes[0].is_active():
				e.take_hit(99.0, e.global_position + Vector3.UP, e.hurtboxes[0])
		await get_tree().physics_frame
		t += get_physics_process_delta_time()


## Salvar e continuar: vence o prólogo, recarrega a ilha, continua do mesmo ponto e testa a "Nova campanha"
## da pausa. Usa outro arquivo de campanha. Uso: godot --headless --path . -- --salvar
func _run_save_test() -> void:
	SaveGame.path = "user://teste_campanha.json"
	SaveGame.enabled = true
	story.fast = true
	await _wait(0.4)
	match SaveGame.test_phase:
		0:
			SaveGame.erase()
			SaveGame.test_ok = true
			player.god_mode = true
			player.set_character("menina")
			close_menus()
			await _wait(0.3)
			_save_check("começar a campanha já salva o prólogo", SaveGame.read().get("etapa", "") == "prologo")
			var praca: Defense = story.defenses.praca
			await _stand(praca.center + Vector3(0, 0, -6))
			var t := 0.0
			while praca.state != Defense.State.VENCIDA and t < 60.0:
				await _wait_until(func() -> bool: return praca.state in [Defense.State.ONDA, Defense.State.VENCIDA], 6.0)
				if praca.state == Defense.State.ONDA:
					await _clear_wave(praca)
				t += 1.0
			await _wait(0.5)
			player.unlock_weapon("granulado")
			player.add_max_heart()
			story.records.festa = 3
			story.add_coins(150, player.global_position)
			shop_menu.buy("jujuba")
			story.save()
			var data := SaveGame.read()
			_save_check("vencer a praia salva a etapa, a defesa, o personagem e a bandeira", data.get("etapa", "") == "cidade"
					and "praca" in data.get("vencidas", []) and data.get("personagem", "") == "menina" and data.get("bandeira", "") == "Praca",
					"(%s)" % JSON.stringify(data).left(160))
			SaveGame.test_phase = 1
			get_tree().reload_current_scene()
		1:
			open_menu("inicio")
			_save_check("menu inicial oferece Continuar com a etapa salva", start_panel.visible and _continue_button.visible
					and "Lanternas da cidade" in _continue_button.text, "(\"%s\")" % _continue_button.text)
			_continue_campaign()
			await _wait(0.5)
			_save_check("continuar volta na cidade, com a praia vencida e as lanternas acesas", story.stage == "cidade"
					and story.defenses.praca.state == Defense.State.VENCIDA and story.defenses.oeste.active and story.defenses.leste.active
					and story.lanterns.Oeste.lit and menu_state == "")
			_save_check("continuar mantém blasters, corações, personagem e recordes", player.has_weapon("granulado")
					and player.max_hearts == 6 and player.character_name == "menina" and story.records.festa == 3
					and story.coins == 90 and player.has_weapon("jujuba") and player.equipped[0] == "jujuba" and coins_bar.visible,
					"(%d corações, %s)" % [player.max_hearts, player.character_name])
			open_menu("pausa")
			await get_tree().process_frame
			_pause_buttons[3].pressed.emit()
			await get_tree().process_frame
			_save_check("Nova campanha na pausa pede confirmação", menu_state == "confirmar" and confirm_panel.visible
					and _pause_buttons[3].text == "Nova campanha")
			SaveGame.test_phase = 2
			_confirm_buttons[0].pressed.emit()
		2:
			_save_check("nova campanha: apaga o salvo e volta do começo", not SaveGame.exists() and SaveGame.go_new
					and story.stage == "antes" and story.defenses.praca.state != Defense.State.VENCIDA)
			SaveGame.go_new = false
			# Campanha salva já na festa (depois do desfecho): continuar volta na praça, à noite.
			# Gravado como a versão 1 (antes das moedas): ao continuar, ganha as moedas dos guardiões vencidos.
			var old := FileAccess.open(SaveGame.path, FileAccess.WRITE)
			old.store_string(JSON.stringify({"etapa": "festa", "vencidas": Story.REGIONS.keys(), "blasters": ["pacoca", "granulado", "pipoqueira", "pe_de_moleque"],
				"coracoes": 7, "personagem": "menino", "bandeira": "TopoDoMorro", "recompensas": [], "fotos": [{"legenda": "Teste", "arquivo": ""}],
				"recordes": {"festa": 2, "tiro": 7}, "versao": 1}))
			old.close()
			SaveGame.test_phase = 3
			get_tree().reload_current_scene()
		3:
			_continue_campaign()
			await _wait(0.5)
			var guests := get_tree().get_nodes_in_group(&"convidados").filter(func(n: Node) -> bool: return (n as Node3D).global_position.distance_to(Ending.PLAZA) < 45.0)
			_save_check("continuar na festa: praça à noite, convidados e recordes", story.stage == "festa" and ending.night and guests.size() >= 12
					and player.global_position.distance_to(Ending.PLAZA) < 20.0 and gallery.hits == 7 and story.photos.size() == 1
					and story.defenses.values().all(func(d: Defense) -> bool: return d.state == Defense.State.VENCIDA and not d.active),
					"(%s, %d convidados, %d acertos)" % [story.stage, guests.size(), gallery.hits])
			_save_check("campanha antiga ganha as moedas dos guardiões (350 menos os 3 blasters, 150)", story.coins == 200 and story.coins_ever,
					"(%d moedas)" % story.coins)
			SaveGame.erase()
			print("SALVAR OK" if SaveGame.test_ok else "SALVAR COM FALHAS")
			get_tree().quit()


func _save_check(label: String, ok: bool, detail := "") -> void:
	SaveGame.test_ok = _check(label, ok, detail) and SaveGame.test_ok


## Fotos do fim (precisa de janela): desfecho, festa à noite, créditos, pós-jogo e "Defender a festa".
## Uso: godot --path . -- --final-captura
func _run_ending_capture() -> void:
	player.god_mode = true
	story.fast = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var out := "res://tools/capturas/"
	var size := Vector2i(1280, 720)
	await _wait(0.6)
	story.skip_to_cemetery()
	var cemiterio: Defense = story.defenses.cemiterio
	story.fast = true
	await _stand(cemiterio.center + Vector3(0, 0, 2))
	await _wait_until(func() -> bool: return cemiterio.state == Defense.State.ONDA, 6.0)
	for k in 2:
		await _clear_wave(cemiterio, false)
		await _wait_until(func() -> bool: return cemiterio.state == Defense.State.ONDA, 6.0)
	await _wait_until(func() -> bool: return is_instance_valid(cemiterio.boss) and cemiterio.boss.phase == Boss.Phase.LUTANDO, 8.0)
	var mestre := cemiterio.boss as BossMestre
	await _wait_until(func() -> bool: return _wave_enemies().all(func(e: SkeletonEnemy) -> bool: return e.state != SkeletonEnemy.State.ACORDANDO), 4.0)
	for e in _wave_enemies():
		e.take_hit(99.0, e.global_position + Vector3.UP, e.hurtboxes[0])
	story.fast = false
	for d in story.defenses.values():
		d.fast = true
	mestre.take_hit(999.0, mestre.global_position + Vector3.UP * 2.0, mestre.hurtboxes[1])
	await _wait_until(func() -> bool: return ending.in_cutscene, 12.0)
	await _wait(3.4)
	await _shot("f01_desfecho_convite.png")
	await _wait(2.6)
	await _shot("f02_desfecho_amigos.png")
	await _wait_until(func() -> bool: return story.stage == "festa", 14.0)
	await _wait(1.5)
	await _shot("f03_noite_seguinte.png")
	await _wait(5.0)
	await _shot("f04_festa_chegando.png")
	await _wait(5.0)
	await _art_shot(out + "f05_festa_praca.png", size, Ending.PLAZA + Vector3(10.0, 7.0, 16.0), Ending.PLAZA + Vector3(-1.0, 1.5, -4.0), 60.0)
	await _art_shot(out + "f06_festa_palco.png", size, Ending.PLAZA + Vector3(-3.0, 3.0, -3.0), Ending.STAGE_TOP + Vector3(0, 1.5, 0), 60.0)
	var vovo := get_node("Vovo") as Townsperson
	var vb := vovo.visual.global_basis
	await _art_shot(out + "f07_mestre_e_vovo.png", size, vovo.global_position + vb.z * 4.0 + vb.x * 0.5 + Vector3.UP * 1.8,
			vovo.global_position + vb.x * 0.5 + Vector3.UP * 0.8, 55.0)
	await _art_shot(out + "f08_torre_e_palhaco.png", size, Ending.PLAZA + Vector3(1.0, 4.0, 4.0), Ending.PLAZA + Vector3(Ending.TOWER_SPOT.x, 3.0, Ending.TOWER_SPOT.y), 60.0)
	if is_instance_valid(gallery):
		await _art_shot(out + "f09_mira_torta_tiro.png", size, gallery.global_transform * Vector3(-0.5, 2.4, 2.2), gallery.global_transform * Vector3(-3.5, 1.2, -1.8), 60.0)
	await _art_shot(out + "f10_fogos_ceu.png", size, Ending.PLAZA + Vector3(0, 2.0, 20.0), Ending.PLAZA + Vector3(0, 18.0, -20.0), 70.0)
	await _stand(Ending.STAGE_TOP + Vector3(0, 0.3, 0))
	await _wait_until(func() -> bool: return ending.credits_running, 3.0)
	await _wait(1.6)
	await _shot("f11_creditos_album.png")
	var c: Credits = get_children().filter(func(n: Node) -> bool: return n is Credits)[0]
	c._skip = true
	await _wait_until(func() -> bool: return story.stage == "fim", 10.0)
	await _wait(2.0)
	await _art_shot(out + "f12_pos_jogo_praca.png", size, Ending.PLAZA + Vector3(10.0, 7.0, 16.0), Ending.PLAZA + Vector3(-1.0, 1.5, -4.0), 60.0)
	var pd := party_mode
	await _art_shot(out + "f13_festa_sem_fim.png", size, pd.center + Vector3(9.0, 6.0, 9.0), pd.center + Vector3(0, 1.0, 0), 60.0)
	await _stand(pd.center)
	await _wait_until(func() -> bool: return pd.state == EndlessParty.State.ONDA and pd.alive.size() >= 3, 12.0)
	await _wait(2.5)
	await _art_shot(out + "f14_festa_sem_fim_onda.png", size, pd.center + Vector3(-7.0, 5.0, 10.0), pd.center + Vector3(0, 1.0, 0), 65.0)
	print("capturas do fim em tools/capturas/")
	get_tree().quit()


## Fotos da defesa final e do Mestre Ossinho (precisa de janela). Uso: godot --path . -- --cemiterio-captura
func _run_cemetery_capture() -> void:
	player.god_mode = true
	story.fast = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _wait(0.6)
	story.skip_to_cemetery()
	var cemiterio: Defense = story.defenses.cemiterio
	var out := "res://tools/capturas/"
	var size := Vector2i(1280, 720)
	# No fundo do pátio: o Mestre fica entre o aventureiro e o portão, e o arco vai para o fundo da foto.
	await _stand(cemiterio.center + Vector3(2.5, 0, -5.0))
	await _wait_until(func() -> bool: return cemiterio.state == Defense.State.ONDA, 6.0)
	await _wait(1.5)
	await _art_shot(out + "c01_defesa_no_cemiterio.png", size, cemiterio.center + Vector3(5.5, 6.5, 8.5), cemiterio.center + Vector3(-1, 0.5, -2), 60.0)
	for k in 2:
		await _clear_wave(cemiterio, false)
		await _wait_until(func() -> bool: return cemiterio.state == Defense.State.ONDA, 6.0)
	await _wait_until(func() -> bool: return is_instance_valid(cemiterio.boss) and cemiterio.boss.phase == Boss.Phase.LUTANDO, 8.0)
	var mestre := cemiterio.boss as BossMestre
	await _wait(1.0)
	for e in _wave_enemies():
		e.visible = false
		e.set_physics_process(false)
	# Câmera livre atrás do aventureiro, um pouco acima, olhando o Mestre.
	var view := func() -> Array:
		var to_m := mestre.global_position - player.global_position
		to_m.y = 0.0
		var side := to_m.normalized().cross(Vector3.UP)
		return [player.global_position - to_m.normalized() * 3.5 + side * 2.0 + Vector3.UP * 4.0, mestre.global_position + Vector3.UP * 2.6]
	mestre._cast_timer = 0.0
	await _wait(0.4)
	var v: Array = view.call()
	await _art_shot(out + "c02_mestre_ossinho.png", size, v[0], v[1], 55.0)
	mestre.take_hit(mestre.health - 31.0, mestre.global_position + Vector3.UP * 2.0, mestre.hurtboxes[1])
	await _wait(0.6)
	v = view.call()
	await _art_shot(out + "c03_escudo_de_bolhas.png", size, v[0], v[1], 55.0)
	for b in mestre.shield.duplicate():
		b.take_hit(1.0, b.global_position, null)
	await _wait(0.8)
	v = view.call()
	await _art_shot(out + "c04_mestre_tonto.png", size, v[0], v[1], 55.0)
	mestre._dizzy = 0.0
	mestre.take_hit(mestre.health - 15.0, mestre.global_position + Vector3.UP * 2.0, mestre.hurtboxes[1])
	await _wait(0.2)
	mestre._release()
	await _wait(1.0)
	v = view.call()
	await _art_shot(out + "c05_bolha_gigante.png", size, v[0], v[1], 60.0)
	for n in _projectiles(Projectile.Kind.BOLHA):
		n.queue_free()
	mestre.take_hit(999.0, mestre.global_position + Vector3.UP * 2.0, mestre.hurtboxes[1])
	await _wait(4.6)
	var front := mestre.global_position + mestre.forward() * 7.0 + Vector3.UP * 3.0
	await _art_shot(out + "c06_sem_coroa.png", size, front, mestre.global_position + Vector3.UP * 1.2 + mestre.forward() * 1.5, 50.0)
	for e in _wave_enemies():
		e.visible = true
		e.set_physics_process(true)
	await _clear_wave(cemiterio, false)
	await _wait(1.0)
	await _shot("c07_convite.png")
	get_tree().quit()


## Fotos dos guardiões da mata (precisa de janela). Uso: godot --path . -- --mata-captura
func _run_forest_capture() -> void:
	player.god_mode = true
	story.fast = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _wait(0.6)
	story.skip_to_forest()
	var clareira: Defense = story.defenses.clareira
	await _stand(clareira.center + Vector3(3, 0, 13))
	await _wait_until(func() -> bool: return clareira.state == Defense.State.ONDA, 6.0)
	await _clear_wave(clareira)
	# Golem de Ossos da segunda onda: chegando e batendo no chão.
	await _wait_until(func() -> bool: return clareira.state == Defense.State.ONDA, 6.0)
	await _wait_until(func() -> bool: return _awake_wave_enemy("Skeleton_Golem") != null, 8.0)
	var golem := _awake_wave_enemy("Skeleton_Golem")
	if golem != null:
		for e in _wave_enemies():
			if e != golem:
				e.visible = false
				e.set_physics_process(false)
		var away := player.global_position - golem.global_position
		away.y = 0.0
		await _stand(golem.global_position + away.normalized() * 10.0)
		await _aim_for(golem, 2.5, 0.8)
		await _shot("m00a_golem.png")
		golem._start_attack()
		await _wait(1.25)
		await _aim_for(golem, 1.0, 0.15)
		await _shot("m00b_golem_pancada.png")
		for e in _wave_enemies():
			e.visible = true
			e.set_physics_process(true)
	await _clear_wave(clareira)
	await _wait_until(func() -> bool: return is_instance_valid(clareira.boss) and clareira.boss.phase == Boss.Phase.LUTANDO, 8.0)
	var torre := clareira.boss as BossTorre
	for e in _wave_enemies():
		e.visible = false
	await _aim_for(torre, 4.5, 0.6)
	await _shot("m01_torre.png")
	var seg: Dictionary = torre.segments[1]
	torre.take_hit(99.0, (seg.holder as Node3D).global_position, seg.hurtboxes[0])
	await _wait(1.6)
	await _aim_for(torre, 6.0, 0.3)
	await _shot("m02_torre_andar_de_balao.png")
	await _clear_wave(clareira)
	await _wait(2.0)
	var ventos: Defense = story.defenses.ventos
	await _stand(ventos.center + Vector3(3, 0, 13))
	for k in 2:
		await _wait_until(func() -> bool: return ventos.state == Defense.State.ONDA, 6.0)
		await _clear_wave(ventos)
	await _wait_until(func() -> bool: return is_instance_valid(ventos.boss) and ventos.boss.phase == Boss.Phase.LUTANDO, 8.0)
	var mz := ventos.boss as BossMinionzao
	for e in _wave_enemies():
		e.visible = false
	mz._charge_cooldown = 0.0
	mz._rest()
	mz._move_time = 0.8
	await _wait_until(func() -> bool: return is_instance_valid(mz._stripe) and mz._stripe.visible, 4.0)
	await _wait(0.5)
	player.global_position += Vector3(5, 0, 0)
	await _aim_for(mz, 3.0, 0.3)
	await _shot("m03_minionzao_faixa.png")
	await _wait_until(func() -> bool: return mz.is_dizzy(), 4.0)
	await _wait(0.4)
	await _aim_for(mz, 6.0, 0.3)
	await _shot("m04_minionzao_tonto.png")
	await _clear_wave(ventos)
	await _wait(2.5)
	await _stand(Vector3(14, 27, 16))
	player.aim_at(Vector3(0, 30, 0))
	await _wait(0.6)
	await _shot("m05_cemiterio_aberto.png")
	await _stand(Vector3(9, 27, 0))
	await _wait(0.8)
	await _shot("m06_fim_desta_versao.png")
	get_tree().quit()


func _run_smoke() -> void:
	var minion := enemies[0]
	for anim_name in ["especial/Skeletons_Death", "especial/Skeletons_Death_Resurrect", "especial/Skeletons_Awaken_Floor", "especial/Skeletons_Taunt", "tiro/Ranged_1H_Shoot"]:
		var lib_name: String = anim_name.get_slice("/", 0)
		var lib := AnimUtil.library(lib_name)
		print("duração ", anim_name, ": ", lib.get_animation(StringName(anim_name.get_slice("/", 1))).length)
	await _wait(2.5)
	player.force_aim = true
	var shots := 0
	while minion.state != SkeletonEnemy.State.INDO_EMBORA and shots < 20:
		await _aim_for(minion, 1.0, 0.25)
		player.fire()
		shots += 1
		print("tiro ", shots, " vida ", minion.health, " estado ", SkeletonEnemy.State.keys()[minion.state])
	var leaving_y := minion.global_position.y
	await _wait(2.5)
	var rose := minion.global_position.y - leaving_y if is_instance_valid(minion) else 99.0
	print("subiu de balão: %.1f m em 2,5 s" % rose)
	await _wait(6.0)
	print("depois de esperar: foi embora de vez = ", not is_instance_valid(minion), ", esqueletos restantes ", enemies.size())
	for key in CHARACTER_ORDER:
		player.set_character(key)
		await get_tree().physics_frame
	print("trocou por todos os aventureiros; atual ", player.character_name)
	print("SMOKE OK")
	get_tree().quit()


# --- festa e moradores ----------------------------------------------------------

## Barraca de tiro, moradores novos e o desafio do Guerreiro Planta no Bosque das Copas.
## Uso: godot --headless --path . -- --extras
func _run_extras_test() -> void:
	var all_ok := true
	player.god_mode = true
	story.fast = true
	await _wait(0.6)
	# Barraca de tiro ao alvo, com tiro de verdade.
	all_ok = _check("barraca de tiro com 4 alvos, boneco e placar", is_instance_valid(gallery) and gallery.targets.size() == 4 and is_instance_valid(gallery.dummy)) and all_ok
	var t: ShootingGallery.GalleryTarget = gallery.targets[1]
	await _stand(gallery.global_position + gallery.global_basis.z * -2.0)
	player.force_aim = true
	await _aim_for(t, 1.45, 0.5)
	player.fire()
	await get_tree().physics_frame
	all_ok = _check("tiro no alvo marca ponto e derruba o alvo", gallery.hits == 1 and not t.up, "(acertos %d)" % gallery.hits) and all_ok
	await _wait(3.4)
	all_ok = _check("o alvo volta sozinho", t.up) and all_ok
	await _aim_for(gallery.dummy, 2.1, 0.5)
	player.fire()
	await get_tree().physics_frame
	player.force_aim = false
	all_ok = _check("boneco de treino mostra o dano", gallery.dummy.hits == 1 and gallery.hits == 1) and all_ok
	# Moradores novos.
	var names := ["Urso", "Bruxa", "SuperHeroi", "Astronauta", "HomemDasCavernas", "Lenhador", "Pescador"]
	var found := names.filter(func(n: String) -> bool: return get_node_or_null(n) is Townsperson)
	all_ok = _check("moradores novos na ilha", found.size() == names.size(), "(%d de %d)" % [found.size(), names.size()]) and all_ok
	# Bichos soltos e peixes (Quaternius).
	var animal_markers := island.get_node("Marcadores/Animais").get_child_count()
	var animals := get_tree().get_nodes_in_group(&"animais")
	var starts := {}
	for an in animals:
		starts[an] = (an as Node3D).global_position
	await _wait(9.0)
	var walked := animals.filter(func(an: Node3D) -> bool: return an.global_position.distance_to(starts[an]) > 1.0)
	all_ok = _check("bichos soltos na ilha, passeando", animals.size() == animal_markers and walked.size() >= 4,
			"(%d bichos, %d andaram)" % [animals.size(), walked.size()]) and all_ok
	var fishes := get_tree().get_nodes_in_group(&"peixes")
	var under := fishes.filter(func(f: Node3D) -> bool: return f.global_position.y < SEA_LEVEL + 1.5)
	all_ok = _check("peixes nadando no mar e no rio", fishes.size() >= 20 and under.size() == fishes.size(), "(%d peixes)" % fishes.size()) and all_ok
	# Cais do pacote de peixes: dá para andar da areia até a ponta sem cair na água.
	var deer: Animal = get_node("Veado1")
	player.global_position = deer.global_position + Vector3(2.0, 1.0, 0)
	var deer_start := deer.global_position
	await _wait(2.0)
	all_ok = _check("veado foge galopando quando o aventureiro chega perto", deer.global_position.distance_to(deer_start) > 4.0,
			"(%.1f m)" % deer.global_position.distance_to(deer_start)) and all_ok
	player.global_position = Vector3(0, 1.0, 199)
	player.velocity = Vector3.ZERO
	await _wait(0.5)
	await _walk_toward(Vector3(0, 0, 260), 9.0)
	await _wait(0.4)
	all_ok = _check("dá para andar pelo cais até a ponta", player.global_position.z > 245.0 and player.global_position.y > 0.2 and not _splashing,
			"(z %.1f, y %.2f)" % [player.global_position.z, player.global_position.y]) and all_ok
	# Desafio do Guerreiro Planta.
	story.skip_to_forest()
	await _wait(0.3)
	var vila: Defense = story.defenses.vila
	await _stand(vila.center + Vector3(0, 0, 6))
	await _wait_until(func() -> bool: return is_instance_valid(vila.boss) and vila.boss.phase == Boss.Phase.LUTANDO, 8.0)
	var planta := vila.boss as BossPlanta
	all_ok = _check("entrar no Bosque das Copas chama o Guerreiro Planta", is_instance_valid(planta) and planta.display_name == "Guerreiro Planta" and boss_bar.visible) and all_ok
	if planta == null:
		print("EXTRAS COM FALHAS")
		get_tree().quit()
		return
	planta.set_physics_process(false)
	var front := planta.global_position + planta.forward() * 1.0 + Vector3.UP * 2.0
	var h0 := planta.health
	planta.take_hit(2.0, front, planta.hurtboxes[1])
	all_ok = _check("escudo de folha segura tiro no corpo pela frente", planta.health == h0) and all_ok
	planta.take_hit(2.0, front, planta.hurtboxes[0])
	all_ok = _check("tiro na cabeça passa", planta.health < h0, "(%.0f -> %.0f)" % [h0, planta.health]) and all_ok
	var arrows := _projectiles(Projectile.Kind.FLECHA).size()
	planta._volley()
	await get_tree().physics_frame
	all_ok = _check("três flechas em leque", _projectiles(Projectile.Kind.FLECHA).size() == arrows + 3) and all_ok
	planta.set_physics_process(true)
	planta._dash_timer = 0.0
	planta._arrow_timer = 99.0
	await _wait_until(func() -> bool: return planta.is_open(), 4.0)
	var h1 := planta.health
	planta.take_hit(2.0, planta.global_position + planta.forward() * 1.0 + Vector3.UP * 2.0, planta.hurtboxes[1])
	all_ok = _check("depois da investida fica sem escudo", planta.is_open() and planta.health < h1) and all_ok
	planta.take_hit(999.0, planta.global_position + Vector3.UP * 2.0, planta.hurtboxes[0])
	await _wait(2.0)
	all_ok = _check("vencido, aplaude e fica (sem balão)", is_instance_valid(planta) and planta.phase == Boss.Phase.INDO_EMBORA and planta._balloons == null) and all_ok
	await _wait_until(func() -> bool: return vila.state == Defense.State.VENCIDA, 4.0)
	await get_tree().physics_frame
	all_ok = _check("desafio vencido dá +1 coração e não mexe na história", vila.state == Defense.State.VENCIDA and story.rewards.size() == 1
			and story.rewards[0].kind == "coracao" and story.stage == "mata") and all_ok
	print("EXTRAS OK" if all_ok else "EXTRAS COM FALHAS")
	get_tree().quit()


## Fotos das novidades (x01 a x12). Uso: godot --path . -- --extras-captura
func _run_extras_capture() -> void:
	player.god_mode = true
	story.fast = true
	await _wait(1.2)
	var out := "res://tools/capturas/"
	var size := Vector2i(1280, 720)
	var c := Vector3(0, 0, 170)
	await _art_shot(out + "x01_tiro_ao_alvo.png", size, c + Vector3(-4.0, 3.2, 4.5), c + Vector3(-6.0, 1.4, 13.8), 62.0)
	await _art_shot(out + "x02_bruxa.png", size, c + Vector3(-9.5, 2.6, -4.0), c + Vector3(-15.0, 1.2, -8.2), 55.0)
	await _art_shot(out + "x03_banda_com_urso.png", size, c + Vector3(0, 2.6, -4.0), c + Vector3(0, 1.9, -12.2), 55.0)
	await _art_shot(out + "x04_homem_das_cavernas.png", size, c + Vector3(-5.0, 2.4, 3.5), c + Vector3(-10.0, 1.2, 0.5), 55.0)
	await _art_shot(out + "x05_astronauta.png", size, c + Vector3(6.5, 2.4, -5.5), c + Vector3(11.0, 1.2, -11.0), 55.0)
	var lj: Node3D = get_node("Lenhador")
	await _art_shot(out + "x06_lenhador.png", size, lj.global_position + Vector3(-5.0, 2.5, 5.5), lj.global_position + Vector3(1.0, 1.0, -0.5), 55.0)
	var fisher: Node3D = get_node("Pescador")
	await _art_shot(out + "x07_pescador.png", size, fisher.global_position + Vector3(5.0, 2.2, -5.0), fisher.global_position + Vector3(0.5, 1.0, 0), 55.0)
	var vila_c := _ground_point(Vector3(115, 0, -160))
	await _art_shot(out + "x08_bosque_das_copas.png", size, vila_c + Vector3(15, 9, 15), vila_c + Vector3(0, 3, 0), 60.0)
	story.skip_to_forest()
	var vila: Defense = story.defenses.vila
	await _stand(vila.center + Vector3(0, 0, 7))
	await _wait_until(func() -> bool: return is_instance_valid(vila.boss) and vila.boss.phase == Boss.Phase.LUTANDO, 8.0)
	var planta := vila.boss as BossPlanta
	await _wait(0.6)
	var view := func() -> Array:
		var to_p := planta.global_position - player.global_position
		to_p.y = 0.0
		return [player.global_position - to_p.normalized() * 3.0 + to_p.normalized().cross(Vector3.UP) * 2.0 + Vector3.UP * 3.0,
			planta.global_position + Vector3.UP * 2.0]
	var v: Array = view.call()
	await _art_shot(out + "x10_guerreiro_planta.png", size, v[0], v[1], 55.0)
	planta._arrow_timer = 0.0
	await _wait(0.75)
	v = view.call()
	await _art_shot(out + "x11_planta_arco.png", size, v[0], v[1], 55.0)
	planta.take_hit(999.0, planta.global_position + Vector3.UP * 2.0, planta.hurtboxes[0])
	await _wait(1.6)
	v = view.call()
	await _art_shot(out + "x12_planta_vencido.png", size, v[0], v[1], 55.0)
	print("EXTRAS FOTOS OK")
	get_tree().quit()


## Fotos da paisagem sem a interface (p01 a p08): cemitério do Morro, ponte de pedra, mata com as cores
## do pacote completo, morrinhos na margem do rio e cerejeiras da praça. Uso: godot --path . -- --paisagem-captura
func _run_landscape_capture() -> void:
	player.god_mode = true
	await _wait(1.0)
	var dome := find_child("CupulaDoCemiterio", true, false) as StaticBody3D
	if dome:
		dome.visible = false
		dome.collision_layer = 0
	var out := "res://tools/capturas/"
	var size := Vector2i(1280, 720)
	var top := _ground_point(Vector3(0, 0, 2))
	await _art_shot(out + "p01_cemiterio_de_cima.png", size, top + Vector3(0, 32, 30), top + Vector3(0, 0, -3), 60.0)
	await _art_shot(out + "p02_cemiterio_cripta.png", size, top + Vector3(-6, 4.5, 12), top + Vector3(0, 3.0, -17), 55.0)
	await _art_shot(out + "p03_cemiterio_tumulos.png", size, top + Vector3(-4, 3.5, 6), top + Vector3(15, 1.0, -2), 60.0)
	var bridge := _ground_point(Vector3(0, 0, -112))
	await _art_shot(out + "p04_ponte.png", size, bridge + Vector3(26, 6, 6), bridge + Vector3(0, 1, 0), 55.0)
	await _art_shot(out + "p05_ponte_de_cima.png", size, bridge + Vector3(8, 14, 28), bridge + Vector3(0, 0, -4), 55.0)
	await _art_shot(out + "p06_mata_clareira.png", size, _ground_point(Vector3(40, 0, -140)) + Vector3(0, 9, 0), Vector3(40, 3, -180), 60.0)
	await _art_shot(out + "p07_mata_ventos.png", size, _ground_point(Vector3(-60, 0, -130)) + Vector3(0, 10, 0), Vector3(-95, 8, -158), 60.0)
	await _art_shot(out + "p08_morrinhos_do_rio.png", size, _ground_point(Vector3(-100, 0, -80)) + Vector3(0, 10, 0), Vector3(-118, 0, -100), 60.0)
	await _art_shot(out + "p09_praca_cerejeiras.png", size, Vector3(0, 12, 196), Vector3(0, 1, 168), 60.0)
	var beach: Vector3 = story.defenses.praca.center
	await _art_shot(out + "p10_praia_do_cais.png", size, beach + Vector3(14, 9, -26), beach + Vector3(0, 0, 6), 60.0)
	await _art_shot(out + "p11_cais_madeira.png", size, Vector3(6.5, 2.6, 214), Vector3(0, 0.5, 236), 60.0)
	var lj: Node3D = get_node("Lenhador")
	await _wait(0.46)
	await _art_shot(out + "p12_lenhador.png", size, lj.global_position + Vector3(-1.5, 1.8, 4.2), lj.global_position + Vector3(-0.6, 0.7, 0), 50.0)
	var ventos := _ground_point(Vector3(-80, 0, -162))
	await _art_shot(out + "p13_morro_dos_ventos.png", size, ventos + Vector3(40, 20, 40), ventos + Vector3(0, 0, 0), 55.0)
	var gate := find_child("PortaoDoCemiterio", true, false) as Node3D
	if gate:
		var out_dir := gate.global_position + gate.global_basis.z * 9.0 + gate.global_basis.x * 2.6
		await _art_shot(out + "p14_portao_fechado.png", size, out_dir + Vector3.UP * 3.0, gate.global_position + gate.global_basis.x * 2.6 + Vector3.UP * 1.5, 55.0)
		story._open_gate()
		await _wait(2.5)
		await _art_shot(out + "p15_portao_aberto.png", size, out_dir + Vector3.UP * 3.0, gate.global_position + gate.global_basis.x * 2.6 + Vector3.UP * 1.5, 55.0)
	var fisher: Node3D = get_node("Pescador")
	await _wait(0.3)
	await _art_shot(out + "p17_pescador_linha.png", size, fisher.global_position + Vector3(4.5, 1.6, -5.5), fisher.global_position + Vector3(1.6, 0.2, 0), 55.0)
	await _art_shot(out + "p18b_cais_reto.png", size, Vector3(0, 4.0, 203), Vector3(0, 0.4, 232), 60.0)
	await _art_shot(out + "p18_ponta_do_cais.png", size, Vector3(9, 4.5, 244), Vector3(0, 0.6, 253), 55.0)
	await _art_shot(out + "p19_rua_sul.png", size, Vector3(52, 2.0, 200), Vector3(30, 0.3, 188), 60.0)
	await _art_shot(out + "p20_praca_de_cima.png", size, Vector3(0, 34, 171), Vector3(0, 0, 170.1), 62.0)
	var bosque := _ground_point(Vector3(115, 0, -160))
	await _art_shot(out + "p21_bosque_das_copas.png", size, bosque + Vector3(11, 5, 11), bosque + Vector3(-2, 2, -2), 65.0)
	var pasture := _ground_point(Vector3(-104, 0, 52))
	await _art_shot(out + "p16_pasto.png", size, pasture + Vector3(12, 6, 14), pasture + Vector3(0, 0.8, 0), 55.0)
	await _art_shot(out + "p22_cais_peixes.png", size, Vector3(14, 5.5, 214), Vector3(0, 0.3, 236), 60.0)
	await _art_shot(out + "p23_cais_ponta.png", size, Vector3(-9, 4.0, 236), Vector3(2, 0.3, 252), 60.0)
	var pasto := _ground_point(Vector3(-104, 0, 52))
	await _wait(1.0)
	await _art_shot(out + "p24_pasto_bichos.png", size, pasto + Vector3(13, 5, 13), pasto + Vector3(0, 0.8, 0), 55.0)
	var deer: Node3D = get_node("Veado1")
	await _art_shot(out + "p25_veados.png", size, deer.global_position + Vector3(6, 2.5, 7), deer.global_position + Vector3(2, 1.0, -2), 55.0)
	var fox: Node3D = get_node("Raposa1")
	await _art_shot(out + "p26_raposa.png", size, fox.global_position + Vector3(4, 2.0, 4), fox.global_position + Vector3(0, 0.5, 0), 50.0)
	await _art_shot(out + "p27_peixes_mar.png", size, Vector3(13, 6, 230), Vector3(13, -1.0, 238), 60.0)
	var dog: Node3D = get_node("Shiba")
	await _art_shot(out + "p28_cachorro_praca.png", size, dog.global_position + Vector3(3.5, 2.0, 3.5), dog.global_position + Vector3(0, 0.5, 0), 50.0)
	await _art_shot(out + "p29_sitio.png", size, pasto + Vector3(22, 11, 24), pasto + Vector3(-2, 1.5, -6), 60.0)
	var farmer: Node3D = get_node("Fazendeiro")
	await _art_shot(out + "p30_fazendeiro.png", size, farmer.global_position + Vector3(-3.5, 2.0, 3.5), farmer.global_position + Vector3(0, 1.0, 0), 50.0)
	var farmer_b: Node3D = get_node("Fazendeira")
	await _art_shot(out + "p31_fazendeira.png", size, farmer_b.global_position + Vector3(-4.0, 2.0, -3.0), farmer_b.global_position + Vector3(1.5, 1.0, 1.0), 55.0)
	await _art_shot(out + "p32_ponte_sem_barreira.png", size, Vector3(0, 3.0, -86), Vector3(0, 1.0, -112), 60.0)
	print("PAISAGEM OK")
	get_tree().quit()


## Fotos da festa na praça e dos moradores, sem a interface, em tools/capturas/ (f01 a f08).
## Uso: godot --path . -- --festa-captura
func _run_festa_capture() -> void:
	player.god_mode = true
	await _wait(1.2)
	var c := Vector3(0, 0, 170)
	var out := "res://tools/capturas/"
	var size := Vector2i(1280, 720)
	await _art_shot(out + "f01_praca.png", size, _ground_point(c + Vector3(0, 0, 22)) + Vector3.UP * 8.0, c + Vector3(0, 0.5, -3), 60.0)
	await _art_shot(out + "f02_palco.png", size, c + Vector3(0, 2.4, -3.5), c + Vector3(0, 1.6, -11.5), 55.0)
	await _art_shot(out + "f03_palhaco.png", size, c + Vector3(8.5, 2.4, 3.5), c + Vector3(14.0, 1.0, 9.5), 55.0)
	await _art_shot(out + "f03b_plateia.png", size, c + Vector3(17.5, 2.2, 15.0), c + Vector3(12.5, 0.6, 9.5), 50.0)
	await _art_shot(out + "f04_barraca.png", size, c + Vector3(-9.0, 2.4, 4.5), c + Vector3(-15.5, 0.9, 10.0), 55.0)
	await _art_shot(out + "f05_mesas.png", size, c + Vector3(-5.5, 2.6, 0.5), c + Vector3(-11.5, 0.8, 0.5), 55.0)
	await _stand(c + Vector3(-2.6, 0, 2.6))
	await _wait(0.8)
	await _art_shot(out + "f06_vovo.png", size, c + Vector3(-0.5, 2.2, 8.5), c + Vector3(-4.5, 1.4, 4.5), 45.0)
	await _art_shot(out + "f07_rua.png", size, Vector3(-37, 3.0, 154), Vector3(-37, 1.2, 146.0), 60.0)
	await _art_shot(out + "f08_trilheiro.png", size, _ground_point(Vector3(-2, 0, 107)) + Vector3.UP * 2.5, Vector3(-2, 1.2 + ground_y(Vector3(-2, 0, 100)), 100), 45.0)
	print("FESTA OK")
	get_tree().quit()


func ground_y(p: Vector3) -> float:
	return _ground_point(p).y


# --- arte da Steam -------------------------------------------------------------

## Arte da Steam (capas, fundo da página e ícone): monta uma cena posada na campina ao pé do Morro,
## com o cemitério ao fundo, os dois aventureiros à direita, esqueletos descendo o Morro e outros
## indo embora de balão, e fotografa sem a interface com câmeras próprias em alta resolução. O lado
## esquerdo fica livre para o logo. Salva em build/arte_steam/; o logo e as capas finais saem de
## tools/arte_steam.py. Uso: godot --path . -- --arte-steam
func _run_steam_art() -> void:
	player.god_mode = true
	var dome := find_child("CupulaDoCemiterio", true, false)
	if dome:
		dome.visible = false
	# Tudo é posicionado em relação à câmera do fundo da página: profundidade e deslocamento lateral.
	var cam := _ground_point(Vector3(30, 0, 100)) + Vector3(-5, 1.6, 10)
	var fwd := Vector3(0.12, 0, -1).normalized()
	var right := fwd.cross(Vector3.UP)
	var at := func(depth: float, lateral: float) -> Vector3:
		return _ground_point(cam + fwd * depth + right * lateral)
	var girl := Player.new()
	girl.name = "Menina"
	add_child(girl)
	girl.set_character("menina")
	girl.input_enabled = false
	girl.god_mode = true
	girl.force_aim = true
	girl.switch_weapon(1)
	player.unlock_weapon("pipoqueira")
	player.force_aim = true
	var boy_pos: Vector3 = at.call(8.0, 2.6)
	var girl_pos: Vector3 = at.call(9.6, 4.4)
	await _stand(boy_pos)
	girl.global_position = girl_pos + Vector3.UP
	# Esqueletos descendo o Morro (congelados no meio da corrida) e outros subindo de balão.
	var ground := [["Minion", 13.0, -0.6], ["Warrior", 15.5, -3.2], ["Mage", 17.0, 1.8], ["Rogue", 20.0, -6.0]]
	var sky := [["Minion", 16.0, -2.0, 6.0], ["Mage", 22.0, -7.5, 9.0], ["Rogue", 19.0, 3.5, 10.5]]
	var walkers: Array[SkeletonEnemy] = []
	for spec in ground:
		walkers.append(_art_skeleton(spec[0], at.call(spec[1], spec[2])))
	var flyers: Array[SkeletonEnemy] = []
	for spec in sky:
		# Nascem longe da câmera: o "Tchau!" aparece lá e não na foto.
		flyers.append(_art_skeleton(spec[0], cam + Vector3(0, 0, 60)))
	await _wait(0.4)
	for f in flyers:
		f._start_leaving()
	# Os dois miram para a frente e à esquerda da câmera: rosto de três quartos.
	var aim_point := cam + fwd * 2.5 + right * -7.0 + Vector3.UP * 0.6
	for k in 70:
		player.aim_at(aim_point)
		girl.aim_at(aim_point + right * -2.0)
		await get_tree().physics_frame
	for i in walkers.size():
		var w := walkers[i]
		w.set_physics_process(false)
		w.global_position = at.call(ground[i][1], ground[i][2])
		var dir := boy_pos - w.global_position
		w.visual.rotation.y = atan2(dir.x, dir.z)
	await _wait(0.8)
	for f in flyers:
		f.set_physics_process(false)
	player.set_physics_process(false)
	girl.set_physics_process(false)
	# Cada foto tem o seu lugar para os esqueletos de balão: [profundidade, lateral, altura].
	var place := func(spots: Array) -> void:
		for i in flyers.size():
			flyers[i].global_position = at.call(spots[i][0], spots[i][1]) + Vector3.UP * spots[i][2]
	var out := "res://build/arte_steam/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var look := cam + fwd * 20.0 + Vector3.UP * 2.6
	place.call([[20.0, -4.0, 1.8], [27.0, -11.0, 3.2], [21.0, 9.5, 3.4]])
	await _wait(0.1)
	await _art_shot(out + "hero.png", Vector2i(3840, 1240), cam, look, 32.0)
	# Na capa horizontal o logo vai no céu da direita: os três balões ficam do lado esquerdo.
	place.call([[20.0, -3.5, 2.2], [26.0, -9.0, 3.6], [23.0, -15.0, 4.6]])
	await _wait(0.1)
	await _art_shot(out + "capa_horizontal.png", Vector2i(1840, 860), cam - fwd * 1.5 + right * 0.5, look + right * 0.5, 38.0)
	var cam_v := cam + right * 1.6 + fwd * 0.5 + Vector3.UP * 0.2
	place.call([[16.0, -1.6, 3.2], [22.0, -5.0, 4.6], [19.0, 3.6, 5.6]])
	await _wait(0.1)
	await _art_shot(out + "capa_vertical.png", Vector2i(1200, 1800), cam_v, cam_v + fwd * 14.0 + Vector3.UP * 3.6, 58.0)
	# Ícone: um esqueleto de balão sozinho bem alto, acenando contra o céu.
	place.call([[18.0, -2.0, 22.0], [60.0, -40.0, 0.0], [60.0, 40.0, 0.0]])
	await _wait(0.1)
	var f0 := flyers[0].global_position + Vector3.UP * 2.45
	await _art_shot(out + "icone.png", Vector2i(1024, 1024), f0 - fwd * 7.5 + right * -2.5 + Vector3.UP * -1.2, f0, 40.0)
	print("ARTE OK")
	get_tree().quit()


func _art_skeleton(type_name: String, pos: Vector3) -> SkeletonEnemy:
	var e := SkeletonEnemy.new()
	e.type_name = "Skeleton_" + type_name
	e.start_awake = true
	e.aggro_radius = 999.0
	e.leash_radius = 999.0
	e.target = player
	add_child(e)
	e.global_position = pos + Vector3.UP * 0.2
	return e


## Ponto no chão logo abaixo (ou acima) de `p`.
func _ground_point(p: Vector3) -> Vector3:
	var query := PhysicsRayQueryParameters3D.create(Vector3(p.x, 200.0, p.z), Vector3(p.x, -50.0, p.z), 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position if not hit.is_empty() else Vector3(p.x, 0.0, p.z)


## Fotografa a cena com uma câmera própria num SubViewport do tamanho pedido (a interface não entra).
func _art_shot(path: String, size: Vector2i, from: Vector3, to: Vector3, fov: float) -> void:
	var vp := SubViewport.new()
	vp.size = size
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var cam := Camera3D.new()
	cam.fov = fov
	vp.add_child(cam)
	cam.look_at_from_position(from, to)
	cam.current = true
	for k in 3:
		await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("arte: ", path)
	vp.queue_free()
