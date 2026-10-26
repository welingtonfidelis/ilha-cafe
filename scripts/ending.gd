class_name Ending
extends Node
## Fim da história (seção 4 do doc, "Ato 3" e "Epílogo"), em quatro partes:
## - desfecho em cena no cemitério: o Mestre Ossinho, sentado e sem coroa, recebe o convite da festa
##   das mãos do aventureiro; os esqueletos saem do chão comemorando e a tela escurece ("Na noite seguinte...");
## - epílogo: a Festa do Cafuné à noite na praça, com luzinhas, lua, estrelas e fogos; os esqueletos que
##   foram embora de balão descem de balão como convidados (dançam, tocam na banda, servem doces);
## - créditos: subir no palco abre o álbum de fotos da partida e os créditos (scripts/credits.gd);
## - pós-jogo: a ilha de dia, em festa, com os esqueletos amigos e a "Festa sem fim" no cemitério
##   (scripts/endless_party.gd).

## Centro da praça da festa (o quarteirão PLAZA de tools/gerar_ilha.gd).
const PLAZA := Vector3(0, 0, 170)
## Em cima do palco (as duas plataformas de 4x4 atrás da banda); o retângulo é a área em x e z.
const STAGE_TOP := Vector3(0, 1.0, 158.5)
const STAGE_RECT := Rect2(-4.2, 155.8, 8.4, 4.4)
const SKELETONS := "res://assets/characters/skeletons/%s.glb"
const WEAPONS := "res://assets/weapons/skeleton/%s.gltf"
const FESTA := "res://assets/props/festa/%s.gltf"
const PLAT := "res://assets/props/platformer/%s.gltf"
const FRIEND_LINES := ["Oi! Obrigado pelo convite!", "Agora a gente é amigo, né?", "Ainda estou cheio de doce da festa!",
	"Vou passear na praça mais tarde!", "Desculpa pelos sustos!", "Tchau! Quer dizer... oi!"]
## Convidados da festa: [nome, modelo, escala, atividade, item, giro do item, escala do item, (x, z) a partir
## do centro da praça, para onde olha (graus), falas, destino (quem anda, a partir do centro)].
const GUESTS := [
	["Minionzao", "Skeleton_Minion", 1.8, "dancando", "", Vector3.ZERO, 1.0, Vector2(0, 1.0), 180.0,
		["Eu fiquei tonto na luta... agora fico tonto dançando!"]],
	["Minion1", "Skeleton_Minion", 1.0, "dancando", "", Vector3.ZERO, 1.0, Vector2(3.1, 2.8), 230.0, ["Primeira festa da minha vida!"]],
	["Minion2", "Skeleton_Minion", 1.0, "dancando", "", Vector3.ZERO, 1.0, Vector2(-1.8, 4.1), 150.0, ["Olha o meu passinho!"]],
	["Minion3", "Skeleton_Minion", 1.0, "dancando", "", Vector3.ZERO, 1.0, Vector2(-3.1, -0.8), 60.0, ["Dança com a gente!"]],
	["Minion4", "Skeleton_Minion", 1.0, "dancando", "", Vector3.ZERO, 1.0, Vector2(1.8, -2.1), 0.0, ["Obrigado pelo convite!"]],
	["Trompete", "Skeleton_Warrior", 1.0, "tocando", "moradores/ToySoldier_Trumpet", Vector3.ZERO, 1.0, Vector2(-3.1, -11.2), 0.0,
		["Tu-tu-ruuu! Aprendi ontem!", "A banda me chamou para tocar!"]],
	["Garcom1", "Skeleton_Mage", 1.0, "andando", "festa/doces/plate_decorated_A", Vector3.ZERO, 0.6, Vector2(9.0, 4.0), -90.0,
		["Docinho? Fui eu que servi!", "Brigadeiro de abóbora, quem quer?"], Vector2(5.0, 0.5)],
	["Garcom2", "Skeleton_Mage", 1.0, "andando", "festa/comida/food_pizza_cheese_plated", Vector3.ZERO, 0.35, Vector2(-9.0, -3.6), 90.0,
		["Pizza quentinha! Sem osso!"], Vector2(-5.0, -1.5)],
	["Ossao", "Skeleton_Warrior", 1.7, "parado", "festa/comida/food_burger", Vector3.ZERO, 0.7, Vector2(-8.6, 4.0), -90.0,
		["Essa comida é muito melhor que osso!", "Desculpa pelo susto na Lanterna Oeste!"]],
	["Sorvete", "Skeleton_Rogue", 1.0, "parado", "festa/comida/icecream_cone_stacked", Vector3.ZERO, 0.5, Vector2(10.8, -6.0), 120.0,
		["Sorvete! Eu nunca tinha tomado sorvete!"]],
]
const MESTRE_LINES := ["Melhor festa de todas!", "O vovô está me contando histórias da ilha."]
const MESTRE_PARTY_LINES := ["Vamos brincar de Festa sem fim? É luta de brincadeira, mas vale de verdade!",
	"Fique no círculo dourado quando estiver pronto. Cada onda vencida dá moedas!"]
