class_name KartRace
extends Node3D
## Box da pista de kart, a leste do Morro (pedidos do usuário em 2026-10-26; a pista virou um 8 com ponte em
## 2026-10-29, scripts/kart_circuit.gd). Os veículos ficam estacionados nas vagas do box, vazios: chegar perto
## de um e apertar B (ou E) entra e já sai dirigindo (sem contagem). Dá para passear pela ilha inteira com ele.
## A corrida começa quando o veículo entra na pista pela abertura da mureta marcada "LARGADA" (na reta da
## largada, de frente para o box), vindo de fora da pista: o carro é posto na largada, contagem 3, 2, 1, "Já!"
## e três voltas contra o relógio (cada volta só vale passando pelo alto da volta norte, pela ponte e pelo
## fundo da volta sul). Na chegada mostra o tempo, guarda o recorde e dá moedas (15, mais 10 com recorde novo).
## Dois rivais correm junto (pedido do usuário em 2026-10-29, "pilotando com IA"): dois karts do box largam ao
## lado, com a outra criança e o Mago no banco, seguindo a linha do meio da pista cada um na sua faixa. São
## fantasmas (não batem em ninguém) e têm elástico: na frente do jogador aliviam um pouco, atrás apertam um
## pouco. A faixa de cima mostra a posição; chegar em 1º dá mais 5 moedas. Depois da chegada eles voltam para
## as vagas.
## Descer (B ou E): dentro da pista, o aventureiro vai para fora dela e o veículo volta para a vaga; fora da
## pista, o veículo fica onde parou e volta sozinho para a vaga quando o aventureiro se afasta 50 m. Cair no
## mar também manda o veículo de volta. Dirigindo, os esqueletos atacam do mesmo jeito: cada golpe tira um
## coração e dá um tranco no veículo; sem corações, o aventureiro fica tonto, desce e o veículo volta para a
## vaga.

const LAPS := 3
## As marcas valem em toda a largura da pista.
const GATE_RADIUS := 9.0
const COINS := 15
const RECORD_BONUS := 10
const WIN_BONUS := 5
## Rivais: quantos, quem vai no banco (além da outra criança), a velocidade máxima de cada um (o kart do jogador
## chega a 17 m/s), a faixa de cada um (metros para o lado da linha do meio) e quantas amostras (de 1 m) ele olha
## à frente para virar.
const RIVALS := 2
const RIVAL_PILOTS := ["res://assets/characters/adventurers/Mage.glb"]
const RIVAL_SPEEDS := [15.8, 16.5]
const RIVAL_LANES := [3.0, -3.0]
const RIVAL_LOOK := 11
## Distância para entrar num veículo estacionado.
const ENTER_RADIUS := 3.4
## Longe assim do veículo deixado pela ilha, ele volta para a vaga.
const RETURN_DISTANCE := 50.0
const SEA_LEVEL := -0.6
## piloto: onde o aventureiro senta (y é a altura do banco, onde fica a cintura); piloto_escala: tamanho dele.
const KART := {"modelo": "kart-oopi", "escala": 1.6, "piloto": Vector3(0, 0.42, -0.15), "piloto_escala": 0.75, "velocidade": 17.0}
## Um por vaga: [nome, modelo base, cor].
const GARAGE := [
	["Kart Morango", KART, Color("#ff7a7a")],
	["Kart Mirtilo", KART, Color("#7ab8ff")],
	["Kart Hortelã", KART, Color("#8affa0")],
	["Kart Uva", KART, Color("#c08aff")],
	["Kart Limão", KART, Color("#ffe066")],
]

