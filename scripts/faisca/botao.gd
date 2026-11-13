class_name Botao
extends StaticBody3D
## Botão colorido no chão (a button_base do Platformer Pack), pedido do usuário em 2026-10-29: o Faísca pula e
## cai em cima dele, o botão afunda, acende e fica apertado. A fase junta os botões numa ponte: com todos
## apertados, as plataformas sobem do vão (Fase.ponte_dos_botoes).

signal apertado(botao: Botao)

var cor := "red"
var esta_apertado := false
var _tampa: MeshInstance3D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var modelo: Node3D = load(Fase.PLATAFORMA + "button_base_%s.gltf" % cor).instantiate()
	modelo.scale = Vector3.ONE * 1.3
	add_child(modelo)
	for mi in modelo.find_children("*", "MeshInstance3D", true, false):
		if String(mi.name).begins_with("button_") and not String(mi.name).begins_with("button_base"):
			_tampa = mi
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(2.2, 0.26, 2.2)
	cs.shape = caixa
	cs.position.y = 0.13
	add_child(cs)
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = Fase.CAMADA_JOGADOR
	var forma := CollisionShape3D.new()
	var topo := BoxShape3D.new()
	topo.size = Vector3(1.6, 0.6, 1.6)
	forma.shape = topo
	forma.position.y = 0.5
	area.add_child(forma)
	add_child(area)
	area.body_entered.connect(func(corpo: Node3D) -> void:
		if corpo is Jogador and corpo.velocity.y <= 0.5:
			apertar())


func apertar() -> void:
	if esta_apertado:
		return
	esta_apertado = true
	if _tampa:
		var tw := create_tween()
		tw.tween_property(_tampa, "position:y", _tampa.position.y - 0.14, 0.12).set_trans(Tween.TRANS_BACK)
		var m := StandardMaterial3D.new()
		var base_cor := {"red": Color("ff5d5d"), "yellow": Color("ffd23f"), "blue": Color("4aa8ff"), "green": Color("5fdc7a")}
		m.albedo_color = base_cor.get(cor, Color.WHITE)
		m.emission_enabled = true
		m.emission = m.albedo_color
		m.emission_energy_multiplier = 1.4
		_tampa.material_override = m
	Fx.confetti(get_parent(), global_position + Vector3.UP * 0.8, 18, 2.5)
	Sfx.play_at(get_parent(), "ui_ok", global_position, -2.0)
	apertado.emit(self)
