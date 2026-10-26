class_name Story
extends Node
## A história na ilha (seção 4 do doc): prólogo na praça, lanternas da cidade, ponte, lanternas da mata
## e o cemitério dos esqueletos. Cada região é uma Defense; vencer apaga a lanterna, deixa a região em festa e entrega
## a recompensa. Também cuida do objetivo atual (texto e ponto que o marcador da tela aponta).

signal objective_changed(text: String)

## Ondas por região: lista de [tipo, quantidade]. O guardião vem na última onda.
const REGIONS := {
	"praca": {
		"nome": "Praia do Cais", "titulo": "praia do cais", "lanterna": "", "guardiao": "", "recompensa": "", "bandeira": "Praca",
		"ondas": [[["Skeleton_Minion", 3]], [["Skeleton_Minion", 4], ["Skeleton_Rogue", 1]]],
	},
	"oeste": {
		"nome": "Lanterna Oeste", "titulo": "Lanterna Oeste", "lanterna": "Oeste", "guardiao": "ossao", "recompensa": "granulado", "bandeira": "CidadeOeste",
		"ondas": [[["Skeleton_Minion", 5]], [["Skeleton_Minion", 4], ["Skeleton_Warrior", 2]], [["Skeleton_Minion", 4], ["Skeleton_Warrior", 1]]],
	},
	"leste": {
		"nome": "Lanterna Leste", "titulo": "Lanterna Leste", "lanterna": "Leste", "guardiao": "mira_torta", "recompensa": "pipoqueira", "bandeira": "CidadeLeste",
		"ondas": [[["Skeleton_Minion", 4], ["Skeleton_Rogue", 1]], [["Skeleton_Minion", 3], ["Skeleton_Rogue", 3]], [["Skeleton_Minion", 3], ["Skeleton_Rogue", 2]]],
	},
	"clareira": {
		"nome": "Clareira da Jabuticabeira", "titulo": "Lanterna da Clareira", "lanterna": "Clareira", "guardiao": "torre", "recompensa": "coracao", "bandeira": "Clareira",
		"ondas": [[["Skeleton_Minion", 4], ["Skeleton_Mage", 1]], [["Skeleton_Golem", 1], ["Skeleton_Minion", 2], ["Skeleton_Mage", 2], ["Skeleton_Rogue", 1]], [["Skeleton_Mage", 2]]],
	},
	"ventos": {
		"nome": "Morro dos Ventos", "titulo": "Lanterna do Morro dos Ventos", "lanterna": "Ventos", "guardiao": "minionzao", "recompensa": "pe_de_moleque", "bandeira": "MorroDosVentos",
		"ondas": [[["Skeleton_Minion", 5], ["Skeleton_Warrior", 1]], [["Skeleton_Golem", 1], ["Skeleton_Warrior", 1], ["Skeleton_Rogue", 2], ["Skeleton_Mage", 1]], [["Skeleton_Minion", 3]]],
	},
	# Desafio opcional no Bosque das Copas (clareira de árvores gigantes): só o Guerreiro Planta, sem ondas. Não conta para a história.
	"vila": {
		"nome": "Bosque das Copas", "titulo": "Bosque das Copas", "lanterna": "", "guardiao": "planta", "recompensa": "coracao", "bandeira": "",
		"ondas": [[]],
	},
	# Defesa final, no meio do cemitério do Morro (abre quando a cúpula cai): todos os tipos e o Mestre Ossinho.
	"cemiterio": {
		"nome": "Cemitério dos Ossinhos", "titulo": "cemitério", "lanterna": "", "guardiao": "mestre", "recompensa": "", "bandeira": "TopoDoMorro",
		"ondas": [[["Skeleton_Minion", 4], ["Skeleton_Rogue", 1], ["Skeleton_Mage", 1]], [["Skeleton_Warrior", 2], ["Skeleton_Rogue", 2], ["Skeleton_Minion", 2]],
			[["Skeleton_Golem", 1], ["Skeleton_Mage", 1]]],
	},
}
const CITY := ["oeste", "leste"]
const FOREST := ["clareira", "ventos"]
const GUARDIANS := {
	"ossao": preload("res://scripts/boss_ossao.gd"),
	"mira_torta": preload("res://scripts/boss_mira_torta.gd"),
	"torre": preload("res://scripts/boss_torre.gd"),
	"minionzao": preload("res://scripts/boss_minionzao.gd"),
	"mestre": preload("res://scripts/boss_mestre.gd"),
	"planta": preload("res://scripts/boss_planta.gd"),
}
const BALLOONS := ["red/ball_red", "blue/ball_blue", "yellow/ball_yellow", "green/ball_green"]
const PLAT := "res://assets/props/platformer/%s.gltf"
const FESTA := "res://assets/props/festa/%s.gltf"
## Quem vem festejar em cada região vencida: [modelo, variante, atividade].
const PARTY_GUESTS := {
	"oeste": [["MonsterCostume", "monstercostume_texture_D", "torcendo"], ["MagicalGirl", "", "torcendo"], ["Farmer_A", "", "parado"]],
	"leste": [["MagicalGirl", "magical_girl_texture_B", "torcendo"], ["MonsterCostume", "monstercostume_texture_C", "torcendo"], ["Driver", "", "parado"]],
	"clareira": [["MonsterCostume", "", "torcendo"], ["Hiker", "hiker_texture_b", "parado"], ["Farmer_B", "", "torcendo"]],
	"ventos": [["MagicalGirl", "magical_girl_texture_D", "torcendo"], ["MonsterCostume", "monstercostume_texture_B", "torcendo"], ["Hiker", "", "parado"]],
}
const PARTY_LINES := ["Obrigado! Agora é festa aqui também!", "Viva! A lanterna apagou!", "Vem dançar com a gente!"]
const CEMETERY := Vector3(0, 26, 2)
const BRIDGE_SOUTH_Z := -97.0

