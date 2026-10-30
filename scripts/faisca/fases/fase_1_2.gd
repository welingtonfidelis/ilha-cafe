class_name Fase12
extends Fase
## 1-2 Túneis do Morro (Mundo 1, a porta do leste no térreo do farol). As Bolotas esconderam a segunda
## Estrela Grande na mina velha dos Ossinhos, por baixo do Morro dos Ventos, e as tochas que os esqueletos
## deixaram estão apagadas. Fase do chão, no escuro azulado da caverna, com as peças do Dungeon Pack em
## 1,5x (módulos de 6 m) e sem teto: em cima, o escuro faz a vez da rocha e a câmera fica solta.
## Novidade: o laser acende tochas (clareiam, abrem portas e levantam pontes). Refeita em 2026-10-29 no padrão
## de playgrounds (docs/level-design/molde-das-fases.html): quatro salas em volta do marco, o Poço do Cristal (um
## cristal gigante aceso no meio da caverna), subindo até a arena da Bolotona no alto dele.
##   1 Salão das Tochas (chão, ao sul): três tochas abrem a porta do carrinho; andaime com estrelinhas
##   viagem: carrinho de mina subindo a rampa
##   2 Mina de Ouro (8 m, a oeste): abismo com a ponte da tocha ou os tablados; V1 atrás da parede rachada (P1)
##   viagem: elevador
##   3 Sala das Alavancas (16 m, ao norte): três grades; a da saída, a da sala escura (V2) e a do depósito
##     (coração) (P2)
##   viagem: balsa que vai e volta (atalho)
##   4 Poço dos Cristais (16 m, a leste): cristais que jogam para o alto, subindo até a arena; V3 atrás da
##     parede rachada (P3)
##   Arena no alto do cristal (30 m): a Bolotona; vencida com as filhas, a grade da alcova do baú abre

## Escala das peças de construção e o tamanho de um módulo.
const S := 1.5
const M := 6.0
const COR_ROCHA := Color("3b3550")
const COR_MADEIRA := Color("7a4a2a")
## Altura das paredes invisíveis acima das que se veem.
const LIMITE := 16.0
## O marco: o meio do Poço do Cristal (o cristal vai de 24 m abaixo até 24 m acima; a arena fica em cima).
const CRISTAL := Vector3(0, 0, -66)

var _mat_rocha: StandardMaterial3D
var _paredes: StaticBody3D
var _limites: StaticBody3D
## A luz da caverna (a sala escura abaixa e devolve).
var _ambiente: Environment
var _luz_de_cima: DirectionalLight3D
var escuro := false
var _grade_da_arena: Grade


func _montar() -> void:
	nome = "1-2 Túneis do Morro"
	inicio = Vector3(-3, 0.1, -16)
	limite_queda = -12.0
	_mat_rocha = _material(COR_ROCHA)
	_mat_rocha.roughness = 1.0
	_paredes = StaticBody3D.new()
	add_child(_paredes)
	_limites = StaticBody3D.new()
	_limites.collision_layer = CAMADA_LIMITE
	_limites.collision_mask = 0
	add_child(_limites)
	_poco_do_cristal()
	_salao_das_tochas()
	_carrinho_ate_a_mina()
	_mina_de_ouro()
	_elevador_ate_as_alavancas()
	_sala_das_alavancas()
	_sala_escura()
	_deposito()
	_balsa_ate_os_cristais()
	_poco_dos_cristais()
	_arena_no_cristal()


## O marco: o cristal gigante aceso no meio do poço, sólido, com a luz azul que chega em todas as salas. Lá no
## fundo, cristaizinhos dão a ideia de fundura.
func _poco_do_cristal() -> void:
	var corpo := StaticBody3D.new()
	corpo.position = CRISTAL
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 5.0
	cil.height = 48.0
	cs.shape = cil
	corpo.add_child(cs)
	add_child(corpo)
	var cristal := _material(Color("7fd8ff"))
	cristal.emission_enabled = true
	cristal.emission = Color("2fa8ff")
	cristal.emission_energy_multiplier = 0.8
	cristal.roughness = 0.15
	cristal.metallic_specular = 0.9
	# Prismas de seis lados (as faces pegam a luz das tochas): o grande e quatro menores grudados nele.
	var principal := MeshInstance3D.new()
	principal.mesh = _prisma(4.9, 48.0, 4.5)
	principal.material_override = cristal
	principal.position = CRISTAL
	add_child(principal)
	for spec in [[Vector3(4.6, -8, 2.0), 1.6, 14.0, 0.35], [Vector3(-4.4, 2, -2.5), 1.4, 12.0, -0.3],
			[Vector3(2.8, 12, -4.2), 1.2, 10.0, 0.25], [Vector3(-3.6, -14, 3.8), 1.8, 16.0, -0.4]]:
		var mi := MeshInstance3D.new()
		mi.mesh = _prisma(spec[1], spec[2], spec[1] * 0.25)
		mi.material_override = cristal
		mi.position = CRISTAL + spec[0]
		mi.rotation = Vector3(spec[3], 0.4, -spec[3])
		add_child(mi)
	for y in [-6.0, 14.0]:
		var luz := OmniLight3D.new()
		luz.light_color = Color("5fc8ff")
		luz.light_energy = 2.2
		luz.omni_range = 34.0
		luz.position = CRISTAL + Vector3(0, y, 0)
		add_child(luz)
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 12
	for i in 16:
		var mi := MeshInstance3D.new()
		var tam := sorteio.randf_range(0.8, 1.8)
		mi.mesh = _prisma(0.35 * tam, 2.0 * tam, 0.05)
		mi.material_override = cristal
		mi.position = CRISTAL + Vector3(sorteio.randf_range(-16.0, 16.0), -24.0 + tam, sorteio.randf_range(-16.0, 16.0))
		mi.rotation = Vector3(sorteio.randf_range(-0.4, 0.4), 0, sorteio.randf_range(-0.4, 0.4))
		add_child(mi)


