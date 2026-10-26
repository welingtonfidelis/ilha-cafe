extends SceneTree
## Gera a ilha jogável: scenes/ilha.tscn (cidade ao sul, Morro no meio, rio, mata ao norte)
## e o terreno em assets/terrain/. Depois de gerada, a ilha é uma cena comum: dá para abrir no
## editor da Godot, mover prédios, árvores e marcadores, e salvar.
##
## Uso: godot --headless --path . -s res://tools/gerar_ilha.gd
##
## ATENÇÃO: sobrescreve scenes/ilha.tscn e assets/terrain/. Se você já mexeu na ilha pelo
## editor, faça commit antes de rodar de novo (o git guarda a versão editada).
##
## Coordenadas: -Z é norte, +X é leste. 1 unidade = 1 metro. O mar fica em y = SEA_LEVEL.

const CELL := 4.0
const HALF_X := 224.0
const HALF_Z := 272.0
const SEA_LEVEL := -0.6
const ISLAND_A := 190.0
const ISLAND_B := 245.0
const CITY_Z := 95.0
const MORRO_R := 90.0
const MORRO_H := 26.0
const MORRO_TOP_R := 24.0
const RIVER_Z := -112.0
const RIVER_HALF := 7.0
const RIVER_BANK := 6.0
## Longe da costa (antes ficava na beira da praia e o terreno virava areia e mar).
const VENTOS := Vector2(-95, -158)
const VENTOS_R := 45.0
const VENTOS_H := 14.0
const CLAREIRA := Vector2(40, -180)
const VILA := Vector2(115, -160)
const SPIRAL_TURNS := 2.5
const SPIRAL_R0 := 86.0
const SPIRAL_R1 := 15.0
const PATH_HALF := 3.2
## Regiões de defesa (centro da arena em x, z). Nas quatro de fora da praça a lanterna fica no centro.
const REGIONS := {
	"praca": Vector2(0, 170),
	"oeste": Vector2(-84, 140),
	"leste": Vector2(84, 140),
	"clareira": Vector2(24, -166),
	"ventos": Vector2(-95, -158),
}
const REGION_NAMES := {"oeste": "Oeste", "leste": "Leste", "clareira": "Clareira", "ventos": "Ventos"}
## Raio do círculo da arena e raio sem árvores, pedras e arbustos em volta do centro.
const ARENA_R := 22.0
const CLEAR_R := 26.0
const CEMETERY_DOME_R := 25.5

const CITY := "res://assets/env/city/%s.gltf"
const FOREST := "res://assets/env/forest/%s.gltf"
const PLAT := "res://assets/props/platformer/%s.gltf"
const FESTA := "res://assets/props/festa/%s.gltf"
const CEMITERIO := "res://assets/props/cemiterio/%s.gltf"
const PONTE := "res://assets/props/ponte/%s.gltf"
const EXTRAS := "res://assets/props/%s.gltf"
## Árvores e arbustos nas outras cores do Forest Nature Pack completo (a cor 1 fica em env/forest/).
const FOREST_COLOR := "res://assets/env/forest/cor%d/%s_Color%d.gltf"
## Formatos de árvore da mata (os 5, 6 e 7 só existem no pacote completo).
const TREE_SHAPES := ["Tree_1_A", "Tree_1_B", "Tree_2_A", "Tree_2_C", "Tree_3_A", "Tree_4_A", "Tree_4_B",
	"Tree_5_A", "Tree_5_B", "Tree_5_C", "Tree_6_A", "Tree_6_B", "Tree_7_A", "Tree_7_B"]
const MORADOR_ITEM := "res://assets/props/%s.gltf"
const CITY_SCALE := 5.0
## Topo das ruas (a peça fica em y = 0,01 e tem 0,1 de altura).
const ROAD_TOP := 0.11
## Os carros do City Builder Bits têm as rodas 7,2 cm abaixo da origem (36 cm na escala 5).
const CAR_LIFT := 0.072 * CITY_SCALE
const FOREST_SCALE := 1.8
const ROAD_XS := [-60, -20, 20, 60]
const ROAD_ZS := [110, 150, 190]
const PLAZA := Rect2(-20, 150, 40, 40)  # quarteirão da praça (x, z, largura, profundidade)

const C_SEABED := Color("#d9c48c")
const C_SAND := Color("#ecd9a2")
const C_GRASS := Color("#8cc96b")
const C_GRASS_FOREST := Color("#6fb35a")
const C_DIRT := Color("#c9a46a")
const C_ROCK := Color("#9aa3ad")
const C_PAVEMENT := Color("#c4b9a1")
const C_PLAZA := Color("#d3b98f")

var trails := [
	[Vector2(0, 106), Vector2(0, SPIRAL_R0)],  # da cidade ao começo da subida do Morro
	[Vector2(0, -126), Vector2(10, -150), CLAREIRA],
	[Vector2(10, -150), Vector2(-40, -165), Vector2(-90, -165)],
	[Vector2(10, -150), Vector2(70, -150), VILA],
]

var ilha: Node3D
var rng := RandomNumberGenerator.new()
## Sorteio separado para as cores das árvores: assim trocar cores não muda a posição de nada.
var rng_cor := RandomNumberGenerator.new()
var _cols := 0
var _rows := 0
var _hs := PackedFloat32Array()


func _init() -> void:
	rng.seed = 2026
	rng_cor.seed = 77
	ilha = Node3D.new()
	ilha.name = "Ilha"
	_terrain()
	_sea()
	_city()
	_festa()
	_morro()
	_bridge_and_pier()
	_forest()
	_grass()
	_markers()
	var packed := PackedScene.new()
	var err := packed.pack(ilha)
	if err != OK:
		push_error("falha ao empacotar a ilha: %d" % err)
	ResourceSaver.save(packed, "res://scenes/ilha.tscn")
	print("ilha gerada: scenes/ilha.tscn")
	quit()


# --- forma da ilha -----------------------------------------------------------

func _island_d(x: float, z: float) -> float:
	var ang := atan2(z, x)
	var coast := 1.0 + 0.06 * sin(ang * 3.0 + 0.7) + 0.04 * sin(ang * 7.0 + 2.1) + 0.025 * sin(ang * 13.0)
	return sqrt(pow(x / ISLAND_A, 2) + pow(z / ISLAND_B, 2)) / coast


func _river_z(x: float) -> float:
	return RIVER_Z + 9.0 * sin(x / 38.0)


## Altura "ideal" do terreno (a malha é feita a partir dela em grade de CELL metros).
func height(x: float, z: float) -> float:
	var land := 0.0
	# Mata: morrinhos suaves ao norte do rio.
	var forest_w := clampf((-z - 60.0) / 60.0, 0.0, 1.0)
	var n := 0.5 + 0.5 * (0.6 * sin(x * 0.045 + 1.3) * sin(z * 0.05 + 0.4) + 0.4 * sin(x * 0.11 + z * 0.07))
	land += forest_w * 2.2 * n
	# Morro no centro, com topo plano e largo para o cemitério dos esqueletos.
	var r := Vector2(x, z).length()
	if r < MORRO_R:
		var t := clampf((r - MORRO_TOP_R) / (MORRO_R - MORRO_TOP_R), 0.0, 1.0)
		land = maxf(land, MORRO_H * (0.5 + 0.5 * cos(PI * t)))
	# Morro dos Ventos, a noroeste.
	var rv := Vector2(x, z).distance_to(VENTOS)
	if rv < VENTOS_R:
		land = maxf(land, VENTOS_H * (0.5 + 0.5 * cos(PI * rv / VENTOS_R)))
	# Cidade plana.
	if z > CITY_Z:
		land = 0.0
	# Rio Preguiçoso, atravessando a ilha de leste a oeste.
	var dr := absf(z - _river_z(x))
	if dr < RIVER_HALF + RIVER_BANK:
		land = lerpf(land, -2.6, smoothstep(RIVER_HALF + RIVER_BANK, RIVER_HALF, dr))
	# Praia e mar.
	var d := _island_d(x, z)
	land = lerpf(land, -0.15, smoothstep(0.86, 0.93, d))
	land = lerpf(land, -4.0, smoothstep(0.95, 1.08, d))
	return land


## Altura exata da malha (interpola os triângulos do jeito que foram montados).
func ground(x: float, z: float) -> float:
	var fx := (x + HALF_X) / CELL
	var fz := (z + HALF_Z) / CELL
	var i := clampi(int(floor(fx)), 0, _cols - 1)
	var j := clampi(int(floor(fz)), 0, _rows - 1)
	var u := fx - i
	var v := fz - j
	var h00 := _hs[j * (_cols + 1) + i]
	var h10 := _hs[j * (_cols + 1) + i + 1]
	var h01 := _hs[(j + 1) * (_cols + 1) + i]
	var h11 := _hs[(j + 1) * (_cols + 1) + i + 1]
	if u + v <= 1.0:
		return h00 + (h10 - h00) * u + (h01 - h00) * v
	return h11 + (h01 - h11) * (1.0 - u) + (h10 - h11) * (1.0 - v)


