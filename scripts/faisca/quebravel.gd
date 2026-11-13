class_name Quebravel
extends StaticBody3D
## Caixa, pote ou presente que quebra com qualquer golpe (item 6 da lista do Faísca, 2026-11-11, o "mundo que reage"
## do Astro Bot): soco, giro, pisão em cima, laser dos pés, pancada do Martelinho e Bolota arremessada. Quebra de uma
## vez: dá um estalo, some numa chuva de cacos com as cores do próprio modelo (tiradas da textura) e solta moedas. O
## presente solta confete junto. Fica sólido até quebrar: dá para subir em cima.
## Cada mundo tem os seus (`TIPOS`, escolhidos pela `Fase.ESTILOS`); o vaso de barro é feito aqui, sem modelo.

signal quebrou(q: Quebravel)

const DOCES := "res://assets/faisca/doces/"
const NEVE := "res://assets/faisca/neve/"
## tipo -> [modelo ("" = o vaso de barro), escala, quanto subir o modelo (os que têm a origem no meio), som, moedas]
const TIPOS := {
	"caixa": [Fase.MASMORRA + "box_large.gltf", 0.7, 0.0, "caixa_quebra", 3],
	"barril": [Fase.MASMORRA + "barrel_small.gltf", 1.0, 0.0, "caixa_quebra", 3],
	"vaso": ["", 1.1, 0.0, "pote_quebra", 3],
	"pote": [Fase.COZINHA + "jar_A_medium.gltf", 1.9, 0.0, "pote_quebra", 3],
	"pote_azul": [Fase.COZINHA + "jar_C_medium.gltf", 1.9, 0.0, "pote_quebra", 3],
	"presente": [DOCES + "present_A_red.gltf", 1.6, 0.0, "presente_abre", 4],
	"presente_alto": [DOCES + "present_B_blue.gltf", 1.3, 0.0, "presente_abre", 4],
	"presente_verde": [NEVE + "present_A_green.gltf", 1.6, 0.0, "presente_abre", 4],
	"presente_grande": [NEVE + "present_D_red.gltf", 1.1, 0.0, "presente_abre", 4],
	"caixote": [Fase.FABRICA + "crate.gltf", 0.55, 0.55, "caixa_quebra", 3],
}
## Cores de reserva dos cacos, se a textura não der para ler.
const CORES_DE_RESERVA := [Color("c08a52"), Color("8a5a30"), Color("e9c46a")]
const CACOS := 12
const GRAVIDADE := 20.0

## Para os golpes: quebrado conta como derrotado (não vira mais alvo).
var derrotado := false
var raio_golpe := 0.6
var tipo := "caixa"
var moedas := 3
## Tamanho da caixa de colisão (para a fase conferir o espaço em volta).
var tamanho := Vector3.ONE
var _modelo: Node3D
var _forma: CollisionShape3D
var _cacos: Array[Dictionary] = []
var _cores: Array = []
static var _cores_por_modelo := {}


func _init(qual := "caixa") -> void:
	tipo = qual


func _ready() -> void:
	add_to_group(Alvo.GRUPO)
	# Mundo (para pisar em cima e as Bolotas baterem) e a camada dos alvos (para o laser dos pés achar).
	collision_layer = 1 | Alvo.CAMADA
	collision_mask = 0
	var spec: Array = TIPOS.get(tipo, TIPOS.caixa)
	moedas = spec[4]
	if String(spec[0]) == "":
		_modelo = _vaso()
	else:
		_modelo = load(spec[0]).instantiate()
	_modelo.scale = Vector3.ONE * float(spec[1])
	_modelo.position.y = float(spec[2])
	add_child(_modelo)
	var caixa := _aabb()
	tamanho = caixa.size
	_forma = CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = caixa.size
	_forma.shape = forma
	_forma.position = caixa.get_center()
	add_child(_forma)
	raio_golpe = maxf(caixa.size.x, caixa.size.z) * 0.5 + 0.1


## Quebra no primeiro golpe, venha de onde vier.
func receber_golpe(_dano: int, de: Vector3, _forca := 6.0, _tipo := "") -> bool:
	if derrotado:
		return false
	quebrar(de)
	return true


