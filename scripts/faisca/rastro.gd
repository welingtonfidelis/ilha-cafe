class_name Rastro
extends MeshInstance3D
## O rastro de luz da mão no giro do Faísca (no jeito do Astro, 2026-11-13): um arco atrás da mão, em volta do eixo do
## corpo, largo e claro perto da mão e afinando e sumindo na ponta, como o risco que a mão deixa girando rápido.
## O arco é calculado a cada quadro (a mão de agora girada para trás pelo tanto que o corpo girou), então sai redondo
## em qualquer taxa de quadros; guardando as posições de verdade, com a tela lenta sobravam 2 ou 3 pontos e virava
## um borrão. Quem usa diz onde está a mão (`alvo`), o eixo (`centro`), quanto o arco cobre (`varrido`, em
## radianos, no sentido da volta) e a força (0 apaga).

const PEDACOS := 28

var largura := 0.22
var cor := Color(0.4, 0.88, 1.0, 0.95)
var forca := 0.0
var varrido := 0.0
var alvo: Callable
var centro: Callable
var _malha := ImmediateMesh.new()


func _init() -> void:
	top_level = true
	mesh = _malha
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = m


func _process(_delta: float) -> void:
	global_transform = Transform3D.IDENTITY
	_desenhar()


func _desenhar() -> void:
	_malha.clear_surfaces()
	if forca <= 0.01 or absf(varrido) < 0.05 or not alvo.is_valid() or not centro.is_valid():
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var mao: Vector3 = alvo.call()
	var eixo: Vector3 = centro.call()
	var rel := mao - eixo
	# Cada pedaço tem três fileiras: a borda de um lado, o meio e a outra borda, para a fita sair macia como um risco de
	# luz.
	var fileiras: Array = []
	for i in PEDACOS + 1:
		var t := float(i) / PEDACOS
		var p := eixo + rel.rotated(Vector3.UP, -varrido * t)
		var tangente := rel.rotated(Vector3.UP, -varrido * t + PI / 2.0 * signf(varrido))
		var lado := tangente.cross(cam.global_position - p)
		var vida := 1.0 - t
		lado = lado.normalized() * largura * pow(vida, 0.5) if lado.length() > 0.0001 else Vector3.ZERO
		var a := cor.a * forca * pow(vida, 1.4)
		# As bordas azuis meio transparentes (o brilho em volta) e o miolo quase branco.
		fileiras.append([p + lado, p, p - lado, Color(cor.r, cor.g, cor.b, a * 0.3), Color(cor.r, cor.g, cor.b, a).lerp(Color(1, 1, 1, a), 0.6)])
	_malha.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in fileiras.size() - 1:
		var a: Array = fileiras[i]
		var b: Array = fileiras[i + 1]
		for tri: Array in [[a, 0, a, 1, b, 0], [a, 1, b, 1, b, 0], [a, 1, a, 2, b, 1], [a, 2, b, 2, b, 1]]:
			for k in 3:
				var f: Array = tri[k * 2]
				var col: int = tri[k * 2 + 1]
				_malha.surface_set_color(f[4] if col == 1 else f[3])
				_malha.surface_add_vertex(f[col])
	_malha.surface_end()
