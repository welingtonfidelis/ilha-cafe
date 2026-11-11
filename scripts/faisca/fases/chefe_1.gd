class_name Chefe1
extends Fase
## Chefe do andar 1: o Bolotão Fofão no Ninho das Nuvens (item 5 da lista de melhorias do Faísca, 2026-11-11; a porta
## no térreo do farol, ao norte-nordeste, abre com as 2 Estrelas Grandes do mundo 1). Uma ilha redonda de grama
## (RAIO m) no meio das nuvens, com uma parede invisível na beira (não dá para cair) e árvores em volta, uma roda de
## 12 estrelinhas e o chefe no meio. A luta (ChefeBolotao) tem três fases; aqui ficam:
## - a onda de choque do pisão (um anel que cresce pelo chão; quem está no chão quando ela passa perde um coração);
## - a sombra de onde ele vai cair;
## - as Bolotinhas que ele cospe na fase 2 (um soco deixa tonta, para agarrar e arremessar nele);
## - as 4 flores de luz da fase 3 (acesas todas com o laser, a luz deixa ele tonto);
## - um coração no meio da arena a cada fase nova, e no fim 40 moedas e o baú dourado que cai do céu com a estrela.

## O chefe vencido conta assim (FaiscaJogo) e não entra nas Estrelas Grandes.
const ID := "chefe-1"
const RAIO := 15.0
const ONDA_ATE := 14.0
const ONDA_TEMPO := 1.4
const FLORES := [45.0, 135.0, 225.0, 315.0]

signal faixa_pedida(titulo: String, sub: String)

var chefe: ChefeBolotao
var bolotinhas: Array[BolotaMonstro] = []
var flores_do_chefe: Array[FlorDeLuz] = []
## Quantas ondas acertaram o Faísca (os testes olham).
var ondas_que_acertaram := 0
var _ondas: Array[Dictionary] = []
var _comecou := false
var _espera := 1.2


func _montar() -> void:
	nome = "Chefe: Bolotão Fofão"
	superficie = "grama"
	inicio = Vector3(0, 0.1, 11.0)
	limite_queda = -10.0
	farol(Vector3(-80, -14, -300), 2.0)
	_ilha()
	roda(Vector3(0, 1.0, 0), RAIO - 2.2, 12)
	chefe = ChefeBolotao.new()
	chefe.name = "Bolotao"
	chefe.arena = self
	chefe.position = Vector3(0, 0, -3.0)
	add_child(chefe)
	chefe.fase_mudou.connect(_fase_mudou)
	chefe.vencido.connect(_vitoria)


## A ilha redonda: o tampo de grama, a borda de terra, a pedra por baixo, as árvores e a parede invisível.
func _ilha() -> void:
	var corpo := StaticBody3D.new()
	add_child(corpo)
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = RAIO + 0.6
	cil.height = 2.0
	cs.shape = cil
	cs.position.y = -1.0
	corpo.add_child(cs)
	for spec in [[RAIO + 0.6, RAIO + 0.6, 0.6, -0.3, Color("8ad16a")], [RAIO + 0.5, RAIO - 0.4, 1.4, -1.3, Color("a8794e")],
			[RAIO - 0.4, 3.0, 7.0, -5.5, Color("9aa3b5")]]:
		var mi := MeshInstance3D.new()
		var forma := CylinderMesh.new()
		forma.top_radius = spec[0]
		forma.bottom_radius = spec[1]
		forma.height = spec[2]
		forma.radial_segments = 48
		mi.mesh = forma
		mi.material_override = _material(spec[4])
		mi.position.y = spec[3]
		add_child(mi)
	# A parede invisível da beira, mais alta que o pulo com os jatos.
	var muro := StaticBody3D.new()
	add_child(muro)
	for k in 32:
		var a := TAU * k / 32.0
		var parte := CollisionShape3D.new()
		var caixa := BoxShape3D.new()
		caixa.size = Vector3(2.0 * PI * RAIO / 32.0 + 0.6, 6.0, 0.6)
		parte.shape = caixa
		parte.position = Vector3(sin(a), 0, cos(a)) * (RAIO + 0.2) + Vector3.UP * 3.0
		parte.rotation.y = a
		muro.add_child(parte)
	# Árvores e arbustos na beira (enfeite, de fora da parede).
	# Só os modelos que já estão na pasta da build (os da 1-1).
	var tipos := [[1, 8], [4, 1], [2, 5], [5, 6], [4, 7]]
	for k in 10:
		var a := TAU * (k + 0.5) / 10.0
		var p := Vector3(sin(a), 0, cos(a)) * (RAIO - 0.6)
		if absf(angle_difference(a, 0.0)) < 0.5:
			continue
		arvore(tipos[k % tipos.size()][0], tipos[k % tipos.size()][1], p, 0.8 + (k % 3) * 0.15, a)