## Prisma de cristal de seis lados (raio embaixo, altura e raio em cima).
func _prisma(raio: float, altura: float, topo: float) -> CylinderMesh:
	var p := CylinderMesh.new()
	p.radial_segments = 6
	p.rings = 1
	p.bottom_radius = raio
	p.top_radius = topo
	p.height = altura
	return p


## Playground 1 · Salão das Tochas (apresenta): a sala da entrada, no chão, com a claridade do dia atrás e a beira do
## poço na frente (dá para ver o cristal e o brilho do baú lá no alto). Três tochas apagadas abrem a porta do
## carrinho: uma no caminho, uma do outro lado e uma em cima dos caixotes (pulo alto e voo). O andaime do canto
## leste é o bolso, com estrelinhas no alto. O Ossinho mineiro acena; uma Bolota dorme.
func _salao_das_tochas() -> void:
	playground("1 · Salão das Tochas", Vector3(0, 0, -30), 18.0, inicio)
	rocha(-18.0, 18.0, -12.0, -48.0, 0.0)
	chao([-15.0, -9.0, -3.0, 3.0, 9.0, 15.0], -15.0, -45.0, 0.0)
	parede_x(-11.25, [-15.0, -9.0, 3.0, 9.0, 15.0], 0.0)
	var vao := peca_de(MASMORRA, "wall_doorway", Vector3(-3.0, 0, -11.25), PI, S, false)
	vao.find_child("wall_doorway_door", true, false).queue_free()
	_muro(Vector3(-3.0, 0, -11.25), Vector3(6.0, M, 1.5))
	var dia := MeshInstance3D.new()
	var quadro := QuadMesh.new()
	quadro.size = Vector2(6.0, 6.0)
	dia.mesh = quadro
	var claro := StandardMaterial3D.new()
	claro.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	claro.albedo_color = Color("e4f3ff")
	dia.material_override = claro
	dia.position = Vector3(-3.0, 3.0, -10.2)
	dia.rotation.y = PI
	add_child(dia)
	var luz_do_dia := OmniLight3D.new()
	luz_do_dia.light_color = Color("cfe6ff")
	luz_do_dia.light_energy = 2.5
	luz_do_dia.omni_range = 13.0
	luz_do_dia.position = Vector3(-3.0, 3.5, -13.0)
	add_child(luz_do_dia)
	parede_z(-18.75, -15.0, -21.0, 0.0)
	parede_z(-18.75, -33.0, -45.0, 0.0)
	parede_z(18.75, -15.0, -45.0, 0.0)
	# Mureta na beira do poço.
	rocha(-18.0, 18.0, -47.2, -48.0, 0.9, 0.0)

	var ta := tocha(Vector3(-11.0, 0, -23.0))
	var tb := tocha(Vector3(9.0, 0, -36.0))
	caixote(Vector3(-12.0, 0, -40.0), Vector3(1.8, 1.6, 1.8))
	caixote(Vector3(-15.0, 0, -41.0), Vector3(3.0, 3.0, 3.0))
	var tc := tocha(Vector3(-15.8, 3.0, -41.8), false)
	saidas.append(porta_das_tochas(Vector3(-18.75, 0, -27.0), PI / 2.0, [ta, tb, tc]))
	ponto_de_dica(Vector3(-6.0, 0.5, -22.5), 2.6, "tocha")
	tocha(Vector3(-16.4, 0, -14.0), true, true)
	trilha_creme([Vector3(-3, 0, -15), Vector3(-4, 0, -21), Vector3(-9, 0, -26), Vector3(-17.5, 0, -27)])
	trilha(Vector3(-3.5, 1.0, -18.0), Vector3(-8.0, 1.0, -25.5), 4)
	estrelinha(Vector3(-12.0, 2.6, -40.0))
	estrelinha(Vector3(-14.2, 4.0, -40.2))

	# Bolso: o andaime do canto leste, com estrelinhas no alto.
	tablado(Vector3(13.0, 1.6, -16.5), Vector2(4, 4))
	tablado(Vector3(13.0, 3.2, -21.5), Vector2(4, 4))
	tablado(Vector3(8.0, 4.8, -21.5), Vector2(4, 4))
	roda(Vector3(8.0, 5.8, -21.5), 1.2, 4)
	trilha(Vector3(2.0, 1.0, -17.5), Vector3(9.0, 1.0, -15.5), 3)
	estrelinha(Vector3(13.0, 2.6, -16.5))
	estrelinha(Vector3(13.0, 4.2, -21.5))

	_ossinho(Vector3(-7.0, 0, -15.0), 0.5)
	bolota(Vector3(3.0, 0, -22.0), true)
	enfeite_m("barrel_large", Vector3(-15.8, 0, -18.0))
	enfeite_m("barrel_small_stack", Vector3(15.6, 0, -40.0), 1.2, 0.4)
	enfeite_m("crates_stacked", Vector3(16.0, 0, -30.0), 1.2, -0.3)
	enfeite_m("bucket_pickaxes", Vector3(-15.9, 0, -33.0), 1.2, 0.8)
	enfeite_m("rocks", Vector3(4.0, 0, -44.5), 1.3, 1.0)


