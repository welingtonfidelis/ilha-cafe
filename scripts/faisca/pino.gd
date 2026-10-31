class_name Pino
extends StaticBody3D
## Pino laranja de bater, como o da bancadinha de martelar (3-2 Fábrica de Blocos, 2026-10-31): fica 1,6 m em pé e só
## afunda com a pancada do Martelinho de Apito (Jogador.martelinho). Pular em cima, socar ou acertar com o laser não
## faz nada. Batido, ele afunda rente à base com um "ploc" e avisa (`batido`): a fase liga o pistão dele, a esteira dos
## blocos... Quando o Faísca tem o martelinho e está perto, o pino pulsa: é a deixa. O nó fica no meio do chão.

signal batido(pino: Pino)

const GRUPO := "pinos"
const ALTURA := 1.6
const RAIO := 1.1
## Batido, sobra só a tampa branca, rente à base.
const ALTURA_BATIDO := 0.14

var batido_ja := false
var _pino: Node3D
var _forma: CollisionShape3D
var _mat: StandardMaterial3D
var _tempo := 0.0


func _ready() -> void:
	add_to_group(GRUPO)
	collision_layer = 1
	collision_mask = 0
	var base := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = RAIO + 0.45
	disco.bottom_radius = RAIO + 0.55
	disco.height = 0.12
	base.mesh = disco
	base.material_override = _material(Color("3a3f55"))
	base.position.y = 0.06
	add_child(base)
	_pino = Node3D.new()
	add_child(_pino)
	_mat = _material(Color("ff7a22"))
	_mat.emission_enabled = true
	_mat.emission = Color("ff8a2a")
	_mat.emission_energy_multiplier = 0.1
	var corpo := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = RAIO * 0.9
	cil.bottom_radius = RAIO * 0.9
	cil.height = ALTURA - 0.2
	corpo.mesh = cil
	corpo.material_override = _mat
	corpo.position.y = (ALTURA - 0.2) * 0.5
	_pino.add_child(corpo)
	var tampa := MeshInstance3D.new()
	var t := CylinderMesh.new()
	t.top_radius = RAIO
	t.bottom_radius = RAIO
	t.height = 0.2
	tampa.mesh = t
	tampa.material_override = _material(Color("fff6ec"))
	tampa.position.y = ALTURA - 0.1
	_pino.add_child(tampa)
	_forma = CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = RAIO
	forma.height = ALTURA
	_forma.shape = forma
	_forma.position.y = ALTURA * 0.5
	add_child(_forma)


func _process(delta: float) -> void:
	_tempo += delta
	if batido_ja:
		return
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	var chama := j != null and j.martelinho and j.global_position.distance_to(global_position) < 22.0
	_mat.emission_energy_multiplier = 0.8 + 0.6 * sin(_tempo * 6.0) if chama else 0.1


## Altura da tampa de cima (onde o Faísca pisa).
func topo() -> float:
	return global_position.y + (ALTURA_BATIDO if batido_ja else ALTURA)


## A pancada do martelinho: afunda (uma vez só) e avisa a fase.
func bater() -> bool:
	if batido_ja:
		return false
	batido_ja = true
	var desce := ALTURA - ALTURA_BATIDO
	var tw := create_tween().set_parallel()
	tw.tween_property(_pino, "position:y", -desce, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_forma, "position:y", ALTURA * 0.5 - desce, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_mat.emission = Color("ffd23f")
	_mat.emission_energy_multiplier = 0.6
	Fx.confetti(get_parent(), global_position + Vector3.UP * 1.0, 18, 2.5)
	Sfx.play_at(get_parent(), "ui_ok", global_position, -2.0)
	batido.emit(self)
	return true


func _material(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.55
	return m