func _process(delta: float) -> void:
	super(delta)
	_atualizar_ondas(delta)
	if _comecou:
		return
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	if j == null or not j.controle_ligado or not j.is_on_floor():
		return
	_espera -= delta
	if _espera <= 0.0 or j.global_position.distance_to(chefe.global_position) < 9.0:
		comecar_luta()


func comecar_luta() -> void:
	if _comecou:
		return
	_comecou = true
	faixa_pedida.emit("Bolotão Fofão!", "O capitão do Rei Bolotão quer a coroa das nuvens")
	chefe.comecar()


func _fase_mudou(f: int) -> void:
	if f == 2:
		faixa_pedida.emit("Agora ele cospe Bolotinhas!", "Um soco deixa a Bolotinha tonta: agarre e jogue nele")
		dica.emit("agarrar")
	elif f == 3:
		faixa_pedida.emit("Ele ficou bravo!", "Acenda as 4 flores com o laser para deixar ele tonto")
		novas_flores()
		dica.emit("laser")
	if f >= 2 and f <= 3:
		coracao(Vector3(0, 1.4, 6.0))
	if f >= 3:
		for b in bolotinhas:
			if is_instance_valid(b) and not b.derrotado:
				b._derrotar()


# --- a onda de choque e a sombra -------------------------------------------------------

## A onda do pisão: um anel claro que sai de `centro` e cresce até ONDA_ATE em ONDA_TEMPO.
func onda(centro: Vector3) -> void:
	var anel := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 0.75
	toro.outer_radius = 1.0
	toro.rings = 48
	anel.mesh = toro
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.92, 0.45, 0.95)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	anel.material_override = m
	add_child(anel)
	anel.global_position = Vector3(centro.x, 0.25, centro.z)
	_ondas.append({"anel": anel, "centro": Vector3(centro.x, 0, centro.z), "t": 0.0, "acertou": false})
	tremer_chao(centro, 0.8)
	Fx.dust(self, centro)


func _atualizar_ondas(delta: float) -> void:
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	for o in _ondas.duplicate():
		o.t += delta
		var r: float = ONDA_ATE * o.t / ONDA_TEMPO
		var anel: MeshInstance3D = o.anel
		# O toro de raio 1 escalado: a faixa fica com uns 0,6 m de largura e 0,75 m de altura, bem amarela para a
		# criança ver chegando.
		anel.scale = Vector3(maxf(r, 0.1), 3.0, maxf(r, 0.1))
		(anel.material_override as StandardMaterial3D).albedo_color.a = 0.95 * (1.0 - 0.6 * o.t / ONDA_TEMPO)
		if j and not o.acertou and j.is_on_floor():
			var d := Vector2(j.global_position.x - o.centro.x, j.global_position.z - o.centro.z).length()
			if absf(d - r) < 0.8 and j.global_position.y < 1.2:
				o.acertou = true
				if j.receber_dano(o.centro):
					ondas_que_acertaram += 1
		if o.t >= ONDA_TEMPO:
			anel.queue_free()
			_ondas.erase(o)


