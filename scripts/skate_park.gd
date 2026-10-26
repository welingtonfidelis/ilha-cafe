class_name SkatePark
extends Node3D
## Pista de skate (Mini Skate do Kenney, CC0; pedidos do usuário em 2026-10-26), ao lado da cidade, a
## noroeste. O skate fica no chão na entrada: chegar perto (ou estar dentro da pista com o skate lá) e apertar
## B (ou E) sobe nele, e dá para andar pela ilha inteira. Descer (B ou E) deixa o skate no chão onde parou;
## longe dele (50 m), ele volta sozinho para a entrada da pista. Cair no mar ou ficar tonto também manda o
## skate de volta.
## Sessão de pontos: passar de skate pela marca dourada "SESSÃO" dentro da pista começa 60 s em que cada pulo
## pousado vale pontos pelo tempo no ar e pelos giros (a cada meia volta); pousar atravessado é tombo
## ("Caiu!"), sem pontos. Sair de perto da pista cancela a sessão. No fim, o recorde fica salvo e os pontos
## viram moedas (1 a cada 100, até 25).

const SESSION := 60.0
const PICK_RADIUS := 3.0
const SESSION_RADIUS := 2.6
const LEAVE_RADIUS := 45.0
const RETURN_DISTANCE := 50.0
const MAX_COINS := 25
## Meio lado da pista (40 x 40 m).
const HALF := 21.0

var game: Node
var story: Story
var center := Vector3.ZERO
## Onde o skate fica guardado (na entrada da pista).
var entrance := Vector3.ZERO
## Marca da sessão de pontos, dentro da pista.
var session_spot := Vector3.ZERO
## a_pe, andando, sessao
var state := "a_pe"
var score := 0
var time_left := 0.0
var board: Node3D
var near := false
var _prompt: Label3D
var _armed := true


func _ready() -> void:
	_prompt = Label3D.new()
	_prompt.text = "PISTA DE SKATE\nPegue o skate com B (ou E)"
	_prompt.font_size = 96
	_prompt.outline_size = 14
	_prompt.modulate = Color("#ffd23f")
	_prompt.outline_modulate = Color(0.15, 0.08, 0.25)
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.pixel_size = 0.008
	add_child(_prompt)
	_prompt.global_position = entrance + Vector3.UP * 5.0
	board = load("res://assets/skate/skateboard.glb").instantiate()
	board.scale = Vector3.ONE * 1.5
	board.name = "SkateDaPista"
	add_child(board)
	_board_home()
	var mark := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = SESSION_RADIUS
	disc.bottom_radius = SESSION_RADIUS
	disc.height = 0.04
	disc.material = Defense.glow(Color(1.0, 0.82, 0.25, 0.5))
	mark.mesh = disc
	mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mark)
	mark.global_position = session_spot + Vector3.UP * 0.08
	var sign := Label3D.new()
	sign.text = "SESSÃO\npasse aqui de skate"
	sign.font_size = 64
	sign.outline_size = 12
	sign.modulate = Color("#ffd23f")
	sign.outline_modulate = Color(0.15, 0.08, 0.25)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.pixel_size = 0.008
	add_child(sign)
	sign.global_position = session_spot + Vector3.UP * 2.6
	var player: Player = game.player
	player.skate_landed.connect(_on_landed)
	player.dizzy_started.connect(func() -> void:
		if riding():
			_drop(true))


func running() -> bool:
	return state == "sessao"


func riding() -> bool:
	return state != "a_pe"


func board_at_home() -> bool:
	return board.visible and board.global_position.distance_to(entrance + Vector3(1.6, 0.05, 0)) < 0.5


func hud_text() -> String:
	match state:
		"sessao":
			return "Skate  ·  %d s  ·  %d pontos" % [ceili(time_left), score]
		"andando":
			return "Skate  ·  B (ou E): descer"
	return ""


func _board_home() -> void:
	board.visible = true
	board.global_position = entrance + Vector3(1.6, 0.05, 0)
	board.rotation_degrees = Vector3(0, 60.0, 0)


