class_name Faisquinha
extends Area3D
## Faisquinha: os robozinhos ajudantes do farol, que as Bolotas prenderam em bolhas pelas fases. Era o vaga-lume
## (item 1 da lista de melhorias do Faísca, pedido do usuário em 2026-11-11, inspirado nos robôs perdidos do Astro
## Bot). Seis por fase: os três de antes (ids "0" a "2", que o save já conhecia), mais dois em bolsos ("3" e "4")
## e um que uma Bolota leva pendurado ("5"), que só se solta quando ela é vencida.
## Parece um Faísca pequenininho (uns 0,9 m): capacete branco com tela preta e olhos ciano, a antena com a luzinha
## verde-limão de quando era vaga-lume, e o corpo, as orelhas e os pés na cor dele (cada id tem a sua, a de CORES).
## O nó fica 0,5 m acima dos pés. Estados:
## - "preso": na bolha lilás das Bolotas, flutuando; encostar estoura a bolha e ele está salvo;
## - "carregado": na bolha, amarrado em cima de uma Bolota (`dono`), sem dar para encostar;
## - "caindo" e "solto": vencida a Bolota, a bolha estoura e ele cai no chão, pulando e acenando até o Faísca encostar;
## - "salvo": pula, acena para o Faísca e sobe girando para o farol;
## - "morador": no farol (HubFarol), sem bolha e 1,3x maior, brincando perto da casa dele, olhando e acenando para
##   o Faísca, dançando junto quando ele dança no mesmo andar e pulando para o lado quando ele esbarra.
## Perto dele (pedido da lista, item 2), quem ainda não foi salvo chama com um "piu-piu" de robô e o controle treme
## de leve, mais rápido quanto mais perto. Já salvo em outra vez (`ja_visto`), a bolha tem só uma moeda dentro, que
## sai quando ela estoura, e não chama (pedido do usuário em 2026-11-12: antes era o mesmo boneco transparente, e
## não dava para saber se era um novo).

signal salvo(f: Faisquinha)

const CORES := [Color("ff7a22"), Color("4aa3ff"), Color("ff6fa8"), Color("4cc27a"), Color("a77bff"), Color("ffc93a")]
const RAIO_BOLHA := 0.62
## Altura do meio da bolha acima do pé da Bolota que leva ele.
const ALTURA_NA_BOLOTA := 2.6
## Até onde ele chama, e até onde o controle treme.
const CHAMA := 14.0
const TREME := 9.0
const ESCALA_MORADOR := 1.3

var id := "0"
var ja_visto := false
var encontrado := false
var estado := "preso"
var dono: Alvo
var morador := false
## No farol: onde ele mora (o pé) e para onde olha quando não tem nada para fazer.
var casa := Vector3.ZERO
var olhar_casa := 0.0
## Quantos "piu-piu" ele já deu (os testes olham).
var chamados := 0
var corpo: Node3D
var bolha: MeshInstance3D
var _bracos: Array[Node3D] = []
var _pernas: Array[Node3D] = []
var _luz_antena: OmniLight3D
var _fio: MeshInstance3D
var _tempo := 0.0
var _chamar := 0.0
var _pulso := 0.0
var _jogador: Jogador
var _origem_dono := Vector3.ZERO
var _acao := ""
var _acao_t := 0.0
var _proxima := 2.0
var _salto := 0.0
var _empurrao := Vector3.ZERO
var _acenando := 0.0
var _base := Vector3.ZERO
## A moeda girando dentro da bolha do já salvo.
var _moeda: Node3D

static var _materiais := {}
static var _malhas := {}


static func cor_de(i: int) -> Color:
	return CORES[posmod(i, CORES.size())]