func quebrar(de := Vector3.INF) -> void:
	if derrotado:
		return
	derrotado = true
	remove_from_group(Alvo.GRUPO)
	collision_layer = 0
	_forma.set_deferred("disabled", true)
	var spec: Array = TIPOS.get(tipo, TIPOS.caixa)
	var centro := global_position + Vector3.UP * tamanho.y * 0.5
	Sfx.play_at(get_parent(), String(spec[3]), centro, -2.0, 0.12)
	_cores = _cores_do_modelo()
	var tw := create_tween()
	tw.tween_property(_modelo, "scale", _modelo.scale * Vector3(1.18, 0.8, 1.18), 0.05)
	tw.tween_callback(_modelo.hide)
	_soltar_cacos(centro, de)
	Fx.dust(get_parent(), centro)
	if String(spec[3]) == "presente_abre":
		Fx.confetti(get_parent(), centro + Vector3.UP * 0.3, 30, 5.0)
	var fase := get_parent() as Fase
	if fase:
		fase.soltar_moedas(centro, moedas, 1.4)
	quebrou.emit(self)


func _physics_process(delta: float) -> void:
	if _cacos.is_empty():
		return
	var chao := global_position.y
	for c in _cacos:
		var no: MeshInstance3D = c.no
		c.vida -= delta
		var v: Vector3 = c.vel
		v.y -= GRAVIDADE * delta
		var p := no.global_position + v * delta
		# Quica no chão onde a caixa estava, cada vez mais baixo.
		if p.y < chao + 0.05 and v.y < 0.0:
			p.y = chao + 0.05
			v.y *= -0.35
			v.x *= 0.6
			v.z *= 0.6
		c.vel = v
		no.global_position = p
		no.rotate(c.eixo, c.giro * delta)
		if c.vida < 0.3:
			no.scale = Vector3.ONE * maxf(c.vida / 0.3, 0.01)
	for c in _cacos.filter(func(x: Dictionary) -> bool: return x.vida <= 0.0):
		(c.no as Node).queue_free()
		_cacos.erase(c)


## Os cacos voam para longe de quem bateu (por cima, para os lados), girando, e quicam no chão.
func _soltar_cacos(centro: Vector3, de: Vector3) -> void:
	var lado := Vector3.ZERO
	if de != Vector3.INF:
		lado = centro - de
		lado.y = 0.0
		lado = lado.normalized() if lado.length() > 0.05 else Vector3.ZERO
	var malha := BoxMesh.new()
	malha.size = Vector3.ONE
	for i in CACOS:
		var mi := MeshInstance3D.new()
		mi.mesh = malha
		var mat := StandardMaterial3D.new()
		mat.albedo_color = _cores[i % _cores.size()]
		mat.roughness = 0.6
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.top_level = true
		add_child(mi)
		var a := TAU * i / CACOS + randf() * 0.5
		var lado_caco := Vector3(cos(a), 0, sin(a))
		mi.global_position = centro + lado_caco * minf(tamanho.x, tamanho.z) * 0.3 + Vector3.UP * randf_range(-0.2, 0.3)
		mi.scale = Vector3(randf_range(0.12, 0.26), randf_range(0.08, 0.2), randf_range(0.12, 0.26))
		var vel := lado_caco * randf_range(2.0, 4.0) + lado * 2.5 + Vector3.UP * randf_range(3.5, 6.5)
		_cacos.append({"no": mi, "vel": vel, "eixo": Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5).normalized(),
				"giro": randf_range(6.0, 14.0), "vida": randf_range(0.9, 1.3)})


