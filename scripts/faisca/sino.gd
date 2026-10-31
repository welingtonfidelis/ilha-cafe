class_name Sino
extends Node3D
## Sino laranja (o bell do Holiday Bits), a peça da Luva de Neve na 3-1 Pico Gelado (2026-10-30). Fica longe e alto,
## pendurado num arquinho escuro, e só a bola de neve da luva alcança (Jogador.jogar_bola_de_neve). Quando o Faísca
## tem a luva e está ao alcance, ele balança e pulsa: é a deixa. Acertado, faz "dlém", balança forte, fica aceso e
## avisa (`tocou`): a fase liga cada sino a uma coisa (a cadeirinha, a escada de gelo, a cachoeira, a porta do cume).
## Fica alto demais para encostar, então é enfeite (o revisor de física não cobra colisão). O nó fica no pé do arco.

signal tocou(sino: Sino)

const GRUPO := "sinos"
## Altura do meio do sino acima do nó.
const ALTURA := 2.4

var tocado := false
var _sino: Node3D
var _mat: StandardMaterial3D
var _tempo := 0.0
var _balanco := 0.0


func _ready() -> void:
	add_to_group(GRUPO)
	Fase.so_enfeite(self)
	_tempo = randf() * 4.0
	var ferro := StandardMaterial3D.new()
	ferro.albedo_color = Color("3a3150")
	ferro.roughness = 0.6
	for spec in [[Vector3(-1.3, 1.7, 0), Vector3(0.22, 3.4, 0.22)], [Vector3(1.3, 1.7, 0), Vector3(0.22, 3.4, 0.22)], [Vector3(0, 3.45, 0), Vector3(2.9, 0.25, 0.25)]]:
		var barra := MeshInstance3D.new()
		var caixa := BoxMesh.new()
		caixa.size = spec[1]
		barra.mesh = caixa
		barra.material_override = ferro
		barra.position = spec[0]
		add_child(barra)
	_sino = Node3D.new()
	_sino.position.y = 3.35
	add_child(_sino)
	var modelo: Node3D = load("res://assets/faisca/neve/bell.gltf").instantiate()
	modelo.scale = Vector3.ONE * 2.2
	modelo.position.y = -0.4 * 2.2 + 0.05
	_sino.add_child(modelo)
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color("ff7a22")
	_mat.roughness = 0.3
	_mat.metallic = 0.4
	_mat.emission_enabled = true
	_mat.emission = Color("ff8a2a")
	_mat.emission_energy_multiplier = 0.15
	for mi in modelo.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = _mat


## O meio do sino (onde a bola de neve acerta).
func ponto() -> Vector3:
	return global_position + Vector3.UP * ALTURA


func _process(delta: float) -> void:
	_tempo += delta
	_balanco = maxf(_balanco - delta * 0.6, 0.0)
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	var chama := not tocado and j != null and j.luva_de_neve and j.global_position.distance_to(ponto()) < Jogador.ALCANCE_LUVA
	if tocado:
		_mat.emission_energy_multiplier = 0.9
	else:
		_mat.emission_energy_multiplier = 1.4 + 0.7 * sin(_tempo * 6.0) if chama else 0.15
	var amplitude := 0.12 + (0.12 if chama else 0.0) + _balanco * 0.6
	_sino.rotation.z = sin(_tempo * (2.2 + _balanco * 5.0)) * amplitude


## A bola de neve acertou: "dlém", balança forte, fica aceso e avisa a fase (uma vez só).
func tocar() -> void:
	if tocado:
		return
	tocado = true
	_balanco = 1.0
	_mat.albedo_color = Color("ffb13d")
	_mat.emission = Color("ffd23f")
	Sfx.play_at(get_parent(), "sino", ponto(), 2.0)
	Fx.confetti(get_parent(), ponto(), 22, 3.0)
	tocou.emit(self)
