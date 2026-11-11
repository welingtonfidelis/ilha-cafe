class_name Miudezas3D
extends RefCounted
## As miudezas espalhadas no chão das fases do Faísca, uma turma por mundo (pedido do usuário em 2026-11-11: "trabalha
## na textura e vegetaçao ou outros materias que fazem sentido pra fase"). Cada uma é feita aqui, com poucos
## triângulos, para desenhar às centenas por MultiMesh, com a cor de cada uma vinda da instância:
## - pedrinha (túneis): pedra redondinha e facetada;
## - montinho (pico): montinho de neve achatado;
## - cristal (pico): três pontas de cristal de gelo;
## - granulado (nuvens e cozinha): o granulado de confeitar, deitado;
## - confeito (nuvens): a bala redonda e achatada;
## - farelo (cozinha): migalha irregular;
## - pecinha (quarto): a pecinha de montar 2x2, com os quatro pinos;
## - gude (quarto): a bolinha de gude;
## - porca e parafuso (fábrica).
## O UV.y é 1 em tudo (as peças não escurecem no pé como a grama), e as normais são as de verdade.


static func pedrinha() -> ArrayMesh:
	return _bolota(Vector3(0.16, 0.1, 0.13), 0.22, 21, 1)


static func montinho() -> ArrayMesh:
	return _bolota(Vector3(0.55, 0.22, 0.45), 0.12, 22, 2, true)


static func cristal() -> ArrayMesh:
	var st := _comecar()
	var g := RandomNumberGenerator.new()
	g.seed = 23
	for k in 3:
		var a := TAU * k / 3.0 + 0.4
		var pe := Vector3(cos(a), 0, sin(a)) * 0.06
		var eixo := (Vector3.UP + Vector3(cos(a), 0, sin(a)) * g.randf_range(0.2, 0.5)).normalized()
		var altura := g.randf_range(0.22, 0.36)
		var raio := 0.04
		var base := Basis.looking_at(eixo, Vector3.FORWARD if absf(eixo.z) < 0.9 else Vector3.RIGHT)
		var anel: Array[Vector3] = []
		for s in 6:
			var b := TAU * s / 6.0
			anel.append(pe + base * Vector3(cos(b) * raio, sin(b) * raio, 0))
		var meio := pe + eixo * altura * 0.75
		var ponta := pe + eixo * altura
		for s in 6:
			var a0 := anel[s]
			var a1 := anel[(s + 1) % 6]
			var c0 := a0 + eixo * altura * 0.75
			var c1 := a1 + eixo * altura * 0.75
			_tri(st, a0, c0, c1)
			_tri(st, a0, c1, a1)
			_tri(st, c0, ponta, c1)
		var _m := meio
	st.generate_normals()
	return st.commit()


static func granulado() -> ArrayMesh:
	var c := CapsuleMesh.new()
	c.radius = 0.035
	c.height = 0.2
	c.radial_segments = 6
	c.rings = 1
	return _deitado(c, Vector3(0, 0.035, 0))


static func confeito() -> ArrayMesh:
	return _bolota(Vector3(0.12, 0.06, 0.12), 0.0, 24, 2, false, 0.05)


static func farelo() -> ArrayMesh:
	return _bolota(Vector3(0.11, 0.07, 0.09), 0.35, 25, 0)


static func pecinha() -> ArrayMesh:
	var st := _comecar()
	_caixa(st, Vector3(0, 0.1, 0), Vector3(0.32, 0.2, 0.32))
	for k in 4:
		var x := 0.08 if k % 2 == 0 else -0.08
		var z := 0.08 if k < 2 else -0.08
		_cilindro(st, Vector3(x, 0.2, z), 0.05, 0.05, 8)
	st.generate_normals()
	return st.commit()


static func gude() -> ArrayMesh:
	var s := SphereMesh.new()
	s.radius = 0.1
	s.height = 0.2
	s.radial_segments = 12
	s.rings = 6
	return _com_uv_cheio(s, Vector3(0, 0.1, 0))


static func porca() -> ArrayMesh:
	var st := _comecar()
	# Anel sextavado: seis gomos entre o furo e a borda, com o topo e os lados.
	var fora := 0.1
	var dentro := 0.045
	var alto := 0.07
	for s in 6:
		var a0 := TAU * s / 6.0
		var a1 := TAU * (s + 1) / 6.0
		var o0 := Vector3(cos(a0), 0, sin(a0)) * fora
		var o1 := Vector3(cos(a1), 0, sin(a1)) * fora
		var i0 := Vector3(cos(a0), 0, sin(a0)) * dentro
		var i1 := Vector3(cos(a1), 0, sin(a1)) * dentro
		var y := Vector3.UP * alto
		_tri(st, o0 + y, i0 + y, i1 + y)
		_tri(st, o0 + y, i1 + y, o1 + y)
		_tri(st, o0, o1, o1 + y)
		_tri(st, o0, o1 + y, o0 + y)
		_tri(st, i0, i0 + y, i1 + y)
		_tri(st, i0, i1 + y, i1)
	st.generate_normals()
	return st.commit()