var game: Node
var story: Story
## Para onde o aventureiro vai ao descer dentro da pista (no box, entre as vagas e a pista).
var paddock := Vector3.ZERO
var start := Transform3D.IDENTITY
## Vagas do box (marcadores "Vagas").
var spots: Array[Transform3D] = []
## Marcas na ordem da volta (alto da volta norte, ponte, fundo da volta sul) e a linha de chegada, na altura de
## projeto do asfalto (a da ponte só vale em cima dela).
var gates: Array[Vector3] = []
## Meio da abertura da mureta (a entrada da corrida), na pista.
var entry_center := Vector3.ZERO
## Para fora da pista, a partir da abertura (o lado do box).
var entry_out := Vector3.ZERO
var vehicles: Array[Kart] = []
## Veículo que o aventureiro está dirigindo (nulo a pé).
var kart: Kart
## a_pe, dirigindo, contagem, correndo
var state := "a_pe"
var lap := 0
var time := 0.0
var nearest: Kart
var _next_gate := 0
var _count := 0.0
var _armed := false
var _prompt: Label3D
## Rivais da corrida: {kart, i (amostra da pista), run (metros desde a largada), lane, speed, done, time, stuck}.
var rivals: Array[Dictionary] = []
## Posição do jogador na corrida (1 é o primeiro), contando os rivais.
var place := 1
## Progresso do jogador na pista, contado como o dos rivais.
var _player_i := 0
var _player_run := 0.0
## Depois da chegada, os rivais ainda andam um pouco antes de voltar para as vagas.
var _rivals_home_in := 0.0
## Quantas vezes um rival preso ou fora da pista voltou para o meio dela (os testes conferem).
var rival_resets := 0


func _ready() -> void:
	for k in KartCircuit.GATES:
		gates.append(KartCircuit.at_point(k).pos)
	gates.append(KartCircuit.from_start(0.0).pos)
	var e := KartCircuit.from_start(-(KartCircuit.ENTRY_FROM + KartCircuit.ENTRY_TO) * 0.5)
	entry_center = e.pos
	var left := Vector3(e.dir.z, 0, -e.dir.x)
	entry_out = left if (paddock - entry_center).dot(left) > 0.0 else -left
	for k in mini(spots.size(), GARAGE.size()):
		var spec: Array = GARAGE[k]
		var base: Dictionary = spec[1]
		var v := Kart.new()
		v.name = "Veiculo%d" % (k + 1)
		v.display_name = spec[0]
		v.model_name = base.modelo
		v.model_scale = base.escala
		v.tint = spec[2]
		v.driver_spot = base.piloto
		v.driver_scale = base.piloto_escala
		v.max_speed = base.velocidade
		v.home = spots[k]
		v.transform = spots[k]
		add_child(v)
		vehicles.append(v)
	_prompt = Label3D.new()
	_prompt.text = "PISTA DE KART\nChegue perto de um carrinho e aperte B (ou E)"
	_prompt.font_size = 96
	_prompt.outline_size = 14
	_prompt.modulate = Color("#ffd23f")
	_prompt.outline_modulate = Color(0.15, 0.08, 0.25)
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.pixel_size = 0.008
	add_child(_prompt)
	_prompt.global_position = paddock + Vector3(-6.0, 6.0, 4.0)
	_build_entry_mark()
	var player: Player = game.player
	player.damaged.connect(func() -> void:
		if driving() and is_instance_valid(kart):
			kart.jolt())
	player.dizzy_started.connect(func() -> void:
		if driving():
			leave(true))


## A abertura da pista: faixa dourada no asfalto e a placa "LARGADA" em cima.
func _build_entry_mark() -> void:
	var stripe := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(KartCircuit.WIDTH - 1.0, 0.04, KartCircuit.ENTRY_FROM - KartCircuit.ENTRY_TO)
	box.material = Defense.glow(Color(1.0, 0.82, 0.25, 0.32))
	stripe.mesh = box
	stripe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(stripe)
	stripe.global_position = entry_center + Vector3.UP * 0.06
	stripe.look_at(stripe.global_position + Vector3(entry_out.z, 0, -entry_out.x), Vector3.UP)
	var sign := Label3D.new()
	sign.text = "LARGADA\nentre aqui para correr"
	sign.font_size = 80
	sign.outline_size = 14
	sign.modulate = Color("#ffd23f")
	sign.outline_modulate = Color(0.15, 0.08, 0.25)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.pixel_size = 0.008
	add_child(sign)
	sign.global_position = entry_center + entry_out * (KartCircuit.WIDTH * 0.5 + 1.0) + Vector3.UP * 3.6


func running() -> bool:
	return state in ["contagem", "correndo"]


func driving() -> bool:
	return state != "a_pe"


## Dentro da pista (com a entrada), onde descer manda o veículo de volta para a vaga.
func on_track(p: Vector3) -> bool:
	return KartCircuit.on_track(p, 1.0)


## Na abertura da mureta, já em cima da pista.
func in_entry(p: Vector3) -> bool:
	return Vector2(p.x - entry_center.x, p.z - entry_center.z).length() < KartCircuit.WIDTH * 0.5

