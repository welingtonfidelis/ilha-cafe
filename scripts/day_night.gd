class_name DayNight
extends Node3D
## Ciclo de dia e noite na ilha (pedido do usuário em 2026-10-29). Um dia inteiro leva 16 minutos:
##   amanhecer (~1 min), dia (~9 min), entardecer (~1 min) e uma noite curta (~3,5 min).
## A noite é clara o bastante para criança brincar: céu azul-escuro com estrelas, lua azulada, luz ambiente
## forte e os postes da cidade e da pista de kart acesos.
## O ciclo mistura as cores do céu, do mar no horizonte, da névoa e da luz ambiente entre os momentos do dia. O
## sol anda de leste a oeste e, à noite, a mesma luz vira a lua. Na troca, a luz quase apaga por um instante,
## para a sombra não pular.
## O ciclo para nas horas que a história já marca: a noite da festa e a abertura da Parte 2 (o Desfecho põe a
## noite ele mesmo), as cenas, o farol (a ilha fica parada lá dentro) e os testes. Depois da noite da festa, o
## ciclo recomeça de manhã. A hora fica no salvamento ("hora"). É um Node3D para os postes sumirem junto com a
## ilha quando o Faísca entra no farol.

## Duração de um dia inteiro, em segundos.
const DAY_LENGTH := 960.0
## Hora do ciclo (de 0 a 1) em que começa um jogo novo ou a manhã depois da festa: o meio da manhã.
const MORNING := 0.12
## Momentos do dia: [hora do ciclo, estado]. Entre dois momentos as cores se misturam.
const KEYS := [
	[0.00, "aurora"], [0.05, "dia"], [0.62, "dia"], [0.68, "entardecer"], [0.74, "noite"], [0.94, "noite"], [1.00, "aurora"],
]
const STATES := {
	"dia": {
		"top": Color("#4f9cf0"), "horizon": Color("#cfe8ff"), "ground_horizon": Color("#cfe8ff"), "sea": Color("#3f9fd8"),
		"fog": Color("#cfe8ff"), "ambient": Color("#cfe8ff"), "sky_light": 1.0, "ambient_energy": 0.9,
		"light": Color("#fff4e0"), "light_energy": 1.2, "stars": 0.0, "lamps": 0.0,
	},
	"entardecer": {
		"top": Color("#3b5aa8"), "horizon": Color("#ffb27a"), "ground_horizon": Color("#f3a77a"), "sea": Color("#3a6ea6"),
		"fog": Color("#f0b08a"), "ambient": Color("#d9a0b0"), "sky_light": 0.6, "ambient_energy": 0.85,
		"light": Color("#ffb070"), "light_energy": 0.7, "stars": 0.25, "lamps": 0.7,
	},
	"aurora": {
		"top": Color("#4a6cc0"), "horizon": Color("#ffcf9a"), "ground_horizon": Color("#f7c49a"), "sea": Color("#3f7fba"),
		"fog": Color("#f3cfae"), "ambient": Color("#e0b8c0"), "sky_light": 0.7, "ambient_energy": 0.85,
		"light": Color("#ffc890"), "light_energy": 0.6, "stars": 0.15, "lamps": 0.4,
	},
	"noite": {
		"top": Color("#0f1a4d"), "horizon": Color("#3d3f86"), "ground_horizon": Color("#3d3f86"), "sea": Color("#0c1a40"),
		"fog": Color("#262c66"), "ambient": Color("#7884c8"), "sky_light": 0.0, "ambient_energy": 0.8,
		"light": Color("#aab8ff"), "light_energy": 0.35, "stars": 0.95, "lamps": 1.0,
	},
}
## O sol fica acima do horizonte até esta hora; a lua vai daí até o fim do ciclo.
const SUNSET := 0.72
## De quanto em quanto tempo o céu é refeito (mudar as cores do céu refaz a luz dele; a cada quadro pesa à toa).
const STEP := 0.25

var game: Node
## Hora do ciclo, de 0 a 1 (0 é o sol nascendo).
var t := MORNING
## Liga o andar das horas (os testes e as fotos deixam parado, no meio da manhã).
var running := true
## Os testes adiantam o relógio com isto (1 = normal).
var speed := 1.0
var _lamps: Array[OmniLight3D] = []
var _held := false
var _wait := 0.0
var _stars: Texture2D


func setup(p_game: Node) -> void:
	game = p_game
	_stars = stars_texture()
	var sky: ProceduralSkyMaterial = game.sky_material
	sky.sky_cover = _stars
	(game.environment.sky as Sky).process_mode = Sky.PROCESS_MODE_INCREMENTAL
	_build_lamps()
	apply()


