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
##   4 Pia (a leste): pratos boiando e bolhas na pia (P3); no fim, o registro que solta a água
##   5 Cozinha Alagando (no canto da janela): o momento especial (item 9, 2026-11-11). Cada registro girado faz a
##     água subir uma etapa no chão da cozinha inteira, e o que boia (esponjas, pratos, o patinho com o V3, o pote)
##     sobe junto e vira caminho: da bancada da pia até a escadinha (P4), dela até o balde, e dele até a torre de
##     potes, de onde a bandeja leva até a prateleira atrás da geladeira e o sorvete
##   Arena em cima da geladeira (20 m): o baú e duas Bolotas
## Mais longa desde 2026-11-11 (item 12): a Cozinha Alagando no lugar das bolhas de degrau que iam da bancada da pia
## até a prateleira, e a saída da pia pede o registro.

const K := 8.0
const COR_PAREDE := Color("f3e2c7")
const COR_ACO := Color("c6ccd8")
const COR_ARMARIO := Color("8fc6c0")
const COR_MADEIRA := Color("c58a52")
## O que é de madeira na cozinha, o único que leva o desenho de tábuas (`TexturaDoChao.na_fase`).
const DE_MADEIRA := ["kitchencounter", "kitchentable", "table_round", "cuttingboard", "chair", "crate"]
## A enchente (o momento especial), os três registros e a bandeja que leva da torre de potes até a prateleira.
var enchente: Enchente
var registros: Array[Registro] = []
var bandeja: AnimatableBody3D
var escadinha_topo := Vector3(53.0, 8.5, -52.0)
var balde_topo := Vector3(53.0, 7.6, -77.0)
## O que boia, na ordem do caminho (os testes pulam de uma para a outra).
var boias_do_caminho: Array[Boia] = []
var patinho: Boia
## O marco: o meio de baixo da geladeira (o tampo dela, a 20 m, vai de x -8 a 8 e de z -78 a -62).
const GELADEIRA := Vector3(0, 0, -70)


func _montar() -> void:
	superficie = "madeira"
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
	_cozinha_alagando()
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
	# Do lado de dentro, de uma parede do fundo à outra (mais compridos, as pontas ficavam no plano delas, por fora).
	for x in [-62.9, 62.9]:
		_parede(Vector3(x, 0, -60), Vector3(0.3, 3, 132), Color("c58a52"), false)
		_parede(Vector3(x, 14, -60), Vector3(0.3, 10, 132), Color("cde9f2"), false)
	# Janela grande com a luz do dia, na parede da direita.
	var janela := MeshInstance3D.new()
	var plano := QuadMesh.new()
	plano.size = Vector2(60, 14)
	janela.mesh = plano
	var luz_da_janela := StandardMaterial3D.new()
	luz_da_janela.albedo_color = Color("dff3ff")
	luz_da_janela.emission_enabled = true
	luz_da_janela.emission = Color("dff3ff")
	luz_da_janela.emission_energy_multiplier = 1.4
	janela.material_override = luz_da_janela
	# Acima da faixa de azulejo (antes ficava atrás dela, a 5 cm).
	janela.position = Vector3(62.7, 31, -40)
	janela.rotation.y = -PI / 2.0
	add_child(janela)
	cozinha("fridge_A", GELADEIRA)


