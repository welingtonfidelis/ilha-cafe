class_name Story
extends Node
## A história na ilha (seção 4 do doc): prólogo na praça, lanternas da cidade, ponte, lanternas da mata
## e castelinho. Cada região é uma Defense; vencer apaga a lanterna, deixa a região em festa e entrega
## a recompensa. Também cuida do objetivo atual (texto e ponto que o marcador da tela aponta).

signal objective_changed(text: String)

## Ondas por região: lista de [tipo, quantidade]. Guardiões ainda não feitos ficam sem (próxima etapa).
const REGIONS := {
	"praca": {
		"nome": "Praça da Festa", "titulo": "praça", "lanterna": "", "guardiao": "", "recompensa": "", "bandeira": "Praca",
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
		"ondas": [[["Skeleton_Minion", 4], ["Skeleton_Mage", 1]], [["Skeleton_Minion", 3], ["Skeleton_Mage", 2], ["Skeleton_Rogue", 1]], [["Skeleton_Mage", 2]]],
	},
	"ventos": {
		"nome": "Morro dos Ventos", "titulo": "Lanterna do Morro dos Ventos", "lanterna": "Ventos", "guardiao": "minionzao", "recompensa": "pe_de_moleque", "bandeira": "MorroDosVentos",
		"ondas": [[["Skeleton_Minion", 5], ["Skeleton_Warrior", 1]], [["Skeleton_Warrior", 2], ["Skeleton_Rogue", 2], ["Skeleton_Mage", 1]], [["Skeleton_Minion", 3]]],
	},
}
const CITY := ["oeste", "leste"]
const FOREST := ["clareira", "ventos"]
const GUARDIANS := {"ossao": preload("res://scripts/boss_ossao.gd"), "mira_torta": preload("res://scripts/boss_mira_torta.gd")}
const BALLOONS := ["red/ball_red", "blue/ball_blue", "yellow/ball_yellow", "green/ball_green"]
const PLAT := "res://assets/props/platformer/%s.gltf"
const CASTLE := Vector3(0, 26, 0)
const BRIDGE_SOUTH_Z := -97.0

var game: Node
var island: Node3D
## antes, prologo, cidade, mata, castelo, fim
var stage := "antes"
var defenses := {}
var lanterns := {}
var rewards: Array[RewardPickup] = []
var objective_text := ""
var objective_target := Vector3.INF
## Testes: ondas e intervalos curtos.
var fast := false

var _bridge: StaticBody3D
var _dome: StaticBody3D
var _central_orb: MeshInstance3D


func setup(p_game: Node, p_island: Node3D) -> void:
	game = p_game
	island = p_island
	game.player.keep_only_weapons(["pacoca"])
	_bridge = island.get_node("BarreiraDaPonte")
	_dome = island.get_node("Morro/CupulaDoCastelinho")
	_central_orb = island.get_node("Morro/Castelinho/LanternaCentral")
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
	game.banner("Véspera da Festa do Cafuné", "Os esqueletos querem levar a festa! Defenda a praça.")
	_refresh_objective()


func _set_fast() -> void:
	for d in defenses.values():
		d.fast = fast


func _physics_process(_delta: float) -> void:
	if stage == "castelo" and is_instance_valid(game.player):
		if game.player.global_position.distance_to(CASTLE) < 14.0:
			stage = "fim"
			game.banner("Você chegou ao castelinho!", "O Mestre Ossinho aparece na próxima versão do jogo.")
			_refresh_objective()
	if stage in ["cidade", "mata", "castelo"]:
		_refresh_objective()


# --- regiões vencidas --------------------------------------------------------

func _on_defense_won(d: Defense) -> void:
	var spec: Dictionary = REGIONS[d.id]
	_celebrate(d)
	game.activate_checkpoint(spec.bandeira)
	if spec.lanterna != "":
		_set_lantern_look(spec.lanterna, false, true)
	if spec.recompensa != "":
		var r := RewardPickup.new()
		r.kind = spec.recompensa
		r.collected.connect(_on_reward_collected)
		game.add_child(r)
		r.global_position = d.center + Vector3(0, 0, 3.0)
		rewards.append(r)
		r.tree_exiting.connect(func() -> void: rewards.erase(r))
	match stage:
		"prologo":
			_light_lanterns()
			stage = "cidade"
			for id in CITY:
				defenses[id].activate()
			game.banner("O Mestre Ossinho acendeu as Lanternas Mágicas!", "Apague as duas lanternas da cidade.", Color("#d9a8ff"))
		"cidade":
			if _all_won(CITY):
				_open_bridge()
				stage = "mata"
				for id in FOREST:
					defenses[id].activate()
				game.banner("%s apagada!" % spec.titulo, "A barreira da ponte sumiu: a mata está aberta!")
			else:
				game.banner("%s apagada!" % spec.titulo, "Falta uma lanterna na cidade.")
		"mata":
			if _all_won(FOREST):
				_open_dome()
				stage = "castelo"
				game.banner("As quatro lanternas apagaram!", "A cúpula do castelinho caiu. Suba o Morro!", Color("#d9a8ff"))
			else:
				game.banner("%s apagada!" % spec.titulo, "Falta uma lanterna na mata.")
	_refresh_objective()


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
		game.banner("Novo blaster: %s!" % def.nome, "No controle, aperte %s no direcional. No teclado, a tecla %d." % [Weapons.ARROWS[i], i + 1], def.cor)
	_refresh_objective()


## Região em festa: postes com balões em volta do círculo e confete.
func _celebrate(d: Defense) -> void:
	var party := Node3D.new()
	party.name = "Festa_" + d.id
	game.add_child(party)
	for k in 8:
		var a := TAU * k / 8.0
		var pos := d.center + Vector3(cos(a), 0, sin(a)) * (d.radius - 3.0)
		var pole: Node3D = load(PLAT % "neutral/pillar_1x1x4").instantiate()
		pole.scale = Vector3(0.5, 0.7, 0.5)
		party.add_child(pole)
		pole.global_position = pos
		var ball: Node3D = load(PLAT % BALLOONS[k % BALLOONS.size()]).instantiate()
		ball.scale = Vector3(0.5, 0.6, 0.5)
		party.add_child(ball)
		ball.global_position = pos + Vector3.UP * 3.6
		Fx.confetti(game, pos + Vector3.UP * 3.0, 20, 4.0)


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


func _open_bridge() -> void:
	_dissolve(_bridge)


func _open_dome() -> void:
	_dissolve(_dome)
	_set_orb_lit(_central_orb, false)


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


## Abre a ponte na hora (usado pelo teste da ilha).
func open_bridge_now() -> void:
	_bridge.collision_layer = 0
	_bridge.visible = false


func bridge_open() -> bool:
	return _bridge.collision_layer == 0


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
		text = "Defenda: %s" % running.nome
	elif not rewards.is_empty():
		text = "Pegue a recompensa"
		target = rewards[0].global_position + Vector3.UP * 2.0
	else:
		match stage:
			"antes", "prologo":
				text = "Defenda a praça da festa"
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
			"castelo":
				text = "Suba o Morro até o castelinho"
				target = CASTLE + Vector3.UP * 2.0
			"fim":
				text = "Explore a ilha à vontade!"
	objective_target = target
	if text != objective_text:
		objective_text = text
		objective_changed.emit(text)


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
