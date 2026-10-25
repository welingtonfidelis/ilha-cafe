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

const CHARACTER_LABELS := {
	"Knight": "Cavaleiro",
	"Barbarian": "Bárbaro",
	"Mage": "Mago",
	"Ranger": "Patrulheiro",
	"Rogue": "Ladino",
	"Rogue_Hooded": "Ladino de capuz",
}
const CHARACTER_ORDER := ["Knight", "Barbarian", "Mage", "Ranger", "Rogue", "Rogue_Hooded"]

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

const HINT_KEYBOARD := "WASD andar · Espaço pular · Botão direito mirar · Botão esquerdo atirar\nQ/E ou 1 a 6 trocar de aventureiro · Tab escolher aventureiro · F3 regiões de impacto · Esc soltar o mouse"
const HINT_GAMEPAD := "Analógico esquerdo andar · Analógico direito olhar · A pular · LT mirar · RT atirar\nDirecional ←/→ trocar de aventureiro · Start escolher aventureiro · Back regiões de impacto"
const MENU_KEYBOARD := "Clique, ou use as setas e Enter"
const MENU_GAMEPAD := "Direcional para escolher, A para confirmar"

var player: Player
var enemies: Array[SkeletonEnemy] = []
var crosshair: Crosshair
var select_panel: Control
var character_label: Label
var hint: Label
var menu_hint: Label
var _buttons: Array[Button] = []
var _show_regions := false
var _game_started := false
var checkpoints: Array[Checkpoint] = []
var current_checkpoint: Checkpoint
var hearts_bar: HeartsBar
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
		position = Vector2(get_viewport_rect().size.x - max_hearts * 46.0 - 12.0, 74.0)
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


class Crosshair:
	extends Control
	var color := Color.WHITE

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_delta: float) -> void:
		# Filho direto de CanvasLayer: posiciona pelo tamanho da tela em vez de âncoras.
		position = get_viewport_rect().size * 0.5

	func _draw() -> void:
		var shadow := Color(0, 0, 0, 0.6)
		for c in [[shadow, 2.0], [color, 0.0]]:
			var col: Color = c[0]
			var w: float = 4.0 + c[1]
			for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
				draw_line(d * 6.0, d * 16.0, col, w)
			draw_circle(Vector2.ZERO, 2.0 + c[1] * 0.5, col)

	func flash(c: Color) -> void:
		color = c
		queue_redraw()
		var tw := create_tween()
		tw.tween_interval(0.12)
		tw.tween_callback(func() -> void:
			color = Color.WHITE
			queue_redraw())


var music: AudioStreamPlayer