## Viagem 1: o carrinho de mina, da estação do lado de fora da porta das tochas, sobe a rampa até a mina (8 m).
func _carrinho_ate_a_mina() -> void:
	rocha(-24.0, -18.0, -24.0, -30.0, 0.0)
	chao_pedaco(Vector3(-21.0, 0.0, -27.0), Vector2(6.0, 6.0))
	var de := Vector3(-21.5, 0.0, -28.5)
	var ate := Vector3(-21.5, 8.0, -46.0)
	carrinho(de, ate)
	caixote(Vector3(-23.4, 0.0, -25.4), Vector3(1.2, 0.7, 1.2))
	estrelinha(de + Vector3(0, 2.4, 0))
	for i in 4:
		estrelinha(de.lerp(ate, (i + 1) / 5.0) + Vector3(0, 2.1, 0))
	tocha(Vector3(-23.2, 0.0, -29.4), true, true)
	# Chegada: a plataforma da mina, com o P1.
	rocha(-24.0, -18.0, -46.0, -52.0, 8.0)
	chao_pedaco(Vector3(-21.0, 8.0, -49.0), Vector2(6.0, 6.0))
	posto(Vector3(-21.0, 8.0, -50.5))


## Playground 2 · Mina de Ouro (desenvolve): uma sala larga a 8 m, cortada no meio por um abismo. Pelo meio, a tocha
## da beira levanta a ponte; pela esquerda, dois tablados de pulo. Dentro do abismo, uma beiradinha com
## estrelinhas e uma mola de volta (bolso embaixo). A parede rachada do oeste esconde o V1 num nicho com velas.
## Três Bolotas, o monte de ouro (mini-marco) e o elevador no canto nordeste.
func _mina_de_ouro() -> void:
	playground("2 · Mina de Ouro", Vector3(-39.0, 8.0, -63.0), 20.0, Vector3(-21.0, 8.0, -49.0))
	rocha(-54.0, -24.0, -42.0, -54.0, 8.0)
	rocha(-54.0, -24.0, -66.0, -84.0, 8.0)
	chao([-51.0, -45.0, -39.0, -33.0, -27.0], -45.0, -51.0, 8.0)
	chao([-51.0, -45.0, -39.0, -33.0, -27.0], -69.0, -81.0, 8.0)
	parede_x(-41.25, [-51.0, -45.0, -39.0, -33.0, -27.0], 8.0)
	parede_z(-54.75, -45.0, -69.0, 8.0)
	parede_z(-54.75, -81.0, -81.0, 8.0)
	parede_x(-84.75, [-51.0, -45.0, -39.0, -33.0], 8.0)
	# Mureta na beira do poço (o lado leste, menos a chegada do carrinho).
	rocha(-24.8, -24.0, -42.0, -46.0, 8.9, 8.0)
	rocha(-24.8, -24.0, -52.0, -54.0, 8.9, 8.0)
	rocha(-24.8, -24.0, -66.0, -84.0, 8.9, 8.0)

	# O abismo: a ponte da tocha pelo meio e os tablados pela esquerda.
	var t1 := tocha(Vector3(-36.0, 8.0, -52.5))
	ponte_da_tocha(t1, Vector3(-39.0, 8.0, -54.0), Vector3(-39.0, 8.0, -66.0))
	trilha(Vector3(-39.0, 9.0, -55.5), Vector3(-39.0, 9.0, -64.5), 3)
	tablado(Vector3(-50.0, 8.0, -57.5), Vector2(3.5, 3.0), -14.0, false)
	tablado(Vector3(-50.0, 8.0, -62.5), Vector2(3.5, 3.0), -14.0, false)
	estrelinha(Vector3(-50.0, 9.1, -57.5))
	estrelinha(Vector3(-50.0, 9.1, -62.5))
	rocha(-32.0, -26.0, -58.0, -62.0, 2.0, -2.0)
	roda(Vector3(-30.0, 3.0, -60.0), 1.0, 3)
	mola(Vector3(-27.5, 2.0, -60.0), 19.0)

	# O V1 atrás da parede rachada do oeste.
	parede_rachada(Vector3(-54.75, 8.0, -75.0), PI / 2.0)
	_muro(Vector3(-54.75, 8.0 + M, -75.0), Vector3(1.5, LIMITE, 6.0), true)
	ponto_de_dica(Vector3(-51.0, 8.5, -75.0), 2.6, "golpe")
	rocha(-61.5, -54.0, -72.0, -78.0, 8.0)
	chao([-58.5], -75.0, -75.0, 8.0)
	parede_z(-62.25, -75.0, -75.0, 8.0, 1, "wall_inset_candles", PI / 2.0)
	parede_x(-71.25, [-58.5], 8.0)
	parede_x(-78.75, [-58.5], 8.0)
	var velas := OmniLight3D.new()
	velas.light_color = Color("ffc070")
	velas.light_energy = 1.2
	velas.omni_range = 5.0
	velas.position = Vector3(-60.0, 10.5, -75.0)
	add_child(velas)
	vaga_lume(Vector3(-58.0, 9.2, -75.0))
	trilha(Vector3(-52.0, 9.0, -73.5), Vector3(-52.0, 9.0, -76.5), 2)

	bolota(Vector3(-33.0, 8.0, -47.0))
	bolota(Vector3(-45.0, 8.0, -74.0))
	bolota(Vector3(-31.0, 8.0, -79.0))
	trilha_creme([Vector3(-21, 8, -48), Vector3(-30, 8, -49), Vector3(-38, 8, -52.5)])
	trilha_creme([Vector3(-39, 8, -67), Vector3(-36, 8, -74), Vector3(-29, 8, -81)])
	trilha(Vector3(-27.0, 9.0, -48.5), Vector3(-34.0, 9.0, -50.0), 3)
	trilha(Vector3(-38.0, 9.0, -69.0), Vector3(-31.0, 9.0, -78.0), 3)
	enfeite_m("rocks_gold", Vector3(-46.0, 8.0, -46.5), 2.4, 0.6)
	enfeite_m("rocks_gold", Vector3(-51.5, 8.0, -81.0), 1.3, 2.0)
	enfeite_m("bucket_pickaxes", Vector3(-43.0, 8.0, -45.0), 1.2, 0.4)
	enfeite_m("pickaxe", Vector3(-49.6, 8.05, -45.0), 1.4, 1.2)
	enfeite_m("keg", Vector3(-25.6, 8.0, -71.0), 1.1, 0.5)
	tocha(Vector3(-52.6, 8.0, -43.6), true, true)
	tocha(Vector3(-25.6, 8.0, -76.0), true, true)