func _ready() -> void:
	collision_layer = 0
	collision_mask = Fase.CAMADA_JOGADOR
	var cs := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 0.9
	cs.shape = esfera
	add_child(cs)
	_tempo = randf() * 6.0
	_proxima = randf_range(1.0, 4.0)
	corpo = boneco(cor_de(int(id)))
	add_child(corpo)
	corpo.position.y = -0.5
	for n in ["BracoE", "BracoD"]:
		_bracos.append(corpo.get_node(n))
	for n in ["PernaE", "PernaD"]:
		_pernas.append(corpo.get_node(n))
	_luz_antena = OmniLight3D.new()
	_luz_antena.light_color = Color("c6ff4a")
	_luz_antena.light_energy = 1.1
	_luz_antena.omni_range = 2.6
	_luz_antena.position.y = 0.97
	corpo.add_child(_luz_antena)
	if morador:
		estado = "morador"
		monitoring = false
		# No farol (uma sala de 32 m), um pouco maiores para aparecerem de longe.
		corpo.scale = Vector3.ONE * ESCALA_MORADOR
	else:
		bolha = MeshInstance3D.new()
		var esf := SphereMesh.new()
		esf.radius = RAIO_BOLHA
		esf.height = RAIO_BOLHA * 2.0
		esf.radial_segments = 24
		esf.rings = 12
		bolha.mesh = esf
		bolha.material_override = _material_bolha()
		add_child(bolha)
		body_entered.connect(_encostou)
		if ja_visto:
			# Já salvo: no lugar dele, a moeda das Bolotas (a do Board Game Bits, em pé, girando).
			corpo.visible = false
			_moeda = (load(Moeda.MODELO) as PackedScene).instantiate()
			_moeda.scale = Vector3.ONE * 0.6
			_moeda.rotation.x = PI / 2.0
			# Um brilho dourado, para ela aparecer dourada através do lilás da bolha.
			for mi: MeshInstance3D in _moeda.find_children("*", "MeshInstance3D", true, false):
				var original := mi.get_active_material(0) as StandardMaterial3D
				var ouro := original.duplicate() as StandardMaterial3D if original else StandardMaterial3D.new()
				ouro.emission_enabled = true
				ouro.emission = Color("ffb21a")
				ouro.emission_energy_multiplier = 0.9
				mi.material_override = ouro
			var giro := Node3D.new()
			giro.name = "MoedaNaBolha"
			add_child(giro)
			giro.add_child(_moeda)
			_moeda = giro
	_base = position
	if dono:
		_amarrar()


## Passa o Faisquinha preso para outro pai, em `local` dele (o patinho que boia na enchente da 2-1): o balanço
## dele passa a ser em volta desse lugar novo.
func prender_em(pai: Node3D, local: Vector3) -> void:
	reparent(pai)
	position = local
	_base = local


func _process(delta: float) -> void:
	_tempo += delta
	if not is_instance_valid(_jogador):
		_jogador = get_tree().get_first_node_in_group("jogador") as Jogador
	match estado:
		"preso":
			corpo.position.y = -0.5 + sin(_tempo * 2.2) * 0.06
			position.y = _base.y + sin(_tempo * 1.6) * 0.08
			if _moeda:
				_moeda.rotation.y += delta * 2.5
			_balancar_bolha()
			_pose_na_bolha()
			_chamar_o_faisca(delta)
		"carregado":
			_seguir_dono()
			if _moeda:
				_moeda.rotation.y += delta * 2.5
			_balancar_bolha()
			_pose_na_bolha()
			_chamar_o_faisca(delta)
		"solto":
			_pulinhos_de_espera(delta)
			_chamar_o_faisca(delta)
		"morador":
			_brincar(delta)


# --- na bolha e pendurado -------------------------------------------------------------

func _balancar_bolha() -> void:
	if bolha:
		var s := 1.0 + sin(_tempo * 3.1) * 0.035
		bolha.scale = Vector3(s, 2.0 - s, s)


## Na bolha: encolhido, com os bracinhos para cima, empurrando a bolha.
func _pose_na_bolha() -> void:
	for i in 2:
		var lado := -1.0 if i == 0 else 1.0
		_bracos[i].rotation.z = lado * (2.3 + sin(_tempo * 5.0 + i) * 0.25)
		_pernas[i].rotation.x = 0.35 + sin(_tempo * 3.0 + i * 1.7) * 0.2
	corpo.rotation.y = sin(_tempo * 0.7) * 0.5


## Bolota levando ele: amarra a bolha em cima dela, com um fio, e guarda onde ela estava (para cair num lugar firme
## se ela for vencida longe de qualquer chão).
func carregar(b: Alvo) -> void:
	dono = b
	if is_inside_tree():
		_amarrar()


