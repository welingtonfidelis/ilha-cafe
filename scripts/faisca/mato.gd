class_name Mato
extends Node3D
## As plantinhas que balançam quando o Faísca passa (item 6 da lista do Faísca, 2026-11-11, o "mundo que reage" do
## Astro Bot). Cada fase tem um Mato só, que a `Fase.planta` cria na primeira vez; cada planta é uma mola: o Faísca
## perto empurra o topo para longe dele, e ao sair ela volta balançando até parar. O giro empurra de mais longe e o
## laser dos pés, por cima, abre o mato em roda. Nenhuma tem colisão (são enfeite), e cada mundo tem as suas:
##   grama e flor           floresta e ilhas (1-1, a grama de sempre do Forest Nature e flores feitas aqui)
##   cogumelo               túneis (1-2), com o chapéu brilhando de leve
##   pirulito               nuvens de algodão-doce (2-2), com flores cor-de-rosa
##   catavento              quarto de brinquedos (2-3): gira quando ele passa
##   gelo e flor_de_gelo    pico gelado (3-1): a grama coberta de geada e flores de cristal
##   antena                 fábrica (3-2): a mola com a bolinha em cima, que faz "boing"

## Até onde o Faísca encosta (do pé da planta, no chão) e o quanto o topo dobra.
const RAIO := 1.3
const RAIO_GIRO := 2.8
const RAIO_LASER := 2.4
const DOBRA := 0.7
## A mola: dureza e freio (a antena é mais mole e balança mais).
const DUREZA := 70.0
const FREIO := 5.5
const CORES_DAS_FLORES := [Color("ff7eb6"), Color("ffffff"), Color("ffd23f"), Color("8fd3ff"), Color("ff9f43"), Color("c39bff")]
const CORES_DOS_PIRULITOS := [Color("ff5d8f"), Color("7bdff2"), Color("ffd23f"), Color("b8f2a0")]
const CORES_DOS_CATAVENTOS := [Color("ff4d4d"), Color("ffd23f"), Color("3fa7ff"), Color("4cd964")]

## Cada planta: o nó, o pé, a base (giro e escala), o topo (a inclinação, x e z), a rapidez, a mola dela, se estava
## encostada, e o que gira (o catavento).
var plantas: Array[Dictionary] = []
## Quantas vezes alguma planta foi empurrada (para os testes).
var empurroes := 0
var _som := 0.0
var _cache := {}


## Uma planta do `tipo` com o pé em `pe`. `semente` escolhe a cor e o jeito (a mesma semente dá a mesma planta).
func plantar(tipo: String, pe: Vector3, semente: int) -> Node3D:
	var gerador := RandomNumberGenerator.new()
	gerador.seed = semente
	var no := _montar(tipo, gerador)
	no.set_meta("enfeite", true)
	add_child(no)
	var giro := Basis(Vector3.UP, gerador.randf() * TAU)
	var escala := gerador.randf_range(0.85, 1.15)
	no.global_transform = Transform3D(giro.scaled(Vector3.ONE * escala), pe)
	var mole := 0.55 if tipo == "antena" else 1.0
	plantas.append({"no": no, "pe": pe, "base": no.global_basis, "topo": Vector2.ZERO, "vel": Vector2.ZERO,
			"dureza": DUREZA * mole, "freio": FREIO * (0.6 if tipo == "antena" else 1.0), "perto": false, "tipo": tipo,
			"helice": no.get_node_or_null("Helice"), "giro_helice": 0.0})
	return no


