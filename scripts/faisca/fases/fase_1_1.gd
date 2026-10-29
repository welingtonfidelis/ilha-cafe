class_name Fase11
extends Fase
## 1-1 Pulinhos nas Nuvens (Mundo 1, Ilhas Fofas). A primeira fase: ensina um truque de cada
## vez, sem perigo além de cair. O caminho vai para -Z e sobe aos poucos, com o Farol ao longe.
## Os trechos seguem o plano do docs/FAISCA.md:
##   1 Ilha do Começo (V1 atrás da árvore grande)  2 ponte de plataformas  3 Ilha das Molas (P1)
##   4 Ilha Alta (V2 no pilar)  5 vão grande  6 Jardim de Luz (P2)  7 plataformas que se mexem
##   8 Ilha do Baú (V3 na beiradinha embaixo)


func _montar() -> void:
	nome = "1-1 Pulinhos nas Nuvens"
	inicio = Vector3(0, 0.1, 4)
	limite_queda = -8.0
	farol(Vector3(-70, -14, -210), 2.0)
	_ilha_do_comeco()
	_ponte()
	_ilha_das_molas()
	_ilha_alta()
	_vao_grande()
	_jardim_de_luz()
	_plataformas_que_se_mexem()
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


## 3. P1, duas Bolotas acordadas (soco e combo), uma terceira dormindo embaixo de um degrau
## (pede o pisão), um coração extra e a mola para a Ilha Alta.
func _ilha_das_molas() -> void:
	morro("12x12x4", Vector3(0, 1.8, -50.5))
	morro("4x4x2", Vector3(4.0, 3.0, -47.2))
	posto(Vector3(-3.6, 1.8, -46.0))
	bolota(Vector3(-2.4, 1.8, -51.5))
	bolota(Vector3(2.0, 1.8, -53.5))
	bolota(Vector3(4.0, 1.8, -50.4), true)
	coracao(Vector3(-4.6, 2.8, -54.6))
	mola(Vector3(0, 1.8, -55.2))
	estrelinha(Vector3(4.0, 4.0, -47.2))
	estrelinha(Vector3(-4.6, 2.7, -50.6))
	estrelinha(Vector3(0, 2.7, -48.0))
	arvore(4, 7, Vector3(-5.0, 1.8, -45.0), 1.0)
	arvore(2, 1, Vector3(5.2, 1.8, -55.4), 1.1)
	enfeite("Bush_2_A_Color1", Vector3(5.0, 1.8, -44.8), 2.5)
	enfeite("Rock_1_A_Color1", Vector3(-5.2, 1.8, -55.0), 1.4)


## 4. Ilha Alta: o V2 fica no alto de um pilar (outra mola e depois flutuar). Na beira, a dica
## de flutuar para o vão grande.
func _ilha_alta() -> void:
	morro("8x8x8", Vector3(0, 6.0, -63.5))
	morro("2x2x4", Vector3(2.5, 10.0, -65.6))
	mola(Vector3(-1.6, 6.0, -61.6))
	vaga_lume(Vector3(2.5, 11.1, -65.6))
	trilha(Vector3(-1.6, 9.5, -61.6), Vector3(-1.6, 12.5, -61.6), 3)
	arvore(5, 1, Vector3(-2.8, 6.0, -66.5), 0.9)
	ponto_de_dica(Vector3(0, 6.5, -66.2), 2.4, "flutuar")


## 5. Vão grande: só dá para atravessar flutuando; o arco de estrelinhas desenha o caminho e
## duas nuvenzinhas mais baixas são a segunda chance de quem cair cedo.
func _vao_grande() -> void:
	arco(Vector3(0, 7.0, -68.4), Vector3(0, 5.6, -75.6), 2.2, 5)
	nuvem(Vector3(-1.2, 2.2, -70.8), 1.5)
	nuvem(Vector3(1.0, 3.0, -74.0), 1.5)
	estrelinha(Vector3(-1.2, 3.1, -70.8))
	estrelinha(Vector3(1.0, 3.9, -74.0))