var game: Node
var island: Node3D
## antes, prologo, cidade, mata, cemiterio, festa (epílogo, à noite), fim (depois dos créditos)
var stage := "antes"
var defenses := {}
var lanterns := {}
var rewards: Array[RewardPickup] = []
var objective_text := ""
var objective_target := Vector3.INF
## Testes: ondas e intervalos curtos.
var fast := false
## Fotos do álbum: {legenda, arquivo, imagem} (a imagem só fica na memória; o arquivo vai para user://album/).
var photos: Array = []
## Recordes: ondas no "Defender a festa" e acertos na barraca de tiro.
var records := {"festa": 0, "tiro": 0}
## Legenda da foto tirada quando cada região é vencida.
const PHOTO_CAPTIONS := {
	"praca": "A primeira defesa, na praia do cais",
	"oeste": "O Ossão foi embora de balão",
	"leste": "A Mira-Torta errou de novo",
	"clareira": "A Torre de Ossinhos desmontou",
	"ventos": "O Minionzão ficou tonto",
	"vila": "O Guerreiro Planta virou amigo da gente",
}

var _crowd_check := 0.0
var _dome: StaticBody3D
var _gate: StaticBody3D
var _gate_left: Node3D
var _gate_right: Node3D
var _central_orb: MeshInstance3D


func setup(p_game: Node, p_island: Node3D) -> void:
	game = p_game
	island = p_island
	game.player.keep_only_weapons(["pacoca"])
	_dome = island.get_node("Morro/CupulaDoCemiterio")
	_central_orb = island.get_node("Morro/Cemiterio/LanternaCentral")
	_gate = island.get_node_or_null("Morro/Cemiterio/PortaoDoCemiterio")
	_gate_left = island.get_node("Morro/Cemiterio").find_child("arch_gate_left", true, false)
	_gate_right = island.get_node("Morro/Cemiterio").find_child("arch_gate_right", true, false)
	for key in ["Oeste", "Leste", "Ventos", "Clareira"]:
		lanterns[key] = {
			"orb": island.get_node("LanternasVisuais/Esfera" + key),
			"beam": island.get_node("LanternasVisuais/Raio" + key),
			"lit": false,
		}
		_set_lantern_look(key, false)
	_set_orb_lit(_central_orb, false)
	for id in REGIONS:
		var spec: Dictionary = REGIONS[id]
		var marker: Marker3D = island.get_node("Marcadores/Regioes/" + id)
		var d := Defense.new()
		d.name = "Defesa_" + id
		d.id = id
		d.nome = spec.nome
		d.game = game
		d.center = marker.global_position
		d.radius = marker.get_meta("raio", 22.0)
		for c in marker.get_children():
			d.cracks.append((c as Node3D).global_position)
		d.waves = spec.ondas
		d.guardian_script = GUARDIANS.get(spec.guardiao)
		d.won.connect(_on_defense_won)
		d.changed.connect(func(_d: Defense) -> void: _refresh_objective())
		d.guardian_spawned.connect(func(_d: Defense, b: Boss) -> void: game.show_guardian(b))
		d.guardian_left.connect(func(_d: Defense) -> void: game.hide_guardian())
		add_child(d)
		defenses[id] = d
	_refresh_objective()