## Só a madeira ganha tábuas: as peças de madeira do pacote e as caixas feitas aqui com a cor de madeira (revisão de
## 2026-11-11: a geladeira, os pratos, as panelas, o fogão e a caixa de cereal ficavam com tábuas em cima).
func leva_desenho(mi: MeshInstance3D, arquivo: String) -> bool:
	if arquivo == "":
		var m := mi.get_active_material(0) as StandardMaterial3D
		return m != null and m.albedo_color.is_equal_approx(COR_MADEIRA)
	for p in DE_MADEIRA:
		if arquivo.begins_with(p):
			return true
	return false


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
	# O Faisquinha 3 no meio da roda lá em cima (a tampa joga até ele) e o 4 em cima do vidro de ketchup, a 6 m da
	# tampa: pulando dela e flutuando até lá.
	faisquinha(Vector3(7.0, 15.5, -28.0), "3").set_meta("no_ar", true)
	faisquinha(Vector3(13.0, 15.4, -30.5), "4").set_meta("sem_estrelinhas", true)
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
	# Uns centímetros acima do tampo e uma acima da outra: no mesmo plano, as faces de cima piscavam (z-fighting,
	# um dos glitches da revisão de 2026-11-11).
	cozinha("cuttingboard", Vector3(-20, 6.83, -26))
	cozinha("cuttingboard", Vector3(-25.5, 6.86, -26.03))
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
	# O porco leva o Faisquinha 5 pendurado.
	faisquinha_na_bolota(bolota(Vector3(-35.0, 8.0, -31.0), false, "porco"))
	bolota(Vector3(-58.0, 8.0, -42.0), false, "caranguejo")
	# O vão do canto: a panela no banquinho e a prateleira com o V1.
	bloco(Vector3(-54, 0, -26), Vector3(7.0, 5.0, 5.0), COR_MADEIRA)
	panela_com_tampa(Vector3(-54.0, 5.0, -26.0), 23.0, 0.6)
	bloco(Vector3(-61, 15, -26), Vector3(6, 1, 16), COR_MADEIRA)
	for z in [-20.0, -32.0]:
		bloco(Vector3(-62.5, 12.5, z), Vector3(1.0, 2.5, 1.0), COR_MADEIRA)
	faisquinha(Vector3(-61.0, 17.0, -30.0))
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
	pizza(Vector3(-38.0, 7.42, -82.0), 0.35, 6.0)
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
	faisquinha(Vector3(-56.0, 16.1, -108.0))
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

	# Na bancada do fim, o registro que solta a água (a saída da pia: item 12, 2026-11-11). Antes ficavam aqui as
	# bolhas de degrau até a prateleira; agora se chega lá pela Cozinha Alagando.
	bolota(Vector3(21.0, 8.0, -45.0), false, "caranguejo")
	var r1 := registro(Vector3(26.5, 8.0, -52.0))
	ponto_de_dica(Vector3(23.5, 8.5, -51.0), 3.2, "registro")
	arco_de_saida(Vector3(29.3, 8.0, -46.0), PI / 2.0, "yellow")
	r1.girado.connect(func(_r: Registro) -> void: enchente.subir())
	# Termina onde começa a prateleira de trás da geladeira (as duas no mesmo lugar piscavam).
	bloco(Vector3(11, 13, -61), Vector3(6, 1, 34), COR_MADEIRA)
	for z in [-46.0, -58.0, -70.0]:
		bloco(Vector3(13.4, 9.0, z), Vector3(1.0, 4.0, 1.0), COR_MADEIRA)
	bolota(Vector3(11.0, 14.0, -50.0), false, "cacto")
	trilha(Vector3(11.0, 15.0, -55.0), Vector3(11.0, 15.0, -66.0), 4)
	mola_de_sorvete(Vector3(11.0, 14.0, -72.0), 21.0)
	arco(Vector3(11.0, 18.0, -72.0), Vector3(4.0, 22.0, -72.0), 3.0, 3)
	# Segredo: a prateleira dobra atrás da geladeira, com o V3 escondido atrás da caixa.
	bloco(Vector3(3, 13, -81), Vector3(22, 1, 6), COR_MADEIRA)
	cozinha("crate", Vector3(1.0, 14.0, -82.0), 0.0, 2.0)
	# O V3 mudou para as costas do patinho da enchente; aqui atrás ficou um coração.
	coracao(Vector3(-5.0, 15.6, -80.0))
	trilha(Vector3(10.5, 15.0, -79.0), Vector3(4.5, 15.0, -82.5), 2)
	trilha_creme([Vector3(20, 8, -98), Vector3(22, 8, -93)])
	trilha(Vector3(18.0, 9.0, -97.0), Vector3(22.0, 9.0, -93.0), 2)
	trilha(Vector3(22.5, 9.0, -54.0), Vector3(25.5, 9.0, -49.0), 3)
	trilha_creme([Vector3(22, 8, -55), Vector3(25, 8, -50), Vector3(29, 8, -46)])
	trilha_creme([Vector3(13, 14, -81), Vector3(11, 14, -75)])