## A sombra escura de onde ele vai cair, crescendo durante o voo.
func sombra(onde: Vector3, voo: float) -> void:
	var s := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = ChefeBolotao.RAIO + 0.4
	disco.bottom_radius = disco.top_radius
	disco.height = 0.02
	s.mesh = disco
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.1, 0.05, 0.2, 0.0)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	s.material_override = m
	s.name = "Sombra"
	add_child(s)
	s.global_position = Vector3(onde.x, 0.03, onde.z)
	s.scale = Vector3(0.3, 1, 0.3)
	var tw := s.create_tween().set_parallel()
	tw.tween_property(s, "scale", Vector3.ONE, voo)
	tw.tween_property(m, "albedo_color:a", 0.45, voo)
	tw.chain().tween_callback(s.queue_free)


## O tremor do chão (no controle) quando ele cai ou bate na beira, mais forte perto.
func tremer_chao(onde: Vector3, forca: float) -> void:
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	if j:
		var perto := clampf(1.0 - j.global_position.distance_to(onde) / 20.0, 0.2, 1.0)
		j.tremidinha(forca * perto)


# --- as Bolotinhas e as flores -------------------------------------------------------------

func bolotinhas_vivas() -> int:
	return bolotinhas.filter(func(b: BolotaMonstro) -> bool: return is_instance_valid(b) and not b.derrotado).size()


## Uma Bolotinha que sai da boca dele e cai na arena: 2 de vida, e um soco já deixa tonta. Não solta estrelinhas
## (para não dar para juntar estrelinhas sem fim), só 1 moeda.
func cuspir_bolotinha(de: Vector3, frente: Vector3) -> void:
	var b := BolotaMonstro.new("alien")
	b.vida_max = 2
	b.chance_tontura = 1.0
	b.position = to_local(de)
	b.set_meta("do_chefe", true)
	add_child(b)
	b.velocity = frente * 6.0 + Vector3.UP * 5.0
	b.derrotada.connect(func(a: Alvo) -> void: soltar_moedas(a.global_position + Vector3.UP * 0.4, 1))
	bolotinhas.append(b)
	Sfx.play_at(self, "estouro", de, -2.0, 0.1)


## As 4 flores da fase 3, apagadas, perto da beira (as de antes somem).
func novas_flores() -> void:
	for f in flores_do_chefe:
		if is_instance_valid(f):
			f.queue_free()
	flores_do_chefe.clear()
	for g in FLORES:
		var a := deg_to_rad(g)
		var f := FlorDeLuz.new()
		f.scale = Vector3.ONE * 1.4
		add_child(f)
		f.position = Vector3(sin(a), 0, cos(a)) * (RAIO - 4.0)
		f.acesa.connect(_flor_do_chefe_acesa)
		flores_do_chefe.append(f)
		Fx.confetti(self, f.global_position + Vector3.UP, 10, 2.0)


func _flor_do_chefe_acesa(_f: FlorDeLuz) -> void:
	Sfx.play(self, "estrelinha")
	if flores_do_chefe.all(func(f: FlorDeLuz) -> bool: return f.esta_acesa):
		# A luz das quatro sobe e cai nele.
		for f in flores_do_chefe:
			Fx.confetti(self, f.global_position + Vector3.UP * 1.5, 16, 3.0)
		Fx.shockwave(self, chefe.global_position, 6.0)
		chefe.cansar()


# --- a vitória --------------------------------------------------------------------------

func _vitoria() -> void:
	faixa_pedida.emit("Você venceu o Bolotão Fofão!", "Abra o baú dourado")
	soltar_moedas(chefe.global_position + Vector3.UP * 1.0, 40, 4.0)
	var b := colocar_bau(Vector3(0, 9.0, 0), PI, true)
	var tw := b.create_tween()
	tw.tween_property(b, "position:y", 0.0, 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: Fx.confetti(self, b.global_position + Vector3.UP * 1.5, 40, 4.0))
