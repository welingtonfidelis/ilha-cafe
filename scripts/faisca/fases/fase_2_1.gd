class_name Fase21
extends Fase
## 2-1 Cozinha Gigante (Mundo 2, Doces e Brinquedos; a porta do 2º andar do farol, que pede 60 estrelinhas). As
## Bolotas levaram a terceira Estrela Grande para a cozinha de uma casa de gigantes, e o Faísca fica
## pequenininho entre panelas, pratos e potes: tudo do Restaurant Bits ampliado 8 vezes (a bancada tem 8 m, o
## prato 7,6 m, a geladeira 20 m). Feita em 2026-10-29, a pedido do usuário ("pode fazer a próxima fase"), já no
## tamanho das fases compridas.
## O caminho vai para -Z por cima dos móveis; o chão da cozinha fica lá embaixo, e cair nele é cair (volta no
## posto). Novidade: as tampas das panelas que pulam (levam para o alto no tempo delas).
##   1 Mesa do Café (V1 atrás do pote)  2 Tábua de Cortar  3 Bancada das Panelas (P1; tampas que pulam)
##   4 Prateleira dos Potes (V2 no pote mais alto)  5 Fogão (bocas que acendem)  6 Pia (P2; pratos boiando e
##   bolhas)  7 Bancada da Massa (rolos de macarrão)  8 Pizza Giratória (P3)  9 Geladeira (sorvete que joga
##   lá para cima, o baú e o V3)

const K := 8.0
const COR_PAREDE := Color("f3e2c7")
const COR_ACO := Color("c6ccd8")
const COR_ARMARIO := Color("8fc6c0")
const COR_MADEIRA := Color("c58a52")


func _montar() -> void:
	nome = "2-1 Cozinha Gigante"
	inicio = Vector3(0, 8.1, 1.5)
	limite_queda = 3.0
	_sala()
	_mesa_do_cafe()
	_tabua_de_cortar()
	_bancada_das_panelas()
	_prateleira_dos_potes()
	_fogao()
	_pia()
	_bancada_da_massa()
	_pizza_giratoria()
	_geladeira()


## A cozinha: o chão xadrez lá embaixo, as paredes de longe, a janela com o sol e a parede de azulejo atrás da
## bancada e da prateleira.
func _sala() -> void:
	for i in 3:
		for j in 9:
			cozinha("floor_kitchen", Vector3(-32 + i * 32, 0, 16 - j * 32), PI / 2.0 * ((i + j) % 2), K, false)
	_parede(Vector3(-44, 0, -110), Vector3(2, 46, 270), COR_PAREDE)
	_parede(Vector3(44, 0, -110), Vector3(2, 46, 270), COR_PAREDE)
	_parede(Vector3(0, 0, -246), Vector3(90, 46, 2), COR_PAREDE)
	_parede(Vector3(0, 0, 26), Vector3(90, 46, 2), COR_PAREDE)
	# Rodapé e azulejos (faixas de cor) nas paredes compridas.
	for x in [-42.9, 42.9]:
		_parede(Vector3(x, 0, -110), Vector3(0.3, 3, 270), Color("c58a52"), false)
		_parede(Vector3(x, 14, -110), Vector3(0.3, 10, 270), Color("cde9f2"), false)
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
	janela.position = Vector3(42.8, 26, -120)
	janela.rotation.y = -PI / 2.0
	add_child(janela)
	# A parede de azulejo atrás da bancada e da prateleira.
	_parede(Vector3(-9.5, 0, -58), Vector3(1.0, 34, 84), Color("e8f4f6"))
	for y in [10.0, 16.0, 22.0, 28.0]:
		_parede(Vector3(-8.95, y, -58), Vector3(0.1, 0.25, 84), Color("b9d8de"), false)


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


## 1. Mesa do Café: o Faísca chega na mesa grande, com pratos (degraus de 0,8 m), uma tigela com estrelinhas
## dentro, uma Bolota dormindo e o V1 escondido atrás do pote grande, no canto. As cadeiras ficam lá embaixo.
func _mesa_do_cafe() -> void:
	cozinha("kitchentable_A_large", Vector3(0, 0, -4))
	cozinha("plate", Vector3(-6, 8, -1))
	cozinha("plate", Vector3(5.5, 8, -7.5))
	cozinha("bowl", Vector3(6, 8, 1.5))
	cozinha("jar_D_large", Vector3(-8.5, 8, -8.5))
	vaga_lume(Vector3(-10.7, 9.0, -10.8))
	bolota(Vector3(1.5, 8, -5.5), true)
	for p in [Vector3(5.0, 9.2, 1.0), Vector3(7.0, 9.2, 1.0), Vector3(6.0, 9.2, 2.6)]:
		estrelinha(p)
	estrelinha(Vector3(-6, 10.0, -1))
	estrelinha(Vector3(5.5, 10.0, -7.5))
	trilha(Vector3(0, 9.0, -1.0), Vector3(0, 9.0, -10.0), 4)
	for spec in [[Vector3(-15.5, 0, -1), PI / 2.0], [Vector3(15.5, 0, -7), -PI / 2.0], [Vector3(-15.5, 0, -8), PI / 2.0], [Vector3(15.5, 0, 0), -PI / 2.0]]:
		cozinha("chair_A", spec[0], spec[1], K, false)
	cozinha("mustard", Vector3(9.5, 8, -3.0), 0.4, 5.0)