func _spiral_point(s: float) -> Vector2:
	var theta := PI / 2.0 + s * SPIRAL_TURNS * TAU
	var r := lerpf(SPIRAL_R0, SPIRAL_R1, s)
	return Vector2(cos(theta), sin(theta)) * r


## Distância (radial) até a trilha em espiral que sobe o Morro.
func _spiral_dist(x: float, z: float) -> float:
	var r := Vector2(x, z).length()
	var base := fposmod(atan2(z, x) - PI / 2.0, TAU)
	var best := INF
	for k in 4:
		var s := (base + TAU * k) / (SPIRAL_TURNS * TAU)
		if s > 1.0:
			break
		best = minf(best, absf(r - lerpf(SPIRAL_R0, SPIRAL_R1, s)))
	return best


func _trail_dist(p: Vector2) -> float:
	var best := INF
	for trail in trails:
		for k in trail.size() - 1:
			var a: Vector2 = trail[k]
			var b: Vector2 = trail[k + 1]
			var ab := b - a
			var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
			best = minf(best, p.distance_to(a + ab * t))
	return best


## Perto do centro de alguma arena de defesa (fica sem árvores, pedras nem arbustos).
func _near_region(p: Vector2, extra := 0.0) -> bool:
	for key in REGIONS:
		if key != "praca" and p.distance_to(REGIONS[key]) < CLEAR_R + extra:
			return true
	return false


func _in_city(x: float, z: float) -> bool:
	return x > -72 and x < 72 and z > 98 and z < 202


func _ground_color(x: float, z: float, h: float, ny: float) -> Color:
	var p := Vector2(x, z)
	if h < SEA_LEVEL + 0.2:
		return C_SEABED
	var d := _island_d(x, z)
	if d > 0.87 and h < 0.5:
		return C_SAND
	if _in_city(x, z):
		return C_PLAZA if PLAZA.has_point(p) else C_PAVEMENT
	if ny < 0.78:
		return C_ROCK
	if p.length() < MORRO_R and p.length() > MORRO_TOP_R - 1.0 and _spiral_dist(x, z) < PATH_HALF:
		return C_DIRT
	if _trail_dist(p) < 2.6:
		return C_DIRT
	var jitter := 0.04 * sin(x * 0.37 + z * 0.23) * cos(z * 0.31 - x * 0.11)
	var base := C_GRASS_FOREST if z < RIVER_Z else C_GRASS
	return base.lightened(jitter) if jitter > 0.0 else base.darkened(-jitter)


# --- montagem ----------------------------------------------------------------

func _add(parent: Node, node: Node) -> Node:
	parent.add_child(node, true)
	node.owner = ilha
	return node


func _group(parent: Node, group_name: String) -> Node3D:
	var n := Node3D.new()
	n.name = group_name
	_add(parent, n)
	return n