## Playground 5 · Cozinha Alagando (o momento especial da 2-1, item 9 da lista, 2026-11-11), no canto da janela, a
## leste da pia. O registro da bancada da pia (a saída do playground 4) faz a pia transbordar e o chão da cozinha
## inteira encher; cada registro sobe a água mais uma etapa (`Enchente`), e o que boia sobe junto:
##   etapa 1 (3,1 m): a esponja, o prato e a esponja levam da bancada até o degrau de baixo da escadinha (P4 em cima);
##   etapa 2 (5,2 m): do alto da escadinha, esponja, prato e esponja até o balde virado (o registro 3 em cima); o
##     patinho, de lado, leva o V3 nas costas;
##   etapa 3 (7,2 m): do balde, o prato e o pote de sorvete (alto) até a torre de potes; de lá, a bandeja leva até a
##     prateleira atrás da geladeira, com o coração e o sorvete que joga lá para cima.
## Antes da água, o que boia fica deitado no chão (que é "lava"), e nada do playground se alcança da bancada.
func _cozinha_alagando() -> void:
	playground("5 · Cozinha Alagando", Vector3(51.0, 7.0, -62.0), 20.0, escadinha_topo)
	enchente = Enchente.new()
	enchente.agua_da_pia = _agua_da_pia()
	add_child(enchente)
	# A escadinha de madeira: dois degraus e o alto, encostados um no outro, com o P4 e o registro 2 em cima.
	bloco(Vector3(53, 0, -42), Vector3(8, 4.5, 4), COR_MADEIRA)
	bloco(Vector3(53, 0, -46), Vector3(8, 6.5, 4), COR_MADEIRA)
	bloco(Vector3(53, 0, -52), Vector3(8, 8.5, 8), COR_MADEIRA)
	posto(Vector3(52.0, 8.5, -51.0))
	var r2 := registro(Vector3(55.5, 8.5, -55.0))
	bolota(Vector3(50.5, 8.5, -54.5), false, "cogumelo")
	estrelinha(Vector3(53.0, 5.7, -42.0))
	estrelinha(Vector3(53.0, 7.7, -46.0))
	# O balde azul virado de boca para baixo, com a alça, e o registro 3 em cima.
	cilindro_solido(Vector3(53, 0, -77), 3.0, 3.6, 7.6, Color("3f8fe0"))
	var alca := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 3.3
	toro.outer_radius = 3.55
	toro.rings = 40
	alca.mesh = toro
	alca.material_override = _material(Color("2f6fb8"))
	alca.position = Vector3(53, 3.2, -77)
	alca.rotation = Vector3(0, 0, PI / 2.0 - 0.25)
	add_child(so_enfeite(alca))
	var r3 := registro(balde_topo + Vector3(0.9, 0, -0.9))
	roda(balde_topo + Vector3(0, 1.4, 0), 2.2, 4)
	# A torre de potes, encostada na pia: o degrau (11,1 m) e o alto (13 m), de onde sai a bandeja. Cada um fica 1,9 m
	# acima do anterior (o pote boiando está a 9,2 m), um pulo sem aperto; da borda da pia (8 m) não se alcança.
	cilindro_solido(Vector3(33.8, 0, -79.5), 2.3, 2.5, 11.1, Color("ffe08a"))
	cilindro_solido(Vector3(33.8, 0, -84.6), 2.4, 2.6, 13.0, Color("ff9fd0"))
	for spec in [[Vector3(33.8, 11.1, -79.5), 2.45, Color("e2553f")], [Vector3(33.8, 13.0, -84.6), 2.55, Color("4cc27a")]]:
		cilindro_solido(spec[0] - Vector3(0, 0.6, 0), spec[1], spec[1], 0.63, spec[2], false)
	trilha(Vector3(33.8, 12.3, -79.5), Vector3(33.8, 14.2, -84.6), 2)
	# A bandeja sobe 1 m no caminho: sai na altura da torre e chega na da prateleira (dá para descer andando).
	bandeja = movel_peca(COZINHA, "plate", K, Vector3(27.4, 13.0, -84.6), Vector3(7.4, 0.8, 7.4), Vector3(-9.4, 1.0, 0), 10.0, 0.0, true, 0.22)
	trilha(Vector3(26.0, 14.8, -84.6), Vector3(18.0, 15.6, -84.6), 3)
	# O que boia: deitado no chão seco, perto de onde vai servir.
	for spec in [
		["esponja", Vector3(33.4, 0, -46.5), 0.1], ["prato", Vector3(40.6, 0, -45.0), 0.0], ["esponja", Vector3(46.6, 0, -42.5), PI / 2.0],
		["esponja", Vector3(53.0, 0, -59.5), 0.15], ["prato", Vector3(52.0, 0, -65.5), 0.0], ["esponja", Vector3(53.5, 0, -71.5), -0.1],
		["prato", Vector3(45.5, 0, -78.5), 0.0], ["pote", Vector3(39.0, 0, -79.5), 0.0]]:
		var b := boia(spec[0], spec[1], spec[2])
		boias_do_caminho.append(b)
		_estrelinha_na(b, 1.3)
	# O patinho olha para a parede: quem chega do prato cai nas costas dele, perto do rabo, e anda até o V3.
	patinho = boia("patinho", Vector3(60.0, 0, -63.5), -PI / 2.0 + 0.25)
	faisquinha(Vector3(60.0, 1.6 + 1.1, -63.5)).prender_em(patinho, Vector3(0, 1.1, 0.2))
	r2.girado.connect(func(_r: Registro) -> void: enchente.subir())
	r3.girado.connect(func(_r: Registro) -> void: enchente.subir())
	trilha_creme([escadinha_topo + Vector3(-1, 0, 3), escadinha_topo + Vector3(0, 0, -3.5)])


