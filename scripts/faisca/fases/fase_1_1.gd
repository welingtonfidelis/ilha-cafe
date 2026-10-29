class_name Fase11
extends Fase
## 1-1 Pulinhos nas Nuvens (Mundo 1, Ilhas Fofas). A primeira fase: ensina um truque de cada
## vez, sem perigo além de cair. O caminho vai para -Z e sobe aos poucos, com o Farol ao longe.
## Os trechos seguem o plano do docs/FAISCA.md. Em 2026-10-29 o usuário achou a fase muito curta (uns 130 m,
## 1 a 2 minutos), e ela ganhou cinco trechos novos (marcados com *), passando de uns 300 m:
##   1 Ilha do Começo (V1 atrás da árvore grande)  2 ponte de plataformas  *3 Ilha das Esteiras
##   4 Ilha das Molas (P1)  5 Ilha Alta (V2 no pilar)  6 vão grande  *7 Argolas no Céu
##   8 Jardim de Luz (P2)  *9 Botões Coloridos  10 plataformas que se mexem  *11 Nuvens que Somem (P3)
##   *12 Canhão de Nuvem  13 Ilha do Baú (V3 na beiradinha embaixo)


func _montar() -> void:
	nome = "1-1 Pulinhos nas Nuvens"
	inicio = Vector3(0, 0.1, 4)
	limite_queda = -8.0
	farol(Vector3(-80, -14, -390), 2.0)
	_ilha_do_comeco()
	_ponte()
	_ilha_das_esteiras()
	_ilha_das_molas()
	_ilha_alta()
	_vao_grande()
	_argolas_no_ceu()
	_jardim_de_luz()
	_botoes_coloridos()
	_plataformas_que_se_mexem()
	_nuvens_que_somem()
	_canhao_de_nuvem()
	_ilha_do_bau()


## 1. Ilha grande de grama, degraus baixos de morro ensinando o pulo, uma Bolota dormindo para
## o primeiro soco e o V1 atrás da árvore grande.
func _ilha_do_comeco() -> void:
	morro("12x12x4", Vector3(0, 0, 0))
	morro("12x6x4", Vector3(0, 0, -9.25))
	morro("4x4x2", Vector3(-2.5, 0.8, -7.0))
	morro("4x4x2", Vector3(1.8, 1.6, -9.6))
	trilha(Vector3(0, 0.9, 2.2), Vector3(-1.6, 0.9, -3.4), 3)
	estrelinha(Vector3(1.8, 2.6, -9.6))
	bolota(Vector3(1.6, 0, -2.0), true)

	# V1: atrás da árvore grande, coberto pelas moitas; só aparece girando a câmera.
	arvore(1, 1, Vector3(-4.0, 0, 0.2), 1.6)
	enfeite("Bush_2_A_Color1", Vector3(-3.6, 0, 1.4), 3.0)
	enfeite("Bush_4_A_Color1", Vector3(-4.9, 0, 1.1), 2.6, 0.7)
	vaga_lume(Vector3(-5.2, 1.0, -1.4))

	arvore(4, 1, Vector3(4.6, 0, 4.2), 1.2)
	arvore(5, 6, Vector3(-4.8, 0, 4.8), 1.1)
	arvore(2, 8, Vector3(4.8, 0, -2.6), 1.2, 0.8)
	arvore(1, 5, Vector3(-4.6, 0, -10.8), 1.0, 2.0)
	for p in [Vector3(2.2, 0, 4.9), Vector3(-1.8, 0, 5.4), Vector3(5.2, 0, 0.8), Vector3(-5.4, 0, -6.2), Vector3(5.3, 0, -11.2)]:
		enfeite("Bush_1_A_Color1", p, 3.5, p.x)
	enfeite("Rock_1_A_Color1", Vector3(3.6, 0, -6.4), 1.6, 0.4)
	enfeite("Rock_3_A_Color1", Vector3(-5.4, 0.3, 2.9), 1.0, 1.0)
	peca("signage_arrow_stand_yellow", Vector3(4.2, 0, -11.2), -PI / 2.0, 1.0, false)


