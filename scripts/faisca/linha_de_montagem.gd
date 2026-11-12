class_name LinhaDeMontagem
extends Node3D
## A linha de montagem disparada, o momento especial da 3-2 (item 9 da lista do Faísca, 2026-11-11): com a ponte de
## blocos pronta, a Máquina de Blocos dispara. O giroflex vermelho acende e gira, a sirene toca, sai vapor da boca da
## máquina e ela começa a cuspir blocos de brinquedo, que deslizam ponte abaixo (descem cada degrau) até cair lá
## embaixo. Eles vêm numa faixa ou na outra da ponte (dá para desviar) e, de vez em quando, um largo que pega as duas
## (só pulando). Quem um bloco pega é empurrado ponte abaixo, sem perder coração.

signal disparou
signal empurrou

## O caminho do pé dos blocos, da boca da máquina até onde eles caem (pontos seguidos: retas e quedas de degrau).
var caminho := PackedVector3Array()
## O lado da ponte (perpendicular ao caminho, no chão) e o deslocamento das duas faixas.
var lado := Vector3(0, 0, 1)
var faixa := 1.1
## Onde fica a boca da máquina (o giroflex e o vapor).
var boca := Vector3.ZERO
var velocidade := 4.0
var periodo := 2.8
## A ordem dos blocos: "A" e "B" são as faixas; "L" é o largo, que pega as duas.
var ordem := ["A", "B", "A", "L", "B", "A", "B", "L"]
var pasta_blocos := "res://assets/faisca/fabrica/"
var ligada := false
## Os testes param a linha para subir a ponte degrau por degrau sem blocos.
var pausada := false
var vezes_que_empurrou := 0
var blocos_soltos := 0

const PEQUENO := Vector3(1.6, 1.3, 1.6)
const LARGO := Vector3(1.6, 1.2, 4.4)

var _blocos: Array = []
var _tempo := 0.0
var _proximo := 0.0
var _jogador: Jogador
var _espera := 0.0
var _giroflex: Node3D
var _luz: OmniLight3D
var _comprimentos: Array[float] = []
var _total := 0.0


func _ready() -> void:
	for i in caminho.size() - 1:
		var c := caminho[i].distance_to(caminho[i + 1])
		_comprimentos.append(c)
		_total += c
	# O giroflex em cima da boca da máquina: apagado até a linha disparar.
	_giroflex = Node3D.new()
	_giroflex.position = boca + Vector3.UP * 3.4
	add_child(Fase.so_enfeite(_giroflex))
	var base := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.55
	cil.bottom_radius = 0.65
	cil.height = 0.3
	base.mesh = cil
	var cinza := StandardMaterial3D.new()
	cinza.albedo_color = Color("6a6478")
	base.material_override = cinza
	_giroflex.add_child(base)
	var cupula := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.5
	esfera.height = 0.8
	cupula.mesh = esfera
	var vermelho := StandardMaterial3D.new()
	vermelho.albedo_color = Color("ff3b3b")
	vermelho.emission_enabled = true
	vermelho.emission = Color("ff2020")
	vermelho.emission_energy_multiplier = 0.2
	cupula.material_override = vermelho
	cupula.position.y = 0.4
	_giroflex.add_child(cupula)
	_luz = OmniLight3D.new()
	_luz.light_color = Color("ff3030")
	_luz.light_energy = 0.0
	_luz.omni_range = 14.0
	_luz.position = Vector3(0.9, 0.5, 0)
	_giroflex.add_child(_luz)


## A máquina dispara: o giroflex acende, a sirene toca, sai vapor e, um instante depois, começam os blocos.
func disparar(j: Jogador = null) -> void:
	if ligada:
		return
	ligada = true
	_jogador = j
	disparou.emit()
	var cupula := _giroflex.get_child(1) as MeshInstance3D
	(cupula.material_override as StandardMaterial3D).emission_energy_multiplier = 3.0
	_luz.light_energy = 3.0
	Sfx.play_at(get_parent(), "alarme", boca, 4.0, 0.0)
	for k in 6:
		get_tree().create_timer(k * 0.25).timeout.connect(func() -> void: Fx.dust(get_parent(), boca + Vector3(randf_range(-1, 1), 2.0, randf_range(-1, 1))))
	if is_instance_valid(_jogador):
		_jogador.tremidinha(0.6)
	_proximo = 1.6


## Os blocos descendo agora (para os testes): cada um com o nó, a distância na linha, o desvio e o tamanho.
func blocos() -> Array:
	return _blocos


