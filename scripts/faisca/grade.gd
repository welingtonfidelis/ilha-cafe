class_name Grade
extends StaticBody3D
## Grade de ferro no vão de uma porta da masmorra (pedido do usuário em 2026-10-29), feita por código: barras
## em pé e duas travessas. Fechada, segura o caminho. `abrir` sobe a grade para dentro da parede e solta a
## passagem. O nó fica no chão, no meio do vão (3 m de largura por 4,1 de altura, o vão da wall_doorway em 1,5x).

const LARGURA := 3.0
const ALTURA := 4.1

var aberta := false
var _forma: CollisionShape3D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var ferro := StandardMaterial3D.new()
	ferro.albedo_color = Color("4a4658")
	ferro.metallic = 0.6
	ferro.roughness = 0.4
	var barras := 8
	for i in barras:
		var b := MeshInstance3D.new()
		var cil := CylinderMesh.new()
		cil.top_radius = 0.07
		cil.bottom_radius = 0.07
		cil.height = ALTURA
		b.mesh = cil
		b.material_override = ferro
		b.position = Vector3(-LARGURA * 0.5 + 0.2 + i * (LARGURA - 0.4) / (barras - 1), ALTURA * 0.5, 0)
		add_child(b)
	for y in [0.9, ALTURA - 0.6]:
		var t := MeshInstance3D.new()
		var caixa := BoxMesh.new()
		caixa.size = Vector3(LARGURA, 0.16, 0.16)
		t.mesh = caixa
		t.material_override = ferro
		t.position = Vector3(0, y, 0)
		add_child(t)
	_forma = CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(LARGURA, ALTURA, 0.4)
	_forma.shape = forma
	_forma.position.y = ALTURA * 0.5
	add_child(_forma)


func abrir() -> void:
	if aberta:
		return
	aberta = true
	_forma.set_deferred("disabled", true)
	var tw := create_tween()
	tw.tween_interval(0.3)
	tw.tween_property(self, "position:y", position.y + ALTURA + 0.4, 1.2).set_trans(Tween.TRANS_SINE)
	Sfx.play_at(get_parent(), "remontar", global_position + Vector3.UP * 2.0, -3.0)