static func parafuso() -> ArrayMesh:
	var st := _comecar()
	# Deitado: a cabeça sextavada e a haste com a rosca em anéis.
	var cabeca := Basis(Vector3.FORWARD, PI / 2.0)
	_cilindro(st, Vector3(0, 0.06, 0), 0.06, 0.05, 6, cabeca, Vector3(-0.12, 0, 0))
	for k in 5:
		_cilindro(st, Vector3(0, 0.06, 0), 0.03 if k % 2 == 0 else 0.026, 0.05, 8, cabeca, Vector3(-0.07 + k * 0.05, 0, 0))
	st.generate_normals()
	return st.commit()


# --- miúdos ---------------------------------------------------------------------------

static func _comecar() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_uv(Vector2(0.5, 1.0))
	st.set_color(Color.WHITE)
	return st


## Na ordem da Forma (a face da frente para fora).
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for v in [a, c, b]:
		st.set_uv(Vector2(0.5, 1.0))
		st.set_color(Color.WHITE)
		st.add_vertex(v)


## Uma bolota facetada (esfera baixa com as pontas puxadas para dentro e para fora), com o pé no chão.
static func _bolota(raios: Vector3, aspereza: float, semente: int, divisoes: int, so_em_cima := false, achata := 0.0) -> ArrayMesh:
	var g := RandomNumberGenerator.new()
	g.seed = semente
	var s := SphereMesh.new()
	s.radius = 1.0
	s.height = 1.0 if so_em_cima else 2.0
	s.is_hemisphere = so_em_cima
	s.radial_segments = 6 + divisoes * 3
	s.rings = 3 + divisoes * 2
	var arrays := s.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var jitter := {}
	for i in verts.size():
		var v := verts[i]
		var chave := Vector3i(roundi(v.x * 100.0), roundi(v.y * 100.0), roundi(v.z * 100.0))
		if not jitter.has(chave):
			jitter[chave] = 1.0 + g.randf_range(-aspereza, aspereza)
		v *= jitter[chave]
		v = Vector3(v.x * raios.x, v.y * raios.y, v.z * raios.z)
		if achata > 0.0:
			v.y = clampf(v.y, -raios.y + achata * 0.2, raios.y - achata * 0.2)
		verts[i] = v + Vector3.UP * (0.0 if so_em_cima else raios.y * 0.7)
	arrays[Mesh.ARRAY_VERTEX] = verts
	return _refazer(arrays)


static func _deitado(malha: PrimitiveMesh, sobe: Vector3) -> ArrayMesh:
	var arrays := malha.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normais: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var giro := Basis(Vector3.RIGHT, PI / 2.0)
	for i in verts.size():
		verts[i] = giro * verts[i] + sobe
		normais[i] = giro * normais[i]
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normais
	return _uv_cheio(arrays)


static func _com_uv_cheio(malha: PrimitiveMesh, sobe: Vector3) -> ArrayMesh:
	var arrays := malha.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		verts[i] += sobe
	arrays[Mesh.ARRAY_VERTEX] = verts
	return _uv_cheio(arrays)


## UV.y = 1 em todos os vértices (sem o pé escuro da grama).
static func _uv_cheio(arrays: Array) -> ArrayMesh:
	var uvs := PackedVector2Array()
	uvs.resize((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
	uvs.fill(Vector2(0.5, 1.0))
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m


## Refaz as normais (a bolota amassada) e põe o UV cheio.
static func _refazer(arrays: Array) -> ArrayMesh:
	var m := ArrayMesh.new()
	arrays[Mesh.ARRAY_NORMAL] = null
	arrays[Mesh.ARRAY_TANGENT] = null
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var st := SurfaceTool.new()
	st.create_from(m, 0)
	st.generate_normals()
	var pronta := st.commit_to_arrays()
	return _uv_cheio(pronta)


static func _caixa(st: SurfaceTool, meio: Vector3, tam: Vector3) -> void:
	var h := tam * 0.5
	var c := [Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z),
			Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z)]
	for f in [[4, 5, 6, 7], [3, 2, 1, 0], [0, 1, 5, 4], [2, 3, 7, 6], [1, 2, 6, 5], [3, 0, 4, 7]]:
		var a: Vector3 = meio + c[f[0]]
		var b: Vector3 = meio + c[f[1]]
		var cc: Vector3 = meio + c[f[2]]
		var d: Vector3 = meio + c[f[3]]
		_tri(st, a, cc, b)
		_tri(st, a, d, cc)


static func _cilindro(st: SurfaceTool, pe: Vector3, raio: float, alto: float, lados: int, giro := Basis.IDENTITY, desloca := Vector3.ZERO) -> void:
	for s in lados:
		var a0 := TAU * s / lados
		var a1 := TAU * (s + 1) / lados
		var b0 := Vector3(cos(a0) * raio, 0, sin(a0) * raio)
		var b1 := Vector3(cos(a1) * raio, 0, sin(a1) * raio)
		var y := Vector3.UP * alto
		var p := func(v: Vector3) -> Vector3: return giro * v + pe + desloca
		_tri(st, p.call(b0), p.call(b1 + y), p.call(b1))
		_tri(st, p.call(b0), p.call(b0 + y), p.call(b1 + y))
		_tri(st, p.call(y), p.call(b1 + y), p.call(b0 + y))
