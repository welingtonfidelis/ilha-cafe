extends SceneTree
## Revisor de piscadas (2026-11-11, na revisão dos glitches da 2-1): procura duas peças com faces planas no mesmo
## plano (até DIST m), viradas para o mesmo lado e uma por cima da outra, de material diferente. Na tela elas piscam,
## uma aparecendo por cima da outra conforme a câmera anda (z-fighting): as tábuas da ponte da 2-1, a pizza no tampo,
## as camadas dos bolos da 2-2, a neve no pico da 3-1.
## Fica fora o que não se vê: as faces viradas para baixo, as que têm algo sólido logo na frente (escondidas dentro de
## outra peça) e as de material igual (a mesma cor nas duas, que não pisca). O desenho só de sombra também fica fora.
## Uso: godot --headless --path . -s res://tools/revisor_piscadas.gd [-- 1-1 1-2 2-1 2-2 2-3 3-1 3-2 3-3 nave]
## Sem nomes, revisa todas as fases do Faísca. Sai com código 1 se achar alguma.

const NIVEIS := ["1-1", "1-2", "2-1", "2-2", "2-3", "3-1", "3-2", "3-3", "nave", "chefe-1", "chefe-2", "chefe-3"]
const DIST := 0.002
const AREA_MIN := 0.05

var _planos := {}
var _entradas := {}


func _init() -> void:
	var pedidos := Array(OS.get_cmdline_user_args())
	var quais: Array = NIVEIS if pedidos.is_empty() else pedidos
	var total := 0
	for id in quais:
		total += await _revisar(id)
	print("RESULTADO: %d piscando" % total)
	quit(1 if total > 0 else 0)


func _revisar(id: String) -> int:
	_planos.clear()
	_entradas.clear()
	var nivel: Node3D
	match id:
		"1-1": nivel = Fase11.new()
		"1-2": nivel = Fase12.new()
		"2-1": nivel = Fase21.new()
		"2-2": nivel = Fase22.new()
		"2-3": nivel = Fase23.new()
		"3-1": nivel = Fase31.new()
		"3-2": nivel = Fase32.new()
		"3-3": nivel = Fase33.new()
		"nave": nivel = FaseNave.new()
		"chefe-1": nivel = Chefe1.new()
		"chefe-2": nivel = Chefe2.new()
		"chefe-3": nivel = Chefe3.new()
	root.add_child(nivel)
	for i in 4:
		await physics_frame
	var instancias: Array[MeshInstance3D] = []
	_juntar(nivel, instancias)
	for mi in instancias:
		_planificar(mi, nivel)
	var achados := []
	for chave in _planos:
		if chave == "+y":
			continue
		var lista: Array = _planos[chave]
		lista.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.c < b.c)
		for i in lista.size():
			for j in range(i + 1, lista.size()):
				var a: Dictionary = lista[i]
				var b: Dictionary = lista[j]
				if b.c - a.c > DIST:
					break
				if a.dono == b.dono or _mesmo_material(a.dono, b.dono):
					continue
				var r: Rect2 = a.r.intersection(b.r)
				if r.get_area() < AREA_MIN:
					continue
				var area := _area_comum(nivel, a.tris, b.tris, r, chave, a.c)
				if area >= AREA_MIN:
					achados.append([area, a.c, a.nome + _desc(a.dono), b.nome + _desc(b.dono)])
	achados.sort_custom(func(x: Array, y: Array) -> bool: return x[0] > y[0])
	for f in achados:
		print("%-8s %6.2f m² no plano %.2f   %s  <>  %s" % [id, f[0], f[1], f[2], f[3]])
	nivel.queue_free()
	await process_frame
	return achados.size()


func _juntar(n: Node, lista: Array[MeshInstance3D]) -> void:
	if n is MeshInstance3D and n.mesh and n.is_visible_in_tree() and n.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
		lista.append(n)
	for c in n.get_children():
		_juntar(c, lista)