## Viagem 2: o elevador do canto nordeste da mina sobe até o patamar da Sala das Alavancas (16 m), onde fica o P2.
func _elevador_ate_as_alavancas() -> void:
	saidas.append(elevador(Vector3(-27.0, 8.0, -82.0), 8.0, 10.0, 0.0))
	trilha(Vector3(-27.0, 11.0, -82.0), Vector3(-27.0, 15.0, -82.0), 3)
	rocha(-30.0, -18.0, -84.0, -90.0, 16.0)
	chao_pedaco(Vector3(-24.0, 16.0, -87.0), Vector2(12.0, 6.0))
	posto(Vector3(-25.0, 16.0, -87.0))


## Playground 3 · Sala das Alavancas (central): a maior sala, a 16 m, de frente para o cristal. Três grades na parede:
## a da saída (leste, alavanca em cima do caixote), a da sala escura (norte, alavanca guardada por duas Bolotas) e
## a do depósito (norte, alavanca do lado). As duas colunas com ouro e tochas são o mini-marco.
func _sala_das_alavancas() -> void:
	playground("3 · Sala das Alavancas", Vector3(0, 16.0, -105.0), 22.0, Vector3(-22.0, 16.0, -87.5))
	rocha(-24.0, 24.0, -90.0, -121.5, 16.0)
	chao([-21.0, -15.0, -9.0, -3.0, 3.0, 9.0, 15.0, 21.0], -93.0, -117.0, 16.0, "floor_tile_large")
	parede_z(-24.75, -93.0, -117.0, 16.0)
	parede_x(-120.75, [-21.0, -15.0, -3.0, 3.0, 9.0, 21.0], 16.0)
	parede_z(24.75, -99.0, -117.0, 16.0)
	rocha(-18.0, 24.0, -90.0, -90.8, 16.9, 16.0)
	ponto_de_dica(Vector3(-18.0, 16.5, -94.0), 2.6, "alavanca")

	caixote(Vector3(19.5, 16.0, -101.5), Vector3(3.0, 1.6, 3.0))
	saidas.append(portao_de_grade(Vector3(24.75, 16.0, -93.0), PI / 2.0, Vector3(20.0, 17.6, -102.6), "yellow"))
	_lados_da_grade(Vector3(24.75, 16.0, -93.0), true)
	estrelinha(Vector3(19.0, 18.8, -100.8))
	portao_de_grade(Vector3(-9.0, 16.0, -120.75), 0.0, Vector3(-3.0, 16.0, -114.0), "red")
	portao_de_grade(Vector3(15.0, 16.0, -120.75), 0.0, Vector3(11.0, 16.0, -116.5), "blue")
	_lados_da_grade(Vector3(-9.0, 16.0, -120.75), false)
	_lados_da_grade(Vector3(15.0, 16.0, -120.75), false)
	bolota(Vector3(-6.0, 16.0, -111.0))
	bolota(Vector3(1.0, 16.0, -112.0))
	bolota(Vector3(6.0, 16.0, -100.0))

	for x in [-6.0, 6.0]:
		peca_de(MASMORRA, "pillar", Vector3(x, 16.0, -105.0), 0.0, S, false)
		_muro(Vector3(x, 16.0, -105.0), Vector3(2.2, M, 2.2), false)
		enfeite_m("rocks_gold", Vector3(x, 16.0, -102.6), 1.1, x)
	tocha(Vector3(-22.6, 16.0, -118.6), true, true)
	tocha(Vector3(22.6, 16.0, -118.6), true, true)
	tocha(Vector3(-22.6, 16.0, -96.0), true, true)
	trilha_creme([Vector3(-24, 16, -87), Vector3(-16, 16, -93.5), Vector3(-4, 16, -97), Vector3(10, 16, -96), Vector3(23.5, 16, -93)])
	trilha(Vector3(-14.0, 17.0, -94.0), Vector3(-2.0, 17.0, -97.0), 4)
	trilha(Vector3(9.0, 17.0, -96.0), Vector3(15.0, 17.0, -95.0), 2)
	roda(Vector3(0, 17.0, -105.0), 2.2, 5)
	enfeite_m("crates_stacked", Vector3(-21.6, 16.0, -108.0), 1.2, 0.2)
	enfeite_m("barrel_large", Vector3(21.6, 16.0, -111.0), 1.0)


