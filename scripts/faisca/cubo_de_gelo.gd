class_name CuboDeGelo
extends StaticBody3D
## Pinguim filhote preso num cubo de gelo (3-1 Pico Gelado, 2026-10-30): o laser dos pés derrete o gelo (flutuar em
## cima dele, como nas flores de luz). O cubo some num estalo, e o pinguim pula de alegria e fica lá, batendo as
## asinhas. O cubo é sólido (dá para subir nele) e fica também na camada que o laser enxerga. O nó fica no chão,
## embaixo do meio do cubo.

signal solto(cubo: CuboDeGelo)

const LADO := 2.4
const ALTO := 2.6

var derretido := false
var _cubo: MeshInstance3D
var _caixa: CollisionShape3D
var _pinguim: Node3D
var _tempo := 0.0


func _ready() -> void:
	collision_layer = 1 | Fase.CAMADA_LUZ
	collision_mask = 0
	_tempo = randf() * 3.0
	_pinguim = Node3D.new()
	add_child(_pinguim)
	var azul := _material(Color("1d2340"))
	var branco := _material(Color("f4fbff"))
	var laranja := _material(Color("ff8a2a"))
	_parte(_esfera(0.55, 1.35), azul, Vector3(0, 0.75, 0))
	_parte(_esfera(0.42, 1.0), branco, Vector3(0, 0.7, 0.22))
	_parte(_esfera(0.38, 0.76), azul, Vector3(0, 1.55, 0))
	var bico := CylinderMesh.new()
	bico.top_radius = 0.0
	bico.bottom_radius = 0.11
	bico.height = 0.3
	_parte(bico, laranja, Vector3(0, 1.5, 0.42)).rotation.x = PI / 2.0
	for lado in [-1.0, 1.0]:
		_parte(_esfera(0.07, 0.14), branco, Vector3(0.14 * lado, 1.62, 0.32))
		_parte(_esfera(0.14, 0.4), azul, Vector3(0.52 * lado, 0.85, 0)).rotation.z = 0.5 * lado
		_parte(_esfera(0.16, 0.12), laranja, Vector3(0.2 * lado, 0.06, 0.15))
	_cubo = MeshInstance3D.new()
	var malha := BoxMesh.new()
	malha.size = Vector3(LADO, ALTO, LADO)
	_cubo.mesh = malha
	_cubo.material_override = Gelo.material_cubo()
	_cubo.position.y = ALTO * 0.5
	add_child(_cubo)
	_caixa = CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(LADO, ALTO, LADO)
	_caixa.shape = forma
	_caixa.position.y = ALTO * 0.5
	add_child(_caixa)


func _process(delta: float) -> void:
	_tempo += delta
	if derretido:
		_pinguim.rotation.y = sin(_tempo * 3.0) * 0.5
	else:
		_pinguim.rotation.y = sin(_tempo * 1.5) * 0.25


## O laser chegou: o gelo derrete e o pinguim sai pulando.
func acender() -> void:
	if derretido:
		return
	derretido = true
	collision_layer = 1
	Sfx.play_at(get_parent(), "gelo", global_position, 0.0)
	Fx.confetti(get_parent(), global_position + Vector3.UP * 1.6, 24, 3.0)
	var tw := create_tween()
	tw.tween_property(_cubo, "scale", Vector3(1.15, 0.05, 1.15), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(_cubo.hide)
	# Depois do gelo, só o pinguim (uma colisão do tamanho dele).
	var pequeno := CylinderShape3D.new()
	pequeno.radius = 0.6
	pequeno.height = 1.9
	_caixa.set_deferred("shape", pequeno)
	_caixa.set_deferred("position", Vector3(0, 0.95, 0))
	var pulos := create_tween().set_loops(3)
	pulos.tween_property(_pinguim, "position:y", 0.9, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pulos.tween_property(_pinguim, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	solto.emit(self)


func _parte(malha: Mesh, mat: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = mat
	mi.position = pos
	_pinguim.add_child(mi)
	return mi


func _esfera(raio: float, altura: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = raio
	s.height = altura
	return s


func _material(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.5
	return m
