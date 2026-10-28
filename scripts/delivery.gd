class_name Delivery
extends Area3D
## Entrega de balão da lojinha do celular (pedido do usuário em 2026-10-27): o que se compra no celular desce
## do céu num presente pendurado em três balões e pousa na frente do aventureiro, num lugar livre (Delivery.spot
## procura chão plano sem árvore, pedra, prédio, gente ou água, que dê para ver de onde ele está). Pousado, os
## balões soltam e sobem, e o presente fica brilhando num anel dourado com o nome do que veio; encostar pega
## tudo. Quem aplica o que veio é a história (sinal `collected`).

signal collected(delivery: Delivery)

const PRESENT := "res://assets/props/festa/doces/present_A_yellow.gltf"
const DROP_HEIGHT := 16.0
const FALL_TIME := 3.0
## Raio livre em volta do ponto de pouso e a altura que precisa estar vazia acima do chão.
const CLEAR_RADIUS := 0.8
const CLEAR_HEIGHT := 2.2
## Nível do mar (o mesmo SEA_LEVEL do main.gd e de tools/gerar_ilha.gd).
const SEA_LEVEL := -0.6

var items: Array = []
## Volta de um jogo salvo: já aparece pousado.
var start_landed := false
var landed := false
var _visual: Node3D
var _balloons: Node3D
var _ring: MeshInstance3D
var _label: Label3D
var _time := 0.0
var _taken := false


## Ponto de pouso: na frente da câmera, a 3 m, girando para os lados (e mais perto ou mais longe) até achar
## um lugar livre. Sem nenhum, cai no próprio lugar do aventureiro (onde ele está cabe um presente).
static func spot(player: Player) -> Vector3:
	var fwd := -player.camera_pivot.global_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
	var base := player.global_position
	for dist in [3.2, 4.6, 2.4]:
		for k in [0, 1, -1, 2, -2, 3, -3, 4, -4, 5, -5, 6]:
			var p := _free_spot(player, base + fwd.rotated(Vector3.UP, deg_to_rad(30.0 * k)) * dist)
			if p != Vector3.INF:
				return p
	return base