func _rel_xform(node: Node3D, ancestor: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur: Node = node
	while cur != ancestor and cur != null:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf


func _model_aabb(inst: Node3D) -> AABB:
	var aabb := AABB()
	var first := true
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var a: AABB = _rel_xform(mi, inst) * (mi as MeshInstance3D).get_aabb()
		aabb = a if first else aabb.merge(a)
		first = false
	return aabb


## Coloca um modelo. collider: "" (sem colisão), "caixa", "tronco" (cilindro fino) ou "convexo".
func _prop(parent: Node, path: String, pos: Vector3, rot_y: float, s: float, collider := "") -> Node3D:
	var inst: Node3D = load(path).instantiate()
	if collider == "":
		inst.position = pos
		inst.rotation_degrees.y = rot_y
		inst.scale = Vector3.ONE * s
		_add(parent, inst)
		return inst
	var body := StaticBody3D.new()
	body.name = inst.name
	body.position = pos
	body.rotation_degrees.y = rot_y
	body.scale = Vector3.ONE * s
	_add(parent, body)
	_add(body, inst)
	var cs := CollisionShape3D.new()
	match collider:
		"caixa":
			var aabb := _model_aabb(inst)
			var box := BoxShape3D.new()
			box.size = aabb.size
			cs.shape = box
			cs.position = aabb.get_center()
		"tronco":
			var cyl := CylinderShape3D.new()
			cyl.radius = 0.3
			cyl.height = 3.0
			cs.shape = cyl
			cs.position.y = 1.5
		"convexo":
			var mi: MeshInstance3D = inst.find_children("*", "MeshInstance3D", true, false)[0]
			cs.shape = mi.mesh.create_convex_shape()
			cs.transform = _rel_xform(mi, inst)
	_add(body, cs)
	return body


func _box_body(parent: Node, body_name: String, size: Vector3, xform: Transform3D, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = body_name
	body.transform = xform
	_add(parent, body)
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mesh.material = mat
	mi.mesh = mesh
	_add(body, mi)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	_add(body, cs)
	return body


# --- terreno e mar -----------------------------------------------------------

func _terrain() -> void:
	_cols = int(HALF_X * 2.0 / CELL)
	_rows = int(HALF_Z * 2.0 / CELL)
	_hs.resize((_cols + 1) * (_rows + 1))
	for j in _rows + 1:
		for i in _cols + 1:
			_hs[j * (_cols + 1) + i] = height(-HALF_X + i * CELL, -HALF_Z + j * CELL)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	for j in _rows:
		for i in _cols:
			var x0 := -HALF_X + i * CELL
			var z0 := -HALF_Z + j * CELL
			var p00 := Vector3(x0, _hs[j * (_cols + 1) + i], z0)
			var p10 := Vector3(x0 + CELL, _hs[j * (_cols + 1) + i + 1], z0)
			var p01 := Vector3(x0, _hs[(j + 1) * (_cols + 1) + i], z0 + CELL)
			var p11 := Vector3(x0 + CELL, _hs[(j + 1) * (_cols + 1) + i + 1], z0 + CELL)
			for tri in [[p00, p10, p01], [p10, p11, p01]]:
				var a: Vector3 = tri[0]
				var b: Vector3 = tri[1]
				var c: Vector3 = tri[2]
				# Godot desenha a face da frente no sentido horário: a normal sobe.
				var normal := (c - a).cross(b - a).normalized()
				var center := (a + b + c) / 3.0
				var color := _ground_color(center.x, center.z, center.y, normal.y)
				for v in [a, b, c]:
					st.set_normal(normal)
					st.set_color(color)
					st.add_vertex(v)
				faces.append(a)
				faces.append(b)
				faces.append(c)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	# As cores do terreno estão em sRGB (como no resto do jogo); sem isso o chão sai quase branco.
	mat.vertex_color_is_srgb = true
	mat.roughness = 1.0
	st.set_material(mat)
	var mesh := st.commit()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/terrain"))
	ResourceSaver.save(mesh, "res://assets/terrain/ilha_terreno.res")
	mesh.take_over_path("res://assets/terrain/ilha_terreno.res")
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	ResourceSaver.save(shape, "res://assets/terrain/ilha_colisao.res")
	shape.take_over_path("res://assets/terrain/ilha_colisao.res")

	var body := StaticBody3D.new()
	body.name = "Terreno"
	_add(ilha, body)
	var mi := MeshInstance3D.new()
	mi.name = "Malha"
	mi.mesh = mesh
	_add(body, mi)
	var cs := CollisionShape3D.new()
	cs.name = "Colisao"
	cs.shape = shape
	_add(body, cs)


func _sea() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Mar"
	var plane := PlaneMesh.new()
	plane.size = Vector2(6000, 6000)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.65, 0.9, 0.78)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.15
	mat.metallic_specular = 0.8
	plane.material = mat
	mi.mesh = plane
	mi.position.y = SEA_LEVEL
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(ilha, mi)


# --- cidade ------------------------------------------------------------------

## Peças de rua: a reta corre norte-sul; o T abre para o leste; a curva liga sul e leste.
## Girar +90° leva leste->norte, sul->leste, oeste->sul e norte->oeste.
func _road_piece(n: bool, s: bool, e: bool, w: bool) -> Array:
	var count := int(n) + int(s) + int(e) + int(w)
	if count == 4:
		return ["road_junction", 0.0]
	if count == 3:
		if not w:
			return ["road_tsplit", 0.0]
		if not s:
			return ["road_tsplit", 90.0]
		if not e:
			return ["road_tsplit", 180.0]
		return ["road_tsplit", 270.0]
	if count == 2 and not (n and s) and not (e and w):
		if s and e:
			return ["road_corner", 0.0]
		if e and n:
			return ["road_corner", 90.0]
		if n and w:
			return ["road_corner", 180.0]
		return ["road_corner", 270.0]
	return ["road_straight", 90.0 if (e or w) and not (n or s) else 0.0]


func _city() -> void:
	var city := _group(ilha, "Cidade")
	var roads := _group(city, "Ruas")
	var buildings := _group(city, "Predios")
	var props := _group(city, "Enfeites")
	var cells := {}
	for x in ROAD_XS:
		for z in range(ROAD_ZS[0], ROAD_ZS[-1] + 1, 10):
			cells[Vector2i(x, z)] = true
	for z in ROAD_ZS:
		for x in range(ROAD_XS[0], ROAD_XS[-1] + 1, 10):
			cells[Vector2i(x, z)] = true
	for key in cells:
		var piece := _road_piece(cells.has(key + Vector2i(0, -10)), cells.has(key + Vector2i(0, 10)),
				cells.has(key + Vector2i(10, 0)), cells.has(key + Vector2i(-10, 0)))
		# Achatada (5 x 1 x 5): a rua fica rente ao chão, sem degrau para o personagem.
		var road := _prop(roads, CITY % piece[0], Vector3(key.x, 0.01, key.y), piece[1], 1.0)
		road.scale = Vector3(CITY_SCALE, 1.0, CITY_SCALE)

	# Prédios em volta de cada quarteirão, de frente para a rua mais próxima (a frente do modelo é o sul).
	var models := ["building_A", "building_B", "building_C", "building_D", "building_E", "building_F", "building_G", "building_H"]
	for bx in ROAD_XS.size() - 1:
		for bz in ROAD_ZS.size() - 1:
			var xa: int = ROAD_XS[bx]
			var za: int = ROAD_ZS[bz]
			if Vector2i(xa, za) == Vector2i(int(PLAZA.position.x), int(PLAZA.position.y)):
				continue
			for cx in 3:
				for cz in 3:
					if cx == 1 and cz == 1:
						# Miolo do quarteirão: um jardinzinho.
						_prop(props, FOREST % "Tree_3_A_Color1", Vector3(xa + 20, 0, za + 20), rng.randf_range(0, 360), 1.4, "tronco")
						_prop(props, CITY % "bench", Vector3(xa + 20, 0, za + 24), 0.0, CITY_SCALE, "caixa")
						continue
					var rot := 0.0
					if cz == 0:
						rot = 180.0
					elif cz == 2:
						rot = 0.0
					elif cx == 0:
						rot = 270.0
					else:
						rot = 90.0
					var model: String = models[rng.randi() % models.size()]
					_prop(buildings, CITY % model, Vector3(xa + 10 + cx * 10, -0.3, za + 10 + cz * 10), rot, CITY_SCALE, "caixa")

	# Postes nos cruzamentos e alguns carros estacionados.
	for x in ROAD_XS:
		for z in ROAD_ZS:
			_prop(props, CITY % "streetlight", Vector3(x + 6.5, 0, z + 6.5), 0.0, CITY_SCALE, "caixa")
	var cars := ["car_sedan", "car_taxi", "car_hatchback", "car_stationwagon", "car_police"]
	for k in 10:
		var on_x := rng.randf() < 0.5
		var pos := Vector3.ZERO
		var rot := 0.0
		if on_x:
			pos = Vector3(ROAD_XS[rng.randi() % ROAD_XS.size()] + 2.5, ROAD_TOP + CAR_LIFT, ROAD_ZS[0] + 5 + rng.randi_range(0, 7) * 10)
		else:
			pos = Vector3(ROAD_XS[0] + 5 + rng.randi_range(0, 11) * 10, ROAD_TOP + CAR_LIFT, ROAD_ZS[rng.randi() % ROAD_ZS.size()] + 2.5)
			rot = 90.0
		_prop(props, CITY % cars[rng.randi() % cars.size()], pos, rot + (180.0 if rng.randf() < 0.5 else 0.0), CITY_SCALE, "caixa")
	for k in 14:
		var z: int = ROAD_ZS[rng.randi() % ROAD_ZS.size()]
		var x := ROAD_XS[0] + 3 + rng.randi_range(0, 23) * 5
		var item: String = ["trash_A", "trash_B", "firehydrant", "dumpster", "box_A", "box_B"][rng.randi() % 6]
		var item_rot := rng.randf_range(0, 360)
		# Na areia da praça não (atrapalhava a festa e a barraca de tiro); o sorteio continua o mesmo.
		if PLAZA.grow(-5.0).has_point(Vector2(x, z - 7.5)):
			continue
		_prop(props, CITY % item, Vector3(x, 0, z - 7.5), item_rot, CITY_SCALE, "caixa")
	_prop(props, CITY % "watertower", Vector3(-85, 0, 200), 0.0, CITY_SCALE, "caixa")

	# Praça da festa: palco, arco, balões e bancos. Aqui o jogo começa.
	var plaza := _group(city, "Praca")
	var center := Vector3(PLAZA.position.x + 20, 0, PLAZA.position.y + 20)
	_prop(plaza, PLAT % "red/platform_4x4x1_red", center + Vector3(-2, 0, -12), 0.0, 1.0, "caixa")
	_prop(plaza, PLAT % "blue/platform_4x4x1_blue", center + Vector3(2, 0, -12), 0.0, 1.0, "caixa")
	_prop(plaza, PLAT % "yellow/arch_wide_yellow", center + Vector3(0, 1, -13.6), 0.0, 1.0)
	var balls := ["red/ball_red", "blue/ball_blue", "yellow/ball_yellow", "green/ball_green"]
	for k in 8:
		var a := TAU * k / 8.0
		var p := center + Vector3(cos(a) * 13.0, 0, sin(a) * 13.0)
		_prop(plaza, PLAT % "neutral/pillar_1x1x4", p, 0.0, 0.6, "caixa")
		_prop(plaza, PLAT % balls[k % balls.size()], p + Vector3(0, 3.4, 0), 0.0, 0.6)
	for k in 4:
		var a := TAU * k / 4.0 + PI / 4.0
		_prop(plaza, CITY % "bench", center + Vector3(cos(a) * 7.0, 0, sin(a) * 7.0), rad_to_deg(-a), CITY_SCALE, "caixa")
	for corner in [Vector3(-15, 0, -15), Vector3(15, 0, -15), Vector3(-15, 0, 15), Vector3(15, 0, 15)]:
		# Cerejeiras rosas nos cantos da praça da festa.
		_prop(plaza, _tree_path("Tree_2_A", 8), center + corner, rng.randf_range(0, 360), 1.3, "tronco")


# --- festa na praça -----------------------------------------------------------

## Enfeites e comida da Festa do Cafuné em volta da praça (o meio fica livre para a luta do prólogo):
## presentes e trenzinho ao lado do palco, lanternas, mesas de comida e doces, a barraca dos
## fazendeiros e o cantinho do palhaço. Posições fixas: não mexe no sorteio do resto da ilha.
func _festa() -> void:
	var festa := _group(_find_group("Cidade/Praca"), "Festa")
	var c := Vector3(PLAZA.position.x + 20, 0, PLAZA.position.y + 20)
	var at := func(x: float, z: float) -> Vector3:
		return Vector3(c.x + x, ground(c.x + x, c.z + z), c.z + z)
	# Presentes empilhados à esquerda do palco e trenzinho de presentes à direita.
	var presents := [["doces/present_A_red", -6.6, -12.4, 20.0], ["doces/present_B_blue", -5.8, -13.3, 50.0],
		["doces/present_C_yellow", -7.4, -13.2, 10.0], ["doces/present_D_green", -6.2, -11.5, 70.0],
		["doces/present_sphere_A_green", -7.6, -11.9, 0.0], ["doces/present_E_white", -5.4, -12.2, 35.0],
		["doces/present_sphere_B_red", -6.9, -14.0, 0.0], ["doces/present_F_red", -8.2, -12.6, 80.0]]
	for spec in presents:
		_prop(festa, FESTA % spec[0], at.call(spec[1], spec[2]), spec[3], 1.5)
	_prop(festa, FESTA % "doces/present_A_yellow", at.call(-6.5, -12.7) + Vector3.UP * 0.99, 15.0, 1.3)
	var train := ["doces/train_locomotive", "doces/train_tender_presents_A", "doces/train_wagon", "doces/train_tender_presents_B"]
	for k in train.size():
		_prop(festa, FESTA % train[k], at.call(5.2 + k * 1.5, -12.6), 90.0, 1.8)
	# Lanternas enfeitadas nos cantos do palco e na entrada da praça.
	for spot in [Vector2(-4.8, -9.4), Vector2(4.8, -9.4), Vector2(-3.5, 17.5), Vector2(3.5, 17.5)]:
		_prop(festa, FESTA % "doces/lantern_decorated", at.call(spot.x, spot.y), 0.0, 0.8, "tronco")
	# Mesas de comida a oeste e de doces a leste.
	_table(festa, "comida/table_round_B_tablecloth_red", at.call(-11.5, -3.0), [
		["comida/food_pizza_cheese_plated", Vector3(-0.35, 0, -0.3), 0.42], ["comida/food_burger", Vector3(0.55, 0, 0.35), 0.5],
		["comida/icecream_bowl_decorated_A", Vector3(0.4, 0, -0.65), 0.6]])
	_table(festa, "comida/table_round_B_tablecloth_green", at.call(-11.5, 4.0), [
		["comida/food_pizza_pepperoni_plated", Vector3(0.3, 0, 0.3), 0.42], ["comida/food_vegetableburger", Vector3(-0.55, 0, -0.35), 0.5],
		["comida/icecream_cone_stacked", Vector3(-0.5, 0, 0.55), 0.6]])
	_table(festa, "comida/table_round_A_decorated", at.call(11.5, -3.0), [])
	_table(festa, "comida/table_round_B_tablecloth_red", at.call(11.5, 4.0), [
		["doces/plate_decorated_A", Vector3(-0.4, 0, -0.3), 0.7], ["doces/plate_decorated_B", Vector3(0.45, 0, 0.3), 0.7],
		["doces/hot_chocolate_decorated", Vector3(0.45, 0, -0.5), 0.9], ["doces/candy_A_pink", Vector3(-0.3, 0, 0.55), 1.2],
		["doces/candy_B_blue", Vector3(-0.6, 0, 0.2), 1.2]])
	_prop(festa, FESTA % "comida/icecream_machine", at.call(14.5, -6.5), -60.0, 0.6, "caixa")
	# Barraca dos fazendeiros (sudoeste): bancada com verduras, caixotes e o carrinho de mão.
	_table(festa, "comida/kitchentable_A_large", at.call(-15.5, 9.0), [
		["moradores/carrot", Vector3(-0.4, 0, -0.5), 1.4], ["moradores/lettuce", Vector3(0.3, 0, -0.2), 1.4],
		["moradores/carrot", Vector3(0.1, 0, 0.5), 1.4]], 90.0, 0.8, MORADOR_ITEM)
	for spec in [["comida/crate_carrots", -13.3, 7.6], ["comida/crate_lettuce", -13.3, 9.0], ["comida/crate_tomatoes", -13.3, 10.4]]:
		_prop(festa, FESTA % spec[0], at.call(spec[1], spec[2]), 90.0, 0.45, "caixa")
	_prop(festa, MORADOR_ITEM % "moradores/wheelbarrow", at.call(-17.0, 12.6), 20.0, 0.9, "caixa")
	# Barraca de poções da bruxa (noroeste): bancada de poções, caldeirão e cesto de cogumelos.
	_prop(festa, EXTRAS % "moradores/bruxa/Potionstation_decorated", at.call(-15.6, -8.2), 90.0, 1.0, "caixa")
	_prop(festa, EXTRAS % "moradores/bruxa/Cauldron", at.call(-12.9, -6.4), 0.0, 1.2, "caixa")
	_prop(festa, EXTRAS % "moradores/bruxa/Basket_Mushrooms", at.call(-13.6, -10.0), 30.0, 1.2)
	_prop(festa, EXTRAS % "moradores/bruxa/Broom", at.call(-17.2, -10.3), 15.0, 1.1)
	# Cantinho do palhaço (sudeste): pódio, arco e brinquedos no chão.
	_prop(festa, FESTA % "circo/circus_podium", at.call(15.0, 8.0), 0.0, 0.8, "caixa")
	_prop(festa, FESTA % "circo/circus_hoop", at.call(16.8, 10.6), -30.0, 0.8)
	for spec in [["circo/juggling_pin_red", 13.6, 9.6], ["circo/juggling_pin_blue", 13.9, 9.9], ["circo/juggling_pin_yellow", 13.4, 10.1]]:
		_prop(festa, FESTA % spec[0], at.call(spec[1], spec[2]), 40.0, 1.3)
	_prop(festa, FESTA % "circo/clown_ball", at.call(13.4, 6.4), 0.0, 1.0)


## Mesa com coisas em cima (posições relativas ao centro do tampo).
func _table(parent: Node, table: String, pos: Vector3, items: Array, rot := 0.0, s := 0.8, item_fmt := FESTA) -> void:
	var t := _prop(parent, FESTA % table, pos, rot, s, "caixa")
	var inst: Node3D = t.get_child(0)
	var top := _model_aabb(inst).end.y * s
	for spec in items:
		var off: Vector3 = Basis(Vector3.UP, deg_to_rad(rot)) * spec[1]
		_prop(parent, item_fmt % spec[0], pos + off + Vector3.UP * top, rot + 20.0, spec[2])


func _find_group(path: String) -> Node3D:
	return ilha.get_node(path)


# --- Morro -------------------------------------------------------------------

func _morro() -> void:
	var morro := _group(ilha, "Morro")
	var top := MORRO_H
	_cemiterio(morro, top)
	# Cúpula mágica sobre o cemitério todo: some quando as quatro lanternas apagam (o jogo cuida disso).
	var dome := StaticBody3D.new()
	dome.name = "CupulaDoCemiterio"
	dome.position = Vector3(0, top, 0)
	_add(morro, dome)
	var dome_mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = CEMETERY_DOME_R
	sphere.height = CEMETERY_DOME_R * 2.0
	sphere.material = _magic_material()
	dome_mi.mesh = sphere
	dome_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(dome, dome_mi)
	var dome_cs := CollisionShape3D.new()
	var dome_shape := SphereShape3D.new()
	dome_shape.radius = CEMETERY_DOME_R
	dome_cs.shape = dome_shape
	_add(dome, dome_cs)
	# Placa no começo da subida.
	var sign_pos := _spiral_point(0.0) + Vector2(4, 4)
	_prop(morro, PLAT % "neutral/sign", Vector3(sign_pos.x, ground(sign_pos.x, sign_pos.y), sign_pos.y), 0.0, 1.0, "caixa")
	# Algumas árvores e pedras nas encostas, fora da trilha.
	var trees := ["Tree_1_A", "Tree_2_B", "Tree_3_B", "Tree_4_A"]
	var placed := 0
	var tries := 0
	while placed < 38 and tries < 3000:
		tries += 1
		var a := rng.randf_range(0, TAU)
		var r := rng.randf_range(30, MORRO_R - 4)
		var x := cos(a) * r
		var z := sin(a) * r
		if _spiral_dist(x, z) < PATH_HALF + 3.0 or z > CITY_Z - 4 or _trail_dist(Vector2(x, z)) < 5.0:
			continue
		var slope_color: int = [1, 2, 3, 6][rng_cor.randi() % 4]
		_prop(morro, _tree_path(trees[rng.randi() % trees.size()], slope_color), Vector3(x, ground(x, z) - 0.1, z), rng.randf_range(0, 360), FOREST_SCALE * rng.randf_range(0.8, 1.15), "tronco")
		placed += 1
	for k in 16:
		var a := rng.randf_range(0, TAU)
		var r := rng.randf_range(20, MORRO_R)
		var x := cos(a) * r
		var z := sin(a) * r
		if _spiral_dist(x, z) < PATH_HALF + 2.0 or z > CITY_Z:
			continue
		_prop(morro, FOREST % ("Rock_%d_%s_Color1" % [rng.randi_range(1, 3), "ABCDE"[rng.randi() % 5]]), Vector3(x, ground(x, z) - 0.1, z), rng.randf_range(0, 360), FOREST_SCALE * rng.randf_range(0.8, 1.6), "convexo")


## Cemitério dos Ossinhos no topo do Morro: a casa dos esqueletos, simpática e de dia. Cerca em volta com
## portão em arco onde a trilha chega, cripta no fundo (norte) com a lanterna mágica flutuando em cima,
## túmulos nas laterais, abóboras, velas, lanternas e os doces que os esqueletos juntaram para a festa.
## O meio fica livre para a luta final. Posições fixas: não mexe no sorteio do resto da ilha.
func _cemiterio(morro: Node, top: float) -> void:
	var cem := _group(morro, "Cemiterio")
	var at := func(x: float, z: float) -> Vector3:
		return Vector3(x, ground(x, z), z)
	var gate_a := _gate_angle()
	var fence_r := MORRO_TOP_R - 2.0
	# Cerca de segmentos de 4 m com pilares, deixando o vão do portão.
	var segs := int(TAU * fence_r / 4.4)
	var step := TAU / segs
	for k in segs:
		var a := step * k
		if absf(angle_difference(a, gate_a)) < 0.2:
			continue
		var p := Vector2(cos(a), sin(a)) * fence_r
		_prop(cem, CEMITERIO % "fence", at.call(p.x, p.y), _tangent_deg(a), 1.05, "caixa")
		var q := Vector2(cos(a + step * 0.5), sin(a + step * 0.5)) * fence_r
		_prop(cem, CEMITERIO % "fence_pillar", at.call(q.x, q.y), _tangent_deg(a), 1.05, "caixa")
	var g := Vector2(cos(gate_a), sin(gate_a)) * fence_r
	_prop(cem, CEMITERIO % "arch_gate", at.call(g.x, g.y), _tangent_deg(gate_a), 1.3)
	# Cripta no fundo e a lanterna mágica flutuando em cima.
	_prop(cem, CEMITERIO % "crypt", at.call(0, -17.5), 180.0, 1.3, "caixa")
	_orb(cem, "LanternaCentral", Vector3(0, top + 13.0, -17.5), 1.0)
	# Caminho de pedra do portão até o meio e do meio até a porta da cripta.
	var mid := Vector2(0, 2)
	for seg in [[g * 0.95, mid], [mid, Vector2(0, -11.5)]]:
		var a2: Vector2 = seg[0]
		var b2: Vector2 = seg[1]
		var n := int(a2.distance_to(b2) / 2.1)
		for i in n + 1:
			var p := a2.lerp(b2, float(i) / maxf(n, 1))
			_prop(cem, CEMITERIO % ["path_A", "path_B", "path_C"][i % 3], at.call(p.x, p.y) + Vector3.UP * 0.02, 37.0 * i, 1.1)
	# Túmulos nas laterais (o meio fica livre).
	var stones := ["grave_A", "gravestone", "grave_B", "gravemarker_A", "gravemarker_B"]
	var spots := []
	for x in [13.5, 17.0]:
		for z in [-9.0, -5.0, -1.0, 3.0, 7.0]:
			spots.append(Vector2(x, z))
	for x in [-13.5, -17.0]:
		for z in [-11.0, -7.0, -3.0]:
			spots.append(Vector2(x, z))
	for v in [Vector2(-7.5, -18.0), Vector2(7.5, -18.0)]:
		spots.append(v)
	for i in spots.size():
		var v: Vector2 = spots[i]
		var name: String = stones[i % stones.size()]
		_prop(cem, CEMITERIO % name, at.call(v.x, v.y), 0.0, 1.1, "caixa" if name.begins_with("grave_") else "")
		if i % 3 == 0:
			_prop(cem, CEMITERIO % "candle_triple", at.call(v.x + 0.9, v.y + 0.8), 20.0 * i, 1.0)
	# Lanternas pela beira da cerca.
	for k in 8:
		var a := TAU * k / 8.0 + 0.2
		if absf(angle_difference(a, gate_a)) < 0.45:
			continue
		var p := Vector2(cos(a), sin(a)) * (fence_r - 1.6)
		_prop(cem, CEMITERIO % "post_lantern", at.call(p.x, p.y), rad_to_deg(-a) - 90.0, 1.2, "tronco")
	# Abóboras sorridentes no portão e espalhadas, espantalho e feno, doces juntados na porta da cripta.
	for side in [-1.0, 1.0]:
		var p := Vector2(cos(gate_a + side * 0.16), sin(gate_a + side * 0.16)) * (fence_r - 1.8)
		_prop(cem, CEMITERIO % "pumpkin_orange_jackolantern", at.call(p.x, p.y), rad_to_deg(-gate_a) + 90.0, 1.1, "caixa")
	for spec in [["pumpkin_yellow_jackolantern", 15.0, 10.0], ["pumpkin_orange", 11.5, -12.0], ["pumpkin_yellow_small", -11.0, -14.0],
			["pumpkin_orange_small", 16.0, -12.5], ["pumpkin_orange", -15.0, 1.5], ["pumpkin_yellow", 4.0, -15.0]]:
		_prop(cem, CEMITERIO % spec[0], at.call(spec[1], spec[2]), 30.0, 1.1, "caixa")
	_prop(cem, CEMITERIO % "scarecrow", at.call(17.5, 12.5), -150.0, 1.2, "tronco")
	_prop(cem, CEMITERIO % "haybale", at.call(15.5, 14.0), 70.0, 1.1, "caixa")
	_prop(cem, CEMITERIO % "haybale", at.call(18.5, 10.0), 20.0, 1.1, "caixa")
	for spec in [["candy_bucket_A_decorated", -2.6, -10.6], ["candy_bucket_B_decorated", 2.6, -10.8], ["lollipop_pink", -3.6, -10.0],
			["lollipop_blue", 3.5, -10.2], ["candycorn", -1.8, -9.8], ["lollipop_orange", 1.6, -9.6]]:
		_prop(cem, CEMITERIO % spec[0], at.call(spec[1], spec[2]), 15.0, 1.2)
	_prop(cem, CEMITERIO % "shrine_candles", at.call(-5.0, -12.5), 0.0, 1.1, "caixa")
	_prop(cem, CEMITERIO % "plaque_candles", at.call(5.0, -12.5), 0.0, 1.1, "caixa")
	# Pinheiros de outono por fora da cerca, fora da trilha.
	var pines := ["tree_pine_orange_large", "tree_pine_yellow_medium", "tree_pine_orange_medium", "tree_pine_yellow_large", "tree_pine_orange_small"]
	for k in 14:
		var a := TAU * k / 14.0 + 0.11
		var r := MORRO_TOP_R + 2.5 + (k % 3) * 1.6
		var p := Vector2(cos(a), sin(a)) * r
		if absf(angle_difference(a, gate_a)) < 0.35 or _spiral_dist(p.x, p.y) < PATH_HALF + 2.0:
			continue
		_prop(cem, CEMITERIO % pines[k % pines.size()], at.call(p.x, p.y) - Vector3.UP * 0.3, 40.0 * k, 1.2, "tronco")


## Ângulo (em volta do centro do Morro) em que a trilha chega na beira do topo.
func _gate_angle() -> float:
	var s := clampf((SPIRAL_R0 - (MORRO_TOP_R - 1.0)) / (SPIRAL_R0 - SPIRAL_R1), 0.0, 1.0)
	var p := _spiral_point(s)
	return atan2(p.y, p.x)


## Rotação (graus, em Y) que deixa o eixo X do modelo na tangente do círculo no ângulo a.
func _tangent_deg(a: float) -> float:
	return rad_to_deg(atan2(-cos(a), -sin(a)))


## Árvore ou arbusto na cor pedida (1 é a original do pacote grátis).
func _tree_path(model: String, color: int) -> String:
	if color == 1:
		return FOREST % (model + "_Color1")
	return FOREST_COLOR % [color, model, color]


## Cor das árvores da mata: verdes misturados; outono perto do Morro dos Ventos; cerejeiras perto da Clareira.
func _forest_color(p: Vector2) -> int:
	if p.distance_to(VENTOS) < 55.0:
		return [6, 6, 5, 1][rng_cor.randi() % 4]
	if p.distance_to(CLAREIRA) < 45.0:
		return [8, 7, 1, 3][rng_cor.randi() % 4]
	return [1, 1, 2, 3][rng_cor.randi() % 4]


func _orb(parent: Node, orb_name: String, pos: Vector3, radius: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = orb_name
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#b06cff")
	mat.emission_enabled = true
	mat.emission = Color("#b06cff")
	mat.emission_energy_multiplier = 2.0
	sphere.material = mat
	mi.mesh = sphere
	mi.position = pos
	_add(parent, mi)
	return mi


# --- ponte e cais ------------------------------------------------------------

## Passarela de tábuas entre dois pontos (a, b = topo do piso), com corrimãos dos lados.
func _walkway(parent: Node, walk_name: String, a: Vector3, b: Vector3, width: float) -> void:
	var group := _group(parent, walk_name)
	var flat := Vector2(b.x - a.x, b.z - a.z)
	var length := Vector3(b - a).length()
	var yaw := atan2(flat.x, flat.y)
	var pitch := atan2(b.y - a.y, flat.length())
	var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -pitch)
	var mid := (a + b) * 0.5
	_box_body(group, "Piso", Vector3(width, 0.4, length), Transform3D(basis, mid - basis.y * 0.2), Color("#b07a45"))
	for side in [-1.0, 1.0]:
		var rail_pos: Vector3 = mid + basis.x * (side * (width * 0.5 - 0.1)) + basis.y * 0.5
		_box_body(group, "Corrimao", Vector3(0.2, 1.0, length), Transform3D(basis, rail_pos), Color("#8a5a30"))


func _bridge_and_pier() -> void:
	var z_south := _river_z(0) + RIVER_HALF + RIVER_BANK + 2.0
	var z_north := _river_z(0) - RIVER_HALF - RIVER_BANK - 2.0
	_stone_bridge(z_south, z_north)
	# Barreira mágica na cabeceira sul: some quando as duas lanternas da cidade apagam (o jogo cuida disso).
	_magic_wall(ilha, "BarreiraDaPonte", Vector3(0, ground(0, z_south + 1.0) + 2.5, z_south + 1.0), Vector3(9, 5, 0.5))
	# Cais: sai da praça para o mar, ao sul.
	_walkway(ilha, "Cais", Vector3(0, ground(0, 206) + 0.02, 206), Vector3(0, 0.25, 252), 7.0)
	# Pescador no fim do cais: caixa de pesca e balde (o pescador é um morador; o jogo cria).
	var pier_y := lerpf(ground(0, 206) + 0.02, 0.25, (247.0 - 206.0) / 46.0)
	_prop(ilha, EXTRAS % "pesca/fishing_tacklebox", Vector3(1.0, pier_y, 246.0), 15.0, 1.1)
	_prop(ilha, EXTRAS % "pesca/bucket_metal", Vector3(1.2, pier_y, 248.3), 0.0, 1.0)
	# Toras do lenhador na margem sul do rio, perto da ponte.
	var river_s := _river_z(12.0) + RIVER_HALF + RIVER_BANK + 6.0
	var logs := _group(ilha, "Lenha")
	for spec in [["log_stacks", 14.6, 1.6, 20.0], ["log_stacks", 9.2, 1.4, -15.0], ["log_split", 13.4, -1.8, 60.0]]:
		_prop(logs, EXTRAS % ("moradores/lenhador/" + spec[0]), Vector3(spec[1], ground(spec[1], river_s + spec[2]), river_s + spec[2]), spec[3], 1.3, "caixa")


## Ponte de pedra em arco (Medieval Hexagon) sobre o rio. No pacote ela fica na diagonal do hexágono (30° do
## eixo Z), com o piso numa faixa de uns 0,4 x 2 m que desce de leve do meio (0,20) para as pontas (0,0):
## gira para alinhar com o rio, estica (6 m de largura, comprimento de margem a margem) e as pontas ficam na
## altura das margens. A colisão é uma malha com a escala já aplicada nos pontos (escala diferente por eixo
## não funciona bem na física da Godot).
func _stone_bridge(z_south: float, z_north: float) -> void:
	var group := _group(ilha, "Ponte")
	var length := (z_south - z_north) + 2.0
	var sc := Vector3(6.0 / 0.4, 3.2, length / 2.0)
	var deck_y := maxf(ground(0, z_south), ground(0, z_north)) + 0.08
	var origin := Vector3(0, deck_y, (z_south + z_north) * 0.5)
	var holder := Node3D.new()
	holder.name = "PonteDePedra"
	holder.position = origin
	holder.scale = sc
	_add(group, holder)
	var inst: Node3D = load(PONTE % "building_bridge_A").instantiate()
	inst.rotation_degrees.y = -30.0
	_add(holder, inst)
	var body := StaticBody3D.new()
	body.name = "Piso"
	_add(group, body)
	var faces := PackedVector3Array()
	var base := Transform3D(Basis.from_scale(sc), origin) * Transform3D(Basis(Vector3.UP, deg_to_rad(-30.0)), Vector3.ZERO)
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var xf := base * _rel_xform(mi, inst)
		for v in (mi as MeshInstance3D).mesh.get_faces():
			faces.append(xf * v)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	var cs := CollisionShape3D.new()
	cs.shape = shape
	_add(body, cs)
	# Rampas invisíveis nas pontas: o personagem não sobe degrau, e a margem fica um pouco abaixo do piso.
	var end_s := z_south + 1.0
	var end_n := z_north - 1.0
	_ramp(group, Vector3(0, ground(0, end_s + 3.0), end_s + 3.0), Vector3(0, deck_y, end_s - 0.6), 6.0)
	_ramp(group, Vector3(0, deck_y, end_n + 0.6), Vector3(0, ground(0, end_n - 3.0), end_n - 3.0), 6.0)


## Rampa invisível (só colisão) de a até b.
func _ramp(parent: Node, a: Vector3, b: Vector3, width: float) -> void:
	var flat := Vector2(b.x - a.x, b.z - a.z)
	var basis := Basis(Vector3.UP, atan2(flat.x, flat.y)) * Basis(Vector3.RIGHT, -atan2(b.y - a.y, flat.length()))
	var body := StaticBody3D.new()
	body.name = "Rampa"
	_add(parent, body)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, 0.3, Vector3(b - a).length())
	cs.shape = box
	cs.transform = Transform3D(basis, (a + b) * 0.5 - basis.y * 0.15)
	_add(body, cs)