func _physics_process(delta: float) -> void:
	if ligada:
		_giroflex.rotation.y += delta * 6.0
		_luz.light_energy = 2.0 + sin(_tempo * 12.0) * 1.2
	if not ligada or pausada:
		return
	_tempo += delta
	_espera -= delta
	_proximo -= delta
	if _proximo <= 0.0:
		_proximo = periodo
		_soltar(ordem[blocos_soltos % ordem.size()])
	for k in range(_blocos.size() - 1, -1, -1):
		var b: Dictionary = _blocos[k]
		b.d += velocidade * delta
		var no := b.no as Node3D
		if b.d >= _total:
			_cair(no)
			_blocos.remove_at(k)
			continue
		var p := _no_caminho(b.d) + lado * float(b.desvio)
		no.global_position = p
		if is_instance_valid(_jogador) and _espera <= 0.0 and _jogador.controle_ligado and _pegou(p, b.tamanho):
			_empurrar(p)


## Solta um bloco da boca: na faixa A, na B, ou o largo.
func _soltar(tipo: String) -> void:
	blocos_soltos += 1
	var largo := tipo == "L"
	var tamanho := LARGO if largo else PEQUENO
	var no := Node3D.new()
	get_parent().add_child(Fase.so_enfeite(no))
	var n := 3 if largo else 1
	for i in n:
		# Amarelos: a ponte é de blocos vermelhos, azuis e verdes, e da mesma cor eles sumiam nela.
		var modelo: Node3D = load(pasta_blocos + "colored_block_yellow.gltf").instantiate()
		modelo.scale = Vector3.ONE * (tamanho.x * 0.5)
		modelo.scale.y = tamanho.y * 0.5
		# O pé do bloco no chão: o modelo tem o meio no centro (lado 2 m na escala 1).
		modelo.position = Vector3(0, tamanho.y * 0.5, 0) + lado * (tamanho.z / n) * (i - (n - 1) * 0.5)
		no.add_child(modelo)
	var desvio := 0.0 if largo else (-faixa if tipo == "A" else faixa)
	no.global_position = _no_caminho(0.0) + lado * desvio
	_blocos.append({"no": no, "d": 0.0, "desvio": desvio, "tamanho": tamanho})
	Sfx.play_at(get_parent(), "pistao", boca, -6.0, 0.1)


## O ponto do caminho a `d` metros da boca.
func _no_caminho(d: float) -> Vector3:
	var resta := d
	for i in _comprimentos.size():
		if resta <= _comprimentos[i]:
			return caminho[i].lerp(caminho[i + 1], resta / maxf(_comprimentos[i], 0.001))
		resta -= _comprimentos[i]
	return caminho[caminho.size() - 1]


## O Faísca dentro do bloco (com uma folguinha), sem estar por cima dele (pulando, passa).
func _pegou(p: Vector3, tamanho: Vector3) -> bool:
	var d := _jogador.global_position - p
	var r := Vector3(caminho[caminho.size() - 1].x - caminho[0].x, 0, caminho[caminho.size() - 1].z - caminho[0].z).normalized()
	var ao_longo := absf(d.dot(r))
	var de_lado := absf(d.dot(lado))
	# A folga de lado deixa o meio da ponte livre dos pequenos (só o largo pega ali).
	return ao_longo < tamanho.x * 0.5 + 0.4 and de_lado < tamanho.z * 0.5 + 0.3 and d.y < tamanho.y - 0.2 and d.y > -1.2


## O bloco pegou: empurra o Faísca ponte abaixo (sem perder coração), com o "bonk" e o controle tremendo.
func _empurrar(p: Vector3) -> void:
	_espera = 0.9
	vezes_que_empurrou += 1
	empurrou.emit()
	var r := Vector3(caminho[caminho.size() - 1].x - caminho[0].x, 0, caminho[caminho.size() - 1].z - caminho[0].z).normalized()
	_jogador.empurrar(r * 9.0 + Vector3.UP * 5.0)
	_jogador.robo.expressao("dor", 0.6)
	_jogador.tremidinha(0.5)
	Sfx.play_at(get_parent(), "bonk", p, 2.0, 0.05)


## No fim do caminho, o bloco tomba da ponte e cai lá embaixo, girando, e some.
func _cair(no: Node3D) -> void:
	var tw := no.create_tween()
	var fora := no.global_position - lado * 3.0 + Vector3.DOWN * 18.0
	tw.tween_property(no, "global_position", fora, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(no, "rotation", Vector3(2.5, 1.0, 1.8), 1.0)
	tw.tween_callback(no.queue_free)
