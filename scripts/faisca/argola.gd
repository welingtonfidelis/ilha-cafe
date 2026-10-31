class_name Argola
extends Node3D
## Argola no ar (a hoop do Platformer Pack), pedido do usuário em 2026-10-29: o Faísca passa por dentro pulando
## ou flutuando e ela acende (fica dourada, gira um pouco e solta confete). A fase conta as acesas e, com todas,
## solta uma chuva de estrelinhas. A abertura fica no plano XY do nó (atravessa-se andando em Z).

signal acesa(argola: Argola)

## Meio da abertura, acima do pé da argola, e o raio de dentro (na escala 1).
const MEIO := 2.35
const RAIO := 1.35

var cor := "red"
var escala := 1.2
var esta_acesa := false
var _modelo: Node3D


func _ready() -> void:
	_modelo = load(Fase.PLATAFORMA + "hoop_%s.gltf" % cor).instantiate()
	_modelo.scale = Vector3.ONE * escala
	# O aro se atravessa (é para passar por dentro dele).
	add_child(Fase.so_enfeite(_modelo))
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = Fase.CAMADA_JOGADOR
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = RAIO * escala
	cil.height = 0.9
	cs.shape = cil
	cs.rotation.x = PI / 2.0
	cs.position.y = MEIO * escala
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(func(corpo: Node3D) -> void:
		if corpo is Jogador and not esta_acesa:
			acender())


## Centro da abertura, no mundo (os testes passam o Faísca por aqui).
func centro() -> Vector3:
	return global_position + global_basis.y * MEIO * escala


func acender() -> void:
	esta_acesa = true
	var dourado := StandardMaterial3D.new()
	dourado.albedo_color = Color("ffd23f")
	dourado.emission_enabled = true
	dourado.emission = Color("ffb800")
	dourado.emission_energy_multiplier = 1.2
	dourado.roughness = 0.3
	for mi in _modelo.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = dourado
	var tw := create_tween()
	tw.tween_property(_modelo, "rotation:z", TAU, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Fx.confetti(get_parent(), centro(), 24, 3.0)
	Sfx.play_at(get_parent(), "bandeira", centro(), -3.0)
	acesa.emit(self)
