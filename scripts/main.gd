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
var _splashing := false

## Comandos mostrados no menu de pausa (não ficam mais na tela durante o jogo).
const CONTROLS_KEYBOARD := [
	["Andar", "W A S D"], ["Olhar", "mouse"], ["Pular", "Espaço"], ["Mirar", "botão direito"],
	["Atirar", "botão esquerdo"], ["Recarregar", "R"], ["Granada", "G"],
	["Trocar de blaster", "1 a 4 ou rodinha"], ["Pausa", "Esc ou Tab"], ["Regiões de impacto", "F3"],
]
const CONTROLS_GAMEPAD := [
	["Andar", "analógico esquerdo"], ["Olhar", "analógico direito"], ["Pular", "A"], ["Mirar", "LT"],
	["Atirar", "RT"], ["Recarregar", "X"], ["Granada", "RB"], ["Trocar de blaster", "Y ou direcional ←/→"],
	["Pausa", "Start"], ["Regiões de impacto", "Back"],
]
const MENU_KEYBOARD := "Clique, ou use as setas e Enter"
const MENU_GAMEPAD := "Direcional para escolher, A para confirmar"

var player: Player
var enemies: Array[SkeletonEnemy] = []
var crosshair: Crosshair
## Menus: "escolha" (personagem; na abertura e pela pausa), "pausa" e "comandos". Com menu aberto o
## jogo fica pausado; a interface e a música continuam rodando.
var ui_layer: CanvasLayer
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
var _show_regions := false
var _game_started := false
var checkpoints: Array[Checkpoint] = []
var current_checkpoint: Checkpoint
var hearts_bar: HeartsBar
var ammo_hud: WeaponHud
var message_label: Label
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
		e.tree_exited.connect(func() -> void: enemies.erase(e))
		add_child(e)
		enemies.append(e)
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
	return {"start": start.global_position + Vector3.UP * 0.3, "start_yaw": start.rotation.y, "enemies": spawns, "checkpoints": cps, "crates": crate_spots}


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

	_bind_key("pular", [KEY_SPACE])
	_bind_button("pular", JOY_BUTTON_A)
	_bind_mouse("atirar", MOUSE_BUTTON_LEFT)
	_bind_axis("atirar", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_bind_key("recarregar", [KEY_R])
	_bind_button("recarregar", JOY_BUTTON_X)
	_bind_key("granada", [KEY_G])
	_bind_button("granada", JOY_BUTTON_RIGHT_SHOULDER)
	_bind_mouse("arma_proxima", MOUSE_BUTTON_WHEEL_UP)
	_bind_button("arma_proxima", JOY_BUTTON_Y)
	_bind_button("arma_proxima", JOY_BUTTON_DPAD_RIGHT)
	_bind_mouse("arma_anterior", MOUSE_BUTTON_WHEEL_DOWN)
	_bind_button("arma_anterior", JOY_BUTTON_DPAD_LEFT)
	for i in Weapons.count():
		_bind_key("arma_%d" % (i + 1), [KEY_1 + i])
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
			if event.is_action_pressed("menu") and not player.dizzy:
				open_menu("pausa")
		"pausa":
			close_menus()
		"comandos":
			open_menu("pausa")
		"escolha":
			# Na abertura do jogo é preciso escolher; vindo da pausa, voltar leva à pausa.
			if _game_started:
				open_menu("pausa")


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
	select_panel.visible = state == "escolha"
	pause_panel.visible = state == "pausa"
	controls_panel.visible = state == "comandos"
	menu_dim.visible = true
	crosshair.hide()
	player.input_enabled = false
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	match state:
		"escolha":
			var i := maxi(CHARACTER_ORDER.find(player.character_name), 0)
			_buttons[i].grab_focus.call_deferred()
		"pausa":
			_pause_buttons[0].grab_focus.call_deferred()
		"comandos":
			_controls_back.grab_focus.call_deferred()


func close_menus() -> void:
	menu_state = ""
	select_panel.hide()
	pause_panel.hide()
	controls_panel.hide()
	menu_dim.hide()
	crosshair.show()
	get_tree().paused = false
	_game_started = true
	if not player.using_gamepad:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Libera o boneco um instante depois, para o A que confirmou o menu não virar pulo.
	get_tree().create_timer(0.2).timeout.connect(func() -> void: player.input_enabled = true)


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
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_color = Color("#fff4e0")
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0 if arena else 110.0
	add_child(sun)


## Caiu no mar ou no rio: "tchibum", sem perder coração, e volta na última bandeira.
func _physics_process(_delta: float) -> void:
	if _splashing or not is_instance_valid(player) or player.dizzy:
		return
	if player.global_position.y < SEA_LEVEL - 0.9:
		_splash()


func _splash() -> void:
	_splashing = true
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

	menu_dim = _overlay(layer, Color(0.03, 0.04, 0.08))
	menu_dim.modulate.a = 0.45
	menu_dim.hide()

	var box := _menu_box(layer, "Escolha quem vai jogar")
	select_panel = box.get_parent().get_parent()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	box.add_child(grid)
	# Foco bem visível: quem joga de controle precisa enxergar de longe qual botão está marcado.
	var focus_style := StyleBoxFlat.new()
	focus_style.draw_center = false
	focus_style.set_border_width_all(5)
	focus_style.border_color = Color("#ffd23f")
	focus_style.set_corner_radius_all(6)
	focus_style.set_expand_margin_all(3)
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

	# Pausa: continuar, trocar de personagem, ver os comandos ou sair.
	var pbox := _menu_box(layer, "Pausa")
	pause_panel = pbox.get_parent().get_parent()
	for spec in [["Continuar", close_menus], ["Trocar de personagem", open_menu.bind("escolha")],
			["Comandos", open_menu.bind("comandos")], ["Sair do jogo", get_tree().quit]]:
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
	for panel_root in [select_panel, pause_panel, controls_panel]:
		panel_root.hide()


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


func _on_enemy_defeated(e: SkeletonEnemy) -> void:
	if player.hearts <= 2 or randf() < heart_drop_chance:
		var heart := HeartPickup.new()
		heart.position = e.global_position
		add_child(heart)
	if player.limited_ammo_fraction() < 0.25 or randf() < AMMO_DROP_CHANCE:
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


func _choose_character(key: String) -> void:
	player.set_character(key)
	Sfx.play(ui_layer, "ui_ok", 0.0, 0.0)
	close_menus()


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

	# Direcional troca de blaster (o personagem só muda pelo menu de pausa).
	var w0 := player.weapon_index
	var c0 := player.character_name
	await _joy_button(JOY_BUTTON_DPAD_RIGHT)
	var w1 := player.weapon_index
	await _wait(0.35)
	await _joy_button(JOY_BUTTON_DPAD_LEFT)
	all_ok = _check("direcional troca de blaster, não de personagem", w1 != w0 and player.weapon_index == w0 and player.character_name == c0,
			"(%d -> %d -> %d)" % [w0, w1, player.weapon_index]) and all_ok
	await _wait(0.35)

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
	await _shot("ilha_jogo_05_castelinho.png")
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

	print("ARMAS OK" if all_ok else "ARMAS COM FALHAS")
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
