class_name Fase12
extends Fase
## 1-2 Túneis do Morro (Mundo 1, a porta do leste no térreo do farol). As Bolotas esconderam a segunda
## Estrela Grande na mina velha dos Ossinhos, por baixo do Morro dos Ventos, e as tochas que os esqueletos
## deixaram estão apagadas. Fase do chão, no escuro azulado da caverna, com as peças do Dungeon Pack em
## 1,5x (módulos de 6 m) e sem teto: em cima, o escuro faz a vez da rocha e a câmera fica solta.
## Novidades: tochas que o laser acende (clareiam; três abrem a porta; as do abismo sobem a ponte),
## paredes rachadas que três golpes quebram e elevadores de madeira. Plano na seção 11 do docs/ILHA-CAFUNE.md.
## O caminho vai para -Z, subindo em quatro níveis (chão a 0, 8, 16 e 28 m). Em 2026-10-29 o usuário achou a
## fase muito curta (uns 200 m) e ela ganhou cinco trechos novos (marcados com *), passando de uns 380 m:
##   1 Boca do túnel (o Ossinho acena)  2 Corredor das tochas (V1 atrás da parede rachada)
##   3 Poço dos andaimes (V2 numa viga alta)  4 Abismo: as tochas sobem a ponte (P1 antes; V3 embaixo)
##   5 Mina de ouro (P2)  *6 Carrinho de mina (P3 na chegada)  *7 Sala escura  8 Elevadores
##   9 Porta das três tochas  *10 Alavancas  *11 Poço dos cristais  *12 Arena da Bolotona (P4)
##   13 Câmara do Baú

## Escala das peças de construção e o tamanho de um módulo.
const S := 1.5
const M := 6.0
const COR_ROCHA := Color("3b3550")
const COR_MADEIRA := Color("7a4a2a")
## Altura das paredes invisíveis acima das que se veem.
const LIMITE := 16.0

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
	inicio = Vector3(0, 0.1, 2.5)
	limite_queda = -6.0
	_mat_rocha = _material(COR_ROCHA)
	_mat_rocha.roughness = 1.0
	_paredes = StaticBody3D.new()
	add_child(_paredes)
	_limites = StaticBody3D.new()
	_limites.collision_layer = CAMADA_LIMITE
	_limites.collision_mask = 0
	add_child(_limites)
	_boca_do_tunel()
	_corredor_das_tochas()
	_poco_dos_andaimes()
	_abismo()
	_mina_de_ouro()
	_carrinho_de_mina()
	_sala_escura()
	_elevadores()
	_porta_das_tres_tochas()
	_alavancas()
	_poco_dos_cristais()
	_arena_da_bolotona()
	_camara_do_bau()


## 1. Logo depois da entrada: atrás, o arco claro da saída com a luz do dia; na frente, o Ossinho mineiro
## acenando, barris, caixotes, a trilha de estrelinhas e uma Bolota dormindo.
func _boca_do_tunel() -> void:
	rocha(-15.0, 15.0, 7.5, -66.0, 0.0, -2.0)
	chao([-3.0, 3.0], 3.0, -3.0, 0.0)
	parede_z(6.75, 3.0, -39.0, 0.0)
	parede_z(-6.75, 3.0, -21.0, 0.0)
	parede_z(-6.75, -33.0, -39.0, 0.0)
	# A entrada: o vão sem a porta, com a claridade lá fora (fechado por uma parede invisível).
	var vao := peca_de(MASMORRA, "wall_doorway", Vector3(0, 0, 6.75), PI, S, false)
	vao.find_child("wall_doorway_door", true, false).queue_free()
	peca_de(MASMORRA, "wall_half", Vector3(3.0, 0, 6.75), 0.0, S, false)
	peca_de(MASMORRA, "wall_half", Vector3(-3.0, 0, 6.75), PI, S, false)
	_muro(Vector3(0, 0, 6.75), Vector3(12.0, M, 1.5))
	var dia := MeshInstance3D.new()
	var quadro := QuadMesh.new()
	quadro.size = Vector2(6.0, 6.0)
	dia.mesh = quadro
	var claro := StandardMaterial3D.new()
	claro.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	claro.albedo_color = Color("e4f3ff")
	dia.material_override = claro
	dia.position = Vector3(0, 3.0, 7.8)
	dia.rotation.y = PI
	add_child(dia)
	var luz_do_dia := OmniLight3D.new()
	luz_do_dia.light_color = Color("cfe6ff")
	luz_do_dia.light_energy = 2.5
	luz_do_dia.omni_range = 13.0
	luz_do_dia.position = Vector3(0, 3.5, 5.0)
	add_child(luz_do_dia)
	_ossinho(Vector3(-3.4, 0, -3.0), 0.5)
	enfeite_m("barrel_large", Vector3(-4.8, 0, 4.6))
	enfeite_m("barrel_small_stack", Vector3(4.6, 0, 4.8), 1.2, 0.4)
	enfeite_m("crates_stacked", Vector3(4.7, 0, -1.6), 1.2, -0.3)
	enfeite_m("bucket_pickaxes", Vector3(-4.9, 0, 1.4), 1.2, 0.8)
	trilha(Vector3(0, 1.0, 0.0), Vector3(0, 1.0, -7.0), 4)
	bolota(Vector3(2.3, 0, -4.6), true)