## Começa o prólogo (chamado quando o jogador escolhe o personagem pela primeira vez).
func start() -> void:
	if stage != "antes":
		return
	stage = "prologo"
	_set_fast()
	defenses.praca.activate()
	game.banner("Véspera da Festa do Cafuné", "Os esqueletos estão chegando pela praia! Vá até o cais e defenda a festa.")
	_refresh_objective()
	save()


func _set_fast() -> void:
	for d in defenses.values():
		d.fast = fast


func _physics_process(delta: float) -> void:
	_crowd_check -= delta
	if _crowd_check <= 0.0:
		_crowd_check = 0.5
		_update_crowd()
	if stage in ["cidade", "mata", "cemiterio", "festa", "fim"]:
		_refresh_objective()


# --- regiões vencidas --------------------------------------------------------

func _on_defense_won(d: Defense) -> void:
	var spec: Dictionary = REGIONS[d.id]
	if PHOTO_CAPTIONS.has(d.id):
		get_tree().create_timer(1.6 if not fast else 0.1, false).timeout.connect(func() -> void: take_photo(PHOTO_CAPTIONS[d.id]))
	if d.id == "vila":
		_celebrate(d)
		_spawn_reward(spec.recompensa, d.center + Vector3(0, 0, 3.0))
		game.banner("Desafio vencido!", "O Guerreiro Planta reconheceu você como amigo da mata.", Color("#c9f7a0"))
		_refresh_objective()
		save()
		return
	_celebrate(d)
	game.activate_checkpoint(spec.bandeira)
	if spec.lanterna != "":
		_set_lantern_look(spec.lanterna, false, true)
	if spec.recompensa != "":
		_spawn_reward(spec.recompensa, d.center + Vector3(0, 0, 3.0))
	match stage:
		"prologo":
			_light_lanterns()
			stage = "cidade"
			for id in CITY:
				defenses[id].activate()
			game.banner("O Mestre Ossinho acendeu as Lanternas Mágicas!", "Apague as duas lanternas da cidade.", Color("#d9a8ff"))
		"cidade":
			if _all_won(CITY):
				stage = "mata"
				for id in FOREST:
					defenses[id].activate()
				defenses.vila.activate()
				game.banner("%s apagada!" % spec.titulo, "Agora as lanternas da mata, do outro lado da ponte!")
			else:
				game.banner("%s apagada!" % spec.titulo, "Falta uma lanterna na cidade.")
		"mata":
			if _all_won(FOREST):
				_open_dome()
				stage = "cemiterio"
				defenses.cemiterio.activate()
				game.banner("As quatro lanternas apagaram!", "A cúpula do cemitério caiu. Suba o Morro!", Color("#d9a8ff"))
			else:
				game.banner("%s apagada!" % spec.titulo, "Falta uma lanterna na mata.")
		"cemiterio":
			# O desfecho em cena leva ao epílogo, que salva a campanha já na festa.
			game.ending.start_cutscene(d.boss as BossMestre)
			_refresh_objective()
			return
	_refresh_objective()
	save()


func _spawn_reward(kind: String, pos: Vector3) -> void:
	var r := RewardPickup.new()
	r.kind = kind
	r.collected.connect(_on_reward_collected)
	game.add_child(r)
	r.global_position = pos
	rewards.append(r)
	r.tree_exiting.connect(func() -> void: rewards.erase(r))


