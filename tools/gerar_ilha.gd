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
const VENTOS := Vector2(-80, -162)
const VENTOS_R := 58.0
const VENTOS_H := 8.0
## Topo plano do Morro dos Ventos: a arena (22 m) inteira fica no plano, e a encosta é suave.
const VENTOS_TOP_R := 29.0
const CLAREIRA := Vector2(40, -180)
const VILA := Vector2(115, -160)
## Pasto dos cavalos, a oeste da cidade.
## Atividades extras (pedido do usuário em 2026-10-26, pacotes do Kenney, CC0): pista de kart na campina a
## leste do Morro (a pista de skate saiu em 2026-10-29). As áreas ficam sem árvores, pedras, arbustos e grama. A pista de kart foi refeita em 2026-10-29: um 8 com ponte, montado
## aqui por código a partir do traçado de scripts/kart_circuit.gd (antes era um oval de peças do City Kit Roads).
## Vagas do box (o jogo põe os veículos nelas).
const KART_SPOTS := 5
## Box: metros para o lado de fora da reta da largada, a partir da abertura da mureta. O chão dele é aplainado
## (KART_PAD_R) para os karts, os pneus e a caixa ficarem retos no pé do Morro.
const KART_PADDOCK_OUT := 16.0
const KART_PAD_R := 15.0
## Rampa da abertura da mureta: do asfalto até o chão, para o kart subir na pista vindo do box.
const KART_RAMP := 4.0
const KART_BARRIER_H := 0.9
const KART_BARRIER_W := 0.35
## Espessura da ponte (o vão do cruzamento).
const KART_DECK := 0.7
## Onde ficava a pista de skate, perto da cidade (a noroeste). Ela saiu em 2026-10-29 (pedido do usuário: "remove
## a pista de skate e o skate"), mas a campina continua limpa: assim o sorteio do resto da ilha não muda.
const SKATE := Vector2(-98, 66)
const SKATE_TILE := 5.0
const SKATE_N := 8
const PISTA := "res://assets/pista/%s.glb"
const CARROS := "res://assets/carros/%s.glb"
const PASTURE := Vector2(-120, -6)
const PASTURE_R := 11.0
const SPIRAL_TURNS := 2.5
const SPIRAL_R0 := 86.0
const SPIRAL_R1 := 15.0
const PATH_HALF := 3.2
## Regiões de defesa (centro da arena em x, z). Nas quatro de fora da praça a lanterna fica no centro.
const REGIONS := {
	"praca": Vector2(-30, 212),  # a luta do prólogo é na praia ao lado do cais (o jogo começa na praça)
	"oeste": Vector2(-84, 140),
	"leste": Vector2(84, 140),
	"clareira": Vector2(24, -166),
	"ventos": Vector2(-80, -162),
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
const CAIS := "res://assets/props/cais/%s.gltf"
## Construções do sítio (Medieval Hexagon): estábulo, moinho, poço, bebedouros e feno.
const SITIO := "res://assets/props/sitio/%s.gltf"
## Cais de madeira do Animated Cute Fish Pack (Quaternius): módulos com estacas e corda de corrimão.
const DOCKS := "res://assets/props/cais_peixes/%s.fbx"
const DOCK_SCALE := 0.75
## Altura do piso do módulo (medida na malha): 3,8 m acima do pé das estacas, no tamanho do pacote.
const DOCK_DECK := 3.8
const PIER_DECK_Y := 0.45
## A cerca de madeira do Medieval Hexagon é a borda de um hexágono: a madeira fica 1 m para -X da origem.
const FENCE_OFFSET := 1.0
## Árvores e arbustos nas outras cores do Forest Nature Pack completo (a cor 1 fica em env/forest/).
const FOREST_COLOR := "res://assets/env/forest/cor%d/%s_Color%d.gltf"
## Formatos de árvore da mata (os 5, 6 e 7 só existem no pacote completo).
const TREE_SHAPES := ["Tree_1_A", "Tree_1_B", "Tree_2_A", "Tree_2_C", "Tree_3_A", "Tree_4_A", "Tree_4_B",
	"Tree_5_A", "Tree_5_B", "Tree_5_C", "Tree_6_A", "Tree_6_B", "Tree_7_A", "Tree_7_B"]
const MORADOR_ITEM := "res://assets/props/%s.gltf"
const CITY_SCALE := 5.0
## Topo das ruas (a peça fica em y = 0,01 e tem 0,1 de altura).
const ROAD_TOP := 0.03
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
## Ponta do cais (centro da beira do mar, no nível do piso) e meia largura do módulo da ponta.
var pier_end := Vector3.ZERO
var pier_end_half_w := 4.0
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
	_kart_mask()
	_clear_activity_areas()
	_kart_circuit()
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
		var tv := clampf((rv - VENTOS_TOP_R) / (VENTOS_R - VENTOS_TOP_R), 0.0, 1.0)
		land = maxf(land, VENTOS_H * (0.5 + 0.5 * cos(PI * tv)))
	# Box da pista de kart: chão plano (no pé do Morro ele já começava a subir).
	var dp := Vector2(x, z).distance_to(_kart_pad2d())
	if dp < KART_PAD_R + 10.0:
		land = lerpf(land, 0.0, 1.0 - smoothstep(KART_PAD_R, KART_PAD_R + 10.0, dp))
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
	# A cidade fica plana até a beira, mesmo onde a costa chega perto (canto sudeste).
	var cx := maxf(absf(x) - 70.0, 0.0)
	var cz := maxf(maxf(100.0 - z, z - 197.0), 0.0)
	return lerpf(land, 0.0, 1.0 - smoothstep(0.0, 10.0, Vector2(cx, cz).length())) if z > CITY_Z - 10.0 else land


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


## Em cima de uma rua (as peças têm 10 x 10 m centradas nas linhas ROAD_XS e ROAD_ZS)?
func _on_road(x: float, z: float, margin := 0.0) -> bool:
	if x < ROAD_XS[0] - 5.0 - margin or x > ROAD_XS[-1] + 5.0 + margin or z < ROAD_ZS[0] - 5.0 - margin or z > ROAD_ZS[-1] + 5.0 + margin:
		return false
	for rx in ROAD_XS:
		if absf(x - rx) < 5.0 + margin:
			return true
	for rz in ROAD_ZS:
		if absf(z - rz) < 5.0 + margin:
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
		"malha":
			# Colisão no formato exato do modelo (rampas, curvas com mureta).
			var faces := PackedVector3Array()
			for m in inst.find_children("*", "MeshInstance3D", true, false):
				var xf := _rel_xform(m, inst)
				for v in (m as MeshInstance3D).mesh.get_faces():
					faces.append(xf * v)
			var shape := ConcavePolygonShape3D.new()
			shape.set_faces(faces)
			shape.backface_collision = true
			cs.shape = shape
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
		# Achatada (5 x 1 x 5) e um pouco afundada: o asfalto do modelo fica a 7 cm e a calçada a 10 cm;
		# assim o asfalto fica a 2,5 cm do chão em que o personagem pisa.
		var road := _prop(roads, CITY % piece[0], Vector3(key.x, -0.045, key.y), piece[1], 1.0)
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
					if cx == 1:
						# Viela de 10 m de norte a sul até o jardinzinho (pedido do usuário em 2026-10-29, "andar entre
						# os prédios"): sem o prédio do meio dos lados das ruas. O sorteio do modelo continua, para
						# não mudar o resto da ilha.
						rng.randi()
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
		if PLAZA.grow(-5.0).has_point(Vector2(x, z - 7.5)) or _on_road(x, z - 7.5, 1.0):
			continue
		_prop(props, CITY % item, Vector3(x, 0, z - 7.5), item_rot, CITY_SCALE, "caixa")
	_prop(props, CITY % "watertower", Vector3(-85, ground(-85, 200), 200), 0.0, CITY_SCALE, "caixa")

	# Praça da festa: palco, arco, balões e bancos. Aqui o jogo começa.
	var plaza := _group(city, "Praca")
	var center := Vector3(PLAZA.position.x + 20, 0, PLAZA.position.y + 20)
	_prop(plaza, PLAT % "red/platform_4x4x1_red", center + Vector3(-2, 0, -12), 0.0, 1.0, "caixa")
	_prop(plaza, PLAT % "blue/platform_4x4x1_blue", center + Vector3(2, 0, -12), 0.0, 1.0, "caixa")
	_prop(plaza, PLAT % "yellow/arch_wide_yellow", center + Vector3(0, 1, -13.6), 0.0, 1.0, "malha")
	var balls := ["red/ball_red", "blue/ball_blue", "yellow/ball_yellow", "green/ball_green"]
	for k in 8:
		var a := TAU * k / 8.0
		var p := center + Vector3(cos(a) * 13.0, 0, sin(a) * 13.0)
		_prop(plaza, PLAT % "neutral/pillar_1x1x4", p, 0.0, 0.6, "caixa")
		# A bola em cima também é sólida: o Faísca pula e flutua até essa altura.
		_prop(plaza, PLAT % balls[k % balls.size()], p + Vector3(0, 3.4, 0), 0.0, 0.6, "caixa")
	for k in 4:
		var a := TAU * k / 4.0 + PI / 4.0
		_prop(plaza, CITY % "bench", center + Vector3(cos(a) * 7.0, 0, sin(a) * 7.0), rad_to_deg(-a), CITY_SCALE, "caixa")
	for corner in [Vector3(-13.2, 0, -13.2), Vector3(13.2, 0, -13.2), Vector3(-13.2, 0, 13.2), Vector3(13.2, 0, 13.2)]:
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
		_prop(festa, FESTA % spec[0], at.call(spec[1], spec[2]), spec[3], 1.5, "caixa")
	_prop(festa, FESTA % "doces/present_A_yellow", at.call(-6.5, -12.7) + Vector3.UP * 0.99, 15.0, 1.3, "caixa")
	var train := ["doces/train_locomotive", "doces/train_tender_presents_A", "doces/train_wagon", "doces/train_tender_presents_B"]
	for k in train.size():
		_prop(festa, FESTA % train[k], at.call(5.2 + k * 1.5, -12.6), 90.0, 1.8, "caixa")
	# Lanternas enfeitadas nos cantos do palco e na entrada da praça.
	for spot in [Vector2(-4.8, -9.4), Vector2(4.8, -9.4), Vector2(-3.5, 13.6), Vector2(3.5, 13.6)]:
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
	_prop(festa, FESTA % "comida/icecream_machine", at.call(12.6, -6.8), -60.0, 0.6, "caixa")
	# Barraca dos fazendeiros (sudoeste): bancada com verduras, caixotes e o carrinho de mão.
	_table(festa, "comida/kitchentable_A_large", at.call(-12.6, 9.4), [
		["moradores/carrot", Vector3(-0.4, 0, -0.5), 1.4], ["moradores/lettuce", Vector3(0.3, 0, -0.2), 1.4],
		["moradores/carrot", Vector3(0.1, 0, 0.5), 1.4]], 90.0, 0.8, MORADOR_ITEM)
	for spec in [["comida/crate_carrots", -10.6, 8.0], ["comida/crate_lettuce", -10.6, 9.4], ["comida/crate_tomatoes", -10.6, 10.8]]:
		_prop(festa, FESTA % spec[0], at.call(spec[1], spec[2]), 90.0, 0.45, "caixa")
	_prop(festa, MORADOR_ITEM % "moradores/wheelbarrow", at.call(-12.8, 13.0), 20.0, 0.9, "caixa")
	# Barraca de poções da bruxa (noroeste): bancada de poções, caldeirão e cesto de cogumelos.
	_prop(festa, EXTRAS % "moradores/bruxa/Potionstation_decorated", at.call(-12.8, -8.4), 90.0, 1.0, "caixa")
	_prop(festa, EXTRAS % "moradores/bruxa/Cauldron", at.call(-10.4, -6.2), 0.0, 1.2, "caixa")
	_prop(festa, EXTRAS % "moradores/bruxa/Basket_Mushrooms", at.call(-11.0, -10.6), 30.0, 1.2)
	_prop(festa, EXTRAS % "moradores/bruxa/Broom", at.call(-13.6, -10.9), 15.0, 1.1)
	# Cantinho do palhaço (sudeste): pódio, arco e brinquedos no chão.
	_prop(festa, FESTA % "circo/circus_podium", at.call(12.4, 7.0), 0.0, 0.8, "caixa")
	_prop(festa, FESTA % "circo/circus_hoop", at.call(13.4, 10.6), -30.0, 0.8, "malha")
	for spec in [["circo/juggling_pin_red", 11.0, 9.0], ["circo/juggling_pin_blue", 11.3, 9.3], ["circo/juggling_pin_yellow", 10.8, 9.5]]:
		_prop(festa, FESTA % spec[0], at.call(spec[1], spec[2]), 40.0, 1.3)
	_prop(festa, FESTA % "circo/clown_ball", at.call(10.6, 5.2), 0.0, 1.0)


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
	# O arch_gate já vem com as duas folhas do portão (arch_gate_left e arch_gate_right, com a origem na
	# dobradiça). Fechado até a cúpula cair; o jogo gira as folhas e desliga esta colisão.
	var gate_block := StaticBody3D.new()
	gate_block.name = "PortaoDoCemiterio"
	gate_block.position = at.call(g.x, g.y)
	gate_block.rotation_degrees.y = _tangent_deg(gate_a)
	_add(cem, gate_block)
	var gate_cs := CollisionShape3D.new()
	var gate_box := BoxShape3D.new()
	gate_box.size = Vector3(3.9, 3.9, 0.4)
	gate_cs.shape = gate_box
	gate_cs.position = Vector3(0, 1.95, 0)
	_add(gate_block, gate_cs)
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
	# Cais: sai da praça para o mar, ao sul.
	_dock_pier(206.0)
	# Pescador na ponta (o pescador é um morador; o jogo cria): caixa de pesca e balde do lado.
	var fish_spot := pier_end + Vector3(pier_end_half_w - 0.9, 0, -4.0)
	_prop(ilha, EXTRAS % "pesca/fishing_tacklebox", fish_spot + Vector3(-1.1, 0, -0.8), 15.0, 1.1)
	_prop(ilha, EXTRAS % "pesca/bucket_metal", fish_spot + Vector3(-1.0, 0, 0.9), 0.0, 1.0)
	# Toras do lenhador na margem sul do rio, perto da ponte.
	var river_s := _river_z(12.0) + RIVER_HALF + RIVER_BANK + 6.0
	var logs := _group(ilha, "Lenha")
	for spec in [["log_stacks", 14.6, 2.4, 20.0], ["log_stacks", 9.2, 2.6, -15.0], ["log_split", 13.6, -2.2, 60.0]]:
		_prop(logs, EXTRAS % ("moradores/lenhador/" + spec[0]), Vector3(spec[1], ground(spec[1], river_s + spec[2]), river_s + spec[2]), spec[3], 1.3, "caixa")
	# Tronco caído na frente dele (o golpe do KayKit é de cima para baixo, na altura de um tronco deitado),
	# o toco da árvore cortada e um pinheiro ainda de pé ao lado.
	var trunk_x := 12.0 - 0.95
	var trunk := _prop(logs, EXTRAS % "moradores/lenhador/log_A", Vector3(trunk_x, ground(trunk_x, river_s) + 0.17, river_s), 0.0, 1.0, "caixa")
	trunk.rotation_degrees = Vector3(90, 0, 0)
	trunk.scale = Vector3(0.8, 3.0, 0.8)
	var stump := _prop(logs, EXTRAS % "moradores/lenhador/log_B", Vector3(trunk_x - 0.4, ground(trunk_x, river_s - 2.6) + 0.2, river_s - 2.6), 30.0, 1.0, "caixa")
	stump.scale = Vector3(1.4, 0.4, 1.4)
	_prop(logs, _tree_path("Tree_5_B", 1), Vector3(trunk_x - 2.6, ground(trunk_x - 2.6, river_s - 3.4) - 0.1, river_s - 3.4), 40.0, FOREST_SCALE, "tronco")


## Sítio do Cafuné: pasto com cerca de madeira (Medieval Hexagon), estábulo, moinho, poço, bebedouros e feno;
## os bichos vêm dos marcadores Animais e o casal de fazendeiros, dos Moradores.
func _pasture() -> void:
	var pasture := _group(ilha, "Pasto")
	var segs := 14
	for k in segs:
		var a := TAU * k / segs
		if k == 3:
			continue  # porteira aberta
		var p := PASTURE + Vector2(cos(a), sin(a)) * PASTURE_R
		# A cerca com colisão (pedido do usuário em 2026-10-29: "o jogador atravessa como se não tivesse cerca"):
		# o corpo fica sem escala e a caixa acompanha a madeira esticada.
		var body := StaticBody3D.new()
		body.name = "Cerca"
		body.position = Vector3(p.x, ground(p.x, p.y), p.y) + Basis(Vector3.UP, -a) * Vector3(FENCE_OFFSET * 3.0, 0, 0)
		body.rotation.y = -a
		_add(pasture, body)
		var rail: Node3D = load(CAIS % "fence_wood_straight").instantiate()
		rail.scale = Vector3(3.0, 2.0, 4.3)
		_add(body, rail)
		var caixa := _model_aabb(rail)
		var cs := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = (caixa.size * rail.scale).max(Vector3(0.5, 0.5, 0.5))
		cs.shape = forma
		cs.position = caixa.get_center() * rail.scale
		_add(body, cs)
	# Sítio: estábulo de frente para o pasto, moinho, poço, bebedouro e feno (Medieval Hexagon).
	var farm := func(model: String, offset: Vector2, rot: float, s: float, collider := "caixa") -> void:
		var fp := PASTURE + offset
		_prop(pasture, SITIO % model, Vector3(fp.x, ground(fp.x, fp.y), fp.y), rot, s, collider)
	farm.call("building_stables_red", Vector2(0, -18.5), 0.0, 7.0)
	farm.call("building_windmill_red", Vector2(-19, -12), 35.0, 7.0)
	farm.call("building_well_red", Vector2(16.5, 10.0), -30.0, 4.0)
	farm.call("trough_long", Vector2(4.0, -6.0), 90.0, 7.0)
	farm.call("trough", Vector2(-5.5, 4.5), 0.0, 8.0)
	farm.call("haybale", Vector2(9.5, -15.5), 70.0, 6.0)
	farm.call("haybale", Vector2(11.0, -13.6), 20.0, 6.0)
	farm.call("haybale", Vector2(-8.5, -16.0), -10.0, 6.0)
	_prop(pasture, FESTA % "comida/crate_lettuce", Vector3(PASTURE.x, ground(PASTURE.x, PASTURE.y), PASTURE.y), 20.0, 0.5, "caixa")


## Cais do Animated Cute Fish Pack: dois módulos compridos e o largo na ponta, um atrás do outro a partir
## da praia (z0) para o mar. As estacas descem para dentro da água; o piso fica a PIER_DECK_Y. A colisão é
## uma caixa no piso de cada módulo, paredes invisíveis no lugar da corda e uma rampa na areia.
func _dock_pier(z0: float) -> void:
	var group := _group(ilha, "Cais")
	var z := z0
	var origin_y := PIER_DECK_Y - DOCK_DECK * DOCK_SCALE
	var body := StaticBody3D.new()
	body.name = "Piso"
	_add(group, body)
	var modules := ["Dock_Long", "Dock_Long", "Dock_Wide"]
	for i in modules.size():
		var dock: Node3D = load(DOCKS % modules[i]).instantiate()
		var aabb := _model_aabb(dock)
		var length := aabb.size.z * DOCK_SCALE
		var half_w := aabb.size.x * DOCK_SCALE * 0.5 * 0.86
		dock.position = Vector3(0, origin_y, z - aabb.position.z * DOCK_SCALE)
		dock.scale = Vector3.ONE * DOCK_SCALE
		dock.name = "Modulo%d" % (i + 1)
		_add(group, dock)
		var mid := z + length * 0.5
		_box_shape(body, Vector3(half_w * 2.0, 0.3, length), Vector3(0, PIER_DECK_Y - 0.15, mid))
		for side in [-1.0, 1.0]:
			_box_shape(body, Vector3(0.3, 1.2, length), Vector3(side * half_w, PIER_DECK_Y + 0.6, mid))
		if i == modules.size() - 1:
			_box_shape(body, Vector3(half_w * 2.0, 1.2, 0.3), Vector3(0, PIER_DECK_Y + 0.6, z + length - 0.4))
			pier_end = Vector3(0, PIER_DECK_Y, z + length)
			pier_end_half_w = half_w
		z += length - 0.15
	_ramp(group, Vector3(0, ground(0, z0 - 3.5), z0 - 3.5), Vector3(0, PIER_DECK_Y, z0 + 0.5), 5.0)


func _box_shape(body: StaticBody3D, size: Vector3, pos: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	cs.position = pos
	_add(body, cs)


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
		var city_tree := _tree_path(trees[rng.randi() % trees.size()], city_color)
		var city_rot := rng.randf_range(0, 360)
		var city_scale := FOREST_SCALE * rng.randf_range(0.85, 1.2)
		if p.distance_to(PASTURE) < PASTURE_R + 17.0:
			continue
		_prop(forest, city_tree, Vector3(p.x, ground(p.x, p.y) - 0.1, p.y), city_rot, city_scale, "tronco")
	# Jabuticabeira gigante no meio da clareira.
	_prop(forest, FOREST % "Tree_1_A_Color1", Vector3(CLAREIRA.x, ground(CLAREIRA.x, CLAREIRA.y) - 0.2, CLAREIRA.y), 30.0, FOREST_SCALE * 3.2, "tronco")
	# Bosque das Copas: clareira redonda fechada por árvores gigantes, com pedras com musgo, arbustos floridos
	# e um tronco caído. É a arena do desafio do Guerreiro Planta (o guardião da mata).
	var bosque := _group(forest, "BosqueDasCopas")
	for k in 9:
		var a := TAU * k / 9.0 + 0.2
		var p := VILA + Vector2(cos(a), sin(a)) * (15.5 + (k % 2) * 1.5)
		var giant: String = ["Tree_1_A", "Tree_7_B", "Tree_2_A", "Tree_6_B"][k % 4]
		_prop(bosque, _tree_path(giant, [3, 2, 1, 8][k % 4]), Vector3(p.x, ground(p.x, p.y) - 0.2, p.y), 40.0 * k, FOREST_SCALE * 2.2, "tronco")
	for k in 7:
		var a := TAU * k / 7.0 + 0.6
		var p := VILA + Vector2(cos(a), sin(a)) * 12.8
		_prop(bosque, _tree_path("Bush_%d_A" % (k % 4 + 1), [8, 3, 2][k % 3]), Vector3(p.x, ground(p.x, p.y) - 0.05, p.y), 50.0 * k, FOREST_SCALE * 1.3)
	for spec in [[2.1, 13.2, "Rock_1_C"], [4.0, 13.6, "Rock_2_B"], [5.6, 12.6, "Rock_3_D"]]:
		var p: Vector2 = VILA + Vector2(cos(spec[0]), sin(spec[0])) * spec[1]
		_prop(bosque, FOREST % (spec[2] + "_Color1"), Vector3(p.x, ground(p.x, p.y) - 0.1, p.y), 30.0, FOREST_SCALE * 1.3, "convexo")
	var log_p := VILA + Vector2(-9.5, 4.0)
	var fallen := _prop(bosque, EXTRAS % "moradores/lenhador/log_A", Vector3(log_p.x, ground(log_p.x, log_p.y) + 0.5, log_p.y), 0.0, 1.0, "caixa")
	fallen.rotation_degrees = Vector3(90, 35, 0)
	fallen.scale = Vector3(2.2, 5.0, 2.2)
	# Pedras e arbustos.
	for k in 70:
		var p := Vector2(rng.randf_range(-185, 185), rng.randf_range(-240, 200))
		if _island_d(p.x, p.y) > 0.84 or _in_city(p.x, p.y) or _trail_dist(p) < 4.0 or p.length() < MORRO_R or _near_region(p):
			continue
		if absf(p.y - _river_z(p.x)) < RIVER_HALF + RIVER_BANK + 2.0 or p.distance_to(PASTURE) < PASTURE_R + 17.0:
			continue
		_prop(forest, FOREST % ("Rock_%d_%s_Color1" % [rng.randi_range(1, 3), "ABCDEFG"[rng.randi() % 7]]), Vector3(p.x, ground(p.x, p.y) - 0.1, p.y), rng.randf_range(0, 360), FOREST_SCALE * rng.randf_range(0.7, 1.5), "convexo")
	for k in 160:
		var p := Vector2(rng.randf_range(-185, 185), rng.randf_range(-240, 200))
		if _island_d(p.x, p.y) > 0.85 or _in_city(p.x, p.y) or _trail_dist(p) < 3.0 or ground(p.x, p.y) < SEA_LEVEL + 0.5 or _near_region(p, -6.0):
			continue
		if p.distance_to(PASTURE) < PASTURE_R + 17.0:
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


# --- pista de kart e pista de skate -------------------------------------------

## Pista de kart (com uma folga para os lados) e o box: grade de 4 m marcada uma vez (a conta da distância até a
## pista é cara para cada tufo de grama e cada árvore).
var _kart_cells := {}


func _kart_mask() -> void:
	for cx in range(15, 45):
		for cz in range(-26, 26):
			var c := Vector3(cx * 4.0 + 2.0, 0, cz * 4.0 + 2.0)
			if KartCircuit.on_track(c, 7.0) or c.distance_to(_kart_paddock()) < 16.0:
				_kart_cells[Vector2i(cx, cz)] = true


func _skate_rect() -> Rect2:
	var skate_size := Vector2.ONE * SKATE_N * SKATE_TILE
	return Rect2(SKATE - skate_size * 0.5 - Vector2(4, 4), skate_size + Vector2(8, 12))


func _in_activity(p: Vector2) -> bool:
	return _kart_cells.has(Vector2i(floori(p.x / 4.0), floori(p.y / 4.0))) or _skate_rect().has_point(p)


## Tira árvores, pedras e arbustos de dentro das áreas (depois do sorteio: não muda o resto da ilha).
func _clear_activity_areas() -> void:
	var forest := _find_group("Mata")
	for child in forest.get_children():
		var n := child as Node3D
		if n and _in_activity(Vector2(n.position.x, n.position.z)):
			forest.remove_child(n)
			n.free()


## Pista de kart em 8 (refeita em 2026-10-29, pedido do usuário; o traçado e as contas ficam em
## scripts/kart_circuit.gd). Uma malha só, com cores por vértice:
## - asfalto de 13 m, zebras vermelhas e brancas nas beiradas, faixa tracejada no meio e faixa quadriculada na
##   largada;
## - muretas vermelhas e brancas dos dois lados. Só a de fora da reta da largada tem uma abertura: a entrada
##   que vem do box.
## O asfalto nunca fica abaixo do chão. Onde ele sobe (a rampa, a ponte e a lombada), as paredes descem até o
## chão. No cruzamento, a pista de cima vira ponte, sem parede embaixo, para a de baixo passar. A colisão é a
## mesma malha (asfalto, muretas e paredes), salva em assets/terrain/ junto com o terreno.
var _kart_heights := PackedFloat32Array()


func _kart_circuit() -> void:
	var group := _group(ilha, "PistaDeKart")
	var sm: Array = KartCircuit.samples()
	var n := sm.size()
	var half := KartCircuit.WIDTH * 0.5
	var outer := half + KART_BARRIER_W
	# Altura do asfalto: a de projeto, nunca a menos de 12 cm do chão embaixo dele (o terreno tem grade de 4 m),
	# suavizada para não dar degrau.
	var floor_h := PackedFloat32Array()
	var hs := PackedFloat32Array()
	for i in n:
		var c: Vector3 = sm[i].pos
		var left := _kart_left(sm[i])
		var top := -INF
		for o in [-outer - 1.0, -half * 0.5, 0.0, half * 0.5, outer + 1.0]:
			var q: Vector3 = c + left * o
			top = maxf(top, ground(q.x, q.z))
		floor_h.append(top + 0.12)
		hs.append(maxf(c.y, top + 0.12))
	for _k in 3:
		var smooth := hs.duplicate()
		for i in n:
			var acc := 0.0
			for d in range(-5, 6):
				acc += hs[(i + d + n) % n]
			smooth[i] = maxf(acc / 11.0, floor_h[i])
		hs = smooth
	_kart_heights = hs
	# Vão da ponte: os pedaços com outra parte da pista passando por baixo.
	var span: Array[bool] = []
	for i in n:
		var over := false
		var pi: Vector3 = sm[i].pos
		for j in n:
			var gap := absi(i - j)
			if mini(gap, n - gap) < 40:
				continue
			var pj: Vector3 = sm[j].pos
			if Vector2(pi.x - pj.x, pi.z - pj.z).length() < outer + 3.0 and hs[j] < hs[i] - 2.0:
				over = true
				break
		span.append(over)
	var start_i: int = sm.find(KartCircuit.from_start(0.0))
	var pad_side := _kart_paddock_side()
	var gap_a := posmod(start_i - int(KartCircuit.ENTRY_FROM), n)
	var gap_b := posmod(start_i - int(KartCircuit.ENTRY_TO), n)
	var in_gap := func(i: int) -> bool:
		return posmod(i - gap_a, n) <= posmod(gap_b - gap_a, n)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	var asphalt := Color("#555b6e")
	var red := Color("#e8505b")
	var white := Color("#f3f1ea")
	var wall := Color("#d9cbb0")
	var deck := Color("#b8b0c8")
	for i in n:
		var j := (i + 1) % n
		var ci: Vector3 = sm[i].pos
		var cj: Vector3 = sm[j].pos
		var li := _kart_left(sm[i])
		var lj := _kart_left(sm[j])
		var yi := hs[i]
		var yj := hs[j]
		var at := func(c: Vector3, l: Vector3, o: float, y: float) -> Vector3:
			return Vector3(c.x, 0, c.z) + l * o + Vector3.UP * y
		# Asfalto.
		_kart_quad(st, faces, at.call(ci, li, half, yi), at.call(ci, li, -half, yi), at.call(cj, lj, -half, yj),
				at.call(cj, lj, half, yj), Vector3.UP, asphalt, true)
		# Zebras, faixa do meio e quadriculado da largada (só pintura, sem colisão).
		var zebra := red if (i / 2) % 2 == 0 else white
		for sgn in [1.0, -1.0]:
			_kart_quad(st, faces, at.call(ci, li, sgn * half, yi + 0.02), at.call(ci, li, sgn * (half - 0.9), yi + 0.02),
					at.call(cj, lj, sgn * (half - 0.9), yj + 0.02), at.call(cj, lj, sgn * half, yj + 0.02), Vector3.UP, zebra, false)
		var near_start := posmod(i - start_i, n) < 2
		if near_start:
			for k in int(KartCircuit.WIDTH):
				var o0 := -half + k
				var col := white if (k + posmod(i - start_i, n)) % 2 == 0 else Color("#22242e")
				_kart_quad(st, faces, at.call(ci, li, o0, yi + 0.025), at.call(ci, li, o0 + 1.0, yi + 0.025),
						at.call(cj, lj, o0 + 1.0, yj + 0.025), at.call(cj, lj, o0, yj + 0.025), Vector3.UP, col, false)
		elif i % 6 < 3:
			_kart_quad(st, faces, at.call(ci, li, 0.15, yi + 0.015), at.call(ci, li, -0.15, yi + 0.015),
					at.call(cj, lj, -0.15, yj + 0.015), at.call(cj, lj, 0.15, yj + 0.015), Vector3.UP, white, false)
		# Muretas e paredes dos dois lados.
		var block := red if (i / 3) % 2 == 0 else white
		for sgn in [1.0, -1.0]:
			var gap: bool = sgn == pad_side and in_gap.call(i)
			var out: float = sgn * outer
			var inn: float = sgn * half
			var face_out: Vector3 = li * sgn
			if not gap:
				# Mureta: dentro, em cima e fora.
				_kart_quad(st, faces, at.call(ci, li, inn, yi), at.call(ci, li, inn, yi + KART_BARRIER_H),
						at.call(cj, lj, inn, yj + KART_BARRIER_H), at.call(cj, lj, inn, yj), -face_out, block, true)
				_kart_quad(st, faces, at.call(ci, li, inn, yi + KART_BARRIER_H), at.call(ci, li, out, yi + KART_BARRIER_H),
						at.call(cj, lj, out, yj + KART_BARRIER_H), at.call(cj, lj, inn, yj + KART_BARRIER_H), Vector3.UP, block, true)
				_kart_quad(st, faces, at.call(ci, li, out, yi), at.call(ci, li, out, yi + KART_BARRIER_H),
						at.call(cj, lj, out, yj + KART_BARRIER_H), at.call(cj, lj, out, yj), face_out, block, true)
				# Ponta da mureta na abertura da entrada.
				if sgn == pad_side and (in_gap.call(j) or in_gap.call((i - 1 + n) % n)):
					var cap_c: Vector3 = cj if in_gap.call(j) else ci
					var cap_l: Vector3 = lj if in_gap.call(j) else li
					var cap_y: float = yj if in_gap.call(j) else yi
					var cap_d: Vector3 = sm[j].dir if in_gap.call(j) else -sm[i].dir
					_kart_quad(st, faces, at.call(cap_c, cap_l, inn, cap_y), at.call(cap_c, cap_l, out, cap_y),
							at.call(cap_c, cap_l, out, cap_y + KART_BARRIER_H), at.call(cap_c, cap_l, inn, cap_y + KART_BARRIER_H), cap_d, block, true)
			if gap:
				# Rampa da entrada: do asfalto até o chão do box, sem degrau (com os lados fechados nas pontas).
				var gi := ground(at.call(ci, li, sgn * (half + KART_RAMP), 0.0).x, at.call(ci, li, sgn * (half + KART_RAMP), 0.0).z) + 0.03
				var gj := ground(at.call(cj, lj, sgn * (half + KART_RAMP), 0.0).x, at.call(cj, lj, sgn * (half + KART_RAMP), 0.0).z) + 0.03
				_kart_quad(st, faces, at.call(ci, li, inn, yi), at.call(ci, li, sgn * (half + KART_RAMP), gi),
						at.call(cj, lj, sgn * (half + KART_RAMP), gj), at.call(cj, lj, inn, yj), Vector3.UP, asphalt, true)
				# Lados nas pontas: no começo (antes de i não tem rampa) e no fim (j já está fora da abertura).
				for end in [[i, (i - 1 + n) % n, -1.0], [j, j, 1.0]]:
					if not in_gap.call(end[1]):
						var ec: Vector3 = sm[end[0]].pos
						var el := _kart_left(sm[end[0]])
						var ey: float = hs[end[0]]
						var eg: float = gi if end[0] == i else gj
						var ed: Vector3 = sm[end[0]].dir * end[2]
						_kart_quad(st, faces, at.call(ec, el, inn, ey), at.call(ec, el, inn, eg - 0.3),
								at.call(ec, el, sgn * (half + KART_RAMP), eg - 0.3), at.call(ec, el, sgn * (half + KART_RAMP), eg), ed, wall, true)
				continue
			# Parede de fora até o chão (ou, na ponte, a borda da laje).
			var bi: float = yi - KART_DECK if span[i] else minf(ground(at.call(ci, li, out, 0.0).x, at.call(ci, li, out, 0.0).z) - 0.3, yi - 0.05)
			var bj: float = yj - KART_DECK if span[i] else minf(ground(at.call(cj, lj, out, 0.0).x, at.call(cj, lj, out, 0.0).z) - 0.3, yj - 0.05)
			_kart_quad(st, faces, at.call(ci, li, out, bi), at.call(ci, li, out, yi), at.call(cj, lj, out, yj),
					at.call(cj, lj, out, bj), face_out, deck if span[i] else wall, true)
		if span[i]:
			# Embaixo da ponte.
			_kart_quad(st, faces, at.call(ci, li, outer, yi - KART_DECK), at.call(ci, li, -outer, yi - KART_DECK),
					at.call(cj, lj, -outer, yj - KART_DECK), at.call(cj, lj, outer, yj - KART_DECK), Vector3.DOWN, deck, true)
		if span[i] != span[j]:
			# Cabeceira da ponte: a parede de baixo da pista termina aqui, virada para o vão.
			var hc: Vector3 = cj if span[i] else ci
			var hl: Vector3 = lj if span[i] else li
			var hy: float = yj if span[i] else yi
			var toward: Vector3 = -sm[j].dir if span[i] else sm[i].dir
			var g0 := minf(ground(hc.x, hc.z), ground(at.call(hc, hl, outer, 0.0).x, at.call(hc, hl, outer, 0.0).z)) - 0.3
			_kart_quad(st, faces, at.call(hc, hl, outer, g0), at.call(hc, hl, -outer, g0), at.call(hc, hl, -outer, hy - KART_DECK),
					at.call(hc, hl, outer, hy - KART_DECK), toward, wall, true)

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 0.85
	st.set_material(mat)
	var mesh := st.commit()
	ResourceSaver.save(mesh, "res://assets/terrain/pista_kart.res")
	mesh.take_over_path("res://assets/terrain/pista_kart.res")
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	ResourceSaver.save(shape, "res://assets/terrain/pista_kart_colisao.res")
	shape.take_over_path("res://assets/terrain/pista_kart_colisao.res")
	var body := StaticBody3D.new()
	body.name = "Pista"
	_add(group, body)
	var mi := MeshInstance3D.new()
	mi.name = "Malha"
	mi.mesh = mesh
	_add(body, mi)
	var cs := CollisionShape3D.new()
	cs.name = "Colisao"
	cs.shape = shape
	_add(body, cs)

	# Arco de chegada (o do Watercraft Kit) em cima da faixa quadriculada.
	var start: Dictionary = sm[start_i]
	_prop(group, "res://assets/barcos/gate-finish.glb", Vector3(start.pos.x, hs[start_i], start.pos.z),
			rad_to_deg(atan2(start.dir.x, start.dir.z)), 2.3)
	# Postes de luz por fora, onde a pista está no chão (fora da ponte e da abertura).
	for i in range(8, n, 34):
		var sgn := 1.0 if (i / 34) % 2 == 0 else -1.0
		if span[i] or (sgn == pad_side and in_gap.call(i)):
			continue
		var l := _kart_left(sm[i]) * sgn
		var lp: Vector3 = sm[i].pos + l * (outer + 1.4)
		var gy := ground(lp.x, lp.z)
		if hs[i] - gy > 0.8:
			continue
		_prop(group, PISTA % "light-curved", Vector3(lp.x, gy, lp.z), rad_to_deg(atan2(-l.x, -l.z)), 7.0, "tronco")
	# Box: pneus empilhados e uma caixa atrás das vagas, cada um no chão do lugar dele.
	var box := _kart_box()
	var back: Vector3 = box.pad - box.to_track * 6.0
	var tyres: Vector3 = back - box.along * 3.0
	for k in 3:
		_prop(group, CARROS % "wheel-racing", Vector3(tyres.x, ground(tyres.x, tyres.z) + 0.3 * 1.6 + k * 0.62, tyres.z), 0.0, 1.6, "caixa")
	var crate: Vector3 = back + box.along * 2.5
	_prop(group, CARROS % "box", Vector3(crate.x, ground(crate.x, crate.z), crate.z), 20.0, 1.8, "caixa")


## Lado esquerdo de quem corre (no plano).
func _kart_left(sample: Dictionary) -> Vector3:
	var d: Vector3 = sample.dir
	return Vector3(d.z, 0, -d.x)


## Lado da reta da largada onde fica o box (o do Morro, a oeste): +1 é a esquerda de quem corre.
func _kart_paddock_side() -> float:
	return 1.0 if _kart_left(KartCircuit.from_start(0.0)).x < 0.0 else -1.0


## Box: o meio dele, a direção da reta e para onde fica a pista.
func _kart_box() -> Dictionary:
	var e := KartCircuit.from_start(-(KartCircuit.ENTRY_FROM + KartCircuit.ENTRY_TO) * 0.5)
	var side := _kart_left(e) * _kart_paddock_side()
	var p: Vector3 = e.pos + side * KART_PADDOCK_OUT
	return {"pad": Vector3(p.x, 0, p.z), "along": e.dir, "to_track": -side}


func _kart_paddock() -> Vector3:
	return _kart_box().pad


var _pad2d := Vector2.INF


func _kart_pad2d() -> Vector2:
	if _pad2d == Vector2.INF:
		var p := _kart_paddock()
		_pad2d = Vector2(p.x, p.z)
	return _pad2d


## Quadrado a-b-c-d com a frente virada para `normal` (a ordem dos vértices é acertada aqui). `solid` entra
## na colisão.
func _kart_quad(st: SurfaceTool, faces: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		normal: Vector3, color: Color, solid: bool) -> void:
	# Na Godot a frente é a do sentido horário: o produto (b - a) x (c - a) aponta para trás.
	if (b - a).cross(c - a).dot(normal) > 0.0:
		var t := b
		b = d
		d = t
	for v in [a, b, c, a, c, d]:
		st.set_color(color)
		st.set_normal(normal)
		st.add_vertex(v)
	if solid:
		faces.append_array(PackedVector3Array([a, b, c, a, c, d]))


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
			var turn := rng.randf_range(0, TAU)
			# Sem grama na pista de kart e na de skate (o sorteio de cada tufo continua o mesmo).
			if _in_activity(p):
				continue
			xforms.append(Transform3D(Basis(Vector3.UP, turn).scaled(Vector3.ONE * s), Vector3(p.x, h - 0.05, p.y)) * _rel_xform(mi, inst))
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
	_marker(cps, "MorroDosVentos", -57, -140)
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

	# Diversões: barraca de tiro ao alvo no canto sudoeste da praça (os alvos ficam ao sul do marcador).
	var fun := _group(markers, "Diversao")
	var pc0 := Vector2(PLAZA.position.x + 20, PLAZA.position.y + 20)
	_marker(fun, "TiroAoAlvo", pc0.x - 4.0, pc0.y + 9.4)
	# Kart: o box (para onde o aventureiro vai ao descer dentro da pista), a largada (logo depois da faixa
	# quadriculada, virada para a frente da pista) e as vagas, enfileiradas ao longo da reta e viradas para a
	# abertura da mureta. O veículo do Car Kit olha para +Z.
	var box := _kart_box()
	_marker(fun, "Kart", box.pad.x, box.pad.z)
	var sm: Array = KartCircuit.samples()
	var st: Dictionary = KartCircuit.from_start(4.0)
	var grid := _marker(fun, "KartLargada", st.pos.x, st.pos.z)
	grid.position.y = _kart_heights[sm.find(st)] + 0.1
	grid.rotation.y = atan2(st.dir.x, st.dir.z)
	var spots := _group(fun, "Vagas")
	for k in KART_SPOTS:
		var vp: Vector3 = box.pad + box.along * ((k - 2) * 4.2)
		var v := _marker(spots, "Vaga%d" % (k + 1), vp.x, vp.z)
		v.rotation.y = atan2(box.to_track.x, box.to_track.z)
	_pasture()

	# Bichos soltos (Quaternius, CC0): modelo, tamanho, raio do passeio e se foge do aventureiro.
	var animals := _group(markers, "Animais")
	var pcz := Vector2(PLAZA.position.x + 20, PLAZA.position.y + 20)
	var bichos := [
		["Cavalo", "Horse.gltf", 0.42, 7.0, false, PASTURE + Vector2(-3, 2)],
		["CavaloBranco", "Horse_White.gltf", 0.42, 7.0, false, PASTURE + Vector2(3, -2)],
		["Vaca", "Cow.gltf", 0.36, 6.0, false, PASTURE + Vector2(0, 4)],
		["Burro", "Donkey.gltf", 0.4, 6.0, false, PASTURE + Vector2(-4, -3)],
		["Alpaca", "Alpaca.gltf", 0.38, 6.0, false, PASTURE + Vector2(4, 3)],
		["Shiba", "ShibaInu.gltf", 0.3, 5.0, false, pcz + Vector2(3, 3)],
		["Husky", "Husky.gltf", 0.32, 8.0, false, Vector2(-12, 200)],
		["Veado1", "Deer.gltf", 0.42, 10.0, true, Vector2(55, -140)],
		["Veado2", "Deer.gltf", 0.4, 10.0, true, Vector2(62, -146)],
		["Cervo", "Stag.gltf", 0.42, 10.0, true, Vector2(-35, -145)],
		["Raposa1", "Fox.gltf", 0.3, 9.0, true, Vector2(-45, -205)],
		["Raposa2", "Fox.gltf", 0.3, 9.0, true, Vector2(95, -130)],
	]
	for b in bichos:
		var bp: Vector2 = b[5]
		_marker(animals, b[0], bp.x, bp.y, {"modelo": b[1], "escala": b[2], "raio": b[3], "timido": b[4]})
	# Cardumes de peixes fofos (Quaternius): no mar perto do cais e no rio perto da ponte. Os do mar pulam.
	var schools := _group(markers, "Cardumes")
	var cardumes := [
		["MarLeste", Vector2(13, 238), 5.5, ["Clownfish", "BlueTang", "YellowTang", "ZebraClownFish", "Puffer"], true],
		["MarOeste", Vector2(-13, 244), 5.0, ["ButterflyFish", "MoorishIdol", "RoyalGramma", "ParrotFish"], true],
		["RioPonte", Vector2(22, _river_z(22)), 3.5, ["Koi", "Goldfish", "BlueGoldfish", "Tetra"], true],
		["RioOeste", Vector2(-45, _river_z(-45)), 3.0, ["Betta", "CardinalFish", "MandarinFish"], false],
	]
	for c in cardumes:
		var cp: Vector2 = c[1]
		var m := _marker(schools, c[0], cp.x, cp.y, {"raio": c[2], "peixes": PackedStringArray(c[3]), "pula": c[4]})
		m.position.y = SEA_LEVEL

	# Caixas de munição: voltam um tempo depois de pegas (o jogo cuida disso).
	var crates := _group(markers, "Municao")
	var crate_spots := [
		["Praca", Vector2(-9, 164)], ["CidadeOeste", Vector2(-50, 150)], ["CidadeLeste", Vector2(50, 150)],
		["PeDoMorro", Vector2(-8, 96)], ["TrilhaDoMorro", _spiral_point(0.45) + Vector2(2, 2)],
		["Cemiterio", Vector2(9, -13)], ["EntradaDaMata", Vector2(-6, -134)], ["Clareira", Vector2(50, -178)],
		["BosqueDasCopas", Vector2(108, -150)], ["MorroDosVentos", Vector2(-86, -148)],
	]
	for spot in crate_spots:
		_marker(crates, spot[0], spot[1].x, spot[1].y)

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
		["Palhaco", "Clown", "parado", "", "festa/circo/balloon_dog_red", pc + Vector2(12.4, 7.0), -120.0, 0.8,
			["Respeitável público! Quer um cachorrinho de balão?", "Acerte a cabeça: vale o dobro!"]],
		["Dino1", "MonsterCostume", "sentado_chao", "", "", pc + Vector2(9.4, 9.9), 60.0, 0.0,
			["Eu sou um dinossauro! Rawr!", "O palhaço é muito engraçado!"]],
		["Dino2", "MonsterCostume", "sentado_chao", "monstercostume_texture_C", "", pc + Vector2(8.6, 7.4), 85.0, 0.0,
			["Shhh, o show vai começar!"]],
		["Magica1", "MagicalGirl", "sentado_chao", "magical_girl_texture_B", "", pc + Vector2(10.6, 11.8), 30.0, 0.0,
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
	var pier_z := pier_end.z - 4.0
	var pier_y := PIER_DECK_Y
	var pier_x := pier_end_half_w - 0.9
	var river_s := _river_z(12.0) + RIVER_HALF + RIVER_BANK + 6.0
	folks.append_array([
		["Urso", "Animatronic_Normal", "tocando", "", "moradores/urso/Guitar", pc + Vector2(0.0, -12.4), 0.0, 1.0,
			["Eu toco violão na banda! Amanhã tem show!", "Cada esqueleto que vai de balão é uma nota a menos... ops, a mais!"]],
		["Bruxa", "Witch", "trabalhando", "", "", pc + Vector2(-14.2, -8.4), 90.0, 0.0,
			["Poção de groselha! Deixa a língua azul!", "Não tenho poção contra esqueleto... só de cócegas."]],
		["SuperHeroi", "Superhero", "torcendo", "", "", pc + Vector2(-1.2, 9.8), -110.0, 0.0,
			["Minha fantasia é de super-herói! Acerta o alvo pra mim?", "Na cabeça do boneco vale o dobro!"]],
		["Astronauta", "SpaceRanger", "parado", "", "", pc + Vector2(11.4, -10.6), -90.0, 0.0,
			["Esse trenzinho vai até a lua!", "Fantasia de astronauta, nota dez!"]],
		["HomemDasCavernas", "Caveman", "parado", "", "", pc + Vector2(-9.3, 1.2), -90.0, 0.0,
			["Uga! Pizza boa!", "Fantasia de homem das cavernas. A barba é de verdade."]],
		["Fazendeiro", "Farmer_A", "trabalhando", "", "moradores/pitchfork", PASTURE + Vector2(8.5, -12.5), 160.0, 0.0,
			["Bom dia! Bem-vindo ao Sítio do Cafuné.", "Os cavalos adoram feno fresquinho.", "Amanhã levo cenoura e alface para a festa!"]],
		["Fazendeira", "Farmer_B", "parado", "", "", PASTURE + Vector2(14.0, 12.5), -140.0, 0.0,
			["Pode chegar perto dos bichos, eles são mansos.", "A vaca não sai de perto do cocho!", "Cuidado com os esqueletos lá do Morro."]],
		["Lenhador", "Werewolf_Man", "cortando", "", "moradores/lenhador/axe", Vector2(12.0, river_s), -90.0, 0.0,
			["Lenha para a fogueira da festa!", "Do outro lado da ponte a mata está cheia de esqueletos. Cuidado!"]],
		["Pescador", "Hiker", "pescando", "hiker_texture_b", "pesca/fishing_rod", Vector2(pier_x, pier_z), 90.0, pier_y - ground(pier_x, pier_z) - 0.1,
			["Psiu! Os peixes estão quase mordendo.", "Hoje só pesquei uma bota... e um balão!"]],
	])
	var walk_to := {"Motorista1": Vector2(-26.0, 146.0), "Motorista2": Vector2(48.0, 146.0)}
	for f in folks:
		var p: Vector2 = f[5]
		var meta := {"modelo": f[1], "atividade": f[2], "variante": f[3], "item": f[4], "altura": f[7],
			"falas": PackedStringArray(f[8])}
		# O machado do KayKit fica com a lâmina para cima no osso da mão: gira em volta do cabo.
		if f[4] == "moradores/lenhador/axe":
			meta["item_rot"] = Vector3(0, 180, 0)
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