func _process(delta: float) -> void:
	if game == null:
		return
	# A noite da festa e a abertura da Parte 2 são do Desfecho: o ciclo espera e, depois, volta de manhã.
	var ending: Ending = game.ending
	var hold: bool = (ending != null and (ending.night or ending.busy())) or (game.parte2 != null and game.parte2.busy())
	if hold:
		if not _held:
			_held = true
			_set_lamps(0.0)
		return
	if _held:
		_held = false
		t = MORNING
		apply()
		return
	if running:
		t = fposmod(t + delta * speed / DAY_LENGTH, 1.0)
	_wait -= delta
	if _wait <= 0.0:
		_wait = STEP
		apply()


## Quanto é noite agora (0 de dia, 1 de noite), para quem quiser saber.
func nightness() -> float:
	return float(_state_at(t).lamps)


func is_night() -> bool:
	return nightness() > 0.8


## Põe as cores, a luz, as estrelas e os postes da hora `t`.
func apply() -> void:
	var s := _state_at(t)
	var env: Environment = game.environment
	var sky: ProceduralSkyMaterial = game.sky_material
	var sun: DirectionalLight3D = game.sun_light
	sky.sky_top_color = s.top
	sky.sky_horizon_color = s.horizon
	sky.ground_horizon_color = s.ground_horizon
	sky.ground_bottom_color = s.sea
	sky.sky_cover = _stars
	sky.sky_cover_modulate = Color(1, 1, 1, s.stars)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = s.ambient
	env.ambient_light_sky_contribution = s.sky_light
	env.ambient_light_energy = s.ambient_energy
	env.fog_light_color = s.fog
	env.glow_enabled = s.lamps > 0.3
	env.glow_intensity = 0.9
	env.glow_hdr_threshold = 0.9
	sun.light_color = s.light
	# O sol anda de leste a oeste num arco; depois a mesma luz é a lua, mais baixa e do outro lado. Perto da
	# troca a luz quase apaga, para a sombra não pular.
	var energy: float = s.light_energy
	if t < SUNSET:
		var d := t / SUNSET
		sun.rotation_degrees = Vector3(-(6.0 + 54.0 * sin(PI * d)), lerpf(-100.0, 80.0, d), 0)
	else:
		var m := (t - SUNSET) / (1.0 - SUNSET)
		sun.rotation_degrees = Vector3(-(12.0 + 30.0 * sin(PI * m)), lerpf(130.0, 230.0, m), 0)
	var to_switch := minf(absf(t - SUNSET), minf(t, 1.0 - t))
	energy *= clampf(to_switch / 0.015, 0.15, 1.0)
	sun.light_energy = energy
	sun.light_angular_distance = 2.0 if t >= SUNSET else 0.0
	_set_lamps(s.lamps)


## Mistura dos dois momentos do dia em volta de `at`.
func _state_at(at: float) -> Dictionary:
	for k in KEYS.size() - 1:
		var a: Array = KEYS[k]
		var b: Array = KEYS[k + 1]
		if at >= a[0] and at <= b[0]:
			var w := smoothstep(0.0, 1.0, (at - a[0]) / maxf(b[0] - a[0], 0.0001))
			return _mix(STATES[a[1]], STATES[b[1]], w)
	return STATES.dia


static func _mix(a: Dictionary, b: Dictionary, w: float) -> Dictionary:
	var out := {}
	for key in a:
		out[key] = a[key].lerp(b[key], w) if a[key] is Color else lerpf(a[key], b[key], w)
	return out


## Uma luz em cima de cada poste da cidade e de cada poste da pista de kart.
func _build_lamps() -> void:
	var island: Node = game.island
	if island == null:
		return
	var holders: Array[Node] = []
	var enfeites := island.get_node_or_null("Cidade/Enfeites")
	if enfeites:
		holders.append_array(enfeites.get_children().filter(func(n: Node) -> bool: return String(n.name).begins_with("streetlight")))
	var track := island.get_node_or_null("PistaDeKart")
	if track:
		holders.append_array(track.get_children().filter(func(n: Node) -> bool: return String(n.name).begins_with("light-curved")))
	for h in holders:
		if not h is Node3D:
			continue
		var l := OmniLight3D.new()
		l.light_color = Color("#ffd89a")
		l.omni_range = 14.0
		l.shadow_enabled = false
		l.visible = false
		add_child(l)
		l.global_position = _top_of(h as Node3D) - Vector3.UP * 0.6
		_lamps.append(l)


func _set_lamps(amount: float) -> void:
	var on := smoothstep(0.3, 0.8, amount)
	for l in _lamps:
		l.visible = on > 0.01
		l.light_energy = 1.6 * on


## Topo das malhas de um objeto do cenário (onde fica a lâmpada do poste).
static func _top_of(node: Node3D) -> Vector3:
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


static var _stars_cache: ImageTexture


## Estrelas pintadas na textura de cobertura do céu (panorama: o alto da imagem é o zênite). Também usada na
## noite da festa (Desfecho).
static func stars_texture() -> ImageTexture:
	if _stars_cache:
		return _stars_cache
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
	_stars_cache = ImageTexture.create_from_image(img)
	return _stars_cache