func _magic_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.45, 1.0, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color("#b06cff")
	mat.emission_energy_multiplier = 0.8
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


## Parede mágica roxa translúcida, com colisão.
func _magic_wall(parent: Node, wall_name: String, center: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = wall_name
	body.position = center
	_add(parent, body)
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _magic_material()
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(body, mi)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	_add(body, cs)
	return body


# --- mata --------------------------------------------------------------------

func _forest() -> void:
	var forest := _group(ilha, "Mata")
	var trees := TREE_SHAPES
	var placed: Array[Vector2] = []
	var tries := 0
	while placed.size() < 330 and tries < 12000:
		tries += 1
		var p := Vector2(rng.randf_range(-190, 190), rng.randf_range(-245, RIVER_Z - 15))
		if _island_d(p.x, p.y) > 0.84 or _trail_dist(p) < 4.5:
			continue
		if p.distance_to(CLAREIRA) < 24.0 or p.distance_to(VILA) < 14.0 or p.distance_to(VENTOS) < 10.0 or _near_region(p):
			continue
		var ok := true
		for q in placed:
			if p.distance_squared_to(q) < 36.0:
				ok = false
				break
		if not ok:
			continue
		placed.append(p)
		_prop(forest, _tree_path(trees[rng.randi() % trees.size()], _forest_color(p)), Vector3(p.x, ground(p.x, p.y) - 0.1, p.y), rng.randf_range(0, 360), FOREST_SCALE * rng.randf_range(0.85, 1.25), "tronco")
	# Árvores nos arredores da cidade, a leste e a oeste.
	for k in 60:
		var side := -1.0 if k % 2 == 0 else 1.0
		var p := Vector2(side * rng.randf_range(78, 175), rng.randf_range(20, 205))
		if _island_d(p.x, p.y) > 0.84 or _near_region(p):
			continue
		var city_color: int = [1, 3][rng_cor.randi() % 2]
		_prop(forest, _tree_path(trees[rng.randi() % trees.size()], city_color), Vector3(p.x, ground(p.x, p.y) - 0.1, p.y), rng.randf_range(0, 360), FOREST_SCALE * rng.randf_range(0.85, 1.2), "tronco")
	# Jabuticabeira gigante no meio da clareira.
	_prop(forest, FOREST % "Tree_1_A_Color1", Vector3(CLAREIRA.x, ground(CLAREIRA.x, CLAREIRA.y) - 0.2, CLAREIRA.y), 30.0, FOREST_SCALE * 3.2, "tronco")
	# Vila das Copas: plataformas de madeira entre as árvores (chegar lá em cima fica para o pulo duplo).
	for k in 3:
		var a := TAU * k / 3.0
		var p := VILA + Vector2(cos(a), sin(a)) * 8.0
		var y := ground(p.x, p.y)
		_prop(forest, PLAT % "neutral/pillar_1x1x4", Vector3(p.x, y, p.y), 0.0, 1.0, "caixa")
		_prop(forest, PLAT % "red/platform_4x4x1_red", Vector3(p.x, y + 4.0, p.y), rad_to_deg(a), 1.0, "caixa")
	# Passarelas de tábuas ligando o topo das plataformas (as molas no chão levam até lá; o jogo cuida disso).
	for k in 3:
		var a := VILA + Vector2(cos(TAU * k / 3.0), sin(TAU * k / 3.0)) * 8.0
		var b := VILA + Vector2(cos(TAU * (k + 1) / 3.0), sin(TAU * (k + 1) / 3.0)) * 8.0
		var ab := (b - a).normalized()
		var pa := a + ab * 2.1
		var pb := b - ab * 2.1
		_walkway(forest, "Passarela%d" % (k + 1), Vector3(pa.x, ground(a.x, a.y) + 5.0, pa.y), Vector3(pb.x, ground(b.x, b.y) + 5.0, pb.y), 1.8)
	# Pedras e arbustos.
	for k in 70:
		var p := Vector2(rng.randf_range(-185, 185), rng.randf_range(-240, 200))
		if _island_d(p.x, p.y) > 0.84 or _in_city(p.x, p.y) or _trail_dist(p) < 4.0 or p.length() < MORRO_R or _near_region(p):
			continue
		if absf(p.y - _river_z(p.x)) < RIVER_HALF + RIVER_BANK + 2.0:
			continue
		_prop(forest, FOREST % ("Rock_%d_%s_Color1" % [rng.randi_range(1, 3), "ABCDEFG"[rng.randi() % 7]]), Vector3(p.x, ground(p.x, p.y) - 0.1, p.y), rng.randf_range(0, 360), FOREST_SCALE * rng.randf_range(0.7, 1.5), "convexo")
	for k in 160:
		var p := Vector2(rng.randf_range(-185, 185), rng.randf_range(-240, 200))
		if _island_d(p.x, p.y) > 0.85 or _in_city(p.x, p.y) or _trail_dist(p) < 3.0 or ground(p.x, p.y) < SEA_LEVEL + 0.5 or _near_region(p, -6.0):
			continue
		if p.length() < MORRO_R and (_spiral_dist(p.x, p.y) < PATH_HALF + 1.0 or p.length() < MORRO_TOP_R + 1.0):
			continue
		var bush := "Bush_%d_%s" % [rng.randi_range(1, 4), "ABC"[rng.randi() % 3]]
		var bush_color: int = [1, 1, 2, 3, 8][rng_cor.randi() % 5]
		_prop(forest, _tree_path(bush, bush_color), Vector3(p.x, ground(p.x, p.y) - 0.05, p.y), rng.randf_range(0, 360), FOREST_SCALE * rng.randf_range(0.8, 1.2))
	# Morrinhos de pedra com topo de grama na margem sul do rio (longe da ponte e do lugar do tchibum).
	var hills := [["Hill_8x8x4", -150.0], ["Hill_12x6x4", -118.0], ["Hill_8x4x4", -86.0], ["Hill_4x4x4", -62.0],
		["Hill_8x8x4", 78.0], ["Hill_12x6x4", 108.0], ["Hill_8x4x4", 140.0]]
	for h in hills:
		var hx: float = h[1]
		var hz := _river_z(hx) + RIVER_HALF + RIVER_BANK + 5.0
		if _island_d(hx, hz) > 0.82 or _trail_dist(Vector2(hx, hz)) < 6.0 or Vector2(hx, hz).length() < MORRO_R + 4.0:
			continue
		_prop(forest, FOREST % (h[0] + "_Color1"), Vector3(hx, ground(hx, hz) - 0.4, hz), rad_to_deg(atan2(_river_z(hx + 1.0) - _river_z(hx), 1.0)), 1.0, "caixa")


## Grama em MultiMesh (milhares de tufos sem pesar).
func _grass() -> void:
	var group := _group(ilha, "Grama")
	for kind in ["Grass_1_A_Color1", "Grass_2_A_Color1"]:
		var inst: Node3D = load(FOREST % kind).instantiate()
		var mi: MeshInstance3D = inst.find_children("*", "MeshInstance3D", true, false)[0]
		var xforms: Array[Transform3D] = []
		var tries := 0
		while xforms.size() < 1800 and tries < 20000:
			tries += 1
			var p := Vector2(rng.randf_range(-185, 185), rng.randf_range(-240, 205))
			var h := ground(p.x, p.y)
			if _island_d(p.x, p.y) > 0.85 or _in_city(p.x, p.y) or h < SEA_LEVEL + 0.5 or _trail_dist(p) < 2.5:
				continue
			if p.length() < MORRO_R and (_spiral_dist(p.x, p.y) < PATH_HALF + 0.5 or p.length() < MORRO_TOP_R + 2.0):
				continue
			var s := FOREST_SCALE * rng.randf_range(0.8, 1.3)
			xforms.append(Transform3D(Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3.ONE * s), Vector3(p.x, h - 0.05, p.y)) * _rel_xform(mi, inst))
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mi.mesh
		mm.instance_count = xforms.size()
		for k in xforms.size():
			mm.set_instance_transform(k, xforms[k])
		var path := "res://assets/terrain/%s.res" % kind.to_lower()
		ResourceSaver.save(mm, path)
		mm.take_over_path(path)
		var mmi := MultiMeshInstance3D.new()
		mmi.name = kind
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_add(group, mmi)
		print("grama %s: %d tufos" % [kind, xforms.size()])
		inst.free()


