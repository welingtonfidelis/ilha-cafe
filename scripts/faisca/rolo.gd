class_name RoloDeMassa
extends AnimatableBody3D
## Rolo de macarrão rolando de um lado para o outro da bancada (2-1 Cozinha Gigante): é pular por cima dele.
## Encostar empurra e tira um coração, como encostar numa Bolota. Vai e volta `caminho` em `periodo` segundos,
## girando como se rolasse. O rolo fica deitado com o comprimento em Z (atravessa o caminho do Faísca).

var caminho := Vector3(10, 0, 0)
var periodo := 4.0
var atraso := 0.0
## 4,5 vezes o modelo: 1,9 m de altura, dá para passar pulando (o pulo alto chega a uns 2,1 m).
var escala := 4.5
var _base := Vector3.ZERO
var _t := 0.0
var _visual: Node3D
var _raio := 1.0
var _area: Area3D


func _ready() -> void:
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	_base = position
	_t = atraso
	_raio = 0.21 * escala
	_visual = Node3D.new()
	_visual.position.y = _raio
	add_child(_visual)
	var rolo: Node3D = load(Fase.COZINHA + "rollingpin.gltf").instantiate()
	rolo.scale = Vector3.ONE * escala
	# O modelo deita no X; girado, fica em Z.
	rolo.rotation.y = PI / 2.0
	_visual.add_child(rolo)
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = _raio
	cil.height = 1.48 * escala
	cs.shape = cil
	cs.rotation.x = PI / 2.0
	cs.position.y = _raio
	add_child(cs)
	_area = Area3D.new()
	_area.collision_layer = 0
	_area.collision_mask = Fase.CAMADA_JOGADOR
	var forma := CollisionShape3D.new()
	var maior := CylinderShape3D.new()
	maior.radius = _raio + 0.35
	maior.height = 1.48 * escala
	forma.shape = maior
	forma.rotation.x = PI / 2.0
	forma.position.y = _raio
	_area.add_child(forma)
	add_child(_area)


func _physics_process(delta: float) -> void:
	_t += delta
	var antes := position
	position = _base + caminho * (0.5 - 0.5 * cos(TAU * _t / periodo))
	# Gira o quanto andou (rolando de verdade).
	_visual.rotation.z -= (position - antes).x / _raio
	for corpo in _area.get_overlapping_bodies():
		if corpo is Jogador:
			(corpo as Jogador).receber_dano(global_position + Vector3.UP * _raio)
