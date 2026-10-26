class_name PartyDefense
extends Node3D
## "Defender a festa" (pós-jogo, seção 4 do doc): a brincadeira que o Mestre Ossinho propõe na praia do
## cais. Cinco enfeites ficam em pódios no meio; ficar uns instantes no círculo começa. A cada onda, os
## esqueletos (agora amigos, sem atacar) saem das rachaduras, pegam um enfeite e correm de volta. Derrubar
## quem carrega devolve o enfeite ao pódio; quem chega na rachadura leva o enfeite embora. Quando os cinco
## forem levados, a brincadeira acaba. O recorde é o número de ondas vencidas (fica salvo na campanha).

const FESTA := "res://assets/props/festa/%s.gltf"
const PRESENTS := ["doces/present_A_red", "doces/present_B_blue", "doces/present_C_yellow", "doces/present_D_green",
	"doces/present_sphere_A_green"]
const RING := 4.0
const START_RADIUS := 2.2
const START_HOLD := 1.0
## Longe assim do círculo, a brincadeira é cancelada.
const LEAVE_RADIUS := 70.0
const BREAK_TIME := 3.5
const SPAWN_GAP := 0.7

enum State { PARADA, CONTAGEM, ONDA, INTERVALO, FIM }

var game: Node
var story: Story
var center := Vector3.ZERO
var cracks: Array[Vector3] = []
var fast := false
## O Mestre Ossinho, que chama para a brincadeira e torce durante as ondas.
var host: Townsperson
var state := State.PARADA
var wave := 0
var cleared := 0
var thieves: Array[SkeletonEnemy] = []
## Um por pódio: {casa (onde o enfeite fica), enfeite (nó), estado ("podio", "levando", "voltando",
## "perdido"), ladrao}.
var slots: Array[Dictionary] = []

var _timer := 0.0
var _hold := 0.0
var _to_spawn: Array[String] = []
var _board: Label3D
var _ring: MeshInstance3D


func _ready() -> void:
	_ring = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = START_RADIUS
	disc.bottom_radius = START_RADIUS
	disc.height = 0.04
	var mat := Fx.flat_material(Color(1.0, 0.82, 0.25, 0.45))
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc.material = mat
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
	_board.global_position = _ring.global_position + Vector3.UP * 4.2
	for k in PRESENTS.size():
		var a := TAU * k / PRESENTS.size() + PI / 2.0
		var base: Vector3 = game._ground_point(center + Vector3(cos(a), 0, sin(a)) * RING)
		var podium: Node3D = load(FESTA % "circo/circus_podium").instantiate()
		podium.scale = Vector3.ONE * 0.55
		add_child(podium)
		podium.global_position = base
		var home := Vector3(base.x, _top_y(podium, base.y + 0.6), base.z)
		slots.append({"casa": home, "enfeite": null, "estado": "perdido", "ladrao": null})
	_reset_presents()
	if cracks.is_empty():
		for k in 6:
			var a := TAU * k / 6.0
			cracks.append(game._ground_point(center + Vector3(cos(a), 0, sin(a)) * 16.0))
	_refresh_board()


func _top_y(node: Node3D, fallback: float) -> float:
	var top := -INF
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		top = maxf(top, (m.global_transform * m.get_aabb()).end.y)
	return top if top > -INF else fallback


func _reset_presents() -> void:
	for k in slots.size():
		var slot: Dictionary = slots[k]
		if is_instance_valid(slot.enfeite):
			slot.enfeite.queue_free()
		var present: Node3D = load(FESTA % PRESENTS[k]).instantiate()
		present.scale = Vector3.ONE * 1.3
		add_child(present)
		present.global_position = slot.casa
		slot.enfeite = present
		slot.estado = "podio"
		slot.ladrao = null


func running() -> bool:
	return state in [State.CONTAGEM, State.ONDA, State.INTERVALO]


func left_count() -> int:
	return slots.filter(func(s: Dictionary) -> bool: return s.estado != "perdido").size()


func hud_text() -> String:
	return "Defender a festa · onda %d · enfeites: %d de 5" % [maxi(wave, 1), left_count()]


func objective_text() -> String:
	return "Defenda os enfeites: %d de 5 (onda %d)" % [left_count(), maxi(wave, 1)]