func _amarrar() -> void:
	estado = "carregado"
	_origem_dono = dono.global_position
	set_deferred("monitoring", false)
	_fio = MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.015
	cil.bottom_radius = 0.015
	cil.height = 1.0
	_fio.mesh = cil
	_fio.material_override = _mat(Color("f4f5f9"), false)
	_fio.top_level = true
	add_child(_fio)
	dono.derrotada.connect(func(_a: Alvo) -> void: _soltar_do_dono())
	_seguir_dono()


func _seguir_dono() -> void:
	if not is_instance_valid(dono):
		_soltar_do_dono()
		return
	var alvo := dono.global_position + Vector3.UP * ALTURA_NA_BOLOTA + Vector3(sin(_tempo * 1.3), 0, cos(_tempo * 1.1)) * 0.15
	global_position = global_position.lerp(alvo, 0.35) if global_position.distance_to(alvo) < 3.0 else alvo
	# O fio vai da cabeça da Bolota até o pé da bolha.
	var de := dono.global_position + Vector3.UP * 1.55
	var ate := global_position - Vector3.UP * RAIO_BOLHA
	_fio.global_position = (de + ate) * 0.5
	var d := ate - de
	if d.length() > 0.05:
		_fio.global_basis = Basis(Quaternion(Vector3.UP, d.normalized())) * Basis.from_scale(Vector3(1, d.length(), 1))


## A Bolota foi vencida: a bolha estoura e ele cai no chão embaixo (ou no lugar de onde ela saiu, se embaixo não
## tiver chão), e fica pulando até o Faísca encostar.
func _soltar_do_dono() -> void:
	if estado != "carregado":
		return
	dono = null
	if is_instance_valid(_fio):
		_fio.queue_free()
	if ja_visto:
		# Só a moeda: a bolha estoura lá em cima e ela sai dali mesmo.
		salvar()
		return
	estado = "caindo"
	_estourar_bolha()
	var chao := _chao_embaixo(global_position)
	if is_nan(chao.x):
		chao = _chao_embaixo(_origem_dono + Vector3.UP * 1.0)
	if is_nan(chao.x):
		chao = _origem_dono
	var destino := chao + Vector3.UP * 0.5
	var tw := create_tween()
	tw.tween_property(self, "global_position", global_position.lerp(destino, 0.5) + Vector3.UP * 1.0, 0.25) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position", destino, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		estado = "solto"
		Fx.dust(get_parent(), chao)
		monitoring = true)


func _chao_embaixo(de: Vector3) -> Vector3:
	var espaco := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(de, de + Vector3.DOWN * 9.0, 1)
	var r := espaco.intersect_ray(q)
	return r.position if not r.is_empty() else Vector3(NAN, NAN, NAN)


## Solto, no chão: pulinhos e aceno, virado para o Faísca.
func _pulinhos_de_espera(delta: float) -> void:
	var fase := fmod(_tempo * 1.6, 1.0)
	corpo.position.y = -0.5 + maxf(sin(fase * PI), 0.0) * 0.35
	_olhar_para_o_faisca(delta, 6.0)
	_acenar(delta, 1.0)


func _estourar_bolha() -> void:
	if not is_instance_valid(bolha):
		return
	Fx.bubble_pop(get_parent(), bolha.global_position)
	Sfx.play_at(get_parent(), "estouro", global_position, -4.0, 0.1)
	bolha.queue_free()
	bolha = null


# --- chamando o Faísca (item 2) ----------------------------------------------------------

func _chamar_o_faisca(delta: float) -> void:
	if ja_visto or encontrado or not is_instance_valid(_jogador) or not _jogador.controle_ligado:
		return
	var d := global_position.distance_to(_jogador.global_position)
	_chamar -= delta
	if d < CHAMA and _chamar <= 0.0:
		_chamar = randf_range(2.4, 3.2)
		chamados += 1
		_acenando = 0.6
		Sfx.play_at(get_parent(), "faisquinha_chama", global_position, -3.0, 0.08)
	_pulso -= delta
	if d < TREME and _pulso <= 0.0:
		var perto := clampf((d - 2.0) / (TREME - 2.0), 0.0, 1.0)
		_pulso = lerpf(0.4, 1.4, perto)
		_jogador.tremidinha(lerpf(0.35, 0.12, perto))
	if _acenando > 0.0:
		_acenando -= delta
		_bracos[1].rotation.z = 2.6 + sin(_tempo * 18.0) * 0.4
	_luz_antena.light_energy = 1.1 + (1.2 if _acenando > 0.0 else 0.0)


