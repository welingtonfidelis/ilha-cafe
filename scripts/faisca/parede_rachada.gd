class_name ParedeRachada
extends StaticBody3D
## Parede de pedra rachada (a `wall_cracked` do Dungeon Pack), que esconde um segredo nos Túneis do Morro.
## Fica no grupo dos alvos, então golpes acertam (e a mira do golpe vira para ela); a cada golpe ela treme
## e solta pedrinhas, e no terceiro desmorona: as pedras voam, sobra um montinho de entulho no chão e a
## passagem fica livre. O laser não quebra.

signal quebrada(parede: ParedeRachada)

const GOLPES_PARA_QUEBRAR := 3

## Para os golpes: quebrada conta como derrotada (não vira mais alvo).
var derrotado := false
## A parede tem 6 m de largura: os golpes alcançam a partir de qualquer ponto da frente dela.
var raio_golpe := 2.8
var golpes := 0
var escala := 1.5
var _modelo: Node3D
var _imune := 0.0


func _ready() -> void:
	add_to_group(Alvo.GRUPO)
	collision_layer = 1
	collision_mask = 0
	_modelo = load(Fase.MASMORRA + "wall_cracked.gltf").instantiate()
	_modelo.scale = Vector3.ONE * escala
	add_child(_modelo)
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(4.0, 4.0, 1.0) * escala
	cs.shape = caixa
	cs.position.y = 2.0 * escala
	add_child(cs)


func _process(delta: float) -> void:
	_imune -= delta


func receber_golpe(_dano: int, de: Vector3, _forca := 6.0, _tipo := "") -> bool:
	if derrotado or _imune > 0.0:
		return false
	_imune = 0.3
	golpes += 1
	var lado := signf(global_basis.z.dot(de - global_position) + 0.01)
	var tw := create_tween()
	tw.tween_property(_modelo, "position:z", -0.12 * lado, 0.05)
	tw.tween_property(_modelo, "position:z", 0.06 * lado, 0.07)
	tw.tween_property(_modelo, "position:z", 0.0, 0.08)
	_pedrinhas(de, 4)
	if golpes >= GOLPES_PARA_QUEBRAR:
		_quebrar(de)
	return true


func _quebrar(de: Vector3) -> void:
	derrotado = true
	collision_layer = 0
	_pedrinhas(de, 14)
	var tw := create_tween()
	tw.tween_property(_modelo, "scale", Vector3(escala * 1.04, escala * 0.2, escala * 1.04), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(_modelo.hide)
	var entulho: Node3D = load(Fase.MASMORRA + "rubble_half.gltf").instantiate()
	entulho.scale = Vector3.ONE * 0.9
	add_child(entulho)
	entulho.position = Vector3(1.4 * escala, 0, 0)
	quebrada.emit(self)


## Pedrinhas cinza voando para o lado de quem bateu.
func _pedrinhas(de: Vector3, quantas: int) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("8a90a8")
	m.roughness = 0.9
	var meio := global_position + Vector3.UP * 2.0 * escala
	var para := de - global_position
	para.y = 0.0
	para = para.normalized() if para.length() > 0.1 else global_basis.z
	for i in quantas:
		var p := MeshInstance3D.new()
		var caixa := BoxMesh.new()
		caixa.size = Vector3.ONE * randf_range(0.18, 0.4)
		p.mesh = caixa
		p.material_override = m
		p.top_level = true
		add_child(p)
		var inicio := meio + global_basis.x * randf_range(-2.4, 2.4) * escala * 0.6 + Vector3.UP * randf_range(-1.5, 1.5)
		p.global_position = inicio
		var destino := inicio + para * randf_range(1.0, 3.0) + Vector3(randf_range(-0.8, 0.8), 0, randf_range(-0.8, 0.8))
		destino.y = global_position.y + 0.15
		var tw := p.create_tween().set_parallel()
		tw.tween_property(p, "global_position", destino, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(p, "rotation", Vector3(randf() * 6.0, randf() * 6.0, 0), 0.55)
		tw.chain().tween_interval(0.8)
		tw.chain().tween_property(p, "scale", Vector3.ONE * 0.01, 0.3)
		tw.chain().tween_callback(p.queue_free)