## 2. Plataformas coloridas sobre as nuvens, com vãos crescendo; a última, mais alta, pede o
## pulo alto. Arcos de estrelinhas no meio dos pulos.
func _ponte() -> void:
	var tops := [Vector3(0, 0, -15.5), Vector3(1.0, 0, -21.0), Vector3(-0.5, 0, -27.0), Vector3(0.5, 0, -33.5), Vector3(0, 1.5, -39.5)]
	var cores := ["blue", "yellow", "red", "green", "blue"]
	var anterior := Vector3(0, 0, -12.5)
	for i in tops.size():
		plataforma("4x4x1", cores[i], tops[i])
		var perto: Vector3 = tops[i] + Vector3(0, 0, 2.0)
		arco(anterior + Vector3(0, 0.9, -0.6), perto + Vector3(0, 0.9, 0.6), 1.4, 2)
		anterior = tops[i] + Vector3(0, 0, -2.0)
	ponto_de_dica(Vector3(0.5, 1.0, -33.5), 2.2, "pulo_alto")


## 3*. Ilha das Esteiras: duas esteiras lado a lado (a verde leva para a frente; a vermelha, para trás, tem as
## estrelinhas), uma plataforma e uma esteira atravessada que empurra para o lado, com uma mureta no fim (quem
## não anda é empurrado contra ela, sem cair).
func _ilha_das_esteiras() -> void:
	plataforma("6x6x1", "green", Vector3(0, 1.5, -47.5))
	esteira(Vector3(-2.2, 1.5, -54.5), PI, 3.5, "green")
	esteira(Vector3(2.2, 1.5, -54.5), 0.0, 2.5, "red")
	trilha(Vector3(2.2, 2.6, -51.5), Vector3(2.2, 2.6, -57.5), 3)
	plataforma("6x6x1", "yellow", Vector3(0, 1.5, -61.5))
	esteira(Vector3(0, 1.5, -66.6), PI / 2.0, 3.0, "blue")
	peca("barrier_4x1x2_blue", Vector3(4.6, 0.5, -66.6), PI / 2.0)
	trilha(Vector3(-2.5, 2.6, -66.6), Vector3(2.5, 2.6, -66.6), 3)
	plataforma("6x6x1", "red", Vector3(0, 1.5, -71.5))
	estrelinha(Vector3(0, 2.6, -71.5))


## 4. P1, duas Bolotas acordadas (soco e combo), uma terceira dormindo embaixo de um degrau
## (pede o pisão), um coração extra e a mola para a Ilha Alta.
func _ilha_das_molas() -> void:
	morro("12x12x4", Vector3(0, 1.8, -83.5))
	morro("4x4x2", Vector3(4.0, 3.0, -80.2))
	posto(Vector3(-3.6, 1.8, -79.0))
	bolota(Vector3(-2.4, 1.8, -84.5))
	bolota(Vector3(2.0, 1.8, -86.5))
	bolota(Vector3(4.0, 1.8, -83.4), true)
	# Primeiras Bolotas acordadas: o Vovô mostra o agarrar e arremessar (Y, 2026-10-29).
	ponto_de_dica(Vector3(0, 2.8, -79.5), 3.0, "agarrar")
	coracao(Vector3(-4.6, 2.8, -87.6))
	mola(Vector3(0, 1.8, -88.2))
	estrelinha(Vector3(4.0, 4.0, -80.2))
	estrelinha(Vector3(-4.6, 2.7, -83.6))
	estrelinha(Vector3(0, 2.7, -81.0))
	arvore(4, 7, Vector3(-5.0, 1.8, -78.0), 1.0)
	arvore(2, 1, Vector3(5.2, 1.8, -88.4), 1.1)
	enfeite("Bush_2_A_Color1", Vector3(5.0, 1.8, -77.8), 2.5)
	enfeite("Rock_1_A_Color1", Vector3(-5.2, 1.8, -88.0), 1.4)


## 5. Ilha Alta: o V2 fica no alto de um pilar (outra mola e depois flutuar). Na beira, a dica
## de flutuar para o vão grande.
func _ilha_alta() -> void:
	morro("8x8x8", Vector3(0, 6.0, -96.5))
	morro("2x2x4", Vector3(2.5, 10.0, -98.6))
	mola(Vector3(-1.6, 6.0, -94.6))
	vaga_lume(Vector3(2.5, 11.1, -98.6))
	trilha(Vector3(-1.6, 9.5, -94.6), Vector3(-1.6, 12.5, -94.6), 3)
	arvore(5, 1, Vector3(-2.8, 6.0, -99.5), 0.9)
	ponto_de_dica(Vector3(0, 6.5, -99.2), 2.4, "flutuar")


## 6. Vão grande: só dá para atravessar flutuando; o arco de estrelinhas desenha o caminho e
## duas nuvenzinhas mais baixas são a segunda chance de quem cair cedo.
func _vao_grande() -> void:
	arco(Vector3(0, 7.0, -101.4), Vector3(0, 5.6, -108.6), 2.2, 5)
	nuvem(Vector3(-1.2, 2.2, -103.8), 1.5)
	nuvem(Vector3(1.0, 3.0, -107.0), 1.5)
	estrelinha(Vector3(-1.2, 3.1, -103.8))
	estrelinha(Vector3(1.0, 3.9, -107.0))