## 2. Corredor de mina com andaimes atravessados, cada vez mais escuro. A primeira tocha apagada fica no
## caminho (o Vovô mostra o laser na tocha); a parede rachada da esquerda esconde o V1 num nicho com velas.
func _corredor_das_tochas() -> void:
	chao([-3.0, 3.0], -9.0, -39.0, 0.0)
	for z in [-6.0, -18.0, -30.0]:
		peca_de(MASMORRA, "scaffold_pillars_connected", Vector3(0, 0, z), 0.0, Vector3(12.6 / 7.0, S, S), false)
		for lado in [-1.0, 1.0]:
			_muro(Vector3(5.6 * lado, 0, z), Vector3(0.6, 5.4, 0.6), false)
	ponto_de_dica(Vector3(0, 0.5, -7.5), 3.0, "tocha")
	tocha(Vector3(-3.6, 0, -11.0))
	tocha(Vector3(3.8, 0, -21.0))
	tocha(Vector3(-3.8, 0, -35.0))
	tocha(Vector3(3.8, 0, -40.0))
	trilha(Vector3(0, 1.0, -12.0), Vector3(0, 1.0, -21.0), 4)
	bolota(Vector3(-2.0, 0, -17.0))
	bolota(Vector3(2.4, 0, -32.0))
	# A parede rachada e o nicho atrás dela.
	parede_rachada(Vector3(-6.75, 0, -27.0), PI / 2.0)
	_muro(Vector3(-6.75, M, -27.0), Vector3(1.5, LIMITE, 6.0), true)
	ponto_de_dica(Vector3(-3.4, 0.5, -27.0), 2.6, "golpe")
	chao([-10.5], -27.0, -27.0, 0.0)
	parede_z(-14.25, -27.0, -27.0, 0.0, 1, "wall_inset_candles", PI / 2.0)
	parede_x(-23.25, [-10.5], 0.0)
	parede_x(-30.75, [-10.5], 0.0)
	var velas := OmniLight3D.new()
	velas.light_color = Color("ffc070")
	velas.light_energy = 1.2
	velas.omni_range = 5.0
	velas.position = Vector3(-12.0, 2.5, -27.0)
	add_child(velas)
	vaga_lume(Vector3(-10.4, 1.2, -27.0))
	trilha(Vector3(-9.0, 1.0, -25.5), Vector3(-9.0, 1.0, -28.5), 2)
	trilha(Vector3(0, 1.0, -25.0), Vector3(0, 1.0, -38.0), 5)
	enfeite_m("rocks", Vector3(-4.7, 0, -15.6), 1.3, 1.0)
	enfeite_m("rubble_half", Vector3(4.6, 0, -26.0), 1.0, PI / 2.0)
	enfeite_m("barrel_small", Vector3(4.9, 0, -34.0), 1.2)
	enfeite_m("box_large", Vector3(-4.9, 0, -39.5), 1.2, 0.3)


