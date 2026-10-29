class_name Forma
extends RefCounted
## Malhas arredondadas feitas por código para as peças do robô.


## Superelipsoide centrada na origem. Expoente 1 dá uma elipsoide; abaixo de 1 a forma fica
## mais quadrada, com cantos redondos. `eta_min` corta a parte de baixo (boné, cascas), em
## radianos de latitude: -PI/2 fecha a forma inteira.
static func superelipsoide(raios: Vector3, e_vert := 1.0, e_horiz := 1.0, eta_min := -PI / 2.0, aneis := 28, gomos := 48) -> ArrayMesh:
	var pts := []
	var nrm := []
	for i in aneis + 1:
		var eta := eta_min + (PI / 2.0 - eta_min) * i / aneis
		var linha_p := []
		var linha_n := []
		for j in gomos + 1:
			var omega := -PI + TAU * j / gomos
			var p := Vector3(
				raios.x * _sp(cos(eta), e_vert) * _sp(cos(omega), e_horiz),
				raios.y * _sp(sin(eta), e_vert),
				raios.z * _sp(cos(eta), e_vert) * _sp(sin(omega), e_horiz))
			var n := Vector3(
				_sp(cos(eta), 2.0 - e_vert) * _sp(cos(omega), 2.0 - e_horiz) / raios.x,
				_sp(sin(eta), 2.0 - e_vert) / raios.y,
				_sp(cos(eta), 2.0 - e_vert) * _sp(sin(omega), 2.0 - e_horiz) / raios.z)
			linha_p.append(p)
			linha_n.append(n.normalized() if n.length() > 0.00001 else Vector3(0, signf(p.y), 0))
		pts.append(linha_p)
		nrm.append(linha_n)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in aneis:
		for j in gomos:
			for ij in [[i, j], [i + 1, j + 1], [i + 1, j], [i, j], [i, j + 1], [i + 1, j + 1]]:
				st.set_normal(nrm[ij[0]][ij[1]])
				st.add_vertex(pts[ij[0]][ij[1]])
	return st.commit()


## Caixa com quinas arredondadas (raio `raio`), centrada na origem. Cada face é uma grade em
## que só a faixa da quina é subdividida; o ponto da face é empurrado para o arco a partir
## da caixa interna, e a normal sai desse empurrão (sombreado liso, sem triângulos tortos).
static func caixa_redonda(tamanho: Vector3, raio: float, gomos := 5) -> ArrayMesh:
	var meio := tamanho / 2.0
	raio = minf(raio, minf(meio.x, minf(meio.y, meio.z)) * 0.95)
	var interno := meio - Vector3.ONE * raio
	var amostras := []
	for eixo in 3:
		var h: float = meio[eixo]
		var lista: Array[float] = []
		for k in gomos + 1:
			lista.append(-h + raio * k / gomos)
		for k in gomos + 1:
			lista.append(h - raio + raio * k / gomos)
		amostras.append(lista)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for eixo in 3:
		var b := (eixo + 1) % 3
		var c := (eixo + 2) % 3
		for sinal in [-1.0, 1.0]:
			var face := Vector3.ZERO
			face[eixo] = sinal
			var grade := []
			for u in amostras[b]:
				var linha := []
				for v in amostras[c]:
					var p := Vector3.ZERO
					p[eixo] = sinal * meio[eixo]
					p[b] = u
					p[c] = v
					var dentro := p.clamp(-interno, interno)
					var n := (p - dentro).normalized()
					linha.append([dentro + n * raio, n])
				grade.append(linha)
			for i in grade.size() - 1:
				for j in grade[i].size() - 1:
					var q := [grade[i][j], grade[i + 1][j], grade[i + 1][j + 1], grade[i][j + 1]]
					for tri in [[q[0], q[1], q[2]], [q[0], q[2], q[3]]]:
						# Na Godot a face da frente é a de giro horário visto de fora.
						if (tri[1][0] - tri[0][0]).cross(tri[2][0] - tri[0][0]).dot(face) > 0.0:
							tri = [tri[0], tri[2], tri[1]]
						for vert in tri:
							st.set_normal(vert[1])
							st.add_vertex(vert[0])
	return st.commit()