func _refresh_board() -> void:
	if running():
		_board.text = "ONDA %d\nEnfeites: %d de 5" % [maxi(wave, 1), left_count()]
	else:
		_board.text = "DEFENDER A FESTA\nFique no círculo para começar\nRecorde: %d %s" % [story.records.festa,
			"onda" if story.records.festa == 1 else "ondas"]
	_ring.visible = not running()


func _physics_process(delta: float) -> void:
	if story.stage != "fim" or not is_instance_valid(game.player):
		return
	var player: Player = game.player
	var flat := Vector2(player.global_position.x - center.x, player.global_position.z - center.z).length()
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
			if not _to_spawn.is_empty() and _timer <= 0.0:
				_spawn_thief(_to_spawn.pop_front())
				_timer = SPAWN_GAP * (0.5 if fast else 1.0)
			elif _to_spawn.is_empty() and thieves.is_empty():
				cleared += 1
				state = State.INTERVALO
				_timer = BREAK_TIME * (0.3 if fast else 1.0)
				game.banner("Onda %d vencida!" % wave, "Ainda tem %d enfeites na festa." % left_count(), Color("#c9f7a0"), 2.0)
				_refresh_board()
		State.INTERVALO:
			if _timer <= 0.0:
				_next_wave()
		State.FIM:
			if _timer <= 0.0:
				state = State.PARADA
				_reset_presents()
				_refresh_board()
	if running() and flat > LEAVE_RADIUS:
		_cancel()


func _begin() -> void:
	state = State.CONTAGEM
	wave = 0
	cleared = 0
	_timer = 2.0 * (0.3 if fast else 1.0)
	game.banner("Defender a festa!", "Os esqueletos vão tentar levar os enfeites. Derrube quem estiver carregando um!", Color("#ffd23f"), 2.6)
	if is_instance_valid(host):
		host.say("Valendo!", 2.0)
		host.crowd = true
	_refresh_board()
	story._refresh_objective()


func _next_wave() -> void:
	wave += 1
	state = State.ONDA
	_to_spawn = _wave_list(wave)
	_timer = 0.0
	if wave > 1:
		game.banner("Onda %d!" % wave, "", Color("#ffd23f"), 1.4)
	_refresh_board()


## Mais esqueletos a cada onda; da terceira em diante vem guerreiro de escudo, da quinta um Golem.
func _wave_list(n: int) -> Array[String]:
	var list: Array[String] = []
	for k in mini(2 + n, 9):
		if n >= 5 and k == 0:
			list.append("Skeleton_Golem")
		elif n >= 3 and k % 3 == 1:
			list.append("Skeleton_Warrior")
		else:
			list.append("Skeleton_Minion")
	return list


func _spawn_thief(type_name: String) -> void:
	var at: Vector3 = cracks[randi() % cracks.size()]
	var e: SkeletonEnemy = game.spawn_wave_enemy(type_name, at)
	e.thief = self
	e.set_meta("saida", at)
	e.set_meta("ladrao", true)
	e.defeated.connect(_on_thief_defeated)
	e.tree_exiting.connect(func() -> void: thieves.erase(e))
	thieves.append(e)
	Fx.dust(game, at + Vector3.UP * 0.3)


func speed_factor(e: SkeletonEnemy) -> float:
	var f := minf(1.0 + 0.06 * (wave - 1), 1.5)
	if _slot_of(e).size() > 0:
		f *= 0.85
	return f * (2.0 if fast else 1.0)


func _slot_of(e: SkeletonEnemy) -> Dictionary:
	for s in slots:
		if s.ladrao == e and s.estado == "levando":
			return s
	return {}


## Para onde o esqueleto anda: com enfeite, de volta para a rachadura; sem, para o enfeite mais perto.
func goal_for(e: SkeletonEnemy) -> Vector3:
	if _slot_of(e).size() > 0:
		return e.get_meta("saida")
	var best: Vector3 = e.get_meta("saida")
	var best_d := INF
	for s in slots:
		if s.estado == "podio":
			var d: float = e.global_position.distance_to(s.casa)
			if d < best_d:
				best_d = d
				best = s.casa
	return best