func hud_text() -> String:
	match state:
		"contagem":
			return "Prepare-se!"
		"correndo":
			var best: float = story.records.get("kart", 0.0)
			var where := "  ·  %dº de %d" % [place, rivals.size() + 1] if not rivals.is_empty() else ""
			return "Volta %d de %d  ·  %s%s%s" % [mini(lap + 1, LAPS), LAPS, format_time(time), where, "  ·  recorde %s" % format_time(best) if best > 0.0 else ""]
		"dirigindo":
			return "%s  ·  B (ou E): descer" % kart.display_name
	return ""


static func format_time(t: float) -> String:
	var tenths := int(round(t * 10.0))
	return "%d:%02d,%d" % [tenths / 600, (tenths / 10) % 60, tenths % 10]


func _physics_process(delta: float) -> void:
	var player: Player = game.player
	if not is_instance_valid(player):
		return
	_prompt.visible = player.global_position.distance_to(paddock) < 120.0 and state == "a_pe"
	# Veículo deixado pela ilha: longe dele, volta para a vaga.
	for v in vehicles:
		if v != kart and is_instance_valid(v) and not v.is_home() and not is_rival(v):
			if v.global_position.distance_to(player.global_position) > RETURN_DISTANCE:
				Fx.confetti(game, v.global_position + Vector3.UP, 20, 3.0)
				v.go_home()
	match state:
		"a_pe":
			nearest = null
			# O Faísca também dirige (a criança guardada sai vestida dele).
			if (player.visible or game.faisca_on_island()) and not player.dizzy:
				var best := ENTER_RADIUS
				for v in vehicles:
					var d := v.global_position.distance_to(player.global_position)
					if d < best:
						best = d
						nearest = v
		"dirigindo", "contagem", "correndo":
			# Um pouco acima do veículo: o "tchibum" do jogo (que olha o aventureiro) só vem depois que o
			# veículo afunda e ele desce.
			player.global_position = kart.global_position + Vector3.UP * 0.6
			player.ride_tick(delta)
			kart.show_driver(player.visual.visible)
			if kart.global_position.y < SEA_LEVEL - 0.9:
				# Caiu no mar: o veículo volta para a vaga e o aventureiro faz o "tchibum" de sempre.
				leave(true)
				return
			var p := kart.global_position
			if state == "dirigindo":
				# Depois da chegada, os rivais terminam a volta e vão para as vagas.
				if not rivals.is_empty():
					_drive_rivals(delta)
					_rivals_home_in -= delta
					if _rivals_home_in <= 0.0:
						_send_rivals_home()
				if not on_track(p):
					_armed = true
				elif _armed and in_entry(p):
					_start_race()
			elif state == "contagem":
				_countdown(delta)
			else:
				time += delta
				_track_player()
				_drive_rivals(delta)
				_check_gates()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interagir") or game.menu_state != "":
		return
	if state == "a_pe" and nearest:
		enter(nearest)
		get_viewport().set_input_as_handled()
	elif state != "a_pe":
		leave()
		get_viewport().set_input_as_handled()


## Entra no veículo e já sai dirigindo de onde ele está.
func enter(v: Kart) -> void:
	if game.faisca_on_island():
		game.parte2.vestir_crianca(true)
	kart = v
	nearest = null
	v.drive(game.player)
	v.input_enabled = true
	v.camera.make_current()
	game.enter_vehicle()
	state = "dirigindo"
	_armed = not on_track(v.global_position)
	game.show_message("%s! Entre na LARGADA para correr." % v.display_name, Color("#ffd23f"), 2.6)


## Desce do veículo. Na pista, o veículo volta para a vaga e o aventureiro fica fora da pista; pela ilha, o
## veículo fica onde parou. send_home (caiu no mar ou ficou tonto): o veículo volta para a vaga e o
## aventureiro fica ali mesmo.
func leave(send_home := false) -> void:
	_send_rivals_home()
	var v := kart
	kart = null
	if state in ["contagem", "correndo"] and not send_home:
		game.show_message("Corrida cancelada", Color(1, 1, 1, 0.9), 1.4)
	state = "a_pe"
	if not is_instance_valid(v):
		game.exit_vehicle(paddock + Vector3.UP * 0.5)
		return
	var where := v.global_position
	if send_home:
		v.go_home()
		game.exit_vehicle(where)
	elif on_track(where):
		v.go_home()
		game.exit_vehicle(paddock + Vector3.UP * 0.5)
	else:
		v.park()
		var side := v.global_basis.x.normalized()
		var spot: Vector3 = game._ground_point(where + side * 2.4)
		game.exit_vehicle(spot + Vector3.UP * 0.3)