# --- marcadores (editáveis no editor) ----------------------------------------

func _marker(parent: Node, marker_name: String, x: float, z: float, meta := {}) -> Marker3D:
	var m := Marker3D.new()
	m.name = marker_name
	m.position = Vector3(x, ground(x, z) + 0.1, z)
	for key in meta:
		m.set_meta(key, meta[key])
	_add(parent, m)
	return m


func _markers() -> void:
	var markers := _group(ilha, "Marcadores")
	_marker(markers, "Inicio", 0, 178)

	var cps := _group(markers, "PontosDeRetorno")
	_marker(cps, "Praca", 9, 170)
	_marker(cps, "PeDoMorro", 8, 97)
	# Na trilha, logo antes do portão do cemitério (fora da cúpula, que cobre o topo inteiro).
	var top_cp := _spiral_point((SPIRAL_R0 - (CEMETERY_DOME_R + 2.5)) / (SPIRAL_R0 - SPIRAL_R1))
	_marker(cps, "TopoDoMorro", top_cp.x, top_cp.y)
	_marker(cps, "EntradaDaMata", 8, -133)
	_marker(cps, "Clareira", 54, -170)
	_marker(cps, "MorroDosVentos", -66, -142)
	_marker(cps, "CidadeOeste", -58, 152)
	_marker(cps, "CidadeLeste", 58, 152)

	var enemies := _group(markers, "Esqueletos")
	# Grupinhos soltos entre as regiões (a maior parte dos esqueletos vem nas ondas das defesas).
	var spawns := [
		["Skeleton_Minion", Vector2(-30, 110)], ["Skeleton_Minion", Vector2(30, 110)], ["Skeleton_Rogue", Vector2(2, 112)],
		["Skeleton_Minion", _spiral_point(0.08)], ["Skeleton_Minion", _spiral_point(0.2)], ["Skeleton_Rogue", _spiral_point(0.36)],
		["Skeleton_Rogue", _spiral_point(0.56)], ["Skeleton_Warrior", _spiral_point(0.82)],
		["Skeleton_Minion", Vector2(10, -142)], ["Skeleton_Minion", Vector2(-32, -164)], ["Skeleton_Rogue", Vector2(-62, -196)],
		["Skeleton_Mage", Vector2(70, -205)], ["Skeleton_Warrior", Vector2(104, -152)], ["Skeleton_Minion", Vector2(78, -150)],
	]
	var counts := {}
	for spawn in spawns:
		var kind: String = spawn[0]
		counts[kind] = counts.get(kind, 0) + 1
		var p: Vector2 = spawn[1]
		_marker(enemies, "%s_%02d" % [kind.trim_prefix("Skeleton_"), counts[kind]], p.x, p.y, {"tipo": kind})

	# Regiões de defesa: centro da arena e 4 rachaduras em volta, de onde saem as ondas.
	var regions := _group(markers, "Regioes")
	for key in REGIONS:
		var c: Vector2 = REGIONS[key]
		var r := _marker(regions, key, c.x, c.y, {"raio": ARENA_R})
		for k in 4:
			var a := PI / 4.0 + k * PI / 2.0
			var cp := c + Vector2(cos(a), sin(a)) * (12.0 if key == "praca" else 15.0)
			var crack := Marker3D.new()
			crack.name = "Rachadura%d" % (k + 1)
			crack.position = Vector3(cp.x, ground(cp.x, cp.y) + 0.05, cp.y) - r.position
			_add(r, crack)

	# Defesa final: a arena no meio do cemitério, entre o portão e a cripta; rachaduras nas diagonais.
	var cemetery := _marker(regions, "cemiterio", 0, 2, {"raio": 18.0})
	for k in 4:
		var a := PI / 4.0 + k * PI / 2.0
		var cp := Vector2(0, 2) + Vector2(cos(a), sin(a)) * 10.0
		var crack := Marker3D.new()
		crack.name = "Rachadura%d" % (k + 1)
		crack.position = Vector3(cp.x, ground(cp.x, cp.y) + 0.05, cp.y) - cemetery.position
		_add(cemetery, crack)

	# Desafio do Guerreiro Planta na Vila das Copas (opcional): só o guardião, sem rachaduras.
	_marker(regions, "vila", VILA.x, VILA.y, {"raio": 12.0})

	# Diversões: barraca de tiro ao alvo no canto sudoeste da praça (os alvos ficam ao sul do marcador) e as
	# molas da Vila das Copas, uma ao lado de cada plataforma, do lado de dentro.
	var fun := _group(markers, "Diversao")
	var pc0 := Vector2(PLAZA.position.x + 20, PLAZA.position.y + 20)
	_marker(fun, "TiroAoAlvo", pc0.x - 6.0, pc0.y + 10.5)
	var springs := _group(markers, "Molas")
	for k in 3:
		var sp := VILA + Vector2(cos(TAU * k / 3.0), sin(TAU * k / 3.0)) * 3.0
		_marker(springs, "Mola%d" % (k + 1), sp.x, sp.y)

	# Caixas de munição: voltam um tempo depois de pegas (o jogo cuida disso).
	var crates := _group(markers, "Municao")
	var crate_spots := [
		["Praca", Vector2(-9, 164)], ["CidadeOeste", Vector2(-50, 150)], ["CidadeLeste", Vector2(50, 150)],
		["PeDoMorro", Vector2(-8, 96)], ["TrilhaDoMorro", _spiral_point(0.45) + Vector2(2, 2)],
		["Cemiterio", Vector2(9, -13)], ["EntradaDaMata", Vector2(-6, -134)], ["Clareira", Vector2(50, -178)],
		["VilaDasCopas", Vector2(108, -150)], ["MorroDosVentos", Vector2(-86, -148)],
	]
	for spot in crate_spots:
		_marker(crates, spot[0], spot[1].x, spot[1].y)
	# Uma caixa em cima de uma plataforma da Vila das Copas, para quem subir pelas molas.
	var top_spot := VILA + Vector2(cos(TAU / 3.0), sin(TAU / 3.0)) * 8.0
	var top_crate := _marker(crates, "VilaDasCopasNoAlto", top_spot.x, top_spot.y)
	top_crate.position.y += 5.0

	# Moradores (personagens das Mystery Monthly do KayKit). Metadados: modelo, atividade, variante
	# (textura), item (na mão), falas, destino (quem anda vai e volta) e altura (em cima do palco ou
	# do pódio). A rotação do marcador é para onde ele olha.
	var people := _group(markers, "Moradores")
	var pc := Vector2(PLAZA.position.x + 20, PLAZA.position.y + 20)
	var folks := [
		["Banda1", "ToySoldier", "tocando", "", "moradores/ToySoldier_Trumpet", pc + Vector2(-1.5, -11.6), 0.0, 1.0,
			["Tan-tan-taraaa! A banda está ensaiando para a festa!", "Amanhã a gente toca a noite inteira!"]],
		["Banda2", "ToySoldier", "tocando", "", "moradores/ToySoldier_Trumpet", pc + Vector2(1.5, -11.6), 0.0, 1.0,
			["Psiu! Os esqueletos saem daquelas rachaduras roxas."]],
		["Fazendeiro", "Farmer_A", "trabalhando", "", "", pc + Vector2(-17.0, 9.0), 90.0, 0.0,
			["Cenoura fresquinha para a festa!", "Caixa de munição pisca perto das casas. Pega que ajuda!"]],
		["Fazendeira", "Farmer_B", "parado", "", "", pc + Vector2(-15.4, 6.0), 100.0, 0.0,
			["Meu carrinho está cheio de verdura!", "Será que os esqueletos gostam de sopa de abóbora?"]],
		["Palhaco", "Clown", "parado", "", "festa/circo/balloon_dog_red", pc + Vector2(15.0, 8.0), -120.0, 0.8,
			["Respeitável público! Quer um cachorrinho de balão?", "Acerte a cabeça: vale o dobro!"]],
		["Dino1", "MonsterCostume", "sentado_chao", "", "", pc + Vector2(12.0, 10.9), 70.0, 0.0,
			["Eu sou um dinossauro! Rawr!", "O palhaço é muito engraçado!"]],
		["Dino2", "MonsterCostume", "sentado_chao", "monstercostume_texture_C", "", pc + Vector2(11.2, 8.4), 95.0, 0.0,
			["Shhh, o show vai começar!"]],
		["Magica1", "MagicalGirl", "sentado_chao", "magical_girl_texture_B", "", pc + Vector2(13.0, 12.6), 40.0, 0.0,
			["Minha varinha brilha! Mas não assusta esqueleto."]],
		["Dino3", "MonsterCostume", "torcendo", "monstercostume_texture_B", "", pc + Vector2(-3.0, -7.4), 180.0, 0.0,
			["Vai ter bolo na festa?", "Eu vou dançar a noite inteira!"]],
		["Magica2", "MagicalGirl", "torcendo", "magical_girl_texture_C", "", pc + Vector2(3.0, -7.4), 180.0, 0.0,
			["Que banda boa!", "Amanhã é a Festa do Cafuné!"]],
		["Vovo", "Lorekeeper", "sentado_banco", "", "moradores/Lorekeeper_Staff", pc + Vector2(-4.95, 4.95), 45.0, 0.0,
			["Quando eu era pequeno, os esqueletos também espiavam a festa lá do Morro.",
			"Apague as quatro lanternas e a cúpula do cemitério cai.", "Será que alguém já convidou os esqueletos?"]],
		["Magica3", "MagicalGirl", "sentado_banco", "magical_girl_texture_D", "moradores/MagicalGirl_Wand", pc + Vector2(4.95, 4.95), -45.0, 0.0,
			["O vovô conta cada história do Morro..."]],
		["Motorista1", "Driver", "andando", "", "", Vector2(-48.0, 146.0), 90.0, 0.0,
			["Que movimento! É a véspera da festa.", "A ponte para a mata só abre quando as lanternas da cidade apagam."]],
		["Motorista2", "Driver", "andando", "driver_texture_B", "", Vector2(26.0, 146.0), 90.0, 0.0,
			["Cuidado na rua! E com os esqueletos também."]],
		["Trilheiro", "Hiker", "parado", "", "", Vector2(-2.0, 100.0), 0.0, 0.0,
			["A trilha sobe em espiral até o cemitério dos esqueletos.", "Lá no Morro dos Ventos venta tanto que o boné voa!"]],
	]
	# Na festa: o urso da banda, a bruxa das poções e gente fantasiada. Fora dela: o lenhador na margem do
	# rio e o pescador no fim do cais (altura do píer, não do fundo do mar).
	var pier_z := 247.0
	var pier_y := lerpf(ground(0, 206) + 0.02, 0.25, (pier_z - 206.0) / 46.0)
	var river_s := _river_z(12.0) + RIVER_HALF + RIVER_BANK + 6.0
	folks.append_array([
		["Urso", "Animatronic_Normal", "tocando", "", "moradores/urso/Guitar", pc + Vector2(0.0, -12.4), 0.0, 1.0,
			["Eu toco violão na banda! Amanhã tem show!", "Cada esqueleto que vai de balão é uma nota a menos... ops, a mais!"]],
		["Bruxa", "Witch", "trabalhando", "", "", pc + Vector2(-17.0, -8.2), 90.0, 0.0,
			["Poção de groselha! Deixa a língua azul!", "Não tenho poção contra esqueleto... só de cócegas."]],
		["SuperHeroi", "Superhero", "torcendo", "", "", pc + Vector2(-1.2, 9.8), -110.0, 0.0,
			["Minha fantasia é de super-herói! Acerta o alvo pra mim?", "Na cabeça do boneco vale o dobro!"]],
		["Astronauta", "SpaceRanger", "parado", "", "", pc + Vector2(11.4, -10.6), -90.0, 0.0,
			["Esse trenzinho vai até a lua!", "Fantasia de astronauta, nota dez!"]],
		["HomemDasCavernas", "Caveman", "parado", "", "", pc + Vector2(-9.3, 1.2), -90.0, 0.0,
			["Uga! Pizza boa!", "Fantasia de homem das cavernas. A barba é de verdade."]],
		["Lenhador", "Werewolf_Man", "cortando", "", "moradores/lenhador/axe", Vector2(12.0, river_s), -90.0, 0.0,
			["Lenha para a fogueira da festa!", "Do outro lado da ponte a mata está cheia de esqueletos. Cuidado!"]],
		["Pescador", "Hiker", "pescando", "hiker_texture_b", "pesca/fishing_rod", Vector2(2.3, pier_z), 90.0, pier_y - ground(2.3, pier_z) - 0.1,
			["Psiu! Os peixes estão quase mordendo.", "Hoje só pesquei uma bota... e um balão!"]],
	])
	var walk_to := {"Motorista1": Vector2(-26.0, 146.0), "Motorista2": Vector2(48.0, 146.0)}
	for f in folks:
		var p: Vector2 = f[5]
		var meta := {"modelo": f[1], "atividade": f[2], "variante": f[3], "item": f[4], "altura": f[7],
			"falas": PackedStringArray(f[8])}
		if walk_to.has(f[0]):
			var w: Vector2 = walk_to[f[0]]
			meta["destino"] = Vector3(w.x, ground(w.x, w.y), w.y)
		var m := _marker(people, f[0], p.x, p.y, meta)
		m.rotation_degrees.y = f[6]

	# Lanternas mágicas: poste, esfera e raio até a lanterna em cima da cripta do cemitério.
	var lanterns := _group(markers, "Lanternas")
	var visuals := _group(ilha, "LanternasVisuais")
	var source := Vector3(0, MORRO_H + 13.0, -17.5)
	for spec in [["Oeste", REGIONS.oeste], ["Leste", REGIONS.leste], ["Ventos", REGIONS.ventos], ["Clareira", REGIONS.clareira]]:
		var m := _marker(lanterns, "Lanterna" + spec[0], spec[1].x, spec[1].y)
		var base := m.position
		_prop(visuals, PLAT % "neutral/pillar_1x1x4", base, 0.0, 1.0, "caixa")
		var orb_pos := base + Vector3(0, 4.8, 0)
		_orb(visuals, "Esfera" + spec[0], orb_pos, 0.7)
		var beam := MeshInstance3D.new()
		beam.name = "Raio" + spec[0]
		var cyl := CylinderMesh.new()
		var length := source.distance_to(orb_pos)
		cyl.top_radius = 0.18
		cyl.bottom_radius = 0.18
		cyl.height = length
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.72, 0.45, 1.0, 0.55)
		cyl.material = mat
		beam.mesh = cyl
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var dir := (orb_pos - source).normalized()
		beam.transform = Transform3D(Basis(Quaternion(Vector3.UP, dir)), (source + orb_pos) * 0.5)
		_add(visuals, beam)
