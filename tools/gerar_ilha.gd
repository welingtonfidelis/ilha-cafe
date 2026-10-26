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
const MORRO_TOP_R := 13.0
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
const CASTLE_DOME_R := 11.5

const CITY := "res://assets/env/city/%s.gltf"
const FOREST := "res://assets/env/forest/%s.gltf"
const PLAT := "res://assets/props/platformer/%s.gltf"
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
var _cols := 0
var _rows := 0
var _hs := PackedFloat32Array()


func _init() -> void:
	rng.seed = 2026
	ilha = Node3D.new()
	ilha.name = "Ilha"
	_terrain()
	_sea()
	_city()
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
	# Morro no centro, com topo plano para o castelinho.
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
	if p.length() < MORRO_R and (_spiral_dist(x, z) < PATH_HALF or p.length() < MORRO_TOP_R + 1.0):
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
		_prop(props, CITY % item, Vector3(x, 0, z - 7.5), rng.randf_range(0, 360), CITY_SCALE, "caixa")
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
		_prop(plaza, FOREST % "Tree_2_A_Color1", center + corner, rng.randf_range(0, 360), 1.3, "tronco")


# --- Morro -------------------------------------------------------------------

func _morro() -> void:
	var morro := _group(ilha, "Morro")
	var top := MORRO_H
	# Castelinho dos esqueletos no topo: quatro torres, muros e um portão virado para o sul.
	var castle := _group(morro, "Castelinho")
	for cx in [-7.0, 7.0]:
		for cz in [-7.0, 7.0]:
			_prop(castle, PLAT % "neutral/pillar_2x2x8", Vector3(cx, top, cz), 0.0, 1.0, "caixa")
			_prop(castle, PLAT % "red/flag_C_red", Vector3(cx, top + 8.0, cz), 90.0, 1.0)
	for k in 3:
		var offset := -4.0 + k * 4.0
		_prop(castle, PLAT % "neutral/barrier_4x1x2", Vector3(offset, top, -7.0), 0.0, 1.0, "caixa")
		_prop(castle, PLAT % "neutral/barrier_4x1x2", Vector3(-7.0, top, offset), 90.0, 1.0, "caixa")
		_prop(castle, PLAT % "neutral/barrier_4x1x2", Vector3(7.0, top, offset), 90.0, 1.0, "caixa")
	for side in [-1.0, 1.0]:
		_prop(castle, PLAT % "neutral/barrier_4x1x2", Vector3(side * 4.5, top, 7.0), 0.0, 1.0, "caixa")
	_prop(castle, PLAT % "red/arch_tall_red", Vector3(0, top, 7.0), 0.0, 1.0)
	_prop(castle, PLAT % "neutral/pillar_1x1x4", Vector3(0, top, 0), 0.0, 1.0, "caixa")
	_orb(castle, "LanternaCentral", Vector3(0, top + 5.0, 0), 0.9)
	# Cúpula mágica: some quando as quatro lanternas apagam (o jogo cuida disso).
	var dome := StaticBody3D.new()
	dome.name = "CupulaDoCastelinho"
	dome.position = Vector3(0, top, 0)
	_add(morro, dome)
	var dome_mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = CASTLE_DOME_R
	sphere.height = CASTLE_DOME_R * 2.0
	sphere.material = _magic_material()
	dome_mi.mesh = sphere
	dome_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(dome, dome_mi)
	var dome_cs := CollisionShape3D.new()
	var dome_shape := SphereShape3D.new()
	dome_shape.radius = CASTLE_DOME_R
	dome_cs.shape = dome_shape
	_add(dome, dome_cs)
	# Placa no começo da subida.
	var sign_pos := _spiral_point(0.0) + Vector2(4, 4)
	_prop(morro, PLAT % "neutral/sign", Vector3(sign_pos.x, ground(sign_pos.x, sign_pos.y), sign_pos.y), 0.0, 1.0, "caixa")
	# Algumas árvores e pedras nas encostas, fora da trilha.
	var trees := ["Tree_1_A_Color1", "Tree_2_B_Color1", "Tree_3_B_Color1", "Tree_4_A_Color1"]
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
		_prop(morro, FOREST % trees[rng.randi() % trees.size()], Vector3(x, ground(x, z) - 0.1, z), rng.randf_range(0, 360), FOREST_SCALE * rng.randf_range(0.8, 1.15), "tronco")
		placed += 1
	for k in 16:
		var a := rng.randf_range(0, TAU)
		var r := rng.randf_range(20, MORRO_R)
		var x := cos(a) * r
		var z := sin(a) * r
		if _spiral_dist(x, z) < PATH_HALF + 2.0 or z > CITY_Z:
			continue
		_prop(morro, FOREST % ("Rock_%d_%s_Color1" % [rng.randi_range(1, 3), "ABCDE"[rng.randi() % 5]]), Vector3(x, ground(x, z) - 0.1, z), rng.randf_range(0, 360), FOREST_SCALE * rng.randf_range(0.8, 1.6), "convexo")


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
	_walkway(ilha, "Ponte", Vector3(0, ground(0, z_south) + 0.02, z_south), Vector3(0, ground(0, z_north) + 0.02, z_north), 6.0)
	# Barreira mágica na cabeceira sul: some quando as duas lanternas da cidade apagam (o jogo cuida disso).
	_magic_wall(ilha, "BarreiraDaPonte", Vector3(0, ground(0, z_south + 1.0) + 2.5, z_south + 1.0), Vector3(9, 5, 0.5))
	# Cais: sai da praça para o mar, ao sul.
	_walkway(ilha, "Cais", Vector3(0, ground(0, 206) + 0.02, 206), Vector3(0, 0.25, 252), 7.0)


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
	var trees := ["Tree_1_A_Color1", "Tree_1_B_Color1", "Tree_2_A_Color1", "Tree_2_C_Color1", "Tree_3_A_Color1", "Tree_4_A_Color1", "Tree_4_B_Color1"]
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
		_prop(forest, FOREST % trees[rng.randi() % trees.size()], Vector3(p.x, ground(p.x, p.y) - 0.1, p.y), rng.randf_range(0, 360), FOREST_SCALE * rng.randf_range(0.85, 1.25), "tronco")
	# Árvores nos arredores da cidade, a leste e a oeste.
	for k in 60:
		var side := -1.0 if k % 2 == 0 else 1.0
		var p := Vector2(side * rng.randf_range(78, 175), rng.randf_range(20, 205))
		if _island_d(p.x, p.y) > 0.84 or _near_region(p):
			continue
		_prop(forest, FOREST % trees[rng.randi() % trees.size()], Vector3(p.x, ground(p.x, p.y) - 0.1, p.y), rng.randf_range(0, 360), FOREST_SCALE * rng.randf_range(0.85, 1.2), "tronco")
	# Jabuticabeira gigante no meio da clareira.
	_prop(forest, FOREST % "Tree_1_A_Color1", Vector3(CLAREIRA.x, ground(CLAREIRA.x, CLAREIRA.y) - 0.2, CLAREIRA.y), 30.0, FOREST_SCALE * 3.2, "tronco")
	# Vila das Copas: plataformas de madeira entre as árvores (chegar lá em cima fica para o pulo duplo).
	for k in 3:
		var a := TAU * k / 3.0
		var p := VILA + Vector2(cos(a), sin(a)) * 8.0
		var y := ground(p.x, p.y)
		_prop(forest, PLAT % "neutral/pillar_1x1x4", Vector3(p.x, y, p.y), 0.0, 1.0, "caixa")
		_prop(forest, PLAT % "red/platform_4x4x1_red", Vector3(p.x, y + 4.0, p.y), rad_to_deg(a), 1.0, "caixa")
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
		if p.length() < MORRO_R and _spiral_dist(p.x, p.y) < PATH_HALF + 1.0:
			continue
		_prop(forest, FOREST % ("Bush_%d_%s_Color1" % [rng.randi_range(1, 4), "ABC"[rng.randi() % 3]]), Vector3(p.x, ground(p.x, p.y) - 0.05, p.y), rng.randf_range(0, 360), FOREST_SCALE * rng.randf_range(0.8, 1.2))


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
	_marker(cps, "TopoDoMorro", 9, 12)
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

	# Caixas de munição: voltam um tempo depois de pegas (o jogo cuida disso).
	var crates := _group(markers, "Municao")
	var crate_spots := [
		["Praca", Vector2(-9, 164)], ["CidadeOeste", Vector2(-50, 150)], ["CidadeLeste", Vector2(50, 150)],
		["PeDoMorro", Vector2(-8, 96)], ["TrilhaDoMorro", _spiral_point(0.45) + Vector2(2, 2)],
		["Castelinho", Vector2(-13, 4)], ["EntradaDaMata", Vector2(-6, -134)], ["Clareira", Vector2(50, -178)],
		["VilaDasCopas", Vector2(108, -150)], ["MorroDosVentos", Vector2(-86, -148)],
	]
	for spot in crate_spots:
		_marker(crates, spot[0], spot[1].x, spot[1].y)

	# Lanternas mágicas: por enquanto só o visual (poste, esfera e raio até o castelinho).
	var lanterns := _group(markers, "Lanternas")
	var visuals := _group(ilha, "LanternasVisuais")
	var source := Vector3(0, MORRO_H + 5.0, 0)
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