## Bolso da Sala das Alavancas: a sala escura. A luz da caverna quase apaga quando o Faísca entra. O caminho é uma
## passarela de tábuas em zigue-zague em cima do vazio, com uma tocha apagada em cada curva; no fim, o V2.
func _sala_escura() -> void:
	rocha(-18.0, 0.0, -121.5, -124.5, 16.0)
	chao_pedaco(Vector3(-9.0, 16.0, -123.0), Vector2(18.0, 3.0))
	parede_z(-18.75, -124.5, -136.5, 16.0)
	parede_z(0.75, -124.5, -136.5, 16.0)
	parede_x(-140.25, [-15.0, -9.0, -3.0], 16.0)
	var trechos := [[Vector3(-12.0, 16.0, -127.0), Vector2(3.0, 5.0)], [Vector3(-9.0, 16.0, -131.0), Vector2(9.0, 3.0)],
		[Vector3(-6.0, 16.0, -135.0), Vector2(3.0, 5.0)], [Vector3(-9.0, 16.0, -138.5), Vector2(9.0, 2.0)]]
	for t in trechos:
		tablado(t[0], t[1], -14.0, false)
	for p in [Vector3(-12.9, 16.0, -131.7), Vector3(-5.1, 16.0, -130.3), Vector3(-5.1, 16.0, -137.8)]:
		tocha(p)
	trilha(Vector3(-12.0, 17.0, -125.5), Vector3(-12.0, 17.0, -128.5), 2)
	trilha(Vector3(-10.5, 17.0, -131.0), Vector3(-7.5, 17.0, -131.0), 2)
	vaga_lume(Vector3(-11.0, 17.2, -138.5))
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = CAMADA_JOGADOR
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(18.0, 22.0, 20.0)
	cs.shape = caixa
	cs.position = Vector3(-9.0, 21.0, -131.0)
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(func(c: Node3D) -> void:
		if c is Jogador:
			escurecer(true))
	area.body_exited.connect(func(c: Node3D) -> void:
		if c is Jogador:
			escurecer(false))


## A luz da caverna baixa quase toda (sala escura) ou volta ao normal, aos poucos.
func escurecer(sim: bool) -> void:
	if sim == escuro or _ambiente == null:
		return
	escuro = sim
	var tw := create_tween().set_parallel()
	tw.tween_property(_ambiente, "ambient_light_energy", 0.08 if sim else 0.5, 0.8)
	tw.tween_property(_luz_de_cima, "light_energy", 0.03 if sim else 0.18, 0.8)


## Bolso da Sala das Alavancas: o depósito, com o coração extra e estrelinhas.
func _deposito() -> void:
	rocha(12.0, 18.0, -121.5, -133.5, 16.0)
	chao([15.0], -124.5, -130.5, 16.0, "floor_tile_large")
	parede_z(11.25, -124.5, -130.5, 16.0)
	parede_z(18.75, -124.5, -130.5, 16.0)
	parede_x(-134.25, [15.0], 16.0)
	coracao(Vector3(15.0, 17.0, -130.0))
	roda(Vector3(15.0, 17.0, -126.5), 1.4, 4)
	tocha(Vector3(16.6, 16.0, -132.4), true, true)


## Viagem 3: do lado de fora da grade da saída, a balsa de madeira vai e volta até o Poço dos Cristais (é também o
## atalho de volta).
func _balsa_ate_os_cristais() -> void:
	rocha(24.0, 31.5, -90.0, -96.0, 16.0)
	chao_pedaco(Vector3(28.5, 16.0, -93.0), Vector2(6.0, 6.0))
	elevador(Vector3(28.5, 16.0, -88.0), 0.0, 12.0, 0.0, Vector3(0, 0, 8.0))
	trilha(Vector3(28.5, 17.4, -88.0), Vector3(28.5, 17.4, -81.0), 3)