## 6. Jardim de Luz: P2, três flores apagadas e o portão fechado entre dois paredões. Flutuar em
## cima de cada flor acende; com as três acesas o portão abre. Duas Bolotas no jardim.
func _jardim_de_luz() -> void:
	morro("12x12x4", Vector3(0, 4.5, -82.25))
	morro("4x4x4", Vector3(-4.25, 8.5, -86.25))
	morro("4x4x4", Vector3(4.25, 8.5, -86.25))
	posto(Vector3(3.8, 4.5, -77.4))
	flor(Vector3(-4.0, 4.5, -79.6))
	flor(Vector3(4.2, 4.5, -81.4))
	flor(Vector3(-0.8, 4.5, -82.6))
	portao(Vector3(0, 4.5, -84.6))
	bolota(Vector3(-2.2, 4.5, -81.2))
	bolota(Vector3(2.6, 4.5, -83.0))
	ponto_de_dica(Vector3(0, 5.0, -77.4), 2.4, "laser")
	for p in [Vector3(-4.0, 6.2, -79.6), Vector3(4.2, 6.2, -81.4), Vector3(-0.8, 6.2, -82.6)]:
		estrelinha(p)
	trilha(Vector3(0, 5.4, -86.0), Vector3(0, 5.4, -88.0), 2)
	arvore(2, 8, Vector3(-5.2, 4.5, -77.0), 1.0)
	arvore(1, 7, Vector3(5.4, 4.5, -83.4), 0.9, 1.2)
	for p in [Vector3(-1.6, 4.5, -77.0), Vector3(1.8, 4.5, -79.6), Vector3(-5.4, 4.5, -82.4), Vector3(5.0, 4.5, -79.0)]:
		enfeite("Bush_4_A_Color1", p, 2.4, p.z)


## 7. Três plataformas indo e voltando, subindo até a última ilha, com estrelinhas no caminho.
func _plataformas_que_se_mexem() -> void:
	movel("4x4x1", "yellow", Vector3(0, 4.5, -92.5), Vector3(0, 0, -5.0), 4.5)
	movel("4x4x1", "green", Vector3(3.5, 6.0, -103.6), Vector3(-7.0, 0, 0), 5.0, 1.2)
	movel("4x4x1", "red", Vector3(0, 7.5, -109.6), Vector3(0, 0, -5.0), 4.5, 2.4)
	trilha(Vector3(0, 5.5, -93.0), Vector3(0, 5.5, -97.0), 2)
	trilha(Vector3(-3.0, 7.0, -103.6), Vector3(3.0, 7.0, -103.6), 2)
	estrelinha(Vector3(0, 8.5, -112.0))


## 8. Ilha do Baú: três Bolotas guardam o baú grande com a Estrela Grande. O V3 fica numa
## beiradinha mais baixa do lado da ilha, com uma mola para voltar.
func _ilha_do_bau() -> void:
	morro("12x12x4", Vector3(0, 9.0, -124.75))
	colocar_bau(Vector3(0, 9.0, -127.0))
	bolota(Vector3(-3.0, 9.0, -122.6))
	bolota(Vector3(3.0, 9.0, -123.2))
	bolota(Vector3(0, 9.0, -129.6))
	roda(Vector3(0, 9.9, -127.0), 3.4, 3)
	morro("4x4x4", Vector3(8.5, 6.0, -126.0))
	vaga_lume(Vector3(8.6, 7.1, -124.6))
	mola(Vector3(8.6, 6.0, -127.4))
	arvore(4, 5, Vector3(-5.0, 9.0, -129.8), 1.1)
	arvore(1, 6, Vector3(4.8, 9.0, -130.2), 1.0)
	for p in [Vector3(-5.2, 9.0, -120.4), Vector3(5.2, 9.0, -120.0)]:
		enfeite("Bush_2_A_Color1", p, 2.6, p.x)