## 7*. Argolas no Céu: da ilhinha do vão grande, nuvens firmes subindo devagar, com uma argola em cada vão. Os
## pulos de uma nuvem para outra passam por dentro delas; com as quatro acesas, cai uma chuva de estrelinhas
## em cima da última nuvem.
func _argolas_no_ceu() -> void:
	morro("8x8x4", Vector3(0, 4.5, -113.25))
	arvore(2, 5, Vector3(-2.6, 4.5, -115.0), 0.8)
	enfeite("Bush_1_A_Color1", Vector3(2.6, 4.5, -111.0), 2.5)
	var nuvens := [Vector3(0, 4.5, -123.0), Vector3(1.5, 5.0, -129.0), Vector3(-1.5, 5.5, -135.0), Vector3(0, 6.0, -141.0)]
	var antes := Vector3(0, 4.5, -117.25)
	var cores := ["red", "yellow", "blue", "green"]
	for i in nuvens.size():
		nuvem(nuvens[i], 1.6)
		var perto: Vector3 = nuvens[i] + Vector3(0, 0, 1.6)
		var meio := (antes + perto) * 0.5
		# Pé da argola um pouco abaixo do chão: a abertura fica na altura do meio do pulo.
		argola(Vector3(meio.x, minf(antes.y, perto.y) - 0.4, meio.z), 0.0, cores[i])
		antes = nuvens[i] - Vector3(0, 0, 1.6)
	var ultima: Vector3 = nuvens[nuvens.size() - 1]
	var premio := []
	for i in 8:
		var a := TAU * i / 8.0
		premio.append(ultima + Vector3(cos(a) * 1.2, 1.4 + 0.4 * sin(a * 2.0), sin(a) * 1.2))
	premio_das_argolas(premio)


## 8. Jardim de Luz: P2, três flores apagadas e o portão fechado entre dois paredões. Flutuar em
## cima de cada flor acende; com as três acesas o portão abre. Duas Bolotas no jardim.
func _jardim_de_luz() -> void:
	morro("12x12x4", Vector3(0, 4.5, -151.75))
	morro("4x4x4", Vector3(-4.25, 8.5, -155.75))
	morro("4x4x4", Vector3(4.25, 8.5, -155.75))
	posto(Vector3(3.8, 4.5, -146.9))
	flor(Vector3(-4.0, 4.5, -149.1))
	flor(Vector3(4.2, 4.5, -150.9))
	flor(Vector3(-0.8, 4.5, -152.1))
	portao(Vector3(0, 4.5, -154.1))
	bolota(Vector3(-2.2, 4.5, -150.7))
	bolota(Vector3(2.6, 4.5, -152.5))
	ponto_de_dica(Vector3(0, 5.0, -146.9), 2.4, "laser")
	for p in [Vector3(-4.0, 6.2, -149.1), Vector3(4.2, 6.2, -150.9), Vector3(-0.8, 6.2, -152.1)]:
		estrelinha(p)
	trilha(Vector3(0, 5.4, -155.5), Vector3(0, 5.4, -157.5), 2)
	arvore(2, 8, Vector3(-5.2, 4.5, -146.5), 1.0)
	arvore(1, 7, Vector3(5.4, 4.5, -152.9), 0.9, 1.2)
	for p in [Vector3(-1.6, 4.5, -146.5), Vector3(1.8, 4.5, -149.1), Vector3(-5.4, 4.5, -151.9), Vector3(5.0, 4.5, -148.5)]:
		enfeite("Bush_4_A_Color1", p, 2.4, p.z)