## Playground 4 · Poço dos Cristais (reviravolta): a sala a leste do poço, a 16 m. Os cristais azuis jogam para o
## alto: do chão da sala para o primeiro tablado dentro do poço, dele para o segundo, e dele para a arena no alto
## do cristal. A parede rachada do leste esconde o V3, e as estrelinhas no chão levam até ela. Duas Bolotas.
func _poco_dos_cristais() -> void:
	playground("4 · Poço dos Cristais", Vector3(26.0, 22.0, -63.0), 16.0, Vector3(28.0, 16.0, -76.0))
	rocha(24.0, 42.0, -48.0, -78.0, 16.0)
	chao([27.0, 33.0, 39.0], -51.0, -75.0, 16.0, "floor_tile_large")
	parede_x(-47.25, [27.0, 33.0, 39.0], 16.0)
	parede_x(-78.75, [33.0, 39.0], 16.0)
	parede_z(42.75, -51.0, -57.0, 16.0)
	parede_z(42.75, -69.0, -75.0, 16.0)
	posto(Vector3(29.0, 16.0, -74.0))
	mola_de_cristal(Vector3(25.5, 16.0, -59.0), 19.0)
	tablado(Vector3(19.5, 21.0, -59.0), Vector2(5.0, 5.0), -14.0, false)
	mola_de_cristal(Vector3(18.2, 21.0, -60.8), 19.0)
	tablado(Vector3(14.0, 25.0, -66.0), Vector2(5.0, 5.0), -14.0, false)
	mola_de_cristal(Vector3(12.6, 25.0, -66.0), 19.0)
	arco(Vector3(25.5, 19.0, -59.0), Vector3(20.5, 22.5, -59.0), 3.0, 3)
	arco(Vector3(18.2, 24.0, -60.8), Vector3(14.5, 26.5, -65.0), 3.0, 3)
	arco(Vector3(12.6, 28.0, -66.0), Vector3(6.0, 31.0, -66.0), 2.0, 3)
	rocha(24.0, 24.8, -48.0, -56.5, 16.9, 16.0)
	rocha(24.0, 24.8, -61.5, -78.0, 16.9, 16.0)
	bolota(Vector3(34.0, 16.0, -56.0))
	bolota(Vector3(37.0, 16.0, -70.0))
	trilha_creme([Vector3(28, 16, -76), Vector3(30, 16, -68), Vector3(26.5, 16, -61)])
	trilha(Vector3(29.5, 17.0, -71.0), Vector3(27.0, 17.0, -63.5), 3)

	# Segredo: a parede rachada do leste, com o V3 no nicho.
	parede_rachada(Vector3(42.75, 16.0, -63.0), -PI / 2.0)
	_muro(Vector3(42.75, 16.0 + M, -63.0), Vector3(1.5, LIMITE, 6.0), true)
	rocha(42.0, 49.5, -60.0, -66.0, 16.0)
	chao([46.5], -63.0, -63.0, 16.0)
	parede_z(50.25, -63.0, -63.0, 16.0, 1, "wall_inset_candles", -PI / 2.0)
	parede_x(-59.25, [46.5], 16.0)
	parede_x(-66.75, [46.5], 16.0)
	var velas := OmniLight3D.new()
	velas.light_color = Color("ffc070")
	velas.light_energy = 1.2
	velas.omni_range = 5.0
	velas.position = Vector3(48.0, 18.5, -63.0)
	add_child(velas)
	vaga_lume(Vector3(46.0, 17.2, -63.0))
	trilha(Vector3(35.0, 17.0, -63.0), Vector3(40.5, 17.0, -63.0), 3)

	# Mini-marco: um ninho de cristais no canto.
	var cristal := _material(Color("7fd8ff"))
	cristal.emission_enabled = true
	cristal.emission = Color("2fa8ff")
	cristal.emission_energy_multiplier = 1.2
	for spec in [[Vector3(38.5, 16.0, -51.5), Vector3(0.9, 3.6, 0.9), 0.2], [Vector3(40.0, 16.0, -52.5), Vector3(0.6, 2.4, 0.6), -0.35],
			[Vector3(37.5, 16.0, -53.0), Vector3(0.5, 2.0, 0.5), 0.4]]:
		var mi := MeshInstance3D.new()
		mi.mesh = _prisma(spec[1].x, spec[1].y * 2.0, spec[1].x * 0.2)
		mi.material_override = cristal
		mi.position = spec[0] + Vector3(0, spec[1].y * 0.8, 0)
		mi.rotation = Vector3(spec[2], 0, -spec[2])
		add_child(mi)
	tocha(Vector3(40.6, 16.0, -76.0), true, true)


## Arena no alto do cristal (30 m): a Bolotona dorme no meio. Derrotada, ela se desfaz em três Bolotas pequenas;
## vencidas todas, a grade da alcova do baú abre. A coluna de luz do baú aparece de toda a caverna.
func _arena_no_cristal() -> void:
	rocha(-9.0, 9.0, -57.0, -75.0, 30.0, 24.0)
	chao([-6.0, 0.0, 6.0], -60.0, -72.0, 30.0, "floor_tile_large")
	var grande := bolotona(Vector3(0, 30.0, -64.0))
	for b in [grande] + grande.filhas:
		b.derrotada.connect(func(_a: Alvo) -> void: _ver_arena(grande))
	coracao(Vector3(7.0, 31.0, -58.5))
	roda(Vector3(0, 30.9, -64.0), 5.5, 6)
	for p in [Vector3(-8.0, 30.0, -58.0), Vector3(8.0, 30.0, -74.0), Vector3(-8.0, 30.0, -74.0)]:
		tocha(p, true, true)
	rocha(-9.8, -9.0, -56.2, -75.8, 30.9, 24.0)
	rocha(-9.0, 9.8, -56.2, -57.0, 30.9, 24.0)
	rocha(-9.0, -3.75, -75.0, -75.8, 30.9, 24.0)
	rocha(3.75, 9.8, -75.0, -75.8, 30.9, 24.0)
	rocha(-3.0, 3.0, -75.0, -81.0, 30.0, 24.0)
	chao([0.0], -78.0, -78.0, 30.0, "floor_tile_large")
	parede_z(-3.75, -78.0, -78.0, 30.0)
	parede_z(3.75, -78.0, -78.0, 30.0)
	parede_x(-81.75, [0.0], 30.0, 1, "wall_inset_candles")
	peca_de(MASMORRA, "wall_doorway", Vector3(0, 30.0, -75.75), 0.0, S, false).find_child("wall_doorway_door", true, false).queue_free()
	_grade_da_arena = Grade.new()
	_grade_da_arena.position = Vector3(0, 30.0, -75.75)
	add_child(_grade_da_arena)
	grades.append(_grade_da_arena)
	_lados_da_grade(Vector3(0, 30.0, -75.75), false)
	colocar_bau(Vector3(0, 30.0, -78.5), 0.0, true)
	brilho_de_marco(Vector3(0, 31.5, -78.5), 30.0)


