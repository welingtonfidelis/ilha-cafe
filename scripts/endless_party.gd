class_name EndlessParty
extends Node3D
## "Festa sem fim" (pós-jogo, seção 4 do doc; pedido do usuário em 2026-10-26, no lugar da brincadeira dos
## cinco presentes): ondas sem fim no cemitério do Morro, propostas pelo Mestre Ossinho. É brincadeira,
## mas os esqueletos lutam de verdade, como na história. Ficar 1 s no círculo dourado começa. As ondas
## crescem e misturam os tipos; a cada 5 ondas vem um guardião (revezando os cinco, cada volta mais forte).
## Entre as ondas caem munição e coração no centro. Ficar tonto (ou sair para longe) acaba a festa; o
## recorde é o número de ondas vencidas e cada onda vencida dá moedas para a lojinha.

const START_RADIUS := 2.2
const START_HOLD := 1.0
const COUNTDOWN := 3.0
const BREAK_TIME := 6.0
const SPAWN_GAP := 0.7
const LEASH := 60.0
const MAX_AT_ONCE := 12
## Guardiões que aparecem a cada 5 ondas, nesta ordem.
const GUARDIANS := ["ossao", "mira_torta", "torre", "minionzao", "planta"]

enum State { PARADA, CONTAGEM, ONDA, INTERVALO, FIM }

var game: Node
var story: Story
var center := Vector3.ZERO
var radius := 18.0
var cracks: Array[Vector3] = []
var fast := false
## O Mestre Ossinho, que chama para a festa e torce durante as ondas.
var host: Townsperson
var state := State.PARADA
var wave := 0
var cleared := 0
var remaining := 0
var alive: Array[Node3D] = []
var boss: Boss

var _timer := 0.0
var _hold := 0.0
var _best_before := 0
var _to_spawn: Array[String] = []
var _crack_i := 0
var _board: Label3D
var _ring: MeshInstance3D
var _visuals: Node3D


func _ready() -> void:
	_visuals = Node3D.new()
	add_child(_visuals)
	_ring = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = START_RADIUS
	disc.bottom_radius = START_RADIUS
	disc.height = 0.04
	disc.material = Defense.glow(Color(1.0, 0.82, 0.25, 0.5))
	_ring.mesh = disc
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	_ring.global_position = game._ground_point(center) + Vector3.UP * 0.05
	_board = Label3D.new()
	_board.font_size = 56
	_board.outline_size = 14
	_board.outline_modulate = Color(0.15, 0.08, 0.25)
	_board.modulate = Color("#ffd23f")
	_board.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_board.pixel_size = 0.008
	add_child(_board)
	_board.global_position = _ring.global_position + Vector3.UP * 4.4
	# Mais pontos de saída que as rachaduras da história: nos eixos, onde o chão é plano.
	var ground_y: float = _ring.global_position.y
	for k in 4:
		var a := TAU * k / 4.0
		var p: Vector3 = game._ground_point(center + Vector3(cos(a), 0, sin(a)) * 13.0)
		if absf(p.y - ground_y) < 0.6:
			cracks.append(p)
	for c in cracks:
		_visuals.add_child(Defense.crack(c))
	_visuals.visible = false
	_refresh_board()


func running() -> bool:
	return state in [State.CONTAGEM, State.ONDA, State.INTERVALO]


func hud_text() -> String:
	match state:
		State.CONTAGEM:
			return "Festa sem fim: lá vêm eles!"
		State.ONDA:
			return "Festa sem fim  ·  onda %d  ·  faltam %d" % [wave, remaining]
		State.INTERVALO:
			return "Onda %d vencida!  Próxima em %d" % [wave, ceili(_timer)]
	return ""


func objective_text() -> String:
	return "Festa sem fim: aguente a onda %d" % maxi(wave, 1)


