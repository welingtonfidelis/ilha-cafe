class_name FlorDeLuz
extends StaticBody3D
## Flor de luz: começa apagada, com as pétalas fechadas e cinzinha. O laser dos pés acende
## (flutuar em cima dela): as pétalas abrem coloridas e o miolo brilha. Fica na camada que só o
## laser enxerga, então o Faísca passa por ela sem esbarrar.

signal acesa(flor: FlorDeLuz)

const PETALAS := 6

var esta_acesa := false
var _petalas: Array[MeshInstance3D] = []
var _miolo: MeshInstance3D
var _mat_petala: StandardMaterial3D
var _mat_miolo: StandardMaterial3D
var _luz: OmniLight3D
var _tempo := 0.0


func _ready() -> void:
	collision_layer = Fase.CAMADA_LUZ
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var forma := SphereShape3D.new()
	forma.radius = 0.75
	cs.shape = forma
	cs.position.y = 1.0
	add_child(cs)
	_tempo = randf() * 5.0

	var caule := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.05
	cil.bottom_radius = 0.07
	cil.height = 1.0
	caule.mesh = cil
	caule.position.y = 0.5
	caule.material_override = _material(Color("4caf50"))
	add_child(caule)
	for lado in [-1.0, 1.0]:
		var folha := MeshInstance3D.new()
		folha.mesh = Forma.superelipsoide(Vector3(0.22, 0.04, 0.1), 1.0, 1.0)
		folha.material_override = caule.material_override
		folha.position = Vector3(0.18 * lado, 0.35, 0)
		folha.rotation.z = 0.4 * lado
		add_child(folha)

	_mat_petala = _material(Color("c9c3d9"))
	_mat_miolo = _material(Color("8a8499"))
	for i in PETALAS:
		var p := MeshInstance3D.new()
		p.mesh = Forma.superelipsoide(Vector3(0.13, 0.04, 0.26), 1.0, 1.0)
		p.material_override = _mat_petala
		var giro := Node3D.new()
		giro.position.y = 1.02
		giro.rotation.y = TAU * i / PETALAS
		add_child(giro)
		giro.add_child(p)
		p.position = Vector3(0, 0, 0.22)
		p.rotation.x = -1.1  # fechada: pétalas para cima, em botão
		_petalas.append(p)
	_miolo = MeshInstance3D.new()
	_miolo.mesh = _esfera(0.15)
	_miolo.material_override = _mat_miolo
	_miolo.position.y = 1.05
	add_child(_miolo)
	_luz = OmniLight3D.new()
	_luz.position.y = 1.3
	_luz.light_color = Color("ffe680")
	_luz.light_energy = 0.0
	_luz.omni_range = 4.0
	add_child(_luz)


func _process(delta: float) -> void:
	_tempo += delta
	rotation.z = sin(_tempo * 1.3) * 0.04
	if esta_acesa:
		_mat_miolo.emission_energy_multiplier = 2.2 + sin(_tempo * 4.0) * 0.6


func acender() -> void:
	if esta_acesa:
		return
	esta_acesa = true
	_mat_petala.albedo_color = Color("ff8fc8")
	_mat_petala.emission_enabled = true
	_mat_petala.emission = Color("ff5fae")
	_mat_petala.emission_energy_multiplier = 0.6
	_mat_miolo.albedo_color = Color("ffe066")
	_mat_miolo.emission_enabled = true
	_mat_miolo.emission = Color("ffd23f")
	var tw := create_tween().set_parallel()
	for p in _petalas:
		tw.tween_property(p, "rotation:x", 0.15, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_luz, "light_energy", 1.4, 0.4)
	tw.tween_property(_miolo, "scale", Vector3.ONE * 1.4, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	acesa.emit(self)


func _material(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.5
	return m


func _esfera(raio: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = raio
	s.height = raio * 2.0
	return s
