class_name MaquinaDeBrindes
extends StaticBody3D
## A Máquina de Brindes do térreo do farol (item 4 da lista de melhorias do Faísca, 2026-11-11), a máquina de cápsula
## do Astro Bot: base vermelha, a cúpula de vidro cheia de cápsulas coloridas, o botão amarelo na frente e a placa do
## preço (o número e uma moeda). O soco no botão (ela fica no grupo dos alvos, como o baú) pede um brinde (`pedido`);
## quem decide é o FaiscaJogo, que chama `soltar` (pagou) ou `negar` (faltam moedas, ou já tem tudo).
## Soltando: a máquina chacoalha, a cápsula sai pela boca e rola para a frente, abre com confete e o brinde sobe
## girando (`revelado`); depois voa para onde `destino` disser (a vaga da estante ou a cabeça do Faísca) e chega
## (`entregue`). O nó fica no chão, com a frente para +Z.

signal pedido
signal revelado(id: String)
signal entregue(id: String)

const CORES_CAPSULAS := [Color("ff5a7a"), Color("4aa3ff"), Color("ffd23f"), Color("4cc27a"), Color("a77bff"), Color("ff9a3c")]

## Para os golpes (grupo dos alvos): nunca derrotada, e o alcance do botão.
var derrotado := false
var raio_golpe := 0.9
var ocupada := false
var preco := Brindes.PRECO
var _imune := 0.0
var _corpo: Node3D
var _botao: MeshInstance3D
var _placa: Label3D
var _capsulas: Array[MeshInstance3D] = []


func _ready() -> void:
	add_to_group(Alvo.GRUPO)
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(1.7, 3.1, 1.5)
	cs.shape = caixa
	cs.position.y = 1.55
	add_child(cs)
	_corpo = Node3D.new()
	add_child(_corpo)
	var vermelho := _mat(Color("e8424f"))
	var dourado := _mat(Color("ffc93c"))
	dourado.metallic = 0.5
	dourado.roughness = 0.3
	var base := MeshInstance3D.new()
	base.mesh = Forma.caixa_redonda(Vector3(1.6, 1.3, 1.4), 0.18)
	base.material_override = vermelho
	base.position.y = 0.65
	_corpo.add_child(base)
	var faixa := MeshInstance3D.new()
	var anel := BoxMesh.new()
	anel.size = Vector3(1.64, 0.12, 1.44)
	faixa.mesh = anel
	faixa.material_override = dourado
	faixa.position.y = 1.22
	_corpo.add_child(faixa)
	# A boca de onde sai a cápsula, embaixo na frente.
	var boca := MeshInstance3D.new()
	var caixa_boca := BoxMesh.new()
	caixa_boca.size = Vector3(0.62, 0.42, 0.08)
	boca.mesh = caixa_boca
	boca.material_override = _mat(Color("2b2140"))
	boca.position = Vector3(0, 0.34, 0.7)
	_corpo.add_child(boca)
	_botao = MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.2
	cil.bottom_radius = 0.22
	cil.height = 0.14
	_botao.mesh = cil
	var amarelo := _mat(Color("ffd23f"))
	amarelo.emission_enabled = true
	amarelo.emission = Color("ffb800")
	amarelo.emission_energy_multiplier = 0.6
	_botao.material_override = amarelo
	_botao.rotation.x = PI / 2.0
	_botao.position = Vector3(0.42, 0.88, 0.74)
	_corpo.add_child(_botao)
	var pescoco := MeshInstance3D.new()
	var cil2 := CylinderMesh.new()
	cil2.top_radius = 0.55
	cil2.bottom_radius = 0.6
	cil2.height = 0.2
	pescoco.mesh = cil2
	pescoco.material_override = dourado
	pescoco.position.y = 1.38
	_corpo.add_child(pescoco)
	var cupula := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.85
	esfera.height = 1.7
	cupula.mesh = esfera
	var vidro := StandardMaterial3D.new()
	vidro.albedo_color = Color(0.85, 0.95, 1.0, 0.25)
	vidro.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidro.roughness = 0.05
	vidro.metallic_specular = 1.0
	vidro.rim_enabled = true
	cupula.material_override = vidro
	cupula.position.y = 2.2
	_corpo.add_child(cupula)
	var tampa := MeshInstance3D.new()
	var cil3 := CylinderMesh.new()
	cil3.top_radius = 0.22
	cil3.bottom_radius = 0.38
	cil3.height = 0.26
	tampa.mesh = cil3
	tampa.material_override = vermelho
	tampa.position.y = 3.08
	_corpo.add_child(tampa)
	# As cápsulas lá dentro, amontoadas na metade de baixo da cúpula.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in 16:
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.0, 0.5)
		var y := 1.65 + rng.randf_range(0.0, 0.5) + (0.5 - r) * 0.4
		var c := capsula(CORES_CAPSULAS[k % CORES_CAPSULAS.size()], 0.19)
		c.position = Vector3(cos(a) * r, y, sin(a) * r)
		c.rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, 0)
		_corpo.add_child(c)
		_capsulas.append(c)
	# A placa do preço, do lado esquerdo do botão: o número e uma moeda.
	_placa = Label3D.new()
	_placa.text = str(preco)
	_placa.font_size = 72
	_placa.pixel_size = 0.008
	_placa.outline_size = 16
	_placa.outline_modulate = Color(0.08, 0.06, 0.18)
	_placa.modulate = Color("ffd23f")
	_placa.position = Vector3(-0.42, 0.9, 0.73)
	_corpo.add_child(_placa)
	var moeda: Node3D = load(Moeda.MODELO).instantiate()
	moeda.scale = Vector3.ONE * 0.26
	moeda.rotation.x = PI / 2.0
	moeda.position = Vector3(-0.1, 0.9, 0.74)
	_corpo.add_child(moeda)
	var luz := OmniLight3D.new()
	luz.light_color = Color("ffe9a8")
	luz.light_energy = 1.0
	luz.omni_range = 4.0
	luz.position = Vector3(0, 2.2, 0.9)
	add_child(luz)