func _physics_process(delta: float) -> void:
	_som -= delta
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	if j == null:
		return
	var p := j.global_position
	var vel := Vector2(j.velocity.x, j.velocity.z)
	var raio := RAIO_GIRO if j.girando > 0.0 else RAIO
	for pl in plantas:
		var pe: Vector3 = pl.pe
		var d := Vector2(pe.x - p.x, pe.z - p.z)
		var longe := d.length()
		var acima := p.y - pe.y
		var alvo := Vector2.ZERO
		var perto := false
		if longe < raio and acima > -0.6 and acima < 1.6:
			perto = true
			var fora := d / longe if longe > 0.05 else Vector2(vel.x, vel.y).normalized()
			alvo = fora * DOBRA * (1.0 - longe / raio * 0.6)
		elif j.flutuando and longe < RAIO_LASER and acima > 0.0 and acima < 5.0:
			perto = true
			alvo = (d / maxf(longe, 0.05)) * DOBRA * 0.8 * (1.0 - longe / RAIO_LASER)
		if perto and not pl.perto:
			# Encostou agora: um empurrão a mais (correndo, mais forte) e o farfalhar.
			var tranco := clampf(vel.length() / 6.0, 0.3, 1.2)
			pl.vel += (alvo.normalized() if alvo.length() > 0.01 else Vector2.RIGHT) * 6.0 * tranco
			empurroes += 1
			if _som <= 0.0 and (vel.length() > 1.5 or j.girando > 0.0 or j.flutuando):
				_som = 0.16
				if pl.tipo == "antena":
					Sfx.play_at(self, "faisca_mola", pe, -16.0, 0.2)
				else:
					Sfx.play_at(self, "mato", pe, -10.0, 0.2)
			if pl.helice:
				pl.giro_helice = maxf(pl.giro_helice, 14.0 + vel.length() * 2.0)
		pl.perto = perto
		var t: Vector2 = pl.topo
		var v: Vector2 = pl.vel
		if not perto and t.length_squared() < 0.00002 and v.length_squared() < 0.0004 and pl.giro_helice <= 0.0:
			continue
		v += ((alvo - t) * pl.dureza - v * pl.freio) * delta
		t += v * delta
		t = t.limit_length(1.1)
		pl.topo = t
		pl.vel = v
		var no: Node3D = pl.no
		var angulo := t.length()
		var base: Basis = pl.base
		no.global_basis = Basis(Vector3(t.y, 0, -t.x) / angulo, angulo) * base if angulo > 0.0005 else base
		if pl.helice:
			(pl.helice as Node3D).rotate_object_local(Vector3.FORWARD, pl.giro_helice * delta)
			pl.giro_helice = move_toward(pl.giro_helice, 0.0, delta * 6.0)


## A inclinação do topo da planta `i` (em radianos, para os testes).
func dobra(i: int) -> float:
	return (plantas[i].topo as Vector2).length()


# --- as plantas ---------------------------------------------------------------------

func _montar(tipo: String, g: RandomNumberGenerator) -> Node3D:
	match tipo:
		"grama":
			return _grama(g, null)
		"gelo":
			return _grama(g, _mat(Color("e6f6ff"), 0.35, Color("bfe6ff"), 0.25))
		"flor":
			return _flor(g, CORES_DAS_FLORES[g.randi() % CORES_DAS_FLORES.size()], false)
		"flor_rosa":
			return _flor(g, [Color("ff7eb6"), Color("ffb3d9"), Color("ffffff")][g.randi() % 3], false)
		"flor_de_gelo":
			return _flor(g, Color("bfe6ff"), true)
		"cogumelo":
			return _cogumelo(g)
		"pirulito":
			return _pirulito(g)
		"catavento":
			return _catavento(g)
		"antena":
			return _antena(g)
	return Node3D.new()


## A grama do Forest Nature (dois tufos juntos); com `mat`, coberta de geada.
func _grama(g: RandomNumberGenerator, mat: Material) -> Node3D:
	var no := Node3D.new()
	for k in 2:
		var arquivo := "Grass_%d_A_Color1" % (1 + g.randi() % 2)
		var tufo: Node3D = _cena(Fase.FLORESTA + arquivo + ".gltf").instantiate()
		tufo.scale = Vector3.ONE * g.randf_range(1.7, 2.3)
		tufo.position = Vector3(g.randf_range(-0.25, 0.25), 0, g.randf_range(-0.25, 0.25))
		tufo.rotation.y = g.randf() * TAU
		if mat:
			for mi in tufo.find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).material_override = mat
		no.add_child(tufo)
	return no