## 3. Salão alto: tablados de andaime sobem 1,6 m de cada vez (um de frente para o outro) até a passarela
## da beirada, a 8 m, onde ficam o P1 e a primeira tocha da ponte. Uma mola no chão, ao lado da passarela,
## é atalho; outra, no canto, leva à viga do V2.
func _poco_dos_andaimes() -> void:
	chao([-9.0, -3.0, 3.0, 9.0], -45.0, -63.0, 0.0)
	parede_x(-42.75, [-9.0, 9.0], 0.0, 2)
	parede_z(12.75, -45.0, -63.0, 0.0, 2)
	parede_z(-12.75, -45.0, -63.0, 0.0, 2)
	parede_x(-66.75, [-9.0, 9.0], 0.0, 2)
	# A beirada (o chão do abismo começa aqui, a 8 m).
	rocha(-6.0, 6.0, -66.0, -72.0, 8.0)
	chao([-3.0, 3.0], -69.0, -69.0, 8.0)
	parede_z(6.75, -69.0, -69.0, 8.0)
	parede_z(-6.75, -69.0, -69.0, 8.0)
	# Um tablado de frente para o outro (sem precisar acertar de lado); o último é uma passarela até a beirada.
	tablado(Vector3(6.0, 1.6, -47.0), Vector2(4, 4))
	tablado(Vector3(6.0, 3.2, -52.5), Vector2(4, 4))
	tablado(Vector3(0.5, 4.8, -52.5), Vector2(4, 4))
	tablado(Vector3(-5.0, 6.4, -52.5), Vector2(4, 4))
	tablado(Vector3(-5.0, 8.0, -61.0), Vector2(4, 10))
	for t in [Vector3(6.0, 1.6, -47.0), Vector3(6.0, 3.2, -52.5), Vector3(0.5, 4.8, -52.5), Vector3(-5.0, 6.4, -52.5), Vector3(-5.0, 8.0, -59.0)]:
		estrelinha(t + Vector3(0, 1.0, 0))
	mola(Vector3(-9.6, 0, -60.0), 21.0)
	# V2: numa viga lá no alto do canto; a mola do canto joga até ela.
	mola(Vector3(9.0, 0, -64.0), 22.0)
	tablado(Vector3(9.0, 9.0, -59.5), Vector2(3, 3), 0.0, false)
	vaga_lume(Vector3(9.0, 10.2, -59.5))
	bolota(Vector3(2.5, 0, -49.0))
	bolota(Vector3(-3.0, 0, -61.0))
	enfeite_m("crates_stacked", Vector3(-10.4, 0, -45.6), 1.3, 0.5)
	enfeite_m("barrel_large", Vector3(10.6, 0, -45.2))
	enfeite_m("rocks_decorated", Vector3(-10.2, 0, -63.4), 1.2, 2.0)
	tocha(Vector3(-10.4, 0, -54.0), true, true)
	posto(Vector3(-3.5, 8.0, -69.0))


