extends SceneTree
## Rascunho da fase 1-2 "Túneis do Morro" com as peças do Dungeon Pack (assets/faisca/masmorra/), para
## conferir escala, escuro e tochas antes de montar a fase de verdade. Um corredor de mina com andaimes,
## tochas apagadas e acesas, um vão com ponte de tábuas, o canto do ouro e o portão com o baú atrás.
## Uso: godot --path . -s tools/rascunho_tuneis.gd (precisa de janela); fotos em tools/capturas/tuneis_*.png.

const PASTA := "res://assets/faisca/masmorra/"
## Escala das peças de construção (paredes, chão, andaimes): os módulos de 4 m viram 6 m.
const S := 1.5

var _quadros := 0
var _cam: Camera3D
var _fotos := [
	["tuneis_1_corredor.png", Vector3(1.5, 4.2, 9.0), Vector3(0, 2.0, -16.0)],
	["tuneis_2_vao.png", Vector3(9.0, 11.0, -20.0), Vector3(0, 0.0, -31.0)],
	["tuneis_3_portao.png", Vector3(-3.5, 3.6, -36.0), Vector3(1.0, 2.2, -50.0)],
]


func _initialize() -> void:
	var raiz := Node3D.new()
	root.add_child.call_deferred(raiz)
	_ambiente(raiz)
	# Chão: corredor de 12 m de largura; o vão fica entre z -24 e -36, só com a ponte de tábuas.
	for z in [0.0, -6.0, -12.0, -18.0, -36.0, -42.0, -54.0]:
		for x in [-3.0, 3.0]:
			_peca(raiz, "floor_dirt_large" if int(absf(z + x)) % 4 != 0 else "floor_dirt_large_rocky", Vector3(x, 0, z), 0.0, S)
	for z in [-48.0]:
		for x in [-3.0, 3.0]:
			_peca(raiz, "floor_tile_large", Vector3(x, 0, z), 0.0, S)
	for k in 4:
		_peca(raiz, "floor_wood_small", Vector3(0, 0, -25.5 - 3.0 * k), 0.0, S)
	# Paredes dos dois lados (o módulo tem 4 m no eixo X; girado, fica ao longo do corredor). Sem teto: o
	# escuro em cima faz a vez da rocha e deixa a câmera livre.
	for z in range(0, 10):
		var zz := 3.0 - 6.0 * z
		for lado in [-1.0, 1.0]:
			var nome := "wall"
			if z == 2 and lado < 0:
				nome = "wall_cracked"
			elif z == 6 and lado > 0:
				nome = "wall_inset_candles"
			_peca(raiz, nome, Vector3(lado * 6.75, 0, zz - 3.0), PI / 2.0 * lado, S)
	# Andaimes de mina atravessando o corredor, com tocha.
	for z in [-3.0, -15.0, -39.0]:
		var a := _peca(raiz, "scaffold_pillars_connected", Vector3(0, 0, z), 0.0, Vector3(12.6 / 7.0, S, S))
		a.name = "Andaime"
	# Portão no fim, entre duas paredes, e a câmara do baú atrás.
	_peca(raiz, "wall_gated", Vector3(0, 0, -51.0), 0.0, S)
	for x in [-6.0, 6.0]:
		_peca(raiz, "wall", Vector3(x, 0, -51.0), 0.0, Vector3(1.0, S, S))
	_peca(raiz, "chest_large_gold", Vector3(0, 0, -56.0), 0.0, 1.5)
	# Canto do ouro e das ferramentas.
	_peca(raiz, "rocks_gold", Vector3(-4.2, 0, -40.0), 0.6, 1.2)
	_peca(raiz, "rocks_gold", Vector3(4.4, 0, -44.5), 2.0, 1.0)
	_peca(raiz, "bucket_pickaxes", Vector3(-3.6, 0, -43.5), 0.3, 1.2)
	_peca(raiz, "crates_stacked", Vector3(4.6, 0, -8.0), 0.4, 1.2)
	_peca(raiz, "barrel_large", Vector3(-4.8, 0, -1.0), 0.0, 1.0)
	_peca(raiz, "barrel_small_stack", Vector3(4.6, 0, 1.5), 0.0, 1.2)
	_peca(raiz, "rocks", Vector3(-4.5, 0, -16.5), 1.0, 1.3)
	_peca(raiz, "rubble_half", Vector3(4.0, 0, -20.0), PI / 2.0, 1.0)
	# Tochas em pedestal: apagada (cinza, sem luz) e acesa (chama e luz laranja).
	_tocha(raiz, Vector3(-4.0, 0, -6.0), false)
	_tocha(raiz, Vector3(4.0, 0, -11.0), true)
	_tocha(raiz, Vector3(-4.0, 0, -19.0), true)
	_tocha(raiz, Vector3(3.8, 0, -38.5), false)
	_tocha(raiz, Vector3(-4.0, 0, -47.0), true)
	# Estrelinhas mostrando o caminho, inclusive em arco sobre o vão.
	for k in 7:
		_estrela(raiz, Vector3(0, 1.0, -1.0 - 3.0 * k))
	for k in 4:
		_estrela(raiz, Vector3(0, 1.0 + sin(PI * (k + 0.5) / 4.0) * 1.5, -25.5 - 3.0 * k))
	# O Faísca, para a escala.
	var robo := Robo.new()
	robo.position = Vector3(0, 0, 3.0)
	robo.rotation.y = PI
	raiz.add_child.call_deferred(robo)
	_cam = Camera3D.new()
	_cam.fov = 60.0
	raiz.add_child.call_deferred(_cam)