## Ovo: elipsoide centrada na origem cujo raio de lado cresce para cima (`afina` > 0) ou para
## baixo (< 0). Em y = +raios.y o raio de lado é multiplicado por 1 + afina.
static func ovo(raios: Vector3, afina := 0.15, aneis := 28, gomos := 48) -> ArrayMesh:
	var pts := []
	var nrm := []
	for i in aneis + 1:
		var eta := -PI / 2.0 + PI * i / aneis
		var linha_p := []
		var linha_n := []
		for j in gomos + 1:
			var omega := -PI + TAU * j / gomos
			var f := 1.0 + afina * sin(eta)
			var p := Vector3(raios.x * f * cos(eta) * cos(omega), raios.y * sin(eta), raios.z * f * cos(eta) * sin(omega))
			# Gradiente de (x / (rx f))² + (y / ry)² + (z / (rz f))², com f dependendo de y.
			var lado := cos(eta) * cos(eta)
			var n := Vector3(p.x / pow(raios.x * f, 2.0), p.y / (raios.y * raios.y) - lado * afina / (f * raios.y), p.z / pow(raios.z * f, 2.0))
			linha_p.append(p)
			linha_n.append(n.normalized() if n.length() > 0.00001 else Vector3(0, signf(p.y), 0))
		pts.append(linha_p)
		nrm.append(linha_n)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in aneis:
		for j in gomos:
			for ij in [[i, j], [i + 1, j + 1], [i + 1, j], [i, j], [i, j + 1], [i + 1, j + 1]]:
				st.set_normal(nrm[ij[0]][ij[1]])
				st.add_vertex(pts[ij[0]][ij[1]])
	return st.commit()


## Tubo fechado de raio `raio` que passa pelos `pontos` (um laço, sem repetir o primeiro no fim). O anel
## de cada ponto fica de frente para a tangente; o "para cima" de cada anel vem do anterior, para o tubo
## não torcer.
static func tubo_fechado(pontos: PackedVector3Array, raio: float, gomos := 16) -> ArrayMesh:
	var n := pontos.size()
	var aneis := []
	var cima := Vector3.ZERO
	for i in n + 1:
		var k := i % n
		var tangente := (pontos[(k + 1) % n] - pontos[(k - 1 + n) % n]).normalized()
		if cima == Vector3.ZERO:
			cima = Vector3(0, 0, 1) if absf(tangente.z) < 0.9 else Vector3(1, 0, 0)
		var lado := tangente.cross(cima).normalized()
		cima = lado.cross(tangente).normalized()
		var anel := []
		for j in gomos + 1:
			var a := TAU * j / gomos
			var radial := cima * cos(a) + lado * sin(a)
			anel.append([pontos[k] + radial * raio, radial])
		aneis.append(anel)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		for j in gomos:
			var q: Array = [aneis[i][j], aneis[i + 1][j], aneis[i + 1][j + 1], aneis[i][j + 1]]
			for tri in [[q[0], q[1], q[2]], [q[0], q[2], q[3]]]:
				var fora: Vector3 = tri[0][1] + tri[1][1] + tri[2][1]
				# Na Godot a face da frente é a de giro horário visto de fora.
				if (tri[1][0] - tri[0][0]).cross(tri[2][0] - tri[0][0]).dot(fora) > 0.0:
					tri = [tri[0], tri[2], tri[1]]
				for vert in tri:
					st.set_normal(vert[1])
					st.add_vertex(vert[0])
	return st.commit()


## Estrela de cinco pontas estufada no meio, de pé no plano XY (a mesma da Ilha Cafuné).
static func estrela(raio := 0.45, interno := 0.2, espessura := 0.22) -> ArrayMesh:
	var contorno: Array[Vector2] = []
	for i in 10:
		var a := PI / 2.0 + i * PI / 5.0
		contorno.append(Vector2(cos(a), sin(a)) * (raio if i % 2 == 0 else interno))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for lado in [1.0, -1.0]:
		var ponta := Vector3(0, 0, lado * espessura * 0.5)
		for i in contorno.size():
			var a := contorno[i]
			var b := contorno[(i + 1) % contorno.size()]
			st.add_vertex(ponta)
			if lado > 0.0:
				st.add_vertex(Vector3(a.x, a.y, 0))
				st.add_vertex(Vector3(b.x, b.y, 0))
			else:
				st.add_vertex(Vector3(b.x, b.y, 0))
				st.add_vertex(Vector3(a.x, a.y, 0))
	st.generate_normals()
	return st.commit()


static func _sp(v: float, e: float) -> float:
	return signf(v) * pow(absf(v), e)