func _ver_arena(grande: Bolotona) -> void:
	if bolotona_vencida(grande):
		_grade_da_arena.abrir()


## Colisão dos dois lados do vão de uma grade (a parede da porta é só desenho) e a parede invisível em cima.
## `ao_longo_de_z`: a porta está numa parede que corre ao longo de z (girada de 90 graus).
func _lados_da_grade(pos: Vector3, ao_longo_de_z: bool) -> void:
	var lado := Vector3(0, 0, 2.25) if ao_longo_de_z else Vector3(2.25, 0, 0)
	var tamanho := Vector3(1.5, M, 1.5)
	_muro(pos + lado, tamanho)
	_muro(pos - lado, tamanho)
	_muro(pos + Vector3.UP * M, Vector3(1.5, LIMITE, 6.0) if ao_longo_de_z else Vector3(6.0, LIMITE, 1.5), true)
	_muro(pos + Vector3.UP * 4.1, Vector3(1.5, M - 4.1, 3.0) if ao_longo_de_z else Vector3(3.0, M - 4.1, 1.5))


# --- peças da caverna ------------------------------------------------------------------

## Caverna: sem céu, escuro azulado, luz ambiente fraquinha e uma névoa leve; só uma luz bem fraca de
## cima, para as formas aparecerem. O resto da luz vem das tochas.
func _montar_ceu_e_luz() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("0d0a18")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("8a90c8")
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.fog_enabled = true
	env.fog_light_color = Color("1a1430")
	env.fog_density = 0.01
	env.ssao_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	_ambiente = env
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-60, 20, 0)
	luz.light_energy = 0.18
	luz.light_color = Color("b8c4ff")
	add_child(luz)
	_luz_de_cima = luz


func _montar_nuvens() -> void:
	pass


## Pedra escura e sólida de x0 a x1 e de z0 a z1, com o chão de cima em `topo`.
func rocha(x0: float, x1: float, z0: float, z1: float, topo: float, fundo := -14.0) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	var tamanho := Vector3(absf(x1 - x0), topo - fundo, absf(z1 - z0))
	corpo.position = Vector3((x0 + x1) * 0.5, (topo + fundo) * 0.5, (z0 + z1) * 0.5)
	var mi := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = tamanho
	mi.mesh = caixa
	mi.material_override = _mat_rocha
	corpo.add_child(mi)
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tamanho
	cs.shape = forma
	corpo.add_child(cs)
	add_child(corpo)
	return corpo


## Chão de módulos de 6 m (só o desenho; a colisão é da rocha embaixo): centros em `xs` e de z0 a z1.
func chao(xs: Array, z0: float, z1: float, y: float, tipo := "floor_dirt_large") -> void:
	var z := z0
	while z >= z1 - 0.01:
		for x in xs:
			var nome := tipo
			var sorteio := absi(int(x * 7.0 + z * 13.0)) % 5
			if tipo == "floor_dirt_large" and sorteio == 0:
				nome = "floor_dirt_large_rocky"
			var desce := 0.15 if tipo.begins_with("floor_dirt") else 0.07
			peca_de(MASMORRA, nome, Vector3(x, y - desce, z), PI / 2.0 * (sorteio % 4), S, false)
		z -= M


## Pedaço de chão de pedra de qualquer tamanho (em cima dos pilares do abismo).
func chao_pedaco(centro: Vector3, tamanho: Vector2) -> void:
	peca_de(MASMORRA, "floor_tile_large", centro + Vector3.DOWN * 0.07, 0.0, Vector3(tamanho.x / 4.0, S, tamanho.y / 4.0), false)


## Paredes ao longo de z (de frente para o corredor) em `x`, com centros de z0 a z1 de 6 em 6, em `linhas`
## fileiras a partir de `y`. Colisão numa caixa só, com a parede invisível em cima.
func parede_z(x: float, z0: float, z1: float, y: float, linhas := 1, nome := "wall", giro := INF) -> void:
	var z := z0
	var g := (PI / 2.0 if x < 0.0 else -PI / 2.0) if giro == INF else giro
	while z >= z1 - 0.01:
		for k in linhas:
			peca_de(MASMORRA, nome, Vector3(x, y + M * k, z), g, S, false)
		z -= M
	var comprimento := absf(z0 - z1) + M
	_muro(Vector3(x, y, (z0 + z1) * 0.5), Vector3(1.5, M * linhas, comprimento))
	_muro(Vector3(x, y + M * linhas, (z0 + z1) * 0.5), Vector3(1.5, LIMITE, comprimento), true)