func _all_won(ids: Array) -> bool:
	return ids.all(func(id: String) -> bool: return defenses[id].state == Defense.State.VENCIDA)


func _on_reward_collected(r: RewardPickup) -> void:
	var player: Player = game.player
	if r.kind == "coracao":
		player.add_max_heart()
		game.banner("+1 coração!", "Agora você tem %d corações." % player.max_hearts, Color("#ff8fa3"))
	else:
		player.unlock_weapon(r.kind)
		var i := Weapons.index_of(r.kind)
		var def := Weapons.get_def(i)
		game.banner("Novo blaster: %s!" % def.nome, "No controle, direcional %s. No teclado, a tecla %d." % [Weapons.DPAD_WORDS[i], i + 1], def.cor)
	_refresh_objective()
	save.call_deferred()


## Região em festa: postes com balões em volta do círculo e confete (quiet: ao carregar a campanha, sem
## confete nem comemoração).
func _celebrate(d: Defense, quiet := false) -> void:
	var party := Node3D.new()
	party.name = "Festa_" + d.id
	game.add_child(party)
	for k in 8:
		var a := TAU * k / 8.0
		var pos := d.center + Vector3(cos(a), 0, sin(a)) * (d.radius - 3.0)
		if _on_street_or_water(pos):
			continue
		var pole: Node3D = load(PLAT % "neutral/pillar_1x1x4").instantiate()
		pole.scale = Vector3(0.5, 0.7, 0.5)
		party.add_child(pole)
		pole.global_position = pos
		var ball: Node3D = load(PLAT % BALLOONS[k % BALLOONS.size()]).instantiate()
		ball.scale = Vector3(0.5, 0.6, 0.5)
		party.add_child(ball)
		ball.global_position = pos + Vector3.UP * 3.6
		if not quiet:
			Fx.confetti(game, pos + Vector3.UP * 3.0, 20, 4.0)
	if not quiet:
		for t in get_tree().get_nodes_in_group(&"moradores"):
			if (t as Node3D).global_position.distance_to(d.center) < d.radius + _crowd_reach(d) + 2.0:
				(t as Townsperson).celebrate(8.0, "Viva!")
	if PARTY_GUESTS.has(d.id):
		_party_guests(d, quiet)


## Uma mesa com comida e três moradores que chegam para festejar na região vencida.
func _party_guests(d: Defense, quiet := false) -> void:
	var table_pos: Vector3 = game._ground_point(d.center + Vector3(5.0, 0, 3.0))
	var table := StaticBody3D.new()
	table.name = "MesaDaFesta_" + d.id
	table.collision_layer = 1
	game.add_child(table)
	table.global_position = table_pos
	var top: Node3D = load(FESTA % "comida/table_round_B_tablecloth_red").instantiate()
	top.scale = Vector3.ONE * 0.8
	table.add_child(top)
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.2
	cyl.height = 0.8
	cs.shape = cyl
	cs.position.y = 0.4
	table.add_child(cs)
	for spec in [["comida/food_pizza_cheese_plated", Vector3(-0.3, 0.8, -0.3), 0.42], ["doces/plate_decorated_A", Vector3(0.45, 0.8, 0.35), 0.7],
			["comida/icecream_cone_stacked", Vector3(0.4, 0.8, -0.5), 0.6]]:
		var food: Node3D = load(FESTA % spec[0]).instantiate()
		food.scale = Vector3.ONE * spec[2]
		food.position = spec[1]
		table.add_child(food)
	var guests: Array = PARTY_GUESTS[d.id]
	for k in guests.size():
		var a := TAU * k / guests.size() + 0.4
		var pos: Vector3 = game._ground_point(table_pos + Vector3(cos(a), 0, sin(a)) * 2.4)
		var to_table := table_pos - pos
		var spec := {"nome": "Convidado_%s_%d" % [d.id, k], "modelo": guests[k][0], "variante": guests[k][1],
			"atividade": guests[k][2], "falas": PackedStringArray([PARTY_LINES[k % PARTY_LINES.size()]])}
		var t: Townsperson = game.spawn_townsperson(spec, pos, atan2(to_table.x, to_table.z))
		if not quiet:
			t.celebrate(8.0)


