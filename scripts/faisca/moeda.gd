class_name Moeda
extends Area3D
## Moeda dourada do Faísca (item 4 da lista de melhorias dele, 2026-11-11): a moeda do Board Game Bits do KayKit,
## em pé, girando e subindo e descendo. Sai das Bolotas vencidas, dos Faisquinhas salvos e do baú (Fase.soltar_moedas)
## e vai para a carteira, que paga a Máquina de Brindes do farol. Como no Astro, elas voltam em cada visita.
## Perto do Faísca (IMA), ela voa até ele; encostar pega. Nasce sem dar para pegar por um instante (o pulinho de
## quando sai), e some sozinha depois de VIDA s se ninguém pegar.

signal pega(m: Moeda)

const MODELO := "res://assets/faisca/quarto/coin_gold.gltf"
const IMA := 3.5
const VIDA := 30.0

var pegavel := true
var _modelo: Node3D
var _tempo := 0.0
var _vida := VIDA
var _voando := false
var _jogador: Jogador
var _pega := false

static var _cena: PackedScene


func _ready() -> void:
	collision_layer = 0
	collision_mask = Fase.CAMADA_JOGADOR
	var cs := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 0.6
	cs.shape = esfera
	add_child(cs)
	if _cena == null:
		_cena = load(MODELO)
	_modelo = _cena.instantiate()
	# A ficha do pacote é deitada e tem 1 m: em pé, de frente, com uns 0,5 m.
	_modelo.scale = Vector3.ONE * 0.48
	_modelo.rotation.x = PI / 2.0
	var giro := Node3D.new()
	giro.name = "Giro"
	add_child(giro)
	giro.add_child(_modelo)
	_tempo = randf() * TAU
	body_entered.connect(_encostou)


func _process(delta: float) -> void:
	_tempo += delta
	var giro := get_node("Giro") as Node3D
	giro.rotation.y += delta * 3.5
	if _pega:
		return
	if not _voando:
		giro.position.y = sin(_tempo * 2.4) * 0.08
	_vida -= delta
	if _vida <= 0.0:
		queue_free()
		return
	if not pegavel:
		return
	if not is_instance_valid(_jogador):
		_jogador = get_tree().get_first_node_in_group("jogador") as Jogador
		return
	# O ímã: voa até o peito do Faísca, cada vez mais rápido.
	var peito := _jogador.global_position + Vector3.UP * 1.0
	var d := peito - global_position
	if _voando or d.length() < IMA:
		_voando = true
		global_position += d.normalized() * minf(d.length(), (6.0 + 14.0 * (1.0 - clampf(d.length() / IMA, 0.0, 1.0))) * delta)
		if d.length() < 0.5:
			_pegar()


func _encostou(corpo: Node3D) -> void:
	if corpo is Jogador and pegavel:
		_pegar()


func _pegar() -> void:
	if _pega:
		return
	_pega = true
	set_deferred("monitoring", false)
	Sfx.play(get_parent(), "moeda", -6.0, 0.12)
	pega.emit(self)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * 0.01, 0.12)
	tw.tween_callback(queue_free)