## Paredes ao longo de x em `z`, com centros em `xs`.
func parede_x(z: float, xs: Array, y: float, linhas := 1, nome := "wall", giro := 0.0) -> void:
	for x in xs:
		for k in linhas:
			peca_de(MASMORRA, nome, Vector3(x, y + M * k, z), giro, S, false)
		_muro(Vector3(x, y, z), Vector3(M, M * linhas, 1.5))
		_muro(Vector3(x, y + M * linhas, z), Vector3(M, LIMITE, 1.5), true)


## Caixa de colisão com o pé em `base` (sólida, ou na camada das paredes invisíveis com `limite`).
func _muro(base: Vector3, tamanho: Vector3, limite := false) -> void:
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tamanho
	cs.shape = forma
	cs.position = base + Vector3.UP * tamanho.y * 0.5
	(_limites if limite else _paredes).add_child(cs)


## Tablado de madeira (largura x profundidade) com o topo em `topo`, em pé num andaime até o chão `chao_y`.
func tablado(topo: Vector3, tamanho: Vector2, chao_y := 0.0, com_pernas := true) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = topo
	var tabuas: Node3D = _cena(MASMORRA + "floor_wood_large.gltf").instantiate()
	tabuas.scale = Vector3(tamanho.x / 4.0, S, tamanho.y / 4.0)
	tabuas.position.y = -0.08
	corpo.add_child(tabuas)
	var lado := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = Vector3(tamanho.x, 0.4, tamanho.y)
	lado.mesh = caixa
	lado.material_override = _material(COR_MADEIRA)
	lado.position.y = -0.3
	corpo.add_child(lado)
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(tamanho.x, 0.5, tamanho.y)
	cs.shape = forma
	cs.position.y = -0.25
	corpo.add_child(cs)
	add_child(corpo)
	var altura := topo.y - 0.5 - chao_y
	if com_pernas and altura > 0.5:
		peca_de(MASMORRA, "scaffold_frame_small", Vector3(topo.x, chao_y, topo.z), 0.0,
				Vector3(tamanho.x / 3.0, altura / 4.0, tamanho.y / 3.0), false)
	elif not com_pernas:
		# Viga presa na parede: só uma trave grossa por baixo.
		var trave := MeshInstance3D.new()
		var t := BoxMesh.new()
		t.size = Vector3(tamanho.x + 3.0, 0.4, 0.5)
		trave.mesh = t
		trave.material_override = _material(Color("6b3f22"))
		trave.position = Vector3(1.5, -0.7, 0)
		corpo.add_child(trave)
	return corpo


## Plataforma de madeira que sobe `subida` metros e volta, a cada `periodo` segundos, parando um pouco em cada
## ponta (`pausa`, como no `movel_peca`). Com `caminho`, anda esse caminho em vez de subir (a balsa da viagem 3).
func elevador(topo: Vector3, subida: float, periodo: float, atraso: float, caminho := Vector3.ZERO, pausa := 0.2) -> AnimatableBody3D:
	var corpo := AnimatableBody3D.new()
	corpo.position = topo
	var tabuas: Node3D = _cena(MASMORRA + "floor_wood_large.gltf").instantiate()
	tabuas.scale = Vector3(1.0, S, 1.0)
	tabuas.position.y = -0.08
	corpo.add_child(tabuas)
	var base := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = Vector3(4.0, 0.5, 4.0)
	base.mesh = caixa
	base.material_override = _material(COR_MADEIRA)
	base.position.y = -0.35
	corpo.add_child(base)
	for x in [-1.0, 1.0]:
		var corda := MeshInstance3D.new()
		var cil := CylinderMesh.new()
		cil.top_radius = 0.05
		cil.bottom_radius = 0.05
		cil.height = 30.0
		corda.mesh = cil
		corda.material_override = _material(Color("c9a873"))
		corda.position = Vector3(1.8 * x, 15.0, 0)
		corpo.add_child(corda)
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(4.0, 0.6, 4.0)
	cs.shape = forma
	cs.position.y = -0.3
	corpo.add_child(cs)
	add_child(corpo)
	_moveis.append([corpo, corpo.position, caminho if caminho != Vector3.ZERO else Vector3(0, subida, 0), periodo, atraso, pausa])
	moveis.append(corpo)
	return corpo


## Caixote sólido (a pilha de caixotes do pacote esticada no tamanho) com o pé em `base`.
func caixote(base: Vector3, tamanho: Vector3) -> void:
	peca_de(MASMORRA, "crates_stacked", base, 0.0, Vector3(tamanho.x / 2.1, tamanho.y / 2.14, tamanho.z / 2.25), false)
	_muro(base, tamanho)


## Enfeite do Dungeon Pack, sem colisão.
func enfeite_m(arquivo: String, pos: Vector3, escala := 1.0, giro := 0.0) -> Node3D:
	return peca_de(MASMORRA, arquivo, pos, giro, escala, false)


## O Ossinho mineiro, amigo desde a Parte 1, acenando na entrada (só enfeite, com um corpo para não
## atravessar).
func _ossinho(pos: Vector3, giro: float) -> void:
	var rig: Node3D = _cena("res://assets/characters/skeletons/Skeleton_Minion.glb").instantiate()
	rig.position = pos
	rig.rotation.y = giro
	add_child(rig)
	var ap := AnimUtil.make_player(rig, ["festa"])
	ap.play(&"festa/Waving")
	_muro(pos, Vector3(0.9, 2.0, 0.9))