func _start_race() -> void:
	state = "contagem"
	_armed = false
	kart.global_transform = start
	kart.speed = 0.0
	kart.velocity = Vector3.ZERO
	kart.input_enabled = false
	_count = 3.0
	lap = 0
	_next_gate = 0
	_place_rivals()
	_player_i = _nearest_index(kart.global_position)
	_player_run = 0.0
	place = 1
	game.show_message("3", Color("#ffd23f"), 0.7)
	Sfx.play(game, "alerta", 0.0, 0.0)
	game.banner("Corrida!", "%d voltas contra %d rivais. Frente (ou RT) acelera, trás (ou LT) freia." % [LAPS, rivals.size()] if not rivals.is_empty()
			else "%d voltas contra o relógio. Frente (ou RT) acelera, trás (ou LT) freia." % LAPS, Color("#ffd23f"), 2.6)


func _countdown(delta: float) -> void:
	var before := ceili(_count)
	_count -= delta
	if ceili(_count) != before and _count > 0.0:
		game.show_message(str(ceili(_count)), Color("#ffd23f"), 0.7)
		Sfx.play(game, "alerta", 0.0, 0.0)
	if _count <= 0.0:
		state = "correndo"
		kart.input_enabled = true
		time = 0.0
		game.show_message("Já!", Color("#c9f7a0"), 0.8)
		Sfx.play(game, "bandeira", 0.0, 0.0)


func _check_gates() -> void:
	var p := kart.global_position
	var gate: Vector3 = gates[_next_gate]
	# A ponte passa em cima do começo da reta: a marca dela só vale lá em cima.
	if Vector2(p.x - gate.x, p.z - gate.z).length() > GATE_RADIUS or absf(p.y - gate.y) > 3.0:
		return
	_next_gate += 1
	if _next_gate < gates.size():
		return
	_next_gate = 0
	lap += 1
	if lap < LAPS:
		game.show_message("Volta %d!" % (lap + 1) if lap < LAPS - 1 else "Última volta!", Color("#ffd23f"), 1.2)
		Sfx.play(game, "ui_ok", 0.0, 0.0)
		return
	_finish()


## Chegada: tempo, recorde e moedas; continua dirigindo (para correr de novo, sair e entrar pela LARGADA).
func _finish() -> void:
	state = "dirigindo"
	_armed = false
	var best: float = story.records.get("kart", 0.0)
	var record := best <= 0.0 or time < best
	if record:
		story.records["kart"] = time
	place = 1 + rivals.filter(func(r: Dictionary) -> bool: return r.done).size()
	var where := "%dº lugar! " % place if not rivals.is_empty() else ""
	game.banner("Chegada!", "%sTempo: %s.%s" % [where, format_time(time), " Novo recorde!" if record else " Recorde: %s." % format_time(best)],
		Color("#c9f7a0"), 3.4)
	var won := place == 1 and not rivals.is_empty()
	story.add_coins(COINS + (RECORD_BONUS if record else 0) + (WIN_BONUS if won else 0), kart.global_position + Vector3.UP * 3.0)
	_rivals_home_in = 4.0
	Fx.confetti(game, kart.global_position + Vector3.UP * 2.0, 60, 6.0)
	story.save()


# --- rivais ------------------------------------------------------------------

func is_rival(v: Kart) -> bool:
	return rivals.any(func(r: Dictionary) -> bool: return r.kart == v)


## Põe dois karts do box no grid, um de cada lado do jogador e um pouco atrás, com a outra criança e o Mago no
## banco. Eles esperam a contagem (sem acelerador) e saem no "Já!".
func _place_rivals() -> void:
	_send_rivals_home()
	var free := vehicles.filter(func(v: Kart) -> bool: return v != kart and v.is_home())
	var me: String = game.player.character_name
	var pilots: Array = [Player.CHARACTERS["menino" if me == "menina" else "menina"]] + RIVAL_PILOTS
	for k in mini(RIVALS, free.size()):
		var v: Kart = free[k]
		var xf := start
		xf.origin += start.basis.x.normalized() * 4.2 * (1.0 if k % 2 == 0 else -1.0) - start.basis.z.normalized() * 3.0
		v.global_transform = xf
		v.drive_ai(load(pilots[k % pilots.size()]).instantiate())
		v.max_speed = RIVAL_SPEEDS[k]
		rivals.append({"kart": v, "i": _nearest_index(xf.origin), "run": 0.0, "lane": RIVAL_LANES[k], "speed": RIVAL_SPEEDS[k],
				"done": false, "time": 0.0, "stuck": 0.0})