func _refresh_board() -> void:
	if running():
		_board.text = "FESTA SEM FIM\nOnda %d" % maxi(wave, 1)
	else:
		var best: int = story.records.festa
		_board.text = "FESTA SEM FIM\nFique no círculo para começar\nRecorde: %d %s" % [best, "onda" if best == 1 else "ondas"]
	_ring.visible = not running()
	_visuals.visible = running()


func _speed() -> float:
	return 0.15 if fast else 1.0


func _physics_process(delta: float) -> void:
	if story.stage != "fim" or not is_instance_valid(game.player):
		return
	var player: Player = game.player
	var flat := Vector2(player.global_position.x - center.x, player.global_position.z - center.z).length()
	if running() and (player.dizzy or flat > LEASH):
		_finish(player.dizzy)
		return
	_timer -= delta
	match state:
		State.PARADA:
			_hold = _hold + delta if flat < START_RADIUS and not player.dizzy else 0.0
			if _hold >= START_HOLD:
				_hold = 0.0
				_begin()
		State.CONTAGEM:
			if _timer <= 0.0:
				_next_wave()
		State.ONDA:
			if not _to_spawn.is_empty() and _timer <= 0.0 and alive.size() < MAX_AT_ONCE:
				_spawn(_to_spawn.pop_front())
				_timer = SPAWN_GAP * _speed()
			elif _to_spawn.is_empty() and remaining <= 0:
				_wave_done()
		State.INTERVALO:
			if _timer <= 0.0:
				_next_wave()
		State.FIM:
			if _timer <= 0.0:
				state = State.PARADA
				_refresh_board()


func _begin() -> void:
	state = State.CONTAGEM
	wave = 0
	cleared = 0
	_best_before = story.records.festa
	_timer = COUNTDOWN * _speed()
	game.banner("Festa sem fim!", "É brincadeira, mas vale de verdade: aguente quantas ondas conseguir!", Color("#ffd23f"), 2.8)
	Sfx.play(game, "alerta", 2.0, 0.0)
	if is_instance_valid(host):
		host.say("Valendo!", 2.0)
		host.crowd = true
	_refresh_board()
	story._refresh_objective()


func _next_wave() -> void:
	wave += 1
	state = State.ONDA
	_to_spawn = wave_list(wave)
	remaining = _to_spawn.size()
	_timer = 0.0
	if wave % 5 == 0:
		_spawn_guardian()
	if wave > 1:
		game.banner("Onda %d!" % wave, "Vem guardião!" if wave % 5 == 0 else "", Color("#ffd23f"), 1.4)
	_refresh_board()
	story._refresh_objective()


## Esqueletos da onda n: mais a cada onda (até 14), com Rogue a partir da 2ª, Pistoleiro e Mage da 3ª, Lobinho
## e Warrior da 4ª, Conde da 5ª e um grandão a cada 3 ondas a partir da 6ª (Golem de Ossos, Grandalhão e Golem
## de Gelo, revezando). Onda de guardião vem com metade.
static func wave_list(n: int) -> Array[String]:
	var count := mini(3 + n, 14)
	if n % 5 == 0:
		count = maxi(count / 2, 2)
	var list: Array[String] = []
	for k in count:
		if n >= 5 and k % 7 == 5:
			list.append("Conde")
		elif n >= 4 and k % 4 == 3:
			list.append("Skeleton_Warrior" if k % 8 == 3 else "Lobinho")
		elif n >= 3 and k % 5 == 2:
			list.append("Skeleton_Mage")
		elif n >= 3 and k % 6 == 4:
			list.append("Skeleton_Pistoleiro")
		elif n >= 2 and k % 3 == 1:
			list.append("Skeleton_Rogue")
		else:
			list.append("Skeleton_Minion")
	if n >= 6 and n % 3 == 0:
		var big := ["Skeleton_Golem", "Grandalhao", "GolemDeGelo"]
		for k in mini(n / 6, 3):
			list.append(big[(n / 3 + k) % big.size()])
	list.shuffle()
	return list


