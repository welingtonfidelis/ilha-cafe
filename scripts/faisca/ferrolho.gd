class_name Ferrolho
extends StaticBody3D
## Ferrolho laranja da 3-3 Moinhos do Vento (2026-11-12): a trava de um moinho de gôndolas (o freio na janela do
## eixo) ou de uma janela do Moinho Gigante. Fica no alto, ao lado do topo de uma coluna de vento, onde o Faísca chega
## com a pipa. Um soco (ou o giro) puxa a trava, com confete e o "clac", e avisa a fase (`aberto`). Fica no grupo dos
## alvos dos golpes; aberto, conta como derrotado. Enquanto fechado e o Faísca perto, pisca de leve: é a deixa.
## O nó fica um pouco abaixo da trava, na altura de onde o Faísca bate (os golpes medem do pé do alvo).

signal aberto(f: Ferrolho)

var aberto_ja := false
var derrotado: bool:
	get:
		return aberto_ja
var raio_golpe := 1.2

var _trava: Node3D
var _mat: StandardMaterial3D
var _tempo := 0.0


func _ready() -> void:
	add_to_group(Alvo.GRUPO)
	collision_layer = 1
	collision_mask = 0
	var escuro := StandardMaterial3D.new()
	escuro.albedo_color = Color("3a3150")
	escuro.metallic = 0.4
	escuro.roughness = 0.4
	var placa := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = Vector3(1.3, 1.3, 0.16)
	placa.mesh = caixa
	placa.material_override = escuro
	placa.position = Vector3(0, 1.2, 0)
	add_child(placa)
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = caixa.size
	cs.shape = forma
	cs.position = placa.position
	add_child(cs)
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color("ff7a22")
	_mat.emission_enabled = true
	_mat.emission = Color("ff7a22")
	_mat.emission_energy_multiplier = 0.2
	_trava = Node3D.new()
	_trava.position = Vector3(0, 1.2, 0.14)
	add_child(_trava)
	var barra := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(1.0, 0.26, 0.2)
	barra.mesh = b
	barra.material_override = _mat
	_trava.add_child(barra)
	var puxador := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.2
	esfera.height = 0.4
	puxador.mesh = esfera
	puxador.material_override = _mat
	puxador.position = Vector3(0.5, 0, 0.12)
	_trava.add_child(puxador)


func receber_golpe(_dano: int, _de: Vector3, _forca := 6.0, _tipo := "") -> bool:
	if aberto_ja:
		return false
	abrir()
	return true


## Puxa a trava (ela gira para cima e apaga), com confete e o "clac".
func abrir() -> void:
	aberto_ja = true
	_mat.emission_energy_multiplier = 0.0
	_mat.albedo_color = Color("c9a227")
	var tw := create_tween()
	tw.tween_property(_trava, "rotation:z", PI / 2.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Fx.confetti(get_parent(), _trava.global_position, 18, 2.5)
	Sfx.play_at(get_parent(), "ui_ok", global_position, -2.0)
	Sfx.play_at(get_parent(), "bonk", _trava.global_position, -4.0, 0.1)
	aberto.emit(self)


func _process(delta: float) -> void:
	_tempo += delta
	if not aberto_ja:
		_mat.emission_energy_multiplier = 0.25 + 0.35 * (0.5 + 0.5 * sin(_tempo * 4.0))