func _ready() -> void:
	_setup_input()
	Sfx.setup_buses()
	music = Sfx.music(self, "tema")
	_build_environment()
	_build_ground()
	_build_city()
	_build_forest()
	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.hit_confirmed.connect(_on_hit_confirmed)
	player.character_changed.connect(_on_character_changed)
	player.input_device_changed.connect(_on_input_device_changed)
	player.health_changed.connect(func(h: int, m: int) -> void: hearts_bar.set_hearts(h, m))
	player.damaged.connect(_on_player_damaged)
	player.dizzy_started.connect(_on_player_dizzy)
	for spawn in ENEMY_SPAWNS:
		var e := SkeletonEnemy.new()
		e.type_name = spawn[0]
		e.name = spawn[0]
		e.position = spawn[1]
		e.target = player
		e.defeated.connect(_on_enemy_defeated)
		add_child(e)
		enemies.append(e)
	for pos in CHECKPOINTS:
		var cp := Checkpoint.new()
		cp.position = pos
		cp.activated.connect(_on_checkpoint_activated)
		add_child(cp)
		checkpoints.append(cp)
	current_checkpoint = checkpoints[0]
	current_checkpoint.set_active.call_deferred(true, true)
	_build_ui()
	hearts_bar.set_hearts(player.hearts, player.max_hearts)
	_on_character_changed(player.character_name)
	_on_input_device_changed(Input.get_connected_joypads().size() > 0)

	var args := OS.get_cmdline_user_args()
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
		_open_menu()
		_run_gamepad_test()
	elif "--combate" in args:
		select_panel.hide()
		_run_combat_test()
	elif "--som" in args:
		Sfx.logging = true
		_open_menu()
		_run_sound_test()
	else:
		_open_menu()


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
	_bind_button("atirar", JOY_BUTTON_RIGHT_SHOULDER)
	_bind_mouse("mirar", MOUSE_BUTTON_RIGHT)
	_bind_axis("mirar", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_bind_button("mirar", JOY_BUTTON_LEFT_SHOULDER)
	InputMap.action_set_deadzone("atirar", 0.3)
	InputMap.action_set_deadzone("mirar", 0.3)

	_bind_key("regioes", [KEY_F3])
	_bind_button("regioes", JOY_BUTTON_BACK)
	_bind_key("menu", [KEY_TAB])
	_bind_button("menu", JOY_BUTTON_START)
	_bind_key("personagem_anterior", [KEY_Q])
	_bind_button("personagem_anterior", JOY_BUTTON_DPAD_LEFT)
	_bind_key("personagem_proximo", [KEY_E])
	_bind_button("personagem_proximo", JOY_BUTTON_DPAD_RIGHT)
	for i in CHARACTER_ORDER.size():
		_bind_key("personagem_%d" % (i + 1), [KEY_1 + i])
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


## O menu é tratado em _input porque, com o painel aberto, a interface consome o Tab.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if select_panel.visible and _game_started:
			_close_menu()
		else:
			_open_menu()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if select_panel.visible:
		if event.is_action_pressed("ui_cancel") and _game_started:
			_close_menu()
		return
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("regioes"):
		_toggle_regions()
	elif player.dizzy:
		return
	elif event.is_action_pressed("personagem_proximo"):
		_cycle_character(1)
	elif event.is_action_pressed("personagem_anterior"):
		_cycle_character(-1)
	else:
		for i in CHARACTER_ORDER.size():
			if event.is_action_pressed("personagem_%d" % (i + 1)):
				player.set_character(CHARACTER_ORDER[i])


func _cycle_character(step: int) -> void:
	var i := CHARACTER_ORDER.find(player.character_name)
	player.set_character(CHARACTER_ORDER[wrapi(i + step, 0, CHARACTER_ORDER.size())])
	Sfx.play(self, "ui_ok", 0.0, 0.0)


func _open_menu() -> void:
	select_panel.show()
	crosshair.hide()
	player.input_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var i := maxi(CHARACTER_ORDER.find(player.character_name), 0)
	_buttons[i].grab_focus.call_deferred()


func _close_menu() -> void:
	select_panel.hide()
	crosshair.show()
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
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_color = Color("#fff4e0")
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0
	add_child(sun)


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
	_prop(CITY % "car_taxi", Vector3(24, 0, -20), 0.0, CITY_SCALE, true)
	_prop(CITY % "car_police", Vector3(28, 0, 0), 180.0, CITY_SCALE, true)
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
	add_child(layer)
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

	hint = Label.new()
	hint.text = HINT_KEYBOARD
	hint.position = Vector2(16, 12)
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_constant_override("outline_size", 6)
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	layer.add_child(hint)

	character_label = Label.new()
	character_label.add_theme_font_size_override("font_size", 24)
	character_label.add_theme_constant_override("outline_size", 8)
	character_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	layer.add_child(character_label)
	character_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 16)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	select_panel = center
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var title := Label.new()
	title.text = "Escolha seu aventureiro"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	box.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 3
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
		button.text = "%d · %s" % [i + 1, CHARACTER_LABELS[key]]
		button.custom_minimum_size = Vector2(220, 56)
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_stylebox_override("focus", focus_style)
		button.pressed.connect(_choose_character.bind(key))
		button.focus_entered.connect(func() -> void: Sfx.play(self, "ui_mover", 0.0, 0.0))
		grid.add_child(button)
		_buttons.append(button)
	menu_hint = Label.new()
	menu_hint.text = MENU_KEYBOARD
	menu_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_hint.add_theme_font_size_override("font_size", 16)
	box.add_child(menu_hint)


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
		heart.position = Vector3(e.global_position.x, 0, e.global_position.z)
		add_child(heart)


func _choose_character(key: String) -> void:
	player.set_character(key)
	Sfx.play(self, "ui_ok", 0.0, 0.0)
	_close_menu()


func _on_input_device_changed(gamepad: bool) -> void:
	if hint:
		hint.text = HINT_GAMEPAD if gamepad else HINT_KEYBOARD
	if menu_hint:
		menu_hint.text = MENU_GAMEPAD if gamepad else MENU_KEYBOARD