## O registro (a roda vermelha) em `pos`, no tampo.
func registro(pos: Vector3) -> Registro:
	var r := Registro.new()
	r.position = pos
	add_child(r)
	registros.append(r)
	return r


## Uma coisa que boia na enchente, deitada no chão em `pos` (x, z), virada `giro`.
func boia(tipo: String, pos: Vector3, giro := 0.0) -> Boia:
	var b := Boia.new()
	b.tipo = tipo
	b.enchente = enchente
	b.position = Vector3(pos.x, 0, pos.z)
	b.rotation.y = giro
	add_child(b)
	enchente.boias.append(b)
	return b


## Estrelinha que vai junto com a boia, `altura` acima do topo dela.
func _estrelinha_na(b: Boia, altura: float) -> void:
	var e := estrelinha(b.position + Vector3(0, b.seca + altura, 0))
	e.reparent(b)
	e.position = Vector3(0, altura, 0)


## Cilindro sólido com o pé em `base` (o balde, a torre de potes).
func cilindro_solido(base: Vector3, r_cima: float, r_baixo: float, altura: float, cor: Color, solido := true) -> Node3D:
	var mi := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = r_cima
	cil.bottom_radius = r_baixo
	cil.height = altura
	cil.radial_segments = 40
	mi.mesh = cil
	mi.material_override = _material(cor)
	if not solido:
		mi.position = base + Vector3.UP * altura * 0.5
		add_child(mi)
		return mi
	var corpo := StaticBody3D.new()
	corpo.position = base + Vector3.UP * altura * 0.5
	corpo.add_child(mi)
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = (r_cima + r_baixo) * 0.5
	forma.height = altura
	cs.shape = forma
	corpo.add_child(cs)
	add_child(corpo)
	return corpo


## O plano da água da pia (a enchente sobe ela até perto da borda).
func _agua_da_pia() -> Node3D:
	for c in get_children():
		if c is MeshInstance3D and c.mesh is PlaneMesh and (c.mesh as PlaneMesh).size == Vector2(12.0, 35.7):
			return c
	return null


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