## 2. Tábua de Cortar: a ponte de madeira da mesa até a bancada, por cima do vão.
func _tabua_de_cortar() -> void:
	cozinha("cuttingboard", Vector3(0, 8, -15), PI / 2.0)
	arco(Vector3(0, 10.0, -11.0), Vector3(0, 10.0, -19.0), 1.2, 4)


## 3. Bancada das Panelas: P1 e três panelas no fogo. Uma pilha de pratinhos sobe da tábua para a primeira
## tampa; as tampas tremem, soltam vapor e pulam (cada uma no seu tempo). As duas primeiras levam até as
## estrelinhas do alto; a terceira joga o Faísca até a prateleira, lá em cima.
func _bancada_das_panelas() -> void:
	cozinha("kitchencounter_straight_A", Vector3(0, 0, -26.0))
	cozinha("kitchencounter_straight_A", Vector3(0, 0, -42.32))
	posto(Vector3(-5.5, 8.0, -20.8))
	for k in 3:
		cozinha("plate_small", Vector3(0, 8.0 + k * 0.8, -22.5))
	ponto_de_dica(Vector3(0, 10.6, -22.5), 3.0, "tampa")
	panela_com_tampa(Vector3(0, 8.0, -29.0), 21.0, 0.0)
	panela_com_tampa(Vector3(0, 8.0, -38.0), 21.0, 1.1)
	panela_com_tampa(Vector3(0, 8.0, -47.0), 21.0, 2.2)
	trilha(Vector3(0, 15.5, -29.0), Vector3(0, 19.5, -29.0), 3)
	trilha(Vector3(0, 15.5, -38.0), Vector3(0, 19.5, -38.0), 3)
	bolota(Vector3(6.0, 8.0, -38.0))
	cozinha("ketchup", Vector3(6.2, 8.0, -24.0), 0.3, 5.0)
	cozinha("crate_tomatoes", Vector3(-5.6, 8.0, -33.0), 0.4, 2.5)


## 4. Prateleira dos Potes: a tábua comprida presa na parede, a 19 m. Potes gigantes no caminho (é desviar em
## zigue-zague) e um potinho de degrau com estrelinha. O V2 fica em cima do pote mais alto, e quem leva até lá é
## a tampa de uma panelinha.
func _prateleira_dos_potes() -> void:
	bloco(Vector3(-3.5, 17.8, -75.0), Vector3(10.0, 1.2, 48.0), COR_MADEIRA)
	for z in [-55.0, -67.0, -79.0, -91.0]:
		bloco(Vector3(-7.5, 14.8, z), Vector3(1.2, 3.0, 1.2), COR_MADEIRA)
	cozinha("jar_A_large", Vector3(-6.0, 19.0, -60.0))
	cozinha("jar_C_large", Vector3(-5.5, 19.0, -70.0))
	cozinha("jar_D_large", Vector3(-6.0, 19.0, -84.0))
	cozinha("jar_A_small", Vector3(0.0, 19.0, -62.5), 0.0, 4.0)
	estrelinha(Vector3(0.0, 22.6, -62.5))
	# V2 no pote mais alto (6 m): a tampa da panelinha ali do lado joga lá para cima; três pratinhos de degrau.
	panela_com_tampa(Vector3(-0.5, 19.0, -74.0), 18.0, 0.6, 4.0)
	for k in 3:
		cozinha("plate_small", Vector3(-0.5, 19.0 + k * 0.4, -78.6), 0.0, 4.0)
	vaga_lume(Vector3(-5.5, 26.1, -70.0))
	bolota(Vector3(-6.0, 19.0, -77.0))
	bolota(Vector3(-2.0, 19.0, -90.0))
	trilha(Vector3(-1.5, 20.0, -53.0), Vector3(-1.5, 20.0, -57.0), 2)
	trilha(Vector3(-6.0, 20.0, -64.0), Vector3(-6.0, 20.0, -66.0), 2)
	trilha(Vector3(-1.0, 20.0, -68.0), Vector3(-1.0, 20.0, -70.0), 2)
	trilha(Vector3(-6.0, 20.0, -74.0), Vector3(-6.0, 20.0, -79.0), 2)
	trilha(Vector3(-3.5, 20.0, -88.0), Vector3(-3.5, 20.0, -97.0), 4)
	coracao(Vector3(0.0, 20.0, -95.0))