func _send_rivals_home() -> void:
	for r in rivals:
		var v: Kart = r.kart
		if is_instance_valid(v):
			Fx.confetti(game, v.global_position + Vector3.UP, 20, 3.0)
			v.go_home()
	rivals.clear()


## Cada rival olha um ponto da linha do meio uns metros à frente (deslocado para a faixa dele) e vira para lá;
## nas curvas fechadas tira o pé. Preso parado ou fora da pista, volta para o meio dela ali mesmo.
func _drive_rivals(delta: float) -> void:
	var samples := KartCircuit.samples()
	var n := samples.size()
	for r in rivals:
		var v: Kart = r.kart
		if not is_instance_valid(v):
			continue
		var p := v.global_position
		var near := _advance(r.i, p)
		r.i = near.i
		r.run += near.step
		var ahead: Dictionary = samples[(int(r.i) + RIVAL_LOOK) % n]
		var dir: Vector3 = ahead.dir
		var to: Vector3 = ahead.pos + Vector3(-dir.z, 0, dir.x) * float(r.lane) - p
		to.y = 0.0
		var fwd := v.forward()
		fwd.y = 0.0
		var angle := fwd.signed_angle_to(to, Vector3.UP)
		v.ai_steer = clampf(angle * 2.5, -1.0, 1.0)
		v.ai_throttle = 1.0 if absf(angle) < 0.6 else 0.5
		# Elástico: na frente do jogador alivia, atrás aperta (até 10% e 8%).
		v.max_speed = float(r.speed) * (1.0 + clampf((_player_run - float(r.run)) / 300.0, -0.1, 0.08))
		r.stuck = float(r.stuck) + delta if v.speed < 1.5 else 0.0
		if float(r.stuck) > 2.5 or p.y < SEA_LEVEL - 0.9 or float(near.dist) > KartCircuit.WIDTH:
			_reset_rival(r)
		if not r.done and float(r.run) >= LAPS * KartCircuit.length():
			r.done = true
			r.time = time
	if state == "correndo":
		place = 1 + rivals.filter(func(r: Dictionary) -> bool: return r.done or float(r.run) > _player_run).size()


## Rival preso ou fora da pista: volta para a faixa dele na amostra em que estava, de frente para a pista.
func _reset_rival(r: Dictionary) -> void:
	var v: Kart = r.kart
	var sm: Dictionary = KartCircuit.samples()[int(r.i)]
	var dir: Vector3 = sm.dir
	v.global_transform = Transform3D(Basis(Vector3.UP.cross(dir).normalized(), Vector3.UP, dir), sm.pos + Vector3(-dir.z, 0, dir.x) * float(r.lane)
			+ Vector3.UP * 0.6)
	v.speed = 0.0
	v.velocity = Vector3.ZERO
	r.stuck = 0.0
	rival_resets += 1


func _track_player() -> void:
	var near := _advance(_player_i, kart.global_position)
	_player_i = near.i
	_player_run += near.step


## A amostra da pista mais perto de `p` (no plano, com a altura desempatando).
static func _nearest_index(p: Vector3) -> int:
	var samples := KartCircuit.samples()
	var best := 0
	var best_d := INF
	for j in samples.size():
		var d: float = (samples[j].pos as Vector3).distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = j
	return best


## Anda a contagem de quem estava na amostra `i` e agora está em `p`: procura só um pouco atrás e à frente (no
## cruzamento do 8 valem as duas pistas). Devolve {i, step (metros andados), dist (até a linha do meio)}.
static func _advance(i: int, p: Vector3) -> Dictionary:
	var samples := KartCircuit.samples()
	var n := samples.size()
	var best := i
	var best_d := INF
	for k in range(-4, 26):
		var j := (i + k + n) % n
		var d := Vector2(samples[j].pos.x - p.x, samples[j].pos.z - p.z).length()
		if d < best_d:
			best_d = d
			best = j
	var step := (best - i + n) % n
	if step > n / 2:
		step -= n
	return {"i": best, "step": step * KartCircuit.length() / n, "dist": best_d}