## A Torre balança ao lado do palco; o aventureiro chega na festa a sudeste do meio da praça.
const TOWER_SPOT := Vector2(-7.4, -8.2)
const ARRIVAL := Vector2(5.5, 9.5)

var game: Node
var story: Story
## O desfecho no cemitério está passando (o menu de pausa fica bloqueado).
var in_cutscene := false
var credits_running := false
var night := false

var _cam: Camera3D
var _scene_nodes: Array[Node] = []
var _party: Node3D
var _night_nodes: Node3D
var _fireworks := 0.0
var _day := {}


func setup(p_game: Node) -> void:
	game = p_game
	story = game.story
	var env: Environment = game.environment
	var sky: ProceduralSkyMaterial = game.sky_material
	var sun: DirectionalLight3D = game.sun_light
	_day = {
		"top": sky.sky_top_color, "horizon": sky.sky_horizon_color, "ground_horizon": sky.ground_horizon_color,
		"ground_bottom": sky.ground_bottom_color, "ambient": env.ambient_light_energy, "fog": env.fog_light_color,
		"sun_color": sun.light_color, "sun_energy": sun.light_energy, "sun_rot": sun.rotation_degrees,
	}


func busy() -> bool:
	return in_cutscene or credits_running


## Esperas da cena: param com o jogo pausado; nos testes, passam bem mais rápido.
func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds * (0.15 if story.fast else 1.0), false).timeout


# --- desfecho no cemitério ------------------------------------------------------------