## 5. Fogão: da ponta da prateleira se pula no fogão lá embaixo. As quatro bocas acendem e apagam (o anel fica
## laranja um instante antes); acesa, encostar tira um coração. É passar na hora em que elas estão apagadas.
func _fogao() -> void:
	cozinha("stove_multi", Vector3(0, 0, -107.08))
	# O tampo do fogão fica a 8,8 m (o 1,2 do modelo conta os botões e o painel de trás).
	boca(Vector3(-3.6, 8.82, -102.0), 3.0, 0.0)
	boca(Vector3(3.6, 8.82, -102.0), 3.0, 2.2)
	boca(Vector3(-3.6, 8.82, -110.0), 3.0, 1.1)
	boca(Vector3(3.6, 8.82, -110.0), 3.0, 3.3)
	trilha(Vector3(0, 10.0, -100.0), Vector3(0, 10.0, -112.0), 4)


## 6. Pia: P2 na beirada e a cuba comprida cheia de água com espuma. Pratos boiando (sobem e descem) e bolhas de
## sabão (estouram um instante depois de pisadas e voltam) levam até o outro lado; cair na água é cair. Nas
## bordas, esponjas altas não deixam ir andando por cima.
func _pia() -> void:
	bloco(Vector3(0, 0, -117.32), Vector3(16.0, 8.0, 4.0), COR_ARMARIO)
	bloco(Vector3(0, 0, -149.32), Vector3(16.0, 8.0, 4.0), COR_ARMARIO)
	bloco(Vector3(-7.25, 0, -133.32), Vector3(1.5, 8.0, 28.0), COR_ARMARIO)
	bloco(Vector3(7.25, 0, -133.32), Vector3(1.5, 8.0, 28.0), COR_ARMARIO)
	# Fundo da cuba abaixo do limite da queda: quem afunda nunca fica preso lá embaixo.
	bloco(Vector3(0, 0, -133.32), Vector3(13.0, 1.5, 28.0), COR_ACO)
	# Tampo de aço em volta (só o desenho, por cima dos blocos).
	for spec in [[Vector3(0, 8.0, -117.32), Vector3(16.2, 0.1, 4.2)], [Vector3(0, 8.0, -149.32), Vector3(16.2, 0.1, 4.2)],
			[Vector3(-7.25, 8.0, -133.32), Vector3(1.7, 0.1, 28.0)], [Vector3(7.25, 8.0, -133.32), Vector3(1.7, 0.1, 28.0)]]:
		_parede(spec[0], spec[1], COR_ACO, false)
	agua(Vector3(0, 7.0, -133.32), Vector2(13.0, 28.0))
	posto(Vector3(-4.0, 8.0, -117.3))
	movel_peca(COZINHA, "plate", K, Vector3(0, 7.6, -124.3), Vector3(7.4, 0.8, 7.4), Vector3(0, 0.5, 0), 3.0, 0.0, true)
	nuvem_que_some(Vector3(-1.5, 8.2, -131.0), 1.8, true)
	movel_peca(COZINHA, "plate", K, Vector3(2.0, 7.6, -137.3), Vector3(7.4, 0.8, 7.4), Vector3(0, 0.5, 0), 3.4, 1.5, true)
	nuvem_que_some(Vector3(-1.5, 8.4, -144.0), 1.8, true)
	for z in [-124.0, -132.0, -140.0]:
		for x in [-7.25, 7.25]:
			bloco(Vector3(x, 8.0, z), Vector3(1.4, 2.8, 2.2), Color("ffd84a"))
			bloco(Vector3(x, 10.8, z), Vector3(1.4, 0.5, 2.2), Color("5fc46a"))
	for p in [Vector3(0, 8.8, -124.3), Vector3(-1.5, 9.4, -131.0), Vector3(2.0, 8.8, -137.3), Vector3(-1.5, 9.6, -144.0)]:
		estrelinha(p)
	# A torneira, feita de canos: sai da parede de trás da cuba e curva para cima da água.
	var cano := _material(COR_ACO)
	cano.metallic = 0.8
	cano.roughness = 0.2
	# Fica no canto da esquerda, longe do caminho (o meio da beirada é por onde se passa).
	for spec in [[Vector3(-6.2, 9.5, -150.6), Vector3(1.2, 3.0, 1.2)], [Vector3(-6.2, 11.6, -147.8), Vector3(1.0, 1.0, 6.0)], [Vector3(-6.2, 10.6, -145.2), Vector3(0.9, 1.6, 0.9)]]:
		var mi := MeshInstance3D.new()
		var caixa := BoxMesh.new()
		caixa.size = spec[1]
		mi.mesh = caixa
		mi.material_override = cano
		mi.position = spec[0]
		add_child(mi)


