extends SceneTree
## Fotos de estúdio do Faísca (o `Robo`): corpo inteiro, rosto de perto e cada expressão dos olhos de LED.
## Veio do tools/foto_robo.gd do projeto Faísca. Precisa de janela (não roda com --headless):
##   godot --path . -s tools/foto_faisca.gd -- --prefixo=depois
## Salva em tools/capturas/faisca/robo/<prefixo>_<vista>.png (o prefixo padrão é "foto").

const PASTA := "res://tools/capturas/faisca/robo/"
const TAMANHO := Vector2i(900, 990)

const VISTAS := [
	{"nome": "frente", "orto": true, "tamanho": 2.75, "pos": Vector3(0, 1.15, 8), "alvo": Vector3(0, 1.15, 0)},
	{"nome": "lado", "orto": true, "tamanho": 2.75, "pos": Vector3(-8, 1.15, 0), "alvo": Vector3(0, 1.15, 0)},
	{"nome": "costas", "orto": true, "tamanho": 2.75, "pos": Vector3(0, 1.15, -8), "alvo": Vector3(0, 1.15, 0)},
	{"nome": "tres_quartos", "orto": false, "pos": Vector3(2.2, 1.7, 3.9), "alvo": Vector3(0, 1.12, 0)},
	{"nome": "peito_de_lado", "orto": false, "pos": Vector3(-1.9, 1.05, 0.9), "alvo": Vector3(0, 0.95, 0.05)},
	{"nome": "costas_perto", "orto": false, "pos": Vector3(-1.1, 1.9, -3.2), "alvo": Vector3(0, 1.25, 0)},
	{"nome": "rosto", "orto": false, "pos": Vector3(0.9, 1.95, 2.7), "alvo": Vector3(0, 1.64, 0)},
	{"nome": "socando", "orto": false, "pos": Vector3(-1.9, 1.3, 2.6), "alvo": Vector3(0.0, 1.0, 0.4), "anim": "luta/Melee_Unarmed_Attack_Punch_A", "tempo": 0.55, "expressao": "bravo"},
	{"nome": "soco_esquerdo", "orto": false, "pos": Vector3(1.9, 1.3, 2.6), "alvo": Vector3(0.0, 1.0, 0.4), "anim": "luta/Soco_Esquerdo", "tempo": 0.55, "expressao": "bravo"},
	{"nome": "danca_1", "orto": false, "pos": Vector3(1.0, 1.5, 4.2), "alvo": Vector3(0, 1.05, 0), "anim": "geral/Idle_A", "tempo": 0.5, "danca": 0.05, "expressao": "feliz"},
	{"nome": "danca_2", "orto": false, "pos": Vector3(1.0, 1.5, 4.2), "alvo": Vector3(0, 1.05, 0), "anim": "geral/Idle_A", "tempo": 0.5, "danca": 0.55, "expressao": "feliz"},
	{"nome": "correndo", "orto": false, "pos": Vector3(2.6, 1.4, 3.2), "alvo": Vector3(0, 1.0, 0), "anim": "mov/Running_A", "tempo": 0.2},
	{"nome": "parado", "orto": false, "pos": Vector3(1.4, 1.5, 3.9), "alvo": Vector3(0, 1.05, 0), "anim": "geral/Idle_A", "tempo": 0.5},
	{"nome": "comemorando", "orto": false, "pos": Vector3(1.6, 1.5, 4.3), "alvo": Vector3(0, 1.25, 0), "anim": "festa/Cheering", "tempo": 0.45, "expressao": "feliz"},
]
## Uma foto de perto para cada expressão (só se o Robo tiver expressões).
const EXPRESSOES := ["normal", "piscando", "feliz", "surpreso", "bravo", "dor", "tonto", "coracao"]

var _vistas: Array = []
var _robo: Robo
var _cam: Camera3D
var _prefixo := "foto"
var _q := 0


func _initialize() -> void:
	DisplayServer.window_set_size(TAMANHO)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--prefixo="):
			_prefixo = arg.get_slice("=", 1)
	_vistas = VISTAS.duplicate()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA))
	_montar_estudio()
	_robo = Robo.new()
	root.add_child(_robo)
	_robo.set("rosto_parado", true)
	if _robo.has_method("expressao"):
		for e: String in EXPRESSOES:
			_vistas.append({"nome": "olhos_" + e, "orto": false, "pos": Vector3(0.5, 1.82, 2.3), "alvo": Vector3(0, 1.69, 0),
					"anim": "geral/Idle_A", "tempo": 0.0, "expressao": e})


func _process(_delta: float) -> bool:
	_q += 1
	if _q < 8:
		return false
	var k := (_q - 8) / 12
	var fase := (_q - 8) % 12
	if k >= _vistas.size():
		return true
	var v: Dictionary = _vistas[k]
	if fase == 0:
		_arrumar(v)
	elif fase == 11:
		var arquivo := ProjectSettings.globalize_path(PASTA + _prefixo + "_" + v.nome + ".png")
		root.get_texture().get_image().save_png(arquivo)
		print("foto: ", arquivo)
	return false


func _arrumar(v: Dictionary) -> void:
	if v.has("anim"):
		_robo.posar(v.anim, v.tempo)
	else:
		_robo.tpose()
	if _robo.has_method("expressao"):
		_robo.call("expressao", v.get("expressao", "normal"), 0.0, true)
	# Dancinha: liga e começa no instante pedido (a foto sai uns 0,18 s depois).
	if _robo.has_method("dancar"):
		_robo.call("dancar", v.has("danca"))
		_robo.set("_danca", 1.0 if v.has("danca") else 0.0)
		_robo.set("_danca_t", v.get("danca", 0.0))
	if v.orto:
		_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		_cam.size = v.tamanho
	else:
		_cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		_cam.fov = 36.0
	_cam.look_at_from_position(v.pos, v.alvo, Vector3.UP)


## Estúdio parecido com as artes do KayKit: fundo lilás, luz principal suave com sombra,
## preenchimento do outro lado e uma luz de recorte por trás.
func _montar_estudio() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("a99be2")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dcd5ff")
	env.ambient_light_energy = 0.45
	env.tonemap_exposure = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	env.ssao_radius = 0.5
	env.ssao_intensity = 1.5
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_hdr_threshold = 1.3
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)

	var chave := DirectionalLight3D.new()
	chave.rotation_degrees = Vector3(-45, -30, 0)
	chave.light_energy = 1.0
	chave.shadow_enabled = true
	chave.light_angular_distance = 3.0
	root.add_child(chave)
	var preenche := DirectionalLight3D.new()
	preenche.rotation_degrees = Vector3(-20, 40, 0)
	preenche.light_energy = 0.35
	root.add_child(preenche)
	var recorte := DirectionalLight3D.new()
	recorte.rotation_degrees = Vector3(-30, 180, 0)
	recorte.light_energy = 0.6
	recorte.light_color = Color("e8f0ff")
	root.add_child(recorte)

	var chao := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(40, 40)
	chao.mesh = plano
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("a395de")
	m.roughness = 1.0
	chao.material_override = m
	root.add_child(chao)

	_cam = Camera3D.new()
	root.add_child(_cam)
	_cam.current = true