## 4. O abismo, escuro e sem ponte. Três tochas em linha (na beirada e em cima de dois pilares): cada uma
## acesa sobe a ponte de tábuas até a próxima. Os vãos têm 13 e 14 m: com o voo de 1 s, o pulo mais longo
## flutuando chega a uns 12 m. Embaixo da
## última ponte, numa beiradinha da parede, o V3, com uma mola para voltar.
func _abismo() -> void:
	parede_z(6.75, -75.0, -117.0, -4.0, 3)
	parede_z(-6.75, -75.0, -117.0, -4.0, 3)
	var t1 := tocha(Vector3(2.6, 8.0, -70.6))
	ponte_da_tocha(t1, Vector3(0, 8.0, -72.0), Vector3(0, 8.0, -86.0))
	rocha(-2.5, 2.5, -86.0, -90.0, 8.0)
	chao_pedaco(Vector3(0, 8.0, -88.0), Vector2(5.0, 4.0))
	var t2 := tocha(Vector3(1.4, 8.0, -88.6))
	ponte_da_tocha(t2, Vector3(0, 8.0, -90.0), Vector3(0, 8.0, -104.0))
	rocha(-2.5, 2.5, -104.0, -107.0, 8.0)
	chao_pedaco(Vector3(0, 8.0, -105.5), Vector2(5.0, 3.0))
	var t3 := tocha(Vector3(1.4, 8.0, -105.6))
	ponte_da_tocha(t3, Vector3(0, 8.0, -107.0), Vector3(0, 8.0, -120.0))
	# As estrelinhas desenham o caminho por cima do escuro (de longe, mostram para onde a ponte vai).
	trilha(Vector3(0, 9.0, -74.0), Vector3(0, 9.0, -84.0), 3)
	trilha(Vector3(0, 9.0, -92.0), Vector3(0, 9.0, -102.0), 3)
	trilha(Vector3(0, 9.0, -109.0), Vector3(0, 9.0, -118.0), 3)
	rocha(-6.0, -2.4, -113.0, -117.0, 2.0, -1.0)
	vaga_lume(Vector3(-4.6, 3.2, -114.1))
	mola(Vector3(-3.4, 2.0, -116.1), 19.0)
	# Lá no fundo, cristais azuis apagadinhos dão a ideia de fundura.
	var cristal := _material(Color("5fd0ff"))
	cristal.emission_enabled = true
	cristal.emission = Color("2fa8ff")
	cristal.emission_energy_multiplier = 1.6
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 12
	for i in 18:
		var mi := MeshInstance3D.new()
		mi.mesh = Forma.superelipsoide(Vector3(0.3, 0.9, 0.3) * sorteio.randf_range(0.7, 1.6), 0.6, 1.0)
		mi.material_override = cristal
		mi.position = Vector3(sorteio.randf_range(-5.0, 5.0), -16.0 + sorteio.randf_range(-1.0, 1.0), sorteio.randf_range(-74.0, -118.0))
		mi.rotation = Vector3(sorteio.randf_range(-0.4, 0.4), 0, sorteio.randf_range(-0.4, 0.4))
		add_child(mi)
	var fundo := OmniLight3D.new()
	fundo.light_color = Color("4aa8ff")
	fundo.light_energy = 2.0
	fundo.omni_range = 24.0
	fundo.position = Vector3(0, -12.0, -96.0)
	add_child(fundo)


## 5. Caverna larga da mina de ouro, a 8 m: P2, pedras de ouro, baldes com picaretas, caixotes, três
## Bolotas acordadas, um coração extra e duas tochas que os Ossinhos deixaram acesas.
func _mina_de_ouro() -> void:
	rocha(-13.5, 13.5, -120.0, -162.0, 8.0)
	chao([-9.0, -3.0, 3.0, 9.0], -123.0, -147.0, 8.0)
	parede_x(-119.25, [-9.0, 9.0], 8.0)
	parede_z(12.75, -123.0, -147.0, 8.0)
	parede_z(-12.75, -123.0, -147.0, 8.0)
	parede_x(-150.75, [-9.0, 9.0], 8.0)
	posto(Vector3(-7.5, 8.0, -124.5))
	tocha(Vector3(-10.6, 8.0, -128.0), true, true)
	tocha(Vector3(10.6, 8.0, -140.0), true, true)
	tocha(Vector3(-10.4, 8.0, -148.0))
	for x in [-6.0, 6.0]:
		peca_de(MASMORRA, "pillar", Vector3(x, 8.0, -135.0), 0.0, S, false)
		_muro(Vector3(x, 8.0, -135.0), Vector3(2.2, M, 2.2), false)
	enfeite_m("rocks_gold", Vector3(-9.6, 8.0, -134.0), 1.3, 0.6)
	enfeite_m("rocks_gold", Vector3(9.8, 8.0, -131.0), 1.2, 2.0)
	enfeite_m("rocks_gold", Vector3(-9.4, 8.0, -144.5), 1.1, 3.6)
	enfeite_m("rocks_decorated", Vector3(10.0, 8.0, -146.5), 1.0, 1.0)
	enfeite_m("bucket_pickaxes", Vector3(-8.2, 8.0, -132.0), 1.2, 0.4)
	enfeite_m("bucket_pickaxes", Vector3(8.6, 8.0, -134.6), 1.2, 2.4)
	enfeite_m("pickaxe", Vector3(-7.6, 8.05, -145.0), 1.3, 1.2)
	enfeite_m("crates_stacked", Vector3(10.4, 8.0, -122.6), 1.2, 0.2)
	enfeite_m("keg", Vector3(-10.5, 8.0, -138.5), 1.1, 0.5)
	enfeite_m("barrel_large", Vector3(4.6, 8.0, -148.0), 1.0)
	bolota(Vector3(4.0, 8.0, -129.0))
	bolota(Vector3(-4.5, 8.0, -137.0))
	bolota(Vector3(5.0, 8.0, -143.0))
	coracao(Vector3(10.0, 9.0, -143.0))
	trilha(Vector3(0, 9.0, -122.0), Vector3(0, 9.0, -131.0), 4)
	arco(Vector3(-1.0, 9.0, -133.0), Vector3(-1.0, 9.0, -138.0), 1.6, 3)
	roda(Vector3(-9.6, 10.6, -134.0), 1.2, 3)
	trilha(Vector3(0, 9.0, -141.0), Vector3(0, 9.0, -147.0), 3)