## Os postes de balão da comemoração não ficam na rua (a cidade vai de x −72 a 72 e de z 98 a 202) nem na água.
func _on_street_or_water(pos: Vector3) -> bool:
	if pos.x > -72.0 and pos.x < 72.0 and pos.z > 98.0 and pos.z < 202.0:
		return true
	return game._ground_point(pos).y < -0.4


## Até onde a torcida ouve a luta: a praça inteira acompanha a defesa da praia ao lado.
func _crowd_reach(d: Defense) -> float:
	return 48.0 if d.id == "praca" else 14.0


## Moradores perto de uma onda em andamento torcem pelo aventureiro.
func _update_crowd() -> void:
	var running := running_defense()
	for t in get_tree().get_nodes_in_group(&"moradores"):
		var near := running != null and running.state == Defense.State.ONDA \
				and (t as Node3D).global_position.distance_to(running.center) < running.radius + _crowd_reach(running)
		(t as Townsperson).crowd = near


# --- lanternas, ponte e cúpula -----------------------------------------------

func _light_lanterns() -> void:
	var delay := 0.0
	for key in lanterns:
		get_tree().create_timer(delay).timeout.connect(_set_lantern_look.bind(key, true, true))
		delay += 0.5
	_set_orb_lit(_central_orb, true)


func _set_lantern_look(key: String, lit: bool, animate := false) -> void:
	var l: Dictionary = lanterns[key]
	l.lit = lit
	(l.beam as Node3D).visible = lit
	_set_orb_lit(l.orb, lit)
	if animate:
		Fx.confetti(game, (l.orb as Node3D).global_position, 40 if lit else 70, 5.0)
		Sfx.play_at(game, "estouro" if not lit else "remontar", (l.orb as Node3D).global_position, 4.0)


func _set_orb_lit(orb: MeshInstance3D, lit: bool) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#b06cff") if lit else Color("#6b6f7a")
	mat.emission_enabled = lit
	mat.emission = Color("#b06cff")
	mat.emission_energy_multiplier = 2.0
	orb.material_override = mat


## Pós-jogo: as lanternas mágicas viram lanternas de festa, cada uma de uma cor.
func party_lanterns() -> void:
	var k := 0
	for key in lanterns:
		var l: Dictionary = lanterns[key]
		l.lit = false
		(l.beam as Node3D).visible = false
		(l.orb as MeshInstance3D).material_override = Fx.glow_material(Fx.CONFETTI_COLORS[k % Fx.CONFETTI_COLORS.size()], 2.2)
		k += 1
	_central_orb.material_override = Fx.glow_material(Color("#ffd23f"), 2.2)


func _open_dome() -> void:
	_dissolve(_dome)
	_set_orb_lit(_central_orb, false)
	_open_gate()