## 7. Bancada da Massa: a massa aberta em cima e dois rolos de macarrão rolando de um lado para o outro. É pular
## por cima deles (encostar tira um coração). Duas Bolotas e um coração no fim.
func _bancada_da_massa() -> void:
	cozinha("kitchencounter_straight_A", Vector3(0, 0, -159.32))
	cozinha("kitchencounter_straight_A", Vector3(0, 0, -175.64))
	cozinha("food_ingredient_dough_base", Vector3(0, 8.0, -163.0))
	rolo(Vector3(-5.0, 9.2, -160.0), Vector3(10.0, 0, 0), 3.6, 0.0)
	rolo(Vector3(-5.0, 8.0, -175.0), Vector3(10.0, 0, 0), 4.2, 1.5)
	bolota(Vector3(4.5, 8.0, -170.0))
	bolota(Vector3(-4.5, 8.0, -180.0))
	coracao(Vector3(6.0, 9.0, -181.0))
	trilha(Vector3(0, 10.4, -154.0), Vector3(0, 10.4, -158.0), 2)
	trilha(Vector3(0, 10.4, -166.0), Vector3(0, 9.2, -172.0), 3)
	estrelinha(Vector3(0, 12.0, -160.0))
	estrelinha(Vector3(0, 10.8, -175.0))
	cozinha("rollingpin", Vector3(-6.5, 8.0, -168.0), 0.2, 3.0)


## 8. Pizza Giratória: P3 na mesa redonda e a pizza gigante girando devagar no meio, como o prato do
## micro-ondas. Os vidros de ketchup e mostarda fecham a beirada dos lados: é atravessar por cima da pizza, que
## leva junto (e as Bolotas também).
func _pizza_giratoria() -> void:
	cozinha("table_round_A", Vector3(0, 0, -197.6))
	pizza(Vector3(0, 8.0, -197.6), 0.35)
	posto(Vector3(0, 8.0, -187.6))
	cozinha("ketchup", Vector3(-10.2, 8.0, -197.6), 0.0, K)
	cozinha("mustard", Vector3(10.2, 8.0, -197.6), 0.0, K)
	for x in [-10.2, 10.2]:
		cozinha("ketchup" if x > 0.0 else "mustard", Vector3(x * 0.82, 8.0, -191.2), 0.0, 6.0)
		cozinha("mustard" if x > 0.0 else "ketchup", Vector3(x * 0.82, 8.0, -204.0), 0.0, 6.0)
	bolota(Vector3(3.0, 10.5, -197.6))
	bolota(Vector3(-3.0, 10.5, -194.0))
	roda(Vector3(0, 11.4, -197.6), 5.0, 6)


## 9. Geladeira: na beirada da mesa, um sorvete gigante joga o Faísca lá para cima da geladeira, a 20 m. Lá
## estão o baú, duas Bolotas e o V3, escondido atrás da caixa no canto do fundo.
func _geladeira() -> void:
	# O tampo dela vai de uns 2 m depois da porta até o fundo (z -213 a -229 aqui).
	cozinha("fridge_A", Vector3(0, 0, -220.92))
	mola_de_sorvete(Vector3(0, 8.0, -208.2), 26.0)
	trilha(Vector3(0, 12.0, -208.4), Vector3(0, 19.0, -209.4), 3)
	colocar_bau(Vector3(0, 20.0, -222.0))
	bolota(Vector3(-4.0, 20.0, -218.0))
	bolota(Vector3(-4.0, 20.0, -226.0))
	roda(Vector3(0, 20.9, -222.0), 3.4, 3)
	cozinha("crate", Vector3(4.0, 20.0, -224.0), 0.0, 2.5)
	vaga_lume(Vector3(4.0, 21.0, -227.8))
	cozinha("icecream_cone_stacked", Vector3(-6.0, 20.0, -227.0), 0.0, 4.0, false)


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