static func _free_spot(player: Player, p: Vector3) -> Vector3:
	var space := player.get_world_3d().direct_space_state
	var base := player.global_position
	var down := PhysicsRayQueryParameters3D.create(Vector3(p.x, base.y + 25.0, p.z), Vector3(p.x, base.y - 6.0, p.z), 1)
	var hit := space.intersect_ray(down)
	# O primeiro que o raio encontra vindo de cima tem que ser chão plano na altura de quem comprou: telhado,
	# copa, beira de barranco e fundo do rio ficam de fora.
	if hit.is_empty() or hit.normal.y < 0.85 or absf(hit.position.y - base.y) > 1.2:
		return Vector3.INF
	var ground: Vector3 = hit.position
	if ground.y < SEA_LEVEL + 0.3:
		return Vector3.INF
	# Nada encostando no presente (tronco, pedra, parede, cerca, morador).
	var box := BoxShape3D.new()
	box.size = Vector3(CLEAR_RADIUS * 2.0, CLEAR_HEIGHT, CLEAR_RADIUS * 2.0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = box
	query.transform = Transform3D(Basis.IDENTITY, ground + Vector3.UP * (CLEAR_HEIGHT * 0.5 + 0.15))
	query.collision_mask = 1 | Townsperson.LAYER
	if not space.intersect_shape(query, 1).is_empty():
		return Vector3.INF
	# Caminho de descida livre (galho, toldo, ponte por cima).
	var sphere := SphereShape3D.new()
	sphere.radius = CLEAR_RADIUS
	var fall := PhysicsShapeQueryParameters3D.new()
	fall.shape = sphere
	fall.transform = Transform3D(Basis.IDENTITY, ground + Vector3.UP * DROP_HEIGHT)
	fall.motion = Vector3.DOWN * (DROP_HEIGHT - CLEAR_HEIGHT)
	fall.collision_mask = 1
	if space.cast_motion(fall)[0] < 0.99:
		return Vector3.INF
	# Dá para ver de onde o aventureiro está (nada de cair do outro lado de um muro).
	var look := PhysicsRayQueryParameters3D.create(base + Vector3.UP * 1.2, ground + Vector3.UP * 0.8, 1)
	look.exclude = [player.get_rid()]
	if not space.intersect_ray(look).is_empty():
		return Vector3.INF
	return ground


## Nome do que vem na caixa ("Jujuba", "Munição"...).
static func item_name(id: String) -> String:
	for up in Weapons.UPGRADES:
		if up.id == id:
			return up.nome
	return Weapons.find(id).get("nome", id)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 1  # jogador
	monitoring = true
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.5
	shape.shape = sphere
	shape.position.y = 0.8
	add_child(shape)
	_visual = Node3D.new()
	add_child(_visual)
	var present: Node3D = load(PRESENT).instantiate()
	present.scale = Vector3.ONE * 1.5
	_visual.add_child(present)
	_balloons = Fx.balloons(0.9)
	_visual.add_child(_balloons)
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.0
	torus.outer_radius = 1.25
	torus.material = Fx.glow_material(Color("#ffd23f"), 1.2)
	_ring.mesh = torus
	_ring.scale = Vector3(1, 0.4, 1)
	_ring.position.y = 0.08
	_ring.visible = false
	add_child(_ring)
	_label = Label3D.new()
	_label.text = " + ".join(items.map(func(id: String) -> String: return item_name(id)))
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 64
	_label.outline_size = 14
	_label.pixel_size = 0.006
	_label.modulate = Color("#ffd23f")
	_label.no_depth_test = true
	_label.position.y = 2.2
	_label.visible = false
	add_child(_label)
	if start_landed:
		_balloons.queue_free()
		_land(false)
	else:
		_visual.position.y = DROP_HEIGHT
		var tw := create_tween()
		tw.tween_property(_visual, "position:y", 0.0, FALL_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_callback(_land.bind(true))
		Sfx.play_at(get_parent(), "balao", global_position + Vector3.UP * 6.0, 2.0)


func _land(animate: bool) -> void:
	landed = true
	_visual.position.y = 0.0
	_visual.rotation = Vector3.ZERO
	_ring.visible = true
	_label.visible = true
	if not animate:
		return
	Fx.dust(get_parent(), global_position + Vector3.UP * 0.2)
	Sfx.play_at(get_parent(), "bonk", global_position, -4.0)
	# Os balões soltam do presente e sobem sozinhos.
	var world := get_parent()
	var at := _balloons.global_transform
	_visual.remove_child(_balloons)
	world.add_child(_balloons)
	_balloons.global_transform = at
	var tw := _balloons.create_tween()
	tw.tween_property(_balloons, "global_position:y", at.origin.y + 14.0, 3.5).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_balloons, "rotation:z", 0.25, 3.5)
	tw.tween_callback(_balloons.queue_free)


func _physics_process(delta: float) -> void:
	_time += delta
	if not landed:
		_visual.rotation.z = sin(_time * 2.0) * 0.08
		_visual.rotation.y += delta * 0.6
		return
	_ring.rotation.y += delta * 1.2
	_ring.scale = Vector3(1, 0.4, 1) * (1.0 + sin(_time * 3.0) * 0.06)
	if _taken:
		return
	for body in get_overlapping_bodies():
		if body is Player and not (body as Player).dizzy:
			_taken = true
			Fx.confetti(get_parent(), global_position + Vector3.UP * 1.0, 60, 5.0)
			Sfx.play(get_parent(), "bandeira")
			collected.emit(self)
			queue_free()
			return


## Onde a seta dourada aponta.
func marker_point() -> Vector3:
	return global_position + Vector3.UP * 1.6
