class_name PonteLevadica
extends Node3D
## Ponte levadiça do castelo de blocos (2-3 Quarto de Brinquedos): começa em pé, tapando o portão; `abaixar()` a
## deita devagar por cima da lava até o outro lado. O nó fica na dobradiça (o pé do portão, no meio), com a ponte
## deitada indo para +Z local.

const LARGURA := 4.0
const COMPRIMENTO := 8.0
const ESPESSURA := 0.5

var abaixada := false
var _tabua: AnimatableBody3D


func _ready() -> void:
	_tabua = AnimatableBody3D.new()
	_tabua.sync_to_physics = false
	add_child(_tabua)
	var madeira := StandardMaterial3D.new()
	madeira.albedo_color = Color("c98b55")
	madeira.roughness = 0.8
	var malha := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = Vector3(LARGURA, ESPESSURA, COMPRIMENTO)
	malha.mesh = caixa
	malha.material_override = madeira
	malha.position = Vector3(0, ESPESSURA * 0.5, COMPRIMENTO * 0.5)
	_tabua.add_child(malha)
	# Ripas escuras atravessadas e as duas correntes (enfeite).
	var escuro := StandardMaterial3D.new()
	escuro.albedo_color = Color("7a4a2a")
	for i in 5:
		var ripa := MeshInstance3D.new()
		var r := BoxMesh.new()
		r.size = Vector3(LARGURA + 0.1, 0.1, 0.25)
		ripa.mesh = r
		ripa.material_override = escuro
		ripa.position = Vector3(0, ESPESSURA + 0.03, 0.8 + i * 1.6)
		_tabua.add_child(ripa)
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(LARGURA, ESPESSURA, COMPRIMENTO)
	cs.shape = forma
	cs.position = malha.position
	_tabua.add_child(cs)
	_tabua.rotation.x = -PI / 2.0


func abaixar() -> void:
	if abaixada:
		return
	abaixada = true
	var tw := _tabua.create_tween()
	tw.tween_interval(0.4)
	tw.tween_property(_tabua, "rotation:x", 0.0, 1.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	Sfx.play_at(get_parent(), "remontar", global_position, 0.0)


## A ponte já está deitada (o tween acabou).
func no_lugar() -> bool:
	return abaixada and absf(_tabua.rotation.x) < 0.01
