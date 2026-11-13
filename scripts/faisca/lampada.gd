class_name Lampada
extends StaticBody3D
## Lâmpada da Nave Aspiratrão (a fase final do Faísca, 2026-11-12, da maquete aprovada pelo usuário): começa apagada,
## cinzinha, e o laser dos pés acende (flutuar em cima dela), como as flores de luz e as tochas. O corpo que o laser
## enxerga fica na camada da luz; o que é sólido fica à parte. Dois jeitos (`estilo`):
## - "pouso": a luz redonda no meio de uma plataforma de pouso do hangar (rente ao chão, quem pisa passa por cima);
## - "poste": o poste baixinho (1,6 m) da Sala do Trono, que o apagão deixa no escuro. Apagado e `chamando`, o bulbo
##   pisca fraquinho: é a deixa.
## Quem cuida do que acontece ao acender é a fase, pelo sinal `acendeu`. O nó fica no chão, no meio da lâmpada.

signal acendeu(l: Lampada)

const AMARELO := Color("ffe066")
const APAGADA := Color("6a5f96")

var estilo := "poste"
var acesa := false
var chamando := false

var _bulbo: MeshInstance3D
var _mat: StandardMaterial3D
var _luz: OmniLight3D
var _tempo := 0.0
var _altura_bulbo := 1.45


func _ready() -> void:
	collision_layer = Fase.CAMADA_LUZ
	collision_mask = 0
	_tempo = randf() * 4.0
	var escuro := StandardMaterial3D.new()
	escuro.albedo_color = Color("2b2140")
	escuro.metallic = 0.3
	escuro.roughness = 0.5
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = APAGADA
	_mat.roughness = 0.2
	_mat.emission_enabled = true
	_mat.emission = AMARELO
	_mat.emission_energy_multiplier = 0.0
	var area := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	if estilo == "pouso":
		_altura_bulbo = 0.18
		var aro := MeshInstance3D.new()
		var toro := TorusMesh.new()
		toro.inner_radius = 1.25
		toro.outer_radius = 1.6
		aro.mesh = toro
		var laranja := StandardMaterial3D.new()
		laranja.albedo_color = Color("ff7a22")
		aro.material_override = laranja
		aro.position.y = 0.08
		add_child(aro)
		_bulbo = MeshInstance3D.new()
		var disco := CylinderMesh.new()
		disco.top_radius = 1.2
		disco.bottom_radius = 1.25
		disco.height = 0.24
		_bulbo.mesh = disco
		_bulbo.position.y = 0.12
		cil.radius = 1.6
		cil.height = 1.2
	else:
		_altura_bulbo = 1.45
		var base := MeshInstance3D.new()
		var b := CylinderMesh.new()
		b.top_radius = 0.45
		b.bottom_radius = 0.6
		b.height = 0.3
		base.mesh = b
		base.material_override = escuro
		base.position.y = 0.15
		add_child(base)
		var poste := MeshInstance3D.new()
		var p := CylinderMesh.new()
		p.top_radius = 0.14
		p.bottom_radius = 0.2
		p.height = 1.1
		poste.mesh = p
		poste.material_override = escuro
		poste.position.y = 0.8
		add_child(poste)
		var chapeu := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.12
		c.bottom_radius = 0.62
		c.height = 0.3
		chapeu.mesh = c
		chapeu.material_override = escuro
		chapeu.position.y = 2.02
		add_child(chapeu)
		_bulbo = MeshInstance3D.new()
		var esfera := SphereMesh.new()
		esfera.radius = 0.48
		esfera.height = 0.96
		_bulbo.mesh = esfera
		_bulbo.position.y = _altura_bulbo
		# O poste em si é sólido (a camada de sempre), à parte da área do laser.
		var solido := StaticBody3D.new()
		add_child(solido)
		var cs := CollisionShape3D.new()
		var forma := CylinderShape3D.new()
		forma.radius = 0.3
		forma.height = 2.1
		cs.shape = forma
		cs.position.y = 1.05
		solido.add_child(cs)
		cil.radius = 1.0
		cil.height = 2.4
	_bulbo.material_override = _mat
	add_child(_bulbo)
	area.shape = cil
	area.position.y = cil.height * 0.5
	add_child(area)
	_luz = OmniLight3D.new()
	_luz.light_color = AMARELO
	_luz.light_energy = 0.0
	_luz.omni_range = 9.0 if estilo == "poste" else 7.0
	_luz.position.y = _altura_bulbo + 0.4
	_luz.visible = false
	add_child(_luz)


## O laser chegou: acende (uma vez só), com o brilho, o "plim" e confete, e avisa a fase.
func acender() -> void:
	if acesa:
		return
	acesa = true
	_mat.albedo_color = AMARELO
	_luz.visible = true
	var tw := create_tween()
	tw.tween_property(_mat, "emission_energy_multiplier", 2.6, 0.35)
	tw.parallel().tween_property(_luz, "light_energy", 2.4, 0.35)
	_bulbo.scale = Vector3.ONE * 1.35
	create_tween().tween_property(_bulbo, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	Fx.confetti(get_parent(), global_position + Vector3.UP * (_altura_bulbo + 0.4), 18, 2.5)
	Sfx.play_at(get_parent(), "brilha", global_position, 0.0, 0.05)
	acendeu.emit(self)


## Apaga de novo (o apagão da Sala do Trono).
func apagar() -> void:
	acesa = false
	_mat.albedo_color = APAGADA
	_mat.emission_energy_multiplier = 0.0
	_luz.light_energy = 0.0
	_luz.visible = false


## Onde fica o bulbo (para as câmeras e os testes).
func bulbo() -> Vector3:
	return global_position + Vector3.UP * _altura_bulbo


func _process(delta: float) -> void:
	_tempo += delta
	if not acesa:
		_mat.emission_energy_multiplier = (0.35 + 0.3 * sin(_tempo * 3.5)) if chamando else 0.0