## 6*. Carrinho de Mina: na estação, o carrinho espera nos trilhos, com uma estrelinha em cima chamando e um
## caixote de degrau. Pulando dentro, ele leva o Faísca por um túnel de 60 m, clareado por tochas acesas; as
## estrelinhas ficam no ar em cima dos trilhos (as mais altas pedem pulo, e pulando ele continua indo junto).
## Na estação de chegada, o P3.
func _carrinho_de_mina() -> void:
	rocha(-7.5, 7.5, -162.0, -228.0, 8.0)
	chao([-3.0, 3.0], -153.0, -225.0, 8.0)
	parede_z(6.75, -153.0, -225.0, 8.0)
	parede_z(-6.75, -153.0, -225.0, 8.0)
	carrinho(Vector3(0, 8.0, -157.0), Vector3(0, 8.0, -219.0))
	caixote(Vector3(-2.4, 8.0, -155.0), Vector3(1.2, 0.7, 1.2))
	estrelinha(Vector3(0, 10.4, -157.0))
	for i in 9:
		estrelinha(Vector3(0, 12.2 if i % 3 == 2 else 10.1, -165.0 - i * 6.5))
	var madeira := _material(COR_MADEIRA)
	for z in [-170.0, -185.0, -200.0, -215.0]:
		var viga := MeshInstance3D.new()
		var caixa := BoxMesh.new()
		caixa.size = Vector3(13.5, 0.5, 0.6)
		viga.mesh = caixa
		viga.material_override = madeira
		viga.position = Vector3(0, 8.0 + 5.8, z)
		add_child(viga)
	for spec in [[Vector3(-5.2, 8.0, -156.0)], [Vector3(5.2, 8.0, -177.0)], [Vector3(-5.2, 8.0, -198.0)], [Vector3(5.2, 8.0, -212.0)], [Vector3(-5.2, 8.0, -221.0)]]:
		tocha(spec[0], true, true)
	# Chegada: o P3 e o batente no fim dos trilhos.
	posto(Vector3(3.6, 8.0, -221.5))
	caixote(Vector3(0, 8.0, -222.8), Vector3(2.6, 0.9, 0.8))
	enfeite_m("crates_stacked", Vector3(-5.0, 8.0, -160.0), 1.2, 0.3)
	enfeite_m("barrel_large", Vector3(5.0, 8.0, -159.0), 1.0)
	enfeite_m("crates_stacked", Vector3(5.0, 8.0, -224.0), 1.1, 1.4)