func _ambiente(raiz: Node3D) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("0d0a18")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("8a90c8")
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.fog_enabled = true
	env.fog_light_color = Color("1a1430")
	env.fog_density = 0.012
	env.ssao_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	raiz.add_child(we)
	# Uma luz fraquinha de cima, como a claridade que entra pela boca do túnel.
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-60, 20, 0)
	luz.light_energy = 0.15
	luz.light_color = Color("b8c4ff")
	raiz.add_child(luz)


func _peca(raiz: Node3D, nome: String, pos: Vector3, giro: float, escala: Variant) -> Node3D:
	var no: Node3D = load(PASTA + nome + ".gltf").instantiate()
	no.position = pos
	no.rotation.y = giro
	no.scale = escala if escala is Vector3 else Vector3.ONE * float(escala)
	raiz.add_child(no)
	return no


func _tocha(raiz: Node3D, pos: Vector3, acesa: bool) -> void:
	var base := _peca(raiz, "column", pos, 0.0, 1.1)
	var tocha := _peca(raiz, "torch_lit" if acesa else "torch", pos + Vector3(0, 1.54 + 0.4, 0), 0.0, 1.3)
	if not acesa:
		for mi in tocha.find_children("*", "MeshInstance3D", true, false):
			var m := StandardMaterial3D.new()
			m.albedo_color = Color("5a5466")
			(mi as MeshInstance3D).material_override = m
		return
	var chama := MeshInstance3D.new()
	var bola := SphereMesh.new()
	bola.radius = 0.28
	bola.height = 0.75
	chama.mesh = bola
	var fogo := StandardMaterial3D.new()
	fogo.albedo_color = Color("ffcf5a")
	fogo.emission_enabled = true
	fogo.emission = Color("ff9a2e")
	fogo.emission_energy_multiplier = 4.0
	chama.material_override = fogo
	chama.position = pos + Vector3(0, 2.95, 0)
	raiz.add_child(chama)
	var luz := OmniLight3D.new()
	luz.light_color = Color("ffb35c")
	luz.light_energy = 2.6
	luz.omni_range = 11.0
	luz.position = pos + Vector3(0, 3.3, 0)
	raiz.add_child(luz)
	base.name = "Tocha"


func _estrela(raiz: Node3D, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = Forma.estrela(0.34, 0.15, 0.17)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("ffd23f")
	m.emission_enabled = true
	m.emission = Color("ffb800")
	m.emission_energy_multiplier = 1.4
	mi.material_override = m
	mi.position = pos
	raiz.add_child(mi)


func _process(_delta: float) -> bool:
	_quadros += 1
	var i := (_quadros - 10) / 25
	if _quadros < 10 or i >= _fotos.size():
		return _quadros >= 10 + 25 * _fotos.size()
	var f: Array = _fotos[i]
	if (_quadros - 10) % 25 == 0:
		_cam.make_current()
		_cam.look_at_from_position(f[1], f[2])
	if (_quadros - 10) % 25 == 24:
		root.get_viewport().get_texture().get_image().save_png("res://tools/capturas/" + f[0])
		print("foto: ", f[0])
	return false
