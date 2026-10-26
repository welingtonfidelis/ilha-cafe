class_name Shop
extends Node3D
## Lojinha de Blasters (seção 8 do doc; pedido do usuário em 2026-10-26): barraca na beira da praia, entre a
## rua da praça e a areia, a leste do cais. Balcão com blasters em exposição, toldo listrado, placa e o
## vendedor. Parar no tapete dourado na frente do balcão abre o menu de compras (ShopMenu); para abrir de
## novo, é só sair do tapete e voltar. A primeira moeda acende uma seta dourada até aqui (Story.shop_target).

const SPOT := Vector3(12, 0, 199.5)
const FESTA := "res://assets/props/festa/%s.gltf"
const MAT_RADIUS := 1.3
const MAT_HOLD := 0.5
const SELLER_LINES := ["Blasters novinhos! Moedas você ganha vencendo os guardiões.", "Volte sempre! Na Festa sem fim também dá para ganhar moedas."]

var game: Node
var _mat_point := Vector3.ZERO
var _hold := 0.0
## Saiu do tapete depois da última vez que abriu (não reabre sozinho em cima do tapete).
var _armed := true


func _ready() -> void:
	var ground: Vector3 = game._ground_point(SPOT)
	global_position = ground
	# O balcão fica de frente para o norte (a rua da praça): quem compra para do lado de -Z.
	var counter := StaticBody3D.new()
	counter.collision_layer = 1
	add_child(counter)
	var table: Node3D = load(FESTA % "comida/kitchentable_A_large").instantiate()
	table.scale = Vector3.ONE * 0.9
	counter.add_child(table)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.6, 1.0, 1.2)
	cs.shape = box
	cs.position.y = 0.5
	counter.add_child(cs)
	var top := _top_y(table)
	for spec in [["blaster-k", Vector3(-0.8, 0, 0.0), 30.0], ["blaster-q", Vector3(0.05, 0, 0.05), -15.0], ["blaster-f", Vector3(0.85, 0, -0.05), 10.0]]:
		var gun: Node3D = load(Weapons.MODEL_DIR % spec[0]).instantiate()
		gun.position = spec[1] + Vector3.UP * (top + 0.12)
		gun.rotation_degrees = Vector3(0, 90.0 + spec[2], 0)
		gun.scale = Vector3.ONE * 0.9
		add_child(gun)
	var crate: Node3D = load(Weapons.MODEL_DIR % "crate-medium").instantiate()
	crate.position = Vector3(1.9, 0, 0.5)
	crate.rotation_degrees.y = 20.0
	add_child(crate)
	_canopy()
	var sign := Label3D.new()
	sign.text = "LOJINHA DE BLASTERS"
	sign.font_size = 96
	sign.outline_size = 22
	sign.modulate = Color("#ffd23f")
	sign.outline_modulate = Color(0.25, 0.1, 0.3)
	sign.pixel_size = 0.006
	sign.position = Vector3(0, 3.35, -1.05)
	sign.rotation_degrees.y = 180.0
	add_child(sign)
	var seller_pos: Vector3 = game._ground_point(SPOT + Vector3(0, 0, 1.4))
	game.spawn_townsperson({"nome": "VendedorDaLojinha", "modelo": "SpaceRanger", "atividade": "parado",
		"falas": PackedStringArray(SELLER_LINES)}, seller_pos, PI)
	# Tapete dourado onde quem compra para.
	_mat_point = game._ground_point(SPOT + Vector3(0, 0, -1.9))
	var mat := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = MAT_RADIUS
	disc.bottom_radius = MAT_RADIUS
	disc.height = 0.04
	disc.material = Defense.glow(Color(1.0, 0.82, 0.25, 0.55))
	mat.mesh = disc
	mat.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mat)
	mat.global_position = _mat_point + Vector3.UP * 0.04


## Toldo listrado em quatro postes, um pouco inclinado para a frente.
func _canopy() -> void:
	var post_mat := Fx.flat_material(Color("#f4f1ea"), false)
	for x in [-1.5, 1.5]:
		for z in [-0.9, 0.9]:
			var post := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.06
			cyl.bottom_radius = 0.06
			cyl.height = 2.7
			cyl.material = post_mat
			post.mesh = cyl
			post.position = Vector3(x, 1.35, z)
			add_child(post)
	var roof := Node3D.new()
	roof.position = Vector3(0, 2.75, 0)
	roof.rotation_degrees.x = -10.0
	add_child(roof)
	var colors := [Color("#ff5d8f"), Color("#fff8f0")]
	for k in 7:
		var stripe := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.48, 0.08, 2.4)
		b.material = Fx.flat_material(colors[k % 2], false)
		stripe.mesh = b
		stripe.position = Vector3(-1.44 + k * 0.48, 0, 0)
		roof.add_child(stripe)


func _top_y(node: Node3D) -> float:
	var top := 0.8
	var first := true
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var y := (m.transform * m.get_aabb()).end.y * node.scale.y
		top = y if first else maxf(top, y)
		first = false
	return top


## Onde a seta dourada aponta.
func marker_point() -> Vector3:
	return global_position + Vector3.UP * 3.0


func _physics_process(delta: float) -> void:
	var player: Player = game.player
	if not is_instance_valid(player) or game.menu_state != "":
		return
	var on_mat := Vector2(player.global_position.x - _mat_point.x, player.global_position.z - _mat_point.z).length() < MAT_RADIUS \
			and absf(player.global_position.y - _mat_point.y) < 1.5
	if not on_mat:
		_armed = true
		_hold = 0.0
		return
	if not _armed or player.dizzy or (game.ending and game.ending.busy()):
		return
	_hold += delta
	if _hold >= MAT_HOLD:
		_armed = false
		_hold = 0.0
		game.open_shop()
