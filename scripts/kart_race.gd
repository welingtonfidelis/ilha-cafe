class_name KartRace
extends Node3D
## Box da pista de kart, a leste do Morro (pedidos do usuário em 2026-10-26). Os veículos ficam estacionados
## nas vagas do box, vazios: chegar perto de um e apertar B (ou E) entra e já sai dirigindo (sem contagem).
## Dá para passear pela ilha inteira com ele. A corrida começa quando o veículo entra na pista pela abertura
## marcada "LARGADA" (a reta oeste, de frente para o box), vindo de fora da pista: o carro é posto na largada,
## contagem 3, 2, 1, "Já!" e três voltas contra o relógio (cada volta só vale passando pelas três marcas do
## meio das retas). Na chegada mostra o tempo, guarda o recorde e dá moedas (15, mais 10 com recorde novo).
## Descer (B ou E): dentro da pista, o aventureiro vai para fora dela e o veículo volta para a vaga; fora da
## pista, o veículo fica onde parou e volta sozinho para a vaga quando o aventureiro se afasta 50 m. Cair no
## mar também manda o veículo de volta. Dirigindo, os esqueletos atacam do mesmo jeito: cada golpe tira um
## coração e dá um tranco no veículo; sem corações, o aventureiro fica tonto, desce e o veículo volta para a
## vaga.

const LAPS := 3
const GATE_RADIUS := 7.0
const COINS := 15
const RECORD_BONUS := 10
## Distância para entrar num veículo estacionado.
const ENTER_RADIUS := 3.4
## Longe assim do veículo deixado pela ilha, ele volta para a vaga.
const RETURN_DISTANCE := 50.0
const SEA_LEVEL := -0.6
## A pista (igual a KART, KART_TILE, KART_W, KART_L e KART_ENTRY de tools/gerar_ilha.gd): oval de 6 x 10
## pedaços de 8 m; a entrada é o pedaço 6 da reta oeste.
const CENTER := Vector2(125, 15)
const TILE := 8.0
const W := 6
const L := 10
const ENTRY := 6
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
## Marcas na ordem da volta (meio da reta de cima, da direita, de baixo) e a linha de chegada.
var gates: Array[Vector3] = []
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
var _entry_zone := Rect2()


func _ready() -> void:
	var o := CENTER - Vector2(W, L) * TILE * 0.5
	for g in [Vector2(W * 0.5, 0.5), Vector2(W - 0.5, L * 0.5), Vector2(W * 0.5, L - 0.5), Vector2(0.5, 5.5)]:
		var p: Vector2 = o + g * TILE
		gates.append(Vector3(p.x, 0, p.y))
	_entry_zone = Rect2(o + Vector2(0, ENTRY) * TILE, Vector2(TILE, TILE))
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
	var c := _entry_zone.get_center()
	var stripe := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(TILE - 0.6, 0.04, TILE - 0.6)
	box.material = Defense.glow(Color(1.0, 0.82, 0.25, 0.32))
	stripe.mesh = box
	stripe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(stripe)
	stripe.global_position = Vector3(c.x, 0.2, c.y)
	var sign := Label3D.new()
	sign.text = "LARGADA\nentre aqui para correr"
	sign.font_size = 80
	sign.outline_size = 14
	sign.modulate = Color("#ffd23f")
	sign.outline_modulate = Color(0.15, 0.08, 0.25)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.pixel_size = 0.008
	add_child(sign)
	sign.global_position = Vector3(c.x - TILE * 0.5, 3.2, c.y)


func running() -> bool:
	return state in ["contagem", "correndo"]


func driving() -> bool:
	return state != "a_pe"


## Dentro da pista (com a entrada), onde descer manda o veículo de volta para a vaga.
func on_track(p: Vector3) -> bool:
	var o := CENTER - Vector2(W, L) * TILE * 0.5
	return Rect2(o, Vector2(W, L) * TILE).grow(1.0).has_point(Vector2(p.x, p.z))


func hud_text() -> String:
	match state:
		"contagem":
			return "Prepare-se!"
		"correndo":
			var best: float = story.records.get("kart", 0.0)
			return "Volta %d de %d  ·  %s%s" % [mini(lap + 1, LAPS), LAPS, format_time(time), "  ·  recorde %s" % format_time(best) if best > 0.0 else ""]
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
		if v != kart and is_instance_valid(v) and not v.is_home():
			if v.global_position.distance_to(player.global_position) > RETURN_DISTANCE:
				Fx.confetti(game, v.global_position + Vector3.UP, 20, 3.0)
				v.go_home()
	match state:
		"a_pe":
			nearest = null
			if player.visible and not player.dizzy and not player.skating:
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
				if not on_track(p):
					_armed = true
				elif _armed and _entry_zone.has_point(Vector2(p.x, p.z)):
					_start_race()
			elif state == "contagem":
				_countdown(delta)
			else:
				time += delta
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
	game.show_message("3", Color("#ffd23f"), 0.7)
	Sfx.play(game, "alerta", 0.0, 0.0)
	game.banner("Corrida!", "%d voltas contra o relógio. Frente (ou RT) acelera, trás (ou LT) freia." % LAPS, Color("#ffd23f"), 2.6)


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
	if Vector2(p.x - gate.x, p.z - gate.z).length() > GATE_RADIUS:
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
	game.banner("Chegada!", "Tempo: %s.%s" % [format_time(time), " Novo recorde!" if record else " Recorde: %s." % format_time(best)],
		Color("#c9f7a0"), 3.4)
	story.add_coins(COINS + (RECORD_BONUS if record else 0), kart.global_position + Vector3.UP * 3.0)
	Fx.confetti(game, kart.global_position + Vector3.UP * 2.0, 60, 6.0)
	story.save()
