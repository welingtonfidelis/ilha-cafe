class_name Defense
extends Node
## Defesa de uma região em ondas (seção 4 do doc). Entrar no círculo começa a defesa; os esqueletos
## saem das rachaduras e perseguem o aventureiro por toda a região. A onda só é cancelada se ele for
## muito longe (leash) ou ficar tonto: os esqueletos dela afundam de volta e a onda recomeça quando ele
## voltar ao círculo. Ondas vencidas continuam vencidas. Na última onda vem o guardião, se houver.

signal won(defense: Defense)
signal changed(defense: Defense)
signal guardian_spawned(defense: Defense, boss: Boss)
signal guardian_left(defense: Defense)

enum State { ESPERANDO, CHEGANDO, ONDA, INTERVALO, PAUSADA, VENCIDA }

const SPAWN_GAP := 0.8
const INTRO := 2.5
const INTERMISSION := 8.0
const LEASH := 90.0

var id := ""
var nome := ""
var center := Vector3.ZERO
var radius := 22.0
var cracks: Array[Vector3] = []
## Cada onda: lista de [tipo, quantidade].
var waves: Array = []
var guardian_script: Script
var game: Node
## Só começa depois que a história liberar a região.
var active := false
## Testes: intervalos curtos.
var fast := false

var state := State.ESPERANDO
var wave_index := 0
var remaining := 0
var guardian_health := -1.0
var boss: Boss
var alive: Array[Node3D] = []

var _to_spawn: Array[String] = []
var _timer := 0.0
var _crack_i := 0
var _visuals: Node3D


func activate() -> void:
	if active or state == State.VENCIDA:
		return
	active = true
	_build_visuals()


func total_waves() -> int:
	return waves.size()


func is_running() -> bool:
	return state in [State.CHEGANDO, State.ONDA, State.INTERVALO]


## Texto da tela durante a defesa ("" fora dela).
func hud_text() -> String:
	match state:
		State.CHEGANDO:
			return "Os esqueletos vêm aí!"
		State.ONDA:
			return "Onda %d de %d  ·  faltam %d" % [wave_index + 1, total_waves(), remaining]
		State.INTERVALO:
			return "Onda %d de %d vencida!  Próxima em %d" % [wave_index, total_waves(), ceili(_timer)]
	return ""


func _physics_process(delta: float) -> void:
	if not active or state == State.VENCIDA or not is_instance_valid(game.player):
		return
	var p: Player = game.player
	var d := Vector2(p.global_position.x - center.x, p.global_position.z - center.z).length()
	match state:
		State.ESPERANDO, State.PAUSADA:
			if d < radius and not p.dizzy and not p.in_vehicle and not p.parked:
				state = State.CHEGANDO
				_timer = INTRO * (0.2 if fast else 1.0)
				Sfx.play(game, "alerta", 2.0, 0.0)
				changed.emit(self)
		State.CHEGANDO:
			if p.dizzy or d > LEASH:
				_cancel()
				return
			_timer -= delta
			if _timer <= 0.0:
				_start_wave()
		State.ONDA:
			if p.dizzy or d > LEASH:
				_cancel()
				return
			_timer -= delta
			if not _to_spawn.is_empty() and _timer <= 0.0:
				_spawn_skeleton(_to_spawn.pop_front())
				_timer = SPAWN_GAP * (0.15 if fast else 1.0)
			if remaining <= 0 and _to_spawn.is_empty():
				_wave_done()
		State.INTERVALO:
			if p.dizzy or d > LEASH:
				state = State.PAUSADA
				changed.emit(self)
				return
			var before := ceili(_timer)
			_timer -= delta
			if ceili(_timer) != before:
				changed.emit(self)
			if _timer <= 0.0:
				_start_wave()


func _start_wave() -> void:
	state = State.ONDA
	_to_spawn.clear()
	for group in waves[wave_index]:
		for k in group[1]:
			_to_spawn.append(group[0])
	_to_spawn.shuffle()
	remaining = _to_spawn.size()
	_timer = 0.0
	var last := wave_index == waves.size() - 1
	# guardian_health 0 = o guardião já foi embora de balão (a onda foi cancelada depois disso).
	if last and guardian_script and guardian_health != 0.0:
		remaining += 1
		_spawn_guardian()
	changed.emit(self)


func _spawn_skeleton(type_name: String) -> void:
	var pos := cracks[_crack_i % cracks.size()] if not cracks.is_empty() else center
	_crack_i += 1
	_add_enemy(game.spawn_wave_enemy(type_name, pos))


func _add_enemy(e: SkeletonEnemy) -> void:
	alive.append(e)
	e.defeated.connect(_on_defeated)
	e.tree_exiting.connect(func() -> void: alive.erase(e))


