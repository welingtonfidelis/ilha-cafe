class_name Fase21
extends Fase
## 2-1 Cozinha Gigante (Mundo 2, Doces e Brinquedos; a porta do 2º andar do farol, que pede 60 estrelinhas). As
## Bolotas levaram a terceira Estrela Grande para a cozinha de uma casa de gigantes, e o Faísca fica
## pequenininho entre panelas, pratos e potes: tudo do Restaurant Bits ampliado 8 vezes (a bancada tem 8 m, o
## prato 7,6 m, a geladeira 20 m). O chão xadrez lá embaixo é "o chão é lava": cair nele é cair (volta no posto).
## Novidade: as tampas das panelas que pulam (levam para o alto no tempo delas).
## Refeita em 2026-10-29 no padrão de playgrounds (docs/level-design/molde-das-fases.html): a geladeira fica no
## meio da cozinha (o marco, com o brilho do baú em cima) e os móveis em volta são os quatro playgrounds.
##   1 Mesa do Café (ao sul): pratos de degrau, a tigela, a caixa de cereal e a primeira tampa, sem risco
##   viagem: ponte de tábuas de cortar
##   2 Bancada das Panelas (a oeste): rolos de macarrão, o vão com a tampa que joga até a prateleira do V1 (P1)
##   viagem: o prato que leva e traz
##   3 Fogão e Pizza (ao norte): a pizza que gira com as Bolotas, as bocas do fogão, a tampa que joga até os livros
##     do V2 e o coração (P2)
##   viagem: o prato que vai e volta por trás da geladeira (atalho)
##   4 Pia e Prateleira (a leste): pratos boiando e bolhas na pia, bolhas de degrau até a prateleira, o V3 atrás da
##     geladeira e o sorvete que joga lá para cima (P3)
##   Arena em cima da geladeira (20 m): o baú e duas Bolotas

const K := 8.0
const COR_PAREDE := Color("f3e2c7")
const COR_ACO := Color("c6ccd8")
const COR_ARMARIO := Color("8fc6c0")
const COR_MADEIRA := Color("c58a52")
## O marco: o meio de baixo da geladeira (o tampo dela, a 20 m, vai de x -8 a 8 e de z -78 a -62).
const GELADEIRA := Vector3(0, 0, -70)


func _montar() -> void:
	nome = "2-1 Cozinha Gigante"
	inicio = Vector3(0, 8.1, -15)
	limite_queda = 3.0
	_sala()
	_mesa_do_cafe()
	_ponte_de_tabuas()
	_bancada_das_panelas()
	_prato_que_leva()
	_fogao_e_pizza()
	_prato_atras_da_geladeira()
	_pia_e_prateleira()
	_em_cima_da_geladeira()


## A cozinha: o chão xadrez lá embaixo, as paredes de longe, a janela com o sol e a geladeira no meio.
func _sala() -> void:
	for i in 4:
		for j in 5:
			cozinha("floor_kitchen", Vector3(-48 + i * 32, 0, -10 - j * 32), PI / 2.0 * ((i + j) % 2), K, false)
	_parede(Vector3(-64, 0, -60), Vector3(2, 46, 136), COR_PAREDE)
	_parede(Vector3(64, 0, -60), Vector3(2, 46, 136), COR_PAREDE)
	_parede(Vector3(0, 0, -127), Vector3(130, 46, 2), COR_PAREDE)
	_parede(Vector3(0, 0, 7), Vector3(130, 46, 2), COR_PAREDE)
	# Rodapé e azulejos (faixas de cor) nas paredes compridas.
	for x in [-62.9, 62.9]:
		_parede(Vector3(x, 0, -60), Vector3(0.3, 3, 136), Color("c58a52"), false)
		_parede(Vector3(x, 14, -60), Vector3(0.3, 10, 136), Color("cde9f2"), false)
	# Janela grande com a luz do dia, na parede da direita.
	var janela := MeshInstance3D.new()
	var plano := QuadMesh.new()
	plano.size = Vector2(60, 22)
	janela.mesh = plano
	var luz_da_janela := StandardMaterial3D.new()
	luz_da_janela.albedo_color = Color("dff3ff")
	luz_da_janela.emission_enabled = true
	luz_da_janela.emission = Color("dff3ff")
	luz_da_janela.emission_energy_multiplier = 1.4
	janela.material_override = luz_da_janela
	janela.position = Vector3(62.8, 26, -40)
	janela.rotation.y = -PI / 2.0
	add_child(janela)
	cozinha("fridge_A", GELADEIRA)