func _physics_process(delta: float) -> void:
	var player: Player = game.player
	if not is_instance_valid(player):
		return
	_prompt.visible = player.global_position.distance_to(entrance) < 120.0
	var flat := Vector2(player.global_position.x - center.x, player.global_position.z - center.z).length()
	match state:
		"a_pe":
			var inside := absf(player.global_position.x - center.x) < HALF and absf(player.global_position.z - center.z) < HALF
			near = board.visible and player.visible and not player.dizzy and not player.skating \
					and (player.global_position.distance_to(board.global_position) < PICK_RADIUS or (inside and board_at_home()))
			# Skate largado pela ilha: longe dele, volta para a entrada da pista.
			if board.visible and not board_at_home() and player.global_position.distance_to(board.global_position) > RETURN_DISTANCE:
				Fx.confetti(game, board.global_position + Vector3.UP, 16, 2.5)
				_board_home()
		"andando":
			near = false
			var on_mark := Vector2(player.global_position.x - session_spot.x, player.global_position.z - session_spot.z).length() < SESSION_RADIUS
			if on_mark and _armed:
				_start_session()
			elif not on_mark:
				_armed = true
		"sessao":
			near = false
			time_left -= delta
			if time_left <= 0.0:
				_finish()
			elif flat > LEAVE_RADIUS:
				state = "andando"
				game.show_message("Sessão cancelada: você saiu da pista", Color(1, 1, 1, 0.9), 1.6)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interagir") or game.menu_state != "":
		return
	if state == "a_pe" and near:
		pick()
		get_viewport().set_input_as_handled()
	elif state != "a_pe":
		_drop(false)
		get_viewport().set_input_as_handled()


## Sobe no skate (o do chão some e aparece debaixo dos pés).
func pick() -> void:
	var player: Player = game.player
	board.visible = false
	player.start_skating()
	game.crosshair.visible = false
	game.ammo_hud.visible = false
	state = "andando"
	near = false
	_armed = true
	game.show_message("Frente: impulso · A: pular · no ar, esquerda e direita giram", Color("#ffd23f"), 3.0)


## Desce do skate: ele fica no chão onde parou (ou volta para a entrada, se go_home).
func _drop(go_home: bool) -> void:
	var player: Player = game.player
	var where := player.global_position
	var heading := player._skate_heading
	player.stop_skating()
	game.crosshair.visible = true
	game.ammo_hud.visible = true
	if state == "sessao":
		game.show_message("Sessão cancelada", Color(1, 1, 1, 0.9), 1.4)
	state = "a_pe"
	if go_home:
		_board_home()
		return
	board.visible = true
	board.global_position = game._ground_point(where + Vector3(sin(heading + PI / 2.0), 0, cos(heading + PI / 2.0)) * 0.9) + Vector3.UP * 0.05
	board.rotation = Vector3(0, heading, 0)


## Caiu no mar de skate: desce e o skate volta para a pista.
func splash() -> void:
	if riding():
		_drop(true)


func _start_session() -> void:
	state = "sessao"
	_armed = false
	score = 0
	time_left = SESSION
	game.banner("Sessão de skate!", "60 segundos: pule nas rampas e gire no ar (esquerda e direita) para ganhar pontos.", Color("#ffd23f"), 3.0)


## Pontos do pulo: 200 por segundo no ar e 100 a cada meia volta. Pousar atravessado não vale.
static func trick_points(air_time: float, spin: float) -> int:
	return int(round(air_time * 200.0)) + int(floor(spin / PI + 0.15)) * 100


static func trick_name(spin: float) -> String:
	var halves := int(floor(spin / PI + 0.15))
	if halves <= 0:
		return "Pulo"
	return "Giro %d" % (halves * 180)


func _on_landed(air_time: float, spin: float, clean: bool) -> void:
	if state != "sessao":
		return
	var player: Player = game.player
	var at := player.global_position + Vector3.UP * 2.6
	if not clean:
		Fx.popup_text(game, at, "Caiu!", Color("#ff9d9d"))
		return
	var points := trick_points(air_time, spin)
	score += points
	Fx.popup_text(game, at, "+%d  %s" % [points, trick_name(spin)], Color("#ffd23f"))
	if points >= 300:
		Fx.confetti(game, at, 24, 3.0)
		Sfx.play(game, "ui_ok", 0.0, 0.0)


## Fim da sessão: recorde e moedas; continua andando (para outra sessão, passar de novo pela marca).
func _finish() -> void:
	state = "andando"
	_armed = false
	var best: int = int(story.records.get("skate", 0))
	var record := score > best
	if record:
		story.records["skate"] = score
	game.banner("Fim da sessão!", "%d pontos.%s" % [score, " Novo recorde!" if record else " Recorde: %d." % best], Color("#c9f7a0"), 3.4)
	var coins := mini(score / 100, MAX_COINS)
	if coins > 0:
		story.add_coins(coins, game.player.global_position + Vector3.UP * 3.0)
	story.save()