func _spawn_guardian() -> void:
	boss = guardian_script.new()
	boss.start_health = guardian_health
	boss.arena_center = center
	boss.arena_radius = radius * 0.7
	boss.defeated.connect(_on_defeated)
	boss.summon_requested.connect(func(type_name: String, pos: Vector3) -> void:
		remaining += 1
		_add_enemy(game.spawn_wave_enemy(type_name, pos))
		changed.emit(self))
	boss.gone.connect(func(_b: Boss) -> void: guardian_left.emit(self))
	game.add_boss(boss, _guardian_spot())
	guardian_spawned.emit(self, boss)


## O guardião sobe a uns metros do centro, do lado do aventureiro: no centro fica o pilar da lanterna, e
## o corpo gigante nascia por dentro dele (o Minionzão empacava ali).
func _guardian_spot() -> Vector3:
	var away: Vector3 = game.player.global_position - center
	away.y = 0.0
	if away.length() < 0.5:
		away = Vector3.BACK
	var p: Vector3 = center + away.normalized() * minf(4.5, radius * 0.4)
	p.y = game.ground_y(p)
	return p


func _on_defeated(_who: Node) -> void:
	remaining = maxi(remaining - 1, 0)
	if _who == boss:
		guardian_health = 0.0
		# A barra do guardião sai logo depois da derrota, sem esperar o balão sumir no céu.
		get_tree().create_timer(1.5).timeout.connect(func() -> void: guardian_left.emit(self))
	changed.emit(self)


func _wave_done() -> void:
	wave_index += 1
	if wave_index >= waves.size():
		_win()
		return
	state = State.INTERVALO
	_timer = INTERMISSION * (0.15 if fast else 1.0)
	# Prêmio do intervalo no centro: munição e um coração.
	var crate := AmmoPickup.new()
	crate.dropped = true
	game.add_child(crate)
	crate.global_position = center + Vector3(1.5, 0, 0)
	var heart := HeartPickup.new()
	game.add_child(heart)
	heart.global_position = center + Vector3(-1.5, 0, 0)
	Sfx.play(game, "bandeira", -4.0, 0.0)
	changed.emit(self)


## Saiu para longe ou ficou tonto: a onda atual some (afunda) e recomeça depois.
func _cancel() -> void:
	for e in alive.duplicate():
		if is_instance_valid(e) and e.has_method("sink_away"):
			e.sink_away()
	alive.clear()
	_to_spawn.clear()
	if is_instance_valid(boss) and boss.is_fighting():
		guardian_health = boss.health
		boss.sink_away()
		guardian_left.emit(self)
	boss = null
	remaining = 0
	state = State.PAUSADA
	changed.emit(self)


func _win() -> void:
	state = State.VENCIDA
	active = false
	if is_instance_valid(_visuals):
		var tw := _visuals.create_tween()
		tw.tween_property(_visuals, "scale", Vector3(1, 0.01, 1), 0.8)
		tw.tween_callback(_visuals.queue_free)
	changed.emit(self)
	won.emit(self)


# --- rachaduras e anel da arena ----------------------------------------------

func _build_visuals() -> void:
	_visuals = Node3D.new()
	_visuals.name = "Defesa_" + id
	game.add_child(_visuals)
	var purple := Color("#b06cff")
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.25
	torus.outer_radius = radius
	torus.rings = 96
	torus.ring_segments = 4
	torus.material = glow(Color(purple, 0.7))
	ring.mesh = torus
	ring.scale = Vector3(1, 0.25, 1)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visuals.add_child(ring)
	ring.global_position = center + Vector3.UP * 0.1
	for c in cracks:
		_visuals.add_child(crack(c))


## Rachadura roxa no chão (de onde os esqueletos saem). Também usada na Festa sem fim.
static func crack(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.3
	cyl.bottom_radius = 1.3
	cyl.height = 0.06
	cyl.radial_segments = 10
	cyl.material = glow(Color(0.42, 0.18, 0.7, 0.9))
	disc.mesh = cyl
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(disc)
	# Rasgos claros cruzando a rachadura.
	for k in 3:
		var slit := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(2.2 - k * 0.4, 0.07, 0.16)
		box.material = glow(Color("#e2c4ff"))
		slit.mesh = box
		slit.rotation.y = k * 1.05
		slit.position.y = 0.02
		root.add_child(slit)
	var sparks := CPUParticles3D.new()
	sparks.amount = 14
	sparks.lifetime = 1.4
	sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = 1.0
	sparks.direction = Vector3.UP
	sparks.spread = 15.0
	sparks.gravity = Vector3.ZERO
	sparks.initial_velocity_min = 0.6
	sparks.initial_velocity_max = 1.4
	var dot := SphereMesh.new()
	dot.radius = 0.05
	dot.height = 0.1
	dot.material = glow(Color("#d9a8ff"))
	sparks.mesh = dot
	root.add_child(sparks)
	return root


static func glow(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = color
	return m