## Moedas por onda vencida (o guardião dá mais 30).
static func wave_coins(n: int) -> int:
	return 5 + 2 * n + (30 if n % 5 == 0 else 0)


func _spawn(type_name: String) -> void:
	var at: Vector3 = cracks[_crack_i % cracks.size()] if not cracks.is_empty() else center
	_crack_i += 1
	var e: SkeletonEnemy = game.spawn_wave_enemy(type_name, at)
	_track(e)


func _track(e: Node3D) -> void:
	alive.append(e)
	e.defeated.connect(_on_defeated)
	e.tree_exiting.connect(func() -> void: alive.erase(e))


func _spawn_guardian() -> void:
	var cycle := (wave / 5 - 1) / GUARDIANS.size()
	var key: String = GUARDIANS[(wave / 5 - 1) % GUARDIANS.size()]
	boss = Story.GUARDIANS[key].new()
	boss.arena_center = center
	boss.arena_radius = radius * 0.7
	boss.defeated.connect(_on_defeated)
	boss.summon_requested.connect(func(type_name: String, pos: Vector3) -> void:
		remaining += 1
		_track(game.spawn_wave_enemy(type_name, pos)))
	# O Guerreiro Planta não vai de balão: depois de aplaudir, afunda de volta.
	boss.gone.connect(func(b: Boss) -> void:
		game.hide_guardian()
		if b is BossPlanta:
			get_tree().create_timer(2.5, false).timeout.connect(func() -> void:
				if is_instance_valid(b):
					b.queue_free()))
	game.add_boss(boss, center)
	# Cada volta pelos cinco guardiões, eles voltam 30% mais fortes.
	boss.max_health *= 1.0 + 0.3 * cycle
	boss.health = boss.max_health
	boss.health_changed.emit(boss)
	remaining += 1
	game.show_guardian(boss)


## Derrotado sai da lista na hora (o balão ainda leva uns segundos para sumir).
func _on_defeated(_who: Node) -> void:
	alive.erase(_who)
	remaining = maxi(remaining - 1, 0)
	if _who == boss:
		get_tree().create_timer(1.5, false).timeout.connect(game.hide_guardian)


func _wave_done() -> void:
	cleared = wave
	state = State.INTERVALO
	_timer = BREAK_TIME * _speed()
	var coins := wave_coins(wave)
	story.add_coins(coins, center + Vector3.UP * 3.0)
	var crate := AmmoPickup.new()
	crate.dropped = true
	game.add_child(crate)
	crate.global_position = center + Vector3(1.5, 0.3, 0)
	var heart := HeartPickup.new()
	game.add_child(heart)
	heart.global_position = center + Vector3(-1.5, 0.3, 0)
	Sfx.play(game, "bandeira", -4.0, 0.0)
	if wave > story.records.festa:
		story.records.festa = wave
	_refresh_board()


## Fim da festa (tonto ou longe): os esqueletos afundam, o recorde fica salvo.
func _finish(dizzy: bool) -> void:
	for e in alive.duplicate():
		if is_instance_valid(e) and e.has_method("sink_away"):
			e.sink_away()
	alive.clear()
	_to_spawn.clear()
	if is_instance_valid(boss) and boss.is_fighting():
		boss.sink_away()
	game.hide_guardian()
	boss = null
	remaining = 0
	state = State.FIM
	_timer = 3.0 * _speed()
	var record := cleared > _best_before
	game.banner("Fim da Festa sem fim!", "Você aguentou %d %s.%s" % [cleared, "onda" if cleared == 1 else "ondas",
		" Novo recorde!" if record else " Recorde: %d." % story.records.festa] if dizzy else "Você saiu do cemitério e a festa parou.",
		Color("#ffd23f"), 3.4)
	if is_instance_valid(host):
		host.crowd = false
		host.say("Revanche quando quiser!", 3.0)
	_refresh_board()
	story._refresh_objective()
	story.save()