func _parede(base: Vector3, tamanho: Vector3, cor: Color, solida := true) -> void:
	var mi := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = tamanho
	mi.mesh = caixa
	mi.material_override = _material(cor)
	mi.position = base + Vector3.UP * tamanho.y * 0.5
	add_child(mi)
	if solida:
		var corpo := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = tamanho
		cs.shape = forma
		cs.position = mi.position
		corpo.add_child(cs)
		add_child(corpo)


## Caixa sólida com o pé em `base` (bancadas feitas por código, como a da pia).
func bloco(base: Vector3, tamanho: Vector3, cor: Color) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = base + Vector3.UP * tamanho.y * 0.5
	var mi := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = tamanho
	mi.mesh = caixa
	mi.material_override = _material(cor)
	corpo.add_child(mi)
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tamanho
	cs.shape = forma
	corpo.add_child(cs)
	add_child(corpo)
	return corpo


## Playground 1 · Mesa do Café (apresenta): a mesa grande (30 x 20 m), sem risco nenhum fora da beirada. Pratos de
## degrau, a tigela com estrelinhas dentro, a caixa de cereal (pulo alto) e a primeira tampa que pula, com a roda
## de estrelinhas lá em cima. O vidro de ketchup é o mini-marco; uma Bolota dorme.
func _mesa_do_cafe() -> void:
	playground("1 · Mesa do Café", Vector3(0, 8.0, -22.0), 16.0, inicio)
	cozinha("kitchentable_A_large", Vector3(0, 0, -22), 0.0, Vector3(10.0, K, 10.0))
	cozinha("plate", Vector3(-8, 8, -17))
	estrelinha(Vector3(-8, 10.0, -17))
	cozinha("bowl", Vector3(9, 8, -15.5))
	for p in [Vector3(8.0, 9.2, -15.0), Vector3(10.0, 9.2, -15.0), Vector3(9.0, 9.2, -16.6)]:
		estrelinha(p)
	bloco(Vector3(-10, 8, -29), Vector3(6, 1.2, 5), Color("f2b134"))
	bloco(Vector3(-10, 9.2, -29), Vector3(6.05, 0.4, 5.05), Color("e2553f"))
	estrelinha(Vector3(-11.5, 11.0, -29))
	estrelinha(Vector3(-8.5, 11.0, -29))
	panela_com_tampa(Vector3(7.0, 8.0, -28.0), 18.0, 0.0)
	ponto_de_dica(Vector3(5.0, 8.5, -23.5), 3.0, "tampa")
	roda(Vector3(7.0, 15.5, -28.0), 1.6, 4)
	cozinha("ketchup", Vector3(13, 8, -30.5), 0.3, K)
	cozinha("jar_D_large", Vector3(-12.5, 8, -13.5))
	bolota(Vector3(2.0, 8, -24.0), true)
	trilha_creme([Vector3(0, 8, -15), Vector3(-3, 8, -21), Vector3(-9, 8, -24.5), Vector3(-14.5, 8, -26)])
	trilha(Vector3(-1.5, 9.0, -19.0), Vector3(-8.0, 9.0, -24.5), 3)
	arco_de_saida(Vector3(-13.5, 8, -26), PI / 2.0, "red")
	for spec in [[Vector3(-4, 0, -6), PI], [Vector3(6, 0, -6), PI], [Vector3(-4, 0, -38), 0.0], [Vector3(6, 0, -38), 0.0]]:
		cozinha("chair_A", spec[0], spec[1], K)