func _process(delta: float) -> void:
	_imune -= delta


## O soco no botão: ele afunda e a máquina pede o brinde.
func receber_golpe(_dano: int, _de: Vector3, _forca := 6.0, _tipo := "") -> bool:
	if ocupada or _imune > 0.0:
		return false
	_imune = 0.8
	var tw := _botao.create_tween()
	tw.tween_property(_botao, "position:z", 0.66, 0.06)
	tw.tween_property(_botao, "position:z", 0.74, 0.15)
	pedido.emit()
	return true


## Não dá (faltam moedas ou já tem tudo): balança de um lado para o outro e a placa do preço pisca.
func negar() -> void:
	Sfx.play_at(get_parent(), "bonk", global_position + Vector3.UP, -4.0, 0.05)
	var tw := _corpo.create_tween()
	for lado in [1.0, -1.0, 0.6, 0.0]:
		tw.tween_property(_corpo, "rotation:z", 0.06 * lado, 0.07)
	var piscar := _placa.create_tween()
	piscar.tween_property(_placa, "modulate", Color("ff5a5a"), 0.1)
	piscar.tween_property(_placa, "scale", Vector3.ONE * 1.3, 0.1)
	piscar.tween_property(_placa, "scale", Vector3.ONE, 0.15)
	piscar.tween_property(_placa, "modulate", Color("ffd23f"), 0.3)