## Flor de caule fino, miolo e seis pétalas abertas. De gelo, as pétalas são cristais compridos que brilham.
func _flor(g: RandomNumberGenerator, cor: Color, de_gelo: bool) -> Node3D:
	var no := Node3D.new()
	var altura := g.randf_range(0.75, 1.1)
	var caule := CylinderMesh.new()
	caule.top_radius = 0.03
	caule.bottom_radius = 0.045
	caule.height = altura
	caule.radial_segments = 6
	caule.rings = 1
	_peca(no, caule, _mat(Color("8fd3ff") if de_gelo else Color("4caf50")), Vector3(0, altura * 0.5, 0))
	var folha := _malha("folha", func() -> Mesh: return Forma.superelipsoide(Vector3(0.14, 0.03, 0.06), 1.0, 1.0, -PI / 2.0, 6, 10))
	var f := _peca(no, folha, _mat(Color("bfe6ff") if de_gelo else Color("5fbf5a")), Vector3(0.1, altura * 0.35, 0))
	f.rotation.z = 0.5
	var cabeca := Node3D.new()
	cabeca.position.y = altura
	cabeca.rotation.x = -0.35
	no.add_child(cabeca)
	var miolo := _malha("miolo", func() -> Mesh: return Forma.superelipsoide(Vector3(0.09, 0.06, 0.09), 1.0, 1.0, -PI / 2.0, 8, 12))
	_peca(cabeca, miolo, _mat(Color("ffffff") if de_gelo else Color("ffb000"), 0.5, Color("ffffff") if de_gelo else Color.BLACK,
			0.6 if de_gelo else 0.0), Vector3(0, 0.03, 0))
	var petala := _malha("petala_gelo" if de_gelo else "petala", func() -> Mesh:
		return Forma.ovo(Vector3(0.05, 0.03, 0.16), 0.35, 6, 10) if de_gelo else Forma.superelipsoide(Vector3(0.09, 0.025, 0.15), 1.0, 1.0, -PI / 2.0, 6, 12))
	var mat_petala := _mat(cor, 0.2 if de_gelo else 0.6, cor if de_gelo else Color.BLACK, 0.9 if de_gelo else 0.0)
	for i in 6:
		var a := TAU * i / 6.0
		var pe := _peca(cabeca, petala, mat_petala, Vector3(sin(a) * 0.14, 0.01, cos(a) * 0.14))
		pe.rotation.y = a
		pe.rotation.x = -0.25 if de_gelo else -0.12
	return no


## Cogumelo dos túneis: pé claro e chapéu redondo colorido com bolinhas, brilhando de leve no escuro.
func _cogumelo(g: RandomNumberGenerator) -> Node3D:
	var no := Node3D.new()
	var cores := [Color("ff5d73"), Color("5dd0ff"), Color("b18cff"), Color("ffb347")]
	var cor: Color = cores[g.randi() % cores.size()]
	var altura := g.randf_range(0.5, 0.85)
	var pe := CylinderMesh.new()
	pe.top_radius = 0.09
	pe.bottom_radius = 0.13
	pe.height = altura
	pe.radial_segments = 8
	pe.rings = 1
	_peca(no, pe, _mat(Color("f4ead2")), Vector3(0, altura * 0.5, 0))
	var chapeu := _malha("chapeu", func() -> Mesh: return Forma.superelipsoide(Vector3(0.34, 0.24, 0.34), 0.8, 1.0, 0.0, 10, 18))
	_peca(no, chapeu, _mat(cor, 0.5, cor, 0.55), Vector3(0, altura - 0.04, 0))
	var bolinha := _malha("bolinha", func() -> Mesh: return Forma.superelipsoide(Vector3(0.06, 0.03, 0.06), 1.0, 1.0, -PI / 2.0, 6, 8))
	for i in 4:
		var a := TAU * i / 4.0 + 0.4
		var b := _peca(no, bolinha, _mat(Color.WHITE, 0.5, Color.WHITE, 0.3), Vector3(sin(a) * 0.2, altura + 0.11, cos(a) * 0.2))
		b.rotation = Vector3(cos(a) * 0.6, 0, -sin(a) * 0.6)
	return no


## Pirulito de espiral num palito branco, como uma flor das nuvens de algodão-doce.
func _pirulito(g: RandomNumberGenerator) -> Node3D:
	var no := Node3D.new()
	var altura := g.randf_range(0.9, 1.3)
	var palito := CylinderMesh.new()
	palito.top_radius = 0.035
	palito.bottom_radius = 0.035
	palito.height = altura
	palito.radial_segments = 6
	palito.rings = 1
	_peca(no, palito, _mat(Color("fffaf0")), Vector3(0, altura * 0.5, 0))
	var cor: Color = CORES_DOS_PIRULITOS[g.randi() % CORES_DOS_PIRULITOS.size()]
	var disco := CylinderMesh.new()
	disco.top_radius = 0.3
	disco.bottom_radius = 0.3
	disco.height = 0.09
	disco.radial_segments = 20
	disco.rings = 1
	var d := _peca(no, disco, _mat(Color.WHITE, 0.3), Vector3(0, altura + 0.22, 0))
	d.rotation.x = PI / 2.0
	# A espiral: três anéis coloridos na frente e atrás do disco branco.
	for k in 3:
		var anel := TorusMesh.new()
		anel.inner_radius = 0.06 + k * 0.08
		anel.outer_radius = 0.1 + k * 0.08
		anel.rings = 16
		anel.ring_segments = 6
		var a := _peca(no, anel, _mat(cor, 0.3, cor, 0.2), Vector3(0, altura + 0.22, 0))
		a.rotation.x = PI / 2.0
		# Mais grosso que o disco (0,09 m), para a espiral aparecer na frente e atrás.
		a.scale = Vector3(1, 3.0, 1)
	return no