func arrived(e: SkeletonEnemy) -> void:
	var carried := _slot_of(e)
	if carried.size() > 0:
		_lose(carried, e)
		return
	for s in slots:
		if s.estado == "podio" and Vector2(e.global_position.x - s.casa.x, e.global_position.z - s.casa.z).length() < 1.6:
			_pick(s, e)
			return
	# Chegou na rachadura sem enfeite nenhum para pegar: vai embora.
	var exit_at: Vector3 = e.get_meta("saida")
	if e.global_position.distance_to(exit_at) < 1.6 and slots.all(func(s: Dictionary) -> bool: return s.estado != "podio"):
		thieves.erase(e)
		e.sink_away()


func _pick(s: Dictionary, e: SkeletonEnemy) -> void:
	s.estado = "levando"
	s.ladrao = e
	var present: Node3D = s.enfeite
	present.reparent(e)
	present.position = Vector3(0, 2.5 * (1.7 if e.type_name == "Skeleton_Golem" else 1.0), 0)
	# Foge para a rachadura mais perto.
	var best: Vector3 = cracks[0]
	for c in cracks:
		if c.distance_to(e.global_position) < best.distance_to(e.global_position):
			best = c
	e.set_meta("saida", best)
	Fx.popup_text(game, e.global_position + Vector3.UP * 3.2, "Peguei!", Color("#ffd6f3"))
	Sfx.play_at(game, "alerta", e.global_position + Vector3.UP * 2.0, -4.0)
	_refresh_board()


## Derrubado com o enfeite: o enfeite volta pulando para o pódio.
func _on_thief_defeated(e: SkeletonEnemy) -> void:
	thieves.erase(e)
	var s := _slot_of(e)
	if s.is_empty():
		return
	s.estado = "voltando"
	s.ladrao = null
	var present: Node3D = s.enfeite
	present.reparent(self)
	var from := present.global_position
	var to: Vector3 = s.casa
	var arc := func(t: float) -> void:
		present.global_position = from.lerp(to, t) + Vector3.UP * sin(PI * t) * 2.0
	var tw := present.create_tween()
	tw.tween_method(arc, 0.0, 1.0, 0.8)
	tw.tween_callback(func() -> void:
		if s.estado == "voltando":
			s.estado = "podio"
		Fx.confetti(game, to + Vector3.UP * 0.5, 16, 2.5))
	Fx.popup_text(game, from + Vector3.UP * 0.6, "Salvou!", Color("#c9f7a0"))
	Sfx.play(game, "ui_ok", 0.0, 0.0)


## Chegou na rachadura com o enfeite: leva embora (some no chão junto com ele).
func _lose(s: Dictionary, e: SkeletonEnemy) -> void:
	s.estado = "perdido"
	s.ladrao = null
	s.enfeite = null
	thieves.erase(e)
	Fx.popup_text(game, e.global_position + Vector3.UP * 3.2, "Levou!", Color("#ff9d9d"))
	e.sink_away()
	_refresh_board()
	story._refresh_objective()
	if left_count() == 0:
		_finish()


func _finish() -> void:
	state = State.FIM
	_timer = 3.0 * (0.3 if fast else 1.0)
	for e in thieves.duplicate():
		if is_instance_valid(e):
			e.sink_away()
	thieves.clear()
	_to_spawn.clear()
	var record: bool = cleared > story.records.festa
	if record:
		story.records.festa = cleared
	game.banner("Fim da brincadeira!", "Você defendeu a festa por %d %s.%s" % [cleared, "onda" if cleared == 1 else "ondas",
		" Novo recorde!" if record else " Recorde: %d." % story.records.festa], Color("#ffd23f"), 3.4)
	if is_instance_valid(host):
		host.crowd = false
		host.say("Revanche quando quiser!", 3.0)
	_refresh_board()
	story._refresh_objective()
	story.save()


func _cancel() -> void:
	for e in thieves.duplicate():
		if is_instance_valid(e):
			e.sink_away()
	thieves.clear()
	_to_spawn.clear()
	state = State.PARADA
	_reset_presents()
	if is_instance_valid(host):
		host.crowd = false
	game.show_message("A brincadeira foi cancelada: você saiu da praia", Color(1, 1, 1, 0.9), 2.0)
	_refresh_board()
	story._refresh_objective()