func _planificar(mi: MeshInstance3D, nivel: Node3D) -> void:
	var faces := mi.mesh.get_faces()
	var t := mi.global_transform
	var nome := str(nivel.get_path_to(mi))
	if nome.length() > 70:
		nome = nome.substr(0, 30) + "…" + nome.substr(nome.length() - 38)
	var dono := mi.get_instance_id()
	var i := 0
	while i + 2 < faces.size():
		var a := t * faces[i]
		var b := t * faces[i + 1]
		var c := t * faces[i + 2]
		i += 3
		var n := (b - a).cross(c - a)
		if n.length() < 1e-6:
			continue
		n = n.normalized()
		for eixo in 3:
			if absf(n[eixo]) < 0.999:
				continue
			var sinal := 1 if n[eixo] > 0 else -1
			var u := (eixo + 1) % 3
			var v := (eixo + 2) % 3
			var coord := (a[eixo] + b[eixo] + c[eixo]) / 3.0
			var p := [Vector2(a[u], a[v]), Vector2(b[u], b[v]), Vector2(c[u], c[v])]
			var chave := "%s%s" % ["+" if sinal > 0 else "-", "xyz"[eixo]]
			var k2 := "%s|%d|%d" % [chave, dono, roundi(coord * 100.0)]
			if not _planos.has(chave):
				_planos[chave] = []
			var entrada: Dictionary = _entrada(k2, chave, coord, nome, dono)
			entrada.tris.append(p)
			var r := Rect2(p[0], Vector2.ZERO).expand(p[1]).expand(p[2])
			entrada.r = r if entrada.r.get_area() == 0.0 and entrada.tris.size() == 1 else entrada.r.merge(r)


func _entrada(k2: String, chave: String, coord: float, nome: String, dono: int) -> Dictionary:
	if _entradas.has(k2):
		return _entradas[k2]
	var e := {"c": coord, "nome": nome, "dono": dono, "tris": [], "r": Rect2(), "chave": chave}
	_entradas[k2] = e
	_planos[chave].append(e)
	return e


func _area_comum(nivel: Node3D, ta: Array, tb: Array, r: Rect2, chave: String, c: float) -> float:
	var n := 12
	var dentro := 0
	var eixo := "xyz".find(chave[1])
	var fora := -1.0 if chave[0] == "+" else 1.0
	var u := (eixo + 1) % 3
	var v := (eixo + 2) % 3
	var espaco := nivel.get_world_3d().direct_space_state
	var q := PhysicsPointQueryParameters3D.new()
	q.collision_mask = 1
	for i in n:
		for j in n:
			var p := r.position + Vector2((i + 0.5) / n * r.size.x, (j + 0.5) / n * r.size.y)
			if _em_algum(ta, p) and _em_algum(tb, p):
				var w := Vector3.ZERO
				w[eixo] = c + fora * 0.04
				w[u] = p.x
				w[v] = p.y
				q.position = w
				if espaco.intersect_point(q, 1).is_empty():
					dentro += 1
	return r.get_area() * dentro / float(n * n)


func _desc(id: int) -> String:
	var mi := instance_from_id(id) as MeshInstance3D
	var m := mi.mesh
	var t := m.get_class()
	if m is BoxMesh:
		t = "Box%s" % [m.size]
	var mat := mi.material_override
	var cor := ""
	if mat is StandardMaterial3D:
		cor = " #" + (mat as StandardMaterial3D).albedo_color.to_html(false)
		if (mat as StandardMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			cor += " transp"
	return " (%s%s)" % [t, cor]


func _em_algum(tris: Array, p: Vector2) -> bool:
	for t in tris:
		if Geometry2D.point_is_inside_triangle(p, t[0], t[1], t[2]):
			return true
	return false


## As duas malhas com o mesmo material (ou a mesma cor e textura): no mesmo plano, não se nota.
func _mesmo_material(a: int, b: int) -> bool:
	var ma := (instance_from_id(a) as MeshInstance3D).get_active_material(0)
	var mb := (instance_from_id(b) as MeshInstance3D).get_active_material(0)
	if ma == mb:
		return true
	if ma is StandardMaterial3D and mb is StandardMaterial3D:
		var sa := ma as StandardMaterial3D
		var sb := mb as StandardMaterial3D
		return sa.albedo_color.is_equal_approx(sb.albedo_color) and sa.albedo_texture == sb.albedo_texture
	return false