## Pagou: a cápsula sai, abre e o brinde `id` voa até `destino` (chamado na hora, para seguir o Faísca andando).
func soltar(id: String, destino: Callable) -> void:
	ocupada = true
	Sfx.play_at(get_parent(), "maquina", global_position + Vector3.UP, 0.0, 0.0)
	# 1. Chacoalha, com as cápsulas pulando lá dentro.
	var tw := _corpo.create_tween()
	for k in 6:
		tw.tween_property(_corpo, "rotation:z", 0.05 * (1.0 if k % 2 == 0 else -1.0), 0.07)
	tw.tween_property(_corpo, "rotation:z", 0.0, 0.07)
	for c in _capsulas:
		var pula := c.create_tween()
		pula.tween_property(c, "position:y", c.position.y + randf_range(0.05, 0.2), 0.12)
		pula.tween_property(c, "position:y", c.position.y, 0.16)
	await tw.finished
	# 2. A cápsula sai pela boca e rola para a frente.
	var cor: Color = CORES_CAPSULAS[randi() % CORES_CAPSULAS.size()]
	var cap := capsula(cor, 0.3)
	add_child(cap)
	cap.position = Vector3(0, 0.32, 0.6)
	var rola := cap.create_tween()
	rola.tween_property(cap, "position", Vector3(0, 0.3, 1.9), 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	rola.parallel().tween_property(cap, "rotation:x", TAU * 1.5, 0.55)
	await rola.finished
	await get_tree().create_timer(0.25).timeout
	# 3. Abre: a metade de cima voa, confete, e o brinde sobe girando.
	Sfx.play_at(get_parent(), "estouro", cap.global_position, -2.0, 0.05)
	Fx.confetti(get_parent(), cap.global_position + Vector3.UP * 0.3, 40, 4.0)
	var meio := cap.global_position
	var abre := cap.create_tween()
	abre.tween_property(cap, "scale", Vector3.ONE * 0.01, 0.25)
	abre.tween_callback(cap.queue_free)
	var brinde := Brindes.modelo(id)
	var raiz := Node3D.new()
	raiz.name = "Brinde"
	get_parent().add_child(raiz)
	raiz.global_position = meio
	if brinde:
		raiz.add_child(brinde)
	raiz.scale = Vector3.ONE * 0.05
	var sobe := raiz.create_tween()
	sobe.tween_property(raiz, "global_position", meio + Vector3.UP * 1.4, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var grande := 1.6 if Brindes.dados(id).get("tipo", "") == "tinta" else 2.0
	sobe.parallel().tween_property(raiz, "scale", Vector3.ONE * grande, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play(get_parent(), "faisquinha_salvo")
	revelado.emit(id)
	var t := 0.0
	while t < 2.2 and is_instance_valid(raiz):
		await get_tree().process_frame
		t += get_process_delta_time()
		raiz.rotation.y += get_process_delta_time() * 2.5
	# 4. Voa até o destino e chega.
	if is_instance_valid(raiz):
		var de := raiz.global_position
		var voo := raiz.create_tween()
		voo.tween_method(func(k: float) -> void:
			var ate: Vector3 = destino.call() if destino.is_valid() else de
			raiz.global_position = de.lerp(ate, k) + Vector3.UP * sin(k * PI) * 1.5
			raiz.scale = Vector3.ONE * lerpf(grande, 1.0, k), 0.0, 1.0, 0.8).set_trans(Tween.TRANS_SINE)
		await voo.finished
		raiz.queue_free()
	ocupada = false
	entregue.emit(id)


## Uma cápsula de duas cores: a metade de cima na `cor`, a de baixo branca.
static func capsula(cor: Color, raio: float) -> MeshInstance3D:
	var cap := MeshInstance3D.new()
	var cima := SphereMesh.new()
	cima.radius = raio
	cima.height = raio * 2.0
	cima.is_hemisphere = true
	cap.mesh = cima
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.25
	cap.material_override = m
	var baixo := MeshInstance3D.new()
	var meia := SphereMesh.new()
	meia.radius = raio
	meia.height = raio * 2.0
	meia.is_hemisphere = true
	baixo.mesh = meia
	var branco := StandardMaterial3D.new()
	branco.albedo_color = Color("f4f5f9")
	branco.roughness = 0.25
	baixo.material_override = branco
	baixo.rotation.x = PI
	cap.add_child(baixo)
	return cap


func _mat(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.45
	return m