## 7*. Sala Escura: no fundo da mina, a luz da caverna quase apaga quando o Faísca entra. O caminho é uma
## passarela de tábuas em zigue-zague em cima de um buraco, com uma tocha apagada em cada curva: acesa com o
## laser, ela clareia o pedaço seguinte. Cair no buraco volta no P3.
func _sala_escura() -> void:
	rocha(-7.5, 7.5, -228.0, -231.0, 8.0)
	chao_pedaco(Vector3(0, 8.0, -229.5), Vector2(13.5, 3.0))
	for x in [-7.5, 6.0]:
		rocha(x, x + 1.5, -231.0, -249.0, 8.0)
	parede_z(6.75, -231.0, -249.0, 8.0)
	parede_z(-6.75, -231.0, -249.0, 8.0)
	# Passarela: frente pela esquerda, atravessa, frente pela direita, atravessa de novo e sai pela esquerda.
	var trechos := [[Vector3(-3.0, 8.0, -233.5), Vector2(3.0, 5.0)], [Vector3(0, 8.0, -237.5), Vector2(9.0, 3.0)],
		[Vector3(3.0, 8.0, -241.5), Vector2(3.0, 5.0)], [Vector3(0, 8.0, -245.5), Vector2(9.0, 3.0)],
		[Vector3(-3.0, 8.0, -248.0), Vector2(3.0, 2.0)]]
	for t in trechos:
		tablado(t[0], t[1], -6.0, false)
	for p in [Vector3(-3.9, 8.0, -238.2), Vector3(3.9, 8.0, -236.8), Vector3(3.9, 8.0, -246.2), Vector3(-3.9, 8.0, -244.8)]:
		tocha(p)
	trilha(Vector3(-3.0, 9.0, -232.0), Vector3(-3.0, 9.0, -235.0), 2)
	trilha(Vector3(-1.5, 9.0, -237.5), Vector3(1.5, 9.0, -237.5), 2)
	trilha(Vector3(3.0, 9.0, -240.0), Vector3(3.0, 9.0, -243.0), 2)
	trilha(Vector3(1.5, 9.0, -245.5), Vector3(-1.5, 9.0, -245.5), 2)
	ponto_de_dica(Vector3(0, 8.5, -229.5), 2.4, "tocha")
	# Escurece só aqui dentro.
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = CAMADA_JOGADOR
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(13.5, 22.0, 19.0)
	cs.shape = caixa
	cs.position = Vector3(0, 5.0, -240.0)
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


## 8. O poço dos elevadores: duas plataformas de madeira sobem e descem 8 m, com estrelinhas no caminho,
## até a beirada da porta, a 16 m.
func _elevadores() -> void:
	rocha(-7.5, 7.5, -249.0, -264.0, 8.0)
	chao([-3.0, 3.0], -252.0, -258.0, 8.0)
	parede_z(6.75, -252.0, -261.0, 8.0, 2)
	parede_z(-6.75, -252.0, -261.0, 8.0, 2)
	elevador(Vector3(-3.0, 8.0, -261.5), 8.0, 6.0, 0.0)
	elevador(Vector3(3.0, 8.0, -261.5), 8.0, 6.0, 3.0)
	trilha(Vector3(-3.0, 11.0, -261.5), Vector3(-3.0, 15.0, -261.5), 3)


## 9. A sala da porta, a 16 m: três tochas apagadas, uma em cima de caixotes altos (pulo alto e depois
## flutuar por cima dela). Com as três acesas, a porta de madeira abre.
func _porta_das_tres_tochas() -> void:
	rocha(-6.0, 6.0, -264.0, -330.0, 16.0, 8.0)
	chao([-3.0, 3.0], -267.0, -285.0, 16.0, "floor_tile_large")
	parede_z(6.75, -267.0, -327.0, 16.0)
	parede_z(-6.75, -267.0, -327.0, 16.0)
	var ta := tocha(Vector3(-3.8, 16.0, -271.0))
	var tb := tocha(Vector3(3.8, 16.0, -275.5))
	# Os caixotes: um degrau de 1,6 m e a pilha de 3 m com a tocha em cima.
	caixote(Vector3(-1.4, 16.0, -280.0), Vector3(1.8, 1.6, 1.8))
	caixote(Vector3(-3.6, 16.0, -280.5), Vector3(2.6, 3.0, 2.6))
	var tc := tocha(Vector3(-4.2, 19.0, -281.1), false)
	porta_das_tochas(Vector3(0, 16.0, -288.75), 0.0, [ta, tb, tc])
	_lados_da_porta(-288.75, 16.0)
	bolota(Vector3(3.0, 16.0, -283.0))
	trilha(Vector3(0, 17.0, -266.5), Vector3(0, 17.0, -276.0), 3)
	estrelinha(Vector3(-1.4, 18.6, -280.0))
	estrelinha(Vector3(-3.0, 20.0, -279.9))