func start_cutscene(mestre: BossMestre) -> void:
	in_cutscene = true
	var player: Player = game.player
	player.input_enabled = false
	player.velocity = Vector3.ZERO
	game.set_hud_visible(false)
	var m: Vector3 = mestre.global_position if is_instance_valid(mestre) else Story.CEMETERY
	# O aventureiro fica na frente do Mestre, com a coroa no chão entre os dois.
	var front: Vector3 = mestre.forward() if is_instance_valid(mestre) else Vector3.BACK
	front.y = 0.0
	front = front.normalized()
	var stand: Vector3 = game._ground_point(m + front * 5.6)
	player.global_position = stand + Vector3.UP * 0.1
	player.visual.rotation.y = atan2(-front.x, -front.z)
	var mid := (m + stand) * 0.5
	var across := front.cross(Vector3.UP).normalized()
	_cam = Camera3D.new()
	_cam.name = "CameraDoDesfecho"
	_cam.fov = 50.0
	game.add_child(_cam)
	_cam.global_position = mid + across * 11.0 + front * 2.0 + Vector3.UP * 4.6
	_cam.look_at(mid + Vector3.UP * 1.6)
	_cam.make_current()
	var dolly := _cam.create_tween()
	dolly.tween_property(_cam, "global_position", mid + across * 9.5 + front * 1.2 + Vector3.UP * 3.9, 10.0).set_trans(Tween.TRANS_SINE)
	game.banner("O Mestre Ossinho tirou a coroa...", "\"Ninguém nunca convidou a gente para a festa.\"", Color("#d9a8ff"), 3.4)
	await _wait(2.4)
	# O convite: um presente sai das mãos do aventureiro e cai no colo do Mestre.
	var gift: Node3D = load(FESTA % "doces/present_A_red").instantiate()
	gift.scale = Vector3.ONE * 1.4
	game.add_child(gift)
	_scene_nodes.append(gift)
	var from := stand + Vector3.UP * 1.1 - front * 0.6
	var to := m + front * 1.2 + Vector3.UP * 0.9
	gift.global_position = from
	Fx.popup_text(game, stand + Vector3.UP * 2.4, "Toma! É o convite da festa!", Color("#ffd23f"))
	Sfx.play(game, "ui_ok", 0.0, 0.0)
	var arc := func(t: float) -> void:
		gift.global_position = from.lerp(to, t) + Vector3.UP * sin(PI * t) * 1.6
		gift.rotation.y = t * TAU
	gift.create_tween().tween_method(arc, 0.0, 1.0, 1.2 * (0.15 if story.fast else 1.0))
	await _wait(1.3)
	Fx.confetti(game, to + Vector3.UP * 0.4, 40, 4.0)
	if is_instance_valid(mestre):
		Fx.popup_text(game, m + Vector3.UP * 4.2, "Um convite... para a gente?!", Color("#ffd6f3"))
	await _wait(1.0)
	if is_instance_valid(mestre):
		mestre.restart(&"festa/Sit_Floor_StandUp")
	_cemetery_friends(m, front, across)
	await _wait(1.3)
	if is_instance_valid(mestre):
		mestre.model.rotation.y = 0.0
		mestre.ap.play(&"festa/Cheering", 0.3)
	game.banner("Vocês entregaram o convite!", "Amanhã a Festa do Cafuné vai ter convidados novos.", Color("#ffd23f"), 3.6)
	await _wait(1.5)
	await story.take_photo("O Mestre Ossinho tirou a coroa")
	await _wait(3.0)
	# Escurece: "Na noite seguinte..."
	var fade: ColorRect = game.fade
	var tw := fade.create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, 0.8)
	await tw.finished
	var caption := _caption("Na noite seguinte...")
	await _wait(0.6)
	for n in _scene_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_scene_nodes.clear()
	if is_instance_valid(mestre):
		mestre.queue_free()
		if is_instance_valid(mestre.crown_on_floor):
			mestre.crown_on_floor.queue_free()
	_cam.queue_free()
	player.camera.make_current()
	start_epilogue(true)
	await _wait(2.0)
	tw = fade.create_tween()
	tw.tween_property(caption, "modulate:a", 0.0, 0.5)
	tw.tween_property(fade, "modulate:a", 0.0, 1.0)
	tw.tween_callback(caption.queue_free)
	await tw.finished
	in_cutscene = false
	game.set_hud_visible(true)
	player.input_enabled = true
	game.banner("A Festa do Cafuné!", "Os esqueletos chegaram de balão. Aproveite a festa e suba no palco quando quiser!", Color("#ffd23f"), 4.0)


