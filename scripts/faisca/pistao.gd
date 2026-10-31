class_name Pistao
extends AnimatableBody3D
## Pistão da Fábrica de Blocos (3-2, 2026-10-31): uma placa laranja em cima de uma coluna de ferro, que fica baixinha
## (0,4 m) até a fase ligar (a pancada no pino dele) e então sobe `sobe` m, levando quem estiver em cima. Um contorno
## laranja mostra até onde ele vai subir. Com `vai_e_volta`, depois de ligado ele fica subindo e descendo devagar, como
## elevador (o pistão alto do bolso do V2). O nó fica no chão, embaixo do meio da placa; a coluna continua para baixo
## do chão (dentro da bancada ou da saliência), para não aparecer vão quando ele sobe.

const PLACA := 0.4

var lado := 3.0
var sobe := 1.6
var vai_e_volta := false
## Segundos de uma ida e volta inteira (com uma paradinha em cada ponta).
var periodo := 8.0
var ligado := false
var _base_y := 0.0
var _subida := 0.0
var _t := 0.0
var _contorno: Node3D


func _ready() -> void:
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	_base_y = position.y
	var total := PLACA + sobe
	var ferro := StandardMaterial3D.new()
	ferro.albedo_color = Color("8a94ab")
	ferro.metallic = 0.4
	ferro.roughness = 0.5
	var coluna := MeshInstance3D.new()
	var c := BoxMesh.new()
	c.size = Vector3(lado * 0.62, total, lado * 0.62)
	coluna.mesh = c
	coluna.material_override = ferro
	coluna.position.y = PLACA - total * 0.5
	add_child(coluna)
	var placa := MeshInstance3D.new()
	placa.mesh = Forma.caixa_redonda(Vector3(lado, PLACA, lado), 0.08)
	var laranja := StandardMaterial3D.new()
	laranja.albedo_color = Color("ff7a22")
	laranja.roughness = 0.55
	placa.material_override = laranja
	placa.position.y = PLACA * 0.5
	add_child(placa)
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(lado, total, lado)
	cs.shape = caixa
	cs.position.y = PLACA - total * 0.5
	add_child(cs)
	_montar_contorno.call_deferred()


## O contorno laranja da placa lá no alto, onde ela vai parar (enfeite: atravessa-se).
func _montar_contorno() -> void:
	_contorno = Fase.so_enfeite(Node3D.new())
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.55, 0.15, 0.7)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var h := lado * 0.5
	for spec in [[Vector3(0, 0, -h), Vector3(lado, 0.08, 0.08)], [Vector3(0, 0, h), Vector3(lado, 0.08, 0.08)],
			[Vector3(-h, 0, 0), Vector3(0.08, 0.08, lado)], [Vector3(h, 0, 0), Vector3(0.08, 0.08, lado)]]:
		var mi := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = spec[1]
		mi.mesh = b
		mi.material_override = m
		mi.position = spec[0]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_contorno.add_child(mi)
	get_parent().add_child(_contorno)
	_contorno.global_position = global_position + Vector3.UP * (sobe + PLACA)
	_contorno.visible = not ligado and not vai_e_volta


## Liga (a pancada no pino): sobe uma vez, ou começa o sobe e desce.
func ligar() -> void:
	if ligado:
		return
	ligado = true
	if _contorno:
		_contorno.hide()
	Sfx.play_at(get_parent(), "pistao", global_position, -2.0)
	Fx.confetti(get_parent(), global_position + Vector3.UP * (sobe + 1.0), 14, 2.0)


## Já subiu até o alto (os testes usam).
func no_alto() -> bool:
	return ligado and not vai_e_volta and _subida >= 1.0


func _physics_process(delta: float) -> void:
	if not ligado:
		return
	if vai_e_volta:
		_t += delta
		var s := 0.5 - 0.5 * cos(TAU * _t / periodo)
		s = clampf((s - 0.12) / 0.76, 0.0, 1.0)
		position.y = _base_y + sobe * s
	elif _subida < 1.0:
		_subida = minf(_subida + delta / 0.8, 1.0)
		position.y = _base_y + sobe * (1.0 - pow(1.0 - _subida, 3.0))