## 9*. Botões Coloridos: depois do portão, três botões no chão (vermelho, amarelo e azul). Pulando em cima de
## cada um, ele afunda e acende; com os três, sobem do vão as três plataformas da ponte, que é longa demais até
## para flutuar. As estrelinhas no ar mostram onde a ponte vai aparecer.
func _botoes_coloridos() -> void:
	morro("12x12x4", Vector3(0, 4.5, -163.75))
	botao(Vector3(-3.6, 4.5, -161.1), "red")
	botao(Vector3(3.6, 4.5, -163.9), "yellow")
	botao(Vector3(0, 4.5, -167.5), "blue")
	ponto_de_dica(Vector3(0, 5.0, -159.1), 2.4, "botao")
	bolota(Vector3(2.4, 4.5, -166.6), true)
	var degraus := [Vector3(0, 4.5, -173.75), Vector3(1.5, 5.0, -179.75), Vector3(-1.0, 5.5, -185.75)]
	ponte_dos_botoes(degraus)
	for d: Vector3 in degraus:
		estrelinha(d + Vector3(0, 1.1, 0))
	for p in [Vector3(-3.6, 5.6, -161.1), Vector3(3.6, 5.6, -163.9), Vector3(0, 5.6, -167.5)]:
		estrelinha(p)
	arvore(4, 5, Vector3(-5.0, 4.5, -168.5), 1.0)
	arvore(1, 8, Vector3(5.2, 4.5, -159.3), 0.9)
	enfeite("Bush_2_A_Color1", Vector3(5.0, 4.5, -168.8), 2.4)


## 10. Três plataformas indo e voltando, subindo até a ilhinha das nuvens, com estrelinhas no caminho.
func _plataformas_que_se_mexem() -> void:
	movel("4x4x1", "yellow", Vector3(0, 4.5, -192.0), Vector3(0, 0, -5.0), 4.5)
	movel("4x4x1", "green", Vector3(3.5, 6.0, -203.1), Vector3(-7.0, 0, 0), 5.0, 1.2)
	movel("4x4x1", "red", Vector3(0, 7.5, -209.1), Vector3(0, 0, -5.0), 4.5, 2.4)
	trilha(Vector3(0, 5.5, -192.5), Vector3(0, 5.5, -196.5), 2)
	trilha(Vector3(-3.0, 7.0, -203.1), Vector3(3.0, 7.0, -203.1), 2)
	estrelinha(Vector3(0, 8.5, -211.5))


## 11*. Nuvens que Somem: P3 numa plataforma e cinco nuvens lilases em zigue-zague, subindo. Cada uma some
## um instante depois de pisada e volta 3 s depois: é seguir pulando, sem parar.
func _nuvens_que_somem() -> void:
	plataforma("6x6x1", "green", Vector3(0, 7.5, -221.25))
	posto(Vector3(0, 7.5, -221.25))
	var nuvens := [Vector3(0, 7.5, -228.5), Vector3(2.0, 8.0, -233.5), Vector3(-2.0, 8.5, -238.5), Vector3(0, 9.0, -243.5), Vector3(2.0, 9.0, -248.5)]
	for n: Vector3 in nuvens:
		nuvem_que_some(n)
		estrelinha(n + Vector3(0, 1.2, 0))


## 12*. Canhão de Nuvem: na plataforma azul, o canhão lança o Faísca num arco bem alto até a Ilha do Baú, e
## as estrelinhas do caminho ficam no meio do voo.
func _canhao_de_nuvem() -> void:
	plataforma("6x6x1", "blue", Vector3(0, 9.0, -255.5))
	var c := canhao(Vector3(0, 9.0, -257.0), Vector3(0, 9.2, -295.0))
	var de := c.to_global(Canhao.BOCA)
	for t in [0.2, 0.35, 0.5, 0.65, 0.8]:
		estrelinha(Canhao.ponto_do_voo(de, c.destino, t) + Vector3.UP * 1.0)


## 13. Ilha do Baú: três Bolotas guardam o baú grande com a Estrela Grande. O V3 fica numa
## beiradinha mais baixa do lado da ilha, com uma mola para voltar.
func _ilha_do_bau() -> void:
	morro("12x12x4", Vector3(0, 9.0, -299.5))
	colocar_bau(Vector3(0, 9.0, -301.75))
	bolota(Vector3(-3.0, 9.0, -297.35))
	bolota(Vector3(3.0, 9.0, -297.95))
	bolota(Vector3(0, 9.0, -304.35))
	# Três Bolotas em volta do baú: o Vovô mostra o giro forte (segurar X, 2026-10-29).
	ponto_de_dica(Vector3(0, 10.0, -294.5), 3.0, "giro_forte")
	roda(Vector3(0, 9.9, -301.75), 3.4, 3)
	morro("4x4x4", Vector3(8.5, 6.0, -300.75))
	vaga_lume(Vector3(8.6, 7.1, -299.35))
	mola(Vector3(8.6, 6.0, -302.15))
	arvore(4, 5, Vector3(-5.0, 9.0, -304.55), 1.1)
	arvore(1, 6, Vector3(4.8, 9.0, -304.95), 1.0)
	for p in [Vector3(-5.2, 9.0, -295.15), Vector3(5.2, 9.0, -294.75)]:
		enfeite("Bush_2_A_Color1", p, 2.6, p.x)
