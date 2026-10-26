class_name SeaTraffic
extends Node3D
## Vida no mar (pedido do usuário em 2026-10-26, Watercraft Kit do Kenney, CC0): barcos de pescador
## ancorados perto da costa, balançando na água, alguns com um pescador de vara; veleiros e um rebocador mais
## longe; e navios grandes (galeão, transatlântico, cargueiro) dando a volta na ilha bem devagar, lá no
## horizonte. Boias perto do cais. Nada disso tem colisão: é paisagem.

const MODELS := "res://assets/barcos/%s.glb"
const SEA_LEVEL := -0.6
## [modelo, posição (x, z), rumo (graus), escala, quanto afunda (fração da altura), pescador?]
const ANCHORED := [
	["boat-fishing-small", Vector2(-38, 268), 70.0, 2.4, 0.12, true],
	["boat-fishing-small", Vector2(46, 274), -40.0, 2.4, 0.12, true],
	["boat-row-small", Vector2(-20, 282), 15.0, 2.0, 0.2, true],
	["boat-sail-a", Vector2(210, 70), 160.0, 2.6, 0.1, false],
	["boat-fishing-small", Vector2(200, -60), 100.0, 2.4, 0.12, true],
	["boat-row-large", Vector2(-212, 30), -60.0, 2.0, 0.2, true],
	["boat-sail-b", Vector2(-205, 150), 20.0, 2.6, 0.1, false],
	["boat-tug-a", Vector2(-70, -282), 80.0, 2.6, 0.12, false],
	["boat-fishing-small", Vector2(95, -270), -120.0, 2.4, 0.12, true],
	["boat-speed-a", Vector2(150, 240), 35.0, 2.4, 0.1, false],
]
## Navios do horizonte: [modelo, escala, quanto afunda, fase na volta (0 a 1)].
const SHIPS := [
	["ship-large", 4.0, 0.08, 0.0],
	["ship-ocean-liner", 4.5, 0.1, 0.36],
	["ship-cargo-a", 4.5, 0.1, 0.7],
]
const SHIP_RADII := Vector2(400, 470)
const SHIP_SPEED := 4.5
const BUOYS := [Vector2(-14, 236), Vector2(14, 240), Vector2(-24, 252), Vector2(26, 256), Vector2(-60, 236), Vector2(60, 238)]

var game: Node
var _anchored: Array[Node3D] = []
var _ships: Array[Dictionary] = []
var _time := 0.0


func _ready() -> void:
	for spec in ANCHORED:
		var boat := _boat(spec[0], spec[3], spec[4])
		var p: Vector2 = spec[1]
		boat.position = Vector3(p.x, 0, p.y)
		boat.rotation_degrees.y = spec[2]
		boat.set_meta("fase", randf() * TAU)
		_anchored.append(boat)
		if spec[5]:
			_fisher(boat, spec[3])
	for spec in SHIPS:
		var ship := _boat(spec[0], spec[1], spec[2])
		_ships.append({"no": ship, "fase": spec[3]})
	for b in BUOYS:
		var buoy: Node3D = load(MODELS % ("buoy-flag" if int(b.x) % 2 == 0 else "buoy")).instantiate()
		buoy.scale = Vector3.ONE * 0.9
		var holder := Node3D.new()
		holder.position = Vector3(b.x, SEA_LEVEL - 0.15, b.y)
		holder.set_meta("fase", randf() * TAU)
		add_child(holder)
		holder.add_child(buoy)
		_anchored.append(holder)


## O barco fica num nó na linha d'água (que balança); o modelo afunda um pouco dentro dele.
func _boat(model_name: String, s: float, sink: float) -> Node3D:
	var holder := Node3D.new()
	holder.name = model_name
	add_child(holder)
	var model: Node3D = load(MODELS % model_name).instantiate()
	model.scale = Vector3.ONE * s
	var height := _height(model) * s
	model.position.y = SEA_LEVEL - height * sink
	holder.add_child(model)
	holder.set_meta("deck", SEA_LEVEL - height * sink + height * 0.32)
	return holder


func _height(model: Node3D) -> float:
	var top := 0.0
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		top = maxf(top, (m.transform * m.get_aabb()).end.y)
	return top


## Pescador sentado na beira do barco, com a vara para fora (a linha desce até a água).
func _fisher(boat: Node3D, s: float) -> void:
	var t := Townsperson.new()
	t.name = "PescadorDoBarco"
	t.model_name = ["Hiker", "Farmer_A", "Driver"][randi() % 3]
	t.activity = "pescando"
	t.item = "pesca/fishing_rod"
	t.lines = PackedStringArray(["Hoje o mar está calminho!", "Peguei um peixe deste tamanho!"])
	t.player = game.player if game else null
	t.position = Vector3(0.55 * s * 0.4, boat.get_meta("deck") - SEA_LEVEL + SEA_LEVEL, 0.2 * s)
	t.collision_layer = 0
	boat.add_child(t)
	t.visual.rotation.y = PI / 2.0


func _process(delta: float) -> void:
	_time += delta
	for b in _anchored:
		if not is_instance_valid(b):
			continue
		var f: float = b.get_meta("fase")
		b.position.y = sin(_time * 1.1 + f) * 0.12
		b.rotation.z = sin(_time * 0.9 + f) * 0.04
		b.rotation.x = sin(_time * 0.7 + f * 1.3) * 0.03
	# Navios: uma volta enorme em volta da ilha, sempre de proa para a frente.
	var lap := TAU * (SHIP_RADII.x + SHIP_RADII.y) * 0.5
	for s in _ships:
		var a: float = TAU * (s.fase + _time * SHIP_SPEED / lap)
		var node: Node3D = s.no
		var pos := Vector3(cos(a) * SHIP_RADII.x, 0, sin(a) * SHIP_RADII.y)
		var tangent := Vector3(-sin(a) * SHIP_RADII.x, 0, cos(a) * SHIP_RADII.y).normalized()
		node.position = pos + Vector3.UP * sin(_time * 0.5 + a) * 0.2
		node.rotation.y = atan2(tangent.x, tangent.z)
		node.rotation.z = sin(_time * 0.4 + a) * 0.02