## Três cores do modelo, lidas da textura nos pontos da malha (guardadas por modelo). Sem dar, as de reserva.
func _cores_do_modelo() -> Array:
	var spec: Array = TIPOS.get(tipo, TIPOS.caixa)
	if String(spec[0]) == "":
		return [Color("d0703f"), Color("b65a30"), Color("f2d49b")]
	if _cores_por_modelo.has(spec[0]):
		return _cores_por_modelo[spec[0]]
	var cores: Array = []
	for mi in _modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := (mi as MeshInstance3D).mesh
		if malha == null:
			continue
		for s in malha.get_surface_count():
			var mat := (mi as MeshInstance3D).get_active_material(s) as BaseMaterial3D
			if mat == null or mat.albedo_texture == null:
				continue
			var img := mat.albedo_texture.get_image()
			if img == null:
				continue
			if img.is_compressed():
				img.decompress()
			var uvs: PackedVector2Array = malha.surface_get_arrays(s)[Mesh.ARRAY_TEX_UV]
			var passo := maxi(uvs.size() / 40, 1)
			for k in range(0, uvs.size(), passo):
				var uv := uvs[k]
				var c := img.get_pixel(clampi(int(uv.x * img.get_width()), 0, img.get_width() - 1),
						clampi(int(uv.y * img.get_height()), 0, img.get_height() - 1)) * mat.albedo_color
				if cores.all(func(o: Color) -> bool: return absf(o.r - c.r) + absf(o.g - c.g) + absf(o.b - c.b) > 0.25):
					cores.append(c)
				if cores.size() >= 3:
					break
			if cores.size() >= 3:
				break
	if cores.is_empty():
		cores = CORES_DE_RESERVA.duplicate()
	_cores_por_modelo[spec[0]] = cores
	return cores


## A caixa que envolve o modelo, no espaço da caixa quebrável.
func _aabb() -> AABB:
	var caixa := AABB()
	var primeira := true
	for mi in _modelo.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var t := global_transform.affine_inverse() * m.global_transform if is_inside_tree() else _relativo(m)
		var b := t * m.get_aabb()
		caixa = b if primeira else caixa.merge(b)
		primeira = false
	return caixa


func _relativo(no: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = no
	while n and n != self:
		t = (n as Node3D).transform * t
		n = n.get_parent()
	return t


## Vaso de barro torneado (o perfil girado em volta do eixo), com uma faixa clara pintada e a boca escura.
func _vaso() -> Node3D:
	var perfil: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(0.26, 0.0), Vector2(0.38, 0.1), Vector2(0.46, 0.32),
			Vector2(0.44, 0.56), Vector2(0.32, 0.74), Vector2(0.25, 0.82), Vector2(0.31, 0.9), Vector2(0.31, 0.97),
			Vector2(0.24, 0.97), Vector2(0.22, 0.9)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var gomos := 24
	var barro := Color("d0703f")
	var faixa := Color("f2d49b")
	for i in perfil.size() - 1:
		var a := perfil[i]
		var b := perfil[i + 1]
		var cor := faixa if (a.y + b.y) * 0.5 > 0.4 and (a.y + b.y) * 0.5 < 0.5 else barro
		if i >= perfil.size() - 3:
			cor = Color("5a2e1a")
		for k in gomos:
			var t0 := TAU * k / gomos
			var t1 := TAU * (k + 1) / gomos
			var p00 := Vector3(cos(t0) * a.x, a.y, sin(t0) * a.x)
			var p01 := Vector3(cos(t1) * a.x, a.y, sin(t1) * a.x)
			var p10 := Vector3(cos(t0) * b.x, b.y, sin(t0) * b.x)
			var p11 := Vector3(cos(t1) * b.x, b.y, sin(t1) * b.x)
			st.set_color(cor)
			# A mesma ordem da Forma (a face da frente para fora).
			for v in [p00, p11, p10, p00, p01, p11]:
				st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.75
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	var no := Node3D.new()
	no.add_child(mi)
	# A faixa de bolinhas: três pintinhas em volta.
	var pinta := SphereMesh.new()
	pinta.radius = 0.05
	pinta.height = 0.1
	var mat_pinta := StandardMaterial3D.new()
	mat_pinta.albedo_color = Color("2a9d8f")
	for k in 6:
		var a := TAU * k / 6.0
		var p := MeshInstance3D.new()
		p.mesh = pinta
		p.material_override = mat_pinta
		p.position = Vector3(cos(a) * 0.45, 0.45, sin(a) * 0.45)
		p.scale = Vector3(1, 1, 0.4)
		p.rotation.y = -a + PI / 2.0
		no.add_child(p)
	return no