## Meias paredes e colisões dos dois lados de uma porta de 3 m no meio de um corredor de 12 m.
func _lados_da_porta(z: float, y: float) -> void:
	peca_de(MASMORRA, "wall_half", Vector3(3.0, y, z), 0.0, S, false)
	peca_de(MASMORRA, "wall_half", Vector3(-3.0, y, z), PI, S, false)
	_muro(Vector3(4.5, y, z), Vector3(3.0, M, 1.5))
	_muro(Vector3(-4.5, y, z), Vector3(3.0, M, 1.5))
	_muro(Vector3(0, y + M, z), Vector3(12.0, LIMITE, 1.5), true)


## 10*. Alavancas: depois da porta, um corredor com três grades. Cada uma abre com um soco na alavanca dela: a
## primeira logo ao lado, a segunda em cima de um caixote (pula e soca lá de cima) e a terceira guardada por
## duas Bolotas.
func _alavancas() -> void:
	chao([-3.0, 3.0], -291.0, -327.0, 16.0, "floor_tile_large")
	ponto_de_dica(Vector3(0, 16.5, -292.0), 2.4, "alavanca")
	portao_de_grade(Vector3(0, 16.0, -297.75), 0.0, Vector3(-3.6, 16.0, -294.0), "yellow")
	_lados_da_porta(-297.75, 16.0)
	caixote(Vector3(3.6, 16.0, -304.0), Vector3(2.2, 2.0, 2.2))
	portao_de_grade(Vector3(0, 16.0, -309.75), 0.0, Vector3(3.6, 18.0, -304.0), "red")
	_lados_da_porta(-309.75, 16.0)
	bolota(Vector3(-3.0, 16.0, -303.5), true)
	trilha(Vector3(0, 17.0, -300.0), Vector3(0, 17.0, -307.0), 3)
	estrelinha(Vector3(3.6, 19.2, -304.0))
	portao_de_grade(Vector3(0, 16.0, -321.75), 0.0, Vector3(-3.6, 16.0, -318.0), "blue")
	_lados_da_porta(-321.75, 16.0)
	bolota(Vector3(2.4, 16.0, -314.5))
	bolota(Vector3(-1.0, 16.0, -319.0))
	coracao(Vector3(4.6, 17.0, -319.5))
	trilha(Vector3(0, 17.0, -312.0), Vector3(0, 17.0, -318.0), 3)
	tocha(Vector3(5.0, 16.0, -292.0), true, true)
	tocha(Vector3(-5.0, 16.0, -312.0), true, true)