## Catavento de quatro pás num palito: gira quando o Faísca passa (a hélice é o nó "Helice").
func _catavento(g: RandomNumberGenerator) -> Node3D:
	var no := Node3D.new()
	var altura := g.randf_range(1.0, 1.3)
	var palito := CylinderMesh.new()
	palito.top_radius = 0.03
	palito.bottom_radius = 0.035
	palito.height = altura
	palito.radial_segments = 6
	palito.rings = 1
	_peca(no, palito, _mat(Color("f2e3c6")), Vector3(0, altura * 0.5, 0))
	var helice := Node3D.new()
	helice.name = "Helice"
	helice.position = Vector3(0, altura, 0.06)
	no.add_child(helice)
	var pa := _malha("pa", func() -> Mesh:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for v in [Vector3(0, 0, 0), Vector3(0.32, 0.02, 0), Vector3(0.3, 0.3, 0.04)]:
			st.add_vertex(v)
		st.generate_normals()
		return st.commit())
	var cor0 := g.randi() % CORES_DOS_CATAVENTOS.size()
	for i in 4:
		var cor: Color = CORES_DOS_CATAVENTOS[(cor0 + i) % CORES_DOS_CATAVENTOS.size()]
		var m := _mat(cor, 0.5)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		var p := _peca(helice, pa, m, Vector3.ZERO)
		p.rotation.z = TAU * i / 4.0
	var botao := SphereMesh.new()
	botao.radius = 0.05
	botao.height = 0.1
	_peca(helice, botao, _mat(Color("ffffff")), Vector3(0, 0, 0.03))
	return no


## Antena de mola da fábrica: a molinha fina e a bolinha brilhante em cima, que balança mais que as outras.
func _antena(g: RandomNumberGenerator) -> Node3D:
	var no := Node3D.new()
	var altura := g.randf_range(0.9, 1.3)
	var base := CylinderMesh.new()
	base.top_radius = 0.12
	base.bottom_radius = 0.16
	base.height = 0.12
	base.radial_segments = 10
	base.rings = 1
	_peca(no, base, _mat(Color("55607a"), 0.4), Vector3(0, 0.06, 0))
	var mola := _malha("mola", func() -> Mesh:
		var pontos := PackedVector3Array()
		for k in 61:
			var a := k * 0.55
			pontos.append(Vector3(cos(a) * 0.05, 0.12 + k * 0.0135, sin(a) * 0.05))
		return Forma.tubo_fechado(pontos, 0.014, 6))
	var mi := _peca(no, mola, _mat(Color("c8ccd6"), 0.25), Vector3.ZERO)
	mi.scale.y = altura / 0.95
	var cores := [Color("ff4d6d"), Color("ffd23f"), Color("3fa7ff"), Color("4cd964")]
	var cor: Color = cores[g.randi() % cores.size()]
	var bola := SphereMesh.new()
	bola.radius = 0.11
	bola.height = 0.22
	_peca(no, bola, _mat(cor, 0.3, cor, 0.6), Vector3(0, altura + 0.08, 0))
	return no


# --- miúdos ---------------------------------------------------------------------------

func _peca(pai: Node3D, malha: Mesh, mat: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pai.add_child(mi)
	return mi


## Malha feita uma vez só por Mato (as plantas do mesmo tipo dividem).
func _malha(nome: String, fazer: Callable) -> Mesh:
	if not _cache.has(nome):
		_cache[nome] = fazer.call()
	return _cache[nome]


func _mat(cor: Color, rugosidade := 0.6, brilho := Color.BLACK, energia := 0.0) -> StandardMaterial3D:
	var chave := "%s/%s/%s/%s" % [cor.to_html(), rugosidade, brilho.to_html(), energia]
	if _cache.has(chave):
		return _cache[chave]
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = rugosidade
	if energia > 0.0:
		m.emission_enabled = true
		m.emission = brilho
		m.emission_energy_multiplier = energia
	_cache[chave] = m
	return m


func _cena(caminho: String) -> PackedScene:
	if not _cache.has(caminho):
		_cache[caminho] = load(caminho)
	return _cache[caminho]
