class_name ArgolaDeIoio
extends Node3D
## Argola laranja do Ioiô, o poder da 2-3 Quarto de Brinquedos (2026-10-30): com o ioiô, apertando o golpe no ar
## perto dela, o Faísca joga o ioiô, ele prende na argola e puxa o Faísca até lá (Jogador.ALCANCE_IOIO). Laranja é a
## cor do que faz alguma coisa. Quando o Faísca tem o ioiô e está perto o bastante, ela acende e pulsa: é a deixa.
## O nó fica no meio da argola.

const GRUPO := "argolas_ioio"

var acesa := false
var _mat: StandardMaterial3D
var _tempo := 0.0


func _ready() -> void:
	add_to_group(GRUPO)
	# A argola fica no ar e se atravessa: o ioiô puxa o Faísca para cima dela.
	Fase.so_enfeite(self)
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color("ff7a22")
	_mat.roughness = 0.35
	_mat.emission_enabled = true
	_mat.emission = Color("ff8a2a")
	_mat.emission_energy_multiplier = 0.2
	var aro := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 0.85
	toro.outer_radius = 1.2
	toro.rings = 32
	aro.mesh = toro
	aro.material_override = _mat
	aro.rotation.x = PI / 2.0
	add_child(aro)
	# Um pino escuro em cima, como se a argola estivesse presa em alguma coisa.
	var pino := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.12
	cil.bottom_radius = 0.12
	cil.height = 0.6
	pino.mesh = cil
	var escuro := StandardMaterial3D.new()
	escuro.albedo_color = Color("3a3150")
	pino.material_override = escuro
	pino.position.y = 1.4
	add_child(pino)


func _process(delta: float) -> void:
	_tempo += delta
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	acesa = j != null and j.ioio and j.global_position.distance_to(global_position) < Jogador.ALCANCE_IOIO
	_mat.emission_energy_multiplier = 1.6 + 0.8 * sin(_tempo * 6.0) if acesa else 0.2
	rotation.y += delta * (1.5 if acesa else 0.4)