## 11*. Poço dos Cristais: um poço alto de 16 a 28 m. Os cristais azuis jogam para o alto como molas: do chão
## para a beirada da direita, dela para a da esquerda e dela para a arena, lá em cima. As estrelinhas
## mostram o caminho de cada pulo.
func _poco_dos_cristais() -> void:
	rocha(-6.0, 6.0, -330.0, -345.0, 16.0, 8.0)
	chao([-3.0, 3.0], -333.0, -339.0, 16.0, "floor_tile_large")
	parede_z(6.75, -333.0, -345.0, 16.0, 3)
	parede_z(-6.75, -333.0, -345.0, 16.0, 3)
	tablado(Vector3(4.0, 21.0, -337.0), Vector2(3.5, 4.0), 16.0, false)
	tablado(Vector3(-4.0, 25.0, -341.5), Vector2(3.5, 4.0), 16.0, false)
	mola_de_cristal(Vector3(-3.0, 16.0, -335.0), 19.0)
	mola_de_cristal(Vector3(4.0, 21.0, -338.0), 19.0)
	mola_de_cristal(Vector3(-4.0, 25.0, -342.5), 15.0)
	arco(Vector3(-3.0, 19.0, -335.0), Vector3(4.0, 22.5, -337.0), 3.0, 3)
	arco(Vector3(4.0, 24.0, -338.0), Vector3(-4.0, 26.5, -341.5), 3.0, 3)
	trilha(Vector3(-4.0, 28.5, -343.0), Vector3(-2.0, 29.5, -346.0), 2)


## 12*. Arena da Bolotona, a 28 m: o P4 na entrada e a Bolotona dormindo no meio. Derrotada, ela se desfaz em
## três Bolotas pequenas; vencidas todas, a grade do fundo abre para a câmara do baú.
func _arena_da_bolotona() -> void:
	rocha(-9.75, 9.75, -345.0, -372.0, 28.0, 16.0)
	chao([-6.0, 0.0, 6.0], -348.0, -366.0, 28.0, "floor_tile_large")
	parede_z(9.75, -348.0, -366.0, 28.0)
	parede_z(-9.75, -348.0, -366.0, 28.0)
	parede_x(-345.0, [-9.0, 9.0], 28.0)
	posto(Vector3(-5.5, 28.0, -349.0))
	var grande := bolotona(Vector3(0, 28.0, -358.0))
	for b in [grande] + grande.filhas:
		b.derrotada.connect(func(_a: Alvo) -> void: _ver_arena(grande))
	coracao(Vector3(7.0, 29.0, -365.0))
	roda(Vector3(0, 28.9, -358.0), 5.5, 6)
	for p in [Vector3(-8.2, 28.0, -347.5), Vector3(8.2, 28.0, -347.5), Vector3(-8.2, 28.0, -367.5), Vector3(8.2, 28.0, -367.5)]:
		tocha(p, true, true)
	peca_de(MASMORRA, "wall_doorway", Vector3(0, 28.0, -369.75), 0.0, S, false).find_child("wall_doorway_door", true, false).queue_free()
	_grade_da_arena = Grade.new()
	_grade_da_arena.position = Vector3(0, 28.0, -369.75)
	add_child(_grade_da_arena)
	grades.append(_grade_da_arena)
	_lados_da_porta(-369.75, 28.0)
	parede_x(-369.75, [-9.0, 9.0], 28.0)


func _ver_arena(grande: Bolotona) -> void:
	if bolotona_vencida(grande):
		_grade_da_arena.abrir()


## 13. A câmara do baú dourado, com duas tochas acesas no fundo (os guardas agora são a Bolotona).
func _camara_do_bau() -> void:
	rocha(-6.0, 6.0, -372.0, -390.0, 28.0, 16.0)
	chao([-3.0, 3.0], -375.0, -387.0, 28.0, "floor_tile_large")
	parede_z(6.75, -375.0, -387.0, 28.0)
	parede_z(-6.75, -375.0, -387.0, 28.0)
	parede_x(-390.75, [-3.0], 28.0, 1, "wall_inset_candles")
	parede_x(-390.75, [3.0], 28.0, 1, "wall_inset_candles")
	colocar_bau(Vector3(0, 28.0, -384.0), 0.0, true)
	roda(Vector3(0, 28.9, -384.0), 3.4, 3)
	tocha(Vector3(-4.6, 28.0, -388.8), true, true)
	tocha(Vector3(4.6, 28.0, -388.8), true, true)


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


## Plataforma de madeira que sobe `subida` metros e volta, a cada `periodo` segundos.
func elevador(topo: Vector3, subida: float, periodo: float, atraso: float) -> AnimatableBody3D:
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
	_moveis.append([corpo, corpo.position, Vector3(0, subida, 0), periodo, atraso])
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
