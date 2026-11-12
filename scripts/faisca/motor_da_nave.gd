class_name MotorDaNave
extends StaticBody3D
## Motor da Sala de Máquinas da Nave Aspiratrão (a fase final do Faísca, 2026-11-12, da maquete aprovada pelo usuário):
## um bloco roxo de 6 x 3,5 x 6 m com faixas amarelas, dois pistões prateados batendo dos lados, as luzinhas piscando e
## o ronco. É sólido, e em cima fica o pino laranja (a fase põe o Pino em `topo()`): a pancada do Martelinho de Apito
## afunda o pino e o motor para (`parar`): os pistões descem, as luzes apagam e sai um puf de fumaça. O nó fica no chão,
## no meio do motor.

const TAMANHO := Vector3(6.0, 3.5, 6.0)

var parado := false

var _pistoes: Array[MeshInstance3D] = []
var _luzes: StandardMaterial3D
var _tempo := 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_tempo = randf() * 3.0
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = TAMANHO
	cs.shape = forma
	cs.position.y = TAMANHO.y * 0.5
	add_child(cs)
	var corpo := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = TAMANHO
	corpo.mesh = bm
	corpo.material_override = _cor(Color("6a4fb8"), 0.3)
	corpo.position.y = TAMANHO.y * 0.5
	add_child(corpo)
	for y in [0.7, 2.8]:
		var faixa := MeshInstance3D.new()
		var f := BoxMesh.new()
		f.size = Vector3(TAMANHO.x + 0.06, 0.3, TAMANHO.z + 0.06)
		faixa.mesh = f
		faixa.material_override = _cor(Color("ffd23f"), 0.0)
		faixa.position.y = y
		add_child(faixa)
	_luzes = _cor(Color("8ff3ff"), 0.0)
	_luzes.emission_enabled = true
	_luzes.emission = Color("8ff3ff")
	_luzes.emission_energy_multiplier = 1.5
	for k in 4:
		var luz := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.18
		s.height = 0.36
		luz.mesh = s
		luz.material_override = _luzes
		luz.position = Vector3(-1.5 + k, 1.75, TAMANHO.z * 0.5 + 0.05)
		add_child(luz)
	var prata := _cor(Color("c6ccd8"), 0.7)
	for lado in [-1.0, 1.0]:
		var camisa := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.7
		c.bottom_radius = 0.8
		c.height = 1.6
		camisa.mesh = c
		camisa.material_override = _cor(Color("3a3150"), 0.4)
		camisa.position = Vector3(lado * (TAMANHO.x * 0.5 + 0.8), 0.8, 0)
		add_child(Fase.so_enfeite(camisa))
		var pistao := MeshInstance3D.new()
		var p := CylinderMesh.new()
		p.top_radius = 0.42
		p.bottom_radius = 0.42
		p.height = 2.6
		pistao.mesh = p
		pistao.material_override = prata
		pistao.position = Vector3(lado * (TAMANHO.x * 0.5 + 0.8), 1.6, 0)
		add_child(Fase.so_enfeite(pistao))
		_pistoes.append(pistao)


## Onde fica o pino de parar (em cima, no meio).
func topo() -> Vector3:
	return global_position + Vector3.UP * TAMANHO.y


## O pino afundou: o motor para.
func parar() -> void:
	if parado:
		return
	parado = true
	_luzes.emission_energy_multiplier = 0.0
	_luzes.albedo_color = Color("4a4658")
	for p in _pistoes:
		p.create_tween().tween_property(p, "position:y", 1.1, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	Fx.confetti(get_parent(), topo() + Vector3.UP * 1.0, 24, 3.0)
	Sfx.play_at(get_parent(), "bonk", topo(), 2.0, 0.1)


func _process(delta: float) -> void:
	if parado:
		return
	_tempo += delta
	for i in _pistoes.size():
		_pistoes[i].position.y = 1.6 + absf(sin(_tempo * 3.2 + i * PI * 0.5)) * 1.4
	_luzes.emission_energy_multiplier = 0.8 + 0.8 * (0.5 + 0.5 * sin(_tempo * 6.0))


func _cor(cor: Color, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.metallic = metal
	m.roughness = 0.45
	return m