## Viagem 1: duas tábuas de cortar, rentes ao tampo, da beirada da mesa até a bancada; um pote gigante segura o meio.
func _ponte_de_tabuas() -> void:
	cozinha("cuttingboard", Vector3(-20, 6.8, -26))
	cozinha("cuttingboard", Vector3(-25.5, 6.8, -26))
	cozinha("jar_A_large", Vector3(-22.5, 0, -26), 0.0, K * 6.8 / 6.0)
	trilha(Vector3(-16.5, 9.0, -26), Vector3(-29.0, 9.0, -26), 4)


## Playground 2 · Bancada das Panelas (desenvolve): três bancadas em L, a 8 m. Dois rolos de macarrão rolam de um
## lado para o outro (é pular por cima). No canto que falta, o vão: uma panela num banquinho, com a tampa rente
## ao tampo; quando ela pula, quem está em cima vai até a prateleira da parede, onde está o V1. Duas Bolotas.
func _bancada_das_panelas() -> void:
	playground("2 · Bancada das Panelas", Vector3(-46.0, 8.0, -34.0), 18.0, Vector3(-32.0, 8.0, -26.0))
	cozinha("kitchencounter_straight_A", Vector3(-38, 0, -26))
	cozinha("kitchencounter_straight_A", Vector3(-38, 0, -42.3))
	cozinha("kitchencounter_straight_A", Vector3(-54, 0, -42.3))
	posto(Vector3(-34.0, 8.0, -21.5))
	rolo(Vector3(-60.0, 8.0, -38.0), Vector3(26.0, 0, 0), 5.0, 0.0)
	rolo(Vector3(-60.0, 8.0, -46.5), Vector3(26.0, 0, 0), 6.0, 2.0)
	# Na bancada: o porco dispara pela bancada e o caranguejo guarda o canto com as garras.
	bolota(Vector3(-35.0, 8.0, -31.0), false, "porco")
	bolota(Vector3(-58.0, 8.0, -42.0), false, "caranguejo")
	# O vão do canto: a panela no banquinho e a prateleira com o V1.
	bloco(Vector3(-54, 0, -26), Vector3(7.0, 5.0, 5.0), COR_MADEIRA)
	panela_com_tampa(Vector3(-54.0, 5.0, -26.0), 23.0, 0.6)
	bloco(Vector3(-61, 15, -26), Vector3(6, 1, 16), COR_MADEIRA)
	for z in [-20.0, -32.0]:
		bloco(Vector3(-62.5, 12.5, z), Vector3(1.0, 2.5, 1.0), COR_MADEIRA)
	vaga_lume(Vector3(-61.0, 17.0, -30.0))
	roda(Vector3(-61.0, 17.0, -22.0), 1.4, 4)
	trilha(Vector3(-47.0, 10.0, -26.0), Vector3(-51.0, 11.0, -26.0), 2)
	trilha_creme([Vector3(-32, 8, -26), Vector3(-37, 8, -33), Vector3(-40, 8, -42), Vector3(-40, 8, -49.5)])
	trilha(Vector3(-36.0, 9.0, -30.0), Vector3(-40.0, 9.0, -48.0), 5)
	trilha(Vector3(-56.0, 9.0, -36.0), Vector3(-56.0, 9.0, -49.0), 3)
	cozinha("crate_tomatoes", Vector3(-58.5, 8.0, -48.5), 0.4, 2.5)
	cozinha("mustard", Vector3(-31.5, 8.0, -47.5), 0.2, 5.0)
	cozinha("rollingpin", Vector3(-50.0, 8.0, -36.0), 1.4, 3.0)
	arco_de_saida(Vector3(-40.0, 8.0, -49.0), 0.0, "green")


