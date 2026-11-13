extends SceneTree
## Vitrine das partículas do Kenney Particle Pack (2026-11-13): em cada parada, o efeito de hoje à esquerda ("hoje") e o
## novo à direita ("novo", da classe Particulas), lado a lado, com a foto tirada no auge de cada um. Serve para o
## usuário escolher antes de trocar o confete nos jogos.
## Uso (precisa de janela): godot --path . -s res://tools/vitrine_particulas.gd
## Fotos em tools/capturas/particulas/.

const SAIDA := "res://tools/capturas/particulas/"

var _mundo: Node3D
var _cam: Camera3D
var _env: Environment
var _chao_mat: StandardMaterial3D
var _rotulos: Array[Node] = []


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA))
	_mundo = Node3D.new()
	root.add_child(_mundo)
	var ceu := ProceduralSkyMaterial.new()
	ceu.sky_top_color = Color("5fa4ff")
	ceu.sky_horizon_color = Color("cfe8ff")
	var sky := Sky.new()
	sky.sky_material = ceu
	var env := Environment.new()
	_env = env
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e2e0ee")
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_hdr_threshold = 1.3
	var we := WorldEnvironment.new()
	we.environment = env
	_mundo.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, -35, 0)
	sol.shadow_enabled = true
	_mundo.add_child(sol)
	var chao := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(300, 300)
	chao.mesh = plano
	_chao_mat = StandardMaterial3D.new()
	_chao_mat.albedo_color = Color("8fd36a")
	chao.material_override = _chao_mat
	_mundo.add_child(chao)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_mundo.add_child(_cam)
	_cam.make_current()
	_rodar.call_deferred()


func _rodar() -> void:
	await process_frame
	await process_frame
	var paradas := [
		["01_estrelinha", "Pegar estrelinha", 0.12, func(p: Vector3) -> void: Fx.confetti(_mundo, p, 24, 4.0), func(p: Vector3) -> void: Particulas.estrelinha(_mundo, p)],
		["02_bolota_estoura", "A Bolota estourando", 0.18, func(p: Vector3) -> void: Fx.confetti(_mundo, p, 30, 4.5), func(p: Vector3) -> void: Particulas.puf(_mundo, p)],
		["03_curto", "O curto do Faísca", 0.1, _fumacinha_de_hoje, func(p: Vector3) -> void: Particulas.curto(_mundo, p)],
		["04_soco", "O soco acertando", 0.08, func(p: Vector3) -> void: Fx.confetti(_mundo, p, 18, 3.0), func(p: Vector3) -> void: Particulas.soco(_mundo, p)],
		["05_poeira", "Poeira de pousar e correr", 0.15, func(p: Vector3) -> void: Fx.dust(_mundo, p + Vector3.DOWN * 0.8), func(p: Vector3) -> void: Particulas.poeira(_mundo, p + Vector3.DOWN * 0.8)],
		["06_magia", "Cápsula de poder e Faisquinha salvo", 0.3, func(p: Vector3) -> void: Fx.confetti(_mundo, p, 40, 4.0), func(p: Vector3) -> void: Particulas.magia(_mundo, p)],
		["07_coracao", "Coração pego", 0.35, func(p: Vector3) -> void: Fx.confetti(_mundo, p, 20, 3.0), func(p: Vector3) -> void: Particulas.coracoes(_mundo, p)],
		["08_redemoinho", "Vento: o giro, o vendaval e o aspirador", 0.2, func(_p: Vector3) -> void: pass, func(p: Vector3) -> void: Particulas.redemoinho(_mundo, p)],
		["09_blaster", "O tiro do blaster (Ilha Cafuné)", 0.03, _clarao_de_hoje, func(p: Vector3) -> void: Particulas.clarao(_mundo, p)],
	]
	# Cada parada duas vezes: de dia (o céu e a grama das fases) e no escuro (como a nave e a noite da ilha).
	for escuro in [false, true]:
		_env.background_mode = Environment.BG_COLOR if escuro else Environment.BG_SKY
		_env.background_color = Color("1c1534")
		_env.ambient_light_energy = 0.35 if escuro else 0.8
		_chao_mat.albedo_color = Color("3c2a6e") if escuro else Color("8fd36a")
		for i in paradas.size():
			var spec: Array = paradas[i]
			for r in _rotulos:
				r.queue_free()
			_rotulos.clear()
			var meio := Vector3(0, 1.6, 0)
			var hoje := meio + Vector3(-1.7, 0, 0)
			var novo := meio + Vector3(1.7, 0, 0)
			_rotulo(spec[1], meio + Vector3(0, 1.9, 0), 48)
			_rotulo("hoje", hoje + Vector3(0, -1.25, 0.6), 36)
			_rotulo("novo", novo + Vector3(0, -1.25, 0.6), 36)
			_cam.global_position = meio + Vector3(0, 0.4, 5.6)
			_cam.look_at(meio + Vector3(0, 0.2, 0))
			await create_timer(0.3).timeout
			(spec[3] as Callable).call(hoje)
			(spec[4] as Callable).call(novo)
			await create_timer(float(spec[2])).timeout
			await RenderingServer.frame_post_draw
			var nome: String = spec[0] + ("_escuro" if escuro else "_dia")
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(SAIDA + nome + ".png"))
			print("foto: ", nome)
			await create_timer(1.3).timeout
	quit()


func _rotulo(texto: String, pos: Vector3, tamanho: int) -> void:
	var l := Label3D.new()
	l.text = texto
	l.font_size = tamanho
	l.outline_size = 12
	l.pixel_size = 0.006
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pos
	_mundo.add_child(l)
	_rotulos.append(l)


## A fumacinha de hoje do curto (a mesma do Jogador): bolinhas cinza e faisquinhas amarelas saindo.
func _fumacinha_de_hoje(centro: Vector3) -> void:
	var fumaca := StandardMaterial3D.new()
	fumaca.albedo_color = Color(0.85, 0.85, 0.9, 0.85)
	fumaca.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var faisca := StandardMaterial3D.new()
	faisca.albedo_color = Color("ffe066")
	faisca.emission_enabled = true
	faisca.emission = Color("ffd23f")
	faisca.emission_energy_multiplier = 3.0
	for i in 10:
		var e := MeshInstance3D.new()
		var bola := SphereMesh.new()
		var e_faisca := i % 2 == 0
		bola.radius = 0.06 if e_faisca else 0.28
		bola.height = bola.radius * 2.0
		e.mesh = bola
		e.material_override = faisca if e_faisca else fumaca
		_mundo.add_child(e)
		e.global_position = centro
		var a := TAU * i / 10.0
		var destino := centro + (Vector3(cos(a) * 1.2, 0.6, sin(a) * 1.2) if e_faisca else Vector3(cos(a) * 0.4, 1.4, sin(a) * 0.4))
		var tw := e.create_tween().set_parallel()
		tw.tween_property(e, "global_position", destino, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(e, "scale", Vector3.ONE * (0.01 if e_faisca else 2.2), 0.9)
		tw.chain().tween_callback(e.queue_free)


## O clarão de hoje na boca do blaster (Fx.muzzle_flash): uma bolinha amarela e a luz.
func _clarao_de_hoje(p: Vector3) -> void:
	var boca := Node3D.new()
	_mundo.add_child(boca)
	boca.global_position = p
	Fx.muzzle_flash(boca)