## O portão do cemitério (as duas folhas do arco, com a origem na dobradiça) abre para dentro e fica aberto.
func _open_gate(instant := false) -> void:
	if is_instance_valid(_gate):
		_gate.collision_layer = 0
	for spec in [[_gate_left, 1.0], [_gate_right, -1.0]]:
		var door: Node3D = spec[0]
		if not is_instance_valid(door):
			continue
		var target: float = deg_to_rad(105.0) * spec[1]
		if instant:
			door.rotation.y = target
		else:
			var tw := door.create_tween()
			tw.tween_interval(0.6)
			tw.tween_property(door, "rotation:y", target, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if not instant and is_instance_valid(_gate):
		Sfx.play_at(game, "escudo", _gate.global_position)


func gate_open() -> bool:
	return is_instance_valid(_gate_left) and absf(_gate_left.rotation.y) > 1.5 and _gate.collision_layer == 0


## A barreira some: perde a colisão na hora e desaparece em confete.
func _dissolve(body: StaticBody3D) -> void:
	if not is_instance_valid(body) or not body.visible:
		return
	body.collision_layer = 0
	Fx.confetti(game, body.global_position, 90, 6.0)
	Sfx.play_at(game, "estouro", body.global_position, 6.0)
	var tw := body.create_tween()
	tw.tween_property(body, "scale", Vector3(1.0, 0.01, 1.0), 0.6)
	tw.tween_callback(func() -> void: body.visible = false)


## Pula direto para a mata, como se a cidade já tivesse sido vencida (testes e fotos da mata).
func skip_to_forest() -> void:
	for id in ["praca"] + CITY:
		var d: Defense = defenses[id]
		d.state = Defense.State.VENCIDA
		d.active = false
	for key in lanterns:
		_set_lantern_look(key, key in ["Ventos", "Clareira"])
	_set_orb_lit(_central_orb, true)
	game.player.unlock_weapon("granulado")
	game.player.unlock_weapon("pipoqueira")
	game.player.switch_weapon(0)
	open_bridge_now()
	stage = "mata"
	_set_fast()
	for id in FOREST:
		defenses[id].activate()
	defenses.vila.activate()
	_refresh_objective()


## Atalho dos testes: tudo vencido até a cúpula cair, com os quatro blasters; a defesa final fica ativa.
func skip_to_cemetery() -> void:
	for id in ["praca"] + CITY + FOREST:
		var d: Defense = defenses[id]
		d.state = Defense.State.VENCIDA
		d.active = false
	for key in lanterns:
		_set_lantern_look(key, false)
	for id in ["granulado", "pipoqueira", "pe_de_moleque"]:
		game.player.unlock_weapon(id)
	game.player.switch_weapon(0)
	open_bridge_now()
	_dome.collision_layer = 0
	_dome.visible = false
	_open_gate(true)
	stage = "cemiterio"
	_set_fast()
	defenses.cemiterio.activate()
	_refresh_objective()


## A ponte não tem mais barreira (pedido do usuário): fica aberta desde o começo. As defesas da mata só
## começam depois das lanternas da cidade.
func open_bridge_now() -> void:
	pass


func bridge_open() -> bool:
	return true


func dome_open() -> bool:
	return _dome.collision_layer == 0


# --- objetivo ----------------------------------------------------------------

func running_defense() -> Defense:
	for d in defenses.values():
		if d.is_running():
			return d
	return null


func _refresh_objective() -> void:
	var text := ""
	var target := Vector3.INF
	var player: Player = game.player
	var running := running_defense()
	if running:
		text = ("Desafio: %s" if running.id == "vila" else "Defenda: %s") % running.nome
	elif not rewards.is_empty():
		text = "Pegue a recompensa"
		target = rewards[0].global_position + Vector3.UP * 2.0
	else:
		match stage:
			"antes", "prologo":
				text = "Vá até a praia do cais e defenda a festa"
				target = defenses.praca.center
			"cidade":
				var left := CITY.filter(func(id: String) -> bool: return defenses[id].state != Defense.State.VENCIDA)
				text = "Apague as lanternas da cidade (%d de 2)" % (2 - left.size())
				target = _nearest(left)
			"mata":
				var left := FOREST.filter(func(id: String) -> bool: return defenses[id].state != Defense.State.VENCIDA)
				if player.global_position.z > BRIDGE_SOUTH_Z:
					text = "Atravesse a ponte para a mata"
					target = Vector3(0, 1.0, BRIDGE_SOUTH_Z)
				else:
					text = "Apague as lanternas da mata (%d de 2)" % (2 - left.size())
					target = _nearest(left)
			"cemiterio":
				text = "Suba o Morro até o cemitério"
				target = CEMETERY + Vector3.UP * 2.0
			"festa":
				text = "Aproveite a festa! Suba no palco para ver o álbum"
				target = Ending.STAGE_TOP + Vector3.UP * 1.5
			"fim":
				if is_instance_valid(game.party_mode) and game.party_mode.running():
					text = game.party_mode.objective_text()
				else:
					text = "Defenda a festa na praia, ou explore a ilha à vontade!"
					target = defenses.praca.center
	objective_target = target
	if text != objective_text:
		objective_text = text
		objective_changed.emit(text)


# --- campanha salva ------------------------------------------------------------

func save() -> void:
	SaveGame.write(snapshot())


func snapshot() -> Dictionary:
	var player: Player = game.player
	var won := defenses.keys().filter(func(id: String) -> bool: return defenses[id].state == Defense.State.VENCIDA)
	var weapons := Weapons.DEFS.map(func(def: Dictionary) -> String: return def.id).filter(func(id: String) -> bool: return player.has_weapon(id))
	var pending := rewards.filter(func(r: RewardPickup) -> bool: return is_instance_valid(r)).map(
			func(r: RewardPickup) -> Array: return [r.kind, r.global_position.x, r.global_position.y, r.global_position.z])
	return {
		"etapa": stage, "vencidas": won, "blasters": weapons, "coracoes": player.max_hearts,
		"personagem": player.character_name, "bandeira": String(game.current_checkpoint.name),
		"recompensas": pending, "recordes": _records_now(),
		"fotos": photos.map(func(p: Dictionary) -> Dictionary: return {"legenda": p.legenda, "arquivo": p.arquivo}),
	}


func _records_now() -> Dictionary:
	if game.gallery:
		records.tiro = game.gallery.hits
	return records


## Foto do álbum: a tela do jogo sem a interface, guardada na memória e em user://album/.
func take_photo(caption: String) -> void:
	# Sem tela (testes), a foto fica só com a legenda; os créditos mostram um cartão no lugar.
	var image: Image = await game.capture_view()
	var file := ""
	if image != null and not image.is_empty():
		image.resize(960, 540, Image.INTERPOLATE_BILINEAR)
		file = SaveGame.save_photo(image, photos.size())
	else:
		image = null
	photos.append({"legenda": caption, "arquivo": file, "imagem": image})
	if stage not in ["cemiterio"]:
		save()


## Monta a ilha no ponto em que a campanha salva parou.
func restore(data: Dictionary) -> void:
	stage = data.get("etapa", "antes")
	var won: Array = data.get("vencidas", [])
	for id in won:
		if defenses.has(id):
			var d: Defense = defenses[id]
			d.state = Defense.State.VENCIDA
			d.active = false
			_celebrate(d, true)
	var lit := stage in ["cidade", "mata", "cemiterio"]
	for id in REGIONS:
		var key: String = REGIONS[id].lanterna
		if key != "":
			_set_lantern_look(key, lit and not (id in won))
	_set_orb_lit(_central_orb, stage in ["cidade", "mata"])
	if stage in ["cemiterio", "festa", "fim"]:
		_dome.collision_layer = 0
		_dome.visible = false
		_open_gate(true)
	match stage:
		"prologo":
			defenses.praca.activate()
		"cidade":
			for id in CITY:
				defenses[id].activate()
		"mata":
			for id in FOREST:
				defenses[id].activate()
		"cemiterio":
			defenses.cemiterio.activate()
	if stage in ["mata", "cemiterio", "festa", "fim"]:
		defenses.vila.activate()
	var player: Player = game.player
	player.set_character(data.get("personagem", "menino"))
	player.keep_only_weapons(["pacoca"])
	for id in data.get("blasters", []):
		if id != "pacoca":
			player.unlock_weapon(id)
	player.switch_weapon(0)
	player.max_hearts = int(data.get("coracoes", 5))
	player.hearts = player.max_hearts
	player.health_changed.emit(player.hearts, player.max_hearts)
	for r in data.get("recompensas", []):
		_spawn_reward(r[0], Vector3(r[1], r[2], r[3]))
	photos.clear()
	for p in data.get("fotos", []):
		photos.append({"legenda": p.legenda, "arquivo": p.arquivo, "imagem": SaveGame.load_photo(p.arquivo)})
	var saved_records: Dictionary = data.get("recordes", {})
	for k in saved_records:
		records[k] = int(saved_records[k])
	if game.gallery:
		game.gallery.set_hits(records.tiro)
	game.activate_checkpoint(data.get("bandeira", "Praca"))
	player.respawn(game.current_checkpoint.spawn_position())
	_set_fast()
	if stage == "festa":
		game.ending.start_epilogue(false)
	elif stage == "fim":
		game.ending.post_game(false)
	_refresh_objective()


func _nearest(ids: Array) -> Vector3:
	var best := Vector3.INF
	var best_d := INF
	for id in ids:
		var c: Vector3 = defenses[id].center
		var d: float = c.distance_to(game.player.global_position)
		if d < best_d:
			best_d = d
			best = c + Vector3.UP * 5.0
	return best