## Viagem 2: um prato grande vai e volta da ponta da bancada até a beirada da mesa da pizza.
func _prato_que_leva() -> void:
	movel_peca(COZINHA, "plate", K, Vector3(-40.0, 8.0, -54.1), Vector3(7.4, 0.8, 7.4), Vector3(0, 0, -12.1), 12.0, 0.0, true, 0.2)
	trilha(Vector3(-40.0, 9.5, -55.0), Vector3(-40.0, 9.5, -65.0), 3)


## Playground 3 · Fogão e Pizza (central): a mesa redonda com a pizza girando (as Bolotas vão junto) e, atrás dela,
## a bancada e o fogão encostados na parede. As bocas acendem e apagam; a tampa da bancada joga até a pilha de
## livros de receitas, onde está o V2. O coração fica na pizza.
func _fogao_e_pizza() -> void:
	playground("3 · Fogão e Pizza", Vector3(-38.0, 8.0, -90.0), 20.0, Vector3(-40.0, 8.0, -72.5))
	cozinha("table_round_A", Vector3(-38, 0, -82))
	# Afundada no tampo: em cima dela fica a 9,2 m, um degrau de pulo da beirada.
	pizza(Vector3(-38.0, 7.4, -82.0), 0.35, 6.0)
	posto(Vector3(-41.0, 8.0, -72.8))
	bolota(Vector3(-35.0, 9.2, -82.0), false, "cacto")
	bolota(Vector3(-40.0, 9.2, -85.0), false, "pinguim")
	coracao(Vector3(-38.0, 11.0, -82.0))
	roda(Vector3(-38.0, 11.2, -82.0), 3.8, 6)
	cozinha("ketchup", Vector3(-49.0, 8.0, -80.0), 0.0, 6.0)
	cozinha("mustard", Vector3(-27.5, 8.0, -78.0), 0.0, 6.0)
	cozinha("kitchencounter_straight_A", Vector3(-54, 0, -104))
	cozinha("kitchencounter_straight_A", Vector3(-38, 0, -104))
	cozinha("stove_multi", Vector3(-22, 0, -104))
	# O tampo do fogão fica a 8,8 m (o 1,2 do modelo conta os botões e o painel de trás).
	boca(Vector3(-25.6, 8.82, -98.9), 3.0, 0.0)
	boca(Vector3(-18.4, 8.82, -98.9), 3.0, 2.2)
	boca(Vector3(-25.6, 8.82, -106.9), 3.0, 1.1)
	boca(Vector3(-18.4, 8.82, -106.9), 3.0, 3.3)
	trilha(Vector3(-28.0, 10.2, -102.9), Vector3(-16.5, 10.2, -102.9), 4)
	# Bolso: a tampa da bancada joga até os livros de receitas, com o V2 em cima.
	panela_com_tampa(Vector3(-46.0, 8.0, -100.0), 19.0, 0.4)
	bloco(Vector3(-56, 8, -108), Vector3(8, 2.4, 7), Color("d9534f"))
	bloco(Vector3(-56, 10.4, -108), Vector3(7.4, 2.2, 6.6), Color("4f8fd9"))
	bloco(Vector3(-56, 12.6, -108), Vector3(7.8, 2.4, 7), Color("f2b134"))
	vaga_lume(Vector3(-56.0, 16.1, -108.0))
	estrelinha(Vector3(-54.0, 16.2, -106.0))
	estrelinha(Vector3(-58.0, 16.2, -110.0))
	arco(Vector3(-46.0, 13.0, -100.0), Vector3(-53.0, 17.0, -105.0), 2.0, 3)
	trilha_creme([Vector3(-41, 8, -72), Vector3(-46, 8, -78), Vector3(-47, 8, -88), Vector3(-40, 8, -95.5)])
	trilha(Vector3(-45.0, 9.0, -77.0), Vector3(-46.5, 9.0, -89.0), 3)
	cozinha("pan_A", Vector3(-34.0, 8.0, -109.0), 0.6, 6.0)
	arco_de_saida(Vector3(-15.5, 8.8, -100.0), PI / 2.0, "blue")