## Esqueletos saem do chão comemorando, no lado oposto ao da câmera: também foram convidados.
func _cemetery_friends(m: Vector3, front: Vector3, across: Vector3) -> void:
	var types := ["Skeleton_Minion", "Skeleton_Rogue", "Skeleton_Minion", "Skeleton_Mage", "Skeleton_Warrior", "Skeleton_Minion"]
	var mid := m + front * 2.8
	for k in types.size():
		var along := lerpf(-4.5, 6.5, float(k) / (types.size() - 1))
		var pos: Vector3 = game._ground_point(mid + front * along - across * randf_range(4.5, 6.5))
		if pos.y > m.y + 0.6:
			continue
		var to_mid := mid - pos
		var t := _spawn({"nome": "AmigoDoCemiterio%d" % k, "modelo_caminho": SKELETONS % types[k], "atividade": "torcendo",
			"falas": PackedStringArray(["Festa!"])}, pos, atan2(to_mid.x, to_mid.z))
		_scene_nodes.append(t)
		t.visual.position.y = -1.8
		var rise := t.create_tween()
		rise.tween_interval(k * 0.15)
		rise.tween_property(t.visual, "position:y", 0.0, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		rise.tween_callback(func() -> void:
			Fx.confetti(game, pos + Vector3.UP * 1.5, 18, 3.0)
			if k % 2 == 0:
				t.say(["Festa!", "Viva!", "Vamos!"][(k >> 1) % 3], 2.5))


func _caption(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 46)
	label.add_theme_color_override("font_color", Color("#ffe9a8"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.modulate.a = 0.0
	game.ui_layer.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.create_tween().tween_property(label, "modulate:a", 1.0, 0.6)
	return label


func _spawn(spec: Dictionary, pos: Vector3, yaw: float) -> Townsperson:
	var t: Townsperson = game.spawn_townsperson(spec, pos, yaw)
	t.add_to_group(&"convidados")
	return t


# --- epílogo: a festa à noite ------------------------------------------------------------

## animate: os convidados descem de balão (ao carregar a campanha já estão na praça).
func start_epilogue(animate: bool) -> void:
	story.stage = "festa"
	_set_night(true)
	_befriend_skeletons()
	_build_party(animate, true)
	story.party_lanterns()
	game.activate_checkpoint("Praca")
	# O aventureiro chega na praça olhando para o palco.
	var player: Player = game.player
	var spot: Vector3 = game._ground_point(PLAZA + Vector3(ARRIVAL.x, 0, ARRIVAL.y))
	player.global_position = spot + Vector3.UP * 0.2
	player.velocity = Vector3.ZERO
	var dir := STAGE_TOP - spot
	dir.y = 0.0
	dir = dir.normalized()
	player.set_yaw(atan2(-dir.x, -dir.z))
	player.visual.rotation.y = atan2(dir.x, dir.z)
	story._refresh_objective()
	if animate:
		_festa_photo()
	story.save()


## Foto da festa para o álbum, de um ângulo bonito (câmera própria por um instante).
func _festa_photo() -> void:
	await _wait(8.0)
	if story.stage != "festa":
		return
	var cam := Camera3D.new()
	cam.fov = 60.0
	game.add_child(cam)
	cam.global_position = PLAZA + Vector3(9.0, 6.5, 14.0)
	cam.look_at(PLAZA + Vector3(-1.0, 1.5, -5.0))
	cam.make_current()
	await story.take_photo("A Festa do Cafuné")
	cam.queue_free()
	if is_instance_valid(game.player):
		game.player.camera.make_current()


func _set_night(on: bool) -> void:
	night = on
	var env: Environment = game.environment
	var sky: ProceduralSkyMaterial = game.sky_material
	var sun: DirectionalLight3D = game.sun_light
	if on:
		sky.sky_top_color = Color("#0f1a4d")
		sky.sky_horizon_color = Color("#3d3f86")
		sky.ground_horizon_color = Color("#3d3f86")
		sky.ground_bottom_color = Color("#0c1a40")
		sky.sky_cover = _stars_texture()
		sky.sky_cover_modulate = Color(1, 1, 1, 0.95)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color("#7884c8")
		env.ambient_light_energy = 0.75
		env.fog_light_color = Color("#262c66")
		env.glow_enabled = true
		env.glow_intensity = 0.9
		env.glow_hdr_threshold = 0.9
		# O "sol" vira a lua: luz fraca e azulada, com o disco no céu na frente do palco.
		sun.light_color = Color("#aab8ff")
		sun.light_energy = 0.35
		sun.light_angular_distance = 2.0
		sun.rotation_degrees = Vector3(-38, 160, 0)
		_build_night_lights()
	else:
		sky.sky_top_color = _day.top
		sky.sky_horizon_color = _day.horizon
		sky.ground_horizon_color = _day.ground_horizon
		sky.ground_bottom_color = _day.ground_bottom
		sky.sky_cover = null
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_energy = _day.ambient
		env.fog_light_color = _day.fog
		env.glow_enabled = false
		sun.light_color = _day.sun_color
		sun.light_energy = _day.sun_energy
		sun.light_angular_distance = 0.0
		sun.rotation_degrees = _day.sun_rot
		if is_instance_valid(_night_nodes):
			_night_nodes.queue_free()


## Estrelas pintadas na textura de cobertura do céu (panorama: o alto da imagem é o zênite).
func _stars_texture() -> ImageTexture:
	var img := Image.create(2048, 1024, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in 1400:
		var x := rng.randi_range(0, 2047)
		var y := int(pow(rng.randf(), 1.4) * 470.0)
		var a := rng.randf_range(0.35, 1.0)
		var c := Color(1.0, rng.randf_range(0.9, 1.0), rng.randf_range(0.8, 1.0), a)
		img.set_pixel(x, y, c)
		if a > 0.85:
			for d in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				img.set_pixel((x + d.x) % 2048, mini(y + d.y, 1023), Color(c, a * 0.6))
	return ImageTexture.create_from_image(img)


## Luzes da noite: postes da cidade perto da praça, lanternas da festa e um foco rosa no palco.
func _build_night_lights() -> void:
	if is_instance_valid(_night_nodes):
		return
	_night_nodes = Node3D.new()
	_night_nodes.name = "LuzesDaNoite"
	game.add_child(_night_nodes)
	var enfeites: Node = game.island.get_node_or_null("Cidade/Enfeites")
	if enfeites:
		for body in enfeites.get_children():
			if not String(body.name).begins_with("streetlight") or not body is Node3D:
				continue
			var p: Vector3 = (body as Node3D).global_position
			if Vector2(p.x - PLAZA.x, p.z - PLAZA.z).length() > 80.0:
				continue
			var top := _top_of(body as Node3D)
			_omni(top - Vector3.UP * 0.6, Color("#ffd89a"), 1.6, 14.0)
	for spot in [Vector2(-4.8, -9.4), Vector2(4.8, -9.4), Vector2(-3.5, 13.6), Vector2(3.5, 13.6)]:
		_omni(PLAZA + Vector3(spot.x, 2.2, spot.y), Color("#ffc46b"), 1.4, 9.0)
	for spot in [Vector2(-11.5, 0.5), Vector2(11.5, 0.5), Vector2(0, 0)]:
		_omni(PLAZA + Vector3(spot.x, 4.5, spot.y), Color("#ffb3e6"), 0.9, 12.0)
	var spot_light := SpotLight3D.new()
	spot_light.light_color = Color("#ff9de2")
	spot_light.light_energy = 3.0
	spot_light.spot_range = 22.0
	spot_light.spot_angle = 28.0
	_night_nodes.add_child(spot_light)
	spot_light.global_position = STAGE_TOP + Vector3(0, 8.0, 9.0)
	spot_light.look_at(STAGE_TOP + Vector3(0, 0.5, 0))


func _omni(pos: Vector3, color: Color, energy: float, light_range: float) -> void:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = light_range
	l.shadow_enabled = false
	_night_nodes.add_child(l)
	l.global_position = pos


## Topo das malhas de um objeto do cenário (onde fica a lâmpada do poste).
func _top_of(node: Node3D) -> Vector3:
	var box := AABB()
	var first := true
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var a: AABB = m.global_transform * m.get_aabb()
		box = a if first else box.merge(a)
		first = false
	if first:
		return node.global_position + Vector3.UP * 4.0
	return Vector3(box.get_center().x, box.end.y, box.get_center().z)


func _physics_process(delta: float) -> void:
	if story == null:
		return
	if night and story.stage == "festa":
		_fireworks -= delta
		if _fireworks <= 0.0:
			_fireworks = randf_range(0.9, 2.0)
			var from := PLAZA + Vector3(randf_range(-20.0, 20.0), 0.5, randf_range(-26.0, -16.0))
			Fx.firework(game, from, randf_range(24.0, 32.0), Fx.CONFETTI_COLORS[randi() % Fx.CONFETTI_COLORS.size()])
	if story.stage == "festa" and not busy():
		var p: Vector3 = game.player.global_position
		if STAGE_RECT.has_point(Vector2(p.x, p.z)) and p.y > STAGE_TOP.y - 0.3 and game.menu_state == "":
			start_credits()


# --- convidados e enfeites da festa -------------------------------------------------------

## A praça em festa: luzinhas coloridas entre os postes de balão e os convidados esqueletos.
func _build_party(animate: bool, with_mestre_on_bench: bool) -> void:
	if is_instance_valid(_party):
		return
	_party = Node3D.new()
	_party.name = "FestaDoCafune"
	game.add_child(_party)
	_string_lights()
	var delay := 0.0
	for spec in GUESTS:
		var off: Vector2 = spec[7]
		var pos: Vector3 = game._ground_point(PLAZA + Vector3(off.x, 0, off.y))
		var data := {"nome": "Convidado" + spec[0], "modelo_caminho": SKELETONS % spec[1], "escala": spec[2],
			"atividade": spec[3], "item": spec[4], "item_rot": spec[5], "item_escala": spec[6], "falas": PackedStringArray(spec[9])}
		if spec.size() > 10:
			var dest: Vector2 = spec[10]
			data.destino = game._ground_point(PLAZA + Vector3(dest.x, 0, dest.y))
		var t := _spawn(data, pos, deg_to_rad(spec[8]))
		if animate:
			_drop_later(t, delay)
			delay += 0.3
	if is_instance_valid(game.gallery):
		var g: Transform3D = game.gallery.global_transform
		var pos: Vector3 = game._ground_point(g * Vector3(-3.5, 0, -1.8))
		var look := (g * Vector3(0, 0, 3.0)) - pos
		var mira := _spawn({"nome": "ConvidadoMiraTorta", "modelo_caminho": SKELETONS % "Skeleton_Rogue", "escala": 1.4,
			"atividade": "parado", "item": WEAPONS % "Skeleton_Crossbow",
			"falas": PackedStringArray(["Eu sempre erro o alvo... mas aqui é divertido!", "Vai lá, mostra como se acerta!"])},
			pos, atan2(look.x, look.z))
		if animate:
			_drop_later(mira, delay)
	var tower := SkeletonTower.new()
	tower.name = "TorreDeOssinhosConvidada"
	tower.add_to_group(&"convidados")
	_party.add_child(tower)
	tower.global_position = game._ground_point(PLAZA + Vector3(TOWER_SPOT.x, 0, TOWER_SPOT.y))
	if animate:
		tower.drop_in(24.0, 5.0 * (0.15 if story.fast else 1.0))
	if with_mestre_on_bench:
		_mestre_on_bench(animate)


## Os balões chegam um atrás do outro (delay).
func _drop_later(t: Townsperson, delay: float) -> void:
	var s := 0.15 if story.fast else 1.0
	t.drop_in(randf_range(18.0, 24.0), randf_range(4.0, 5.5) * s, delay * s)


## O Mestre Ossinho, sem coroa, sentado no banco ao lado do vovô.
func _mestre_on_bench(animate: bool) -> void:
	var vovo := game.get_node_or_null("Vovo") as Townsperson
	var pos := PLAZA + Vector3(-4.2, 0, 5.7)
	var yaw := deg_to_rad(45.0)
	if vovo:
		pos = vovo.global_position + vovo.visual.global_basis.x * 0.95
		yaw = vovo.visual.rotation.y
	var t := _spawn({"nome": "ConvidadoMestre", "modelo_caminho": SKELETONS % "Necromancer", "atividade": "sentado_banco",
		"esconder": PackedStringArray(["Necromancer_Crown"]), "falas": PackedStringArray(MESTRE_LINES)}, pos, yaw)
	if animate:
		_drop_later(t, 2.0)


## Cordões de lâmpadas coloridas ligando os oito postes de balão da praça.
func _string_lights() -> void:
	var mats: Array[StandardMaterial3D] = []
	for c in Fx.CONFETTI_COLORS:
		mats.append(Fx.glow_material(c, 2.6))
	var bulb := SphereMesh.new()
	bulb.radius = 0.1
	bulb.height = 0.2
	bulb.radial_segments = 8
	bulb.rings = 4
	var wire := ImmediateMesh.new()
	wire.surface_begin(Mesh.PRIMITIVE_LINES, Fx.flat_material(Color("#3a2f45")))
	var tops: Array[Vector3] = []
	for k in 8:
		var a := TAU * k / 8.0
		tops.append(PLAZA + Vector3(cos(a) * 13.0, 0, sin(a) * 13.0))
	var n := 0
	for k in 8:
		var p0: Vector3 = tops[k]
		var p1: Vector3 = tops[(k + 1) % 8]
		var y0: float = (game._ground_point(p0) as Vector3).y + 2.45
		var y1: float = (game._ground_point(p1) as Vector3).y + 2.45
		var prev := Vector3.INF
		for i in 13:
			var t := i / 12.0
			var p := p0.lerp(p1, t)
			p.y = lerpf(y0, y1, t) - 0.8 * 4.0 * t * (1.0 - t)
			if prev != Vector3.INF:
				wire.surface_add_vertex(prev)
				wire.surface_add_vertex(p)
			prev = p
			if i > 0 and i < 12:
				var mi := MeshInstance3D.new()
				mi.mesh = bulb
				mi.material_override = mats[n % mats.size()]
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				_party.add_child(mi)
				mi.global_position = p - Vector3.UP * 0.12
				n += 1
	wire.surface_end()
	var wires := MeshInstance3D.new()
	wires.mesh = wire
	wires.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_party.add_child(wires)


## Os esqueletos que dormiam pela ilha viram amigos: ficam no lugar, sentados ou acenando.
func _befriend_skeletons() -> void:
	var k := 0
	for e in game.enemies.duplicate():
		if not is_instance_valid(e) or e.has_meta("onda"):
			continue
		var type_name: String = e.type_name
		var pos: Vector3 = e.global_position
		e.queue_free()
		if type_name == "Skeleton_Golem":
			continue
		var sits := k % 3 == 0
		_spawn({"nome": "Amigo%d" % k, "modelo_caminho": SKELETONS % type_name, "atividade": "sentado_chao" if sits else "parado",
			"falas": PackedStringArray([FRIEND_LINES[k % FRIEND_LINES.size()]])}, pos, randf() * TAU)
		k += 1


# --- créditos e pós-jogo ---------------------------------------------------------------

func start_credits() -> void:
	credits_running = true
	game.set_hud_visible(false)
	game.player.input_enabled = false
	get_tree().paused = true
	var c := Credits.new()
	c.photos = story.photos
	c.fast = story.fast
	game.add_child(c)
	await c.finished
	get_tree().paused = false
	credits_running = false
	post_game(true)


## Depois dos créditos: de dia, a ilha em festa e a brincadeira do Mestre na praia.
func post_game(animate: bool) -> void:
	var fade: ColorRect = game.fade
	if animate:
		fade.modulate.a = 1.0
	story.stage = "fim"
	_set_night(false)
	_befriend_skeletons()
	_build_party(false, false)
	var bench := game.get_node_or_null("ConvidadoMestre")
	if bench:
		bench.queue_free()
	story.party_lanterns()
	var cemiterio: Defense = story.defenses.cemiterio
	if not is_instance_valid(game.party_mode):
		var pd := EndlessParty.new()
		pd.name = "FestaSemFim"
		pd.game = game
		pd.story = story
		pd.center = cemiterio.center
		pd.radius = cemiterio.radius
		pd.cracks = cemiterio.cracks.duplicate()
		pd.fast = story.fast
		game.add_child(pd)
		game.party_mode = pd
		var host_pos: Vector3 = game._ground_point(cemiterio.center + Vector3(5.0, 0, -7.0))
		var look := cemiterio.center - host_pos
		var host := _spawn({"nome": "MestreDaBrincadeira", "modelo_caminho": SKELETONS % "Necromancer", "atividade": "parado",
			"esconder": PackedStringArray(["Necromancer_Crown"]), "falas": PackedStringArray(MESTRE_PARTY_LINES)},
			host_pos, atan2(look.x, look.z))
		pd.host = host
	story._refresh_objective()
	if animate:
		var player: Player = game.player
		player.input_enabled = true
		game.set_hud_visible(true)
		var tw := fade.create_tween()
		tw.tween_interval(0.3)
		tw.tween_property(fade, "modulate:a", 0.0, 1.0)
		game.banner("Depois da festa...", "Os esqueletos agora são amigos da ilha. O Mestre Ossinho chamou você para a Festa sem fim no cemitério!", Color("#ffd23f"), 4.5)
	story.save()


## Torre de Ossinhos convidada: quatro Minions empilhados, balançando e acenando.
class SkeletonTower:
	extends StaticBody3D
	const SPACING := 1.6
	var _time := 0.0
	var _stack: Node3D

	func _ready() -> void:
		collision_layer = Townsperson.LAYER
		collision_mask = 0
		var cs := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = 0.6
		cap.height = 6.4
		cs.shape = cap
		cs.position.y = 3.2
		add_child(cs)
		_stack = Node3D.new()
		add_child(_stack)
		for k in 4:
			var m: Node3D = load(Ending.SKELETONS % "Skeleton_Minion").instantiate()
			m.position.y = k * SPACING
			m.rotation.y = randf_range(-0.3, 0.3)
			_stack.add_child(m)
			var ap := AnimUtil.make_player(m, ["geral", "festa", "especial"])
			ap.play(&"festa/Waving" if k == 3 else &"especial/Skeletons_Idle")
			ap.seek(randf() * 1.0, true)
		_time = randf() * 5.0

	func _process(delta: float) -> void:
		_time += delta
		_stack.rotation.z = sin(_time * 1.5) * 0.07
		_stack.rotation.x = sin(_time * 1.1 + 0.6) * 0.05

	func drop_in(height: float, seconds: float) -> void:
		var land := global_position
		global_position = land + Vector3.UP * height
		var balloons := Fx.balloons(4 * SPACING + 0.6)
		add_child(balloons)
		var tw := create_tween()
		tw.tween_property(self, "global_position", land, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void:
			Fx.confetti(get_parent(), global_position + Vector3.UP * 8.0, 30, 3.0)
			Sfx.play_at(get_parent(), "estouro", global_position + Vector3.UP * 7.0, -6.0)
			balloons.queue_free())