func _on_character_changed(char_name: String) -> void:
	if character_label:
		character_label.text = CHARACTER_LABELS.get(char_name, char_name)


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
	await _wait(0.8)
	var hand: Node3D = player.model.find_child("MaoDireita", true, false)
	var close := Camera3D.new()
	add_child(close)
	close.global_position = hand.global_position + player.visual.global_basis * Vector3(-1.6, 0.5, 1.2)
	close.look_at(hand.global_position)
	close.current = true
	await _shot("00_blaster_close.png")
	close.queue_free()
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
	while minion.state != SkeletonEnemy.State.DESMONTADO:
		await _aim_for(minion, 1.0, 0.25)
		player.fire()
	await _wait(0.9)
	await _shot("04_desmontado.png")
	_toggle_regions()
	await _aim_for(enemies[1], 1.0, 0.5)
	await _shot("05_regioes.png")
	_toggle_regions()
	await _aim_for(minion, 0.6, minion.down_time - 0.4)
	await _wait(1.3)
	await _shot("06_remontando.png")
	player.force_aim = false
	for key in ["Mage", "Barbarian", "Ranger"]:
		player.set_character(key)
		await _wait(0.6)
		await _shot("07_%s.png" % key.to_lower())
	# Combate: armas dos esqueletos, flecha voando, golpe recebido, tonto e volta na bandeira.
	player.set_character("Knight")
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
	# Com controle: as dicas mudam e o menu abre com foco num botão.
	_joy_axis(JOY_AXIS_LEFT_X, 0.6)
	await get_tree().physics_frame
	_joy_axis(JOY_AXIS_LEFT_X, 0.0)
	await _wait(0.3)
	await _shot("08_hud_controle.png")
	_open_menu()
	await _joy_button(JOY_BUTTON_DPAD_RIGHT)
	await _wait(0.2)
	await _shot("09_menu_controle.png")
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
	all_ok = _check("jogo detectou o controle", player.using_gamepad, "(dica: %s...)" % hint.text.left(30)) and all_ok

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
	all_ok = _check("RT atira e acerta", target.health < shots_before or target.state == SkeletonEnemy.State.DESMONTADO,
			"(vida %.0f -> %.0f, %s)" % [shots_before, target.health, SkeletonEnemy.State.keys()[target.state]]) and all_ok

	# Direcional troca de aventureiro.
	var c0 := player.character_name
	await _joy_button(JOY_BUTTON_DPAD_RIGHT)
	var c1 := player.character_name
	await _joy_button(JOY_BUTTON_DPAD_LEFT)
	all_ok = _check("direcional troca de aventureiro", c1 != c0 and player.character_name == c0, "(%s -> %s -> %s)" % [c0, c1, player.character_name]) and all_ok

	# Back mostra as regiões; Start abre e fecha o menu.
	await _joy_button(JOY_BUTTON_BACK)
	all_ok = _check("Back mostra as regiões de impacto", _show_regions) and all_ok
	await _joy_button(JOY_BUTTON_BACK)
	await _joy_button(JOY_BUTTON_START)
	all_ok = _check("Start abre o menu e trava o boneco", select_panel.visible and not player.input_enabled) and all_ok
	await _joy_button(JOY_BUTTON_START)
	await _wait(0.3)
	all_ok = _check("Start fecha o menu e solta o boneco", not select_panel.visible and player.input_enabled) and all_ok

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
	await _wait_until(func() -> bool: return minion.state != SkeletonEnemy.State.DESMONTADO and minion.state != SkeletonEnemy.State.REMONTANDO, 8.0)
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

	# Tiro, acerto na cabeça, ossos desmontando e remontando.
	player.god_mode = true
	var minion := enemies[0]
	await _wait_until(func() -> bool: return minion.state == SkeletonEnemy.State.PERSEGUINDO or minion.state == SkeletonEnemy.State.ESPERANDO, 6.0)
	Sfx.played.clear()
	player.force_aim = true
	while minion.state != SkeletonEnemy.State.DESMONTADO and Sfx.played.count("tiro") < 15:
		await _aim_for(minion.hurtboxes[0], 0.0, 0.25)
		player.fire()
	all_ok = _check("tiro, acerto e ossos", heard.call("tiro") and (heard.call("acerto_cabeca") or heard.call("acerto")) and heard.call("ossos"),
			"(%s)" % ", ".join(Sfx.played.slice(0, 6))) and all_ok
	player.force_aim = false
	await _wait_until(func() -> bool: return heard.call("remontar"), minion.down_time + 1.0)
	all_ok = _check("esqueleto remontando", heard.call("remontar")) and all_ok

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

	print("SOM OK" if all_ok else "SOM COM FALHAS")
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
	while minion.state != SkeletonEnemy.State.DESMONTADO and shots < 20:
		await _aim_for(minion, 1.0, 0.25)
		player.fire()
		shots += 1
		print("tiro ", shots, " vida ", minion.health, " estado ", SkeletonEnemy.State.keys()[minion.state])
	await _wait(minion.down_time + 2.5)
	print("depois de esperar: estado ", SkeletonEnemy.State.keys()[minion.state], " vida ", minion.health)
	for key in CHARACTER_ORDER:
		player.set_character(key)
		await get_tree().physics_frame
	print("trocou por todos os aventureiros; atual ", player.character_name)
	print("SMOKE OK")
	get_tree().quit()