# --- salvo ---------------------------------------------------------------------------

func _encostou(c: Node3D) -> void:
	if not c is Jogador or encontrado or estado in ["carregado", "caindo"]:
		return
	salvar(c as Jogador)


## Estoura a bolha (se ainda tiver), pula, acena para o Faísca e sobe girando para o farol.
func salvar(quem: Jogador = null) -> void:
	if encontrado:
		return
	encontrado = true
	estado = "salvo"
	set_deferred("monitoring", false)
	_estourar_bolha()
	if ja_visto:
		# A bolha da moeda: estoura e pronto. A Fase solta uma moeda de verdade no lugar desta, que vai para o Faísca.
		salvo.emit(self)
		hide()
		return
	if quem:
		quem.robo.expressao("coracao", 1.2)
		var para := quem.global_position - global_position
		corpo.rotation.y = atan2(para.x, para.z)
	Sfx.play(get_parent(), "faisquinha_salvo")
	Fx.confetti(get_parent(), global_position + Vector3.UP * 0.4, 14, 2.0)
	salvo.emit(self)
	var tw := create_tween()
	for k in 2:
		tw.tween_property(corpo, "position:y", 0.15, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(_bracos[0], "rotation:z", -2.7, 0.16)
		tw.parallel().tween_property(_bracos[1], "rotation:z", 2.7, 0.16)
		tw.tween_property(corpo, "position:y", -0.5, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(corpo, "position:y", 6.0, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(corpo, "rotation:y", corpo.rotation.y + TAU * 3.0, 1.1)
	tw.parallel().tween_property(corpo, "scale", Vector3.ONE * 0.01, 0.4).set_delay(0.7)
	tw.chain().tween_callback(hide)


# --- morador do farol ----------------------------------------------------------------

## No farol: perto da casa, olhando o Faísca quando ele chega perto, de vez em quando um pulinho, um giro ou um aceno;
## quando ele dança, dança junto; quando ele esbarra, pula para o lado e volta devagar.
func _brincar(delta: float) -> void:
	# O andar inteiro dança junto (no mesmo andar: a menos de 4 m de altura).
	var dancando := is_instance_valid(_jogador) and _jogador.dancando > 0.0 \
			and absf(_jogador.global_position.y - global_position.y) < 4.0 \
			and _jogador.global_position.distance_to(global_position) < 26.0
	var perto := is_instance_valid(_jogador) and _jogador.global_position.distance_to(global_position) < 5.0
	# Esbarrão: pula para longe do Faísca.
	if is_instance_valid(_jogador) and _salto <= 0.0:
		var d := global_position - _jogador.global_position
		d.y = 0.0
		if d.length() < 1.1 and absf(_jogador.global_position.y - global_position.y) < 1.5:
			_empurrao = d.normalized() * 1.6 if d.length() > 0.05 else Vector3.RIGHT * 1.6
			_salto = 0.45
			Sfx.play_at(get_parent(), "faisquinha_chama", global_position, -10.0, 0.2)
	var pe := global_position - Vector3.UP * 0.5
	if _salto > 0.0:
		_salto -= delta
		pe += _empurrao * delta / 0.45
		corpo.position.y = -0.5 + sin((1.0 - maxf(_salto, 0.0) / 0.45) * PI) * 0.5
	else:
		# Volta devagar para perto de casa.
		var para_casa := casa - pe
		para_casa.y = 0.0
		if para_casa.length() > 0.3:
			pe += para_casa.normalized() * minf(para_casa.length(), 0.8 * delta)
	global_position = Vector3(pe.x, casa.y, pe.z) + Vector3.UP * 0.5
	if dancando:
		_acao = "danca"
	elif _acao == "danca":
		_acao = ""
	_acao_t += delta
	match _acao:
		"danca":
			corpo.position.y = -0.5 + absf(sin(_tempo * 6.3)) * 0.22
			corpo.rotation.y += delta * 4.0
			for i in 2:
				var lado := -1.0 if i == 0 else 1.0
				_bracos[i].rotation.z = lado * (2.4 + sin(_tempo * 12.6 + i * PI) * 0.4)
		"pulo":
			corpo.position.y = -0.5 + maxf(sin(_acao_t / 0.5 * PI), 0.0) * 0.45
			if _acao_t > 0.5:
				_acao = ""
		"giro":
			corpo.rotation.y += delta * TAU * 1.5
			if _acao_t > 0.66:
				_acao = ""
		"aceno":
			_acenar(delta, 1.0)
			if _acao_t > 1.4:
				_acao = ""
		_:
			if _salto <= 0.0:
				corpo.position.y = lerpf(corpo.position.y, -0.5 + sin(_tempo * 2.0) * 0.02, 1.0 - exp(-8.0 * delta))
			for i in 2:
				var lado := -1.0 if i == 0 else 1.0
				_bracos[i].rotation.z = lerpf(_bracos[i].rotation.z, lado * 0.25, 1.0 - exp(-6.0 * delta))
			_proxima -= delta
			if _proxima <= 0.0:
				_proxima = randf_range(2.5, 6.0)
				_acao = ["pulo", "giro", "aceno", "pulo"][randi() % 4] if not perto else "aceno"
				_acao_t = 0.0
	if _acao != "danca" and _acao != "giro":
		if perto:
			_olhar_para_o_faisca(delta, 5.0)
		else:
			corpo.rotation.y = lerp_angle(corpo.rotation.y, olhar_casa, 1.0 - exp(-2.0 * delta))
	for i in 2:
		_pernas[i].rotation.x = lerpf(_pernas[i].rotation.x, 0.0, 1.0 - exp(-8.0 * delta))


func _olhar_para_o_faisca(delta: float, rapidez: float) -> void:
	if not is_instance_valid(_jogador):
		return
	var para := _jogador.global_position - global_position
	corpo.rotation.y = lerp_angle(corpo.rotation.y, atan2(para.x, para.z), 1.0 - exp(-rapidez * delta))


## O braço direito acena (o esquerdo fica abaixado).
func _acenar(_delta: float, forca: float) -> void:
	_bracos[1].rotation.z = 2.5 * forca + sin(_tempo * 14.0) * 0.45
	_bracos[0].rotation.z = -0.25


## Festa no farol (prêmio novo): pulinho e aceno.
func comemorar() -> void:
	_acao = "pulo"
	_acao_t = randf() * -0.4


## Chegada no farol (salvo agora há pouco): cai do alto girando, com confete.
func chegar() -> void:
	var de := corpo.position
	corpo.position.y = 7.0
	corpo.scale = Vector3.ONE * 0.4
	var tw := create_tween()
	tw.tween_interval(randf_range(0.2, 1.2))
	tw.tween_property(corpo, "position:y", de.y, 0.7).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(corpo, "scale", Vector3.ONE * ESCALA_MORADOR, 0.4)
	tw.parallel().tween_property(corpo, "rotation:y", corpo.rotation.y + TAU * 2.0, 0.7)
	tw.tween_callback(func() -> void:
		Fx.confetti(get_parent(), global_position + Vector3.UP * 0.4, 12, 1.6)
		_acao = "pulo"
		_acao_t = 0.0)


# --- o boneco ------------------------------------------------------------------------

## O robozinho (pé em y = 0, olhando para +Z), com os braços e as pernas em nós próprios (BracoE, BracoD, PernaE,
## PernaD) para mexer. As malhas e os materiais são de todos (cache), o que deixa leve ter 40 no farol.
static func boneco(cor: Color, fantasma := false) -> Node3D:
	var raiz := Node3D.new()
	var branco := _mat(Color("f4f5f9"), fantasma)
	var acento := _mat(cor, fantasma)
	var preto := _mat(Color("15121f"), fantasma)
	_peca(raiz, "tronco", acento, Vector3(0, 0.36, 0))
	_peca(raiz, "barriga", branco, Vector3(0, 0.34, 0.12))
	_peca(raiz, "cabeca", branco, Vector3(0, 0.66, 0))
	_peca(raiz, "tela", preto, Vector3(0, 0.655, 0.155))
	_peca(raiz, "antena", branco, Vector3(0, 0.89, 0))
	_peca(raiz, "luz", _brilho(Color("c6ff4a"), fantasma), Vector3(0, 0.98, 0))
	for lado in [-1.0, 1.0]:
		_peca(raiz, "olho", _brilho(Color("8ff3ff"), fantasma), Vector3(0.062 * lado, 0.67, 0.205))
		_peca(raiz, "orelha", acento, Vector3(0.215 * lado, 0.66, 0)).rotation.z = PI / 2.0
		var braco := Node3D.new()
		braco.name = "BracoE" if lado < 0.0 else "BracoD"
		braco.position = Vector3(0.165 * lado, 0.47, 0)
		raiz.add_child(braco)
		_peca(braco, "braco", branco, Vector3(0, -0.09, 0))
		_peca(braco, "mao", acento, Vector3(0, -0.2, 0))
		var perna := Node3D.new()
		perna.name = "PernaE" if lado < 0.0 else "PernaD"
		perna.position = Vector3(0.075 * lado, 0.22, 0)
		raiz.add_child(perna)
		_peca(perna, "perna", branco, Vector3(0, -0.09, 0))
		_peca(perna, "pe", acento, Vector3(0, -0.19, 0.02))
	return raiz


## Uma peça do boneco, com a malha `chave` do cache.
static func _peca(pai: Node3D, chave: String, material: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _malha(chave)
	mi.material_override = material
	mi.position = pos
	pai.add_child(mi)
	return mi


static func _malha(chave: String) -> Mesh:
	if _malhas.has(chave):
		return _malhas[chave]
	var m: Mesh
	match chave:
		"tronco":
			m = Forma.ovo(Vector3(0.16, 0.17, 0.14))
		"barriga":
			m = Forma.superelipsoide(Vector3(0.1, 0.1, 0.035), 1.0, 1.0)
		"cabeca":
			m = Forma.superelipsoide(Vector3(0.22, 0.19, 0.2), 0.8, 0.8)
		"tela":
			m = Forma.superelipsoide(Vector3(0.17, 0.12, 0.06), 0.6, 0.6)
		"pe":
			m = Forma.superelipsoide(Vector3(0.055, 0.035, 0.08), 0.8, 0.8)
		"olho", "braco", "perna":
			var c := CapsuleMesh.new()
			c.radius = {"olho": 0.027, "braco": 0.034, "perna": 0.04}[chave]
			c.height = {"olho": 0.08, "braco": 0.2, "perna": 0.18}[chave]
			m = c
		"orelha", "antena":
			var c := CylinderMesh.new()
			c.top_radius = 0.06 if chave == "orelha" else 0.012
			c.bottom_radius = c.top_radius
			c.height = 0.06 if chave == "orelha" else 0.14
			m = c
		"mao", "luz":
			var e := SphereMesh.new()
			e.radius = 0.045 if chave == "mao" else 0.05
			e.height = e.radius * 2.0
			m = e
	_malhas[chave] = m
	return m


static func _mat(cor: Color, fantasma: bool) -> StandardMaterial3D:
	var chave := "%s/%s" % [cor.to_html(), fantasma]
	if not _materiais.has(chave):
		var m := StandardMaterial3D.new()
		m.albedo_color = cor
		m.roughness = 0.4
		if fantasma:
			m.albedo_color.a = 0.4
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_materiais[chave] = m
	return _materiais[chave]


static func _brilho(cor: Color, fantasma: bool) -> StandardMaterial3D:
	var chave := "brilho/%s/%s" % [cor.to_html(), fantasma]
	if not _materiais.has(chave):
		var m := StandardMaterial3D.new()
		m.albedo_color = cor
		m.emission_enabled = true
		m.emission = cor
		m.emission_energy_multiplier = 0.8 if fantasma else 2.2
		if fantasma:
			m.albedo_color.a = 0.4
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_materiais[chave] = m
	return _materiais[chave]


## A bolha lilás das Bolotas: transparente, com a borda clarinha e um brilho fraco.
func _material_bolha() -> StandardMaterial3D:
	var chave := "bolha"
	if not _materiais.has(chave):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.86, 0.62, 1.0, 0.26)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.05
		m.metallic_specular = 1.0
		m.rim_enabled = true
		m.rim = 1.0
		m.rim_tint = 0.2
		m.emission_enabled = true
		m.emission = Color("b48cff")
		m.emission_energy_multiplier = 0.35
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materiais[chave] = m
	return _materiais[chave]