## Viagem 3: um prato vai e volta entre a ponta do fogão e a bancada da pia, por trás da geladeira (é também o atalho
## de volta).
func _prato_atras_da_geladeira() -> void:
	movel_peca(COZINHA, "plate", K, Vector3(-10.2, 8.0, -100.0), Vector3(7.4, 0.8, 7.4), Vector3(20.4, 0, 0), 14.0, 0.0, true, 0.2)
	trilha(Vector3(-8.0, 9.6, -100.0), Vector3(8.0, 9.6, -100.0), 4)


## Playground 4 · Pia e Prateleira (reviravolta): a bancada da pia a leste da geladeira. Na cuba comprida, pratos
## boiando e bolhas de sabão (estouram um instante depois de pisadas) levam até a outra ponta; cair na água é cair.
## De lá, bolhas de degrau sobem até a prateleira encostada na geladeira, e o sorvete na ponta dela joga lá para
## cima. Atrás da geladeira, a prateleira continua até o V3.
func _pia_e_prateleira() -> void:
	playground("4 · Pia e Prateleira", Vector3(16.0, 10.0, -72.0), 20.0, Vector3(20.0, 8.0, -98.0))
	cozinha("kitchencounter_straight_A", Vector3(22, 0, -100))
	cozinha("kitchencounter_straight_A", Vector3(22, 0, -48))
	posto(Vector3(25.0, 8.0, -96.0))
	# A cuba: bordas de armário, o fundo abaixo do limite da queda e a água.
	bloco(Vector3(15, 0, -73.85), Vector3(2.0, 8.0, 35.7), COR_ARMARIO)
	bloco(Vector3(29, 0, -73.85), Vector3(2.0, 8.0, 35.7), COR_ARMARIO)
	bloco(Vector3(22, 0, -73.85), Vector3(12.0, 1.5, 35.7), COR_ACO)
	for x in [15.0, 29.0]:
		_parede(Vector3(x, 8.0, -73.85), Vector3(2.2, 0.1, 35.7), COR_ACO, false)
	agua(Vector3(22, 7.0, -73.85), Vector2(12.0, 35.7))
	nuvem_que_some(Vector3(21.0, 8.4, -87.5), 1.8, true)
	movel_peca(COZINHA, "plate", K, Vector3(22.5, 7.6, -80.0), Vector3(7.4, 0.8, 7.4), Vector3(0, 0.5, 0), 3.0, 0.0, true)
	nuvem_que_some(Vector3(20.5, 8.2, -71.5), 1.8, true)
	movel_peca(COZINHA, "plate", K, Vector3(22.5, 7.6, -63.5), Vector3(7.4, 0.8, 7.4), Vector3(0, 0.5, 0), 3.4, 1.5, true)
	for p in [Vector3(21.0, 9.6, -87.5), Vector3(22.5, 8.8, -80.0), Vector3(20.5, 9.4, -71.5), Vector3(22.5, 8.8, -63.5)]:
		estrelinha(p)
	for z in [-84.0, -72.0, -61.0]:
		for x in [15.0, 29.0]:
			bloco(Vector3(x, 8.0, z), Vector3(2.0, 2.8, 2.2), Color("ffd84a"))
			bloco(Vector3(x, 10.8, z), Vector3(2.0, 0.5, 2.2), Color("5fc46a"))
	# A torneira, feita de canos (sólidos), no canto do fundo.
	var cano := _material(COR_ACO)
	cano.metallic = 0.8
	cano.roughness = 0.2
	for spec in [[Vector3(27.5, 9.5, -92.5), Vector3(1.2, 3.0, 1.2)], [Vector3(27.5, 11.6, -89.7), Vector3(1.0, 1.0, 6.0)], [Vector3(27.5, 10.6, -87.1), Vector3(0.9, 1.6, 0.9)]]:
		var corpo := StaticBody3D.new()
		corpo.position = spec[0]
		var mi := MeshInstance3D.new()
		var caixa := BoxMesh.new()
		caixa.size = spec[1]
		mi.mesh = caixa
		mi.material_override = cano
		corpo.add_child(mi)
		var cs := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = spec[1]
		cs.shape = forma
		corpo.add_child(cs)
		add_child(corpo)

	# Da bancada do fim, bolhas de degrau sobem até a prateleira encostada na geladeira.
	bolota(Vector3(26.0, 8.0, -45.0), false, "caranguejo")
	nuvem_que_some(Vector3(19.0, 9.6, -45.5), 2.0, true)
	nuvem_que_some(Vector3(17.5, 11.2, -48.8), 2.0, true)
	nuvem_que_some(Vector3(16.5, 12.8, -52.2), 2.0, true)
	for p in [Vector3(19.0, 10.8, -45.5), Vector3(17.5, 12.4, -48.8), Vector3(16.5, 14.0, -52.2)]:
		estrelinha(p)
	bloco(Vector3(11, 13, -62), Vector3(6, 1, 36), COR_MADEIRA)
	for z in [-46.0, -58.0, -70.0]:
		bloco(Vector3(13.4, 9.0, z), Vector3(1.0, 4.0, 1.0), COR_MADEIRA)
	bolota(Vector3(11.0, 14.0, -50.0), false, "cacto")
	trilha(Vector3(11.0, 15.0, -55.0), Vector3(11.0, 15.0, -66.0), 4)
	mola_de_sorvete(Vector3(11.0, 14.0, -72.0), 21.0)
	arco(Vector3(11.0, 18.0, -72.0), Vector3(4.0, 22.0, -72.0), 3.0, 3)
	# Segredo: a prateleira dobra atrás da geladeira, com o V3 escondido atrás da caixa.
	bloco(Vector3(3, 13, -81), Vector3(22, 1, 6), COR_MADEIRA)
	cozinha("crate", Vector3(1.0, 14.0, -82.0), 0.0, 2.0)
	vaga_lume(Vector3(-5.0, 15.1, -80.0))
	trilha(Vector3(10.5, 15.0, -79.0), Vector3(4.5, 15.0, -82.5), 2)
	trilha_creme([Vector3(20, 8, -98), Vector3(22, 8, -93)])
	trilha(Vector3(18.0, 9.0, -97.0), Vector3(22.0, 9.0, -93.0), 2)
	trilha(Vector3(22.5, 9.0, -54.0), Vector3(23.0, 9.0, -47.0), 3)
	trilha_creme([Vector3(22, 8, -55), Vector3(20, 8, -46)])
	trilha_creme([Vector3(11, 14, -45.5), Vector3(11, 14, -70)])


## Arena em cima da geladeira (20 m): o baú, duas Bolotas e a coluna de luz que aparece da cozinha toda.
func _em_cima_da_geladeira() -> void:
	colocar_bau(Vector3(0, 20.0, -73.0))
	bolota(Vector3(-4.0, 20.0, -67.0), false, "pinguim")
	bolota(Vector3(3.5, 20.0, -66.0), false, "porco")
	roda(Vector3(0, 20.9, -73.0), 3.4, 4)
	cozinha("icecream_cone_stacked", Vector3(-5.5, 20.0, -76.0), 0.0, 4.0)
	brilho_de_marco(Vector3(0, 21.5, -73.0), 26.0)


## Cozinha de dia: fundo creme, luz ambiente quente e o sol entrando pela janela, com sombra.
func _montar_ceu_e_luz() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("f6e6cc")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("fff1dc")
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95
	env.ssao_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_hdr_threshold = 1.2
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 60, 0)
	sol.light_color = Color("fff3dd")
	sol.light_energy = 1.1
	sol.shadow_enabled = true
	sol.shadow_opacity = 0.7
	sol.directional_shadow_max_distance = 90.0
	add_child(sol)


func _montar_nuvens() -> void:
	pass
