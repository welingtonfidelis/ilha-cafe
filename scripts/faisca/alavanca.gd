class_name Alavanca
extends StaticBody3D
## Alavanca do chão (a lever_floor_base do Platformer Pack), pedido do usuário em 2026-10-29: um soco (ou o giro)
## vira o cabo para o outro lado e abre a grade dela (Fase.portao_de_grade). Fica no grupo dos alvos dos
## golpes, como o baú e a parede rachada; o laser e o pisão não puxam.

signal puxada(alavanca: Alavanca)

var cor := "yellow"
var puxada_ja := false
## Para os golpes: puxada conta como derrotada (não vira mais alvo).
var derrotado: bool:
	get:
		return puxada_ja
var raio_golpe := 0.9
var _cabo: Node3D


func _ready() -> void:
	add_to_group(Alvo.GRUPO)
	collision_layer = 1
	collision_mask = 0
	var modelo: Node3D = load(Fase.PLATAFORMA + "lever_floor_base_%s.gltf" % cor).instantiate()
	modelo.scale = Vector3.ONE * 1.4
	add_child(modelo)
	for mi in modelo.find_children("*", "MeshInstance3D", true, false):
		if String(mi.name).begins_with("lever_floor_") and not String(mi.name).begins_with("lever_floor_base"):
			_cabo = mi
	if _cabo:
		_cabo.rotation.x = -0.6
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(1.2, 0.6, 1.7)
	cs.shape = caixa
	cs.position.y = 0.3
	add_child(cs)


func receber_golpe(_dano: int, _de: Vector3, _forca := 6.0) -> bool:
	if puxada_ja:
		return false
	puxar()
	return true


func puxar() -> void:
	puxada_ja = true
	if _cabo:
		var tw := create_tween()
		tw.tween_property(_cabo, "rotation:x", 0.6, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Fx.confetti(get_parent(), global_position + Vector3.UP * 1.2, 16, 2.5)
	Sfx.play_at(get_parent(), "ui_ok", global_position, -2.0)
	puxada.emit(self)
