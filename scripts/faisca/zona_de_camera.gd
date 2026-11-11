class_name ZonaDeCamera
extends Area3D
## Zona de câmera guiada (o começo do item 8 da lista do Faísca, 2026-11-11, feito para a corrida da Bolota gigante da
## 1-1): com o Faísca dentro, a câmera vai devagar para um ângulo fixo (`yaw`, `pitch`, `distancia`) e o analógico
## direito não gira; saindo, ela volta a ser a câmera solta. De lado, por exemplo: o Faísca corre da esquerda para a
## direita da tela e se vê onde cada pulo cai.

var yaw := 0.0
var pitch := -0.25
var distancia := 10.0
var tamanho := Vector3(10, 10, 10)
var _jogador: Jogador


func _ready() -> void:
	collision_layer = 0
	collision_mask = Fase.CAMADA_JOGADOR
	monitorable = false
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = tamanho
	cs.shape = caixa
	add_child(cs)
	body_entered.connect(func(corpo: Node3D) -> void:
		if corpo is Jogador:
			_jogador = corpo
			_jogador.camera_guiada = guia())
	body_exited.connect(func(corpo: Node3D) -> void:
		if corpo == _jogador and is_instance_valid(_jogador):
			if _jogador.camera_guiada == guia():
				_jogador.camera_guiada = {}
			_jogador = null)


func guia() -> Dictionary:
	return {"yaw": yaw, "pitch": pitch, "distancia": distancia}
